import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/core/utils/time_util.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/data/todo_tags_repository.dart';
import 'package:zen_do/features/todos/data/todo_with_tags.dart';
import 'package:zen_do/features/todos/domain/sort_option.dart';

class TodoService {
  final TodoRepository todoRepo;
  final EntityRepository entityRepo;
  final TodoTagsRepository todoTagsRepo;

  TodoService({
    required this.todoRepo,
    required this.entityRepo,
    required this.todoTagsRepo,
  });

  Future<Todo> create({
    required String title,
    required ListScope scope,
    DateTime? expiresAt,
    String? description,
    Set<String>? tagUuids,
  }) async {
    return await entityRepo.createWithEntity(EntityType.todo, (
      String tagUuid,
    ) async {
      final todo = await todoRepo.create(
        uuid: tagUuid,
        title: title,
        scope: scope,
        expiresAt: _calculateExpiry(scope),
        description: description,
      );

      if (tagUuids != null && tagUuids.isNotEmpty) {
        await todoTagsRepo.addAllTagsToTodo(
          todoUuid: tagUuid,
          tagUuids: tagUuids,
        );
      }

      return todo;
    });
  }

  DateTime? _calculateExpiry(ListScope scope) {
    if (scope == ListScope.backlog) {
      return null;
    } else {
      return DateTime.now().add(scope.duration).normalized;
    }
  }

  Stream<List<TodoWithTags>> watchAllOpenByScope({
    required ListScope scope,
    SortOption? sortOption,
    SortOrder? sortOrder,
  }) {
    return todoRepo.watchAllByScope(
      scope: scope,
      isCompleted: false,
      sortOption: sortOption,
      sortOrder: sortOrder,
    );
  }

    Stream<List<TodoWithTags>> watchAllCompletedByScope({
    required ListScope scope,
  }) {
    return todoRepo.watchAllByScope(
      scope: scope,
      isCompleted: true,
      sortOption: SortOption.completionDate,
      sortOrder: SortOrder.descending,
    );
  }
}

import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/core/utils/time_util.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/data/todo_tags_repository.dart';
import 'package:zen_do/features/todos/data/todo_with_tags.dart';
import 'package:zen_do/features/todos/domain/todo_dto.dart';
import 'package:zen_do/features/todos/domain/todo_sort_option.dart';

class TodoService {
  final TodoRepository todoRepo;
  final EntityRepository entityRepo;
  final TodoTagsRepository todoTagsRepo;
  final TagRepository tagRepo;

  TodoService({
    required this.todoRepo,
    required this.entityRepo,
    required this.todoTagsRepo,
    required this.tagRepo,
  });

  Future<TodoDto> create({
    required String title,
    required ListScope scope,
    DateTime? expiresAt,
    String? description,
    Set<String>? tagUuids,
  }) async {
    return await entityRepo.createWithEntity(EntityType.todo, (
      Entity entity,
    ) async {
      final todo = await todoRepo.create(
        uuid: entity.uuid,
        title: title,
        scope: scope,
        expiresAt: _calculateExpiry(scope),
        description: description,
      );

      Set<String> validTagUuids = {};
      if (tagUuids != null && tagUuids.isNotEmpty) {
        final validTags = await tagRepo.readAllByUuids(tagUuids);
        validTagUuids = validTags.map((tag) => tag.uuid).toSet();

        await todoTagsRepo.addAllTagsToTodo(
          todoUuid: todo.uuid,
          tagUuids: validTagUuids,
        );
      }

      return TodoDto.fromDb(
        todo: todo,
        entity: entity,
        tagUuids: validTagUuids,
      );
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
    TodoSortOption? sortOption,
    SortOrder? sortOrder,
    Set<String>? tagUuidsFilter,
  }) {
    return todoRepo.watchAllByScope(
      scope: scope,
      isCompleted: false,
      sortOption: sortOption,
      sortOrder: sortOrder,
      tagUuidsFilter: tagUuidsFilter,
    );
  }

  Stream<List<TodoWithTags>> watchAllCompletedByScope({
    required ListScope scope,
    Set<String>? tagUuidsFilter,
  }) {
    return todoRepo.watchAllByScope(
      scope: scope,
      isCompleted: true,
      sortOption: TodoSortOption.completionDate,
      sortOrder: SortOrder.descending,
      tagUuidsFilter: tagUuidsFilter,
    );
  }
}

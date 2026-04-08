import 'package:zen_do/core/domain/app_settings_service.dart';
import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/core/utils/time_util.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/data/todo_tags_repository.dart';
import 'package:zen_do/features/todos/domain/todo_dto.dart';
import 'package:zen_do/features/todos/domain/todo_sort_option.dart';

class TodoService {
  final TodoRepository todoRepo;
  final EntityRepository entityRepo;
  final TodoTagsRepository todoTagsRepo;
  final TagRepository tagRepo;
  final AppSettingsService settingsService;

  TodoService({
    required this.todoRepo,
    required this.entityRepo,
    required this.todoTagsRepo,
    required this.tagRepo,
    required this.settingsService,
  });

  List<ListScope> get _sortedActiveScopes {
    final activeScopes = <ListScope>[
      ...settingsService.getActiveListScopes()?.toList() ?? [],
    ];
    activeScopes.sort();
    return activeScopes;
  }

  /// Creates a new todo with the given attributes and persists it in the database.
  /// Also links the given tags with the new todo.<br>
  /// Returns the new todo as a [TodoDto].
  Future<TodoDto> create({
    required String title,
    required ListScope scope,
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
        expiresAt: calculateExpiry(scope),
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

  DateTime? calculateExpiry(ListScope scope) {
    if (scope == ListScope.backlog) {
      return null;
    } else {
      return DateTime.now().add(scope.duration).normalized;
    }
  }

  /// Returns a reacive stream of all open todos with a given [scope].<br>
  /// Returns a streamed List of [TodoDto]s with populated metadata and associated tags.<br>
  /// If [taguudsFilter] is provided, it filters the list of todos to match any of the given tag uuids.<br>
  /// If [sortOption] is provided, it orders the list by the given option.
  /// By default it orders the list by 'customOrder' ascending.
  /// If [sortOrder] is provided, it orders the list accordingly.
  Stream<List<TodoDto>> watchAllOpenByScope({
    required ListScope scope,
    TodoSortOption? sortOption,
    SortOrder? sortOrder,
    Set<String>? tagUuidsFilter,
  }) {
    final todoStream = todoRepo.watchDtosByScope(
      scope: scope,
      isCompleted: false,
      sortOption: sortOption,
      sortOrder: sortOrder,
      tagUuidsFilter: tagUuidsFilter,
    );
    return todoStream.map((todos) => todos.map(_setWillBeTransfered).toList());
  }

  /// Returns a reacive stream of all completed todos with a given [scope].<br>
  /// Returns a streamed List of [TodoDto]s with populated metadata and associated tags.<br>
  /// If [taguudsFilter] is provided, it filters the list of todos to match any of the given tag uuids.<br>
  /// If [sortOption] is provided, it orders the list by the given option.
  /// By default it orders the list by 'customOrder' ascending.
  /// If [sortOrder] is provided, it orders the list accordingly.
  Stream<List<TodoDto>> watchAllCompletedByScope({
    required ListScope scope,
    Set<String>? tagUuidsFilter,
  }) {
    return todoRepo.watchDtosByScope(
      scope: scope,
      isCompleted: true,
      sortOption: TodoSortOption.completionDate,
      sortOrder: SortOrder.descending,
      tagUuidsFilter: tagUuidsFilter,
    );
  }

  TodoDto _setWillBeTransfered(TodoDto todo) {
    final isMoving = _calcWillBeTransfered(todo.scope, todo.expiresAt);

    return isMoving ? todo.copyWith(willBeTransferred: true) : todo;
  }

  bool _calcWillBeTransfered(ListScope scope, DateTime? expiresAt) {
    if (expiresAt == null) return false;

    final indexOfList = _sortedActiveScopes.indexOf(scope);
    if (indexOfList < 0) {
      return false;
    }

    final scopeToSubtract = indexOfList == 0 || scope == ListScope.backlog
        ? Duration.zero
        : _sortedActiveScopes[indexOfList - 1].duration;
    final transferDate = expiresAt.subtract(scopeToSubtract);
    return DateTime.now().isAfter(transferDate);
  }

  /// Calculates the amount of todos that will be transferred or are expired for the given [scope]
  /// and returns the value in a stream.<br>
  /// Use this method to fill the badges on each todo list.
  Stream<int> watchWillBeTransfered(ListScope scope) {
    return todoRepo.watchAllOpenByScope(scope).map((todos) {
      return todos
          .where((todo) => _calcWillBeTransfered(todo.scope, todo.expiresAt))
          .length;
    }).distinct();
  }

  /// Updates the given todo in the database and marks it as 'updated' to sync to cloud.<br>
  /// Returns true if succesfull, false otherwise.
  Future<bool> update(TodoDto todo) async {
    return await entityRepo.updateWithTouch(todo.uuid, () async {
      final isTodoUpdated = await todoRepo.update(todo);
      await todoTagsRepo.updateTags(
        todoUuid: todo.uuid,
        newTagUuids: todo.tagUuids,
      );
      return isTodoUpdated;
    });
  }

  /// Marks the todo with the given uuid as completed
  /// and updates the updatedAt timestamp to trigger cloud sync.
  Future<bool> markAsCompleted(String uuid) async {
    final updated = await entityRepo.updateWithTouch(uuid, () async {
      return await todoRepo.markAsCompleted(uuid);
    });
    return updated == 1;
  }

  /// Restores the todo with the given uuid by removing the completedAt timestamp
  /// and updates the updatedAt timestamp to trigger cloud sync.
  Future<bool> restore(String uuid) async {
    final updated = await entityRepo.updateWithTouch(uuid, () async {
      return await todoRepo.restore(uuid);
    });
    return updated == 1;
  }

  /// Returns a reactive stream representing the amount of all expired todos in all lists.
  Stream<int> watchExpiredCount() {
    return todoRepo.watchExpiredCount(
      settingsService.getActiveListScopes() ?? ListScope.values.toSet(),
    );
  }

  Future<void> transferTodos() async {
    // TODO implement
    throw UnimplementedError();
  }

  /// Sets the given [destinationScope] to the given [todo] and returns 'true' when
  /// successful, false otherwise.
  Future<bool> moveToOtherList(TodoDto todo, ListScope destinationScope) async {
    final indexOfDestinationScope = _sortedActiveScopes.indexOf(
      destinationScope,
    );
    if (indexOfDestinationScope < 0) return false;

    return await entityRepo.updateWithTouch(todo.uuid, () async {
      return todoRepo.update(todo.copyWith(scope: destinationScope));
    });
  }

  /// Sets the next [ListScope] to the given [todo] and returns 'true' when
  /// successful, false otherwise.
  Future<bool> moveToNextList(TodoDto todo) async {
    final nextScope = getNextScope(todo.scope);
    if (nextScope == null) return false;

    return moveToOtherList(todo, nextScope);
  }

  /// Sets the previous [ListScope] to the given [todo] and returns 'true' when
  /// successful, false otherwise.
  Future<bool> moveToPreviousList(TodoDto todo) async {
    final previousScope = getPreviousScope(todo.scope);
    if (previousScope == null) return false;

    return moveToOtherList(todo, previousScope);
  }

  /// Calculates the previous (next higher) [ListScope] to the given [scope]
  /// Returns 'null' when then given [scope] is the last scope in the
  /// list of active scopes (e.g. [ListScope.backlog])
  ListScope? getPreviousScope(ListScope scope) {
    final indexOfScope = _sortedActiveScopes.indexOf(scope);
    if (indexOfScope < 0 || indexOfScope + 1 >= _sortedActiveScopes.length) {
      return null;
    }
    return _sortedActiveScopes.elementAt(indexOfScope + 1);
  }

  /// Calculates the next (next lower) [ListScope] to the given [scope].
  /// Returns 'null' when then given [scope] is the first scope in the
  /// list of active scopes (e.g. [ListScope.daily])
  ListScope? getNextScope(ListScope scope) {
    final indexOfScope = _sortedActiveScopes.indexOf(scope);
    if (indexOfScope <= 0) {
      return null;
    }
    return _sortedActiveScopes.elementAt(indexOfScope - 1);
  }
}

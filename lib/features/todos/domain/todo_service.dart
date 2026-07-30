import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:zen_do/core/domain/app_settings_service.dart';
import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/core/utils/time_util.dart';
import 'package:zen_do/features/tags/data/tag_repository.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/data/todo_tags_repository.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';
import 'package:zen_do/features/todos/domain/todo_dto.dart';
import 'package:zen_do/features/todos/domain/todo_sort_option.dart';

class TodoService {
  final TodoRepository _todoRepo;
  final EntityRepository _entityRepo;
  final TodoTagsRepository _todoTagsRepo;
  final TagRepository _tagRepo;
  final AppSettingsService _settingsService;

  TodoService({
    required TodoRepository todoRepo,
    required EntityRepository entityRepo,
    required TodoTagsRepository todoTagsRepo,
    required TagRepository tagRepo,
    required AppSettingsService settingsService,
  }) : _todoRepo = todoRepo,
       _entityRepo = entityRepo,
       _todoTagsRepo = todoTagsRepo,
       _tagRepo = tagRepo,
       _settingsService = settingsService;

  List<ListScope> get _sortedActiveScopes {
    final activeScopes = List<ListScope>.from(
      _settingsService.getActiveListScopes(),
    );
    activeScopes.sort();
    return activeScopes;
  }

  List<ListScope> get _scopesWithExpiry {
    final activeScopesWithExpiry = List<ListScope>.from(
      _settingsService.getActiveListScopes(),
    );
    activeScopesWithExpiry.remove(ListScope.backlog);

    return activeScopesWithExpiry;
  }

  /// Creates a new todo with the given attributes and persists it in the database.
  /// Also links the given tags with the new todo.<br>
  /// Returns the new todo as a [TodoDto].
  Future<TodoDto> create({
    required String title,
    required ListScope scope,
    String? description,
    Set<String>? tagUuids,
    DateTime? expiresAt,
  }) async {
    return await _entityRepo.createWithEntity(EntityType.todo, (
      Entity entity,
    ) async {
      final todo = await _todoRepo.create(
        uuid: entity.uuid,
        title: title,
        scope: scope,
        expiresAt: expiresAt?.endOfDay ?? calcExpiry(scope),
        description: description,
      );

      Set<String> validTagUuids = {};
      if (tagUuids != null && tagUuids.isNotEmpty) {
        final validTags = await _tagRepo.readAllByUuids(tagUuids);
        validTagUuids = validTags.map((tag) => tag.uuid).toSet();

        await _todoTagsRepo.addAllTagsToTodo(
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
    final todoStream = _todoRepo.watchDtosByScope(
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
    return _todoRepo.watchDtosByScope(
      scope: scope,
      isCompleted: true,
      sortOption: TodoSortOption.completionDate,
      sortOrder: SortOrder.descending,
      tagUuidsFilter: tagUuidsFilter,
    );
  }

  /// Sets the 'willBeTransferred' flag on the given [todo] if it will be
  /// transfered tomorrow.
  TodoDto _setWillBeTransfered(TodoDto todo) {
    final willBeTransfered = _calcWillBeTransfered(todo.scope, todo.expiresAt);

    return willBeTransfered ? todo.copyWith(willBeTransferred: true) : todo;
  }

  /// Calculates if a todo with the given pair of [scope] and [expiresAt] will be
  /// transfered tomorrow.
  bool _calcWillBeTransfered(ListScope scope, DateTime? expiresAt) {
    if (expiresAt == null) return false;

    final indexOfList = _sortedActiveScopes.indexOf(scope);
    if (indexOfList < 1) {
      return false;
    }

    final scopeToSubtract = indexOfList == 0 || scope == ListScope.backlog
        ? Duration.zero
        : _sortedActiveScopes[indexOfList - 1].duration;
    final transferDate = expiresAt.subtract(scopeToSubtract);
    return !transferDate.isAfter(DateTime.now().endOfDay);
  }

  /// Calculates the amount of todos that will be transferred or are expired for the given [scope]
  /// and returns the value in a stream.<br>
  /// Use this method to fill the badges on each todo list.
  Stream<int> watchWillBeTransferedOrExpiredCount(ListScope scope) {
    return _todoRepo.watchAllOpenByScope(scope).map((todos) {
      return todos.where((todo) {
        return (todo.expiresAt?.isBefore(DateTime.now()) ?? false) ||
            _calcWillBeTransfered(scope, todo.expiresAt);
      }).length;
    }).distinct();
  }

  /// Returns a reactive stream representing the amount of all expired todos in all lists.
  Stream<int> watchExpiredCount() {
    return _todoRepo.watchExpiredCount(_scopesWithExpiry.toSet());
  }

  /// Updates the given todo in the database and marks it as 'updated' to sync to cloud.<br>
  /// Returns true if succesfull, false otherwise.
  Future<bool> update(TodoDto todo) async {
    return await _entityRepo.updateWithTouch(todo.uuid, () async {
      final isTodoUpdated = await _todoRepo.updateDto(todo);
      await _todoTagsRepo.updateTags(
        todoUuid: todo.uuid,
        newTagUuids: todo.tagUuids,
      );
      return isTodoUpdated;
    });
  }

  /// Marks the todo with the given uuid as completed
  /// and updates the updatedAt timestamp to trigger cloud sync.
  Future<bool> markAsCompleted(String uuid) async {
    final updated = await _entityRepo.updateWithTouch(uuid, () async {
      return await _todoRepo.markAsCompleted(uuid);
    });
    return updated == 1;
  }

  /// Restores the todo with the given uuid and updates the updatedAt timestamp to trigger cloud sync.
  Future<bool> restore(TodoDto todo) async {
    final updated = await _entityRepo.updateWithTouch(todo.uuid, () async {
      final isOrderVacant = await _todoRepo.isCustomOrderVacant(
        todo.customOrder,
        todo.scope,
      );

      String? newCustomOrder;
      if (!isOrderVacant) {
        final nextOrder = await _todoRepo.findNextOrder(
          todo.scope,
          todo.customOrder,
        );
        newCustomOrder = FractionalIndexing.generateKeyBetween(
          todo.customOrder,
          nextOrder,
        );
      }

      return await _todoRepo.restore(
        todo.uuid,
        newCustomOrder ?? todo.customOrder,
      );
    });
    return updated == 1;
  }

  /// Transferes all todos with an expiresAt date, that doesn't fit to the
  /// current scope anymore. In that case the most fitting scopes is determined
  /// and set to the todo. Also updates the updatedAt timestampt to trigger cloud sync.
  Future<void> transferTodos() async {
    final scopesToTransferFrom = _scopesWithExpiry..removeAt(0);
    if (scopesToTransferFrom.isEmpty) return;

    await _todoRepo.db.transaction(() async {
      final todos = await _todoRepo.readAllOpenByScopes(
        scopesToTransferFrom.toSet(),
      );

      for (final todo in todos) {
        if (todo.expiresAt == null) continue;

        final nextScope = getNextScope(todo.scope);
        if (nextScope == null) continue;

        final nextScopeExpiry = calcExpiry(nextScope);
        if (todo.expiresAt!.isBefore(nextScopeExpiry!)) {
          final fittingScope = calcFittingScope(todo.expiresAt!);
          await _entityRepo.updateWithTouch(todo.uuid, () async {
            await _todoRepo.update(todo.copyWith(scope: fittingScope));
          });
        }
      }
    });
  }

  /// Returns the most fitting ListScope for the given [expiresAt] date.
  ListScope? calcFittingScope(DateTime expiresAt) {
    final activeScopes = _sortedActiveScopes;
    for (final scope in activeScopes) {
      if (scope == ListScope.backlog) {
        continue;
      }

      final expiryOfScope = calcExpiry(scope)!;
      if (!expiresAt.isAfter(expiryOfScope)) {
        return scope;
      }
    }

    if (activeScopes.contains(ListScope.backlog)) {
      return ListScope.backlog;
    }
    return null;
  }

  /// Calculates the expiration date based on the given [ListScope].
  /// Returns null if the ListScope is Backlog.
  DateTime? calcExpiry(ListScope scope) {
    if (scope == ListScope.backlog) {
      return null;
    } else {
      return DateTime.now().add(scope.duration).endOfDay;
    }
  }

  /// Sets the given [destinationScope] to the given [todo] and calculates the new expiry based on the new [ListScope].<br>
  /// Returns 'true' when successful, false otherwise.
  Future<bool> moveToOtherList(TodoDto todo, ListScope destinationScope) async {
    final indexOfDestinationScope = _sortedActiveScopes.indexOf(
      destinationScope,
    );
    if (indexOfDestinationScope < 0 ||
        indexOfDestinationScope >= _sortedActiveScopes.length) {
      return false;
    }

    return await _entityRepo.updateWithTouch(todo.uuid, () async {
      return _todoRepo.updateDto(
        todo.copyWith(
          scope: destinationScope,
          expiresAt: calcExpiry(destinationScope),
        ),
      );
    });
  }

  /// Sets the next [ListScope] to the given [todo] and and calculates the new expiry based on the new [ListScope].<br>
  /// Returns 'true' when successful, false otherwise.
  Future<bool> moveToNextList(TodoDto todo) async {
    final nextScope = getNextScope(todo.scope);
    if (nextScope == null) return false;

    return moveToOtherList(todo, nextScope);
  }

  /// Sets the previous [ListScope] to the given [todo] and and calculates the new expiry based on the new [ListScope].<br>
  /// Returns 'true' when successful, false otherwise.
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
  /// Returns 'null' when the given [scope] is the first scope in the
  /// list of active scopes (e.g. [ListScope.day])
  ListScope? getNextScope(ListScope scope) {
    final indexOfScope = _sortedActiveScopes.indexOf(scope);
    if (indexOfScope <= 0) {
      return null;
    }
    return _sortedActiveScopes.elementAt(indexOfScope - 1);
  }

  Future<int> delete(TodoDto todo) async {
    // TODO differ if cloud sync is active or not
    return await _entityRepo.hardDelete(todo.uuid);
  }

  Future<void> reorder(List<TodoDto> list, oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final movedTodo = list[oldIndex];
    final int targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    TodoDto? uiPrevious;
    TodoDto? uiNext;
    String? truePreviousOrder;
    String? trueNextOrder;

    if (targetIndex == 0) {
      uiPrevious = null;
      uiNext = list.first;
      truePreviousOrder = await _todoRepo.findPreviousOrder(
        movedTodo.scope,
        uiNext.customOrder,
      );
    } else if (targetIndex >= list.length - 1) {
      uiPrevious = list.last;
      uiNext = null;
      trueNextOrder = await _todoRepo.findNextOrder(
        movedTodo.scope,
        uiPrevious.customOrder,
      );
    } else {
      if (oldIndex < targetIndex) {
        uiPrevious = list[targetIndex];
        uiNext = list[targetIndex + 1];
      } else {
        uiPrevious = list[targetIndex - 1];
        uiNext = list[targetIndex];
      }
      trueNextOrder = await _todoRepo.findNextOrder(
        movedTodo.scope,
        uiPrevious.customOrder,
      );
    }

    final newCustomOrder = FractionalIndexing.generateKeyBetween(
      truePreviousOrder ?? uiPrevious?.customOrder,
      trueNextOrder ?? uiNext?.customOrder,
    );

    await update(movedTodo.copyWith(customOrder: newCustomOrder));
  }
}

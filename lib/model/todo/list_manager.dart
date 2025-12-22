import 'package:logger/logger.dart';
import 'package:zen_do/model/appsettings/settings_service.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/model/todo/todo.dart';
import 'package:zen_do/model/todo/todo_list.dart';
import 'package:zen_do/persistence/persistence_helper.dart';

Logger logger = Logger(level: Level.debug);

class ListManager {
  final Set<TodoList> _lists = {};

  ListManager(Iterable<TodoList> lists, {Set<ListScope>? activeScopes}) {
    final scopesToUse = activeScopes ?? ListScope.values;

    for (final scope in scopesToUse) {
      _lists.add(
        lists.singleWhere(
          (l) => l.scope == scope,
          orElse: () => TodoList(scope),
        ),
      );
    }
  }

  /// Loads all lists from persistence, transfers expired todos and saves the updated lists back to persistence.
  /// Returns true if the transfer was successful, false otherwise.
  /// Use this method for the background auto-transfer task.
  static Future<bool> autoTransferTodos() async {
    logger.d('AutoTransfer of expired todos started...');
    try {
      final lists = await PersistenceHelper.loadAll();
      final SettingsService settings =
          await SharedPrefsSettingsService.getInstance();
      final scopes = settings.getActiveListScopes();
      final manager = ListManager(lists, activeScopes: scopes);

      manager.transferTodos();
      await PersistenceHelper.closeAndRelease();
      logger.d('AutoTransfer of expired todos successfully finished!');
      return true;
    } catch (e, s) {
      logger.e("Error in autoTransfer: $e\n$s");
      return false;
    }
  }

  /// Transfers todos that are expired from higher scope lists to lower scope lists.
  Future<void> transferTodos() async {
    // use only lists with enabled autotransfer
    final activeLists = listsWithAutotransfer;

    if (activeLists.length > 1) {
      for (int i = activeLists.length - 1; i > 0; i--) {
        final currentList = activeLists[i];
        final nextList = activeLists[i - 1];

        final expiredTodos = getTodosToTransfer(
          currentList.todos,
          nextList.scope,
        );
        final addedTodos = await nextList.addAll(expiredTodos);
        await currentList.deleteAll(addedTodos);

        final difference = expiredTodos.length - addedTodos.length;
        if (difference > 0) {
          logger.d(
            '$difference todos could not be transfered from ${currentList.scope} to ${nextList.scope}!'
            'The list migth allready contain Todos with same titles.',
          );
        }
      }
    }
  }

  List<Todo> getTodosToTransfer(
    List<Todo> todosToTransfer,
    ListScope scopeOfNextList,
  ) {
    return todosToTransfer.where((todo) {
      if (todo.expirationDate == null) {
        return false;
      }
      final transferDate = todo.expirationDate!
          .subtract(scopeOfNextList.duration)
          .add(Duration(days: 1));
      return DateTime.now().isAfter(transferDate);
    }).toList();
  }

  /// Returns true if the given [todo] in the list of the given [currentScope] due to be transferred tomorrow.
  /// Returns false if the given [todo] is located in [ListScope.backlog] or [ListScope.daily],
  ///  the [todo] has no expiration date or the [todo] has no listScope.
  bool toBeTransferredTomorrow(Todo todo) {
    if (todo.expirationDate == null ||
        todo.listScope == null ||
        todo.listScope == ListScope.backlog ||
        todo.listScope == ListScope.daily) {
      return false;
    }

    final indexOfListContainigTodo = getIndexOfList(todo.listScope!);
    if (indexOfListContainigTodo <= 0) {
      return false;
    }
    final scopeToSubtract = allLists[indexOfListContainigTodo - 1].scope;
    final transferDate = todo.expirationDate!.subtract(
      scopeToSubtract.duration,
    );
    return DateTime.now().isAfter(transferDate);
  }

  /// Returns the count of todos in the given [list] that are either expired or due to be transferred tomorrow.
  int toBeTransferredOrExpiredCount(TodoList list) {
    int count = 0;
    final now = DateTime.now();
    for (var todo in list.todos) {
      if (todo.expirationDate != null && now.isAfter(todo.expirationDate!) ||
          toBeTransferredTomorrow(todo)) {
        count++;
      }
    }
    return count;
  }

  TodoList? getPreviousList(ListScope scope) {
    final indexOfCurrentList = getIndexOfList(scope);
    if (indexOfCurrentList < 0 || indexOfCurrentList + 1 >= _lists.length) {
      return null;
    }
    return allLists.elementAt(indexOfCurrentList + 1);
  }

  TodoList? getNextList(ListScope scope) {
    final indexOfCurrentList = getIndexOfList(scope);
    if (indexOfCurrentList <= 0) {
      return null;
    }
    return allLists.elementAt(indexOfCurrentList - 1);
  }

  Future<bool> moveToNextList(Todo todo) async {
    if (todo.listScope == null) {
      return false;
    }
    final nextList = getNextList(todo.listScope!);
    if (nextList == null) {
      return false;
    }
    return await moveAndUpdateTodo(todo: todo, destination: nextList.scope);
  }

  Future<bool> moveToPreviousList(Todo todo) async {
    if (todo.listScope == null) {
      return false;
    }
    final previousList = getPreviousList(todo.listScope!);
    if (previousList == null) {
      return false;
    }
    return await moveAndUpdateTodo(todo: todo, destination: previousList.scope);
  }

  /// Moves the given [todo] from its containing list, to another [destination] list
  Future<bool> moveAndUpdateTodo({
    Todo? oldTodo,
    required Todo todo,
    required ListScope destination,
  }) async {
    String errorMessage =
        '[ListManager] Shift of todo ${todo.title} not possible!';

    final ListScope? originScope = oldTodo == null
        ? todo.listScope
        : oldTodo.listScope;
    final Todo todoToUpdate = oldTodo ?? todo;
    TodoList? originList;
    TodoList? destinationList;
    bool isDeleted = false;
    bool isAdded = false;

    if (allScopes.contains(destination)) {
      destinationList = getListByScope(destination);
    }
    if (destinationList == null) {
      logger.i(
        '$errorMessage The destination list with the given scope ${destination.name} does not exist!',
      );
      return false;
    }

    if (originScope != null) {
      originList = getListByScope(originScope);
    }
    if (originList == null) {
      logger.i(
        '$errorMessage No origin list could be determined!'
        '[todo] or [oldTodo] must have a ListScope that represents the origin list!'
        '[ListManager] must have the given origin list!',
      );
      return false;
    }

    if (!isTodoTitleVacant(todo.title, destination)) {
      logger.i(
        '$errorMessage The todo allready exists in the destinatin list $destination!',
      );
      return false;
    }

    isDeleted = await originList.deleteTodo(todoToUpdate);
    if (isDeleted) {
      isAdded = await destinationList.addTodo(todo);
      if (!isAdded) {
        //revert if add to destination not possible
        originList.addTodo(todoToUpdate);
        logger.i(
          '$errorMessage The given todo could not be added to the destinatin list $destination!',
        );
      }
    } else {
      logger.i(
        '$errorMessage The given todo could not be deletet from the containing list!',
      );
    }
    return isAdded && isDeleted;
  }

  /// Checks wether a [Todo] allready exists with the given title in the list of the given [ListScope].
  bool isTodoTitleVacant(String title, ListScope scopeOfList) {
    final listOfScope = getListByScope(scopeOfList);
    if (listOfScope == null) {
      return false;
    }
    return listOfScope.isTodoTitleVacant(title);
  }

  /// Returns the number of expired [Todo]s in all active lists.
  int get expiredTodosCount {
    int count = 0;
    final now = DateTime.now();
    for (final list in listsWithAutotransfer) {
      for (final todo in list.todos) {
        if (todo.expirationDate != null && now.isAfter(todo.expirationDate!)) {
          count++;
        }
      }
    }
    return count;
  }

  int get listCount {
    return _lists.length;
  }

  List<TodoList> get allLists {
    final lists = _lists.toList();
    lists.sort((a, b) => a.compareTo(b));
    return lists;
  }

  List<ListScope> get allScopes {
    List<ListScope> scopes = [];
    for (final list in allLists) {
      scopes.add(list.scope);
    }
    return scopes;
  }

  List<TodoList> get listsWithAutotransfer {
    return allLists.where((l) => l.scope.isAutoTransfer).toList();
  }

  int getIndexOfList(ListScope scope) {
    return allLists.indexWhere((l) => l.scope == scope);
  }

  TodoList? getListByScope(ListScope scope) {
    TodoList? list;
    try {
      list = _lists.firstWhere((list) => list.scope == scope);
    } catch (e) {
      logger.i('[ListManager] List of scope $scope dos not exist!');
    }
    return list;
  }

  bool removeList(TodoList list) {
    return _lists.remove(list);
  }

  /// Adds the given list to the [ListManager].
  /// Returns true if the list was successfully added.
  /// Returns false if the [ListManager] allready contains a list with the given scope.
  bool addList(TodoList list) {
    bool added = _lists.add(list);
    if (!added) {
      logger.d(
        'List with scope ${list.scope} could not be added to ListManager because it is already contained!',
      );
    }
    return added;
  }

  /// Creates and adds an empty TodoList with the given scope.
  /// Returns true if the list was successfully added.
  /// Returns false if the [ListManager] allready contains a list with the given scope.
  bool addListOfScope(ListScope scope) {
    return addList(TodoList(scope));
  }
}

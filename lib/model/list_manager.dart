import 'package:logger/logger.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/persistence_helper.dart';

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
      var lists = await PersistenceHelper.loadAll();
      final manager = ListManager(lists);
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
  void transferTodos() {
    // use only lists with enabled autotransfer
    final activeLists = listsWithAutotransfer;
    activeLists.sort((a, b) => a.compareTo(b));

    if (activeLists.length > 1) {
      for (int i = activeLists.length - 1; i > 0; i--) {
        final currentList = activeLists[i];
        final previousList = activeLists[i - 1];

        final expiredTodos = getTodosToTransfer(
          currentList.todos,
          previousList.scope,
        );
        final addedTodos = previousList.addAll(expiredTodos);
        currentList.deleteAll(addedTodos);

        final difference = expiredTodos.length - addedTodos.length;
        if (difference > 0) {
          logger.d(
            '$difference Todos could not be transfered from ${currentList.scope} to ${previousList.scope}!'
            'The list migth allready contain Todos with the same titles.',
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
  /// Returns false if the given [currentScope] is [ListScope.backlog] or [ListScope.daily] or if the [todo] has no expiration date.
  bool toBeTransferredTomorrow(Todo todo, ListScope currentScope) {
    if (todo.expirationDate == null ||
        currentScope == ListScope.backlog ||
        currentScope == ListScope.daily) {
      return false;
    }
    final activeLists = listsWithAutotransfer;
    activeLists.sort((a, b) => a.compareTo(b));

    final indexOfListContainigTodo = activeLists.indexWhere(
      (l) => l.scope == currentScope,
    );
    if (indexOfListContainigTodo < 1) {
      return false;
    }
    final scopeDurationToSubtract =
        activeLists[indexOfListContainigTodo - 1].scope;
    final transferDate = todo.expirationDate!.subtract(
      scopeDurationToSubtract.duration,
    );
    return DateTime.now().isAfter(transferDate);
  }

  /// Returns the count of todos in the given [list] that are either expired or due to be transferred tomorrow.
  int toBeTransferredOrExpiredCount(TodoList list) {
    int count = 0;
    final now = DateTime.now();
    for (var todo in list.todos) {
      if (todo.expirationDate != null && now.isAfter(todo.expirationDate!) ||
          toBeTransferredTomorrow(todo, list.scope)) {
        count++;
      }
    }
    return count;
  }

  /// Checks wether an [Todo] allready exists with the given title in the list of the given [ListScope].
  bool todoTitleAllreadyExists(String title, ListScope scopeOfList) {
    return getListByScope(scopeOfList).todos.any((todo) => todo.title == title);
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
    return _lists.where((l) => l.scope.isAutoTransfer).toList();
  }

  TodoList getListByScope(ListScope scope) {
    return _lists.firstWhere((list) => list.scope == scope);
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

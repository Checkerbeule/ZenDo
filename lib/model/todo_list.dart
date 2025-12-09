import 'dart:async';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/persistence/persistence_helper.dart';

part 'todo_list.g.dart';

@HiveType(typeId: 1)
class TodoList implements Comparable<TodoList> {
  @HiveField(0)
  final ListScope scope;

  @HiveField(1)
  List<Todo> todos = [];

  @HiveField(2)
  List<Todo> doneTodos = [];

  @HiveField(3)
  TodoList(this.scope);

  int get doneCount {
    return doneTodos.length;
  }

  List<Todo> get allTodos {
    return [...todos, ...doneTodos];
  }

  /// Cache for todo ordering. Not persitet!
  int _currentMaxOrder = 0;

  /// Initialize [_currentMaxOrder].
  /// Call this method once after loading data from persistence.
  void initMaxOrderAfterLoad() {
    final maxOrder = allTodos.map((todo) => todo.order ?? 0).fold(0, max);
    _currentMaxOrder = maxOrder;
  }

  void _setExpirationDate(Todo todo) {
    if (scope != ListScope.backlog) {
      final now = DateTime.now();
      todo.expirationDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(scope.duration);
    }
  }

  void _setOrder(Todo todo) {
    _currentMaxOrder += 1000;
    todo.order = _currentMaxOrder;
  }

  /// Adds the [todo] to the list.
  /// Calculates the expirationDate based on the ListScope.
  /// Uses [PersistenceHelper] to store the list with the added [todo]
  /// Returns true if the new [Todo] was successfully added.
  /// Returns false if there allready exists a [Todo] with same title.
  bool addTodo(Todo todo) {
    if (isTodoTitleVacant(todo.title)) {
      todos.add(todo);
      _setExpirationDate(todo);
      _setOrder(todo);
      todo.listScope = scope;
      unawaited(PersistenceHelper.saveList(this));
      return true;
    }
    return false;
  }

  /// Use this method to transferExpiredTodos with the [ListManager].
  /// Adds all [todosToAdd] to the list.
  /// Does NOT calculate the expirationDate.
  /// Uses [PersistenceHelper] to store the list with the added [todosToAdd].
  List<Todo> addAll(Iterable<Todo> todosToAdd) {
    List<Todo> addedTodos = [];
    for (final todo in todosToAdd) {
      if (isTodoTitleVacant(todo.title)) {
        todos.add(todo);
        _setOrder(todo);
        todo.listScope = scope;
        addedTodos.add(todo);
      }
    }
    if (addedTodos.isNotEmpty) {
      unawaited(PersistenceHelper.saveList(this));
    }
    return addedTodos;
  }

  bool deleteTodo(Todo todo) {
    final isDeleted = todos.remove(todo);
    if (isDeleted) {
      unawaited(PersistenceHelper.saveList(this));
    }
    return isDeleted;
  }

  void deleteAll(Iterable<Todo> todosToDelete) {
    final int initialLength = todos.length;
    for (final todo in todosToDelete) {
      todos.remove(todo);
    }
    if (initialLength != todos.length) {
      unawaited(PersistenceHelper.saveList(this));
    }
  }

  void markAsDone(Todo todo) {
    final bool removed = todos.remove(todo);
    if (removed) {
      doneTodos.add(todo);
      todo.completionDate = DateTime.now();
      unawaited(PersistenceHelper.saveList(this));
    }
  }

  bool restoreTodo(Todo todo) {
    bool isRestorable = isTodoTitleVacant(todo.title);
    if (isRestorable) {
      todos.add(todo);
      doneTodos.remove(todo);
      todo.completionDate = null;
      unawaited(PersistenceHelper.saveList(this));
    }
    return isRestorable;
  }

  /// Updates a [Todo] by replacing the [oldTodo] with [newTodo].
  /// Returns true if replacement was successful, otherwise false.
  bool replaceTodo(Todo oldTodo, Todo newTodo) {
    bool isReplaced = false;
    if (todos.contains(oldTodo) && oldTodo != newTodo) {
      final indexOfOldTodo = todos.indexOf(oldTodo);
      todos.removeAt(indexOfOldTodo);
      if (isTodoTitleVacant(newTodo.title)) {
        todos.insert(indexOfOldTodo, newTodo);
        newTodo.order = oldTodo.order;
        newTodo.listScope = scope;
        isReplaced = true;
      } else {
        // restore old todo
        todos.insert(indexOfOldTodo, oldTodo);
      }
      if (isReplaced) {
        unawaited(PersistenceHelper.saveList(this));
      }
    }
    return isReplaced;
  }

  void reorder(Todo moved, Todo? previous) {
    if (!allTodos.contains(moved)) return;
    final lowerOrder = previous?.order ?? 0;
    final upperOrder = _findNextHigher(lowerOrder)?.order ?? lowerOrder + 2000;

    final difference = upperOrder - lowerOrder;
    if (difference <= 1) {
      _normalizeOrders();
      reorder(moved, previous);
      return;
    }
    moved.order = lowerOrder + difference ~/ 2;
  }

  Todo? _findNextHigher(int lowerOrder) {
    return allTodos.where((t) => (t.order ?? 0) > lowerOrder).fold<Todo?>(
      null,
      (previous, elem) {
        if (previous == null || previous.order! > elem.order!) {
          return elem;
        }
        return previous;
      },
    );
  }

  void _normalizeOrders() {
    final allTodos = [...todos, ...doneTodos]
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    _currentMaxOrder = 0;
    for (var i = 0; i < allTodos.length; i++) {
      allTodos[i].order = (i + 1) * 1000;
    }
    _currentMaxOrder = allTodos.isEmpty ? 0 : allTodos.last.order!;
  }

  /// Checks wether a [Todo] allready exists with the given [title].
  /// Returns true if the given [title] is not yet used, otherwise false.
  bool isTodoTitleVacant(String title) {
    return !todos.any((todo) => todo.title == title.trim());
  }

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TodoList && other.scope == scope;
  }

  @override
  int get hashCode => scope.hashCode;

  @override
  int compareTo(TodoList other) {
    // Backlog ist immer am Ende
    if (scope == ListScope.backlog) {
      return other.scope == ListScope.backlog ? 0 : 1;
    }
    if (other.scope == ListScope.backlog) return -1;

    // sonst nach Dauer sortieren
    return scope.duration.compareTo(other.scope.duration);
  }
}

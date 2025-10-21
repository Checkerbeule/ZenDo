import 'dart:async';

import 'package:hive/hive.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/persistance/persistence_helper.dart';

part 'todo_list.g.dart';

@HiveType(typeId: 1)
class TodoList implements Comparable<TodoList> {
  @HiveField(0)
  final ListScope scope;

  @HiveField(1)
  Set<Todo> todos = {};

  @HiveField(2)
  List<Todo> doneTodos = [];

  TodoList(this.scope);

  /// Adds the [todo] to the list.
  /// Calculates the expirationDate based on the ListScope.
  /// Uses [PersistenceHelper] to store the list with the added [todo]
  bool addTodo(Todo todo) {
    final bool added = todos.add(todo);
    if (added) {
      _setExpirationDate(todo);
      unawaited(PersistenceHelper.saveList(this));
    }
    return added;
  }

  /// Use this method to transferExpiredTodos with the [ListManager].
  /// Adds all [todosToAdd] to the list.
  /// Does not calculate the expirationDate.
  /// Uses [PersistenceHelper] to store the list with the added [todosToAdd].
  List<Todo> addAll(Iterable<Todo> todosToAdd) {
    List<Todo> addedTodos = [];
    for (final todo in todosToAdd) {
      if (todos.add(todo)) {
        addedTodos.add(todo);
      }
    }
    if (addedTodos.isNotEmpty) {
      unawaited(PersistenceHelper.saveList(this));
    }
    return addedTodos;
  }

  void deleteTodo(Todo todo) {
    final bool deleted = todos.remove(todo);
    if (deleted) {
      unawaited(PersistenceHelper.saveList(this));
    }
  }

  void deleteAll(Iterable<Todo> todosToDelete) {
    final int initialLength = todos.length;
    todos.removeAll(todosToDelete);
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
    bool inserted = todos.add(todo);
    if (inserted) {
      doneTodos.remove(todo);
      todo.completionDate = null;
      unawaited(PersistenceHelper.saveList(this));
    }
    return inserted;
  }

  int get doneCount {
    return doneTodos.length;
  }

  List<Todo> getExpiredTodos(Duration durationOfNextListScope) {
    return todos.where((todo) {
      return todo.expirationDate == null
          ? false
          : todo.toBeTransferred(durationOfNextListScope);
    }).toList();
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

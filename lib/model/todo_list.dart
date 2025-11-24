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
  List<Todo> todos = [];

  @HiveField(2)
  List<Todo> doneTodos = [];

  TodoList(this.scope);

  /// Adds the [todo] to the list.
  /// Calculates the expirationDate based on the ListScope.
  /// Uses [PersistenceHelper] to store the list with the added [todo]
  /// Returns true if the new [Todo] was successfully added.
  /// Returns false if there allready exists a [Todo] with same title.
  bool addTodo(Todo todo) {
    if (!todos.any((elem) => elem.title == todo.title)) {
      todos.add(todo);
      _setExpirationDate(todo);
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
      if (!todos.any((elem) => elem.title == todo.title)) {
        todos.add(todo);
        todo.listScope = scope;
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
    bool isRestored = !todos.any((elem) => elem.title == todo.title);
    if (isRestored) {
      todos.add(todo);
      doneTodos.remove(todo);
      todo.completionDate = null;
      unawaited(PersistenceHelper.saveList(this));
    }
    return isRestored;
  }

  /// Updates a [Todo] by replacing the [oldTodo] with [newTodo].
  /// Returns true if replacement was successful, otherwise false.
  bool replaceTodo(Todo oldTodo, Todo newTodo) {
    if (todos.contains(oldTodo) &&
        oldTodo != newTodo &&
        !todos.any((todo) => todo != oldTodo && todo.title == newTodo.title)) {
      final index = todos.indexOf(oldTodo);
      todos[index] = newTodo;

      unawaited(PersistenceHelper.saveList(this));
      return true;
    }

    return false;
  }

  int get doneCount {
    return doneTodos.length;
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

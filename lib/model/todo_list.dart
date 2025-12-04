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

  @HiveField(3)
  TodoList(this.scope);

  /// Adds the [todo] to the list.
  /// Calculates the expirationDate based on the ListScope.
  /// Uses [PersistenceHelper] to store the list with the added [todo]
  /// Returns true if the new [Todo] was successfully added.
  /// Returns false if there allready exists a [Todo] with same title.
  bool addTodo(Todo todo) {
    if (isTodoTitleVacant(todo.title)) {
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
      if (isTodoTitleVacant(todo.title)) {
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

  bool deleteTodo(Todo todo) {
    final bool deleted = todos.remove(todo);
    if (deleted) {
      unawaited(PersistenceHelper.saveList(this));
    }
    return deleted;
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

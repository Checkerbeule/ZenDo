import 'package:hive/hive.dart';
import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/persistance/persistance_helper.dart';

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

  bool addTodo(Todo todo) {
    final bool added = todos.add(todo);
    if (added) {
      PersistanceHelper.saveList(this);
    }
    return added;
  }

  List<Todo> addAll(Iterable<Todo> todosToAdd) {
    List<Todo> addedTodos = [];
    for (final todo in todosToAdd) {
      if (todos.add(todo)) {
        addedTodos.add(todo);
      }
    }
    if (addedTodos.isNotEmpty) {
      PersistanceHelper.saveList(this);
    }
    return addedTodos;
  }

  void deleteTodo(Todo todo) {
    final bool deleted = todos.remove(todo);
    if (deleted) {
      PersistanceHelper.saveList(this);
    }
  }

  void deleteAll(Iterable<Todo> todosToDelete) {
    final int initialLength = todos.length;
    todos.removeAll(todosToDelete);
    if (initialLength != todos.length) {
      PersistanceHelper.saveList(this);
    }
  }

  void markAsDone(Todo todo) {
    final bool removed = todos.remove(todo);
    if (removed) {
      doneTodos.add(todo);
      PersistanceHelper.saveList(this);
    }
  }

  bool restoreTodo(Todo todo) {
    bool inserted = todos.add(todo);
    if (inserted) {
      doneTodos.remove(todo);
      PersistanceHelper.saveList(this);
    }
    return inserted;
  }

  int get doneCount {
    return doneTodos.length;
  }

  List<Todo> get expiredTodos {
    final now = DateTime.now();
    return todos
        .where((todo) => now.difference(todo.creationDate) > scope.duration)
        .toList();
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

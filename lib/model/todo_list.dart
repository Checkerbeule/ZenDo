import 'package:zen_do/model/todo.dart';
import 'package:zen_do/model/todo_scope.dart';

class TodoList {
  final TodoScope scope;
  Set<Todo> todos = {};
  List<Todo> doneTodos = [];

  TodoList(this.scope);

  bool addTodo(Todo todo) {
    return todos.add(todo);
  }

  void deleteTodo(Todo todo) {
    todos.remove(todo);
  }

  void markAsDone(Todo todo) {
    todos.remove(todo);
    doneTodos.add(todo);
  }

  bool restoreTodo(Todo todo) {
    bool inserted = todos.add(todo);
    if (inserted) {
      doneTodos.remove(todo);
    }
    return inserted;
  }

  int get doneCount {
    return doneTodos.length;
  }

  List<Todo> get expiredTodos {
    final now = DateTime.now();
    return todos.where((todo) =>
       now.difference(todo.creationDate) > scope.duration
    ).toList();
  }

  void removeAllExpired() {
    todos.removeWhere((todo) => expiredTodos.contains(todo));
  }

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TodoList &&
      other.scope == scope;
  }
}
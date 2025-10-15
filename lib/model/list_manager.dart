import 'package:logger/logger.dart';
import 'package:zen_do/model/todo_list.dart';

Logger logger = Logger(level: Level.debug);

class ListManager {
  Set<TodoList> todoLists;

  ListManager(this.todoLists);

  void transferExpiredTodos() {
    // use only lists with enabled autotransfer
    final activeLists = todoLists.where((l) => l.scope.autoTransfer).toList();
    // sort by duration ascending
    activeLists.sort((a, b) => a.scope.duration.compareTo(b.scope.duration));

    for (int i = 1; i < activeLists.length; i++) {
      final currentList = activeLists[i];
      final previousList = activeLists[i - 1];

      final expiredTodos = currentList.expiredTodos;
      for (var todo in expiredTodos) {
        bool inserted = previousList.addTodo(todo);
        if (inserted) {
          currentList.deleteTodo(todo);
        } else {
          logger.d(
            'Todo ${todo.title} of list ${currentList.scope} could not be transfered to ${previousList.scope}! '
            'The list migth allready contain a Todo with that title.',
          );
        }
      }
    }
  }

  int get listCount {
    return todoLists.length;
  }

  Set<TodoList> get allLists {
    return todoLists;
  }

  bool removeList(TodoList list) {
    return todoLists.remove(list);
  }

  bool addList(TodoList list) {
    return todoLists.add(list);
  } 
}

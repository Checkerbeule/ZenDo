import 'package:logger/logger.dart';
import 'package:zen_do/model/todo_list.dart';

Logger logger = Logger(level: Level.debug);

class ListManager {
  List<TodoList> lists = [];

  ListManager(Iterable<TodoList> lists) {
    for(var l in lists) {
      if (!this.lists.contains(l)) {
        this.lists.add(l);
      } else {
        logger.d('List with scope ${l.scope} could not be added to ListManager because it is already contained!');
      }
    }
    this.lists.sort((a, b) => a.scope.duration.compareTo(b.scope.duration));
  }

  void transferExpiredTodos() {
    // use only lists with enabled autotransfer
    final activeLists = lists.where((l) => l.scope.autoTransfer).toList();
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
    return lists.length;
  }

  List<TodoList> get allLists {
    return lists;
  }

  bool removeList(TodoList list) {
    return lists.remove(list);
  }

  bool addList(TodoList list) {
    if (!lists.contains(list)) {
      lists.add(list);
      lists.sort((a, b) => a.scope.duration.compareTo(b.scope.duration));
      return true;
    }
    logger.d('List with scope ${list.scope} could not be added to ListManager because it is already contained!');
    return false;
  }
}

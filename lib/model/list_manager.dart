import 'package:logger/logger.dart';
import 'package:zen_do/model/todo_list.dart';

Logger logger = Logger(level: Level.debug);

class ListManager {
  final List<TodoList> _lists = [];

  ListManager(Iterable<TodoList> lists) {
    for (var l in lists) {
      if (!_lists.contains(l)) {
        _lists.add(l);
      } else {
        logger.d(
          'List with scope ${l.scope} could not be added to ListManager because it is already contained!',
        );
      }
    }
    _lists.sort((a, b) => a.compareTo(b));
  }

  void transferExpiredTodos() {
    // use only lists with enabled autotransfer
    final activeLists = _lists.where((l) => l.scope.autoTransfer).toList();
    // sort by duration ascending
    activeLists.sort((a, b) => a.compareTo(b));

    for (int i = activeLists.length; i > 0; i--) {
      final currentList = activeLists[i];
      final previousList = activeLists[i - 1];

      final expiredTodos = currentList.expiredTodos;
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

  int get listCount {
    return _lists.length;
  }

  List<TodoList> get allLists {
    return _lists;
  }

  bool removeList(TodoList list) {
    return _lists.remove(list);
  }

  bool addList(TodoList list) {
    if (!_lists.contains(list)) {
      _lists.add(list);
      _lists.sort((a, b) => a.compareTo(b));
      return true;
    }
    logger.d(
      'List with scope ${list.scope} could not be added to ListManager because it is already contained!',
    );
    return false;
  }
}

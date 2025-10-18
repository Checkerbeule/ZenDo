import 'package:hive/hive.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo_list.dart';

class PersistanceHelper {
  /// Saves a list of [TodoList] objects to the Hive box named 'todo_lists'.
  ///
  /// This method clears the existing contents of the box before saving the new lists.
  /// Each list is stored using its [scope.name] as the key.
  ///
  /// [lists]: The list of [TodoList] objects to save.
  static Future<void> saveAll(List<TodoList> lists) async {
    final box = await Hive.openBox<TodoList>('todo_lists');
    for (final list in lists) {
      await box.delete(list.scope.name);
      await box.put(list.scope.name, list);
    }
  }

  /// Saves a single [TodoList] object to the Hive box named 'todo_lists'.
  ///
  /// The list is stored using its [scope.name] as the key.
  ///
  /// [list]: The [TodoList] object to save.
  static Future<void> saveList(TodoList list) async {
    final box = await Hive.openBox<TodoList>('todo_lists');
    await box.delete(list.scope.name);
    await box.put(list.scope.name, list);
  }

  /// Loads all [TodoList] objects from the Hive box named 'todo_lists'.
  ///
  /// Iterates through all possible [ListScope] values and retrieves the corresponding lists.
  /// If a list for a specific scope does not exist, a new [TodoList] is created for that scope.
  static Future<List<TodoList>> loadAll() async {
    final box = await Hive.openBox<TodoList>('todo_lists');
    final lists = <TodoList>[];

    for (final scope in ListScope.values) {
      final list = box.get(scope.name);
      lists.add(list ?? TodoList(scope));
    }

    return lists;
  }

  /// Loads a [TodoList] from persistent storage for the given [scope].
  ///
  /// If a list for the specified [scope] exists in the Hive box, it is returned.
  /// Otherwise, a new [TodoList] is created, stored in the box, and returned.
  ///
  /// Returns a [Future] that completes with the loaded or newly created [TodoList].
  ///
  /// Throws any exceptions encountered during box access or data retrieval.
  static Future<TodoList> loadList(ListScope scope) async {
    final box = await Hive.openBox<TodoList>('todo_lists');
    final list = box.get(scope.name);

    if (list != null) {
      return list;
    } else {
      final newList = TodoList(scope);
      await box.put(scope.name, newList);
      return newList;
    }
  }
}

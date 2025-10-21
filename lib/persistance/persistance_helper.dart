import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo_list.dart';

class PersistanceHelper {
  static Logger logger = Logger(level: Level.debug);

  static HiveInterface hive = Hive;
  static Box<TodoList>? _listBox;

  // List of currently running save operations
  static final List<Future<void>> _pendingSaves = [];

  /// Generic helper to run any Hive write safely
  static Future<void> _runSafeWrite(Future<void> Function() action) async {
    final future = action();
    _pendingSaves.add(future);

    // Remove from tracking list when finished
    future.whenComplete(() => _pendingSaves.remove(future));

    return future;
  }

  /// Returns the Hive box for [TodoList] items.
  /// Opens the box if it's not yet opened or was closed.
  static Future<Box<TodoList>> _getListBox() async {
    if (_listBox == null || !_listBox!.isOpen) {
      _listBox = await hive.openBox<TodoList>('todo_lists');
    }
    return _listBox!;
  }

  /// Closes all open boxes.
  static Future<void> close() async {
    if (_pendingSaves.isNotEmpty) {
      logger.d(
        '[PersistenceHelper] Waiting for ${_pendingSaves.length} pending saves...',
      );
      await Future.wait(_pendingSaves);
    }

    if (_listBox?.isOpen ?? false) {
      logger.d('[PersistenceHelper] Closing Hive box...');
      await _listBox!.close();
      _listBox = null;
      logger.d('[PersistenceHelper] Hive closed.');
    }
  }

  /// Saves a list of [TodoList] objects to the Hive box named 'todo_lists'.
  ///
  /// This method clears the existing contents of the box before saving the new lists.
  /// Each list is stored using its [scope.name] as the key.
  ///
  /// [lists]: The list of [TodoList] objects to save.
  static Future<void> saveAll(List<TodoList> lists) async {
    await _runSafeWrite(() async {
      final box = await _getListBox();
      for (final list in lists) {
        await box.delete(list.scope.name);
        await box.put(list.scope.name, list);
      }
    });
  }

  /// Saves a single [TodoList] object to the Hive box named 'todo_lists'.
  ///
  /// The list is stored using its [scope.name] as the key.
  ///
  /// [list]: The [TodoList] object to save.
  static Future<void> saveList(TodoList list) async {
    await _runSafeWrite(() async {
      final box = await _getListBox();
      await box.delete(list.scope.name);
      await box.put(list.scope.name, list);
    });
  }

  /// Loads all [TodoList] objects from the Hive box named 'todo_lists'.
  ///
  /// Iterates through all possible [ListScope] values and retrieves the corresponding lists.
  /// If a list for a specific scope does not exist, a new [TodoList] is created for that scope.
  static Future<List<TodoList>> loadAll() async {
    final box = await _getListBox();
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
    final box = await _getListBox();
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

import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:synchronized/synchronized.dart';
import 'package:zen_do/model/list_scope.dart';
import 'package:zen_do/model/todo_list.dart';
import 'package:zen_do/persistance/file_lock_helper.dart';

class PersistenceHelper {
  static Logger logger = Logger(level: Level.debug);

  static HiveInterface hive = Hive;
  static Box<TodoList>? listBox;

  static final List<Future> _pendingOperations = [];
  static final _listLock = Lock();

  /// Returns the Hive box for [TodoList] items.
  /// Opens the box if it's not yet opened or was closed.
  static Future<Box<TodoList>> _getListBox() async {
    if (listBox == null || !listBox!.isOpen) {
      listBox = await hive.openBox<TodoList>('todo_lists');
    }
    return listBox!;
  }

  /// Closes all open boxes and releases the Lock.
  static Future<void> closeAndRelease() async {
    if (_pendingOperations.isNotEmpty) {
      logger.d(
        '[PersistenceHelper] Waiting for ${_pendingOperations.length} pending saves...',
      );
      await Future.wait(_pendingOperations);
    }

    try {
      if (listBox?.isOpen ?? false) {
        logger.d('[PersistenceHelper] Closing Hive boxes...');
        await listBox!.close();
        listBox = null;
        logger.d('[PersistenceHelper] all boxes closed.');
      }
    } catch (e, s) {
      logger.e('[PersistenceHelper] Error while closing Hive box: $e\n$s');
      rethrow;
    } finally {
      await FileLockHelper.instance.release(LockType.todoList);
    }
  }

  /// Helper to run all Hive operations on todo_list boxes safely.
  static Future<T> _runListOperationSafely<T>(
    Future<T> Function() action,
  ) async {
    return _listLock.synchronized(timeout: Duration(seconds: 2), () async {
      final acquired = await FileLockHelper.instance.acquire(LockType.todoList);
      if (!acquired) {
        throw Exception(
          '[PersisteneHelper] Could not access data because it is currently locked by another process!',
        );
      } else {
        Future? future;
        try {
          future = action();
          _pendingOperations.add(future);
          return await future;
        } catch (e, s) {
          logger.e('[PersisteneHelper] Hive operation failed: $e\n$s');
          rethrow;
        } finally {
          _pendingOperations.removeWhere((f) => f == future);
        }
      }
    });
  }

  /// Saves a list of [TodoList] objects to the Hive box named 'todo_lists'.
  ///
  /// This method clears the existing contents of the box before saving the new lists.
  /// Each list is stored using its [scope.name] as the key.
  ///
  /// [lists]: The list of [TodoList] objects to save.
  static Future<void> saveAll(List<TodoList> lists) async {
    await _runListOperationSafely(() async {
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
    await _runListOperationSafely(() async {
      final box = await _getListBox();
      await box.delete(list.scope.name);
      await box.put(list.scope.name, list);
    });
  }

  /// Loads all [TodoList] objects from the Hive box named 'todo_lists'.
  ///
  /// Iterates through all possible [ListScope] values and retrieves the corresponding lists.
  static Future<List<TodoList>> loadAll() async {
    return await _runListOperationSafely(() async {
      final box = await _getListBox();
      final lists = <TodoList>[];

      for (final scope in ListScope.values) {
        final list = box.get(scope.name);
        if (list != null) {
          lists.add(list);
        }
      }
      return lists;
    });
  }

  /// Loads a [TodoList] from persistent storage for the given [scope].
  ///
  /// If a list for the specified [scope] exists in the Hive box, it is returned.
  /// Otherwise, a new [TodoList] is created, stored in the box, and returned.
  ///
  /// Returns a [Future] that completes with the loaded [TodoList].
  ///
  /// Throws an exception if no list with the given scope exists.
  static Future<TodoList> loadList(ListScope scope) async {
    return await _runListOperationSafely(() async {
      final box = await _getListBox();
      final list = box.get(scope.name);

      if (list != null) {
        return list;
      } else {
        throw Exception(
          '[PersistenceHelper] loadList failed! List with scope $scope does not exist!',
        );
      }
    });
  }
}

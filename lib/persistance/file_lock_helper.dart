import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

abstract class ILockHelper {
  Future<bool> acquire(LockType lockType);
  Future<void> release(LockType lockType);
}

enum LockType { todoList() }

class FileLockHelper implements ILockHelper {
  static Logger logger = Logger(level: Level.debug);

  FileLockHelper._internal(); // private constructor
  static ILockHelper instance = FileLockHelper._internal(); // singleton

  bool _isLocked = false; //locked by this process

  static Future<File> _getLockFile(LockType lockType) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/${lockType.name}_lock');
  }

  /// Try to acquire the global Hive file lock for todo_list operations.
  /// Returns `true` if successful, `false` if another process holds the lock.
  @override
  Future<bool> acquire(LockType lockType) async {
    if (_isLocked) {
      return true; // if allready locked then don't try to lock again
    }

    final file = await _getLockFile(lockType);
    if (await file.exists()) {
      logger.d(
        '[FileLockHelper] Could not acquire Lock-file because it allready exists!',
      );
      return false; // Lock already held by another process
    }

    try {
      await file.create();
      _isLocked = true;
      logger.d('[FileLockHelper] Lock-file successfully created!');

      return true;
    } catch (e) {
      logger.e('[FileLockHelper] Could not acquire lock $lockType: $e');

      return false;
    }
  }

  /// Releases the Hive file lock if it exists.
  @override
  Future<void> release(LockType lockType) async {
    if (!_isLocked) return; //if not locked then don't try to release
    final file = await _getLockFile(lockType);
    try {
      if (await file.exists()) {
        await file.delete();
        _isLocked = false;
        logger.d('[FileLockHelper] Lock-file successfully released!');
      }
    } on PathNotFoundException {
      logger.w('[FileLockHelper] Lock-file allready deleted or inaccessible');
    } catch (e) {
      logger.e('[FileLockHelper] Could not release lock $lockType: $e');
    }
  }
}

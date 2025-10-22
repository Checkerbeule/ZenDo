import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class FileLockHelper {
  static Logger logger = Logger(level: Level.debug);

  static Future<File> _getLockFile(FileLockType lockType) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/${lockType.name}_lock');
  }

  /// Try to acquire the global Hive file lock for todo_list operations.
  /// Returns `true` if successful, `false` if another process holds the lock.
  static Future<bool> acquire(FileLockType lockType) async {
    final file = await _getLockFile(lockType);
    if (await file.exists()) {
      logger.d(
        '[FileLockHelper] Could not acquire Lock-file because it allready exists!',
      );

      return false; // Lock already held by another process
    }
    try {
      await file.create();
      logger.d('[FileLockHelper] Lock-file successfully created!');

      return true;
    } catch (e) {
      logger.e('[FileLockHelper] Could not acquire lock $lockType: $e');

      return false;
    }
  }

  /// Releases the Hive file lock if it exists.
  static Future<void> release(FileLockType lockType) async {
    final file = await _getLockFile(lockType);
    try {
      if (await file.exists()) {
        await file.delete();
        logger.d('[FileLockHelper] Lock-file successfully released!');
      }
    } on PathNotFoundException {
      logger.w('[FileLockHelper] Lock-file allready deleted or inaccessible');
    } catch (e) {
      logger.e('[FileLockHelper] Could not release lock $lockType: $e');
    }
  }
}

enum FileLockType { todoList() }

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
    // if allready locked then don't try to lock again
    if (_isLocked) return true;

    final file = await _getLockFile(lockType);
    final int currentPid = pid;

    try {
      await file.create(exclusive: true);
      _isLocked = true;

      final String metadata =
          "${DateTime.now().millisecondsSinceEpoch};$currentPid";
      await file.writeAsString(metadata);

      logger.d(
        '[FileLockHelper] Lock-file successfully acquired by PID: $currentPid',
      );
      return true;
    } on PathExistsException {
      return await _handleExistingLock(file);
    } on FileSystemException {
      if (await file.exists()) {
        return await _handleExistingLock(file);
      }
      rethrow;
    } catch (e) {
      logger.e('[FileLockHelper] Unexpected error: $e');
      return false;
    }
  }

  Future<bool> _handleExistingLock(File file) async {
    try {
      final content = await file.readAsString();
      final parts = content.split(';');
      if (parts.length < 2) return false;

      final int timestamp = int.parse(parts[0]);
      final int holdingPid = int.parse(parts[1]);

      final DateTime lockTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final Duration age = DateTime.now().difference(lockTime);

      // create new lock if older than 15 min.
      if (age > const Duration(minutes: 15)) {
        logger.w(
          '[FileLockHelper] Found outdated lock from PID $holdingPid (Age: ${age.inMinutes}min). Cleaning up...',
        );
        await file.delete();

        return await acquire(LockType.todoList);
      }

      logger.d(
        '[FileLockHelper] Active lock held by PID $holdingPid since ${age.inSeconds}s',
      );
      return false;
    } catch (e) {
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

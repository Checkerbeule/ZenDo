import 'package:drift/drift.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/syncable.dart';

mixin SmartDeleteMixin {
  AppDatabase get db;

  Future<void> smartDelete<T extends Table, D>({
    required TableInfo<T, D> table,
    required D entity,
  }) async {
    try {
      final dynamic e = entity;

      if ((e as dynamic).syncStatus == SyncStatus.localOnly) {
        await (db.delete(
          table,
        )..where((t) => (t as dynamic).uuid.equals(e.uuid))).go();
      } else {
        await (db.update(
          table,
        )..where((t) => (t as dynamic).uuid.equals(e.uuid))).write(
          RawValuesInsertable({
            'sync_status': Variable(SyncStatus.deleted.index),
            'updated_at': Variable(DateTime.now()),
          }),
        );
      }
    } on NoSuchMethodError catch (e) {
      throw ArgumentError(
        "Entity $D is not a Syncable. Sync fields missing: $e",
      );
    } on TypeError catch (e) {
      throw ArgumentError("Entity $D has wrong types on sync fields: $e");
    } catch (e) {
      rethrow;
    }
  }
}

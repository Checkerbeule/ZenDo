import 'package:drift/drift.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/syncable.dart';

mixin SmartDeleteMixin {
  AppDatabase get db;

  Future<void> smartDelete<T extends SyncableTable, D extends SyncableEntity>({
    required TableInfo<T, D> table,
    required D entity,
  }) async {
    try {
      if (entity.syncStatus == SyncStatus.localOnly) {
        await (db.delete(table)..where((t) => t.uuid.equals(entity.uuid))).go();
      } else {
        await (db.update(
          table,
        )..where((t) => t.uuid.equals(entity.uuid))).write(
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

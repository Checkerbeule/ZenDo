import 'package:drift/drift.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/cloudsync/smart_delete_mixin.dart';
import 'package:zen_do/core/persistence/cloudsync/syncable.dart';

abstract class TagRepository {
  Stream<List<Tag>> watchTags();
  Future<void> createTag({required String name, required int color});
  Future<bool> updateTag(Tag tag);
  Future<void> deleteTag(Tag tag);
}

class DriftTagRepository with SmartDeleteMixin implements TagRepository {
  @override
  final AppDatabase db;

  DriftTagRepository(this.db);

  /// Retreive all [Tag]s from the database as a stream.
  /// Ignores tags with a sync status of [SyncStatus.deleted].
  @override
  Stream<List<Tag>> watchTags() {
    return (db.select(db.tags)
          ..where((t) => t.syncStatus.isNotValue(SyncStatus.deleted.name))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.customOrder, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  @override
  Future<void> createTag({required String name, required int color}) async {
    await db.transaction(() async {
      final lastTag =
          await (db.select(db.tags)
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.customOrder,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();

      final String newOrder = FractionalIndexing.generateKeyBetween(
        lastTag?.customOrder,
        null,
      );

      return db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              name: name,
              color: color,
              customOrder: newOrder,
            ),
          );
    });
  }

  @override
  Future<bool> updateTag(Tag tag) {
    final newSyncStatus = tag.syncStatus == SyncStatus.localOnly
        ? SyncStatus.localOnly
        : SyncStatus.pending;
    return db
        .update(db.tags)
        .replace(
          tag.copyWith(syncStatus: newSyncStatus, updatedAt: DateTime.now()),
        );
  }

  /// Uses the SmartDeleteMixin to perform a smartDelete.
  /// This hard deletes the given [tag] entity if [SyncStatus.localOnly] is present.
  /// Soft delete is performed if the [tag] entity was synced with cloud (syncStatus != [SyncStatus.localOnly])
  @override
  Future<void> deleteTag(Tag tag) {
    return smartDelete(table: db.tags, entity: tag);
  }
}

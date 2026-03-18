import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/smart_delete_mixin.dart';
import 'package:zen_do/core/persistence/syncable.dart';

abstract class TagRepository {
  Stream<List<Tag>> watchTags();
  Future<int> createTag({required String name, required int color});
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
    return (db.select(
      db.tags,
    )..where((t) => t.syncStatus.isNotValue(SyncStatus.deleted.name))).watch();
  }

  @override
  Future<int> createTag({required String name, required int color}) {
    return db
        .into(db.tags)
        .insert(TagsCompanion.insert(name: name, color: color));
  }

  @override
  Future<bool> updateTag(Tag tag) {
    return db
        .update(db.tags)
        .replace(
          tag.copyWith(
            syncStatus: SyncStatus.pending,
            updatedAt: DateTime.now(),
          ),
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

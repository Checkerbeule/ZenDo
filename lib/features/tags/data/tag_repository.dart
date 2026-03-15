import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/syncable.dart';

abstract class TagRepository {
  Stream<List<Tag>> watchTags();
  Future<int> createTag({required String name, required int color});
  Future<bool> updateTag(Tag tag);
  Future<void> softDeleteTag(Tag tag);
  Future<void> hardDeleteTag(Tag tag);
}

class DriftTagRepository implements TagRepository {
  final AppDatabase db;

  DriftTagRepository(this.db);

  /// Retreive all [Tag]s from the database as a stream.
  /// Ignores tags with a sync status of [SyncStatus.deleted].
  @override
  Stream<List<Tag>> watchTags() {
    return (db.select(
      db.tags,
    )..where((t) => t.syncStatus.isNotValue(SyncStatus.deleted.index))).watch();
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

  /// Performs a soft delete by setting the [SyncStatus] to [SyncStatus.deleted] and updating the [updatedAt] timestamp.
  @override
  Future<void> softDeleteTag(Tag tag) {
    return db
        .update(db.tags)
        .replace(
          tag.copyWith(
            syncStatus: SyncStatus.deleted,
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// Performs a hard delete by removing the tag from the database permanently.
  @override
  Future<void> hardDeleteTag(Tag tag) {
    return (db.delete(db.tags)..where((t) => t.id.equals(tag.id))).go();
  }
}

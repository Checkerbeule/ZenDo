import 'package:drift/drift.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:zen_do/core/persistence/app_database.dart';

class TagRepository {
  final AppDatabase db;

  TagRepository(this.db);

  Future<void> create({
    required String uuid,
    required String name,
    required int color,
  }) async {
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
              uuid: uuid,
              name: name,
              color: color,
              customOrder: newOrder,
            ),
          );
    });
  }

  Future<List<Tag>> readAll() {
    return (db.select(db.tags).join([
            innerJoin(db.entities, db.entities.uuid.equalsExp(db.tags.uuid)),
          ])
          ..where(db.entities.isDeleted.equals(false))
          ..orderBy([OrderingTerm.asc(db.tags.customOrder)]))
        .get()
        .then((rows) => rows.map((row) => row.readTable(db.tags)).toList());
  }

  /// Retreive all [Tag]s from the database as a stream.
  /// Ignores tags with a sync status of [SyncStatus.deleted].
  Stream<List<Tag>> watchAll() {
    return (db.select(db.tags).join([
            innerJoin(db.entities, db.entities.uuid.equalsExp(db.tags.uuid)),
          ])
          ..where(db.entities.isDeleted.equals(false))
          ..orderBy([OrderingTerm.asc(db.tags.customOrder)]))
        .watch()
        .map((rows) => rows.map((row) => row.readTable(db.tags)).toList());
  }

  Future<bool> update(Tag tag) {
    return db.update(db.tags).replace(tag);
  }
}

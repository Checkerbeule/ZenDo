import 'package:drift/drift.dart';
import 'package:zen_do/core/persistence/app_database.dart';

class TodoTagsRepository {
  final AppDatabase db;

  TodoTagsRepository(this.db);

  /// Adds all tags to the given todo.
  Future<void> addAllTagsToTodo({
    required String todoUuid,
    required Set<String> tagUuids,
  }) async {
    if (tagUuids.isEmpty) return;

    await db.batch((batch) async {
      for (final tagUuid in tagUuids) {
        batch.insert(
          db.todoTags,
          TodoTagsCompanion.insert(todo: todoUuid, tag: tagUuid),
        );
      }
    });
  }

  /// Removes all tags from the given todo.
  Future<int> removeAllTagsFromTodo(String todoUuid) async {
    return await (db.delete(
      db.todoTags,
    )..where((todoTags) => todoTags.todo.equals(todoUuid))).go();
  }

  /// Adds a single tag to the given todo.
  Future<int> addTagToTodo({
    required String todoUuid,
    required String tagUuid,
  }) async {
    return await db
        .into(db.todoTags)
        .insert(TodoTagsCompanion.insert(todo: todoUuid, tag: tagUuid));
  }

  /// Removes a single tag from the given todo.
  Future<int> removeTagFromTodo({
    required String todoUuid,
    required String tagUuid,
  }) async {
    return await (db.delete(db.todoTags)..where(
          (todoTags) =>
              todoTags.todo.equals(todoUuid) & todoTags.tag.equals(tagUuid),
        ))
        .go();
  }

  /// Updates all linked tags on the given todo.<br>
  /// Removes linked tags, that are not present in [newTagUuids].<br>
  /// Adds all new tags with the todo, that are yet not linked.
  Future<int> updateTags({
    required String todoUuid,
    required Set<String> newTagUuids,
  }) async {
    return await db.transaction(() async {
      final existing = await (db.select(
        db.todoTags,
      )..where((t) => t.todo.equals(todoUuid))).get();

      final existingUuids = existing.map((e) => e.tag).toSet();

      final toDelete = existingUuids.difference(newTagUuids);
      final toInsert = newTagUuids.difference(existingUuids);

      int updates = 0;
      if (toDelete.isNotEmpty) {
        updates =
            await (db.delete(db.todoTags)..where(
                  (t) =>
                      t.todo.equals(todoUuid) & t.tag.isIn(toDelete.toList()),
                ))
                .go();
      }

      if (toInsert.isNotEmpty) {
        updates += toInsert.length;
        await db.batch(
          (b) => b.insertAll(db.todoTags, [
            for (final tagUuid in toInsert)
              TodoTagsCompanion.insert(todo: todoUuid, tag: tagUuid),
          ]),
        );
      }
      return updates;
    });
  }

  /// Loads all tags, that are linked with the given todo.<br>
  /// Orders loades tags by custom order ascending.<br>
  /// Note: Only loads tags that are NOT marked as deleted.
  Future<List<Tag>> readTagsFromTodo(String todoUuid) async {
    final query = (db.select(db.tags).join([
      innerJoin(db.entities, db.entities.uuid.equalsExp(db.tags.uuid)),
      leftOuterJoin(db.todoTags, db.todoTags.todo.equalsExp(db.tags.uuid)),
    ]));
    query.where(db.entities.isDeleted.equals(false));

    final subQuery = db.selectOnly(db.todoTags)
      ..addColumns([db.todoTags.tag])
      ..where(db.todoTags.todo.equals(todoUuid));
    query.where(db.tags.uuid.isInQuery(subQuery));

    query.orderBy([OrderingTerm.asc(db.tags.customOrder)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(db.tags)).toList();
  }
}

import 'package:drift/drift.dart';
import 'package:zen_do/core/persistence/app_database.dart';

class TodoTagsRepository {
  final AppDatabase db;

  TodoTagsRepository(this.db);

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

  Future<int> removeAllTagsFromTodo(String todoUuid) async {
    return await (db.delete(
      db.todoTags,
    )..where((todoTags) => todoTags.todo.equals(todoUuid))).go();
  }

  Future<int> addTagToTodo({
    required String todoUuid,
    required String tagUuid,
  }) async {
    return await db
        .into(db.todoTags)
        .insert(TodoTagsCompanion.insert(todo: todoUuid, tag: tagUuid));
  }

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

  Future<int> updateTags(String todoUuid, Set<String> newTagUuids) async {
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

  Future<List<Tag>> readTagsFromTodo(String todoUuid) async {
    final query = (db.select(db.tags).join([
      leftOuterJoin(db.todoTags, db.todoTags.todo.equalsExp(db.tags.uuid)),
    ]));

    final subQuery = db.selectOnly(db.todoTags)
      ..addColumns([db.todoTags.tag])
      ..where(db.todoTags.todo.equals(todoUuid));

    query.where(db.tags.uuid.isInQuery(subQuery));

    final rows = await query.get();
    return rows.map((row) => row.readTable(db.tags)).toList();
  }
}

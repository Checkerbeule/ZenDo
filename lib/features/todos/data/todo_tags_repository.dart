import 'package:drift/drift.dart';
import 'package:zen_do/core/persistence/app_database.dart';

class TodoTagsRepository {
  final AppDatabase db;

  TodoTagsRepository({required this.db});

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
}

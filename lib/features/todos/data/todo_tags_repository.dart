import 'package:zen_do/core/persistence/app_database.dart';

class TodoTagsRepository {
  final AppDatabase db;

  TodoTagsRepository({required this.db});

  Future<void> addAllTagsToTodo({
    required String todoUuid,
    required List<String> tagUuids,
  }) async {
    await db.batch((batch) async {
      for (final tagUuid in tagUuids) {
        batch.insert(
          db.todoTags,
          TodoTagsCompanion.insert(todo: todoUuid, tag: tagUuid),
        );
      }
    });
  }

  Future<int> addTagToTodo({
    required String todoUuid,
    required String tagUuid,
  }) async {
    return await db
        .into(db.todoTags)
        .insert(TodoTagsCompanion.insert(todo: todoUuid, tag: tagUuid));
  }
}

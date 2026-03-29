import 'package:drift/drift.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';

class TodoRepository {
  final AppDatabase db;

  TodoRepository(this.db);

  Future<Todo> create({
    required String uuid,
    required String title,
    required ListScope scope,
    DateTime? expiresAt,
    String? description,
  }) async {
    return await db.transaction(() async {
      final lastTodo =
          await (db.select(db.todos)
                ..where((todo) => todo.scope.equalsValue(scope))
                ..orderBy([(todo) => OrderingTerm.desc(todo.customOrder)])
                ..limit(1))
              .getSingleOrNull();

      final newOrder = FractionalIndexing.generateKeyBetween(
        lastTodo?.customOrder,
        null,
      );

      return await (db
          .into(db.todos)
          .insertReturning(
            TodosCompanion.insert(
              uuid: uuid,
              title: title,
              scope: scope,
              customOrder: newOrder,
              expiresAt: Value(expiresAt),
              description: Value(description),
            ),
          ));
    });
  }
}

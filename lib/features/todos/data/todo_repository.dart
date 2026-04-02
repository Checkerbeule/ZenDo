import 'package:drift/drift.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/domain/todo_dto.dart';
import 'package:zen_do/features/todos/domain/todo_sort_option.dart';

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

  Future<Todo?> read(String uuid) async {
    return await (db.select(
      db.todos,
    )..where((todo) => todo.uuid.equals(uuid))).getSingleOrNull();
  }

  Stream<List<TodoDto>> watchAllByScope({
    required ListScope scope,
    required bool isCompleted,
    TodoSortOption? sortOption,
    SortOrder? sortOrder,
    Set<String>? tagUuidsFilter,
  }) {
    final query = db.select(db.todos).join([
      innerJoin(db.entities, db.entities.uuid.equalsExp(db.todos.uuid)),
      leftOuterJoin(db.todoTags, db.todoTags.todo.equalsExp(db.todos.uuid)),
      leftOuterJoin(db.tags, db.tags.uuid.equalsExp(db.todoTags.tag)),
    ]);

    query.where(
      db.entities.isDeleted.equals(false) &
          db.todos.scope.equalsValue(scope) &
          (isCompleted
              ? db.todos.completedAt.isNotNull()
              : db.todos.completedAt.isNull()),
    );

    if (tagUuidsFilter != null && tagUuidsFilter.isNotEmpty) {
      final subquery = db.selectOnly(db.todoTags)
        ..addColumns([db.todoTags.todo])
        ..where(db.todoTags.tag.isIn(tagUuidsFilter));

      query.where(db.todos.uuid.isInQuery(subquery));
    }

    query.orderBy([_generateOrderingTerm(sortOption, sortOrder)]);

    return query.watch().map((rows) {
      final todoMap = <String, ({Todo todo, Entity entity})>{};
      final tagMap = <String, Set<String>>{};

      for (final row in rows) {
        final entity = row.readTable(db.entities);
        final todo = row.readTable(db.todos);
        final tag = row.readTableOrNull(db.tags);

        todoMap.putIfAbsent(todo.uuid, () => (todo: todo, entity: entity));
        if (tag != null) {
          tagMap.putIfAbsent(todo.uuid, () => {}).add(tag.uuid);
        }
      }

      return todoMap.entries.map((entry) {
        final todoWithMeta = entry.value;
        final tagUuids = tagMap[entry.key] ?? {};

        return TodoDto.fromDb(
          todo: todoWithMeta.todo,
          entity: todoWithMeta.entity,
          tagUuids: tagUuids,
        );
      }).toList();
    });
  }

  Future<int> update(TodosCompanion todo) async {
    return await (db.update(db.todos)..whereSamePrimaryKey(todo)).write(todo);
  }

  OrderingTerm _generateOrderingTerm(
    TodoSortOption? sortOption,
    SortOrder? sortOrder,
  ) {
    final Expression orderingExpr = switch (sortOption) {
      TodoSortOption.custom => db.todos.customOrder,
      TodoSortOption.title => db.todos.title,
      TodoSortOption.expirationDate => db.todos.expiresAt,
      TodoSortOption.creationDate => db.entities.createdAt,
      TodoSortOption.completionDate => db.todos.completedAt,
      null => db.todos.customOrder,
    };

    final OrderingMode orderingMode = sortOrder?.toDrift ?? OrderingMode.asc;

    return OrderingTerm(expression: orderingExpr, mode: orderingMode);
  }
}

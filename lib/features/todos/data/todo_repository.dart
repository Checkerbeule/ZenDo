import 'package:drift/drift.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';
import 'package:zen_do/features/todos/domain/todo_dto.dart';
import 'package:zen_do/features/todos/domain/todo_sort_option.dart';

class TodoRepository {
  final AppDatabase db;

  TodoRepository(this.db);

  /// Creates a new todo with the given attributes.<br>
  /// Generates a new fractional index (customOrder),
  /// so the new todo is placed at last position in a list of all todos.<br>
  /// Returns the created todo.
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

  /// Loads the todo with the given [uuid].<br>
  /// Returns null if no todo with the given [uuid] was found.<br>
  /// Note: Also loads todos, that are marked as deleted.
  Future<Todo?> read(String uuid) async {
    return await (db.select(
      db.todos,
    )..where((todo) => todo.uuid.equals(uuid))).getSingleOrNull();
  }

  /// Loads all open todos that match the given set of [scopes].<br>
  /// Use this method to load all todos for the transfer algorythm.<br>
  /// Note: todos marked as deleted will be ignored.
  Future<List<Todo>> readAllOpenByScopes(Set<ListScope> scopes) async {
    final scopeNames = scopes.map((scope) => scope.name);
    final results =
        await (db.select(db.todos).join([
              innerJoin(db.entities, db.entities.uuid.equalsExp(db.todos.uuid)),
            ])..where(
              db.entities.isDeleted.equals(false) &
                  db.todos.completedAt.isNull() &
                  db.todos.scope.isIn(scopeNames),
            ))
            .get();

    return results.map((row) => row.readTable(db.todos)).toList();
  }

  /// Returns a reacive stream of all todos with a given [scope].<br>
  /// Loads todos, that are still open if [isCompleted] is 'false'.
  /// Loads todos, that allready done if [isCompleted] is 'true'.<br>
  /// Returns a streamed List of [TodoDto]s with populated metadata and associated tags.
  /// Tags are only include if not marked as deleted<br>
  /// If [taguudsFilter] is provided, it filters the list of todos to match any of the given tag uuids.<br>
  /// If [sortOption] is provided, it orders the list by the given option.
  /// By default it orders the list by 'customOrder' ascending.
  /// If [sortOrder] is provided, it orders the list accordingly.
  /// Note: Only loads todos, that are NOT marked as deleted.
  Stream<List<TodoDto>> watchDtosByScope({
    required ListScope scope,
    required bool isCompleted,
    TodoSortOption? sortOption,
    SortOrder? sortOrder,
    Set<String>? tagUuidsFilter,
  }) {
    final tagEntities = db.alias(db.entities, 'tag_entities');
    final query = db.select(db.todos).join([
      innerJoin(db.entities, db.entities.uuid.equalsExp(db.todos.uuid)),
      leftOuterJoin(db.todoTags, db.todoTags.todo.equalsExp(db.todos.uuid)),
      leftOuterJoin(db.tags, db.tags.uuid.equalsExp(db.todoTags.tag)),
      leftOuterJoin(tagEntities, tagEntities.uuid.equalsExp(db.tags.uuid)),
    ]);

    query.where(
      db.entities.isDeleted.equals(false) &
          db.todos.scope.equalsValue(scope) &
          (isCompleted
              ? db.todos.completedAt.isNotNull()
              : db.todos.completedAt.isNull()) &
          (tagEntities.isDeleted.isNull() |
              tagEntities.isDeleted.equals(false)),
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

  /// Returns a reacive stream of all open todos with a given [scope].<br>
  /// Note: Only retreives the [Todo] enitties without metda and associated tags,
  /// not the whole [TodoDto].
  Stream<List<Todo>> watchAllOpenByScope(ListScope scope) {
    final query = db.select(db.todos).join([
      innerJoin(db.entities, db.entities.uuid.equalsExp(db.todos.uuid)),
    ]);

    query.where(
      db.entities.isDeleted.equals(false) &
          db.todos.completedAt.isNull() &
          db.todos.scope.equals(scope.name),
    );

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(db.todos)).toList(),
    );
  }

  /// Updates the given [todo] by replacing all present attributes.
  Future<bool> updateDto(TodoDto todo) async {
    return await db.update(db.todos).replace(_fromDto(todo));
  }

  /// Updates the given [todo] by replacing all present attributes.
  Future<bool> update(Todo todo) async {
    return await db.update(db.todos).replace(todo.toCompanion(false));
  }

  Future<int> markAsCompleted(String uuid) async {
    return await (db.update(db.todos)..where((todo) => todo.uuid.equals(uuid)))
        .write(TodosCompanion(completedAt: Value(DateTime.now())));
  }

  Future<int> restore(String uuid) async {
    return await (db.update(db.todos)..where((todo) => todo.uuid.equals(uuid)))
        .write(TodosCompanion(completedAt: Value(null)));
  }

  Stream<int> watchExpiredCount(Set<ListScope> activeScopes) {
    // TODO move active list scope settings to drift DB and select expiredCount via join on settings table
    final scopeNames = activeScopes.map((scope) => scope.name);
    final query = db.selectOnly(db.todos).join([
      innerJoin(db.entities, db.entities.uuid.equalsExp(db.todos.uuid)),
    ]);

    final now = DateTime.now();
    query.where(
      db.entities.isDeleted.equals(false) &
          db.todos.completedAt.isNull() &
          db.todos.expiresAt.isSmallerOrEqualValue(now) &
          db.todos.scope.isIn(scopeNames),
    );

    return (query..addColumns([countAll()])).watchSingle().map(
      (row) => row.read<int>(countAll()) ?? 0,
    );
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

  TodosCompanion _fromDto(TodoDto dto) {
    return TodosCompanion(
      uuid: Value(dto.uuid),
      scope: Value(dto.scope),
      title: Value(dto.title),
      description: Value(dto.description),
      customOrder: Value(dto.customOrder),
      completedAt: Value(dto.completedAt),
      expiresAt: Value(dto.expiresAt),
    );
  }
}

import 'package:drift/drift.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/features/todos/data/hive_todo.dart';
import 'package:zen_do/features/todos/data/todo_list.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';

class HiveToDriftMigrationService {
  final AppDatabase db;
  late final Box hiveBox;

  HiveToDriftMigrationService(this.db);

  Future<void> migrate() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('was_migrated_to_drift') ?? false) {
      logger.i("Migration from Hive to Drfit has allready been done!");
      return;
    }

    logger.i('Start migration from Hive to Drift ...');

    await db.transaction(() async {
      List<TodoList> hiveLists = await _loadHiveData();

      final existingTags = await db.select(db.tags).get();
      final existingTagUuids = existingTags.map((t) => t.uuid).toSet();

      await db.batch((batch) {
        for (final list in hiveLists) {
          final sortedTodos = List<HiveTodo>.from(list.allTodos);
          sortedTodos.sort((a, b) => (a.order ?? -1).compareTo(b.order ?? -1));

          logger.i(
            "Inserting ${list.allTodos.length} todos from hive list '${list.scope.name}' to Drift ...",
          );

          String lastOrder = 'a0';
          for (final todo in list.allTodos) {
            _createTodo(batch, todo, list.scope.name, lastOrder);
            lastOrder = FractionalIndexing.generateKeyBetween(lastOrder, null);

            _linkTags(batch, todo, existingTagUuids);
          }
        }
      });

      //logger.i("Deleting Hive boxes ...");
      //hiveBox.deleteFromDisk();
      hiveBox.close();
    });

    await prefs.setBool('was_migrated_to_drift', true);
    logger.i("Migration to Drift successfully finished!");
  }

  Future<List<TodoList>> _loadHiveData() async {
    hiveBox = await Hive.openBox<TodoList>('todo_lists');
    final Set<String> oldListScopeNames = {
      'daily',
      'weekly',
      'monthly',
      'yearly',
      'backlog',
    };

    final hiveLists = <TodoList>[];
    for (final scope in oldListScopeNames) {
      final list = hiveBox.get(scope);
      if (list != null) {
        hiveLists.add(list);
        logger.i("Retreived list with scope $scope from Hive.");
      }
    }

    logger.i("Retreived ${hiveLists.length} todo-lists from Hive");
    return hiveLists;
  }

  void _createTodo(
    Batch batch,
    HiveTodo todo,
    String scopeOfList,
    String lastOrder,
  ) {
    final now = DateTime.now().toUtc();
    batch.insert(
      mode: InsertMode.insertOrIgnore,
      db.entities,
      EntitiesCompanion(
        uuid: Value(todo.id),
        type: Value(EntityType.todo),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: Value(false),
      ),
    );

    batch.insert(
      mode: InsertMode.insertOrIgnore,
      db.todos,
      TodosCompanion(
        uuid: Value(todo.id),
        title: Value(todo.title),
        description: Value(todo.description),
        scope: Value(
          ListScope.fromLegacyName(todo.listScope?.name ?? scopeOfList),
        ),
        expiresAt: Value(todo.expirationDate),
        completedAt: Value(todo.completionDate),
        customOrder: Value(lastOrder),
      ),
    );
  }

  void _linkTags(Batch batch, HiveTodo todo, Iterable<String> existingTags) {
    for (final tag in todo.tagUuids) {
      if (existingTags.contains(tag)) {
        batch.insert(
          mode: InsertMode.insertOrIgnore,
          db.todoTags,
          TodoTagsCompanion(todo: Value(todo.id), tag: Value(tag)),
        );
      } else {
        logger.i(
          "Todo tag relation could not be set. Tag with id $tag does not exist",
        );
      }
    }
  }
}

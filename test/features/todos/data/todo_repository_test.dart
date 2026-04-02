import 'package:async/async.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:zen_do/core/domain/sort_order.dart';
import 'package:zen_do/core/persistence/app_database.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/core/persistence/entity_repository.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';
import 'package:zen_do/features/todos/data/todo_repository.dart';
import 'package:zen_do/features/todos/domain/todo_sort_option.dart';

void main() {
  late AppDatabase db;
  late TodoRepository todoRepo;
  late EntityRepository entityRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    todoRepo = TodoRepository(db);
    entityRepo = EntityRepository(db);
  });

  tearDown(() {
    db.close();
  });

  group('TodoRepository create tests', () {
    test('TodoRepository create todo successfully', () async {
      final title = 'Title';
      final description = 'Desc';
      final expirationDate = DateTime.now();

      final todo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity entity,
      ) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: title,
          description: description,
          scope: ListScope.daily,
          expiresAt: expirationDate,
        );
      });

      expect(todo.uuid, isNotNull);
      expect(todo.uuid, isNotEmpty);
      expect(todo.title, title);
      expect(todo.description, description);
      expect(todo.scope, ListScope.daily);
      expect(todo.expiresAt, expirationDate);
      expect(todo.customOrder, 'a0');
      expect(todo.completedAt, isNull);
    });

    test(
      'TodoRepository create todo generates correct fractional index',
      () async {
        final todo_1 = await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Todo 1',
            scope: ListScope.daily,
          );
        });

        final todo_2 = await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Todo 1',
            scope: ListScope.daily,
          );
        });

        expect(todo_1.uuid, isNotNull);
        expect(todo_1.uuid, isNotEmpty);
        expect(todo_1.scope, ListScope.daily);
        expect(todo_1.customOrder, 'a0');
        expect(todo_1.completedAt, isNull);

        expect(todo_2.customOrder, 'a1');
      },
    );
  });

  group('TodoRepository read tests', () {
    test('TodoRepository read single todo successfully', () async {
      final title = 'Title';
      final description = 'Desc';
      final expirationDate = DateTime.now();

      final createdTodo = await entityRepo.createWithEntity(EntityType.todo, (
        Entity entity,
      ) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: title,
          description: description,
          scope: ListScope.daily,
          expiresAt: expirationDate,
        );
      });

      final todo = await todoRepo.read(createdTodo.uuid);

      expect(todo, isNotNull);
      expect(todo!.uuid, isNotNull);
      expect(todo.uuid, isNotEmpty);
      expect(todo.title, title);
      expect(todo.description, description);
      expect(todo.scope, ListScope.daily);
      expect(todo.expiresAt, expirationDate);
      expect(todo.customOrder, 'a0');
      expect(todo.completedAt, isNull);
    });

    test('TodoRepository watchAllByScope successfully', () async {
      for (int i = 0; i < 5; i++) {
        await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Daily todo $i',
            scope: ListScope.daily,
          );
        });
      }
      for (int i = 0; i < 5; i++) {
        await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Weekly todo $i',
            scope: ListScope.weekly,
          );
        });
      }
      for (int i = 0; i < 5; i++) {
        await entityRepo.createWithEntity(EntityType.todo, (
          Entity entity,
        ) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Backlog todo $i',
            scope: ListScope.backlog,
          );
        });
      }

      final dailyTodos = await todoRepo
          .watchAllByScope(scope: ListScope.daily, isCompleted: false)
          .first;
      final weeklyTodos = await todoRepo
          .watchAllByScope(scope: ListScope.weekly, isCompleted: false)
          .first;
      final backlogTodos = await todoRepo
          .watchAllByScope(scope: ListScope.backlog, isCompleted: false)
          .first;

      expect(dailyTodos.length, 5);
      expect(weeklyTodos.length, 5);
      expect(backlogTodos.length, 5);
      for (final todo in dailyTodos) {
        expect(todo.scope, ListScope.daily);
      }
      for (final todo in weeklyTodos) {
        expect(todo.scope, ListScope.weekly);
      }
      for (final todo in backlogTodos) {
        expect(todo.scope, ListScope.backlog);
      }
    });

    test('TodoRepository watchAllByScope with ordering successful', () async {
      await entityRepo.createWithEntity(EntityType.todo, (Entity entity) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'B Todo',
          scope: ListScope.daily,
        );
      });
      await entityRepo.createWithEntity(EntityType.todo, (Entity entity) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'A Todo',
          scope: ListScope.daily,
        );
      });
      await entityRepo.createWithEntity(EntityType.todo, (Entity entity) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'C Todo',
          scope: ListScope.daily,
        );
      });

      final ascList = await todoRepo
          .watchAllByScope(
            scope: ListScope.daily,
            isCompleted: false,
            sortOption: TodoSortOption.title,
            sortOrder: SortOrder.ascending,
          )
          .first;
      final descList = await todoRepo
          .watchAllByScope(
            scope: ListScope.daily,
            isCompleted: false,
            sortOption: TodoSortOption.title,
            sortOrder: SortOrder.descending,
          )
          .first;

      expect(ascList.length, 3);
      expect(ascList.first.title, 'A Todo');
      expect(ascList[1].title, 'B Todo');
      expect(ascList.last.title, 'C Todo');
      expect(descList.length, 3);
      expect(descList.first.title, 'C Todo');
      expect(descList[1].title, 'B Todo');
      expect(descList.last.title, 'A Todo');
    });

    test('TodoRepository watchAllByScope with ordering successful', () async {
      final todoStream = todoRepo.watchAllByScope(
        scope: ListScope.daily,
        isCompleted: false,
      );
      final queue = StreamQueue(todoStream);

      expect(await queue.next, isEmpty);

      await entityRepo.createWithEntity(EntityType.todo, (Entity entity) async {
        return await todoRepo.create(
          uuid: entity.uuid,
          title: 'New todo',
          scope: ListScope.daily,
        );
      });

      expect(await queue.next, hasLength(1));

      queue.cancel();
    });
  });

  group('TodoRepository update tests', () {
    test('TodoRepository update successfuly', () async {
      final Todo initialTodo = await entityRepo.createWithEntity(
        EntityType.todo,
        (Entity entity) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Todo',
            scope: ListScope.daily,
          );
        },
      );
      final now = DateTime.now().toUtc();
      final todoToUpdate = initialTodo.copyWith(
        title: 'New title',
        description: Value('Desc'),
        scope: ListScope.yearly,
        completedAt: Value(now),
        customOrder: 'a2',
      );

      todoRepo.update(todoToUpdate.toCompanion(true));
      final updatedTodo = await todoRepo.read(todoToUpdate.uuid);

      expect(updatedTodo, isNotNull);
      expect(updatedTodo!.title, 'New title');
      expect(updatedTodo.description, 'Desc');
      expect(updatedTodo.scope, ListScope.yearly);
      expect(updatedTodo.completedAt, now);
      expect(updatedTodo.customOrder, 'a2');
    });

    test('TodoRepository update set values to null successfully', () async {
      final Todo initialTodo = await entityRepo.createWithEntity(
        EntityType.todo,
        (Entity entity) async {
          return await todoRepo.create(
            uuid: entity.uuid,
            title: 'Todo',
            description: 'Desc',
            scope: ListScope.daily,
            expiresAt: DateTime.now().toUtc(),
          );
        },
      );
      final todoToUpdate = initialTodo
          .toCompanion(true)
          .copyWith(
            title: Value('New title'),
            description: Value(null),
            scope: Value(ListScope.backlog),
            expiresAt: Value(null),
          );

      final updated = await todoRepo.update(todoToUpdate);
      final updatedTodo = await todoRepo.read(todoToUpdate.uuid.value);

      expect(updated, 1);
      expect(updatedTodo, isNotNull);
      expect(updatedTodo!.title, 'New title');
      expect(updatedTodo.description, isNull);
      expect(updatedTodo.scope, ListScope.backlog);
      expect(updatedTodo.expiresAt, isNull);
    });

    test('TodoRepository update on non existing todo fails', () async {
      final nonExistinTodo = Todo(
        uuid: Uuid().v4(),
        title: 'Not existing todo',
        scope: ListScope.daily,
        customOrder: 'a0',
      );

      final updated = await todoRepo.update(nonExistinTodo.toCompanion(true));
      final updatedTodo = await todoRepo.read(nonExistinTodo.uuid);

      expect(updated, 0);
      expect(updatedTodo, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zen_do/features/todos/domain/list_scope.dart';
import 'package:zen_do/features/todos/data/hive_todo.dart';

void main() {
  group('Todo expirationDate tests', () {
    test('Todo expirationDate: null value returns false', () {
      final todo = HiveTodo(title: 'Todo without expirationDate');

      expect(todo.expirationDate, isNull);
      expect(todo.isExpired, false);
    });

    test('Todo expirationDate: future expirationDate returns false', () {
      final todo = HiveTodo(title: 'Todo with future expirationDate');
      todo.expirationDate = DateTime.now().add(Duration(days: 1));

      expect(todo.expirationDate, isNotNull);
      expect(todo.isExpired, false);
    });

    test('Todo expirationDate: past expirationDate returns true', () {
      final todo = HiveTodo(title: 'Todo with past expirationDate');
      todo.expirationDate = DateTime.now().subtract(Duration(days: 1));

      expect(todo.expirationDate, isNotNull);
      expect(todo.isExpired, true);
    });
  });

  test('Todo copy constructor creates identical todo object', () {
    final original = HiveTodo(title: 'Original todo', description: 'description');

    final copy = HiveTodo.copy(original);

    expect(original, copy);
    expect(original.title, copy.title);
    expect(original.description, copy.description);
    expect(original.creationDate, copy.creationDate);
    expect(original.completionDate, copy.completionDate);
    expect(original.expirationDate, copy.expirationDate);
    expect(original.tagUuids, copy.tagUuids);
  });

  test(
    'Todo copyWith constructor creates identical todo object when no attributes are modified',
    () {
      final original = HiveTodo(title: 'Original todo', description: 'description');

      final copy = original.copyWith();

      expect(original, copy);
      expect(original.title, copy.title);
      expect(original.description, copy.description);
      expect(original.creationDate, copy.creationDate);
      expect(original.completionDate, copy.completionDate);
      expect(original.expirationDate, copy.expirationDate);
      expect(original.tagUuids, copy.tagUuids);
    },
  );
  test(
    'Todo copyWith constructor gives a correct copy with modified attributes',
    () {
      final original = HiveTodo(title: 'Original todo', description: 'description');
      final completionDate = DateTime.now();
      final creationDate = DateTime.now();
      final description = 'description';
      final expirationDate = DateTime.now();
      final title = 'title';
      final Set<String> tagUuids = {"abc", "xyz"};

      final copy = original.copyWith(
        completionDate: completionDate,
        creationDate: creationDate,
        description: description,
        expirationDate: expirationDate,
        listScope: ListScope.daily,
        title: title,
        tagUuids: tagUuids,
      );

      expect(copy.title, title);
      expect(copy.description, description);
      expect(copy.creationDate, creationDate);
      expect(copy.completionDate, completionDate);
      expect(copy.expirationDate, expirationDate);
      expect(copy.tagUuids, tagUuids);
    },
  );

  test('Todo constructor trimms title', () {
    final title = 'Title with leading and tailing spaces';
    final todo = HiveTodo(title: '   $title   ');

    expect(todo.title, title);
  });

  test('Todo set title trimms given value', () {
    final todo = HiveTodo(title: 'Title');
    final String newTitle = 'Title with leading and tailing spaces';
    todo.title = '   $newTitle   ';

    expect(todo.title, newTitle);
  });
}

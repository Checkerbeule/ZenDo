import 'package:flutter_test/flutter_test.dart';
import 'package:zen_do/model/todo/list_scope.dart';
import 'package:zen_do/model/todo/todo.dart';

void main() {
  final className = 'Todo';
  group('$className expirationDate tests', () {
    final testNamePrefix = 'Todo expirationDate:';
    test('$testNamePrefix null value returns false', () {
      final todo = Todo(title: 'Todo without expirationDate');

      expect(todo.expirationDate, isNull);
      expect(todo.isExpired, false);
    });

    test('$testNamePrefix future expirationDate returns false', () {
      final todo = Todo(title: 'Todo with future expirationDate');
      todo.expirationDate = DateTime.now().add(Duration(days: 1));

      expect(todo.expirationDate, isNotNull);
      expect(todo.isExpired, false);
    });

    test('$testNamePrefix past expirationDate returns true', () {
      final todo = Todo(title: 'Todo with past expirationDate');
      todo.expirationDate = DateTime.now().subtract(Duration(days: 1));

      expect(todo.expirationDate, isNotNull);
      expect(todo.isExpired, true);
    });
  });

  test('$className copy constructor creates identical todo object', () {
    final original = Todo(title: 'Original todo', description: 'description');

    final copy = Todo.copy(original);

    expect(original, copy);
    expect(original.title, copy.title);
    expect(original.description, copy.description);
    expect(original.creationDate, copy.creationDate);
    expect(original.completionDate, copy.completionDate);
    expect(original.expirationDate, copy.expirationDate);
  });

  test(
    '$className copyWith constructor creates identical todo object when no attributes are modified',
    () {
      final original = Todo(title: 'Original todo', description: 'description');

      final copy = original.copyWith();

      expect(original, copy);
      expect(original.title, copy.title);
      expect(original.description, copy.description);
      expect(original.creationDate, copy.creationDate);
      expect(original.completionDate, copy.completionDate);
      expect(original.expirationDate, copy.expirationDate);
    },
  );
  test(
    '$className copyWith constructor gives a correct copy with modified attributes',
    () {
      final original = Todo(title: 'Original todo', description: 'description');
      final completionDate = DateTime.now();
      final creationDate = DateTime.now();
      final description = 'description';
      final expirationDate = DateTime.now();
      final title = 'title';

      final copy = original.copyWith(
        completionDate: completionDate,
        creationDate: creationDate,
        description: description,
        expirationDate: expirationDate,
        listScope: ListScope.daily,
        title: title,
      );

      expect(copy.title, title);
      expect(copy.description, description);
      expect(copy.creationDate, creationDate);
      expect(copy.completionDate, completionDate);
      expect(copy.expirationDate, expirationDate);
    },
  );

  test('$className constructor trimms title', () {
    final title = 'Title with leading and tailing spaces';
    final todo = Todo(title: '   $title   ');

    expect(todo.title, title);
  });

  test('$className set title trimms given value', () {
    final todo = Todo(title: 'Title');
    final String newTitle = 'Title with leading and tailing spaces';
    todo.title = '   $newTitle   ';

    expect(todo.title, newTitle);
  });
}

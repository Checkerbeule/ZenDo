import 'package:flutter_test/flutter_test.dart';
import 'package:zen_do/model/todo.dart';

void main() {
  group('Todo expirationDate tests', () {
    test('Todo expirationDate: null value returns false', () {
      final todo = Todo(title: 'Todo without expirationDate');
      
      expect(todo.expirationDate, isNull);
      expect(todo.isExpired, false);
    });

    test('Todo expirationDate: future expirationDate returns false', () {
      final todo = Todo(title: 'Todo with future expirationDate');
      todo.expirationDate = DateTime.now().add(Duration(days: 1));
      
      expect(todo.expirationDate, isNotNull);
      expect(todo.isExpired, false);
    });

    test('Todo expirationDate: past expirationDate returns true', () {
      final todo = Todo(title: 'Todo with past expirationDate');
      todo.expirationDate = DateTime.now().subtract(Duration(days: 1));
      
      expect(todo.expirationDate, isNotNull);
      expect(todo.isExpired, true);
    });
  });

  group('Todo copy tests', () {

    test('Todo copy constructor creates identical todo object', () {
      final original = Todo(title: 'Original todo', description: 'description');
      
      final copy = Todo.copy(original);

      expect(original, copy);
      expect(original.title, copy.title);
      expect(original.description, copy.description);
      expect(original.creationDate, copy.creationDate);
      expect(original.completionDate, copy.completionDate);
      expect(original.expirationDate, copy.expirationDate);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zen_do/model/todo.dart';

void main() {
  group('Todo isExpired tests', () {
    test('Todo isExpired: null value returns false', () {
      final todo = Todo('Todo without expirationDate');
      
      expect(todo.expirationDate, isNull);
      expect(todo.isExpired, false);
    });

    test('Todo isExpired: future expirationDate returns false', () {
      final todo = Todo('Todo with future expirationDate');
      todo.expirationDate = DateTime.now().add(Duration(days: 1));
      
      expect(todo.expirationDate, isNotNull);
      expect(todo.isExpired, false);
    });

    test('Todo isExpired: past expirationDate returns true', () {
      final todo = Todo('Todo with past expirationDate');
      todo.expirationDate = DateTime.now().subtract(Duration(days: 1));
      
      expect(todo.expirationDate, isNotNull);
      expect(todo.isExpired, true);
    });
  });
}

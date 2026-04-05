import 'package:drift/drift.dart';
import 'package:zen_do/features/tags/data/tags.dart';
import 'package:zen_do/features/todos/data/todos.dart';

class TodoTags extends Table {
  TextColumn get todo =>
      text().references(Todos, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get tag =>
      text().references(Tags, #uuid, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {todo, tag};
}

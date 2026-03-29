import 'package:drift/drift.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/features/todos/data/list_scope.dart';

export 'package:zen_do/features/todos/data/list_scope.dart';

@TableIndex(name: 'idx_todos_scope_order', columns: {#scope, #customOrder})
@TableIndex(name: 'idx_todos_completed', columns: {#scope, #completedAt})
@TableIndex(name: 'idx_todos_expires', columns: {#scope, #expiresAt})
class Todos extends Table {
  TextColumn get uuid => text()
      .withLength(min: 36, max: 36)
      .references(Entities, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get scope =>
      text().map(const EnumNameConverter(ListScope.values))();
  TextColumn get customOrder => text()();

  @override
  Set<Column> get primaryKey => {uuid};
}

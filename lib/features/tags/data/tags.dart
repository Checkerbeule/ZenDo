import 'package:drift/drift.dart';

@TableIndex(
  name: 'idx_tags_custom_order',
  columns: {#customOrder},
  unique: true,
)
class Tags extends Table {
  TextColumn get uuid => text().withLength(min: 36, max: 36)();
  TextColumn get name => text().withLength(min: 1, max: 25)();
  IntColumn get color => integer()();
  TextColumn get customOrder => text()();

  @override
  Set<Column> get primaryKey => {uuid};
}

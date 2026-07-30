import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/features/tags/data/tags.dart';
import 'package:zen_do/features/todos/data/todo_tags.dart';
import 'package:zen_do/features/todos/data/todos.dart';

part 'app_database.g.dart';

final Logger logger = Logger(level: Level.debug);

@DriftDatabase(tables: [Entities, Tags, Todos, TodoTags])
class AppDatabase extends _$AppDatabase {
  final bool seedInitalTags;

  AppDatabase() : seedInitalTags = true, super(_openConnection()) {
    _init();
  }

  AppDatabase.test(super.executor, {this.seedInitalTags = false}) {
    _init();
  }

  void _init() {
    driftRuntimeOptions.defaultSerializer = ValueSerializer.defaults(
      serializeDateTimeValuesAsString: true,
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'zendo_local_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');

        if (details.wasCreated && seedInitalTags) {
          await batch((batch) {
            final timestamp = DateTime.now().toUtc();
            final List<EntitiesCompanion> initialEntitiesForTags =
                List.generate(
                  3,
                  (_) => EntitiesCompanion.insert(
                    uuid: Uuid().v4(),
                    type: EntityType.tag,
                    createdAt: timestamp,
                    updatedAt: timestamp,
                  ),
                );
            batch.insertAll(entities, initialEntitiesForTags);

            batch.insertAll(tags, [
              TagsCompanion.insert(
                uuid: initialEntitiesForTags[0].uuid.value,
                name: 'Work',
                color: material.Colors.red.toARGB32(),
                customOrder: 'a0',
              ),
              TagsCompanion.insert(
                uuid: initialEntitiesForTags[1].uuid.value,
                name: 'Private',
                color: material.Colors.yellow.toARGB32(),
                customOrder: 'a1',
              ),
              TagsCompanion.insert(
                uuid: initialEntitiesForTags[2].uuid.value,
                name: 'Volunteering',
                color: material.Colors.blue.toARGB32(),
                customOrder: 'a2',
              ),
            ]);
          });
        }
      },

      onUpgrade: (m, from, to) async {
        await customStatement('PRAGMA foreign_keys = OFF');

        if (from < 3) {
          await m.alterTable(
            TableMigration(
              tags,
              columnTransformer: {
                tags.customOrder: Constant('temp_init_value'),
              },
              newColumns: [tags.customOrder],
            ),
          );
          await _fillInitialFractionalIndices();
          await m.createIndex(
            Index(
              'idx_tags_custom_order',
              'CREATE UNIQUE INDEX idx_tags_custom_order ON tags (custom_order);',
            ),
          );
        }

        if (from < 4) {
          await m.createTable(entities);

          final oldTags = await customSelect('SELECT * FROM tags').get();

          await m.drop(tags);
          await m.createTable(tags);

          final timeStamp = DateTime.now().toUtc();
          await batch((batch) {
            for (int i = 0; i < oldTags.length; i++) {
              final uuid = oldTags[i].data['uuid']?.toString() ?? Uuid().v4();
              final name = oldTags[i].data['name'] as String;
              final color = oldTags[i].data['color'] as int;
              final order =
                  oldTags[i].data['custom_order']?.toString() ?? 'a$i';

              batch.insert(
                tags,
                TagsCompanion.insert(
                  uuid: uuid,
                  name: name,
                  color: color,
                  customOrder: order,
                ),
              );

              batch.insert(
                entities,
                EntitiesCompanion.insert(
                  uuid: uuid,
                  type: EntityType.tag,
                  createdAt: timeStamp,
                  updatedAt: timeStamp,
                ),
              );
            }
          });

          await m.createIndex(
            Index(
              'idx_entities_type',
              'CREATE INDEX idx_entities_type ON entities (type);',
            ),
          );
          await m.createIndex(
            Index(
              'idx_entities_pending_sync',
              'CREATE INDEX idx_entities_pending_sync ON entities (updated_at, last_synced_at);',
            ),
          );
          await m.createIndex(
            Index(
              'idx_tags_custom_order',
              'CREATE UNIQUE INDEX idx_tags_custom_order ON tags (custom_order);',
            ),
          );
        }

        if (from < 5) {
          await m.createTable(todos);
          await m.createIndex(
            Index(
              'idx_todos_scope_order',
              'CREATE INDEX idx_todos_scope_order ON todos (scope, custom_order);',
            ),
          );
          await m.createIndex(
            Index(
              'idx_todos_completed',
              'CREATE INDEX idx_todos_completed ON todos (scope, completed_at);',
            ),
          );
          await m.createIndex(
            Index(
              'idx_todos_expires',
              'CREATE INDEX idx_todos_expires ON todos (scope, expires_at);',
            ),
          );

          await m.createTable(todoTags);
        }

        await customStatement('PRAGMA foreign_keys = ON');
        final violations = await customSelect('PRAGMA foreign_key_check').get();
        if (violations.isNotEmpty) {
          throw Exception(
            'Foreign key constraint violations detected after migration: $violations',
          );
        }
      },
    );
  }

  Future<void> _fillInitialFractionalIndices() async {
    final allTags = await customSelect('SELECT id FROM tags').get();

    if (allTags.isEmpty) return;

    await transaction(() async {
      String? lastKey;

      for (final tag in allTags) {
        final id = tag.read<int>('id');
        final newKey = FractionalIndexing.generateKeyBetween(lastKey, null);

        await customStatement('UPDATE tags SET custom_order = ? WHERE id = ?', [
          newKey,
          id,
        ]);

        lastKey = newKey;
      }
    });
  }
}

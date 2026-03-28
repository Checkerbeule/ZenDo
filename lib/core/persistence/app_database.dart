import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zen_do/core/persistence/cloudsync/syncable.dart';
import 'package:zen_do/core/persistence/entities.dart';
import 'package:zen_do/features/tags/data/tags.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tags, Entities])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'zendo_local_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');

        if (details.wasCreated) {
          await batch((batch) {
            batch.insertAll(tags, [
              TagsCompanion.insert(
                name: 'Work',
                color: material.Colors.red.toARGB32(),
                customOrder: 'a0',
              ),
              TagsCompanion.insert(
                name: 'Private',
                color: material.Colors.green.toARGB32(),
                customOrder: 'a1',
              ),
              TagsCompanion.insert(
                name: 'Focus',
                color: material.Colors.blue.toARGB32(),
                customOrder: 'a2',
              ),
              TagsCompanion.insert(
                name: 'On the Go',
                color: material.Colors.purple.toARGB32(),
                customOrder: 'a3',
              ),
            ]);
          });
        }
      },

      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.alterTable(
            TableMigration(
              tags,
              columnTransformer: {
                tags.syncStatus: CustomExpression<int>('sync_status')
                    .caseMatch<String>(
                      when: {
                        Constant(0): Constant(SyncStatus.localOnly.name),
                        Constant(1): Constant(SyncStatus.synced.name),
                        Constant(2): Constant(SyncStatus.pending.name),
                        Constant(3): Constant(SyncStatus.deleted.name),
                      },
                      orElse: Constant(SyncStatus.localOnly.name),
                    ),
              },
            ),
          );
        }

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
          await _populateEntitiesForExistingData();
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
        }
      },
    );
  }

  Future<void> _fillInitialFractionalIndices() async {
    final allTags = await (select(
      tags,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

    if (allTags.isEmpty) return;

    await batch((batch) {
      String? lastKey;

      for (final tag in allTags) {
        final newKey = FractionalIndexing.generateKeyBetween(lastKey, null);

        batch.update(
          tags,
          TagsCompanion(customOrder: Value(newKey)),
          where: (t) => t.id.equals(tag.id),
        );

        lastKey = newKey;
      }
    });
  }

  Future<void> _populateEntitiesForExistingData() async {
    final allTags = await (select(tags)).get();
    final timeStamp = DateTime.now().toUtc();
    await batch((batch) {
      for (final tag in allTags) {
        batch.insert(
          entities,
          EntitiesCompanion.insert(
            uuid: tag.uuid,
            type: EntityType.tag,
            createdAt: timeStamp,
            updatedAt: timeStamp,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}

// Schema and migration tests. When schemaVersion is bumped:
//   1. dart run drift_dev make-migrations   (dumps drift_schemas/, writes
//      database.steps.dart and regenerates generated/)
//   2. add the stepByStep migration in KernelDatabase.migration
//   3. add an upgrade test below (verifier.startAt(old) -> migrateAndValidate)
import 'package:data_operations/src/db/database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('schema version 1 is the only exported version', () {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 1);
    expect(GeneratedHelper.versions, [db.schemaVersion]);
  });

  test('a fresh install creates exactly the exported v1 schema', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.validateDatabaseSchema();
  });

  test('opening a database already at v1 validates against the dump', () async {
    final connection = await verifier.startAt(1);
    final db = KernelDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 1);
  });

  test('a fresh database contains no rows (no seed data)', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    for (final table in db.allTables) {
      final count = await db
          .customSelect('SELECT COUNT(*) AS c FROM "${table.actualTableName}"')
          .getSingle();
      expect(count.read<int>('c'), 0, reason: table.actualTableName);
    }
  });

  test(
    'every table carries id, created_at, updated_at and sync_state',
    () async {
      final db = KernelDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (final table in db.allTables) {
        final names = table.$columns.map((c) => c.name).toSet();
        expect(
          names,
          containsAll(['id', 'created_at', 'updated_at', 'sync_state']),
          reason: table.actualTableName,
        );
        expect(table.$primaryKey.map((c) => c.name), ['id']);
        final syncState = table.$columns.firstWhere(
          (c) => c.name == 'sync_state',
        );
        expect(syncState.defaultValue, isNotNull);
      }
      expect(
        db.allTables.map((t) => t.actualTableName),
        containsAll([
          'items',
          'locations',
          'lots',
          'scans',
          'inspections',
          'reminders',
          'settings',
        ]),
      );
    },
  );

  test('integrity triggers exist and foreign keys are enforced', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final triggers = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
        .map((row) => row.read<String>('name'))
        .get();
    expect(
      triggers,
      containsAll(['scans_append_only', 'inspections_verified_immutable']),
    );
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.data.values.single, 1);

    await expectLater(
      db.customStatement(
        "INSERT INTO reminders (id, created_at, updated_at, item_id, due_at, "
        "status, notification_id) VALUES ('r', '2026-10-01T00:00:00.000Z', "
        "'2026-10-01T00:00:00.000Z', 'no-such-item', "
        "'2026-10-02T00:00:00.000Z', 'scheduled', 1)",
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('an unexpected schema version is refused, not silently reset', () async {
    final db = KernelDatabase(
      NativeDatabase.memory(setup: (raw) => raw.userVersion = 2),
    );
    addTearDown(db.close);
    // A database from a newer build must never be "migrated" by dropping
    // data; opening fails instead.
    await expectLater(
      db.customSelect('SELECT 1').get(),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('sync_state defaults to localOnly on insert', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO locations (id, created_at, updated_at, type, name) VALUES "
      "('l', '2026-10-01T00:00:00.000Z', '2026-10-01T00:00:00.000Z', 'home', 'Home')",
    );
    final row = await db
        .customSelect("SELECT sync_state FROM locations WHERE id = 'l'")
        .getSingle();
    expect(row.read<String>('sync_state'), 'localOnly');
  });
}

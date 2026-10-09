// Schema and migration tests. When schemaVersion is bumped:
//   1. dart run build_runner build, then dart run drift_dev make-migrations
//      (dumps drift_schemas/, writes database.steps.dart and regenerates
//      generated/)
//   2. add the step to KernelDatabase._upgrade (stepByStep)
//   3. add an upgrade test below (verifier.startAt(old) -> migrateAndValidate)
//      plus a data-integrity test with rows written at the old version
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

  test('every schema version up to the current one is exported', () {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 2);
    expect(GeneratedHelper.versions, [1, 2]);
  });

  test('a fresh install creates exactly the exported v2 schema', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.validateDatabaseSchema();
  });

  test('opening a database already at v2 validates against the dump', () async {
    final connection = await verifier.startAt(2);
    final db = KernelDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('upgrading v1 -> v2 yields exactly the exported v2 schema', () async {
    final connection = await verifier.startAt(1);
    final db = KernelDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('v1 -> v2 keeps every v1 row, adds no rows and defaults the new '
      'columns', () async {
    final schema = await verifier.schemaAt(1);
    const t = '2026-10-01T08:00:00.000Z';
    schema.rawDatabase.execute(
      "INSERT INTO locations (id, created_at, updated_at, type, name) "
      "VALUES ('loc', '$t', '$t', 'warehouse', 'Godown')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO lots (id, created_at, updated_at, code, grain_type, "
      "declared_quantity, quantity_unit, received_at) VALUES "
      "('lot', '$t', '$t', 'LOT-1', 'Wheat', 100.0, 'kg', '$t')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO items (id, created_at, updated_at, owner_role, label, "
      "grain_type, quantity, quantity_unit, storage_date, location_id, "
      "lot_id) VALUES ('item', '$t', '$t', 'farmer', 'Sack R-001', 'Wheat', "
      "50.0, 'kg', '$t', 'loc', 'lot')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO scans (id, created_at, updated_at, item_id, captured_at, "
      "duration_ms, sample_rate, quality, quality_reasons, model_version, "
      "result, confidence, experimental, latency_ms, device_model, "
      "os_version) VALUES ('scan', '$t', '$t', 'item', '$t', 2000, 16000, "
      "'pass', '', 'none', 'notEvaluated', NULL, 1, 100, 'dev', 'os')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO inspections (id, created_at, updated_at, item_id, "
      "scan_id, inspected_at, inspector, observations, verified_finding, "
      "follow_up_status) VALUES ('insp', '$t', '$t', 'item', 'scan', '$t', "
      "'Ravi', 'Looked fine', 'noneFound', 'open')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO settings (id, created_at, updated_at, key, value) "
      "VALUES ('set', '$t', '$t', 'activeRole', 'farmer')",
    );

    final db = KernelDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);

    final counts = {
      for (final table in db.allTables)
        table.actualTableName:
            (await db
                    .customSelect(
                      'SELECT COUNT(*) AS c FROM "${table.actualTableName}"',
                    )
                    .getSingle())
                .read<int>('c'),
    };
    expect(counts, {
      'locations': 1,
      'lots': 1,
      'harvests': 0,
      'items': 1,
      'scans': 1,
      'inspections': 1,
      'reminders': 0,
      'settings': 1,
      'labeled_samples': 0,
    });

    final item = await db.select(db.items).getSingle();
    expect(item.label, 'Sack R-001');
    expect(item.locationId, 'loc');
    expect(item.lotId, 'lot');
    expect(item.harvestId, isNull);
    expect(item.archivedAt, isNull);
    expect((await db.select(db.locations).getSingle()).archivedAt, isNull);
    expect((await db.select(db.lots).getSingle()).archivedAt, isNull);
    final scan = await db.select(db.scans).getSingle();
    expect(scan.audioRetained, isFalse);
    expect(scan.result.name, 'notEvaluated');
    final inspection = await db.select(db.inspections).getSingle();
    expect(inspection.assignedTo, isNull);
    expect(inspection.photoPaths, isEmpty);
    expect(inspection.verifiedFinding.name, 'noneFound');

    // The recreated triggers cover the v2 columns: assignee and follow-up
    // stay writable, the finding, photos and scan fields do not.
    await db.customStatement(
      "UPDATE inspections SET assigned_to = 'Asha', "
      "follow_up_status = 'inProgress' WHERE id = 'insp'",
    );
    await expectLater(
      db.customStatement(
        "UPDATE inspections SET photo_paths = '[\"/x.jpg\"]' "
        "WHERE id = 'insp'",
      ),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.customStatement(
        "UPDATE inspections SET verified_finding = 'pestsFound' "
        "WHERE id = 'insp'",
      ),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.customStatement(
        "UPDATE scans SET audio_retained = 1 WHERE id = 'scan'",
      ),
      throwsA(isA<SqliteException>()),
    );
    final triggers = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
        .map((row) => row.read<String>('name'))
        .get();
    expect(
      triggers,
      unorderedEquals([
        'scans_append_only',
        'inspections_verified_immutable',
        'labeled_samples_immutable',
      ]),
    );
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
          'harvests',
          'scans',
          'inspections',
          'reminders',
          'settings',
          'labeled_samples',
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
      containsAll([
        'scans_append_only',
        'inspections_verified_immutable',
        'labeled_samples_immutable',
      ]),
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
      NativeDatabase.memory(setup: (raw) => raw.userVersion = 3),
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

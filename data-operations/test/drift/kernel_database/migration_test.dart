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

const _v2Triggers = [
  'scans_append_only',
  'inspections_verified_immutable',
  'labeled_samples_immutable',
];

const _v3Triggers = [
  ..._v2Triggers,
  'sightings_analysis_immutable',
  'sightings_verified_once',
  'sensor_events_append_only',
];

const _v3Tables = [
  'sightings',
  'sensor_nodes',
  'sensor_events',
  'knowledge_cards',
  'card_embeddings',
];

const _t = '2026-10-01T08:00:00.000Z';

Future<List<String>> _triggers(KernelDatabase db) => db
    .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
    .map((row) => row.read<String>('name'))
    .get();

Future<Map<String, int>> _counts(KernelDatabase db) async => {
  for (final table in db.allTables)
    table.actualTableName:
        (await db
                .customSelect(
                  'SELECT COUNT(*) AS c FROM "${table.actualTableName}"',
                )
                .getSingle())
            .read<int>('c'),
};

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('every schema version up to the current one is exported', () {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 3);
    expect(GeneratedHelper.versions, [1, 2, 3]);
  });

  test('a fresh install creates exactly the exported v3 schema', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.validateDatabaseSchema();
  });

  test('opening a database already at v3 validates against the dump', () async {
    final connection = await verifier.startAt(3);
    final db = KernelDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
  });

  test('upgrading v1 -> v2 yields exactly the exported v2 schema', () async {
    final connection = await verifier.startAt(1);
    final db = KernelDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('upgrading v2 -> v3 yields exactly the exported v3 schema', () async {
    final connection = await verifier.startAt(2);
    final db = KernelDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
  });

  test('upgrading v1 -> v3 yields exactly the exported v3 schema', () async {
    final connection = await verifier.startAt(1);
    final db = KernelDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
  });

  test('v1 -> v3 keeps every v1 row, adds no rows and defaults the new '
      'columns', () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute(
      "INSERT INTO locations (id, created_at, updated_at, type, name) "
      "VALUES ('loc', '$_t', '$_t', 'warehouse', 'Godown')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO lots (id, created_at, updated_at, code, grain_type, "
      "declared_quantity, quantity_unit, received_at) VALUES "
      "('lot', '$_t', '$_t', 'LOT-1', 'Wheat', 100.0, 'kg', '$_t')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO items (id, created_at, updated_at, owner_role, label, "
      "grain_type, quantity, quantity_unit, storage_date, location_id, "
      "lot_id) VALUES ('item', '$_t', '$_t', 'farmer', 'Sack R-001', 'Wheat', "
      "50.0, 'kg', '$_t', 'loc', 'lot')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO scans (id, created_at, updated_at, item_id, captured_at, "
      "duration_ms, sample_rate, quality, quality_reasons, model_version, "
      "result, confidence, experimental, latency_ms, device_model, "
      "os_version) VALUES ('scan', '$_t', '$_t', 'item', '$_t', 2000, 16000, "
      "'pass', '', 'none', 'notEvaluated', NULL, 1, 100, 'dev', 'os')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO inspections (id, created_at, updated_at, item_id, "
      "scan_id, inspected_at, inspector, observations, verified_finding, "
      "follow_up_status) VALUES ('insp', '$_t', '$_t', 'item', 'scan', '$_t', "
      "'Ravi', 'Looked fine', 'noneFound', 'open')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO settings (id, created_at, updated_at, key, value) "
      "VALUES ('set', '$_t', '$_t', 'activeRole', 'farmer')",
    );

    final db = KernelDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);

    expect(await _counts(db), {
      'locations': 1,
      'lots': 1,
      'harvests': 0,
      'items': 1,
      'scans': 1,
      'inspections': 1,
      'reminders': 0,
      'settings': 1,
      'labeled_samples': 0,
      for (final table in _v3Tables) table: 0,
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
    expect(await _triggers(db), unorderedEquals(_v3Triggers));
  });

  test('v2 -> v3 is additive: every v2 row and trigger is kept and the new '
      'tables start empty', () async {
    final schema = await verifier.schemaAt(2);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO locations (id, created_at, updated_at, type, name, "
      "archived_at) VALUES ('loc', '$_t', '$_t', 'room', 'Kitchen', NULL)",
    );
    raw.execute(
      "INSERT INTO harvests (id, created_at, updated_at, name, grain_type, "
      "harvested_at) VALUES ('h', '$_t', '$_t', 'Rabi', 'Wheat', '$_t')",
    );
    raw.execute(
      "INSERT INTO items (id, created_at, updated_at, owner_role, label, "
      "grain_type, quantity, quantity_unit, storage_date, location_id, "
      "harvest_id) VALUES ('item', '$_t', '$_t', 'household', 'Tin 1', "
      "'Rice', 5.0, 'kg', '$_t', 'loc', 'h')",
    );
    raw.execute(
      "INSERT INTO scans (id, created_at, updated_at, item_id, captured_at, "
      "duration_ms, sample_rate, quality, quality_reasons, model_version, "
      "result, confidence, experimental, latency_ms, device_model, "
      "os_version, audio_retained) VALUES ('scan', '$_t', '$_t', 'item', "
      "'$_t', 2000, 16000, 'pass', '', 'none', 'notEvaluated', NULL, 1, 100, "
      "'dev', 'os', 1)",
    );
    raw.execute(
      "INSERT INTO inspections (id, created_at, updated_at, item_id, "
      "scan_id, inspected_at, inspector, observations, verified_finding, "
      "follow_up_status, assigned_to, photo_paths) VALUES ('insp', '$_t', "
      "'$_t', 'item', 'scan', '$_t', 'Ravi', 'Weevils', 'pestsFound', "
      "'open', 'Asha', '[\"/data/p.jpg\"]')",
    );
    raw.execute(
      "INSERT INTO labeled_samples (id, created_at, updated_at, scan_id, "
      "item_id, label, inspection_id, grain_type) VALUES ('ls', '$_t', "
      "'$_t', 'scan', 'item', 'infested', 'insp', 'Rice')",
    );
    raw.execute(
      "INSERT INTO reminders (id, created_at, updated_at, item_id, due_at, "
      "status, notification_id) VALUES ('rem', '$_t', '$_t', 'item', '$_t', "
      "'scheduled', 7)",
    );
    raw.execute(
      "INSERT INTO settings (id, created_at, updated_at, key, value) "
      "VALUES ('set', '$_t', '$_t', 'researchModeOptIn', 'true')",
    );

    final db = KernelDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);

    expect(await _counts(db), {
      'locations': 1,
      'lots': 0,
      'harvests': 1,
      'items': 1,
      'scans': 1,
      'inspections': 1,
      'reminders': 1,
      'settings': 1,
      'labeled_samples': 1,
      for (final table in _v3Tables) table: 0,
    });
    final inspection = await db.select(db.inspections).getSingle();
    expect(inspection.photoPaths, ['/data/p.jpg']);
    expect(inspection.assignedTo, 'Asha');
    expect((await db.select(db.scans).getSingle()).audioRetained, isTrue);
    expect(
      (await db.select(db.labeledSamples).getSingle()).label.name,
      'infested',
    );
    expect(await _triggers(db), unorderedEquals(_v3Triggers));

    // The v2 guards still hold after the upgrade.
    await expectLater(
      db.customStatement("UPDATE scans SET result = 'clean' WHERE id = 'scan'"),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.customStatement(
        "UPDATE labeled_samples SET label = 'clean' WHERE id = 'ls'",
      ),
      throwsA(isA<SqliteException>()),
    );

    // The new tables accept rows referencing the migrated v2 rows.
    await db.customStatement(
      "INSERT INTO sightings (id, created_at, updated_at, role, source, "
      "observed_at, location_id, item_id, user_validated) VALUES ('s', "
      "'$_t', '$_t', 'household', 'camera', '$_t', 'loc', 'item', 1)",
    );
    await db.customStatement(
      "INSERT INTO sensor_nodes (id, created_at, updated_at, device_address, "
      "name, type, protocol_version, firmware_version, key_fingerprint, "
      "location_id) VALUES ('n', '$_t', '$_t', 'AA:BB', 'Node', 'usAir', 1, "
      "'1.0', '0a1b2c3d', 'loc')",
    );
  });

  test('v3 integrity triggers: sighting analysis immutable, verified finding '
      'set once, sensor events append-only and unique per node seq', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO sightings (id, created_at, updated_at, role, source, "
      "observed_at, user_validated, analysis) VALUES ('s', '$_t', '$_t', "
      "'household', 'camera', '$_t', 1, NULL)",
    );
    // Writable: the user's side and bookkeeping.
    await db.customStatement(
      "UPDATE sightings SET notes = 'by the sink', user_card_id = 'rat', "
      "sync_state = 'pending' WHERE id = 's'",
    );
    await expectLater(
      db.customStatement("UPDATE sightings SET analysis = '{}' WHERE id = 's'"),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.customStatement(
        "UPDATE sightings SET observed_at = '$_t' WHERE id = 's'",
      ),
      throwsA(isA<SqliteException>()),
    );
    // First verified finding is allowed, any later write is refused.
    await db.customStatement(
      "UPDATE sightings SET verified_finding = 'pestsFound' WHERE id = 's'",
    );
    await expectLater(
      db.customStatement(
        "UPDATE sightings SET verified_finding = 'noneFound' WHERE id = 's'",
      ),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.customStatement(
        "UPDATE sightings SET verified_finding = 'pestsFound' WHERE id = 's'",
      ),
      throwsA(isA<SqliteException>()),
    );

    await db.customStatement(
      "INSERT INTO sensor_nodes (id, created_at, updated_at, device_address, "
      "name, type, protocol_version, firmware_version, key_fingerprint) "
      "VALUES ('n', '$_t', '$_t', 'AA:BB', 'Node', 'usAir', 1, '1.0', "
      "'0a1b2c3d')",
    );
    String event(String id, int seq) =>
        "INSERT INTO sensor_events (id, created_at, updated_at, node_id, seq, "
        "started_at, duration_ms, event_class, peak_hz, min_hz, max_hz, "
        "slope_hz_per_ms, snr_db, peak_dbfs, impulses, rep_rate_hz, "
        "harmonics) VALUES ('$id', '$_t', '$_t', 'n', $seq, '$_t', 40, "
        "'tonal', 40000, 39000, 41000, 0, 12, -30, 0, 0, 0)";
    await db.customStatement(event('e1', 1));
    await expectLater(
      db.customStatement(event('e2', 1)),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.customStatement("UPDATE sensor_events SET seq = 9 WHERE id = 'e1'"),
      throwsA(isA<SqliteException>()),
    );
    await db.customStatement(
      "UPDATE sensor_events SET sync_state = 'pending' WHERE id = 'e1'",
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO sensor_nodes (id, created_at, updated_at, "
        "device_address, name, type, protocol_version, firmware_version, "
        "key_fingerprint) VALUES ('n2', '$_t', '$_t', 'AA:BB', 'Twin', "
        "'usAir', 1, '1.0', '0a1b2c3d')",
      ),
      throwsA(isA<SqliteException>()),
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
          ..._v3Tables,
        ]),
      );
    },
  );

  test('integrity triggers exist and foreign keys are enforced', () async {
    final db = KernelDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await _triggers(db), containsAll(_v3Triggers));
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
    await expectLater(
      db.customStatement(
        "INSERT INTO sensor_events (id, created_at, updated_at, node_id, seq, "
        "started_at, duration_ms, event_class, peak_hz, min_hz, max_hz, "
        "slope_hz_per_ms, snr_db, peak_dbfs, impulses, rep_rate_hz, "
        "harmonics) VALUES ('e', '$_t', '$_t', 'no-such-node', 1, '$_t', 40, "
        "'tonal', 1, 1, 1, 0, 1, -30, 0, 0, 0)",
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('an unexpected schema version is refused, not silently reset', () async {
    final db = KernelDatabase(
      NativeDatabase.memory(setup: (raw) => raw.userVersion = 4),
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

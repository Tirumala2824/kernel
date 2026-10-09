import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'converters.dart';
import 'tables.dart';

part 'database.g.dart';

/// Local SQLite database. Internal to data_operations; the UI only sees the
/// contracts interfaces.
///
/// A fresh database is empty: migrations create the schema and never insert
/// rows.
@DriftDatabase(
  tables: [Locations, Lots, Items, Scans, Inspections, Reminders, Settings],
  include: {'integrity.drift'},
)
class KernelDatabase extends _$KernelDatabase {
  KernelDatabase(super.executor);

  /// Bump together with a drift migration step, a new schema dump
  /// (`dart run drift_dev make-migrations`) and a migration test.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Version 1 is the first released schema, so there is nothing to
      // upgrade from yet. Add `stepByStep(...)` from the generated
      // database.steps.dart here when schemaVersion is bumped.
      throw UnsupportedError('No migration path from schema $from to $to');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'converters.dart';
import 'database.steps.dart';
import 'tables.dart';

part 'database.g.dart';

/// Local SQLite database. Internal to data_operations; the UI only sees the
/// contracts interfaces.
///
/// A fresh database is empty: migrations create the schema and never insert
/// rows.
@DriftDatabase(
  tables: [
    Locations,
    Lots,
    Harvests,
    Items,
    Scans,
    Inspections,
    Reminders,
    Settings,
    LabeledSamples,
    Sightings,
    SensorNodes,
    SensorEvents,
    KnowledgeCards,
    CardEmbeddings,
  ],
  include: {'integrity.drift'},
)
class KernelDatabase extends _$KernelDatabase {
  KernelDatabase(super.executor);

  /// Bump together with a drift migration step, a new schema dump
  /// (`dart run drift_dev make-migrations`) and a migration test.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Never "migrate" by dropping data: a database from a newer build, or
      // an unknown version, is refused.
      if (from < 1 || to > schemaVersion || from >= to) {
        throw UnsupportedError('No migration path from schema $from to $to');
      }
      await _upgrade(m, from, to);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Step-by-step upgrades built on the frozen schema snapshots in
  /// database.steps.dart, so later table changes cannot alter old steps.
  /// Every step only adds tables, columns, indexes and triggers; no rows are
  /// inserted and none are removed.
  static final OnUpgrade _upgrade = stepByStep(
    from1To2: (m, schema) async {
      // Harvests first: items.harvest_id references it.
      await m.createTable(schema.harvests);
      await m.addColumn(schema.locations, schema.locations.archivedAt);
      await m.addColumn(schema.lots, schema.lots.archivedAt);
      await m.addColumn(schema.items, schema.items.harvestId);
      await m.addColumn(schema.items, schema.items.archivedAt);
      await m.createIndex(schema.itemsHarvest);
      await m.addColumn(schema.scans, schema.scans.audioRetained);
      await m.addColumn(schema.inspections, schema.inspections.assignedTo);
      await m.addColumn(schema.inspections, schema.inspections.photoPaths);
      await m.createTable(schema.labeledSamples);
      await m.createIndex(schema.labeledSamplesItem);
      // The immutability triggers now cover the new immutable columns
      // (scans.audio_retained, inspections.photo_paths). assigned_to and
      // follow_up_status stay writable.
      await m.drop(schema.scansAppendOnly);
      await m.create(schema.scansAppendOnly);
      await m.drop(schema.inspectionsVerifiedImmutable);
      await m.create(schema.inspectionsVerifiedImmutable);
      await m.create(schema.labeledSamplesImmutable);
    },
    from2To3: (m, schema) async {
      // Additive only: new tables (parents first), their indexes and
      // triggers. Every v2 table, column and trigger is left as it is.
      await m.createTable(schema.sightings);
      await m.createIndex(schema.sightingsObserved);
      await m.createIndex(schema.sightingsLocation);
      await m.createIndex(schema.sightingsItem);
      await m.create(schema.sightingsAnalysisImmutable);
      await m.create(schema.sightingsVerifiedOnce);
      await m.createTable(schema.sensorNodes);
      await m.createTable(schema.sensorEvents);
      await m.createIndex(schema.sensorEventsStarted);
      await m.createIndex(schema.sensorEventsLocation);
      await m.createIndex(schema.sensorEventsItem);
      await m.create(schema.sensorEventsAppendOnly);
      await m.createTable(schema.knowledgeCards);
      await m.createTable(schema.cardEmbeddings);
    },
  );
}

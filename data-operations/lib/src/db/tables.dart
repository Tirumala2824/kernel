import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'converters.dart';

/// Columns every persisted row carries (guardrails §6): a UUID text primary
/// key plus createdAt, updatedAt and syncState for the deferred sync (V3).
mixin TrackedColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncState =>
      textEnum<SyncState>().withDefault(Constant(SyncState.localOnly.name))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// Columns added in schema v2 are declared last, in the order the v1 -> v2
// migration appends them, so fresh and upgraded databases match exactly.

@DataClassName('LocationRow')
class Locations extends Table with TrackedColumns {
  TextColumn get type => textEnum<LocationType>()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable().references(Locations, #id)();

  /// Soft delete (v2). Hidden from lists, kept for history.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

@DataClassName('LotRow')
class Lots extends Table with TrackedColumns {
  TextColumn get code => text()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get supplierName => text().nullable()();
  TextColumn get grainType => text()();
  RealColumn get declaredQuantity => real()();
  TextColumn get quantityUnit => text()();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get screeningStatus => textEnum<ScreeningStatus>().withDefault(
    Constant(ScreeningStatus.pending.name),
  )();

  /// Soft delete (v2).
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

/// A farmer's harvest (v2), grouping the sacks registered from it.
@DataClassName('HarvestRow')
class Harvests extends Table with TrackedColumns {
  TextColumn get name => text()();
  TextColumn get grainType => text()();
  DateTimeColumn get harvestedAt => dateTime()();
  TextColumn get notes => text().nullable()();

  /// Soft delete.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

@DataClassName('ItemRow')
@TableIndex(name: 'items_owner_role', columns: {#ownerRole})
@TableIndex(name: 'items_location', columns: {#locationId})
@TableIndex(name: 'items_lot', columns: {#lotId})
@TableIndex(name: 'items_harvest', columns: {#harvestId})
class Items extends Table with TrackedColumns {
  TextColumn get ownerRole => textEnum<Role>()();
  TextColumn get label => text()();
  TextColumn get grainType => text()();
  RealColumn get quantity => real()();
  TextColumn get quantityUnit => text()();
  DateTimeColumn get storageDate => dateTime()();
  TextColumn get locationId => text().nullable().references(Locations, #id)();
  TextColumn get lotId => text().nullable().references(Lots, #id)();

  /// Farmer harvest this sack belongs to (v2).
  TextColumn get harvestId => text().nullable().references(Harvests, #id)();

  /// Soft delete (v2). Scans, inspections and reminders are kept.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

/// Append-only scan history. The `id` is the engine's scanId.
@DataClassName('ScanRow')
@TableIndex(name: 'scans_item_captured', columns: {#itemId, #capturedAt})
class Scans extends Table with TrackedColumns {
  TextColumn get itemId => text().references(Items, #id)();
  DateTimeColumn get capturedAt => dateTime()();
  IntColumn get durationMs => integer()();
  IntColumn get sampleRate => integer()();
  TextColumn get quality => textEnum<ScanQuality>()();

  /// Comma-separated [QualityReason] names, empty when none.
  TextColumn get qualityReasons =>
      text().map(const QualityReasonsConverter())();
  TextColumn get modelVersion => text()();

  /// Predicted class. Never derived from, or written to, an inspection.
  TextColumn get result => textEnum<Classification>()();
  RealColumn get confidence => real().nullable()();
  BoolColumn get experimental => boolean()();
  IntColumn get latencyMs => integer()();
  TextColumn get deviceModel => text()();
  TextColumn get osVersion => text()();

  /// Whether the engine kept the WAV for this scan (v2). Immutable.
  BoolColumn get audioRetained =>
      boolean().withDefault(const Constant(false))();
}

@DataClassName('InspectionRow')
@TableIndex(name: 'inspections_item', columns: {#itemId})
class Inspections extends Table with TrackedColumns {
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get scanId => text().nullable().references(Scans, #id)();
  DateTimeColumn get inspectedAt => dateTime()();
  TextColumn get inspector => text()();
  TextColumn get observations => text()();

  /// Human-verified finding. Never derived from a scan result.
  TextColumn get verifiedFinding => textEnum<VerifiedFinding>()();
  TextColumn get followUpStatus => textEnum<FollowUpStatus>()();

  /// Staff member responsible for the follow-up (v2). Updatable.
  TextColumn get assignedTo => text().nullable()();

  /// App-private evidence photo paths as a JSON array (v2). Part of the
  /// immutable inspection record.
  TextColumn get photoPaths => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
}

@DataClassName('ReminderRow')
@TableIndex(name: 'reminders_item', columns: {#itemId})
class Reminders extends Table with TrackedColumns {
  TextColumn get itemId => text().references(Items, #id)();
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get status => textEnum<ReminderStatus>()();

  /// 32-bit id handed to the OS notification scheduler.
  IntColumn get notificationId => integer().unique()();
}

/// Key/value settings. Missing keys mean "use the default"; nothing is
/// inserted on first run.
@DataClassName('SettingRow')
class Settings extends Table with TrackedColumns {
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

/// Research recordings (v2): one explicit label per retained scan.
/// Immutable once stored.
@DataClassName('LabeledSampleRow')
@TableIndex(name: 'labeled_samples_item', columns: {#itemId})
class LabeledSamples extends Table with TrackedColumns {
  TextColumn get scanId => text().unique().references(Scans, #id)();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get label => textEnum<SampleLabel>()();
  TextColumn get inspectionId =>
      text().nullable().references(Inspections, #id)();
  TextColumn get grainType => text()();
  TextColumn get sackMaterial => text().nullable()();
  TextColumn get environment => text().nullable()();
  TextColumn get notes => text().nullable()();
}

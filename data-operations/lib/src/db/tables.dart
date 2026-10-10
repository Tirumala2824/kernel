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

// Schema v3 (contracts v4): Pest ID sightings, BLE sensor nodes and their
// events, and the curated knowledge cards with cached embeddings. The v2 ->
// v3 migration only creates these tables, their indexes and triggers.

/// A Pest ID sighting (v3). Three separate records live side by side: the
/// AI analysis (`analysis`, `sound`; never edited after saving), the user's
/// validation (`user_validated`, `user_card_id`) and the human verified
/// finding (set once, trigger-guarded).
@DataClassName('SightingRow')
@TableIndex(name: 'sightings_observed', columns: {#observedAt})
@TableIndex(name: 'sightings_location', columns: {#locationId})
@TableIndex(name: 'sightings_item', columns: {#itemId})
class Sightings extends Table with TrackedColumns {
  TextColumn get role => textEnum<Role>()();
  TextColumn get source => textEnum<SignalSource>()();
  DateTimeColumn get observedAt => dateTime()();
  TextColumn get locationId => text().nullable().references(Locations, #id)();
  TextColumn get itemId => text().nullable().references(Items, #id)();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get accuracyMeters => real().nullable()();

  /// DistanceEstimate as JSON.
  TextColumn get distance =>
      text().map(const DistanceEstimateConverter()).nullable()();

  /// PestAnalysis as JSON. Immutable.
  TextColumn get analysis =>
      text().map(const PestAnalysisConverter()).nullable()();

  /// SoundAnalysis as JSON. Immutable.
  TextColumn get sound =>
      text().map(const SoundAnalysisConverter()).nullable()();
  BoolColumn get userValidated => boolean()();
  TextColumn get userCardId => text().nullable()();

  /// Human physical verification. Null until set once; never overwritten.
  TextColumn get verifiedFinding => textEnum<VerifiedFinding>().nullable()();
  TextColumn get notes => text().nullable()();

  /// App-private still or clip, only when the user chose to keep media.
  TextColumn get mediaPath => text().nullable()();
}

/// A paired BLE sensor node (v3). The per-device key is never stored here,
/// only its 8-hex-char fingerprint.
@DataClassName('SensorNodeRow')
class SensorNodes extends Table with TrackedColumns {
  TextColumn get deviceAddress => text().unique()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<SensorType>()();
  IntColumn get protocolVersion => integer()();
  TextColumn get firmwareVersion => text()();
  TextColumn get keyFingerprint => text()();
  TextColumn get locationId => text().nullable().references(Locations, #id)();
  TextColumn get itemId => text().nullable().references(Items, #id)();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  IntColumn get batteryPercent => integer().nullable()();

  /// Highest event seq removed by `deleteAllHistory`. Events at or below it
  /// are never re-imported from the node's store-and-forward buffer.
  IntColumn get eventsClearedThroughSeq => integer().nullable()();
}

/// One detection event from a node (v3): features only, never audio.
/// Append-only and unique on (node_id, seq). The node's placement at
/// record time is kept with the event.
@DataClassName('SensorEventRow')
@TableIndex(name: 'sensor_events_started', columns: {#startedAt})
@TableIndex(name: 'sensor_events_location', columns: {#locationId})
@TableIndex(name: 'sensor_events_item', columns: {#itemId})
class SensorEvents extends Table with TrackedColumns {
  TextColumn get nodeId => text().references(SensorNodes, #id)();
  IntColumn get seq => integer()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationMs => integer()();
  TextColumn get eventClass => textEnum<SensorEventClass>()();
  RealColumn get peakHz => real()();
  RealColumn get minHz => real()();
  RealColumn get maxHz => real()();
  RealColumn get slopeHzPerMs => real()();
  RealColumn get snrDb => real()();
  RealColumn get peakDbfs => real()();
  IntColumn get impulses => integer()();
  RealColumn get repRateHz => real()();
  IntColumn get harmonics => integer()();

  /// Signature match; all null when the event matched no signature.
  TextColumn get signatureId => text().nullable()();
  TextColumn get packVersion => text().nullable()();
  RealColumn get matchScore => real().nullable()();
  BoolColumn get matchExperimental => boolean().nullable()();

  /// Where the node was placed when the event was recorded.
  TextColumn get locationId => text().nullable().references(Locations, #id)();
  TextColumn get itemId => text().nullable().references(Items, #id)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {nodeId, seq},
  ];
}

/// Curated knowledge card (v3), loaded from the app's card pack
/// (docs/knowledge-cards.md). Reference content, not a user record.
@DataClassName('KnowledgeCardRow')
class KnowledgeCards extends Table with TrackedColumns {
  /// Stable snake_case card id from the pack.
  TextColumn get cardId => text().unique()();

  /// languageTag -> name as a JSON object; 'en' is always present.
  TextColumn get names => text().map(const StringMapConverter())();
  TextColumn get pestGroup => textEnum<PestGroup>()();
  TextColumn get safety => textEnum<SafetyLevel>()();
  TextColumn get summary => text()();
  TextColumn get signs => text().map(const StringListConverter())();
  TextColumn get lookAlikes => text().map(const StringListConverter())();
  TextColumn get healthRisks => text().map(const StringListConverter())();
  TextColumn get safeSteps => text().map(const StringListConverter())();
  TextColumn get callProfessionalWhen =>
      text().map(const StringListConverter())();
  TextColumn get firstAid => text().map(const StringListConverter())();
  TextColumn get legal => text().nullable()();
  TextColumn get sources => text().map(const StringListConverter())();
  TextColumn get reviewStatus => text()();

  /// The pack's `version`.
  TextColumn get packVersion => text()();

  /// Hash of the text that gets embedded; a change invalidates embeddings.
  TextColumn get contentHash => text()();
}

/// Cached on-device embedding of a card (v3), per model version and
/// Matryoshka dimension. Float32, little-endian.
@DataClassName('CardEmbeddingRow')
class CardEmbeddings extends Table with TrackedColumns {
  TextColumn get cardId => text().references(KnowledgeCards, #cardId)();
  TextColumn get modelVersion => text()();
  IntColumn get dim => integer()();
  BlobColumn get vector => blob()();

  /// The card's contentHash when this vector was computed.
  TextColumn get contentHash => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {cardId, modelVersion, dim},
  ];
}

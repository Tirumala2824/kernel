import 'advice.dart';
import 'enums.dart';

/// Columns every persisted entity carries, for optional sync later.
abstract interface class Tracked {
  String get id;
  DateTime get createdAt;
  DateTime get updatedAt;
  SyncState get syncState;
}

class GrainItem implements Tracked {
  const GrainItem({
    required this.id,
    required this.ownerRole,
    required this.label,
    required this.grainType,
    required this.quantity,
    required this.quantityUnit,
    required this.storageDate,
    required this.locationId,
    required this.lotId,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.harvestId,
    this.archivedAt,
  });

  @override
  final String id;
  final Role ownerRole;

  /// User-entered name, e.g. a sack or container label.
  final String label;
  final String grainType;
  final double quantity;
  final String quantityUnit;
  final DateTime storageDate;
  final String? locationId;
  final String? lotId;

  /// Farmer harvest this sack belongs to.
  final String? harvestId;

  /// Soft delete. Archived items are hidden from lists, queues and new
  /// reports; their scan history is kept unchanged.
  final DateTime? archivedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;

  bool get isArchived => archivedAt != null;
}

class GrainItemDraft {
  const GrainItemDraft({
    required this.ownerRole,
    required this.label,
    required this.grainType,
    required this.quantity,
    required this.quantityUnit,
    required this.storageDate,
    this.locationId,
    this.lotId,
    this.harvestId,
  });

  final Role ownerRole;
  final String label;
  final String grainType;
  final double quantity;
  final String quantityUnit;
  final DateTime storageDate;
  final String? locationId;
  final String? lotId;
  final String? harvestId;
}

class Location implements Tracked {
  const Location({
    required this.id,
    required this.type,
    required this.name,
    required this.parentId,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.archivedAt,
  });

  @override
  final String id;
  final LocationType type;
  final String name;
  final String? parentId;
  final DateTime? archivedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;

  bool get isArchived => archivedAt != null;
}

class LocationDraft {
  const LocationDraft({required this.type, required this.name, this.parentId});

  final LocationType type;
  final String name;
  final String? parentId;
}

class Lot implements Tracked {
  const Lot({
    required this.id,
    required this.code,
    required this.supplierId,
    required this.supplierName,
    required this.grainType,
    required this.declaredQuantity,
    required this.quantityUnit,
    required this.receivedAt,
    required this.screeningStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.archivedAt,
  });

  @override
  final String id;

  /// User-entered lot reference.
  final String code;
  final String? supplierId;
  final String? supplierName;
  final String grainType;
  final double declaredQuantity;
  final String quantityUnit;
  final DateTime receivedAt;
  final ScreeningStatus screeningStatus;
  final DateTime? archivedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;

  bool get isArchived => archivedAt != null;
}

class LotDraft {
  const LotDraft({
    required this.code,
    required this.grainType,
    required this.declaredQuantity,
    required this.quantityUnit,
    required this.receivedAt,
    this.supplierId,
    this.supplierName,
  });

  final String code;
  final String grainType;
  final double declaredQuantity;
  final String quantityUnit;
  final DateTime receivedAt;
  final String? supplierId;
  final String? supplierName;
}

/// A farmer's harvest, grouping the sacks registered from it.
class Harvest implements Tracked {
  const Harvest({
    required this.id,
    required this.name,
    required this.grainType,
    required this.harvestedAt,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.archivedAt,
  });

  @override
  final String id;
  final String name;
  final String grainType;
  final DateTime harvestedAt;
  final String? notes;
  final DateTime? archivedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;
}

class HarvestDraft {
  const HarvestDraft({
    required this.name,
    required this.grainType,
    required this.harvestedAt,
    this.notes,
  });

  final String name;
  final String grainType;
  final DateTime harvestedAt;
  final String? notes;
}

/// Persisted, immutable copy of a ScanOutcome. Append-only.
class ScanRecord implements Tracked {
  const ScanRecord({
    required this.id,
    required this.itemId,
    required this.capturedAt,
    required this.durationMs,
    required this.sampleRate,
    required this.quality,
    required this.qualityReasons,
    required this.modelVersion,
    required this.result,
    required this.confidence,
    required this.experimental,
    required this.latencyMs,
    required this.deviceModel,
    required this.osVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.audioRetained = false,
  });

  @override
  final String id;
  final String itemId;
  final DateTime capturedAt;
  final int durationMs;
  final int sampleRate;
  final ScanQuality quality;
  final List<QualityReason> qualityReasons;
  final String modelVersion;

  /// Predicted class. Kept separate from any Inspection.verifiedFinding.
  final Classification result;
  final double? confidence;
  final bool experimental;
  final int latencyMs;
  final String deviceModel;
  final String osVersion;
  final bool audioRetained;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;

  /// Eligible for ranking: usable recording with a real model result.
  bool get isValid =>
      quality == ScanQuality.pass && result != Classification.notEvaluated;
}

class Inspection implements Tracked {
  const Inspection({
    required this.id,
    required this.itemId,
    required this.scanId,
    required this.inspectedAt,
    required this.inspector,
    required this.observations,
    required this.verifiedFinding,
    required this.followUpStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.assignedTo,
    this.photoPaths = const [],
  });

  @override
  final String id;
  final String itemId;
  final String? scanId;
  final DateTime inspectedAt;
  final String inspector;
  final String observations;
  final VerifiedFinding verifiedFinding;
  final FollowUpStatus followUpStatus;

  /// Staff member responsible for the follow-up (FPO task assignment).
  final String? assignedTo;

  /// App-private evidence photos. Evidence for the inspection only, never
  /// acoustic proof.
  final List<String> photoPaths;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;
}

class InspectionDraft {
  const InspectionDraft({
    required this.itemId,
    required this.inspectedAt,
    required this.inspector,
    required this.observations,
    required this.verifiedFinding,
    this.scanId,
    this.followUpStatus = FollowUpStatus.open,
    this.assignedTo,
    this.photoPaths = const [],
  });

  final String itemId;
  final String? scanId;
  final DateTime inspectedAt;
  final String inspector;
  final String observations;
  final VerifiedFinding verifiedFinding;
  final FollowUpStatus followUpStatus;
  final String? assignedTo;
  final List<String> photoPaths;
}

class Reminder implements Tracked {
  const Reminder({
    required this.id,
    required this.itemId,
    required this.dueAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
  });

  @override
  final String id;
  final String itemId;
  final DateTime dueAt;
  final ReminderStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;
}

/// A research recording: a retained scan plus an explicit label. Used only
/// to build training data; never shown as a pest result.
class LabeledSample implements Tracked {
  const LabeledSample({
    required this.id,
    required this.scanId,
    required this.itemId,
    required this.label,
    required this.inspectionId,
    required this.grainType,
    required this.sackMaterial,
    required this.environment,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
  });

  @override
  final String id;
  final String scanId;
  final String itemId;
  final SampleLabel label;

  /// Inspection confirming the label. Required for clean and infested.
  final String? inspectionId;
  final String grainType;
  final String? sackMaterial;

  /// Free text, e.g. "quiet room", "warehouse, fans on".
  final String? environment;
  final String? notes;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;
}

class LabeledSampleDraft {
  const LabeledSampleDraft({
    required this.scanId,
    required this.label,
    required this.grainType,
    this.inspectionId,
    this.sackMaterial,
    this.environment,
    this.notes,
  });

  final String scanId;
  final SampleLabel label;
  final String? inspectionId;
  final String grainType;
  final String? sackMaterial;
  final String? environment;
  final String? notes;
}

class QueueEntry {
  const QueueEntry({
    required this.item,
    required this.latestValidScan,
    this.ageDays,
  });

  final GrainItem item;
  final ScanRecord latestValidScan;

  /// Whole days since [latestValidScan] was captured, when computed.
  final int? ageDays;

  /// Why the item ranks where it does. The UI localizes it.
  RankReason get reason => switch (latestValidScan.result) {
    Classification.infested => RankReason.infested,
    Classification.uncertain => RankReason.uncertain,
    _ => RankReason.clean,
  };
}

/// Output of RankingService: ranked items plus items with no comparable scan.
class InspectionQueue {
  const InspectionQueue({
    required this.ranked,
    required this.needsScan,
    required this.modelVersion,
  });

  /// Highest priority first.
  final List<QueueEntry> ranked;

  /// Items with no valid scan for [modelVersion]. Never shown as evaluated.
  final List<GrainItem> needsScan;

  /// Model version the ranked scans share; null when nothing is ranked.
  final String? modelVersion;

  /// True when any ranked scan came from an experimental model.
  bool get experimental => ranked.any((e) => e.latestValidScan.experimental);
}

class ReportScope {
  const ReportScope({
    required this.role,
    this.kind = ReportKind.history,
    this.locationId,
    this.lotId,
    this.harvestId,
    this.itemIds,
    this.narrative,
  });

  final Role role;
  final ReportKind kind;
  final String? locationId;
  final String? lotId;
  final String? harvestId;
  final List<String>? itemIds;

  /// Optional on-phone LLM draft the user chose to include. Reports render
  /// it in its own labelled section, separate from records and findings.
  final AdviceText? narrative;
}

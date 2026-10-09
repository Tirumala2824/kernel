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
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;
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
  });

  final Role ownerRole;
  final String label;
  final String grainType;
  final double quantity;
  final String quantityUnit;
  final DateTime storageDate;
  final String? locationId;
  final String? lotId;
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
  });

  @override
  final String id;
  final LocationType type;
  final String name;
  final String? parentId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;
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
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;
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
  });

  final String itemId;
  final String? scanId;
  final DateTime inspectedAt;
  final String inspector;
  final String observations;
  final VerifiedFinding verifiedFinding;
  final FollowUpStatus followUpStatus;
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

class QueueEntry {
  const QueueEntry({required this.item, required this.latestValidScan});

  final GrainItem item;
  final ScanRecord latestValidScan;
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
}

class ReportScope {
  const ReportScope({required this.role, this.locationId, this.lotId, this.itemIds});

  final Role role;
  final String? locationId;
  final String? lotId;
  final List<String>? itemIds;
}

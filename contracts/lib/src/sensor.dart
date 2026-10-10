import 'enums.dart';
import 'models.dart';

// Dedicated BLE frequency-detection sensor nodes (guardrails §10). Nodes do
// the FFT and detection on board and send compact features only; the phone
// matches them against a versioned, experimental signature pack. Events are
// signals, never diagnoses. Protocol: docs/sensor-protocol.md.

enum SensorType { usAir, contactPiezo, contactAccel, audioAir }

enum SensorLinkState {
  unpaired,
  pairing,
  connecting,
  connected,
  authenticated,
  disconnected,
  error,
}

enum SensorHealth {
  ok,
  jammed,
  clipped,
  lowBattery,
  surveyNeeded,
  authFailed,

  /// Capture errors on the node (I2S/SPI). Not evaluated.
  sensorFault,

  /// The node's ring overwrote events the phone had not synced. The gap is
  /// not evaluated.
  eventsOverwritten,
}

/// Health values that make a time window "not evaluated", never "nothing
/// there" (guardrails §10).
const notEvaluatedHealth = {
  SensorHealth.jammed,
  SensorHealth.clipped,
  SensorHealth.surveyNeeded,
  SensorHealth.sensorFault,
  SensorHealth.eventsOverwritten,
};

enum SensorEventClass {
  tonal,
  fmSweep,
  flatTone,
  impulseBurst,
  harmonic,
  pulsedChirp,
  continuousEmitter,
}

/// A paired node and where the user placed it.
class SensorNode implements Tracked {
  const SensorNode({
    required this.id,
    required this.deviceAddress,
    required this.name,
    required this.type,
    required this.protocolVersion,
    required this.firmwareVersion,
    required this.keyFingerprint,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    this.locationId,
    this.itemId,
    this.lastSeenAt,
    this.batteryPercent,
  });

  @override
  final String id;

  /// Stable BLE identity (public or static random address).
  final String deviceAddress;
  final String name;
  final SensorType type;
  final int protocolVersion;
  final String firmwareVersion;

  /// First 8 hex chars of sha256(device key). The key itself never leaves
  /// Android Keystore-backed storage.
  final String keyFingerprint;
  final String? locationId;
  final String? itemId;
  final DateTime? lastSeenAt;
  final int? batteryPercent;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final SyncState syncState;
}

class SignatureMatch {
  const SignatureMatch({
    required this.signatureId,
    required this.packVersion,
    required this.score,
    this.experimental = true,
  });

  /// e.g. 'mouse_usv', 'rat_22k', 'grain_larva', 'termite_drum'.
  final String signatureId;
  final String packVersion;

  /// Rule score in 0..1. Not a probability.
  final double score;
  final bool experimental;
}

/// One detection event reported by a node (features only, no audio).
class SensorEvent {
  const SensorEvent({
    required this.nodeId,
    required this.seq,
    required this.startedAt,
    required this.durationMs,
    required this.eventClass,
    required this.peakHz,
    required this.minHz,
    required this.maxHz,
    required this.slopeHzPerMs,
    required this.snrDb,
    required this.peakDbfs,
    required this.impulses,
    required this.repRateHz,
    required this.harmonics,
    this.match,
  });

  final String nodeId;

  /// Node sequence number; (nodeId, seq) is unique.
  final int seq;
  final DateTime startedAt;
  final int durationMs;
  final SensorEventClass eventClass;
  final double peakHz;
  final double minHz;
  final double maxHz;
  final double slopeHzPerMs;
  final double snrDb;
  final double peakDbfs;
  final int impulses;
  final double repRateHz;
  final int harmonics;
  final SignatureMatch? match;
}

/// Periodic band-energy summary for the live view.
class BandFrame {
  const BandFrame({
    required this.nodeId,
    required this.seq,
    required this.at,
    required this.frameMs,
    required this.noiseFloorDbfs,
    required this.bandEdgesHz,
    required this.bandsDbAboveFloor,
    required this.peakHz,
    required this.peakDbfs,
  });

  final String nodeId;
  final int seq;
  final DateTime at;
  final int frameMs;
  final double noiseFloorDbfs;

  /// n+1 edges for n bands.
  final List<double> bandEdgesHz;
  final List<double> bandsDbAboveFloor;
  final double peakHz;
  final double peakDbfs;
}

class SensorStatus {
  const SensorStatus({
    required this.nodeId,
    required this.linkState,
    required this.health,
    this.batteryPercent,
    this.rssi,
    this.errorCode,
    this.sessionActive = false,
  });

  final String nodeId;
  final SensorLinkState linkState;

  /// jammed/clipped mean "not evaluated", never "nothing there".
  final Set<SensorHealth> health;
  final int? batteryPercent;
  final int? rssi;

  /// Stable reason when [linkState] is error, for the UI to localize:
  /// 'bt_permission', 'bt_off', 're_pair_needed', 'not_visible',
  /// 'fgs_not_allowed', 'link'.
  final String? errorCode;

  /// A foreground monitoring session is running for this node.
  final bool sessionActive;

  /// Evaluation is off right now: any [notEvaluatedHealth], a link error, or
  /// no health reported yet.
  bool get notEvaluated =>
      linkState == SensorLinkState.error ||
      health.isEmpty ||
      health.any(notEvaluatedHealth.contains);
}

/// A node's health from [at] until the next change. Live status changes and
/// health records replayed from the node's ring (store-and-forward) both
/// arrive as changes, so a jam while the phone was away is still known.
class SensorHealthChange {
  const SensorHealthChange({
    required this.nodeId,
    required this.at,
    required this.health,
    this.seq,
  });

  final String nodeId;
  final DateTime at;
  final Set<SensorHealth> health;

  /// Ring sequence number when replayed from the node; null for live status.
  final int? seq;
}

/// A closed or open window during which a node was not evaluated.
class SensorNotEvaluatedPeriod {
  const SensorNotEvaluatedPeriod({
    required this.nodeId,
    required this.from,
    required this.health,
    this.until,
  });

  final String nodeId;
  final DateTime from;

  /// Null while still ongoing.
  final DateTime? until;

  /// The [notEvaluatedHealth] values seen in the window.
  final Set<SensorHealth> health;
}

class SensorPlacement {
  const SensorPlacement({this.locationId, this.itemId});

  final String? locationId;
  final String? itemId;
}

/// Phone-side link to sensor nodes (sensor-link plugin). Never throws for
/// radio problems; state is reported through [watchStatus].
abstract interface class SensorLink {
  /// Pairs via CompanionDeviceManager using the node's QR label payload
  /// (device address + per-device key). Null when the user cancels.
  Future<SensorNode?> associate({required String qrPayload});
  Future<void> forget(String nodeId);

  Stream<SensorStatus> watchStatus(String nodeId);
  Stream<BandFrame> liveBands(String nodeId);

  /// Events from every connected node, already signature-matched.
  Stream<SensorEvent> events();

  /// Health changes from every connected node, live and replayed from the
  /// node's ring, including an [SensorHealth.eventsOverwritten] gap.
  Stream<SensorHealthChange> healthChanges();

  /// Learns per-band noise floors and stationary lines (default 5 min).
  Future<void> startSurvey(
    String nodeId, {
    Duration duration = const Duration(minutes: 5),
  });

  /// Foreground-service monitoring session (overnight allowed).
  Future<void> startSession(String nodeId);
  Future<void> stopSession(String nodeId);

  /// Pulls store-and-forward events since the last synced seq; returns count.
  Future<int> syncEvents(String nodeId);
}

abstract interface class SensorNodeRepository {
  Future<SensorNode> upsert(SensorNode node);
  Future<SensorNode?> get(String id);
  Stream<List<SensorNode>> watchAll();
  Future<SensorNode> setPlacement(String id, SensorPlacement placement);
  Future<void> delete(String id);
}

abstract interface class SensorEventRepository {
  /// Idempotent on (nodeId, seq); returns how many were new.
  Future<int> record(List<SensorEvent> events);

  /// Newest first.
  Stream<List<SensorEvent>> watchForNode(String nodeId, {int limit = 500});
  Stream<List<SensorEvent>> watchForLocation(
    String locationId, {
    Duration? window,
  });
  Stream<List<SensorEvent>> watchForItem(String itemId, {Duration? window});

  /// Latest synced seq per node, for GET_EVENTS_SINCE.
  Future<int?> lastSeq(String nodeId);

  /// Idempotent on (nodeId, at, health). Consecutive equal health is merged.
  Future<void> recordHealth(List<SensorHealthChange> changes);

  /// Not-evaluated windows overlapping [window] (or all), newest first. A
  /// summary or rate whose window overlaps one must say "not evaluated".
  Stream<List<SensorNotEvaluatedPeriod>> watchNotEvaluated({
    String? nodeId,
    String? locationId,
    String? itemId,
    Duration? window,
  });
}

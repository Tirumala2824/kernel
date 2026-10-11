// Wire structures -> contracts types (SensorStatus health, SensorEvent, BandFrame).
import 'package:kernel_contracts/kernel_contracts.dart';

import 'protocol.dart';

const _notEvaluated = {
  SensorHealth.jammed,
  SensorHealth.clipped,
  SensorHealth.surveyNeeded,
  SensorHealth.authFailed,
  SensorHealth.sensorFault,
  SensorHealth.eventsOverwritten,
};

/// Maps Status.health bits to contracts health. Jammed, clipped and
/// survey-needed/surveying mean "not evaluated" (guardrails section 10).
/// `ok` appears only when nothing else applies and the sensor reports no fault.
Set<SensorHealth> healthFromBits(int bits, {bool authFailed = false}) {
  final out = <SensorHealth>{};
  if (bits & HealthBits.jammed != 0) out.add(SensorHealth.jammed);
  if (bits & HealthBits.clipped != 0) out.add(SensorHealth.clipped);
  if (bits & HealthBits.lowBattery != 0) out.add(SensorHealth.lowBattery);
  if (bits & (HealthBits.surveyNeeded | HealthBits.surveyActive) != 0) out.add(SensorHealth.surveyNeeded);
  if (authFailed) out.add(SensorHealth.authFailed);
  if (bits & HealthBits.sensorFault != 0) out.add(SensorHealth.sensorFault);
  if (bits & HealthBits.eventsOverwritten != 0) out.add(SensorHealth.eventsOverwritten);
  if (out.isEmpty) out.add(SensorHealth.ok);
  return out;
}

/// False when the node cannot currently be trusted to have listened.
bool isEvaluated(Set<SensorHealth> health) => health.isNotEmpty && !health.any(_notEvaluated.contains);

/// True for health bits that leave the node unable to evaluate.
bool bitsNotEvaluated(int bits) =>
    bits &
        (HealthBits.jammed |
            HealthBits.clipped |
            HealthBits.surveyNeeded |
            HealthBits.surveyActive |
            HealthBits.sensorFault |
            HealthBits.eventsOverwritten) !=
    0;

SensorType? sensorTypeFromWire(int t) => switch (t) {
      1 => SensorType.usAir,
      2 => SensorType.contactPiezo,
      3 => SensorType.contactAccel,
      4 => SensorType.audioAir,
      _ => null,
    };

int sensorTypeToWire(SensorType t) => switch (t) {
      SensorType.usAir => 1,
      SensorType.contactPiezo => 2,
      SensorType.contactAccel => 3,
      SensorType.audioAir => 4,
    };

/// Node clock reference from the latest Status read/notification.
class NodeClock {
  const NodeClock({required this.bootCount, required this.uptimeS, required this.receivedAt});
  final int bootCount;
  final int uptimeS;
  final DateTime receivedAt;
}

/// Wall-clock start of a node timestamp, or null when it cannot be resolved
/// (uptime-based from an earlier boot). Never guessed.
DateTime? nodeTime({
  required bool timeValid,
  required int tStartS,
  required int tStartMs,
  required int bootLow,
  NodeClock? clock,
}) {
  if (timeValid) return DateTime.fromMillisecondsSinceEpoch(tStartS * 1000 + tStartMs, isUtc: true);
  if (clock == null || (clock.bootCount & 0xFF) != bootLow) return null;
  final ageMs = (clock.uptimeS - tStartS) * 1000 - tStartMs;
  if (ageMs < 0) return null;
  return clock.receivedAt.toUtc().subtract(Duration(milliseconds: ageMs));
}

/// Builds the contracts event, or null if the class or the time is unknown.
SensorEvent? toSensorEvent(String nodeId, WireEvent e, {NodeClock? clock, SignatureMatch? match}) {
  if (e.eventClass < 0 || e.eventClass >= SensorEventClass.values.length) return null;
  final at = nodeTime(timeValid: e.timeValid, tStartS: e.tStartS, tStartMs: e.tStartMs, bootLow: e.bootLow, clock: clock);
  if (at == null) return null;
  return SensorEvent(
    nodeId: nodeId,
    seq: e.seq,
    startedAt: at,
    durationMs: e.durationMs,
    eventClass: SensorEventClass.values[e.eventClass],
    peakHz: e.peakHz,
    minHz: e.minHz,
    maxHz: e.maxHz,
    slopeHzPerMs: e.slopeHzPerMs,
    snrDb: e.snrDb,
    peakDbfs: e.peakDbfs.toDouble(),
    impulses: e.impulses,
    repRateHz: e.repRateHz,
    harmonics: e.harmonics,
    match: match,
  );
}

/// Live band frame for the UI. Uses the node time when resolvable, else the
/// phone's receive time (live view only; frames are never persisted).
BandFrame toBandFrame(String nodeId, WireBandFrame f, WireBandTable table, {required DateTime receivedAt}) {
  if (table.nBands != f.nBands) {
    throw ProtocolException('bandFrame has ${f.nBands} bands, table has ${table.nBands}');
  }
  final at = f.timeValid
      ? DateTime.fromMillisecondsSinceEpoch(f.tStartS * 1000 + f.tStartMs, isUtc: true)
      : receivedAt.toUtc();
  return BandFrame(
    nodeId: nodeId,
    seq: f.seq,
    at: at,
    frameMs: f.frameMs,
    noiseFloorDbfs: f.noiseFloorDeciDbfs / 10.0,
    bandEdgesHz: table.edgesHz,
    bandsDbAboveFloor: [for (final b in f.bandsHalfDb) b / 2.0],
    peakHz: f.peakHz10 * 10.0,
    peakDbfs: f.peakDeciDbfs / 10.0,
  );
}

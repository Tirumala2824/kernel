import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../l10n/l10n.dart';
import '../../widgets/status_chip.dart';

/// Prefix of a sensor node's QR label (docs/sensor-protocol.md). The rest
/// carries the device address and per-device key, which only SensorLink
/// reads; the app never shows, logs or stores the payload.
const sensorQrPrefix = 'kernel:sensor:v1:';

/// The trimmed payload when [raw] is a Kernel sensor label, else null.
String? parseSensorQrPayload(String raw) {
  final text = raw.trim();
  if (text.length <= sensorQrPrefix.length) return null;
  if (text.substring(0, sensorQrPrefix.length).toLowerCase() !=
      sensorQrPrefix) {
    return null;
  }
  final body = text.substring(sensorQrPrefix.length);
  if (body.contains(RegExp(r'\s'))) return null;
  return text;
}

extension SensorTypeCopy on SensorType {
  String label(AppLocalizations l) => switch (this) {
    SensorType.usAir => l.sensorTypeUsAir,
    SensorType.contactPiezo => l.sensorTypeContactPiezo,
    SensorType.contactAccel => l.sensorTypeContactAccel,
    SensorType.audioAir => l.sensorTypeAudioAir,
  };

  IconData get icon => switch (this) {
    SensorType.usAir => Icons.sensors_rounded,
    SensorType.contactPiezo ||
    SensorType.contactAccel => Icons.vibration_rounded,
    SensorType.audioAir => Icons.hearing_rounded,
  };
}

extension SensorLinkStateCopy on SensorLinkState {
  String label(AppLocalizations l) => switch (this) {
    SensorLinkState.unpaired => l.sensorLinkUnpaired,
    SensorLinkState.pairing => l.sensorLinkPairing,
    SensorLinkState.connecting => l.sensorLinkConnecting,
    SensorLinkState.connected => l.sensorLinkConnected,
    SensorLinkState.authenticated => l.sensorLinkAuthenticated,
    SensorLinkState.disconnected => l.sensorLinkDisconnected,
    SensorLinkState.error => l.sensorLinkError,
  };

  StatusTone get tone => switch (this) {
    SensorLinkState.connected ||
    SensorLinkState.authenticated => StatusTone.info,
    SensorLinkState.error => StatusTone.danger,
    _ => StatusTone.neutral,
  };

  IconData get icon => switch (this) {
    SensorLinkState.connected ||
    SensorLinkState.authenticated => Icons.bluetooth_connected_rounded,
    SensorLinkState.pairing ||
    SensorLinkState.connecting => Icons.bluetooth_searching_rounded,
    SensorLinkState.error => Icons.bluetooth_disabled_rounded,
    _ => Icons.bluetooth_rounded,
  };
}

/// Health states that mean the node's results are "not evaluated", never
/// "nothing there" (guardrails §10).
/// The contract's [notEvaluatedHealth] plus a failed security check, which
/// also means the node's data can't be trusted.
bool isNotEvaluated(Set<SensorHealth> health) =>
    health.any(notEvaluatedHealth.contains) ||
    health.contains(SensorHealth.authFailed);

extension SensorHealthCopy on SensorHealth {
  String label(AppLocalizations l) => switch (this) {
    SensorHealth.ok => l.sensorHealthOk,
    SensorHealth.jammed => l.sensorHealthJammed,
    SensorHealth.clipped => l.sensorHealthClipped,
    SensorHealth.lowBattery => l.sensorHealthLowBattery,
    SensorHealth.surveyNeeded => l.sensorHealthSurveyNeeded,
    SensorHealth.authFailed => l.sensorHealthAuthFailed,
    SensorHealth.sensorFault => l.sensorHealthSensorFault,
    SensorHealth.eventsOverwritten => l.sensorHealthEventsOverwritten,
  };

  StatusTone get tone => switch (this) {
    SensorHealth.ok => StatusTone.neutral,
    SensorHealth.authFailed => StatusTone.danger,
    _ => StatusTone.attention,
  };

  IconData get icon => switch (this) {
    SensorHealth.ok => Icons.check_rounded,
    SensorHealth.jammed => Icons.wifi_tethering_error_rounded,
    SensorHealth.clipped => Icons.graphic_eq_rounded,
    SensorHealth.lowBattery => Icons.battery_alert_rounded,
    SensorHealth.surveyNeeded => Icons.tune_rounded,
    SensorHealth.authFailed => Icons.gpp_bad_rounded,
    SensorHealth.sensorFault => Icons.error_outline_rounded,
    SensorHealth.eventsOverwritten => Icons.history_toggle_off_rounded,
  };
}

extension SensorEventClassCopy on SensorEventClass {
  String label(AppLocalizations l) => switch (this) {
    SensorEventClass.tonal => l.sensorClassTonal,
    SensorEventClass.fmSweep => l.sensorClassFmSweep,
    SensorEventClass.flatTone => l.sensorClassFlatTone,
    SensorEventClass.impulseBurst => l.sensorClassImpulse,
    SensorEventClass.harmonic => l.sensorClassHarmonic,
    SensorEventClass.pulsedChirp => l.sensorClassChirp,
    SensorEventClass.continuousEmitter => l.sensorClassEmitter,
  };
}

/// Plain name for a signature id from the experimental signature pack.
String signatureName(AppLocalizations l, String? signatureId) =>
    switch (signatureId) {
      null => l.sensorUnmatched,
      'mouse_usv' => l.sensorSigMouseUsv,
      'rat_22k' => l.sensorSigRat22k,
      'grain_larva' => l.sensorSigGrainLarva,
      'termite_drum' => l.sensorSigTermiteDrum,
      final id => l.sensorSigOther(id.replaceAll('_', ' ')),
    };

/// Recorded event counts for one signature (or unmatched events).
/// Event timestamps alone do not establish a watched window.
class SignatureSummary {
  const SignatureSummary({
    required this.signatureId,
    required this.packVersion,
    required this.count,
  });

  /// Null for events without a signature match.
  final String? signatureId;
  final String? packVersion;
  final int count;
}

/// Groups events by signature, most frequent first.
List<SignatureSummary> summarizeEvents(List<SensorEvent> events) {
  final groups = <String?, List<SensorEvent>>{};
  for (final e in events) {
    (groups[e.match?.signatureId] ??= []).add(e);
  }
  final summaries = [
    for (final MapEntry(:key, :value) in groups.entries)
      SignatureSummary(
        signatureId: key,
        packVersion: value.first.match?.packVersion,
        count: value.length,
      ),
  ]..sort((a, b) => b.count.compareTo(a.count));
  return summaries;
}

/// kHz with one decimal, e.g. "22.4".
String khz(double hz) => (hz / 1000).toStringAsFixed(1);

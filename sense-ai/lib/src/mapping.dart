import 'package:kernel_contracts/kernel_contracts.dart';

import 'sense_api.g.dart';
import 'sense_status.dart';

// Pigeon types -> contracts types. Pure functions, tested in test/.

SignalKind mapKind(NativeSignalKind k) => switch (k) {
  NativeSignalKind.motion => SignalKind.motion,
  NativeSignalKind.darkSpecks => SignalKind.darkSpecks,
  NativeSignalKind.eyeshine => SignalKind.eyeshine,
  NativeSignalKind.soundEvent => SignalKind.soundEvent,
};

double _unit(double v) => v.isNaN ? 0.0 : v.clamp(0.0, 1.0).toDouble();

NormalizedBox _box(double left, double top, double width, double height) {
  final l = _unit(left);
  final t = _unit(top);
  return NormalizedBox(
    left: l,
    top: t,
    width: _unit(width).clamp(0.0, 1.0 - l).toDouble(),
    height: _unit(height).clamp(0.0, 1.0 - t).toDouble(),
  );
}

DateTime _utc(int epochMs) =>
    DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);

SignalCandidate mapCandidate(NativeCandidate c) => SignalCandidate(
  id: c.id,
  source: SignalSource.camera,
  kind: mapKind(c.kind),
  score: _unit(c.score),
  detectedAt: _utc(c.detectedAtEpochMs),
  box: _box(c.left, c.top, c.width, c.height),
);

SignalCandidate mapSoundEvent(NativeSoundEvent e) => SignalCandidate(
  id: e.id,
  source: SignalSource.microphone,
  kind: SignalKind.soundEvent,
  score: _unit(e.score),
  detectedAt: _utc(e.detectedAtEpochMs),
  // Labels exist only when a sound model ran on the event window.
  hint: e.labelled ? e.hint : null,
);

ThermalLevel mapThermal(NativeThermalLevel t) => switch (t) {
  NativeThermalLevel.normal => ThermalLevel.normal,
  NativeThermalLevel.reducedFps => ThermalLevel.reducedFps,
  NativeThermalLevel.noStage1 => ThermalLevel.noStage1,
  NativeThermalLevel.paused => ThermalLevel.paused,
};

SenseCameraStatus mapCameraStatus(NativeCameraBatch b) => SenseCameraStatus(
  at: _utc(b.emittedAtEpochMs),
  thermalLevel: mapThermal(b.thermalLevel),
  thermalHeadroom: b.thermalHeadroom,
  cameraActive: b.cameraActive,
  gyroGated: b.gyroGated,
  torchOn: b.torchOn,
  lowLightBoostActive: b.lowLightBoostActive,
  analysisFps: b.analysisFps,
);

SenseCameraCapabilities mapCapabilities(NativeCameraCapabilities c) =>
    SenseCameraCapabilities(
      cameraPermission: c.cameraPermission,
      hasBackCamera: c.hasBackCamera,
      cameraBound: c.cameraBound,
      torchAvailable: c.torchAvailable,
      maxTorchStrength: c.maxTorchStrength,
      lowLightBoostSupported: c.lowLightBoostSupported,
      gyroAvailable: c.gyroAvailable,
    );

NativeBox? boxFor(SignalCandidate c) {
  final b = c.box;
  if (b == null) return null;
  return NativeBox(
    candidateId: c.id,
    left: b.left,
    top: b.top,
    width: b.width,
    height: b.height,
  );
}

CapturedStill mapStill(NativeStill s) => CapturedStill(
  stillId: s.stillId,
  contextImage: s.contextJpeg,
  tiles: [
    for (final t in s.tiles)
      ImageTile(
        candidateId: t.candidateId,
        box: _box(t.left, t.top, t.width, t.height),
        image: t.jpeg,
      ),
  ],
);

ScoredLabel mapLabel(NativeScoredLabel l) =>
    ScoredLabel(label: l.label, score: l.score);

NativeListenMode mapListenMode(ListenMode m) => switch (m) {
  ListenMode.general => NativeListenMode.general,
  ListenMode.mosquitoCloseUp => NativeListenMode.mosquitoCloseUp,
  ListenMode.night => NativeListenMode.night,
};

ListenStatus mapListenStatus(NativeListenStatus s) => ListenStatus(
  state: switch (s.state) {
    NativeListenState.listening => ListenState.listening,
    NativeListenState.stopped => ListenState.stopped,
    NativeListenState.failed => ListenState.failed,
  },
  mode: switch (s.mode) {
    NativeListenMode.general => ListenMode.general,
    NativeListenMode.mosquitoCloseUp => ListenMode.mosquitoCloseUp,
    NativeListenMode.night => ListenMode.night,
  },
  reason: s.reason,
  micVerified: s.micVerified,
  soundModelLoaded: s.soundModelLoaded,
  soundModelName: s.soundModelName,
);

DistanceCapability mapCapability(NativeDistanceCapability c) =>
    DistanceCapability(
      arcoreDepth: c.arcoreDepth,
      focusDistance: c.focusDistance,
      reason: c.reason,
    );

DistanceEstimate unavailableDistance(String reason) => DistanceEstimate(
  method: DistanceMethod.unavailable,
  unavailableReason: reason,
);

/// A measured method without a usable value is reported as unavailable,
/// never as a number the gates did not pass.
DistanceEstimate mapDistance(NativeDistance d) {
  final method = switch (d.method) {
    NativeDistanceMethod.arcoreDepth => DistanceMethod.arcoreDepth,
    NativeDistanceMethod.focusDistance => DistanceMethod.focusDistance,
    NativeDistanceMethod.unavailable => DistanceMethod.unavailable,
  };
  final m = d.meters;
  if (method == DistanceMethod.unavailable || m == null || m.isNaN || m <= 0) {
    return unavailableDistance(d.reason ?? DistanceReasons.measureFailed);
  }
  final low = d.lowMeters;
  final high = d.highMeters;
  return DistanceEstimate(
    method: method,
    meters: m,
    lowMeters: low != null && low <= m ? low : null,
    highMeters: high != null && high >= m ? high : null,
    confidence: d.confidence == null ? null : _unit(d.confidence!),
  );
}

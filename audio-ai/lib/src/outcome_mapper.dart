// Maps pigeon bridge types to the contracts types.
//
// The mapping is deliberately defensive. Whatever the native side reports,
// the produced ScanOutcome always satisfies the contract invariants: a RETRY
// or no-model outcome is notEvaluated, and a notEvaluated outcome never
// carries a confidence. The mapper never upgrades a result. It can only
// downgrade an inconsistent one to notEvaluated/RETRY.
import 'package:kernel_contracts/kernel_contracts.dart';

import 'scan_api.g.dart';

/// Target capture rate of the native pipeline (contracts: 16 kHz).
const int targetSampleRate = 16000;

/// Reported when the native side could not be reached at all, so the real
/// device identity is not known to Dart.
const String unknownDeviceField = 'unknown';

/// Lowest level the native meter reports (digital silence). Matches the
/// Kotlin QualityGate.MIN_DBFS.
const double minLevelDbfs = -120;

ScanOutcome mapScanResult(
  NativeScanResult result, {
  required String scanId,
  required String itemId,
  AudioInputSource inputSource = AudioInputSource.liveMic,
  SensorType? sensorType,
  String? sensorNodeId,
  String? sourceFileName,
}) {
  final reasons = <QualityReason>[];
  for (final reason in result.qualityReasons) {
    final mapped = _mapReason(reason);
    if (!reasons.contains(mapped)) reasons.add(mapped);
  }

  // PASS only if the native gate said pass and gave no reason to retry.
  final quality = result.qualityPass && reasons.isEmpty
      ? ScanQuality.pass
      : ScanQuality.retry;
  if (quality == ScanQuality.retry && reasons.isEmpty) {
    // Native reported a failure without a reason; never invent a signal
    // problem, report it as a capture/processing error.
    reasons.add(QualityReason.captureError);
  }

  final modelVersion = result.modelVersion.trim().isEmpty
      ? noModelVersion
      : result.modelVersion;
  final noModel = modelVersion == noModelVersion;

  var classification = _mapClassification(result.classification);
  var confidence = result.confidence;
  if (quality == ScanQuality.retry || noModel) {
    classification = Classification.notEvaluated;
  }
  if (confidence != null &&
      (confidence.isNaN || confidence < 0 || confidence > 1)) {
    // A real model never yields this; treat it as a failed inference.
    classification = Classification.notEvaluated;
  }
  if (classification == Classification.notEvaluated) confidence = null;

  final outcome = ScanOutcome(
    scanId: scanId,
    itemId: itemId,
    capturedAt: DateTime.fromMillisecondsSinceEpoch(
      result.capturedAtEpochMs,
      isUtc: true,
    ),
    quality: quality,
    qualityReasons: List.unmodifiable(reasons),
    classification: classification,
    confidence: confidence,
    experimental: noModel || result.experimental,
    modelVersion: modelVersion,
    latencyMs: _nonNegative(result.latencyMs),
    durationMs: _nonNegative(result.durationMs),
    sampleRate: _nonNegative(result.sampleRate),
    deviceModel: _orUnknown(result.deviceModel),
    osVersion: _orUnknown(result.osVersion),
    // Native sets this only after the WAV was actually written.
    audioRetained: result.audioRetained,
    inputSource: inputSource,
    sensorType: sensorType,
    sensorNodeId: sensorNodeId,
    sourceFileName: sourceFileName,
    asqiScore: result.asqiScore,
  );

  if (outcome.invariantViolations().isNotEmpty) {
    // Unreachable by construction; kept so a future edit cannot leak an
    // invalid outcome to the repositories. The WAV (if any) still exists,
    // so audioRetained keeps telling the truth about it.
    return failureOutcome(
      scanId: scanId,
      itemId: itemId,
      capturedAt: outcome.capturedAt,
      deviceModel: outcome.deviceModel,
      osVersion: outcome.osVersion,
      audioRetained: outcome.audioRetained,
      inputSource: inputSource,
      sensorType: sensorType,
      sensorNodeId: sensorNodeId,
      sourceFileName: sourceFileName,
      asqiScore: result.asqiScore,
    );
  }
  return outcome;
}

/// Outcome for a scan that could not be run or analysed (bridge failure,
/// unexpected exception). Nothing was evaluated.
ScanOutcome failureOutcome({
  required String scanId,
  required String itemId,
  required DateTime capturedAt,
  String deviceModel = unknownDeviceField,
  String osVersion = unknownDeviceField,
  bool audioRetained = false,
  AudioInputSource inputSource = AudioInputSource.liveMic,
  SensorType? sensorType,
  String? sensorNodeId,
  String? sourceFileName,
  double? asqiScore,
}) {
  return ScanOutcome(
    scanId: scanId,
    itemId: itemId,
    capturedAt: capturedAt.toUtc(),
    quality: ScanQuality.retry,
    qualityReasons: const [QualityReason.captureError],
    classification: Classification.notEvaluated,
    confidence: null,
    experimental: true,
    modelVersion: noModelVersion,
    latencyMs: 0,
    durationMs: 0,
    sampleRate: 0,
    deviceModel: deviceModel,
    osVersion: osVersion,
    audioRetained: audioRetained,
    inputSource: inputSource,
    sensorType: sensorType,
    sensorNodeId: sensorNodeId,
    sourceFileName: sourceFileName,
    asqiScore: asqiScore,
  );
}

EngineInfo mapEngineInfo(NativeEngineInfo info) {
  final modelVersion = info.modelVersion.trim().isEmpty
      ? noModelVersion
      : info.modelVersion;
  final modelPresent = info.modelPresent && modelVersion != noModelVersion;
  return EngineInfo(
    modelPresent: modelPresent,
    modelVersion: modelPresent ? modelVersion : noModelVersion,
    experimental: !modelPresent || info.experimental,
    targetSampleRate: info.targetSampleRate,
    effectiveSampleRate: _positiveOrNull(info.effectiveSampleRate),
    delegate: modelPresent
        ? _mapDelegate(info.delegate)
        : InferenceDelegate.none,
    deviceModel: _orUnknown(info.deviceModel),
    osVersion: _orUnknown(info.osVersion),
    // Provenance belongs to a model; with no usable model there is none.
    modelNote: modelPresent ? _trimmedOrNull(info.modelNote) : null,
    audioSource: _trimmedOrNull(info.audioSource),
    deviceInputSampleRate: _positiveOrNull(info.deviceInputSampleRate),
  );
}

/// Engine info when the native side cannot be reached. No model is usable.
EngineInfo unavailableEngineInfo() {
  return const EngineInfo(
    modelPresent: false,
    modelVersion: noModelVersion,
    experimental: true,
    targetSampleRate: targetSampleRate,
    effectiveSampleRate: null,
    delegate: InferenceDelegate.none,
    deviceModel: unknownDeviceField,
    osVersion: unknownDeviceField,
  );
}

/// Live level reading. Levels are display values, so anything outside the
/// meter's physical range [minLevelDbfs, 0] (or NaN) is pinned to it.
CaptureLevel mapCaptureLevel(NativeCaptureLevel level) {
  return CaptureLevel(
    elapsedMs: _nonNegative(level.elapsedMs),
    targetMs: _nonNegative(level.targetMs),
    rmsDbfs: _dbfs(level.rmsDbfs),
    peakDbfs: _dbfs(level.peakDbfs),
  );
}

QualityReason _mapReason(NativeQualityReason reason) => switch (reason) {
  NativeQualityReason.silence => QualityReason.silence,
  NativeQualityReason.clipping => QualityReason.clipping,
  NativeQualityReason.highNoise => QualityReason.highNoise,
  NativeQualityReason.tooShort => QualityReason.tooShort,
  NativeQualityReason.permissionDenied => QualityReason.permissionDenied,
  NativeQualityReason.captureError => QualityReason.captureError,
};

Classification _mapClassification(NativeClassification value) =>
    switch (value) {
      NativeClassification.clean => Classification.clean,
      NativeClassification.uncertain => Classification.uncertain,
      NativeClassification.infested => Classification.infested,
      NativeClassification.notEvaluated => Classification.notEvaluated,
    };

InferenceDelegate _mapDelegate(NativeDelegate value) => switch (value) {
  NativeDelegate.none => InferenceDelegate.none,
  NativeDelegate.cpu => InferenceDelegate.cpu,
  NativeDelegate.nnapi => InferenceDelegate.nnapi,
  NativeDelegate.gpu => InferenceDelegate.gpu,
};

int _nonNegative(int value) => value < 0 ? 0 : value;

int? _positiveOrNull(int? value) => value == null || value <= 0 ? null : value;

String _orUnknown(String value) =>
    value.trim().isEmpty ? unknownDeviceField : value;

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

double _dbfs(double value) =>
    value.isNaN ? minLevelDbfs : value.clamp(minLevelDbfs, 0.0).toDouble();

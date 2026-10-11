// Test-only scan engine double and scripted outcomes.

import 'dart:async';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';

const noModelInfo = EngineInfo(
  modelPresent: false,
  modelVersion: noModelVersion,
  experimental: true,
  targetSampleRate: 16000,
  effectiveSampleRate: null,
  delegate: InferenceDelegate.none,
  deviceModel: 'test-device',
  osVersion: 'test-os',
);

/// Returns a scripted outcome per call. Levels in [levelScript] are emitted
/// on [captureLevels] during each capture; set [gate] to hold the capture
/// open while a test pushes levels with [emitLevel].
class ScriptedScanEngine implements ScanEngine {
  ScriptedScanEngine({ScanOutcome Function(String itemId)? next})
    : next = next ?? notEvaluatedOutcome;

  ScanOutcome Function(String itemId) next;
  EngineInfo engineInfo = noModelInfo;
  List<CaptureLevel> levelScript = const [];
  Completer<void>? gate;
  final calls = <({String itemId, bool retainAudio, bool haptics})>[];
  final _levels = StreamController<CaptureLevel>.broadcast();
  int deleteRetainedAudioCalls = 0;

  bool get hasLevelListener => _levels.hasListener;

  void emitLevel(CaptureLevel level) => _levels.add(level);
  void failLevels(Object error) => _levels.addError(error);
  Future<void> closeLevels() => _levels.close();

  @override
  Future<ScanOutcome> captureAndAnalyze(
    String itemId, {
    bool retainAudio = false,
    bool haptics = true,
  }) async {
    calls.add((itemId: itemId, retainAudio: retainAudio, haptics: haptics));
    for (final level in levelScript) {
      _levels.add(level);
    }
    final hold = gate;
    if (hold != null) await hold.future;
    final outcome = next(itemId);
    if (!retainAudio || outcome.audioRetained) return outcome;
    return _withRetained(outcome);
  }

  @override
  Future<ScanOutcome> analyzeAudioFile(
    String itemId,
    String filePath, {
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
    bool retainAudio = false,
  }) async {
    final outcome = next(itemId);
    return ScanOutcome(
      scanId: outcome.scanId,
      itemId: outcome.itemId,
      capturedAt: outcome.capturedAt,
      quality: outcome.quality,
      qualityReasons: outcome.qualityReasons,
      classification: outcome.classification,
      confidence: outcome.confidence,
      experimental: outcome.experimental,
      modelVersion: outcome.modelVersion,
      latencyMs: outcome.latencyMs,
      durationMs: outcome.durationMs,
      sampleRate: outcome.sampleRate,
      deviceModel: outcome.deviceModel,
      osVersion: outcome.osVersion,
      audioRetained: retainAudio || outcome.audioRetained,
      inputSource: AudioInputSource.fileUpload,
      sensorType: sensorType,
      sensorNodeId: sensorNodeId,
      sourceFileName: filePath.split(RegExp(r'[/\\]')).last,
      asqiScore: outcome.asqiScore ?? 0.85,
    );
  }

  @override
  Stream<CaptureLevel> captureLevels() => _levels.stream;

  @override
  Future<EngineInfo> info() async => engineInfo;

  @override
  Future<void> deleteRetainedAudio() async => deleteRetainedAudioCalls++;

  @override
  Future<String?> retainedAudioPath(String scanId) async => null;
}

ScanOutcome _withRetained(ScanOutcome o) => ScanOutcome(
  scanId: o.scanId,
  itemId: o.itemId,
  capturedAt: o.capturedAt,
  quality: o.quality,
  qualityReasons: o.qualityReasons,
  classification: o.classification,
  confidence: o.confidence,
  experimental: o.experimental,
  modelVersion: o.modelVersion,
  latencyMs: o.latencyMs,
  durationMs: o.durationMs,
  sampleRate: o.sampleRate,
  deviceModel: o.deviceModel,
  osVersion: o.osVersion,
  audioRetained: true,
);

CaptureLevel level(int elapsedMs, double rms, {double? peak}) => CaptureLevel(
  elapsedMs: elapsedMs,
  targetMs: 2000,
  rmsDbfs: rms,
  peakDbfs: peak ?? rms + 12,
);

ScanOutcome notEvaluatedOutcome(
  String itemId, {
  DateTime? at,
  bool retained = false,
}) => ScanOutcome(
  scanId: testId('scan'),
  itemId: itemId,
  capturedAt: (at ?? DateTime.now()).toUtc(),
  quality: ScanQuality.pass,
  qualityReasons: const [],
  classification: Classification.notEvaluated,
  confidence: null,
  experimental: true,
  modelVersion: noModelVersion,
  latencyMs: 40,
  durationMs: 2000,
  sampleRate: 16000,
  deviceModel: 'test-device',
  osVersion: 'test-os',
  audioRetained: retained,
);

/// A real-model outcome (for result-state tests only).
ScanOutcome modelOutcome(
  String itemId,
  Classification classification, {
  String version = 'proxy-1',
  double confidence = 0.61,
  DateTime? at,
}) => ScanOutcome(
  scanId: testId('scan'),
  itemId: itemId,
  capturedAt: (at ?? DateTime.now()).toUtc(),
  quality: ScanQuality.pass,
  qualityReasons: const [],
  classification: classification,
  confidence: confidence,
  experimental: true,
  modelVersion: version,
  latencyMs: 55,
  durationMs: 2000,
  sampleRate: 16000,
  deviceModel: 'test-device',
  osVersion: 'test-os',
);

ScanOutcome retryOutcome(
  String itemId, {
  List<QualityReason> reasons = const [QualityReason.highNoise],
  DateTime? at,
}) => ScanOutcome(
  scanId: testId('scan'),
  itemId: itemId,
  capturedAt: (at ?? DateTime.now()).toUtc(),
  quality: ScanQuality.retry,
  qualityReasons: reasons,
  classification: Classification.notEvaluated,
  confidence: null,
  experimental: true,
  modelVersion: noModelVersion,
  latencyMs: 35,
  durationMs: 2000,
  sampleRate: 16000,
  deviceModel: 'test-device',
  osVersion: 'test-os',
);

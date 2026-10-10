import 'enums.dart';
import 'scan_outcome.dart';
import 'sensor.dart';

/// On-device acoustic scanning engine. Owned by audio-ai.
abstract interface class ScanEngine {
  /// Records ~2 s of mono PCM (target 16 kHz), runs the quality gate, then
  /// local inference. Never throws for audio or model problems; those are
  /// reported as [ScanQuality.retry] or [Classification.notEvaluated].
  ///
  /// [retainAudio] mirrors the user's explicit opt-in (or a research
  /// recording); when false the audio buffer is discarded after analysis.
  /// [haptics] mirrors the in-app haptics setting.
  Future<ScanOutcome> captureAndAnalyze(
    String itemId, {
    bool retainAudio = false,
    bool haptics = true,
  });

  /// Analyzes an existing audio file (.wav) with acoustic sensor provenance.
  /// [sensorType] specifies the sensor transducer used (piezo, audioAir, etc.).
  /// [sensorNodeId] optionally associates the audio with a paired BLE node.
  Future<ScanOutcome> analyzeAudioFile(
    String itemId,
    String filePath, {
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
    bool retainAudio = false,
  });

  /// Live input levels while a capture is running (~20 Hz). Levels only,
  /// never samples. Emits nothing when no capture is in progress.
  Stream<CaptureLevel> captureLevels();

  Future<EngineInfo> info();

  /// Deletes every recording retained under the audio opt-in. Safe to call
  /// when nothing was retained. Called by PrivacyService.deleteAllHistory.
  Future<void> deleteRetainedAudio();

  /// Absolute path of the retained WAV for [scanId], or null if none.
  /// Used by DatasetExportService.
  Future<String?> retainedAudioPath(String scanId);
}

class CaptureLevel {
  const CaptureLevel({
    required this.elapsedMs,
    required this.targetMs,
    required this.rmsDbfs,
    required this.peakDbfs,
  });

  final int elapsedMs;
  final int targetMs;
  final double rmsDbfs;
  final double peakDbfs;

  double get progress => targetMs == 0 ? 0 : (elapsedMs / targetMs).clamp(0, 1);
}

class EngineInfo {
  const EngineInfo({
    required this.modelPresent,
    required this.modelVersion,
    required this.experimental,
    required this.targetSampleRate,
    required this.effectiveSampleRate,
    required this.delegate,
    required this.deviceModel,
    required this.osVersion,
    this.modelNote,
    this.audioSource,
    this.deviceInputSampleRate,
  });

  final bool modelPresent;
  final String modelVersion;
  final bool experimental;
  final int targetSampleRate;

  /// Null until the device has been probed.
  final int? effectiveSampleRate;
  final InferenceDelegate delegate;
  final String deviceModel;
  final String osVersion;

  /// Human-readable provenance from the model manifest, e.g. that a model
  /// was trained on non-grain proxy recordings. Shown with every result.
  final String? modelNote;

  /// Android audio source in use, e.g. VOICE_RECOGNITION.
  final String? audioSource;

  /// Hardware input rate before any resampling.
  final int? deviceInputSampleRate;
}

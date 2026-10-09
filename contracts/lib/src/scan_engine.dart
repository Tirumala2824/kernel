import 'enums.dart';
import 'scan_outcome.dart';

/// On-device acoustic scanning engine. Owned by audio-ai.
abstract interface class ScanEngine {
  /// Records ~2 s of mono PCM (target 16 kHz), runs the quality gate, then
  /// local inference. Never throws for audio or model problems; those are
  /// reported as [ScanQuality.retry] or [Classification.notEvaluated].
  ///
  /// [retainAudio] mirrors the user's explicit opt-in; when false the audio
  /// buffer is discarded after analysis.
  Future<ScanOutcome> captureAndAnalyze(String itemId, {bool retainAudio = false});

  Future<EngineInfo> info();

  /// Deletes every recording retained under the audio opt-in. Safe to call
  /// when nothing was retained. Called by PrivacyService.deleteAllHistory.
  Future<void> deleteRetainedAudio();
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
}

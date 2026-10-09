// Pigeon definition for the audio-ai Dart <-> Kotlin bridge.
//
// Regenerate after any change (from audio-ai/):
//   dart run pigeon --input pigeons/scan_api.dart
//
// This bridge is internal to audio-ai. The app only sees the contracts types
// (ScanOutcome, EngineInfo, CaptureLevel) through NativeScanEngine.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'audio_ai',
    dartOut: 'lib/src/scan_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/com/kernel/audio_ai/ScanApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.kernel.audio_ai',
      errorClassName: 'ScanApiError',
    ),
  ),
)
/// Mirrors contracts QualityReason.
enum NativeQualityReason {
  silence,
  clipping,
  highNoise,
  tooShort,
  permissionDenied,
  captureError,
}

/// Mirrors contracts Classification.
enum NativeClassification { clean, uncertain, infested, notEvaluated }

/// Mirrors contracts InferenceDelegate.
enum NativeDelegate { none, cpu, nnapi, gpu }

/// One capture plus analysis, as produced by the Kotlin engine.
class NativeScanResult {
  NativeScanResult({
    required this.qualityPass,
    required this.qualityReasons,
    required this.classification,
    required this.confidence,
    required this.experimental,
    required this.modelVersion,
    required this.capturedAtEpochMs,
    required this.latencyMs,
    required this.durationMs,
    required this.sampleRate,
    required this.deviceModel,
    required this.osVersion,
    required this.audioRetained,
  });

  bool qualityPass;
  List<NativeQualityReason> qualityReasons;
  NativeClassification classification;

  /// Null unless a real bundled model produced [classification].
  double? confidence;
  bool experimental;

  /// "none" when no model asset is bundled.
  String modelVersion;

  /// UTC epoch milliseconds at the start of the kept audio (or of the call
  /// when nothing was recorded).
  int capturedAtEpochMs;

  /// Capture end -> result ready, measured on the native side: quality gate
  /// + resampling + log-mel + inference. Per-stage timings go to logcat
  /// (tag AudioAi) in debuggable builds.
  int latencyMs;

  /// Actual recorded duration of the kept audio.
  int durationMs;

  /// Sample rate AudioRecord really delivered (0 if nothing was recorded).
  int sampleRate;
  String deviceModel;
  String osVersion;

  /// True only if the WAV for this scan was actually written to
  /// app-private `files/recordings/<scanId>.wav`.
  bool audioRetained;
}

class NativeEngineInfo {
  NativeEngineInfo({
    required this.modelPresent,
    required this.modelVersion,
    required this.experimental,
    required this.targetSampleRate,
    required this.effectiveSampleRate,
    required this.delegate,
    required this.deviceModel,
    required this.osVersion,
    required this.modelNote,
    required this.audioSource,
    required this.deviceInputSampleRate,
  });

  bool modelPresent;
  String modelVersion;
  bool experimental;
  int targetSampleRate;

  /// Null until a capture has run in this process.
  int? effectiveSampleRate;
  NativeDelegate delegate;
  String deviceModel;
  String osVersion;

  /// `note` from the bundled model's manifest; null with no model.
  String? modelNote;

  /// Android AudioSource used for capture, e.g. "VOICE_RECOGNITION".
  String? audioSource;

  /// Rate the audio HAL captured at (before any resampling), from the
  /// AudioRecordingConfiguration of the last capture (API 29+). Null until a
  /// capture has run in this process, or below API 29.
  int? deviceInputSampleRate;
}

/// One live input-level reading during a capture. Scalars only: never
/// samples or spectra.
class NativeCaptureLevel {
  NativeCaptureLevel({
    required this.elapsedMs,
    required this.targetMs,
    required this.rmsDbfs,
    required this.peakDbfs,
  });

  /// Kept audio recorded so far (excludes the warm-up discard).
  int elapsedMs;

  /// Kept audio the capture is aiming for.
  int targetMs;

  /// RMS of the last ~50 ms window after removing its mean, in dBFS.
  double rmsDbfs;

  /// Largest absolute sample of the last ~50 ms window, in dBFS.
  double peakDbfs;
}

@HostApi()
abstract class ScanHostApi {
  /// Records ~2 s, runs the quality gate and (only with a real bundled model)
  /// inference. Audio/model problems come back as a RETRY or NOT_EVALUATED
  /// result, not as errors. [scanId] names the WAV file when [retainAudio]
  /// is true. [haptics] false means no vibration cue at all.
  @async
  NativeScanResult captureAndAnalyze(
    String scanId,
    bool retainAudio,
    bool haptics,
  );

  @async
  NativeEngineInfo info();

  /// Deletes every retained recording in app-private storage. Returns the
  /// number of files deleted.
  @async
  int deleteRetainedAudio();

  /// Absolute path of `files/recordings/<scanId>.wav` if it exists, else
  /// null (also null for an id that is not a UUID).
  @async
  String? retainedAudioPath(String scanId);
}

/// Live levels while a capture runs (~20 Hz). Nothing is sent while idle.
@EventChannelApi()
abstract class CaptureLevelEvents {
  NativeCaptureLevel captureLevels();
}

// Pigeon definition for the sense-ai Dart <-> Kotlin bridge.
//
// Regenerate after any change (from sense-ai/):
//   dart run pigeon --input pigeons/sense_api.dart
//
// Internal to sense-ai. The app only sees the contracts types
// (SignalCandidate, CapturedStill, DistanceEstimate, ...) through SenseEngine.
// Images and audio cross this bridge only as in-memory bytes; nothing here
// writes to disk except keepMedia, which the app calls only when the user
// saves a sighting with "keep media" on.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'sense_ai',
    dartOut: 'lib/src/sense_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/com/kernel/sense_ai/SenseApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.kernel.sense_ai',
      errorClassName: 'SenseApiError',
    ),
  ),
)
/// Stage-0 detector kinds produced natively. Stage 1 (embeddingMatch) runs
/// in Dart.
enum NativeSignalKind { motion, darkSpecks, eyeshine, soundEvent }

/// Thermal step-down state from PowerManager.getThermalHeadroom.
enum NativeThermalLevel {
  /// Headroom below 0.85, or not reported by the device.
  normal,

  /// Headroom at or above 0.85: Stage-0 analysis rate is lowered.
  reducedFps,

  /// Headroom at or above 0.95: Stage 1 (embeddings) must not run.
  noStage1,

  /// Headroom at or above 1.0: the camera is paused.
  paused,
}

enum NativeListenMode { general, mosquitoCloseUp, night }

enum NativeListenState { listening, stopped, failed }

enum NativeDistanceMethod { arcoreDepth, focusDistance, unavailable }

/// Box in normalised upright image coordinates (0..1, origin top-left).
class NativeBox {
  NativeBox({
    required this.candidateId,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  String candidateId;
  double left;
  double top;
  double width;
  double height;
}

class NativeCandidate {
  NativeCandidate({
    required this.id,
    required this.kind,
    required this.score,
    required this.detectedAtEpochMs,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Stable while the detector keeps tracking the same region.
  String id;
  NativeSignalKind kind;

  /// Detector score in 0..1. Not a probability.
  double score;
  int detectedAtEpochMs;
  double left;
  double top;
  double width;
  double height;
}

/// One throttled Stage-0 update (at most 5 Hz) plus pipeline metadata.
class NativeCameraBatch {
  NativeCameraBatch({
    required this.candidates,
    required this.emittedAtEpochMs,
    required this.thermalLevel,
    required this.thermalHeadroom,
    required this.cameraActive,
    required this.gyroGated,
    required this.torchOn,
    required this.lowLightBoostActive,
    required this.analysisFps,
  });

  List<NativeCandidate> candidates;
  int emittedAtEpochMs;
  NativeThermalLevel thermalLevel;

  /// Last PowerManager.getThermalHeadroom reading; null below API 30 or when
  /// the device does not report it.
  double? thermalHeadroom;

  /// Camera bound and streaming (false while paused for heat or detached).
  bool cameraActive;

  /// The last frame was skipped because the phone was rotating.
  bool gyroGated;
  bool torchOn;
  bool lowLightBoostActive;

  /// Stage-0 frames analysed per second over the last second.
  double analysisFps;
}

class NativeCameraCapabilities {
  NativeCameraCapabilities({
    required this.cameraPermission,
    required this.hasBackCamera,
    required this.cameraBound,
    required this.torchAvailable,
    required this.maxTorchStrength,
    required this.lowLightBoostSupported,
    required this.gyroAvailable,
  });

  bool cameraPermission;
  bool hasBackCamera;

  /// A SenseCameraPreview is mounted and the camera is bound.
  bool cameraBound;
  bool torchAvailable;

  /// Torch strength steps (API 35+); 1 when only on/off is supported.
  int maxTorchStrength;

  /// CameraX Low Light Boost (API 35+, per device). Null-free: false when
  /// unknown because the camera is not bound yet.
  bool lowLightBoostSupported;
  bool gyroAvailable;
}

class NativeTile {
  NativeTile({
    required this.candidateId,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.jpeg,
  });

  String candidateId;
  double left;
  double top;
  double width;
  double height;
  Uint8List jpeg;
}

class NativeStill {
  NativeStill({
    required this.stillId,
    required this.contextJpeg,
    required this.tiles,
    required this.fullWidth,
    required this.fullHeight,
    required this.capturedAtEpochMs,
  });

  String stillId;

  /// Upright downscaled frame, 1024 px long edge.
  Uint8List contextJpeg;
  List<NativeTile> tiles;

  /// Upright size of the full-resolution still held in memory.
  int fullWidth;
  int fullHeight;
  int capturedAtEpochMs;
}

class NativeScoredLabel {
  NativeScoredLabel({
    required this.label,
    required this.score,
    required this.classIndex,
  });

  String label;

  /// Raw classifier score, not calibrated.
  double score;
  int classIndex;
}

class NativeSoundEvent {
  NativeSoundEvent({
    required this.id,
    required this.score,
    required this.detectedAtEpochMs,
    required this.hint,
    required this.labelled,
    required this.onsetCount,
  });

  String id;

  /// Detector score in 0..1 (flux + band coverage). Not a probability.
  double score;
  int detectedAtEpochMs;

  /// Best allow-listed classifier label, when a sound model ran.
  String? hint;

  /// True when the sound model ran on this event's window.
  bool labelled;

  /// Onsets merged into this event.
  int onsetCount;
}

class NativeListenStatus {
  NativeListenStatus({
    required this.state,
    required this.mode,
    required this.reason,
    required this.micVerified,
    required this.soundModelLoaded,
    required this.soundModelName,
  });

  NativeListenState state;
  NativeListenMode mode;

  /// Reason key when stopped or failed: permission_denied,
  /// builtin_mic_unavailable, mic_rerouted, app_not_visible, capture_error,
  /// stopped_from_notification.
  String? reason;

  /// AudioRecord.getRoutedDevice() confirmed TYPE_BUILTIN_MIC.
  bool micVerified;
  bool soundModelLoaded;

  /// File name of the sound model in use (no directories).
  String? soundModelName;
}

class NativeDistanceCapability {
  NativeDistanceCapability({
    required this.arcoreDepth,
    required this.focusDistance,
    required this.reason,
  });

  bool arcoreDepth;
  bool focusDistance;
  String? reason;
}

class NativeDistance {
  NativeDistance({
    required this.method,
    required this.meters,
    required this.lowMeters,
    required this.highMeters,
    required this.confidence,
    required this.reason,
  });

  NativeDistanceMethod method;
  double? meters;
  double? lowMeters;
  double? highMeters;
  double? confidence;
  String? reason;
}

@HostApi()
abstract class SenseHostApi {
  @async
  NativeCameraCapabilities cameraCapabilities();

  /// Full-resolution still (held in memory), upright 1024 px context image
  /// and 512-768 px tiles around [boxes], or a grid when [boxes] is empty.
  /// Null when no camera is bound or the capture failed.
  @async
  NativeStill? captureStill(List<NativeBox> boxes);

  /// 0 = off, 1 = brightest supported strength.
  @async
  void setTorch(double level);

  /// Torch on for [durationMs], then back to the previous level. Eyeshine is
  /// looked for during the pulse.
  @async
  void pulseTorch(int durationMs);

  void setLowLightBoost(bool enabled);

  /// Starts the listen session (own AudioRecord on TYPE_BUILTIN_MIC). The
  /// returned status is `listening` or `failed` with a reason.
  @async
  NativeListenStatus startListening(
    NativeListenMode mode,
    String? soundModelPath,
  );

  void stopListening();

  /// RIFF WAV (mono, 16 kHz, 16-bit, at most 30 s) held in memory.
  Uint8List? clipFor(String candidateId);

  List<NativeScoredLabel> soundLabelsFor(String candidateId);

  @async
  NativeDistanceCapability distanceCapability();

  @async
  NativeDistance measure(NativeBox? target);

  /// Drops every still, tile and audio buffer held natively.
  void discardMedia();

  /// Writes the held full-resolution still (by stillId) or clip (by
  /// candidate id) to app-private storage and returns its absolute path.
  /// Only for a sighting the user saves with "keep media" on.
  @async
  String? keepMedia(String mediaId);
}

@EventChannelApi()
abstract class SenseEvents {
  NativeCameraBatch cameraBatches();
  NativeSoundEvent soundEvents();
  NativeListenStatus listenStatus();
}

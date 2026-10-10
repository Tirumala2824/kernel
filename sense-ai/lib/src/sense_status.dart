import 'package:kernel_contracts/kernel_contracts.dart';

/// Thermal step-down from PowerManager.getThermalHeadroom (polled at most
/// every 10 s): 0.85 lowers the Stage-0 rate, 0.95 stops Stage 1, 1.0
/// pauses the camera.
enum ThermalLevel { normal, reducedFps, noStage1, paused }

/// Camera pipeline metadata that travels with each Stage-0 batch (at most
/// 5 Hz, plus an update whenever the camera stops).
class SenseCameraStatus {
  const SenseCameraStatus({
    required this.at,
    required this.thermalLevel,
    required this.thermalHeadroom,
    required this.cameraActive,
    required this.gyroGated,
    required this.torchOn,
    required this.lowLightBoostActive,
    required this.analysisFps,
  });

  final DateTime at;
  final ThermalLevel thermalLevel;

  /// Last headroom reading; null below Android 11 or when not reported.
  final double? thermalHeadroom;

  /// Camera bound and streaming. False while detached, behind another
  /// screen, measuring, or paused for heat.
  final bool cameraActive;

  /// The last frame was skipped because the phone was rotating.
  final bool gyroGated;
  final bool torchOn;
  final bool lowLightBoostActive;

  /// Stage-0 frames analysed per second.
  final double analysisFps;

  /// Stage 1 (embeddings) may run at this thermal level.
  bool get stage1Allowed => thermalLevel.index < ThermalLevel.noStage1.index;
}

class SenseCameraCapabilities {
  const SenseCameraCapabilities({
    required this.cameraPermission,
    required this.hasBackCamera,
    required this.cameraBound,
    required this.torchAvailable,
    required this.maxTorchStrength,
    required this.lowLightBoostSupported,
    required this.gyroAvailable,
  });

  final bool cameraPermission;
  final bool hasBackCamera;

  /// A [SenseCameraPreview] is mounted and the camera is bound.
  final bool cameraBound;
  final bool torchAvailable;

  /// Torch strength steps (Android 15+); 1 means on/off only.
  final int maxTorchStrength;

  /// Low Light Boost (Android 15+, per device). Known once the camera is bound.
  final bool lowLightBoostSupported;
  final bool gyroAvailable;
}

enum ListenState { listening, stopped, failed }

class ListenStatus {
  const ListenStatus({
    required this.state,
    required this.mode,
    required this.micVerified,
    required this.soundModelLoaded,
    this.reason,
    this.soundModelName,
  });

  final ListenState state;
  final ListenMode mode;

  /// A [ListenReasons] key when stopped or failed.
  final String? reason;

  /// Android confirmed the capture is routed to the built-in microphone.
  final bool micVerified;
  final bool soundModelLoaded;

  /// File name of the sound model in use.
  final String? soundModelName;
}

/// Error added to a [SenseEngine.listen] stream before it closes when
/// listening could not start or stopped on its own.
class SenseException implements Exception {
  const SenseException(this.reason);

  /// A [ListenReasons] key.
  final String reason;

  @override
  String toString() => 'SenseException($reason)';
}

/// Reason keys for [DistanceEstimate.unavailableReason] and
/// [DistanceCapability.reason]. The app localizes them.
abstract final class DistanceReasons {
  static const arcoreUnsupported = 'arcore_unsupported';
  static const moveSlowly = 'move_phone_slowly';
  static const tapToFocus = 'tap_to_focus';
  static const outOfRange = 'out_of_range';

  /// ARCore could work on this phone but is not installed or too old
  /// (capability only; the app never installs it).
  static const arcoreNotInstalled = 'arcore_not_installed';

  /// The user closed the Measure screen.
  static const cancelled = 'cancelled';
  static const cameraPermission = 'camera_permission';

  /// No visible activity, another measurement running, or a bridge failure.
  static const measureFailed = 'measure_failed';
}

/// Reason keys for [ListenStatus.reason] and [SenseException.reason].
abstract final class ListenReasons {
  static const permissionDenied = 'permission_denied';
  static const builtinMicUnavailable = 'builtin_mic_unavailable';
  static const micRerouted = 'mic_rerouted';
  static const appNotVisible = 'app_not_visible';
  static const captureError = 'capture_error';
  static const stoppedFromNotification = 'stopped_from_notification';
}

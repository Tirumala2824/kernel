import 'enums.dart';
import 'sensor.dart';

/// Model version reported when no trained model is bundled.
const String noModelVersion = 'none';

enum AudioInputSource { liveMic, fileUpload, sensorNode }

/// Result of one ~2 s capture plus analysis. Produced only by a [ScanEngine].
class ScanOutcome {
  const ScanOutcome({
    required this.scanId,
    required this.itemId,
    required this.capturedAt,
    required this.quality,
    required this.qualityReasons,
    required this.classification,
    required this.confidence,
    required this.experimental,
    required this.modelVersion,
    required this.latencyMs,
    required this.durationMs,
    required this.sampleRate,
    required this.deviceModel,
    required this.osVersion,
    this.audioRetained = false,
    this.inputSource = AudioInputSource.liveMic,
    this.sensorType,
    this.sensorNodeId,
    this.sourceFileName,
    this.asqiScore,
  });

  final String scanId;
  final String itemId;

  /// UTC.
  final DateTime capturedAt;
  final ScanQuality quality;
  final List<QualityReason> qualityReasons;
  final Classification classification;

  /// Null unless a real model produced [classification].
  final double? confidence;

  /// True until a model has been validated on labelled field data.
  final bool experimental;
  final String modelVersion;
  final int latencyMs;
  final int durationMs;

  /// Effective sample rate the device actually delivered.
  final int sampleRate;
  final String deviceModel;
  final String osVersion;

  /// True when the WAV for this scan was kept (opt-in or research recording).
  final bool audioRetained;

  /// Source of the audio input.
  final AudioInputSource inputSource;

  /// Sensor hardware used if uploaded or recorded via dedicated sensor.
  final SensorType? sensorType;

  /// Optional ID of linked BLE sensor node.
  final String? sensorNodeId;

  /// File name if audio was uploaded from file.
  final String? sourceFileName;

  /// Audio Signal Quality Index (0..1).
  final double? asqiScore;

  /// Contract invariants from docs/contracts.md. Empty means valid.
  /// Repositories must refuse to persist an outcome with violations.
  List<String> invariantViolations() {
    final violations = <String>[];
    if (quality == ScanQuality.retry &&
        classification != Classification.notEvaluated) {
      violations.add('RETRY outcome must not carry a pest class');
    }
    if (quality == ScanQuality.retry && qualityReasons.isEmpty) {
      violations.add('RETRY outcome must state at least one reason');
    }
    if (modelVersion == noModelVersion &&
        classification != Classification.notEvaluated) {
      violations.add(
        'No model bundled, so classification must be notEvaluated',
      );
    }
    if (modelVersion == noModelVersion && !experimental) {
      violations.add('No-model outcome must be marked experimental');
    }
    if (classification == Classification.notEvaluated && confidence != null) {
      violations.add('notEvaluated outcome must not carry a confidence');
    }
    return violations;
  }
}

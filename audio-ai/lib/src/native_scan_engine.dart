import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:uuid/uuid.dart';

import 'outcome_mapper.dart';
import 'scan_api.g.dart';
import 'scan_api.g.dart' as bridge show captureLevels;

/// Production [ScanEngine] backed by the Kotlin pipeline in this plugin:
/// AudioRecord capture, quality gate, log-mel and, only when a real model is
/// bundled, LiteRT inference on the CPU. Everything runs on the device.
///
/// With no model bundled, every outcome is [Classification.notEvaluated] with
/// `modelVersion == "none"`, `experimental == true` and `confidence == null`.
///
/// The app must request RECORD_AUDIO before calling [captureAndAnalyze];
/// without it the outcome is RETRY with [QualityReason.permissionDenied].
class NativeScanEngine implements ScanEngine {
  NativeScanEngine() : _api = ScanHostApi();

  final ScanHostApi _api;
  static const Uuid _uuid = Uuid();

  /// One shared stream for the whole process. The native side has a single
  /// event sink, and every new EventChannel listener would replace the
  /// previous one, so all engines and listeners share this broadcast stream.
  /// Error events (none are sent today) are dropped: a level meter must not
  /// break the screen that shows it, and capture failures are reported by
  /// [captureAndAnalyze].
  static final Stream<CaptureLevel> _levels = bridge
      .captureLevels()
      .map(mapCaptureLevel)
      .handleError((Object _) {});

  /// Device identity from the last successful bridge call, used only to fill
  /// a failure outcome when the bridge itself fails.
  String _deviceModel = unknownDeviceField;
  String _osVersion = unknownDeviceField;

  /// [haptics] false means no vibration cue at all (start, finish or retry).
  /// [ScanOutcome.audioRetained] is true only if the WAV was actually written
  /// to app-private `files/recordings/<scanId>.wav`.
  @override
  Future<ScanOutcome> captureAndAnalyze(
    String itemId, {
    bool retainAudio = false,
    bool haptics = true,
  }) async {
    final scanId = _uuid.v4();
    final calledAt = DateTime.now().toUtc();
    try {
      final result = await _api.captureAndAnalyze(scanId, retainAudio, haptics);
      _deviceModel = result.deviceModel;
      _osVersion = result.osVersion;
      return mapScanResult(result, scanId: scanId, itemId: itemId);
    } catch (_) {
      // Contract: never throw for audio/model problems. A bridge or decode
      // failure means nothing was evaluated.
      return failureOutcome(
        scanId: scanId,
        itemId: itemId,
        capturedAt: calledAt,
        deviceModel: _deviceModel,
        osVersion: _osVersion,
      );
    }
  }

  /// Analyzes an existing audio file (.wav) with acoustic sensor provenance.
  @override
  Future<ScanOutcome> analyzeAudioFile(
    String itemId,
    String filePath, {
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
    bool retainAudio = false,
  }) async {
    final scanId = _uuid.v4();
    final calledAt = DateTime.now().toUtc();
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    try {
      final result = await _api.analyzeFile(scanId, filePath, retainAudio);
      _deviceModel = result.deviceModel;
      _osVersion = result.osVersion;
      return mapScanResult(
        result,
        scanId: scanId,
        itemId: itemId,
        inputSource: AudioInputSource.fileUpload,
        sensorType: sensorType,
        sensorNodeId: sensorNodeId,
        sourceFileName: fileName,
      );
    } catch (_) {
      return failureOutcome(
        scanId: scanId,
        itemId: itemId,
        capturedAt: calledAt,
        deviceModel: _deviceModel,
        osVersion: _osVersion,
        inputSource: AudioInputSource.fileUpload,
        sensorType: sensorType,
        sensorNodeId: sensorNodeId,
        sourceFileName: fileName,
      );
    }
  }

  /// Broadcast stream of live input levels, about every 50 ms of kept audio
  /// while a [captureAndAnalyze] call is recording. Levels only (RMS and peak
  /// in dBFS), never samples. Nothing is emitted while idle, during the start
  /// cue or the 100 ms warm-up, or after the recording ends. The last reading
  /// of a full capture has `elapsedMs == targetMs`.
  ///
  /// Listen before calling [captureAndAnalyze] to see the first reading.
  @override
  Stream<CaptureLevel> captureLevels() => _levels;

  @override
  Future<EngineInfo> info() async {
    try {
      final info = await _api.info();
      _deviceModel = info.deviceModel;
      _osVersion = info.osVersion;
      return mapEngineInfo(info);
    } catch (_) {
      return unavailableEngineInfo();
    }
  }

  /// Deletes every recording kept under the retain-audio opt-in (everything
  /// in app-private `files/recordings/`). Completes normally when there is
  /// nothing to delete or the folder does not exist. Unlike
  /// [captureAndAnalyze], it throws if a file cannot be deleted, so a failed
  /// privacy delete is never silently reported as done.
  @override
  Future<void> deleteRetainedAudio() async {
    await _api.deleteRetainedAudio();
  }

  /// Absolute path of `files/recordings/<scanId>.wav` in app-private storage,
  /// or null when that scan's audio was not retained, has been deleted, or
  /// [scanId] is not a UUID. Like [deleteRetainedAudio] it throws if the
  /// native side cannot be reached, so an export never silently drops
  /// recordings that do exist.
  @override
  Future<String?> retainedAudioPath(String scanId) async {
    final path = await _api.retainedAudioPath(scanId);
    return path == null || path.isEmpty ? null : path;
  }
}

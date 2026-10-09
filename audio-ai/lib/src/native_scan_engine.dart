import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:uuid/uuid.dart';

import 'outcome_mapper.dart';
import 'scan_api.g.dart';

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

  /// Device identity from the last successful bridge call, used only to fill
  /// a failure outcome when the bridge itself fails.
  String _deviceModel = unknownDeviceField;
  String _osVersion = unknownDeviceField;

  @override
  Future<ScanOutcome> captureAndAnalyze(
    String itemId, {
    bool retainAudio = false,
  }) async {
    final scanId = _uuid.v4();
    final calledAt = DateTime.now().toUtc();
    try {
      final result = await _api.captureAndAnalyze(scanId, retainAudio);
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
}

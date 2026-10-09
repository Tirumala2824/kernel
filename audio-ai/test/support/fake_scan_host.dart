// Test-only fake of the Kotlin side of the pigeon ScanHostApi. It answers on
// the real pigeon channel names using the generated codec, so tests exercise
// the full Dart encode/decode path of NativeScanEngine.
//
// Lives under test/ only; never reachable from the production dependency graph.
import 'package:audio_ai/src/scan_api.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _prefix = 'dev.flutter.pigeon.audio_ai.ScanHostApi';

class FakeScanHost {
  /// Answer for captureAndAnalyze. Throw a [PlatformException] to simulate a
  /// native error reply.
  NativeScanResult Function(String scanId, bool retainAudio)? onCapture;
  NativeEngineInfo Function()? onInfo;
  int Function()? onDelete;

  final List<(String scanId, bool retainAudio)> captureCalls = [];

  void install() {
    _handle('captureAndAnalyze', (args) {
      final scanId = args![0]! as String;
      final retain = args[1]! as bool;
      captureCalls.add((scanId, retain));
      return onCapture!(scanId, retain);
    });
    _handle('info', (_) => onInfo!());
    _handle('deleteRetainedAudio', (_) => onDelete!());
  }

  /// Removes all handlers: calls then fail like a missing plugin.
  static void uninstall() {
    for (final method in ['captureAndAnalyze', 'info', 'deleteRetainedAudio']) {
      _messenger.setMockDecodedMessageHandler<Object?>(_channel(method), null);
    }
  }

  void _handle(String method, Object? Function(List<Object?>? args) answer) {
    _messenger.setMockDecodedMessageHandler<Object?>(_channel(method), (
      message,
    ) async {
      try {
        return <Object?>[answer(message as List<Object?>?)];
      } on PlatformException catch (e) {
        return <Object?>[e.code, e.message, e.details];
      }
    });
  }

  static TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  static BasicMessageChannel<Object?> _channel(String method) =>
      BasicMessageChannel<Object?>(
        '$_prefix.$method',
        ScanHostApi.pigeonChannelCodec,
      );
}

/// Native result as the Kotlin side builds it with no model bundled.
NativeScanResult nativeResult({
  bool qualityPass = true,
  List<NativeQualityReason> qualityReasons = const [],
  NativeClassification classification = NativeClassification.notEvaluated,
  double? confidence,
  bool experimental = true,
  String modelVersion = 'none',
  int capturedAtEpochMs = 1760000000000,
  int latencyMs = 12,
  int durationMs = 2000,
  int sampleRate = 16000,
  String deviceModel = 'TEST-DEVICE',
  String osVersion = 'Android 16 (SDK 36)',
}) {
  return NativeScanResult(
    qualityPass: qualityPass,
    qualityReasons: qualityReasons,
    classification: classification,
    confidence: confidence,
    experimental: experimental,
    modelVersion: modelVersion,
    capturedAtEpochMs: capturedAtEpochMs,
    latencyMs: latencyMs,
    durationMs: durationMs,
    sampleRate: sampleRate,
    deviceModel: deviceModel,
    osVersion: osVersion,
  );
}

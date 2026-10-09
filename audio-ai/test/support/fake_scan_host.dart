// Test-only fake of the Kotlin side of the pigeon ScanHostApi and the
// CaptureLevelEvents event channel. It answers on the real pigeon channel
// names using the generated codecs, so tests exercise the full Dart
// encode/decode path of NativeScanEngine.
//
// Lives under test/ only; never reachable from the production dependency graph.
import 'package:audio_ai/src/scan_api.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _prefix = 'dev.flutter.pigeon.audio_ai.ScanHostApi';
const _methods = [
  'captureAndAnalyze',
  'info',
  'deleteRetainedAudio',
  'retainedAudioPath',
];

/// Same name and codec as the generated `captureLevels()` channel.
const levelChannel = EventChannel(
  'dev.flutter.pigeon.audio_ai.CaptureLevelEvents.captureLevels',
  pigeonMethodCodec,
);

class FakeScanHost {
  /// Answer for captureAndAnalyze. Throw a [PlatformException] to simulate a
  /// native error reply.
  NativeScanResult Function(String scanId, bool retainAudio, bool haptics)?
  onCapture;
  NativeEngineInfo Function()? onInfo;
  int Function()? onDelete;
  String? Function(String scanId)? onRetainedPath;

  final List<(String scanId, bool retainAudio, bool haptics)> captureCalls = [];

  /// Event-channel side: set while Dart is listening.
  MockStreamHandlerEventSink? _levelSink;
  int levelListens = 0;
  int levelCancels = 0;

  bool get levelsListened => _levelSink != null;

  void install() {
    _handle('captureAndAnalyze', (args) {
      final scanId = args![0]! as String;
      final retain = args[1]! as bool;
      final haptics = args[2]! as bool;
      captureCalls.add((scanId, retain, haptics));
      return onCapture!(scanId, retain, haptics);
    });
    _handle('info', (_) => onInfo!());
    _handle('deleteRetainedAudio', (_) => onDelete!());
    _handle(
      'retainedAudioPath',
      (args) => onRetainedPath!(args![0]! as String),
    );
    _messenger.setMockStreamHandler(
      levelChannel,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          levelListens++;
          _levelSink = sink;
        },
        onCancel: (_) {
          levelCancels++;
          _levelSink = null;
        },
      ),
    );
  }

  /// Sends one level reading as the Kotlin capture loop would.
  void emitLevel(NativeCaptureLevel level) => _levelSink!.success(level);

  /// Sends an error event on the level channel.
  void emitLevelError(String code) => _levelSink!.error(code: code);

  /// Removes all handlers: calls then fail like a missing plugin.
  static void uninstall() {
    for (final method in _methods) {
      _messenger.setMockDecodedMessageHandler<Object?>(_channel(method), null);
    }
    _messenger.setMockStreamHandler(levelChannel, null);
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
  bool audioRetained = false,
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
    audioRetained: audioRetained,
  );
}

/// Native engine info as the Kotlin side builds it.
NativeEngineInfo nativeInfo({
  bool modelPresent = false,
  String modelVersion = 'none',
  bool experimental = true,
  int? effectiveSampleRate,
  NativeDelegate delegate = NativeDelegate.none,
  String deviceModel = 'I2501',
  String osVersion = 'Android 16 (SDK 36)',
  String? modelNote,
  String? audioSource = 'VOICE_RECOGNITION',
  int? deviceInputSampleRate,
}) {
  return NativeEngineInfo(
    modelPresent: modelPresent,
    modelVersion: modelVersion,
    experimental: experimental,
    targetSampleRate: 16000,
    effectiveSampleRate: effectiveSampleRate,
    delegate: delegate,
    deviceModel: deviceModel,
    osVersion: osVersion,
    modelNote: modelNote,
    audioSource: audioSource,
    deviceInputSampleRate: deviceInputSampleRate,
  );
}

NativeCaptureLevel nativeLevel({
  int elapsedMs = 50,
  int targetMs = 2000,
  double rmsDbfs = -48.5,
  double peakDbfs = -31.25,
}) {
  return NativeCaptureLevel(
    elapsedMs: elapsedMs,
    targetMs: targetMs,
    rmsDbfs: rmsDbfs,
    peakDbfs: peakDbfs,
  );
}

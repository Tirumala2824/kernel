// Test-only SenseHost double: answers like the Kotlin plugin would, from
// values set by each test. Lives under test/ only.
import 'dart:async';
import 'dart:typed_data';

import 'package:sense_ai/sense_ai.dart';
import 'package:sense_ai/src/sense_api.g.dart';

class TestSenseHost implements SenseHost {
  final batches = StreamController<NativeCameraBatch>.broadcast();
  final sounds = StreamController<NativeSoundEvent>.broadcast();
  final listen = StreamController<NativeListenStatus>.broadcast();

  NativeStill? Function(List<NativeBox> boxes)? onCapture;
  bool throwOnCapture = false;
  NativeListenStatus Function(NativeListenMode mode, String? path)? onStart;
  NativeDistance Function(NativeBox? target)? onMeasure;
  NativeDistanceCapability? capability;
  bool throwOnDistance = false;
  final Map<String, Uint8List> clips = {};
  final Map<String, List<NativeScoredLabel>> labels = {};

  final List<List<NativeBox>> captureCalls = [];
  final List<(NativeListenMode, String?)> startCalls = [];
  final List<double> torchCalls = [];
  final List<NativeBox?> measureCalls = [];
  int stopCalls = 0;
  int discardCalls = 0;

  int get batchListeners => batches.hasListener ? 1 : 0;

  @override
  Stream<NativeCameraBatch> cameraBatches() => batches.stream;

  @override
  Stream<NativeSoundEvent> soundEvents() => sounds.stream;

  @override
  Stream<NativeListenStatus> listenStatus() => listen.stream;

  @override
  Future<NativeCameraCapabilities> cameraCapabilities() async =>
      NativeCameraCapabilities(
        cameraPermission: true,
        hasBackCamera: true,
        cameraBound: true,
        torchAvailable: true,
        maxTorchStrength: 5,
        lowLightBoostSupported: false,
        gyroAvailable: true,
      );

  @override
  Future<NativeStill?> captureStill(List<NativeBox> boxes) async {
    captureCalls.add(boxes);
    if (throwOnCapture) throw StateError('bridge down');
    return onCapture?.call(boxes);
  }

  @override
  Future<void> setTorch(double level) async => torchCalls.add(level);

  @override
  Future<void> pulseTorch(int durationMs) async {}

  @override
  Future<void> setLowLightBoost(bool enabled) async {}

  @override
  Future<NativeListenStatus> startListening(
    NativeListenMode mode,
    String? soundModelPath,
  ) async {
    startCalls.add((mode, soundModelPath));
    return onStart?.call(mode, soundModelPath) ??
        status(NativeListenState.listening, mode);
  }

  @override
  Future<void> stopListening() async => stopCalls++;

  @override
  Future<Uint8List?> clipFor(String candidateId) async => clips[candidateId];

  @override
  Future<List<NativeScoredLabel>> soundLabelsFor(String candidateId) async {
    final l = labels[candidateId];
    if (l == null) throw StateError('unknown id');
    return l;
  }

  @override
  Future<NativeDistanceCapability> distanceCapability() async {
    if (throwOnDistance) throw StateError('bridge down');
    return capability ??
        NativeDistanceCapability(
          arcoreDepth: false,
          focusDistance: true,
          reason: 'arcore_unsupported',
        );
  }

  @override
  Future<NativeDistance> measure(NativeBox? target) async {
    measureCalls.add(target);
    if (throwOnDistance) throw StateError('bridge down');
    return onMeasure!(target);
  }

  @override
  Future<void> discardMedia() async => discardCalls++;

  @override
  Future<String?> keepMedia(String mediaId) async =>
      '/data/user/0/app/files/sense_media/$mediaId.jpg';

  static NativeListenStatus status(
    NativeListenState state,
    NativeListenMode mode, {
    String? reason,
  }) => NativeListenStatus(
    state: state,
    mode: mode,
    reason: reason,
    micVerified: true,
    soundModelLoaded: false,
    soundModelName: null,
  );
}

NativeCandidate nativeCandidate(
  String id, {
  NativeSignalKind kind = NativeSignalKind.motion,
  double score = 0.6,
  int at = 1700000000000,
  double left = 0.1,
  double top = 0.2,
  double width = 0.05,
  double height = 0.04,
}) => NativeCandidate(
  id: id,
  kind: kind,
  score: score,
  detectedAtEpochMs: at,
  left: left,
  top: top,
  width: width,
  height: height,
);

NativeCameraBatch nativeBatch(
  List<NativeCandidate> candidates, {
  NativeThermalLevel thermal = NativeThermalLevel.normal,
  bool active = true,
}) => NativeCameraBatch(
  candidates: candidates,
  emittedAtEpochMs: 1700000000500,
  thermalLevel: thermal,
  thermalHeadroom: 0.4,
  cameraActive: active,
  gyroGated: false,
  torchOn: false,
  lowLightBoostActive: false,
  analysisFps: 15,
);

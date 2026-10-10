import 'dart:typed_data';

import 'sense_api.g.dart';
import 'sense_api.g.dart'
    as bridge
    show cameraBatches, listenStatus, soundEvents;

/// The native side of [SenseEngine], as seen from Dart. The production
/// implementation is [PigeonSenseHost]; tests pass their own.
abstract interface class SenseHost {
  Stream<NativeCameraBatch> cameraBatches();
  Stream<NativeSoundEvent> soundEvents();
  Stream<NativeListenStatus> listenStatus();
  Future<NativeCameraCapabilities> cameraCapabilities();
  Future<NativeStill?> captureStill(List<NativeBox> boxes);
  Future<void> setTorch(double level);
  Future<void> pulseTorch(int durationMs);
  Future<void> setLowLightBoost(bool enabled);
  Future<NativeListenStatus> startListening(
    NativeListenMode mode,
    String? soundModelPath,
  );
  Future<void> stopListening();
  Future<Uint8List?> clipFor(String candidateId);
  Future<List<NativeScoredLabel>> soundLabelsFor(String candidateId);
  Future<NativeDistanceCapability> distanceCapability();
  Future<NativeDistance> measure(NativeBox? target);
  Future<void> discardMedia();
  Future<String?> keepMedia(String mediaId);
}

/// [SenseHost] over the pigeon bridge to the Kotlin plugin.
class PigeonSenseHost implements SenseHost {
  PigeonSenseHost() : _api = SenseHostApi();

  final SenseHostApi _api;

  // One stream per event channel for the whole process: the native side has
  // a single sink per channel, and a second listener on a new stream would
  // replace (and on cancel, clear) it.
  static final Stream<NativeCameraBatch> _batches = bridge.cameraBatches();
  static final Stream<NativeSoundEvent> _sounds = bridge.soundEvents();
  static final Stream<NativeListenStatus> _listen = bridge.listenStatus();

  @override
  Stream<NativeCameraBatch> cameraBatches() => _batches;

  @override
  Stream<NativeSoundEvent> soundEvents() => _sounds;

  @override
  Stream<NativeListenStatus> listenStatus() => _listen;

  @override
  Future<NativeCameraCapabilities> cameraCapabilities() =>
      _api.cameraCapabilities();

  @override
  Future<NativeStill?> captureStill(List<NativeBox> boxes) =>
      _api.captureStill(boxes);

  @override
  Future<void> setTorch(double level) => _api.setTorch(level);

  @override
  Future<void> pulseTorch(int durationMs) => _api.pulseTorch(durationMs);

  @override
  Future<void> setLowLightBoost(bool enabled) => _api.setLowLightBoost(enabled);

  @override
  Future<NativeListenStatus> startListening(
    NativeListenMode mode,
    String? soundModelPath,
  ) => _api.startListening(mode, soundModelPath);

  @override
  Future<void> stopListening() => _api.stopListening();

  @override
  Future<Uint8List?> clipFor(String candidateId) => _api.clipFor(candidateId);

  @override
  Future<List<NativeScoredLabel>> soundLabelsFor(String candidateId) =>
      _api.soundLabelsFor(candidateId);

  @override
  Future<NativeDistanceCapability> distanceCapability() =>
      _api.distanceCapability();

  @override
  Future<NativeDistance> measure(NativeBox? target) => _api.measure(target);

  @override
  Future<void> discardMedia() => _api.discardMedia();

  @override
  Future<String?> keepMedia(String mediaId) => _api.keepMedia(mediaId);
}

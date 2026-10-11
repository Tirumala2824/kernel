import 'dart:async';
import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'mapping.dart';
import 'sense_api.g.dart';
import 'sense_host.dart';
import 'sense_status.dart';
import 'sign_ranker.dart';

/// Production [PestSenseEngine] on the Kotlin plugin in this package.
///
/// - **Camera**: mount a `SenseCameraPreview` to bind the camera. Stage 0
///   (motion, dark specks, torch-pulse eyeshine) runs natively on the Y
///   plane; [cameraCandidates] gets at most 5 lists per second.
/// - **Stage 1** runs only with an [Embedder]: [captureStill] tiles are
///   ranked against pest-sign prompts by [SignRanker] in the background
///   ([rankStill] returns the same result). Skipped at thermal level
///   [ThermalLevel.noStage1] or hotter.
/// - **Listen**: own AudioRecord on the built-in mic, spectral-flux events,
///   and a YAMNet-class pre-filter when [soundModelPath] gives a model.
/// - **Distance**: ARCore depth or focus distance, only when their gates
///   pass; otherwise unavailable with a reason (see [DistanceReasons]).
///
/// Images and audio stay in memory until [discardMedia]; [keepMedia]
/// writes one item to app-private storage for a saved sighting. Nothing is
/// sent over the network or logged. The app requests CAMERA and
/// RECORD_AUDIO before use.
class SenseEngine implements PestSenseEngine {
  /// [embedder] enables Stage 1 (or pass a configured [signRanker]).
  /// [soundModelPath] resolves the sound classifier file (model-hub); null
  /// or a null path means sound events come without labels. [host] is for
  /// tests; it defaults to the native plugin.
  SenseEngine({
    Embedder? embedder,
    this._soundModelPath,
    SignRanker? signRanker,
    SenseHost? host,
    DateTime Function()? clock,
    this.stage1Hold = const Duration(seconds: 15),
  }) : _host = host ?? PigeonSenseHost(),
       _ranker = signRanker ?? (embedder == null ? null : SignRanker(embedder)),
       _clock = clock ?? DateTime.now;

  final SenseHost _host;
  final Future<String?> Function()? _soundModelPath;
  final SignRanker? _ranker;
  final DateTime Function() _clock;

  /// How long Stage-1 candidates stay in [cameraCandidates] after ranking.
  final Duration stage1Hold;

  late final StreamController<List<SignalCandidate>> _candidates =
      StreamController.broadcast(
        onListen: _syncBatches,
        onCancel: _syncBatches,
      );
  late final StreamController<SenseCameraStatus> _status =
      StreamController.broadcast(
        onListen: _syncBatches,
        onCancel: _syncBatches,
      );
  late final StreamController<ListenStatus> _listenStatus =
      StreamController.broadcast();
  StreamSubscription<NativeCameraBatch>? _batchSub;
  StreamSubscription<NativeListenStatus>? _listenStatusSub;

  List<SignalCandidate> _stage0 = const [];
  List<SignalCandidate> _stage1 = const [];
  DateTime? _stage1At;
  SenseCameraStatus? _lastStatus;
  final Map<String, Future<List<SignalCandidate>>> _rankings = {};
  int _mediaGeneration = 0;

  StreamController<SignalCandidate>? _activeListen;

  /// Stage 1 is configured (an embedder or ranker was given).
  bool get hasStage1 => _ranker != null;

  /// Last camera status, or null before the first batch.
  SenseCameraStatus? get lastCameraStatus => _lastStatus;

  bool get _stage1Allowed => _lastStatus?.stage1Allowed ?? true;

  // ---- Camera -----------------------------------------------------------------

  /// Live candidates from active camera batches. Inactive batches, bridge
  /// errors and stream completion invalidate candidates with a stream error,
  /// never an evaluated empty list. Later active batches recover the stream;
  /// after completion, a new listener can resubscribe to the native host.
  @override
  Stream<List<SignalCandidate>> cameraCandidates() => _candidates.stream;

  /// Thermal level, torch, gyro gating and analysis rate with each batch.
  /// Bridge errors and stream completion also invalidate this stream.
  Stream<SenseCameraStatus> cameraStatus() => _status.stream;

  Future<SenseCameraCapabilities?> cameraCapabilities() async {
    try {
      return mapCapabilities(await _host.cameraCapabilities());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CapturedStill?> captureStill({
    List<SignalCandidate> candidates = const [],
  }) async {
    final boxes = [
      for (final c in candidates)
        if (c.source == SignalSource.camera) ?boxFor(c),
    ];
    final generation = _mediaGeneration;
    NativeStill? native;
    try {
      native = await _host.captureStill(boxes);
    } catch (_) {
      return null;
    }
    if (native == null) return null;
    final still = mapStill(native);
    if (_ranker != null && _stage1Allowed) {
      _rankings[still.stillId] = _rank(still, generation);
    }
    return still;
  }

  /// Stage-1 candidates for [still] (one per tile that matches a sign).
  /// Empty without an embedder, at thermal level noStage1 or hotter, or
  /// after [discardMedia].
  Future<List<SignalCandidate>> rankStill(CapturedStill still) {
    if (_ranker == null || !_stage1Allowed) return Future.value(const []);
    return _rankings[still.stillId] ??= _rank(still, _mediaGeneration);
  }

  @override
  Future<void> setTorch(double level) async {
    try {
      await _host.setTorch(
        level.isNaN ? 0.0 : level.clamp(0.0, 1.0).toDouble(),
      );
    } catch (_) {
      // No camera bound: nothing to light.
    }
  }

  /// Short torch pulse; eyeshine candidates appear during and after it.
  Future<void> pulseTorch({
    Duration duration = const Duration(milliseconds: 600),
  }) async {
    try {
      await _host.pulseTorch(duration.inMilliseconds);
    } catch (_) {
      // No camera bound.
    }
  }

  /// Low Light Boost on supported devices (Android 15+).
  Future<void> setLowLightBoost(bool enabled) async {
    try {
      await _host.setLowLightBoost(enabled);
    } catch (_) {
      // Unsupported or no camera bound.
    }
  }

  // ---- Listen -----------------------------------------------------------------

  /// Starts listening and emits sound-event candidates until
  /// [stopListening] or until the listener cancels. If listening cannot
  /// start or stops on its own, the stream gets a [SenseException] with a
  /// [ListenReasons] key and closes. [ListenMode.mosquitoCloseUp] only
  /// changes the app's instructions. [ListenMode.night] runs as a
  /// microphone foreground service and must be started while the app is
  /// visible.
  @override
  Stream<SignalCandidate> listen(ListenMode mode) {
    final previous = _activeListen;
    _activeListen = null;
    if (previous != null) unawaited(previous.close());
    StreamSubscription<NativeSoundEvent>? events;
    StreamSubscription<NativeListenStatus>? status;
    late final StreamController<SignalCandidate> controller;
    // Status events before this session started belong to an earlier one.
    var sessionStarted = false;

    Future<void> end([String? reason]) async {
      if (identical(_activeListen, controller)) _activeListen = null;
      if (reason != null && !controller.isClosed) {
        controller.addError(SenseException(reason));
      }
      await events?.cancel();
      await status?.cancel();
      if (!controller.isClosed) await controller.close();
    }

    controller = StreamController<SignalCandidate>(
      onListen: () async {
        events = _host.soundEvents().listen((e) {
          if (!controller.isClosed) controller.add(mapSoundEvent(e));
        }, onError: (Object _) {});
        status = _host.listenStatus().listen((s) {
          if (!sessionStarted) return;
          final mapped = mapListenStatus(s);
          if (mapped.state == ListenState.failed) {
            unawaited(end(mapped.reason ?? ListenReasons.captureError));
          } else if (mapped.state == ListenState.stopped) {
            // A user stop (in the app or the notification) is not an error;
            // the reason is on listenStatus().
            unawaited(end());
          }
        }, onError: (Object _) {});
        String? path;
        try {
          path = await _soundModelPath?.call();
        } catch (_) {
          path = null;
        }
        if (controller.isClosed) return;
        NativeListenStatus started;
        try {
          started = await _host.startListening(mapListenMode(mode), path);
        } catch (_) {
          await end(ListenReasons.captureError);
          return;
        }
        final mapped = mapListenStatus(started);
        _emitListenStatus(mapped);
        sessionStarted = mapped.state == ListenState.listening;
        if (!sessionStarted) {
          await end(mapped.reason ?? ListenReasons.captureError);
        } else if (controller.isClosed ||
            !identical(_activeListen, controller)) {
          // Cancelled or replaced while starting.
          await _stopHost();
        }
      },
      onCancel: () async {
        final wasActive = identical(_activeListen, controller);
        await end();
        if (wasActive) await _stopHost();
      },
    );
    _activeListen = controller;
    return controller.stream;
  }

  /// Listen-session status (also for night mode started elsewhere).
  Stream<ListenStatus> listenStatus() {
    _listenStatusSub ??= _host.listenStatus().listen(
      (s) => _emitListenStatus(mapListenStatus(s)),
      onError: (Object _) {},
    );
    return _listenStatus.stream;
  }

  @override
  Future<void> stopListening() async {
    final active = _activeListen;
    _activeListen = null;
    await _stopHost();
    if (active != null && !active.isClosed) await active.close();
  }

  @override
  Future<Uint8List?> clipFor(String candidateId) async {
    try {
      return await _host.clipFor(candidateId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ScoredLabel>> soundLabelsFor(String candidateId) async {
    try {
      final labels = await _host.soundLabelsFor(candidateId);
      return [for (final l in labels) mapLabel(l)];
    } catch (_) {
      return const [];
    }
  }

  // ---- Distance ---------------------------------------------------------------

  @override
  Future<DistanceCapability> distanceCapability() async {
    try {
      return mapCapability(await _host.distanceCapability());
    } catch (_) {
      return const DistanceCapability(
        arcoreDepth: false,
        focusDistance: false,
        reason: DistanceReasons.arcoreUnsupported,
      );
    }
  }

  /// Opens the native Measure screen. The camera preview pauses while it is
  /// open. [target] is the region to measure; its centre is used.
  @override
  Future<DistanceEstimate> measure({NormalizedBox? target}) async {
    final box = target == null
        ? null
        : NativeBox(
            candidateId: 'target',
            left: target.left,
            top: target.top,
            width: target.width,
            height: target.height,
          );
    try {
      return mapDistance(await _host.measure(box));
    } catch (_) {
      return unavailableDistance(DistanceReasons.measureFailed);
    }
  }

  // ---- Media ------------------------------------------------------------------

  /// Writes the held full-resolution still (by [CapturedStill.stillId]) or
  /// sound clip (by candidate id) to app-private storage and returns the
  /// absolute path. Call only for a sighting saved with "keep media" on.
  Future<String?> keepMedia(String mediaId) async {
    try {
      return await _host.keepMedia(mediaId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> discardMedia() async {
    _mediaGeneration++;
    _rankings.clear();
    _stage1 = const [];
    _stage1At = null;
    _emitCandidates();
    try {
      await _host.discardMedia();
    } catch (_) {
      // Nothing held natively without a bridge.
    }
  }

  /// Stops listening and the camera event subscription.
  Future<void> dispose() async {
    await stopListening();
    await _batchSub?.cancel();
    _batchSub = null;
    await _listenStatusSub?.cancel();
    _listenStatusSub = null;
    await _candidates.close();
    await _status.close();
    await _listenStatus.close();
  }

  // ---- Internals --------------------------------------------------------------

  void _syncBatches() {
    final wanted = _candidates.hasListener || _status.hasListener;
    if (wanted && _batchSub == null) {
      _batchSub = _host.cameraBatches().listen(
        _onBatch,
        onError: _onCameraError,
        onDone: () {
          _batchSub = null;
          _onCameraError(StateError('Camera stream ended'));
        },
      );
    } else if (!wanted && _batchSub != null) {
      unawaited(_batchSub!.cancel());
      _batchSub = null;
    }
  }

  void _onBatch(NativeCameraBatch b) {
    final status = mapCameraStatus(b);
    _lastStatus = status;
    if (!_status.isClosed) _status.add(status);
    if (!status.cameraActive) {
      _invalidateCameraCandidates(StateError('Camera is inactive'));
      return;
    }
    _stage0 = [for (final c in b.candidates) mapCandidate(c)];
    _emitCandidates();
  }

  void _onCameraError(Object error, [StackTrace? stackTrace]) {
    _lastStatus = null;
    _invalidateCameraCandidates(error, stackTrace);
    if (!_status.isClosed) _status.addError(error, stackTrace);
  }

  void _invalidateCameraCandidates(Object error, [StackTrace? stackTrace]) {
    _mediaGeneration++;
    _rankings.clear();
    _stage0 = const [];
    _stage1 = const [];
    _stage1At = null;
    if (!_candidates.isClosed) _candidates.addError(error, stackTrace);
  }

  void _emitCandidates() {
    // Only a real active batch can establish an evaluated camera frame.
    if (_candidates.isClosed || _lastStatus?.cameraActive != true) return;
    final at = _stage1At;
    if (at != null && _clock().difference(at) > stage1Hold) {
      _stage1 = const [];
      _stage1At = null;
    }
    _candidates.add(List.unmodifiable([..._stage0, ..._stage1]));
  }

  void _emitListenStatus(ListenStatus s) {
    if (!_listenStatus.isClosed) _listenStatus.add(s);
  }

  Future<void> _stopHost() async {
    try {
      await _host.stopListening();
    } catch (_) {
      // Bridge gone: the native session stops with the engine.
    }
  }

  Future<List<SignalCandidate>> _rank(
    CapturedStill still,
    int generation,
  ) async {
    final ranker = _ranker;
    if (ranker == null) return const [];
    final liveFrame = _lastStatus?.cameraActive == true;
    try {
      final results = await ranker.rankTiles(still.tiles);
      if (generation != _mediaGeneration) return const [];
      // Still ranking may be useful off-preview, but cannot create a live frame.
      if (liveFrame) {
        _stage1 = results;
        _stage1At = _clock();
        _emitCandidates();
      }
      return results;
    } catch (_) {
      return const [];
    }
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sense_ai/sense_ai.dart';
import 'package:sense_ai/src/sense_api.g.dart';

import 'support/test_embedder.dart';
import 'support/test_sense_host.dart';

NativeStill _still(List<NativeBox> boxes, {String id = 'still-1'}) =>
    NativeStill(
      stillId: id,
      contextJpeg: Uint8List.fromList([1, 2, 3]),
      tiles: [
        for (final b
            in boxes.isEmpty
                ? [
                    NativeBox(
                      candidateId: 'grid-r0c0',
                      left: 0,
                      top: 0,
                      width: 0.5,
                      height: 0.375,
                    ),
                  ]
                : boxes)
          NativeTile(
            candidateId: b.candidateId,
            left: b.left,
            top: b.top,
            width: 0.2,
            height: 0.15,
            jpeg: bytesOf(b.candidateId == 'motion-1' ? 'a gecko' : 'nothing'),
          ),
      ],
      fullWidth: 3000,
      fullHeight: 4000,
      capturedAtEpochMs: 1700000001000,
    );

SignalCandidate _camera(String id, {NormalizedBox? box}) => SignalCandidate(
  id: id,
  source: SignalSource.camera,
  kind: SignalKind.motion,
  score: 0.5,
  detectedAt: DateTime.utc(2026),
  box: box ?? const NormalizedBox(left: 0.4, top: 0.4, width: 0.1, height: 0.1),
);

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  late TestSenseHost host;
  var now = DateTime.utc(2026, 10, 10, 12);

  setUp(() {
    host = TestSenseHost();
    now = DateTime.utc(2026, 10, 10, 12);
  });

  SenseEngine engine({
    Embedder? embedder,
    Future<String?> Function()? soundModelPath,
  }) => SenseEngine(
    host: host,
    embedder: embedder,
    soundModelPath: soundModelPath,
    clock: () => now,
  );

  group('camera', () {
    test('maps Stage-0 batches to camera candidates and status', () async {
      final e = engine();
      final lists = <List<SignalCandidate>>[];
      final statuses = <SenseCameraStatus>[];
      final s1 = e.cameraCandidates().listen(lists.add);
      final s2 = e.cameraStatus().listen(statuses.add);
      host.batches.add(
        nativeBatch([
          nativeCandidate('motion-3', score: 1.7),
          nativeCandidate(
            'specks-1',
            kind: NativeSignalKind.darkSpecks,
            left: 0.9,
            width: 0.3,
          ),
          nativeCandidate('eyeshine-2', kind: NativeSignalKind.eyeshine),
        ], thermal: NativeThermalLevel.reducedFps),
      );
      await _pump();
      final list = lists.single;
      expect(list.map((c) => c.kind), [
        SignalKind.motion,
        SignalKind.darkSpecks,
        SignalKind.eyeshine,
      ]);
      expect(list.every((c) => c.source == SignalSource.camera), isTrue);
      expect(list.first.score, 1.0, reason: 'clamped to 0..1');
      expect(
        list.first.detectedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
      expect(list.first.box!.left, 0.1);
      expect(
        list[1].box!.width,
        closeTo(0.1, 1e-9),
        reason: 'box kept inside the frame',
      );
      expect(statuses.single.thermalLevel, ThermalLevel.reducedFps);
      expect(statuses.single.stage1Allowed, isTrue);
      expect(statuses.single.analysisFps, 15);
      await s1.cancel();
      expect(host.batchListeners, 1, reason: 'status still listening');
      await s2.cancel();
      expect(host.batchListeners, 0, reason: 'native stream released');
    });

    test('captureStill sends only camera candidates with boxes', () async {
      final e = engine();
      host.onCapture = _still;
      final sound = SignalCandidate(
        id: 's1',
        source: SignalSource.microphone,
        kind: SignalKind.soundEvent,
        score: 0.4,
        detectedAt: DateTime.utc(2026),
      );
      final still = await e.captureStill(
        candidates: [_camera('motion-1'), sound],
      );
      expect(host.captureCalls.single.map((b) => b.candidateId), ['motion-1']);
      expect(host.captureCalls.single.single.left, 0.4);
      expect(still!.stillId, 'still-1');
      expect(still.contextImage, [1, 2, 3]);
      expect(still.tiles.single.candidateId, 'motion-1');
      expect(still.tiles.single.box.width, 0.2);
    });

    test('no candidates gives the grid; failures give null', () async {
      final e = engine();
      host.onCapture = _still;
      final grid = await e.captureStill();
      expect(host.captureCalls.single, isEmpty);
      expect(grid!.tiles.single.candidateId, 'grid-r0c0');
      host.onCapture = (_) => null;
      expect(await e.captureStill(), isNull);
      host.throwOnCapture = true;
      expect(await e.captureStill(), isNull);
    });

    test(
      'Stage 1 ranks tiles with the injected embedder and merges candidates',
      () async {
        final emb = TestEmbedder(['gecko']);
        final e = engine(embedder: emb);
        expect(e.hasStage1, isTrue);
        final lists = <List<SignalCandidate>>[];
        final sub = e.cameraCandidates().listen(lists.add);
        host.batches.add(nativeBatch([nativeCandidate('motion-1')]));
        await _pump();
        host.onCapture = _still;
        final still = await e.captureStill(
          candidates: [_camera('motion-1'), _camera('motion-2')],
        );
        final ranked = await e.rankStill(still!);
        expect(ranked.single.kind, SignalKind.embeddingMatch);
        expect(ranked.single.hint, 'gecko');
        expect(ranked.single.id, 'sign:motion-1');
        await _pump();
        final merged = lists.last;
        expect(merged.map((c) => c.id), ['motion-1', 'sign:motion-1']);
        // Stage 0 updates keep the Stage-1 result until it expires.
        host.batches.add(nativeBatch([]));
        await _pump();
        expect(lists.last.map((c) => c.id), ['sign:motion-1']);
        now = now.add(const Duration(seconds: 16));
        host.batches.add(nativeBatch([]));
        await _pump();
        expect(lists.last, isEmpty);
        expect(
          identical(e.rankStill(still), e.rankStill(still)),
          isTrue,
          reason: 'one ranking per still',
        );
        await sub.cancel();
      },
    );

    test('without an embedder Stage 1 is skipped', () async {
      final e = engine();
      host.onCapture = _still;
      final still = await e.captureStill(candidates: [_camera('motion-1')]);
      expect(e.hasStage1, isFalse);
      expect(await e.rankStill(still!), isEmpty);
    });

    test('thermal noStage1 stops Stage 1', () async {
      final emb = TestEmbedder(['gecko']);
      final e = engine(embedder: emb);
      final sub = e.cameraStatus().listen((_) {});
      host.batches.add(nativeBatch([], thermal: NativeThermalLevel.noStage1));
      await _pump();
      host.onCapture = _still;
      final still = await e.captureStill(candidates: [_camera('motion-1')]);
      expect(await e.rankStill(still!), isEmpty);
      expect(emb.imageCalls, 0);
      expect(e.lastCameraStatus!.stage1Allowed, isFalse);
      await sub.cancel();
    });

    test('discardMedia drops Stage-1 results and native media', () async {
      final emb = TestEmbedder(['gecko']);
      final e = engine(embedder: emb);
      final lists = <List<SignalCandidate>>[];
      final sub = e.cameraCandidates().listen(lists.add);
      host.onCapture = _still;
      final still = await e.captureStill(candidates: [_camera('motion-1')]);
      // Discard before the background ranking completes.
      await e.discardMedia();
      await _pump();
      await _pump();
      expect(host.discardCalls, 1);
      expect(
        lists.where((l) => l.isNotEmpty),
        isEmpty,
        reason: 'late ranking is dropped',
      );
      expect(
        await e.rankStill(still!),
        isNotEmpty,
        reason: 'explicit re-rank still works',
      );
      await sub.cancel();
    });

    test('torch level is clamped', () async {
      final e = engine();
      await e.setTorch(3);
      await e.setTorch(-1);
      await e.setTorch(double.nan);
      expect(host.torchCalls, [1.0, 0.0, 0.0]);
    });
  });

  group('listen', () {
    test('starts with the mode and model path and maps sound events', () async {
      final e = engine(soundModelPath: () async => '/models/yamnet.tflite');
      final got = <SignalCandidate>[];
      final done = Completer<void>();
      e.listen(ListenMode.night).listen(got.add, onDone: done.complete);
      await _pump();
      expect(host.startCalls.single, (
        NativeListenMode.night,
        '/models/yamnet.tflite',
      ));
      host.sounds.add(
        NativeSoundEvent(
          id: 'e1',
          score: 0.8,
          detectedAtEpochMs: 1700000002000,
          hint: 'Mouse',
          labelled: true,
          onsetCount: 3,
        ),
      );
      host.sounds.add(
        NativeSoundEvent(
          id: 'e2',
          score: 0.3,
          detectedAtEpochMs: 1700000003000,
          hint: 'Mouse',
          labelled: false,
          onsetCount: 1,
        ),
      );
      await _pump();
      expect(got.map((c) => c.id), ['e1', 'e2']);
      expect(
        got.every(
          (c) =>
              c.source == SignalSource.microphone &&
              c.kind == SignalKind.soundEvent,
        ),
        isTrue,
      );
      expect(got.first.hint, 'Mouse');
      expect(got.last.hint, isNull, reason: 'no label without a model run');
      expect(got.first.box, isNull);
      await e.stopListening();
      await done.future;
      expect(host.stopCalls, 1);
    });

    test('no model path function or a failing one means no model', () async {
      final e = engine();
      final sub = e.listen(ListenMode.general).listen((_) {});
      await _pump();
      expect(host.startCalls.single, (NativeListenMode.general, null));
      await sub.cancel();
      final f = engine(
        soundModelPath: () async => throw StateError('hub offline'),
      );
      final sub2 = f.listen(ListenMode.mosquitoCloseUp).listen((_) {});
      await _pump();
      await _pump();
      expect(host.startCalls.last, (NativeListenMode.mosquitoCloseUp, null));
      await sub2.cancel();
    });

    test('a failed start ends the stream with a SenseException', () async {
      host.onStart = (mode, _) => TestSenseHost.status(
        NativeListenState.failed,
        mode,
        reason: ListenReasons.permissionDenied,
      );
      final e = engine();
      final errors = <Object>[];
      final done = Completer<void>();
      e
          .listen(ListenMode.general)
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await done.future;
      expect(
        (errors.single as SenseException).reason,
        ListenReasons.permissionDenied,
      );
    });

    test(
      'native failure mid-session errors; a user stop just closes',
      () async {
        final e = engine();
        final errors = <Object>[];
        final done = Completer<void>();
        e
            .listen(ListenMode.general)
            .listen((_) {}, onError: errors.add, onDone: done.complete);
        await _pump();
        host.listen.add(
          TestSenseHost.status(
            NativeListenState.failed,
            NativeListenMode.general,
            reason: ListenReasons.micRerouted,
          ),
        );
        await done.future;
        expect(
          (errors.single as SenseException).reason,
          ListenReasons.micRerouted,
        );

        final errors2 = <Object>[];
        final done2 = Completer<void>();
        e
            .listen(ListenMode.night)
            .listen((_) {}, onError: errors2.add, onDone: done2.complete);
        await _pump();
        host.listen.add(
          TestSenseHost.status(
            NativeListenState.stopped,
            NativeListenMode.night,
            reason: ListenReasons.stoppedFromNotification,
          ),
        );
        await done2.future;
        expect(errors2, isEmpty);
      },
    );

    test(
      'a stop event from an earlier session does not end a new one',
      () async {
        host.onStart = (mode, _) {
          // Arrives while this session is starting (left over from a stop).
          host.listen.add(
            TestSenseHost.status(
              NativeListenState.stopped,
              NativeListenMode.general,
            ),
          );
          return TestSenseHost.status(NativeListenState.listening, mode);
        };
        final e = engine();
        var done = false;
        final got = <SignalCandidate>[];
        e.listen(ListenMode.general).listen(got.add, onDone: () => done = true);
        await _pump();
        await _pump();
        expect(done, isFalse);
        host.sounds.add(
          NativeSoundEvent(
            id: 'e9',
            score: 0.5,
            detectedAtEpochMs: 1700000004000,
            hint: null,
            labelled: false,
            onsetCount: 1,
          ),
        );
        await _pump();
        expect(got.single.id, 'e9');
        await e.stopListening();
        await _pump();
        expect(done, isTrue);
      },
    );

    test('cancelling the subscription stops native listening', () async {
      final e = engine();
      final sub = e.listen(ListenMode.general).listen((_) {});
      await _pump();
      await sub.cancel();
      expect(host.stopCalls, 1);
    });

    test(
      'clips and labels come from memory; errors give empty results',
      () async {
        final e = engine();
        host.clips['e1'] = Uint8List.fromList([82, 73, 70, 70]);
        host.labels['e1'] = [
          NativeScoredLabel(label: 'Mouse', score: 0.4, classIndex: 119),
        ];
        expect(await e.clipFor('e1'), [82, 73, 70, 70]);
        expect(await e.clipFor('missing'), isNull);
        final labels = await e.soundLabelsFor('e1');
        expect(labels.single.label, 'Mouse');
        expect(labels.single.score, 0.4);
        expect(await e.soundLabelsFor('missing'), isEmpty);
      },
    );
  });

  group('distance', () {
    test('available only with a value; ranges and confidence mapped', () async {
      final e = engine();
      host.onMeasure = (_) => NativeDistance(
        method: NativeDistanceMethod.focusDistance,
        meters: 0.32,
        lowMeters: 0.29,
        highMeters: 0.36,
        confidence: 0.7,
        reason: null,
      );
      final d = await e.measure(
        target: const NormalizedBox(
          left: 0.2,
          top: 0.3,
          width: 0.1,
          height: 0.1,
        ),
      );
      expect(d.isAvailable, isTrue);
      expect(d.method, DistanceMethod.focusDistance);
      expect(d.meters, 0.32);
      expect(d.lowMeters, 0.29);
      expect(d.highMeters, 0.36);
      expect(d.confidence, 0.7);
      expect(d.unavailableReason, isNull);
      expect(host.measureCalls.single!.left, 0.2);
    });

    test('a method without meters is reported unavailable', () async {
      final e = engine();
      host.onMeasure = (_) => NativeDistance(
        method: NativeDistanceMethod.arcoreDepth,
        meters: null,
        lowMeters: null,
        highMeters: null,
        confidence: null,
        reason: null,
      );
      final d = await e.measure();
      expect(d.method, DistanceMethod.unavailable);
      expect(d.isAvailable, isFalse);
      expect(d.unavailableReason, DistanceReasons.measureFailed);
      expect(host.measureCalls.single, isNull);
    });

    test('unavailable keeps the native reason key', () async {
      final e = engine();
      host.onMeasure = (_) => NativeDistance(
        method: NativeDistanceMethod.unavailable,
        meters: null,
        lowMeters: null,
        highMeters: null,
        confidence: null,
        reason: DistanceReasons.moveSlowly,
      );
      expect((await e.measure()).unavailableReason, 'move_phone_slowly');
    });

    test('bridge failures give unavailable, never a number', () async {
      final e = engine();
      host.throwOnDistance = true;
      final d = await e.measure();
      expect(d.method, DistanceMethod.unavailable);
      expect(d.unavailableReason, DistanceReasons.measureFailed);
      final cap = await e.distanceCapability();
      expect(cap.arcoreDepth, isFalse);
      expect(cap.focusDistance, isFalse);
      expect(cap.reason, DistanceReasons.arcoreUnsupported);
    });

    test('capability is mapped as reported', () async {
      final e = engine();
      final cap = await e.distanceCapability();
      expect(cap.arcoreDepth, isFalse);
      expect(cap.focusDistance, isTrue);
      expect(cap.reason, 'arcore_unsupported');
    });
  });

  test('keepMedia returns the app-private path from the plugin', () async {
    final e = engine();
    expect(await e.keepMedia('still-1'), endsWith('/sense_media/still-1.jpg'));
  });
}

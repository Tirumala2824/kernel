import 'package:audio_ai/audio_ai.dart';
import 'package:audio_ai/src/scan_api.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/fake_scan_host.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeScanHost host;
  late NativeScanEngine engine;

  setUp(() {
    host = FakeScanHost()..install();
    engine = NativeScanEngine();
  });

  tearDown(FakeScanHost.uninstall);

  group('captureAndAnalyze, no model bundled', () {
    test(
      'PASS maps to notEvaluated / "none" / experimental / null confidence',
      () async {
        host.onCapture = (_, _, _) => nativeResult();

        final o = await engine.captureAndAnalyze('item-1');

        expect(o.quality, ScanQuality.pass);
        expect(o.qualityReasons, isEmpty);
        expect(o.classification, Classification.notEvaluated);
        expect(o.modelVersion, noModelVersion);
        expect(o.experimental, isTrue);
        expect(o.confidence, isNull);
        expect(o.invariantViolations(), isEmpty);
      },
    );

    test('carries ids, timing and device fields from native', () async {
      host.onCapture = (_, _, _) => nativeResult(
        capturedAtEpochMs: 1760000000123,
        latencyMs: 34,
        durationMs: 1990,
        sampleRate: 48000,
        deviceModel: 'I2501',
        osVersion: 'Android 16 (SDK 36)',
      );

      final o = await engine.captureAndAnalyze('item-42', retainAudio: true);

      expect(o.itemId, 'item-42');
      expect(o.scanId, matches(_uuidV4));
      expect(host.captureCalls.single, (o.scanId, true, true));
      expect(o.capturedAt.isUtc, isTrue);
      expect(o.capturedAt.millisecondsSinceEpoch, 1760000000123);
      expect(o.latencyMs, 34);
      expect(o.durationMs, 1990);
      expect(o.sampleRate, 48000);
      expect(o.deviceModel, 'I2501');
      expect(o.osVersion, 'Android 16 (SDK 36)');
    });

    test(
      'retainAudio defaults to false and every scan gets a fresh UUID',
      () async {
        host.onCapture = (_, _, _) => nativeResult();

        final a = await engine.captureAndAnalyze('item-1');
        final b = await engine.captureAndAnalyze('item-1');

        expect(host.captureCalls.map((c) => c.$2), [false, false]);
        expect(a.scanId, isNot(b.scanId));
        expect(b.scanId, matches(_uuidV4));
      },
    );

    test('RETRY silence maps to retry/silence/notEvaluated', () async {
      host.onCapture = (_, _, _) => nativeResult(
        qualityPass: false,
        qualityReasons: [NativeQualityReason.silence],
      );

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.quality, ScanQuality.retry);
      expect(o.qualityReasons, [QualityReason.silence]);
      expect(o.classification, Classification.notEvaluated);
      expect(o.confidence, isNull);
      expect(o.invariantViolations(), isEmpty);
    });

    test('permission denied maps to RETRY permissionDenied', () async {
      host.onCapture = (_, _, _) => nativeResult(
        qualityPass: false,
        qualityReasons: [NativeQualityReason.permissionDenied],
        durationMs: 0,
        sampleRate: 0,
        latencyMs: 0,
      );

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.quality, ScanQuality.retry);
      expect(o.qualityReasons, [QualityReason.permissionDenied]);
      expect(o.sampleRate, 0);
      expect(o.invariantViolations(), isEmpty);
    });

    test(
      'a class reported with modelVersion "none" is never passed through',
      () async {
        host.onCapture = (_, _, _) => nativeResult(
          classification: NativeClassification.clean,
          confidence: 0.9,
          experimental: false,
        );

        final o = await engine.captureAndAnalyze('item-1');

        expect(o.classification, Classification.notEvaluated);
        expect(o.confidence, isNull);
        expect(o.experimental, isTrue);
        expect(o.invariantViolations(), isEmpty);
      },
    );

    test('empty modelVersion is treated as no model', () async {
      host.onCapture = (_, _, _) => nativeResult(
        modelVersion: '',
        classification: NativeClassification.infested,
        confidence: 0.7,
      );

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.modelVersion, noModelVersion);
      expect(o.classification, Classification.notEvaluated);
      expect(o.invariantViolations(), isEmpty);
    });
  });

  group('captureAndAnalyze, defensive mapping', () {
    test('RETRY never carries a class even if native sent one', () async {
      host.onCapture = (_, _, _) => nativeResult(
        qualityPass: false,
        qualityReasons: [NativeQualityReason.clipping],
        classification: NativeClassification.infested,
        confidence: 0.95,
        modelVersion: 'grain-cnn-1',
      );

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.quality, ScanQuality.retry);
      expect(o.classification, Classification.notEvaluated);
      expect(o.confidence, isNull);
      expect(o.modelVersion, 'grain-cnn-1');
      expect(o.invariantViolations(), isEmpty);
    });

    test('fail without reason becomes captureError; pass with reason becomes RETRY', () async {
      host.onCapture = (_, _, _) => nativeResult(qualityPass: false);
      final noReason = await engine.captureAndAnalyze('item-1');
      expect(noReason.quality, ScanQuality.retry);
      expect(noReason.qualityReasons, [QualityReason.captureError]);

      host.onCapture = (_, _, _) => nativeResult(
        qualityPass: true,
        qualityReasons: [NativeQualityReason.highNoise],
      );
      final contradictory = await engine.captureAndAnalyze('item-1');
      expect(contradictory.quality, ScanQuality.retry);
      expect(contradictory.qualityReasons, [QualityReason.highNoise]);
      expect(contradictory.invariantViolations(), isEmpty);
    });

    test('duplicate reasons are collapsed in order', () async {
      host.onCapture = (_, _, _) => nativeResult(
        qualityPass: false,
        qualityReasons: [
          NativeQualityReason.clipping,
          NativeQualityReason.highNoise,
          NativeQualityReason.clipping,
        ],
      );

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.qualityReasons, [
        QualityReason.clipping,
        QualityReason.highNoise,
      ]);
    });

    test('a real model result on PASS is passed through unchanged', () async {
      host.onCapture = (_, _, _) => nativeResult(
        classification: NativeClassification.infested,
        confidence: 0.82,
        modelVersion: 'grain-cnn-1',
      );

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.quality, ScanQuality.pass);
      expect(o.classification, Classification.infested);
      expect(o.confidence, 0.82);
      expect(o.modelVersion, 'grain-cnn-1');
      expect(o.experimental, isTrue);
      expect(o.invariantViolations(), isEmpty);
    });

    test('out-of-range confidence is treated as a failed inference', () async {
      host.onCapture = (_, _, _) => nativeResult(
        classification: NativeClassification.clean,
        confidence: 1.5,
        modelVersion: 'grain-cnn-1',
      );

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.classification, Classification.notEvaluated);
      expect(o.confidence, isNull);
      expect(o.invariantViolations(), isEmpty);
    });

    test('negative timing values are clamped to zero', () async {
      host.onCapture = (_, _, _) =>
          nativeResult(latencyMs: -5, durationMs: -1, sampleRate: -16000);

      final o = await engine.captureAndAnalyze('item-1');

      expect([o.latencyMs, o.durationMs, o.sampleRate], [0, 0, 0]);
    });

    test(
      'every native enum value maps to the contract value of the same name',
      () async {
        for (final reason in NativeQualityReason.values) {
          host.onCapture = (_, _, _) =>
              nativeResult(qualityPass: false, qualityReasons: [reason]);
          final o = await engine.captureAndAnalyze('item-1');
          expect(o.qualityReasons.single.name, reason.name);
        }
        for (final c in NativeClassification.values) {
          host.onCapture = (_, _, _) => nativeResult(
            classification: c,
            confidence: c == NativeClassification.notEvaluated ? null : 0.6,
            modelVersion: 'grain-cnn-1',
          );
          final o = await engine.captureAndAnalyze('item-1');
          expect(o.classification.name, c.name);
        }
      },
    );
  });

  group('captureAndAnalyze never throws', () {
    test('native error reply becomes RETRY captureError', () async {
      host.onCapture = (_, _, _) =>
          throw PlatformException(code: 'IllegalStateException', message: 'x');

      final o = await engine.captureAndAnalyze('item-9');

      expect(o.itemId, 'item-9');
      expect(o.scanId, matches(_uuidV4));
      expect(o.quality, ScanQuality.retry);
      expect(o.qualityReasons, [QualityReason.captureError]);
      expect(o.classification, Classification.notEvaluated);
      expect(o.modelVersion, noModelVersion);
      expect(o.experimental, isTrue);
      expect(o.confidence, isNull);
      expect(o.capturedAt.isUtc, isTrue);
      expect(o.audioRetained, isFalse);
      expect(o.invariantViolations(), isEmpty);
    });

    test('missing plugin becomes RETRY captureError', () async {
      FakeScanHost.uninstall();

      final o = await engine.captureAndAnalyze('item-9');

      expect(o.quality, ScanQuality.retry);
      expect(o.qualityReasons, [QualityReason.captureError]);
      expect(o.deviceModel, 'unknown');
      expect(o.audioRetained, isFalse);
      expect(o.invariantViolations(), isEmpty);
    });

    test(
      'failure outcome reuses device identity from an earlier call',
      () async {
        host.onInfo = nativeInfo;
        await engine.info();
        host.onCapture = (_, _, _) => throw PlatformException(code: 'boom');

        final o = await engine.captureAndAnalyze('item-1');

        expect(o.deviceModel, 'I2501');
        expect(o.osVersion, 'Android 16 (SDK 36)');
      },
    );
  });

  group('captureAndAnalyze, haptics flag (v2)', () {
    test('haptics defaults to true', () async {
      host.onCapture = (_, _, _) => nativeResult();

      await engine.captureAndAnalyze('item-1');
      await engine.captureAndAnalyze('item-1', retainAudio: true);

      expect(host.captureCalls.map((c) => c.$3), [true, true]);
    });

    test(
      'haptics false reaches native unchanged, independent of retain',
      () async {
        host.onCapture = (_, _, _) => nativeResult();

        await engine.captureAndAnalyze('item-1', haptics: false);
        await engine.captureAndAnalyze(
          'item-1',
          retainAudio: true,
          haptics: false,
        );
        await engine.captureAndAnalyze('item-1', haptics: true);

        expect(host.captureCalls.map((c) => (c.$2, c.$3)), [
          (false, false),
          (true, false),
          (false, true),
        ]);
      },
    );
  });

  group('captureAndAnalyze, audioRetained (v2)', () {
    test('false unless native says the WAV was written', () async {
      host.onCapture = (_, _, _) => nativeResult();

      final o = await engine.captureAndAnalyze('item-1', retainAudio: true);

      expect(o.audioRetained, isFalse);
    });

    test('true when native wrote the WAV', () async {
      host.onCapture = (_, retain, _) => nativeResult(audioRetained: retain);

      final o = await engine.captureAndAnalyze('item-1', retainAudio: true);

      expect(o.audioRetained, isTrue);
      expect(o.invariantViolations(), isEmpty);
    });

    test('a RETRY recording that was kept still reports it', () async {
      host.onCapture = (_, _, _) => nativeResult(
        qualityPass: false,
        qualityReasons: [NativeQualityReason.highNoise],
        audioRetained: true,
      );

      final o = await engine.captureAndAnalyze('item-1', retainAudio: true);

      expect(o.quality, ScanQuality.retry);
      expect(o.audioRetained, isTrue);
      expect(o.invariantViolations(), isEmpty);
    });
  });

  group('captureLevels (v2)', () {
    /// Lets platform-channel messages (listen, events, cancel) settle.
    Future<void> settle() => pumpEventQueue();

    test('maps every native reading to a contracts CaptureLevel', () async {
      final received = <CaptureLevel>[];
      final sub = engine.captureLevels().listen(received.add);
      await settle();

      host.emitLevel(
        nativeLevel(
          elapsedMs: 50,
          targetMs: 2000,
          rmsDbfs: -48.5,
          peakDbfs: -31.25,
        ),
      );
      host.emitLevel(
        nativeLevel(
          elapsedMs: 2000,
          targetMs: 2000,
          rmsDbfs: -20,
          peakDbfs: -3,
        ),
      );
      await settle();
      await sub.cancel();
      await settle();

      expect(received, hasLength(2));
      final first = received.first;
      expect(first.elapsedMs, 50);
      expect(first.targetMs, 2000);
      expect(first.rmsDbfs, -48.5);
      expect(first.peakDbfs, -31.25);
      expect(first.progress, closeTo(0.025, 1e-12));
      expect(received.last.progress, 1.0);
    });

    test(
      'is one broadcast stream shared by every listener and engine',
      () async {
        expect(engine.captureLevels().isBroadcast, isTrue);
        expect(
          identical(engine.captureLevels(), NativeScanEngine().captureLevels()),
          isTrue,
        );

        final a = <CaptureLevel>[];
        final b = <CaptureLevel>[];
        final subA = engine.captureLevels().listen(a.add);
        final subB = NativeScanEngine().captureLevels().listen(b.add);
        await settle();

        host.emitLevel(nativeLevel(elapsedMs: 100));
        await settle();

        expect(host.levelListens, 1, reason: 'one native subscription');
        expect(a.map((l) => l.elapsedMs), [100]);
        expect(b.map((l) => l.elapsedMs), [100]);

        await subA.cancel();
        await settle();
        expect(host.levelCancels, 0, reason: 'B is still listening');
        await subB.cancel();
        await settle();
        expect(
          host.levelCancels,
          1,
          reason: 'native stops when nobody listens',
        );
        expect(host.levelsListened, isFalse);
      },
    );

    test('emits nothing while native sends nothing (idle)', () async {
      final received = <CaptureLevel>[];
      final sub = engine.captureLevels().listen(received.add);
      await settle();
      await settle();
      await sub.cancel();
      await settle();

      expect(host.levelListens, 1);
      expect(received, isEmpty);
    });

    test('pins out-of-range values to the meter range', () async {
      final received = <CaptureLevel>[];
      final sub = engine.captureLevels().listen(received.add);
      await settle();

      host.emitLevel(
        nativeLevel(
          elapsedMs: -5,
          targetMs: -1,
          rmsDbfs: double.nan,
          peakDbfs: 4.0,
        ),
      );
      host.emitLevel(
        nativeLevel(rmsDbfs: double.negativeInfinity, peakDbfs: -500),
      );
      await settle();
      await sub.cancel();
      await settle();

      expect(received[0].elapsedMs, 0);
      expect(received[0].targetMs, 0);
      expect(received[0].progress, 0);
      expect(received[0].rmsDbfs, -120);
      expect(received[0].peakDbfs, 0);
      expect(received[1].rmsDbfs, -120);
      expect(received[1].peakDbfs, -120);
    });

    test('error events are dropped and later readings still arrive', () async {
      final received = <CaptureLevel>[];
      final errors = <Object>[];
      final sub = engine.captureLevels().listen(
        received.add,
        onError: errors.add,
      );
      await settle();

      host.emitLevelError('boom');
      host.emitLevel(nativeLevel(elapsedMs: 150));
      await settle();
      await sub.cancel();
      await settle();

      expect(errors, isEmpty);
      expect(received.map((l) => l.elapsedMs), [150]);
    });

    test('a listener can resubscribe after cancelling', () async {
      final first = <CaptureLevel>[];
      final sub1 = engine.captureLevels().listen(first.add);
      await settle();
      await sub1.cancel();
      await settle();

      final second = <CaptureLevel>[];
      final sub2 = engine.captureLevels().listen(second.add);
      await settle();
      host.emitLevel(nativeLevel(elapsedMs: 250));
      await settle();
      await sub2.cancel();
      await settle();

      expect(host.levelListens, 2);
      expect(first, isEmpty);
      expect(second.map((l) => l.elapsedMs), [250]);
    });
  });

  group('info', () {
    test('no model', () async {
      host.onInfo = nativeInfo;

      final i = await engine.info();

      expect(i.modelPresent, isFalse);
      expect(i.modelVersion, noModelVersion);
      expect(i.experimental, isTrue);
      expect(i.targetSampleRate, 16000);
      expect(i.effectiveSampleRate, isNull);
      expect(i.delegate, InferenceDelegate.none);
      expect(i.deviceModel, 'I2501');
    });

    test('loaded model on CPU with probed rate', () async {
      host.onInfo = () => nativeInfo(
        modelPresent: true,
        modelVersion: 'grain-cnn-1',
        effectiveSampleRate: 16000,
        delegate: NativeDelegate.cpu,
      );

      final i = await engine.info();

      expect(i.modelPresent, isTrue);
      expect(i.modelVersion, 'grain-cnn-1');
      expect(i.effectiveSampleRate, 16000);
      expect(i.delegate, InferenceDelegate.cpu);
    });

    test('"present" with version "none" is reported as no model', () async {
      host.onInfo = () => nativeInfo(
        modelPresent: true,
        experimental: false,
        delegate: NativeDelegate.cpu,
        modelNote: 'stale note',
      );

      final i = await engine.info();

      expect(i.modelPresent, isFalse);
      expect(i.experimental, isTrue);
      expect(i.delegate, InferenceDelegate.none);
      expect(i.modelNote, isNull);
    });

    test(
      'bridge failure reports no usable model instead of throwing',
      () async {
        FakeScanHost.uninstall();

        final i = await engine.info();

        expect(i.modelPresent, isFalse);
        expect(i.modelVersion, noModelVersion);
        expect(i.delegate, InferenceDelegate.none);
        expect(i.effectiveSampleRate, isNull);
        expect(i.modelNote, isNull);
        expect(i.audioSource, isNull);
        expect(i.deviceInputSampleRate, isNull);
      },
    );
  });

  group('info, v2 fields', () {
    test('audioSource and rates before any capture', () async {
      host.onInfo = nativeInfo;

      final i = await engine.info();

      expect(i.audioSource, 'VOICE_RECOGNITION');
      expect(i.effectiveSampleRate, isNull);
      expect(i.deviceInputSampleRate, isNull, reason: 'not probed yet');
      expect(i.modelNote, isNull, reason: 'no model, no provenance');
    });

    test('hardware input rate after a capture is passed through', () async {
      host.onInfo = () =>
          nativeInfo(effectiveSampleRate: 16000, deviceInputSampleRate: 48000);

      final i = await engine.info();

      expect(i.effectiveSampleRate, 16000);
      expect(i.deviceInputSampleRate, 48000);
    });

    test('non-positive rates are reported as unknown', () async {
      host.onInfo = () =>
          nativeInfo(effectiveSampleRate: 0, deviceInputSampleRate: -1);

      final i = await engine.info();

      expect(i.effectiveSampleRate, isNull);
      expect(i.deviceInputSampleRate, isNull);
    });

    test('modelNote comes from the bundled model manifest', () async {
      host.onInfo = () => nativeInfo(
        modelPresent: true,
        modelVersion: 'proxy-cnn-1',
        delegate: NativeDelegate.cpu,
        modelNote: '  Trained on non-grain proxy recordings.  ',
      );

      final i = await engine.info();

      expect(i.modelPresent, isTrue);
      expect(i.experimental, isTrue);
      expect(i.modelNote, 'Trained on non-grain proxy recordings.');
    });

    test('blank modelNote and audioSource become null', () async {
      host.onInfo = () => nativeInfo(
        modelPresent: true,
        modelVersion: 'grain-cnn-1',
        modelNote: '   ',
        audioSource: '',
      );

      final i = await engine.info();

      expect(i.modelNote, isNull);
      expect(i.audioSource, isNull);
    });
  });

  group('retainedAudioPath (v2)', () {
    const scanId = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';
    const path = '/data/user/0/com.kernel.app/files/recordings/$scanId.wav';

    test('returns the native absolute path for the scan', () async {
      final asked = <String>[];
      host.onRetainedPath = (id) {
        asked.add(id);
        return path;
      };

      expect(await engine.retainedAudioPath(scanId), path);
      expect(asked, [scanId]);
    });

    test('null when nothing was retained for the scan', () async {
      host.onRetainedPath = (_) => null;
      expect(await engine.retainedAudioPath(scanId), isNull);

      host.onRetainedPath = (_) => '';
      expect(await engine.retainedAudioPath(scanId), isNull);
    });

    test('propagates a native failure instead of reporting "none"', () async {
      host.onRetainedPath = (_) => throw PlatformException(code: 'IOException');

      await expectLater(
        engine.retainedAudioPath(scanId),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('deleteRetainedAudio', () {
    test('completes when native deleted files', () async {
      var calls = 0;
      host.onDelete = () {
        calls++;
        return 3;
      };
      await engine.deleteRetainedAudio();
      expect(calls, 1);
    });

    test(
      'completes when there is nothing to delete (folder missing)',
      () async {
        host.onDelete = () => 0;
        await expectLater(engine.deleteRetainedAudio(), completes);
      },
    );

    test('propagates failure so the UI can tell the user', () async {
      host.onDelete = () => throw PlatformException(code: 'IOException');
      await expectLater(
        engine.deleteRetainedAudio(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('analyzeAudioFile', () {
    test('carries file provenance, sensor type, node id, and asqi score', () async {
      host.onAnalyzeFile = (scanId, path, retain) => nativeResult(
        qualityPass: true,
        asqiScore: 0.92,
        durationMs: 2000,
        sampleRate: 16000,
      );

      final outcome = await engine.analyzeAudioFile(
        'sack-item-99',
        '/storage/emulated/0/Download/insect_recording_01.wav',
        sensorType: SensorType.contactPiezo,
        sensorNodeId: 'NODE-BLE-401',
        retainAudio: false,
      );

      expect(outcome.itemId, 'sack-item-99');
      expect(outcome.scanId, matches(_uuidV4));
      expect(outcome.inputSource, AudioInputSource.fileUpload);
      expect(outcome.sensorType, SensorType.contactPiezo);
      expect(outcome.sensorNodeId, 'NODE-BLE-401');
      expect(outcome.sourceFileName, 'insect_recording_01.wav');
      expect(outcome.asqiScore, 0.92);
      expect(outcome.quality, ScanQuality.pass);
      expect(outcome.invariantViolations(), isEmpty);

      expect(host.analyzeFileCalls.single, (
        outcome.scanId,
        '/storage/emulated/0/Download/insect_recording_01.wav',
        false,
      ));
    });

    test('maps retry quality reasons from file analysis', () async {
      host.onAnalyzeFile = (scanId, path, retain) => nativeResult(
        qualityPass: false,
        qualityReasons: [NativeQualityReason.highNoise],
        asqiScore: 0.35,
      );

      final outcome = await engine.analyzeAudioFile(
        'sack-item-100',
        'C:/audio/grain_noisy.wav',
        sensorType: SensorType.audioAir,
      );

      expect(outcome.quality, ScanQuality.retry);
      expect(outcome.qualityReasons, [QualityReason.highNoise]);
      expect(outcome.classification, Classification.notEvaluated);
      expect(outcome.asqiScore, 0.35);
      expect(outcome.inputSource, AudioInputSource.fileUpload);
      expect(outcome.sourceFileName, 'grain_noisy.wav');
      expect(outcome.invariantViolations(), isEmpty);
    });

    test('bridge error returns failure outcome without throwing', () async {
      host.onAnalyzeFile = (_, _, _) => throw PlatformException(code: 'FileReadError');

      final outcome = await engine.analyzeAudioFile(
        'sack-item-101',
        'bad_file.wav',
      );

      expect(outcome.quality, ScanQuality.retry);
      expect(outcome.qualityReasons, [QualityReason.captureError]);
      expect(outcome.classification, Classification.notEvaluated);
      expect(outcome.sourceFileName, 'bad_file.wav');
      expect(outcome.inputSource, AudioInputSource.fileUpload);
      expect(outcome.invariantViolations(), isEmpty);
    });
  });
}

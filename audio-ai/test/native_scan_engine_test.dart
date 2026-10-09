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
    test('PASS maps to notEvaluated / "none" / experimental / null confidence', () async {
      host.onCapture = (_, _) => nativeResult();

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.quality, ScanQuality.pass);
      expect(o.qualityReasons, isEmpty);
      expect(o.classification, Classification.notEvaluated);
      expect(o.modelVersion, noModelVersion);
      expect(o.experimental, isTrue);
      expect(o.confidence, isNull);
      expect(o.invariantViolations(), isEmpty);
    });

    test('carries ids, timing and device fields from native', () async {
      host.onCapture = (_, _) => nativeResult(
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
      expect(host.captureCalls.single, (o.scanId, true));
      expect(o.capturedAt.isUtc, isTrue);
      expect(o.capturedAt.millisecondsSinceEpoch, 1760000000123);
      expect(o.latencyMs, 34);
      expect(o.durationMs, 1990);
      expect(o.sampleRate, 48000);
      expect(o.deviceModel, 'I2501');
      expect(o.osVersion, 'Android 16 (SDK 36)');
    });

    test('retainAudio defaults to false and every scan gets a fresh UUID', () async {
      host.onCapture = (_, _) => nativeResult();

      final a = await engine.captureAndAnalyze('item-1');
      final b = await engine.captureAndAnalyze('item-1');

      expect(host.captureCalls.map((c) => c.$2), [false, false]);
      expect(a.scanId, isNot(b.scanId));
      expect(b.scanId, matches(_uuidV4));
    });

    test('RETRY silence maps to retry/silence/notEvaluated', () async {
      host.onCapture = (_, _) => nativeResult(
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
      host.onCapture = (_, _) => nativeResult(
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

    test('a class reported with modelVersion "none" is never passed through', () async {
      host.onCapture = (_, _) => nativeResult(
        classification: NativeClassification.clean,
        confidence: 0.9,
        experimental: false,
      );

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.classification, Classification.notEvaluated);
      expect(o.confidence, isNull);
      expect(o.experimental, isTrue);
      expect(o.invariantViolations(), isEmpty);
    });

    test('empty modelVersion is treated as no model', () async {
      host.onCapture = (_, _) => nativeResult(
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
      host.onCapture = (_, _) => nativeResult(
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
      host.onCapture = (_, _) => nativeResult(qualityPass: false);
      final noReason = await engine.captureAndAnalyze('item-1');
      expect(noReason.quality, ScanQuality.retry);
      expect(noReason.qualityReasons, [QualityReason.captureError]);

      host.onCapture = (_, _) => nativeResult(
        qualityPass: true,
        qualityReasons: [NativeQualityReason.highNoise],
      );
      final contradictory = await engine.captureAndAnalyze('item-1');
      expect(contradictory.quality, ScanQuality.retry);
      expect(contradictory.qualityReasons, [QualityReason.highNoise]);
      expect(contradictory.invariantViolations(), isEmpty);
    });

    test('duplicate reasons are collapsed in order', () async {
      host.onCapture = (_, _) => nativeResult(
        qualityPass: false,
        qualityReasons: [
          NativeQualityReason.clipping,
          NativeQualityReason.highNoise,
          NativeQualityReason.clipping,
        ],
      );

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.qualityReasons, [QualityReason.clipping, QualityReason.highNoise]);
    });

    test('a real model result on PASS is passed through unchanged', () async {
      host.onCapture = (_, _) => nativeResult(
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
      host.onCapture = (_, _) => nativeResult(
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
      host.onCapture = (_, _) =>
          nativeResult(latencyMs: -5, durationMs: -1, sampleRate: -16000);

      final o = await engine.captureAndAnalyze('item-1');

      expect([o.latencyMs, o.durationMs, o.sampleRate], [0, 0, 0]);
    });

    test('every native enum value maps to the contract value of the same name', () async {
      for (final reason in NativeQualityReason.values) {
        host.onCapture = (_, _) =>
            nativeResult(qualityPass: false, qualityReasons: [reason]);
        final o = await engine.captureAndAnalyze('item-1');
        expect(o.qualityReasons.single.name, reason.name);
      }
      for (final c in NativeClassification.values) {
        host.onCapture = (_, _) => nativeResult(
          classification: c,
          confidence: c == NativeClassification.notEvaluated ? null : 0.6,
          modelVersion: 'grain-cnn-1',
        );
        final o = await engine.captureAndAnalyze('item-1');
        expect(o.classification.name, c.name);
      }
    });
  });

  group('captureAndAnalyze never throws', () {
    test('native error reply becomes RETRY captureError', () async {
      host.onCapture = (_, _) =>
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
      expect(o.invariantViolations(), isEmpty);
    });

    test('missing plugin becomes RETRY captureError', () async {
      FakeScanHost.uninstall();

      final o = await engine.captureAndAnalyze('item-9');

      expect(o.quality, ScanQuality.retry);
      expect(o.qualityReasons, [QualityReason.captureError]);
      expect(o.deviceModel, 'unknown');
      expect(o.invariantViolations(), isEmpty);
    });

    test('failure outcome reuses device identity from an earlier call', () async {
      host.onInfo = () => NativeEngineInfo(
        modelPresent: false,
        modelVersion: 'none',
        experimental: true,
        targetSampleRate: 16000,
        effectiveSampleRate: null,
        delegate: NativeDelegate.none,
        deviceModel: 'I2501',
        osVersion: 'Android 16 (SDK 36)',
      );
      await engine.info();
      host.onCapture = (_, _) => throw PlatformException(code: 'boom');

      final o = await engine.captureAndAnalyze('item-1');

      expect(o.deviceModel, 'I2501');
      expect(o.osVersion, 'Android 16 (SDK 36)');
    });
  });

  group('info', () {
    NativeEngineInfo nativeInfo({
      bool modelPresent = false,
      String modelVersion = 'none',
      bool experimental = true,
      int? effectiveSampleRate,
      NativeDelegate delegate = NativeDelegate.none,
    }) => NativeEngineInfo(
      modelPresent: modelPresent,
      modelVersion: modelVersion,
      experimental: experimental,
      targetSampleRate: 16000,
      effectiveSampleRate: effectiveSampleRate,
      delegate: delegate,
      deviceModel: 'I2501',
      osVersion: 'Android 16 (SDK 36)',
    );

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
      );

      final i = await engine.info();

      expect(i.modelPresent, isFalse);
      expect(i.experimental, isTrue);
      expect(i.delegate, InferenceDelegate.none);
    });

    test('bridge failure reports no usable model instead of throwing', () async {
      FakeScanHost.uninstall();

      final i = await engine.info();

      expect(i.modelPresent, isFalse);
      expect(i.modelVersion, noModelVersion);
      expect(i.delegate, InferenceDelegate.none);
      expect(i.effectiveSampleRate, isNull);
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

    test('completes when there is nothing to delete (folder missing)', () async {
      host.onDelete = () => 0;
      await expectLater(engine.deleteRetainedAudio(), completes);
    });

    test('propagates failure so the UI can tell the user', () async {
      host.onDelete = () => throw PlatformException(code: 'IOException');
      await expectLater(
        engine.deleteRetainedAudio(),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}

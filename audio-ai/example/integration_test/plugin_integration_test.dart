// On-device check of the real plugin (run with `flutter test
// integration_test` from audio-ai/example on the iQOO 15, with RECORD_AUDIO
// granted). No model is bundled yet, so the engine must report "none" and
// never classify.
import 'package:audio_ai/audio_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  bool recorded(ScanOutcome o) =>
      !o.qualityReasons.contains(QualityReason.permissionDenied) &&
      !o.qualityReasons.contains(QualityReason.captureError);

  testWidgets('engine info reports no bundled model', (tester) async {
    final info = await NativeScanEngine().info();

    expect(info.modelPresent, isFalse);
    expect(info.modelVersion, noModelVersion);
    expect(info.experimental, isTrue);
    expect(info.modelNote, isNull);
    expect(info.targetSampleRate, 16000);
    expect(info.audioSource, 'VOICE_RECOGNITION');
    expect(info.deviceModel, isNot('unknown'));
  });

  testWidgets('a real capture yields a contract-valid, unclassified outcome', (
    tester,
  ) async {
    final outcome = await NativeScanEngine().captureAndAnalyze('it-item');

    expect(outcome.invariantViolations(), isEmpty);
    expect(outcome.classification, Classification.notEvaluated);
    expect(outcome.modelVersion, noModelVersion);
    expect(outcome.confidence, isNull);
    expect(outcome.audioRetained, isFalse);
  });

  testWidgets('live levels arrive only while recording', (tester) async {
    final engine = NativeScanEngine();
    final levels = <CaptureLevel>[];
    final sub = engine.captureLevels().listen(levels.add);

    final outcome = await engine.captureAndAnalyze('it-item', haptics: false);
    final countAtResult = levels.length;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await sub.cancel();

    expect(levels.length, countAtResult, reason: 'nothing after the capture');
    if (!recorded(outcome)) {
      expect(levels, isEmpty);
      return;
    }
    // 2000 ms in 50 ms windows; an interrupted capture has fewer.
    expect(levels.length, inInclusiveRange(30, 41));
    expect(levels.every((l) => l.targetMs == 2000), isTrue);
    expect(levels.last.elapsedMs, outcome.durationMs);
    for (var i = 1; i < levels.length; i++) {
      expect(levels[i].elapsedMs, greaterThan(levels[i - 1].elapsedMs));
    }
    for (final l in levels) {
      expect(l.rmsDbfs, lessThanOrEqualTo(l.peakDbfs + 1e-9));
      expect(l.peakDbfs, inInclusiveRange(-120, 0));
    }

    final info = await engine.info();
    expect(info.effectiveSampleRate, outcome.sampleRate);
    // API 29+ reports the HAL rate (the iQOO 15 runs Android 16).
    expect(info.deviceInputSampleRate, isNotNull);
  });

  testWidgets('retained audio has a path until it is deleted', (tester) async {
    final engine = NativeScanEngine();

    final outcome = await engine.captureAndAnalyze(
      'it-item',
      retainAudio: true,
      haptics: false,
    );
    if (!recorded(outcome)) {
      expect(outcome.audioRetained, isFalse);
      return;
    }

    expect(outcome.audioRetained, isTrue);
    final path = await engine.retainedAudioPath(outcome.scanId);
    expect(path, endsWith('/files/recordings/${outcome.scanId}.wav'));

    await engine.deleteRetainedAudio();
    expect(await engine.retainedAudioPath(outcome.scanId), isNull);
  });
}

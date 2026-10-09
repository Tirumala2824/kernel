// On-device check of the real plugin (run with `flutter test
// integration_test` from audio-ai/example on the iQOO 15). No model is
// bundled yet, so the engine must report "none" and never classify.
import 'package:audio_ai/audio_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('engine info reports no bundled model', (tester) async {
    final info = await NativeScanEngine().info();

    expect(info.modelPresent, isFalse);
    expect(info.modelVersion, noModelVersion);
    expect(info.experimental, isTrue);
    expect(info.targetSampleRate, 16000);
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
  });
}

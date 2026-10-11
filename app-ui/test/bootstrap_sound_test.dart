import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/bootstrap.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sense_ai/sense_ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled sound classification survives unavailable local storage',
    () async {
      // No path-provider plugin is installed in this unit-test host: bootstrap
      // must still bind the independent bundled sound service after DB failure.
      final container = ProviderContainer(
        overrides: await bootstrapOverrides(),
      );
      addTearDown(container.dispose);
      final classifier = container.read(insectSoundClassifierProvider);
      expect(classifier, isA<NativeInsectSoundClassifier>());

      const channel = MethodChannel('com.kernel.sense_ai/insect_sound');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return {
              'status': 'rejected',
              'level': 'unknown',
              'label': null,
              'topLabels': <Object>[],
              'reasons': ['low_level'],
              'modelId': 'ganesh333/kernel-insect-classifier',
              'modelVersion': 'none',
              'modelRevision': '001425d7fab4b44af5cc571174410f1c78552d0e',
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final result = await classifier.classifyWavFile('/test/quiet.wav');
      expect(calls.single.method, 'classifyWavFile');
      expect(calls.single.arguments, {'path': '/test/quiet.wav'});
      expect(result.status, InsectSoundStatus.rejected);
      expect(result.reasons, ['low_level']);
      expect(result.topLabels, isEmpty);
    },
  );
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sense_ai/sense_ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.kernel.sense_ai/insect_sound');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('missing Android plugin is honestly unavailable', () async {
    final result = await NativeInsectSoundClassifier().classifyWavFile(
      '/private/clip.wav',
    );
    expect(result.status, InsectSoundStatus.unavailable);
    expect(result.reasons, ['platform_unavailable']);
    expect(result.modelVersion, 'none');
    expect(result.topLabels, isEmpty);
    expect(result.invariantViolations(), isEmpty);
  });

  test(
    'platform failure and malformed native responses cannot become matches',
    () async {
      for (final response in <Object?>[
        null,
        {'status': 'evaluated'},
        'broken',
      ]) {
        messenger.setMockMethodCallHandler(channel, (_) async => response);
        final result = await NativeInsectSoundClassifier().classifyWavFile(
          '/private/clip.wav',
        );
        expect(result.status, InsectSoundStatus.unavailable);
        expect(result.reasons, ['invalid_native_result']);
        expect(result.topLabels, isEmpty);
      }
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'io'),
      );
      final result = await NativeInsectSoundClassifier().classifyWavFile(
        '/private/clip.wav',
      );
      expect(result.status, InsectSoundStatus.unavailable);
      expect(result.reasons, ['native_failure']);
    },
  );

  test(
    'rejects identification leaks and invalid scores from native envelopes',
    () async {
      for (final changes in <Map<String, Object?>>[
        {'status': 'rejected'},
        {'status': 'unavailable'},
        {'modelVersion': 'none'},
        {'modelRevision': 'not-a-revision'},
        {'topLabels': <Object>[]},
        {'label': 'Unsupported species'},
        {
          'topLabels': [
            {'label': 'Myopsaltaleona', 'score': 0.59},
          ],
        },
        {
          'topLabels': [
            {'label': 'Myopsaltaleona', 'score': 0.6},
            {'label': 'Other species', 'score': 0.7},
          ],
        },
        {
          'topLabels': [
            {'label': 'Myopsaltaleona', 'score': double.nan},
          ],
        },
        {
          'topLabels': [
            {'label': 'Myopsaltaleona', 'score': 1.1},
          ],
        },
      ]) {
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => {
            'status': 'evaluated',
            'level': 'species',
            'label': 'Myopsaltaleona',
            'topLabels': [
              {'label': 'Myopsaltaleona', 'score': 0.7},
            ],
            'reasons': <String>[],
            'modelId': 'ganesh333/kernel-insect-classifier',
            'modelVersion': '0.1.0-experimental',
            'modelRevision': '001425d7fab4b44af5cc571174410f1c78552d0e',
            'sampleRate': 16000,
            'durationMs': 2500,
            ...changes,
          },
        );
        final result = await NativeInsectSoundClassifier().classifyWavFile(
          '/private/clip.wav',
        );
        expect(result.status, InsectSoundStatus.unavailable);
        expect(result.topLabels, isEmpty);
        expect(result.reasons, ['invalid_native_result']);
        expect(result.invariantViolations(), isEmpty);
      }
    },
  );

  test('malformed native reasons are rejected before rendering', () async {
    for (final status in ['rejected', 'unavailable']) {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'status': status,
          'level': 'unknown',
          'label': null,
          'topLabels': <Object>[],
          'reasons': [123],
          'modelId': 'ganesh333/kernel-insect-classifier',
          'modelVersion': 'none',
          'modelRevision': '001425d7fab4b44af5cc571174410f1c78552d0e',
          'experimental': true,
        },
      );
      final result = await NativeInsectSoundClassifier().classifyWavFile(
        '/private/clip.wav',
      );
      expect(result.status, InsectSoundStatus.unavailable);
      expect(result.reasons, ['invalid_native_result']);
      expect(result.topLabels, isEmpty);
    }
  });

  test('maps a real native inference envelope without relabelling it', () async {
    // Channel test double only; these scores are NOT a classification fixture.
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'classifyWavFile');
      expect(call.arguments, {'path': '/private/clip.wav'});
      return {
        'status': 'evaluated',
        'level': 'genus',
        'label': 'Myopsalta',
        'topLabels': [
          {'label': 'Myopsaltaleona', 'score': 0.4, 'index': 6},
        ],
        'reasons': <String>[],
        'modelId': 'tests/native-insect-model',
        'experimental': true,
        'modelVersion': '0.1.0-experimental',
        'modelRevision': '001425d7fab4b44af5cc571174410f1c78552d0e',
        'sampleRate': 16000,
        'durationMs': 2500,
      };
    });
    final result = await NativeInsectSoundClassifier().classifyWavFile(
      '/private/clip.wav',
    );
    expect(result.status, InsectSoundStatus.evaluated);
    expect(result.level, InsectIdentificationLevel.genus);
    expect(result.label, 'Myopsalta');
    expect(result.topLabels.single.label, 'Myopsaltaleona');
    expect(result.topLabels.single.score, 0.4);
    expect(result.modelId, 'tests/native-insect-model');
    expect(result.modelVersion, '0.1.0-experimental');
    expect(result.modelRevision, '001425d7fab4b44af5cc571174410f1c78552d0e');
    expect(result.sampleRate, 16000);
    expect(result.durationMs, 2500);
    expect(result.experimental, isTrue);
    expect(result.invariantViolations(), isEmpty);
  });
}

// End-to-end app wiring with the real bundled model. The numerical waveform
// below is test-only: its match is NOT evidence of field recognition accuracy.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kernel_app/agents/agents.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/bootstrap.dart';
import 'package:kernel_app/features/chat/chat_copy.dart';
import 'package:kernel_app/features/chat/kernel_chat_screen.dart';
import 'package:kernel_app/l10n/l10n.dart';
import 'package:kernel_app/theme/kernel_theme.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sense_ai/sense_ai.dart';

class _TestFilePicker extends MediaPickerService {
  _TestFilePicker(this.path);
  final String path;
  @override
  Future<PickedMedia?> pickAudioFile({
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
  }) async => PickedMedia(
    path: path,
    fileName: 'numerical-port-test.wav',
    bytes: Uint8List(0),
    mediaType: 'audio',
  );
}

Uint8List _wave({required bool silent}) {
  const samples = 32000;
  final data = ByteData(44 + samples * 2);
  void text(int start, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(start + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  text(8, 'WAVE');
  text(12, 'fmt ');
  text(36, 'data');
  data.setUint32(4, 36 + samples * 2, Endian.little);
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 16000, Endian.little);
  data.setUint32(28, 32000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  data.setUint32(40, samples * 2, Endian.little);
  if (!silent) {
    for (var i = 0; i < samples; i++) {
      data.setInt16(
        44 + i * 2,
        (6000 * math.sin(2 * math.pi * 500 * i / 16000)).round(),
        Endian.little,
      );
    }
  }
  return data.buffer.asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'app bootstrap classifies locally and chat renders actual output',
    (tester) async {
      debugPrint('[CHAT-PROBE] temporary directory');
      final directory = await (await getTemporaryDirectory()).createTemp(
        'kernel-sound-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final wav = await File('${directory.path}/numerical.wav')
          .writeAsBytes(_wave(silent: false));
      debugPrint('[CHAT-PROBE] bootstrap');
      final overrides = await bootstrapOverrides();
      debugPrint('[CHAT-PROBE] bootstrap ready');
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      expect(
        container.read(insectSoundClassifierProvider),
        isA<NativeInsectSoundClassifier>(),
      );
      debugPrint('[CHAT-PROBE] native classify');
      final result = await container
          .read(orchestratorAgentProvider)
          .execute(
            OrchestratorTask(
              userMessage: '',
              audioMedia: await _TestFilePicker(wav.path).pickAudioFile(),
            ),
          );
      debugPrint('[CHAT-PROBE] classify returned');
      expect(result.sound?.status, InsectSoundStatus.evaluated);
      expect(result.sound?.modelVersion, '0.1.0-experimental');
      expect(
        result.sound?.modelRevision,
        '001425d7fab4b44af5cc571174410f1c78552d0e',
      );
      expect(result.sound?.topLabels, hasLength(5));
      expect(result.sound?.invariantViolations(), isEmpty);
      expect(result.notices, isEmpty);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides,
            mediaPickerServiceProvider.overrideWithValue(
              _TestFilePicker(wav.path),
            ),
          ],
          child: MaterialApp(
            theme: buildKernelTheme(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const KernelChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-attach')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ChatCopy.audio));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-send')));
      // Native work need not schedule a frame while pending. Wait for the
      // actual response, not merely for the first frame to settle.
      for (
        var i = 0;
        i < 100 && find.text(ChatCopy.soundDisclaimer).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.text(ChatCopy.soundDisclaimer), findsOneWidget);
      expect(
        find.text(ChatCopy.soundIdentification(result.sound!)),
        findsOneWidget,
      );
      expect(find.textContaining('0.1.0-experimental'), findsOneWidget);
      expect(find.textContaining('Calibrated Confidence'), findsNothing);
      expect(find.textContaining('Transducer'), findsNothing);

      final silence = await File('${directory.path}/silence.wav')
          .writeAsBytes(_wave(silent: true));
      final rejected = await container
          .read(insectSoundClassifierProvider)
          .classifyWavFile(silence.path);
      expect(rejected.status, InsectSoundStatus.rejected);
      expect(rejected.reasons, ['low_level_or_silence']);
      expect(rejected.label, isNull);
      expect(rejected.topLabels, isEmpty);
    },
  );
}

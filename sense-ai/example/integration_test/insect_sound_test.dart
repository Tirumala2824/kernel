import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sense_ai/sense_ai.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('registered plugin reaches native file and quality gates', (
    tester,
  ) async {
    final classifier = NativeInsectSoundClassifier();
    final missing = await classifier.classifyWavFile('/missing/insect.wav');
    expect(missing.status, InsectSoundStatus.unavailable);
    expect(missing.reasons, ['file_unreadable']);
    // Synthetic silence is solely a quality-gate test, never a species result.
    final data = ByteData(44 + 3200);
    void text(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        data.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    text(8, 'WAVE');
    text(12, 'fmt ');
    text(36, 'data');
    data.setUint32(4, 36 + 3200, Endian.little);
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, 16000, Endian.little);
    data.setUint32(28, 32000, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    data.setUint32(40, 3200, Endian.little);
    final dir = await Directory.systemTemp.createTemp('insect-channel-test-');
    try {
      final wav = await File('${dir.path}/silence.wav')
          .writeAsBytes(data.buffer.asUint8List());
      final result = await classifier.classifyWavFile(wav.path);
      expect(result.status, InsectSoundStatus.rejected);
      expect(result.reasons, ['low_level_or_silence']);
      expect(result.topLabels, isEmpty);
      expect(result.modelVersion, 'none');
      expect(result.sampleRate, 16000);
      expect(result.durationMs, 100);
      expect(result.invariantViolations(), isEmpty);

      // Test-only numerical waveform, NOT an insect recording or accuracy test.
      for (var i = 0; i < 1600; i++) {
        data.setInt16(44 + i * 2, i.isEven ? 5000 : -5000, Endian.little);
      }
      await wav.writeAsBytes(data.buffer.asUint8List());
      final evaluated = await classifier.classifyWavFile(wav.path);
      expect(evaluated.status, InsectSoundStatus.evaluated);
      expect(evaluated.modelVersion, '0.1.0-experimental');
      expect(
        evaluated.modelRevision,
        '001425d7fab4b44af5cc571174410f1c78552d0e',
      );
      expect(evaluated.topLabels, hasLength(5));
      expect(
        evaluated.topLabels.every(
          (e) => e.score.isFinite && e.score >= 0 && e.score <= 1,
        ),
        isTrue,
      );
      expect(evaluated.experimental, isTrue);
      expect(evaluated.invariantViolations(), isEmpty);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}

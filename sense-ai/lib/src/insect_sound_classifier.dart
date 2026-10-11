import 'package:flutter/services.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

/// Local WAV → experimental, closed-set insect sound match. No mic or network.
/// This adapter is independent of the YAMNet listener and grain screening.
class NativeInsectSoundClassifier implements InsectSoundClassifier {
  static const _channel = MethodChannel('com.kernel.sense_ai/insect_sound');

  @override
  Future<InsectSoundResult> classifyWavFile(String path) async {
    try {
      return await _classify(path);
    } on MissingPluginException {
      return const InsectSoundResult(
        status: InsectSoundStatus.unavailable,
        reasons: ['platform_unavailable'],
      );
    } on PlatformException {
      return const InsectSoundResult(
        status: InsectSoundStatus.unavailable,
        reasons: ['native_failure'],
      );
    } catch (_) {
      return const InsectSoundResult(
        status: InsectSoundStatus.unavailable,
        reasons: ['invalid_native_result'],
      );
    }
  }

  Future<InsectSoundResult> _classify(String path) async {
    final data = (await _channel.invokeMapMethod<Object?, Object?>(
      'classifyWavFile',
      {'path': path},
    ))!;
    final result = InsectSoundResult(
      status: InsectSoundStatus.values.byName(data['status'] as String),
      level: InsectIdentificationLevel.values.byName(data['level'] as String),
      label: data['label'] as String?,
      topLabels: (data['topLabels'] as List)
          .map((raw) {
            final label = raw as Map;
            return ScoredLabel(
              label: label['label'] as String,
              score: (label['score'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      // Materialize inside this guarded boundary: a lazy cast can throw later
      // when the UI renders a malformed native reason, outside our fallback.
      reasons: List<String>.unmodifiable(data['reasons'] as List),
      modelId: data['modelId'] as String,
      modelVersion: data['modelVersion'] as String,
      modelRevision: data['modelRevision'] as String?,
      sampleRate: data['sampleRate'] as int?,
      durationMs: data['durationMs'] as int?,
    );
    if (result.invariantViolations().isNotEmpty ||
        result.topLabels.any(
          (label) =>
              !label.score.isFinite || label.score < 0 || label.score > 1,
        )) {
      throw const FormatException('Invalid native insect-sound envelope');
    }
    return result;
  }
}

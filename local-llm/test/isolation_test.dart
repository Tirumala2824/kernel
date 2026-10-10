// Source-level isolation checks (docs/guardrails.md §8). Runs from the
// package root, like `flutter test`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every source file of the plugin that ships, plus the example app.
List<File> _sources() {
  final roots = ['lib', 'android/src/main', 'example/lib', 'pigeons'];
  return [
    for (final root in roots)
      if (Directory(root).existsSync())
        ...Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => RegExp(r'\.(dart|kt|xml|kts)$').hasMatch(f.path)),
  ];
}

void main() {
  test('sources are found', () {
    expect(
      _sources().map((f) => f.path.replaceAll('\\', '/')),
      contains(endsWith('lib/local_llm.dart')),
    );
  });

  test('local_llm never imports or depends on audio_ai', () {
    for (final f in _sources()) {
      expect(f.readAsStringSync(), isNot(contains('audio_ai')), reason: f.path);
    }
    for (final pubspec in ['pubspec.yaml', 'example/pubspec.yaml']) {
      expect(
        File(pubspec).readAsStringSync(),
        isNot(contains('audio_ai')),
        reason: pubspec,
      );
    }
  });

  // Guardrails §8 amendment: multimodal input exists in Pest ID mode only.
  // The native engine configs that may name an encoder or image/audio
  // content are exactly these two files; every other source, including the
  // grain advice config, never does.
  const multimodalAllowed = {'PestIdConfig.kt', 'EmbedConfig.kt'};
  final multimodal = RegExp(
    r'\b(AudioBytes|AudioFile|ImageBytes|ImageFile|audioBackend|visionBackend|'
    r'InputData\.(Image|Audio))\b',
  );

  test('multimodal encoders and content appear only in the Pest ID configs', () {
    for (final f in _sources()) {
      final name = f.uri.pathSegments.last;
      if (multimodalAllowed.contains(name)) continue;
      final hit = multimodal.firstMatch(f.readAsStringSync());
      expect(hit, isNull, reason: '${f.path}: ${hit?.group(0)}');
    }
    for (final name in multimodalAllowed) {
      final file = _sources().where((f) => f.uri.pathSegments.last == name);
      expect(file, hasLength(1), reason: name);
    }
  });

  test('the grain advice path stays text-only', () {
    // Dart: the advice engine and its prompts never touch bytes, media or
    // the Pest ID / embedding bridge calls.
    final adviceDart = RegExp(
      r'Uint8List|ByteData|Float32List|pestGenerate|\.embed\(|NativePestRequest|'
      r'NativeEmbedRequest|media\.dart|dart:io',
    );
    for (final path in [
      'lib/src/local_advice_engine.dart',
      'lib/src/prompts.dart',
    ]) {
      final hit = adviceDart.firstMatch(File(path).readAsStringSync());
      expect(hit, isNull, reason: '$path: ${hit?.group(0)}');
    }
    // Kotlin: the advice engine config builds a text-only Engine.
    final config = File(
      'android/src/main/kotlin/com/kernel/local_llm/LlmConfig.kt',
    ).readAsStringSync();
    expect(config, isNot(contains('maxNumImages')));
    expect(config, isNot(contains('ExperimentalFlags')));
    // The pigeon advice call carries strings only.
    final pigeon = File('pigeons/llm_api.dart').readAsStringSync();
    final generate = RegExp(
      r'NativeGenerateResult generate\(([^)]*)\)',
    ).firstMatch(pigeon);
    expect(generate, isNotNull);
    expect(generate!.group(1), isNot(contains('Uint8List')));
    expect(generate.group(1), isNot(contains('List<')));
  });

  test('no network code and no INTERNET permission', () {
    final forbidden = RegExp(
      r'INTERNET|HttpClient|HttpURLConnection|java\.net\.URL\b|okhttp|'
      r"package:http/|dart:io'.*Socket|WebSocket|DownloadManager",
    );
    for (final f in _sources()) {
      final hit = forbidden.firstMatch(f.readAsStringSync());
      expect(hit, isNull, reason: '${f.path}: ${hit?.group(0)}');
    }
  });

  test('prompts and outputs are never logged', () {
    final logging = RegExp(r'\b(print|debugPrint)\(|\bLog\.[dvi]\(|println\(');
    for (final f in _sources().where((f) => !f.path.contains('example'))) {
      final hit = logging.firstMatch(f.readAsStringSync());
      expect(hit, isNull, reason: '${f.path}: ${hit?.group(0)}');
    }
  });
}

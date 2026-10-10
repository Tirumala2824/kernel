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

  test('no multimodal input or backend is ever used', () {
    final forbidden = RegExp(
      r'AudioBytes|AudioFile|ImageBytes|ImageFile|audioBackend|visionBackend',
    );
    for (final f in _sources()) {
      final text = f.readAsStringSync();
      final hit = forbidden.firstMatch(text);
      expect(hit, isNull, reason: '${f.path}: ${hit?.group(0)}');
    }
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

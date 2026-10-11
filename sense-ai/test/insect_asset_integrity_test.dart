import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pinned insect assets survive Git clean filters byte for byte', () {
    final directory = Directory('android/src/main/assets/insect_sound');
    final files = directory.listSync().whereType<File>().toList();
    expect(files, isNotEmpty);
    for (final file in files) {
      final raw = Process.runSync('git', ['hash-object', '--no-filters', file.path]);
      final clean = Process.runSync('git', [
        '-c', 'core.autocrlf=input', 'hash-object',
        '--path=${file.path}', file.path,
      ]);
      expect(raw.exitCode, 0, reason: '${raw.stderr}');
      expect(clean.exitCode, 0, reason: '${clean.stderr}');
      expect(clean.stdout.toString().trim(), raw.stdout.toString().trim(),
          reason: '${file.path}: a checkout must not change hash-pinned bytes');
    }
  });
}

// Checks every shipped ARB file against the English template: same keys,
// non-empty values, identical placeholders and ICU plural/select shape, and
// the glossary rules that can be checked mechanically (docs/glossary.md).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/l10n/app_localizations.dart';
import 'package:kernel_app/l10n/l10n.dart';

/// en plus the ten Indian languages in docs/decisions-log.md (#25).
const shippedLocales = [
  'en',
  'hi',
  'bn',
  'te',
  'mr',
  'ta',
  'gu',
  'kn',
  'ml',
  'or',
  'pa',
];

const expectedNativeNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'bn': 'বাংলা',
  'te': 'తెలుగు',
  'mr': 'मराठी',
  'ta': 'தமிழ்',
  'gu': 'ગુજરાતી',
  'kn': 'ಕನ್ನಡ',
  'ml': 'മലയാളം',
  'or': 'ଓଡ଼ିଆ',
  'pa': 'ਪੰਜਾਬੀ',
};

Map<String, Object?> readArb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, Object?>;

/// Message keys (no `@` metadata) mapped to their text.
Map<String, String> messagesOf(Map<String, Object?> arb) => {
  for (final e in arb.entries)
    if (!e.key.startsWith('@')) e.key: e.value! as String,
};

/// Order-independent structure of an ICU message: each argument, and for
/// plural/select arguments their case keys and the arguments inside each
/// case. Literal text is ignored, so word order may differ by language.
Set<String> icuShape(String message) => parseIcu(message).shape;

/// Every argument name used anywhere in an ICU message.
Set<String> argumentNames(String message) => parseIcu(message).names;

({Set<String> shape, Set<String> names}) parseIcu(String message) {
  var i = 0;
  final names = <String>{};

  Never fail(String why) =>
      throw FormatException('$why at $i in: $message');

  late Set<String> Function({required bool inCase}) parseText;

  String parseArg() {
    final nameStart = i;
    while (i < message.length && message[i] != ',' && message[i] != '}') {
      i++;
    }
    if (i >= message.length) fail('unterminated argument');
    final name = message.substring(nameStart, i).trim();
    if (!RegExp(r'^[A-Za-z_]\w*$').hasMatch(name)) {
      fail('bad argument name "$name"');
    }
    names.add(name);
    if (message[i] == '}') {
      i++;
      return name;
    }
    i++; // ','
    final typeStart = i;
    while (i < message.length && message[i] != ',') {
      i++;
    }
    if (i >= message.length) fail('unterminated argument type');
    final type = message.substring(typeStart, i).trim();
    if (type != 'plural' && type != 'select') fail('unknown type "$type"');
    i++; // ','
    final cases = <String>[];
    while (true) {
      while (i < message.length && message[i] == ' ') {
        i++;
      }
      if (i >= message.length) fail('unterminated $type');
      if (message[i] == '}') {
        i++;
        break;
      }
      final keyStart = i;
      while (i < message.length && message[i] != '{') {
        i++;
      }
      if (i >= message.length) fail('case without a body');
      final key = message.substring(keyStart, i).trim();
      i++; // '{'
      final inner = parseText(inCase: true).toList()..sort();
      i++; // '}'
      cases.add('$key[${inner.join(',')}]');
    }
    cases.sort();
    return '$name:$type{${cases.join(';')}}';
  }

  parseText = ({required bool inCase}) {
    final shape = <String>{};
    while (i < message.length) {
      final c = message[i];
      if (c == '{') {
        i++;
        shape.add(parseArg());
      } else if (c == '}') {
        if (inCase) return shape;
        fail('unbalanced "}"');
      } else {
        i++;
      }
    }
    if (inCase) fail('unterminated case');
    return shape;
  };

  final shape = parseText(inCase: false);
  return (shape: shape, names: names);
}

/// Placeholder names declared in the template's `@key` metadata.
Set<String> declaredPlaceholders(Map<String, Object?> arb, String key) {
  final meta = arb['@$key'] as Map<String, Object?>?;
  final placeholders = meta?['placeholders'] as Map<String, Object?>?;
  return placeholders?.keys.toSet() ?? const {};
}

void main() {
  final enArb = readArb('en');
  final en = messagesOf(enArb);

  test('the template has the expected size and declares its placeholders', () {
    expect(en.length, greaterThan(500));
    for (final MapEntry(:key, :value) in en.entries) {
      expect(
        argumentNames(value),
        declaredPlaceholders(enArb, key),
        reason: 'app_en.arb $key',
      );
    }
  });

  test('exactly the shipped locales have ARB files and generated classes', () {
    final files = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .map((f) => RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)?.group(1))
        .whereType<String>()
        .toSet();
    expect(files, shippedLocales.toSet());
    expect(
      AppLocalizations.supportedLocales.map((l) => l.toLanguageTag()).toSet(),
      shippedLocales.toSet(),
    );
  });

  test('the language picker has the native name of every shipped locale', () {
    for (final code in shippedLocales) {
      expect(nativeLanguageNames[code], expectedNativeNames[code], reason: code);
    }
  });

  for (final code in shippedLocales.where((c) => c != 'en')) {
    group('app_$code.arb', () {
      late Map<String, Object?> arb;
      late Map<String, String> messages;
      setUpAll(() {
        arb = readArb(code);
        messages = messagesOf(arb);
      });

      test('declares its locale', () {
        expect(arb['@@locale'], code);
      });

      test('has exactly the English keys, none empty', () {
        expect(
          messages.keys.toSet().difference(en.keys.toSet()),
          isEmpty,
          reason: 'keys not in app_en.arb',
        );
        expect(
          en.keys.toSet().difference(messages.keys.toSet()),
          isEmpty,
          reason: 'keys missing from app_$code.arb',
        );
        for (final MapEntry(:key, :value) in messages.entries) {
          expect(value.trim(), isNotEmpty, reason: key);
        }
      });

      test('keeps every placeholder and plural/select structure', () {
        for (final MapEntry(:key, :value) in en.entries) {
          final translated = messages[key];
          if (translated == null) continue; // reported by the key test
          expect(
            icuShape(translated),
            icuShape(value),
            reason: '$key\n  en: $value\n  $code: $translated',
          );
        }
      });

      test('keeps the brand in Latin script', () {
        expect(messages['appTitle'], 'Kernel');
        for (final MapEntry(:key, :value) in en.entries) {
          if (!value.contains('Kernel')) continue;
          expect(messages[key], contains('Kernel'), reason: key);
        }
      });

      test('is actually translated', () {
        // Unit-only strings that are the same in every language.
        const sameEverywhere = {'levelMeterValue'};
        final same = [
          for (final MapEntry(:key, :value) in messages.entries)
            if (!sameEverywhere.contains(key) &&
                value == en[key] &&
                RegExp(r'[A-Za-z]{4,}').hasMatch(
                  value.replaceAll(RegExp(r'\{[^{}]*\}'), '').replaceAll('Kernel', ''),
                ))
              key,
        ];
        expect(same, isEmpty, reason: 'still English: $same');
      });

      test('loads and formats through the generated class', () {
        final l = lookupAppLocalizations(Locale(code));
        expect(l.localeName, code);
        expect(l.appTitle, 'Kernel');
        expect(l.headlineNotEvaluated, messages['headlineNotEvaluated']);
        expect(l.headlineClean, messages['headlineClean']);
        for (final n in [0, 1, 2, 5, 21]) {
          expect(l.sackCount(n), isNotEmpty);
          expect(l.sackCount(n), isNot(contains('{')));
          expect(l.batchPlaceSubtitle('x', n, n), contains('$n'));
          expect(l.scansTodaySummary(n, n), isNotEmpty);
        }
        expect(l.sackCount(7), contains('7'));
        expect(l.registerItemAction('container'), isNot(l.registerItemAction('sack')));
        expect(l.provenanceExperimental('v1'), contains('v1'));
        expect(l.predictedClassLine('X'), contains('X'));
      });
    });
  }
}

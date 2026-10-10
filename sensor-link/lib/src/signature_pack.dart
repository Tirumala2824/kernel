import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:kernel_contracts/kernel_contracts.dart';

import 'protocol.dart';

/// How a rule treats the node's regular-train flag.
enum RegularRule { any, required, forbidden }

/// One literature-derived rule from the pack (docs/sensor-protocol.md section 9).
class SignatureRule {
  const SignatureRule({
    required this.id,
    required this.classes,
    required this.sensors,
    required this.minHz,
    required this.maxHz,
    required this.source,
    this.minDurMs,
    this.maxDurMs,
    this.maxBwHz,
    this.minImpulses,
    this.minRepHz,
    this.maxRepHz,
    this.regular = RegularRule.any,
    this.minHarmonics,
    this.possibleRatePerS,
    this.minWindowS,
  });

  final String id;
  final Set<SensorEventClass> classes;
  final Set<SensorType> sensors;
  final double minHz;
  final double maxHz;
  final double? minDurMs;
  final double? maxDurMs;
  final double? maxBwHz;
  final int? minImpulses;
  final double? minRepHz;
  final double? maxRepHz;
  final RegularRule regular;
  final int? minHarmonics;
  final double? possibleRatePerS;
  final double? minWindowS;
  final String source;
}

enum RateLevel { possible, belowThreshold, notEvaluated }

/// "N events in M minutes" plus, when the rule has one, the rate level.
/// A rate is a signal worth an inspection, never a diagnosis.
class RateAssessment {
  const RateAssessment({
    required this.signatureId,
    required this.count,
    required this.window,
    required this.level,
    required this.packVersion,
  });

  final String signatureId;
  final int count;
  final Duration window;

  /// Null when the signature has no rate rule.
  final RateLevel? level;
  final String packVersion;

  double get perSecond => window.inMilliseconds <= 0 ? 0 : count / (window.inMilliseconds / 1000.0);

  /// English summary for logs/tests; the UI localises its own copy.
  String get summary => rateSummary(count, window);
}

String rateSummary(int count, Duration window) {
  final m = window.inMinutes;
  final ev = count == 1 ? '1 event' : '$count events';
  final min = m == 1 ? '1 minute' : '$m minutes';
  return '$ev in $min';
}

/// Versioned, experimental signature pack. Parsing is closed: unknown keys,
/// a missing or false `pack.experimental`, or an incomplete rule are errors.
class SignaturePack {
  SignaturePack._(this.id, this.version, this.protocol, this.rules);

  final String id;
  final String version;
  final int protocol;
  final List<SignatureRule> rules;

  /// Always true; a pack that claims otherwise is rejected at parse time.
  bool get experimental => true;

  static const assetPath = 'packages/sensor_link/assets/signature_pack_v0_1.properties';

  static Future<SignaturePack> load({AssetBundle? bundle}) async =>
      parse(await (bundle ?? rootBundle).loadString(assetPath));

  static const _packKeys = {'pack.id', 'pack.version', 'pack.protocol', 'pack.experimental', 'pack.signatures'};
  static const _ruleKeys = {
    'classes',
    'sensors',
    'minHz',
    'maxHz',
    'minDurMs',
    'maxDurMs',
    'maxBwHz',
    'minImpulses',
    'minRepHz',
    'maxRepHz',
    'regular',
    'minHarmonics',
    'possibleRatePerS',
    'minWindowS',
    'source',
  };

  static SignaturePack parse(String text) {
    final kv = <String, String>{};
    final lines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) continue;
      final eq = line.indexOf('=');
      if (eq <= 0) throw FormatException('signature pack line ${i + 1}: expected key=value');
      final key = line.substring(0, eq).trim();
      if (kv.containsKey(key)) throw FormatException('signature pack: duplicate key $key');
      kv[key] = line.substring(eq + 1).trim();
    }
    String req(String k) => kv[k] ?? (throw FormatException('signature pack: missing $k'));
    if (req('pack.experimental') != 'true') {
      throw const FormatException('signature pack must be marked pack.experimental=true');
    }
    final protocol = int.tryParse(req('pack.protocol')) ?? (throw const FormatException('pack.protocol'));
    if (protocol != WireLengths.protoMajor) throw FormatException('signature pack protocol $protocol unsupported');
    final ids = req('pack.signatures').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (ids.isEmpty || ids.toSet().length != ids.length) throw const FormatException('pack.signatures');
    for (final k in kv.keys) {
      if (_packKeys.contains(k)) continue;
      final m = RegExp(r'^sig\.([a-z0-9_]+)\.([A-Za-z]+)$').firstMatch(k);
      if (m == null || !ids.contains(m.group(1)) || !_ruleKeys.contains(m.group(2))) {
        throw FormatException('signature pack: unknown key $k');
      }
    }
    final rules = [for (final id in ids) _rule(id, kv)];
    return SignaturePack._(req('pack.id'), req('pack.version'), protocol, List.unmodifiable(rules));
  }

  static SignatureRule _rule(String id, Map<String, String> kv) {
    String? opt(String f) => kv['sig.$id.$f'];
    String req(String f) => opt(f) ?? (throw FormatException('signature $id: missing $f'));
    double num(String f, String v) => double.tryParse(v) ?? (throw FormatException('signature $id: $f is not a number'));
    double? optNum(String f) => opt(f) == null ? null : num(f, opt(f)!);
    int? optInt(String f) => opt(f) == null ? null : (int.tryParse(opt(f)!) ?? (throw FormatException('signature $id: $f')));
    Set<T> list<T extends Enum>(String f, List<T> values) {
      final out = <T>{};
      for (final name in req(f).split(',').map((s) => s.trim())) {
        out.add(values.firstWhere((v) => v.name == name, orElse: () => throw FormatException('signature $id: unknown $f $name')));
      }
      if (out.isEmpty) throw FormatException('signature $id: empty $f');
      return out;
    }

    final minHz = num('minHz', req('minHz'));
    final maxHz = num('maxHz', req('maxHz'));
    if (!(minHz < maxHz)) throw FormatException('signature $id: minHz >= maxHz');
    final regular = switch (opt('regular') ?? 'any') {
      'any' => RegularRule.any,
      'required' => RegularRule.required,
      'forbidden' => RegularRule.forbidden,
      final v => throw FormatException('signature $id: regular=$v'),
    };
    return SignatureRule(
      id: id,
      classes: list('classes', SensorEventClass.values),
      sensors: list('sensors', SensorType.values),
      minHz: minHz,
      maxHz: maxHz,
      minDurMs: optNum('minDurMs'),
      maxDurMs: optNum('maxDurMs'),
      maxBwHz: optNum('maxBwHz'),
      minImpulses: optInt('minImpulses'),
      minRepHz: optNum('minRepHz'),
      maxRepHz: optNum('maxRepHz'),
      regular: regular,
      minHarmonics: optInt('minHarmonics'),
      possibleRatePerS: optNum('possibleRatePerS'),
      minWindowS: optNum('minWindowS'),
      source: req('source'),
    );
  }

  SignatureRule? rule(String id) {
    for (final r in rules) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Best passing rule for [e] from a [sensor] node, or null ("no match" is
  /// never evidence of absence). Score is in 0.5..1 and is not a probability.
  SignatureMatch? match(WireEvent e, SensorType sensor) {
    if (e.eventClass < 0 || e.eventClass >= SensorEventClass.values.length) return null;
    final cls = SensorEventClass.values[e.eventClass];
    SignatureRule? best;
    var bestScore = -1.0;
    for (final r in rules) {
      final s = _score(r, e, cls, sensor);
      if (s != null && s > bestScore) {
        best = r;
        bestScore = s;
      }
    }
    if (best == null) return null;
    return SignatureMatch(signatureId: best.id, packVersion: version, score: bestScore);
  }

  static double _centred(double v, double lo, double hi) {
    final mid = (lo + hi) / 2;
    final half = (hi - lo) / 2;
    if (half <= 0) return 1;
    return 1 - 0.5 * ((v - mid).abs() / half).clamp(0.0, 1.0);
  }

  static double? _score(SignatureRule r, WireEvent e, SensorEventClass cls, SensorType sensor) {
    if (!r.classes.contains(cls) || !r.sensors.contains(sensor)) return null;
    if (e.minHz < r.minHz || e.maxHz > r.maxHz) return null;
    final dur = e.durationMs.toDouble();
    if (r.minDurMs != null && dur < r.minDurMs!) return null;
    if (r.maxDurMs != null && dur > r.maxDurMs!) return null;
    if (r.maxBwHz != null && e.maxHz - e.minHz > r.maxBwHz!) return null;
    if (r.minImpulses != null && e.impulses < r.minImpulses!) return null;
    if (r.minRepHz != null && e.repRateHz < r.minRepHz!) return null;
    if (r.maxRepHz != null && e.repRateHz > r.maxRepHz!) return null;
    if (r.regular == RegularRule.required && !e.regularTrain) return null;
    if (r.regular == RegularRule.forbidden && e.regularTrain) return null;
    if (r.minHarmonics != null && e.harmonics < r.minHarmonics!) return null;
    final terms = <double>[_centred(e.peakHz, r.minHz, r.maxHz)];
    if (r.minDurMs != null && r.maxDurMs != null) terms.add(_centred(dur, r.minDurMs!, r.maxDurMs!));
    if (r.minRepHz != null && r.maxRepHz != null) terms.add(_centred(e.repRateHz, r.minRepHz!, r.maxRepHz!));
    // A satisfied categorical constraint makes the rule more specific.
    if (r.regular != RegularRule.any) terms.add(1);
    return terms.reduce((a, b) => a + b) / terms.length;
  }

  /// Window rate for [signatureId]. [notEvaluated] must be true when any part
  /// of the window was jammed, clipped or surveying.
  RateAssessment assessRate(String signatureId, {required int count, required Duration window, bool notEvaluated = false}) {
    final r = rule(signatureId);
    if (r == null) throw ArgumentError.value(signatureId, 'signatureId', 'not in pack $version');
    RateLevel? level;
    if (r.possibleRatePerS != null) {
      final secs = window.inMilliseconds / 1000.0;
      if (notEvaluated || secs <= 0 || (r.minWindowS != null && secs < r.minWindowS!)) {
        level = RateLevel.notEvaluated;
      } else {
        level = count / secs >= r.possibleRatePerS! ? RateLevel.possible : RateLevel.belowThreshold;
      }
    }
    return RateAssessment(signatureId: signatureId, count: count, window: window, level: level, packVersion: version);
  }
}

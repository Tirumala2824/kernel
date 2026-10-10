// Parsing of constrained Pest ID model output. Pure Dart, no I/O, never
// logs what it parses. Anything that does not fit the expected shape is
// rejected (null / empty), never guessed.
import 'dart:convert';

import 'package:kernel_contracts/kernel_contracts.dart';

/// Longest commonName / list item kept, in characters.
const int maxNameChars = 80;
const int maxItemChars = 200;

/// The model's structured analysis before guarding.
class ParsedAnalysis {
  const ParsedAnalysis({
    required this.cardId,
    required this.commonName,
    required this.group,
    required this.taxonomyPath,
    required this.aiConfidence,
    required this.keyFeatures,
    required this.anomalies,
    required this.insights,
    required this.safety,
    required this.isPest,
  });

  final String cardId;
  final String commonName;
  final PestGroup group;
  final List<String> taxonomyPath;
  final double aiConfidence;
  final List<String> keyFeatures;
  final List<String> anomalies;
  final List<String> insights;
  final SafetyLevel safety;

  /// Null when the model did not say.
  final bool? isPest;

  /// Group shown to the user: "not a pest" only when the model said so.
  PestGroup get effectiveGroup {
    if (isPest == false) return PestGroup.notAPest;
    if (group == PestGroup.notAPest) return PestGroup.unknown;
    return group;
  }
}

/// Decodes the JSON value in [raw], tolerating code fences and text around
/// it. Null when there is none.
Object? decodeModelJson(String raw) {
  var s = raw.trim();
  final fence = RegExp(r'^```[a-zA-Z]*\s*([\s\S]*?)\s*```$').firstMatch(s);
  if (fence != null) s = fence.group(1)!.trim();
  try {
    return jsonDecode(s);
  } on FormatException {
    // Fall through to the first {...} or [...] span.
  }
  final starts = [s.indexOf('{'), s.indexOf('[')].where((i) => i >= 0);
  if (starts.isEmpty) return null;
  final start = starts.reduce((a, b) => a < b ? a : b);
  final end = s[start] == '{' ? s.lastIndexOf('}') : s.lastIndexOf(']');
  if (end <= start) return null;
  try {
    return jsonDecode(s.substring(start, end + 1));
  } on FormatException {
    return null;
  }
}

String _key(String s) => s.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();

T? _byName<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! String) return null;
  final k = _key(raw);
  for (final v in values) {
    if (_key(v.name) == k) return v;
  }
  return null;
}

String _cut(String s, int max) {
  final runes = s.runes.toList();
  return runes.length <= max
      ? s
      : String.fromCharCodes(runes.take(max)).trim();
}

List<String> _strings(Object? raw, int maxItems) {
  if (raw is! List) return const [];
  final out = <String>[];
  for (final item in raw) {
    if (item is! String) continue;
    final t = item.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) continue;
    out.add(_cut(t, maxItemChars));
    if (out.length == maxItems) break;
  }
  return out;
}

/// The analysis object, or null when it is not valid: cardId outside
/// [allowedIds] (which includes "none"), missing name, missing or
/// non-finite confidence. Unknown group -> unknown; unknown safety ->
/// caution (never silently "low").
ParsedAnalysis? parseAnalysis(String raw, Set<String> allowedIds) {
  final json = decodeModelJson(raw);
  if (json is! Map) return null;
  final cardId = json['cardId'];
  if (cardId is! String || !allowedIds.contains(cardId.trim())) return null;
  final name = json['commonName'];
  if (name is! String) return null;
  final commonName = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (commonName.isEmpty || commonName.runes.length > maxNameChars) {
    return null;
  }
  final conf = json['aiConfidence'];
  if (conf is! num || !conf.isFinite) return null;
  final pest = json['isPest'];
  return ParsedAnalysis(
    cardId: cardId.trim(),
    commonName: commonName,
    group: _byName(PestGroup.values, json['group']) ?? PestGroup.unknown,
    taxonomyPath: _strings(json['taxonomyPath'], 6),
    aiConfidence: conf.toDouble().clamp(0.0, 1.0),
    keyFeatures: _strings(json['keyFeatures'], 5),
    anomalies: _strings(json['anomalies'], 5),
    insights: _strings(json['insights'], 5),
    safety: _byName(SafetyLevel.values, json['safety']) ?? SafetyLevel.caution,
    isPest: pest is bool ? pest : null,
  );
}

/// One label-only vote: the id if it is one of [allowed], else null.
String? parseLabel(String raw, Set<String> allowed) {
  final t = raw
      .trim()
      .replaceAll(RegExp(r'''^[\s"'`]+|[\s"'`.,;:!]+$'''), '')
      .trim();
  if (allowed.contains(t)) return t;
  final first = t.split(RegExp(r'\s+')).first;
  return allowed.contains(first) ? first : null;
}

/// The most frequent non-null vote and its count. Ties go to the label
/// that was voted first. (null, 0) when no vote is valid.
(String?, int) majorityVote(List<String?> votes) {
  final counts = <String, int>{};
  for (final v in votes) {
    if (v == null) continue;
    counts[v] = (counts[v] ?? 0) + 1;
  }
  String? best;
  var bestCount = 0;
  for (final v in votes) {
    if (v == null) continue;
    final c = counts[v]!;
    if (c > bestCount) {
      best = v;
      bestCount = c;
    }
  }
  return (best, bestCount);
}

/// Share of [votes] equal to [label] (the reported label). With a strict
/// majority this is majority count / samples.
double agreementFor(List<String?> votes, String label) {
  if (votes.isEmpty) return 0;
  return votes.where((v) => v == label).length / votes.length;
}

/// Gemma `box_2d` output (`[ymin, xmin, ymax, xmax]` on a 0-1000 grid) to
/// normalised boxes (0..1, origin top-left). Items with another shape, a
/// label outside [labels] (when given) or no area are skipped. At most
/// [maxBoxes].
List<NormalizedBox> parseBoxes(
  String raw, {
  Set<String>? labels,
  int maxBoxes = 20,
}) {
  var json = decodeModelJson(raw);
  if (json is Map) json = json['boxes'] ?? json['objects'] ?? [json];
  if (json is! List) return const [];
  final out = <NormalizedBox>[];
  for (final item in json) {
    if (item is! Map) continue;
    final box = item['box_2d'];
    if (box is! List || box.length != 4 || box.any((v) => v is! num)) continue;
    final label = item['label'];
    if (labels != null && (label is! String || !labels.contains(label))) {
      continue;
    }
    final v = [for (final n in box) ((n as num).toDouble() / 1000).clamp(0.0, 1.0)];
    if (v.any((d) => !d.isFinite)) continue;
    final top = v[0] < v[2] ? v[0] : v[2];
    final bottom = v[0] < v[2] ? v[2] : v[0];
    final left = v[1] < v[3] ? v[1] : v[3];
    final right = v[1] < v[3] ? v[3] : v[1];
    if (bottom - top <= 0 || right - left <= 0) continue;
    out.add(
      NormalizedBox(
        left: left,
        top: top,
        width: right - left,
        height: bottom - top,
      ),
    );
    if (out.length == maxBoxes) break;
  }
  return out;
}

/// Sound-classifier labels (e.g. YAMNet) for the prompt and the result:
/// finite scores clamped to 0..1, top first, at most [maxLabels], label text
/// trimmed to 60 characters.
List<ScoredLabel> cleanScoredLabels(List<ScoredLabel> raw, {int maxLabels = 5}) {
  final kept = <ScoredLabel>[];
  for (final l in raw) {
    if (!l.score.isFinite) continue;
    final text = l.label
        .replaceAll(RegExp(r'[\x00-\x1F\x7F{}\[\]<>"`\\|$#*~=]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) continue;
    kept.add(ScoredLabel(label: _cut(text, 60), score: l.score.clamp(0.0, 1.0)));
  }
  kept.sort((a, b) => b.score.compareTo(a.score));
  return kept.take(maxLabels).toList();
}

/// Lowest top-label score for a group hint; below it the hint is unknown.
const double minHintScore = 0.3;

final List<(RegExp, PestGroup)> _groupKeywords = [
  (
    RegExp(
      r'insect|cricket|mosquito|\bbee|wasp|\bfly\b|flies|buzz|cicada|'
      r'grasshopper|cockroach|beetle|termite|moth',
      caseSensitive: false,
    ),
    PestGroup.insect,
  ),
  (
    RegExp(r'rodent|\brats?\b|mouse|mice|squeak|gnaw', caseSensitive: false),
    PestGroup.rodent,
  ),
  (
    RegExp(r'snake|gecko|lizard|reptile|rattle', caseSensitive: false),
    PestGroup.reptile,
  ),
  (
    RegExp(
      r'bird|chirp|tweet|crow|pigeon|\bbats?\b|\bdog|\bcat\b|frog|toad|owl',
      caseSensitive: false,
    ),
    PestGroup.other,
  ),
];

/// Group hint from the sound classifier's top label (a lookup of its class
/// name, not a model of ours). Unknown when the top score is below
/// [minHintScore] or the label is not an animal sound.
PestGroup groupHintFromLabels(List<ScoredLabel> labels) {
  if (labels.isEmpty) return PestGroup.unknown;
  final top = labels.first;
  if (top.score < minHintScore) return PestGroup.unknown;
  for (final (pattern, group) in _groupKeywords) {
    if (pattern.hasMatch(top.label)) return group;
  }
  return PestGroup.unknown;
}

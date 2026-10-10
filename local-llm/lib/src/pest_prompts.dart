// Prompt templates and constrained-output specs for Pest ID mode
// (guardrails §8 amendment, §9). Pure Dart, no I/O.
//
// Free text from the user (room name, question) and from curated cards is
// sanitized before it is embedded. Bump [pestPromptVersion] whenever a
// template, schema or system instruction here changes.
import 'dart:convert';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'prompts.dart' show adviceLanguages, normalizeLanguageTag, percentWords;

/// Version of the templates below; stored as `PestAnalysis.promptVersion`.
const String pestPromptVersion = 'kernel-pest-prompts-v1';

/// The "no card fits" label of the constrained label set.
const String noMatchLabel = 'none';

/// Most card ids offered to the model in one request.
const int maxAllowedCards = 64;

/// Card ids are snake_case and stable (docs/knowledge-cards.md).
final RegExp _cardIdPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');

/// Valid, de-duplicated card ids in their original order, without "none",
/// at most [maxAllowedCards].
List<String> sanitizeCardIds(Iterable<String> ids) {
  final out = <String>[];
  for (final raw in ids) {
    final id = raw.trim();
    if (id == noMatchLabel || !_cardIdPattern.hasMatch(id)) continue;
    if (out.contains(id)) continue;
    out.add(id);
    if (out.length == maxAllowedCards) break;
  }
  return out;
}

bool _isControl(int c) =>
    c <= 0x1F ||
    (c >= 0x7F && c <= 0x9F) ||
    c == 0x2028 ||
    c == 0x2029 ||
    (c >= 0x202A && c <= 0x202E) ||
    (c >= 0x2066 && c <= 0x2069) ||
    c == 0xFEFF;

const String _syntax = '{}[]<>"`\\|\$#*_~=';

/// Free text made safe to embed in a prompt: control and bidi characters
/// removed, template/markup syntax stripped, whitespace collapsed, at most
/// [maxChars] code points.
String sanitizeFreeText(String? raw, int maxChars) {
  if (raw == null) return '';
  final kept = raw.runes.map(
    (c) => _isControl(c) || _syntax.codeUnits.contains(c) ? 0x20 : c,
  );
  var s = String.fromCharCodes(kept).replaceAll(RegExp(r'\s+'), ' ').trim();
  final runes = s.runes.toList();
  if (runes.length > maxChars) {
    s = String.fromCharCodes(runes.take(maxChars)).trim();
  }
  return s;
}

/// Room names stay short ("kitchen", "store room").
String sanitizeRoomHint(String? raw) => sanitizeFreeText(raw, 40);

/// Labels for region proposals: letters, digits, spaces, '-' and '_' only,
/// at most 8 labels of 40 characters.
List<String> sanitizeRegionLabels(Iterable<String> labels) {
  final out = <String>[];
  for (final raw in labels) {
    final l = sanitizeFreeText(raw, 40)
        .replaceAll(RegExp(r"[^\p{L}\p{M}\p{N} _'-]", unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (l.isEmpty || out.contains(l)) continue;
    out.add(l);
    if (out.length == 8) break;
  }
  return out;
}

String _language(String? languageTag) =>
    adviceLanguages[normalizeLanguageTag(languageTag)]!;

String signalWords(SignalKind kind) => switch (kind) {
  SignalKind.motion => 'movement',
  SignalKind.darkSpecks => 'small dark specks (possible droppings)',
  SignalKind.eyeshine => 'eyeshine in the dark',
  SignalKind.embeddingMatch => 'a visual match to a known sign',
  SignalKind.modelBox => 'a detector box',
  SignalKind.soundEvent => 'a sound event',
};

String safetyWords(SafetyLevel s) => switch (s) {
  SafetyLevel.low => 'low',
  SafetyLevel.caution => 'caution',
  SafetyLevel.medicalRisk => 'medical risk (bites, stings or disease)',
  SafetyLevel.venomous => 'venomous',
  SafetyLevel.protectedWildlife => 'protected wildlife',
};

String groupWords(PestGroup g) => switch (g) {
  PestGroup.insect => 'insect',
  PestGroup.arachnid => 'spider, scorpion or mite',
  PestGroup.rodent => 'rodent',
  PestGroup.reptile => 'reptile',
  PestGroup.other => 'other animal',
  PestGroup.notAPest => 'not a pest',
  PestGroup.unknown => 'unknown',
};

/// A rendered Pest ID request: system instruction plus the user turn.
class PestPrompt {
  const PestPrompt({
    required this.systemInstruction,
    required this.prompt,
    required this.languageTag,
  });

  final String systemInstruction;
  final String prompt;
  final String languageTag;
}

/// What the images show, for the analysis and vote prompts.
class PestScene {
  const PestScene({required this.hasContext, this.room = '', this.signal});

  final bool hasContext;
  final String room;
  final SignalKind? signal;

  List<String> lines() => [
    'The first image is the region the user confirmed on the phone.',
    if (hasContext) 'The second image shows the whole scene for context.',
    if (room.isNotEmpty) 'Place: $room.',
    if (signal != null)
      'The phone camera flagged this region for ${signalWords(signal!)}.',
  ];
}

// ---------------------------------------------------------------------------
// Image analysis

String analysisSystemInstruction(String? languageTag) {
  final language = _language(languageTag);
  return [
    'You identify pests and other animals, or their signs, in photos for '
        'Kernel, a phone app used in homes, farms and grain stores in India.',
    'Rules:',
    '- Look only at what is visible. If the image is unclear, use cardId '
        '"$noMatchLabel" and a low aiConfidence.',
    '- cardId must be one of the given card ids, or "$noMatchLabel" when no '
        'card fits.',
    '- aiConfidence is your own estimate from 0 to 1. It is not calibrated. '
        'Never claim certainty.',
    '- keyFeatures: up to 5 short visible features that support the label.',
    '- anomalies: up to 5 things that do not fit the label or make it '
        'uncertain.',
    '- insights: up to 5 short practical observations about what is '
        'visible. Never mention pesticides, rodenticides, poisons, baits, '
        'fumigants, sprays or doses.',
    '- safety: the most serious level that may apply. venomous for venomous '
        'animals, medicalRisk for animals that bite, sting or spread disease, '
        'protectedWildlife for protected wild animals, otherwise caution or '
        'low. When unsure, choose the more serious level.',
    '- isPest: false when the animal is not a household, crop or storage '
        'pest.',
    '- Write commonName, taxonomyPath, keyFeatures, anomalies and insights '
        'in $language, as short plain phrases. taxonomyPath goes from coarse '
        'to fine. No links.',
  ].join('\n');
}

PestPrompt renderAnalysisPrompt(
  PestScene scene,
  List<String> choices, {
  String? languageTag,
}) => PestPrompt(
  systemInstruction: analysisSystemInstruction(languageTag),
  languageTag: normalizeLanguageTag(languageTag),
  prompt: [
    ...scene.lines(),
    'Card ids you may choose: ${choices.join(', ')}.',
    'Return the JSON object for the animal or sign in the first image.',
  ].join('\n'),
);

/// JSON schema for the analysis; cardId is constrained to [choices].
String analysisSchema(List<String> choices) {
  Map<String, Object> list(int max) => {
    'type': 'array',
    'items': {'type': 'string'},
    'maxItems': max,
  };
  return jsonEncode({
    'type': 'object',
    'properties': {
      'cardId': {'type': 'string', 'enum': choices},
      'commonName': {'type': 'string'},
      'group': {
        'type': 'string',
        'enum': [for (final g in PestGroup.values) g.name],
      },
      'taxonomyPath': list(6),
      'aiConfidence': {'type': 'number', 'minimum': 0, 'maximum': 1},
      'keyFeatures': list(5),
      'anomalies': list(5),
      'insights': list(5),
      'safety': {
        'type': 'string',
        'enum': [for (final s in SafetyLevel.values) s.name],
      },
      'isPest': {'type': 'boolean'},
    },
    'required': analysisFields,
    'additionalProperties': false,
  });
}

const List<String> analysisFields = [
  'cardId',
  'commonName',
  'group',
  'taxonomyPath',
  'aiConfidence',
  'keyFeatures',
  'anomalies',
  'insights',
  'safety',
  'isPest',
];

// ---------------------------------------------------------------------------
// Self-consistency votes (label only)

const String labelSystemInstruction =
    'You identify pests and other animals, or their signs, in photos. '
    'Answer with exactly one card id from the list, or "$noMatchLabel" when '
    'no card fits or the image is unclear. Answer with the id only.';

PestPrompt renderLabelPrompt(PestScene scene, List<String> choices) =>
    PestPrompt(
      systemInstruction: labelSystemInstruction,
      languageTag: 'en',
      prompt: [
        ...scene.lines(),
        'Which card id fits the animal or sign in the first image?',
        'Choices: ${choices.join(', ')}.',
      ].join('\n'),
    );

/// Regex for a label-only answer: exactly one of [choices]. Card ids are
/// `[a-z0-9_-]` (see [sanitizeCardIds]), so no escaping is needed.
String labelPattern(List<String> choices) => '(${choices.join('|')})';

// ---------------------------------------------------------------------------
// Sound description (experimental)

String soundSystemInstruction(String? languageTag) {
  final language = _language(languageTag);
  return [
    'You describe short sound clips for the Pest ID mode of Kernel, a phone '
        'app.',
    'Rules:',
    '- Answer only in $language, in one or two short sentences, at most 40 '
        'words. No lists, no links, no emojis.',
    '- Describe what can be heard: pitch, rhythm, loudness and duration.',
    '- You may say which kind of animal it might come from, using words like '
        '"may" or "might". Never claim certainty.',
    '- Never mention pesticides, poisons, baits, sprays or any treatment.',
  ].join('\n');
}

PestPrompt renderSoundPrompt(
  List<ScoredLabel> preFilter, {
  String? languageTag,
}) {
  final labels = preFilter
      .map((l) => '${l.label} (${percentWords(l.score)})')
      .join(', ');
  return PestPrompt(
    systemInstruction: soundSystemInstruction(languageTag),
    languageTag: normalizeLanguageTag(languageTag),
    prompt: [
      if (labels.isNotEmpty)
        'A sound classifier on this phone suggested: $labels. These scores '
            'are not calibrated.',
      'Describe the clip.',
    ].join('\n'),
  );
}

// ---------------------------------------------------------------------------
// Region proposals (box_2d)

const String regionSystemInstruction =
    'You locate objects in images. Output only JSON.';

PestPrompt renderRegionPrompt(List<String> labels) => PestPrompt(
  systemInstruction: regionSystemInstruction,
  languageTag: 'en',
  prompt:
      'Detect every ${labels.join(', ')} in the image. Return a JSON list. '
      'Each item has "box_2d": [ymin, xmin, ymax, xmax] on a 0-1000 grid and '
      '"label". Return [] if there is none.',
);

String regionSchema(List<String> labels) => jsonEncode({
  'type': 'array',
  'maxItems': 10,
  'items': {
    'type': 'object',
    'properties': {
      'box_2d': {
        'type': 'array',
        'items': {'type': 'integer', 'minimum': 0, 'maximum': 1000},
        'minItems': 4,
        'maxItems': 4,
      },
      'label': {'type': 'string', 'enum': labels},
    },
    'required': ['box_2d', 'label'],
    'additionalProperties': false,
  },
});

// ---------------------------------------------------------------------------
// Card-grounded guidance (text only)

/// Cards included in one guidance prompt.
const int maxGuideCards = 3;

/// Facts per list field and characters per fact.
const int maxFactsPerField = 6;
const int maxFactChars = 300;

/// Word budget given to the model; maxOutputTokens is the hard cap.
const int maxGuideWords = 120;

String guideSystemInstruction(String? languageTag) {
  final language = _language(languageTag);
  return [
    'You explain Pest ID results inside Kernel, a phone app used in homes, '
        'farms and grain stores in India.',
    'Rules:',
    '- Answer only in $language. Use plain, everyday words.',
    '- Write at most $maxGuideWords words in 3 to 6 short sentences. No '
        'headings, no bullet points, no links, no emojis.',
    '- Use ONLY the card facts given. Do not add any other advice, numbers, '
        'products or species.',
    '- Never mention or suggest any pesticide, rodenticide, fumigant, poison, '
        'bait, spray, chemical or dose, not even to warn against it.',
    '- Never say the identification is certain, and never say an animal or a '
        'place is safe or harmless. The label is AI-estimated and not '
        'calibrated; say so briefly.',
    '- Follow each card\'s safety and legal text. For venomous or medically '
        'important animals: keep your distance and get medical care for bites '
        'or stings. For protected wildlife: do not harm, capture or kill it, '
        'and contact the State Forest Department or a licensed rescuer.',
    '- If the facts do not answer the question, say so and suggest a '
        'licensed professional.',
  ].join('\n');
}

String _facts(List<String> items) => items
    .map((s) => sanitizeFreeText(s, maxFactChars))
    .where((s) => s.isNotEmpty)
    .take(maxFactsPerField)
    .join('; ');

String cardName(KnowledgeCard card, String languageTag) {
  final name = card.names[languageTag] ?? card.names['en'] ?? card.id;
  final clean = sanitizeFreeText(name, 80);
  return clean.isEmpty ? card.id : clean;
}

List<String> _cardLines(int index, KnowledgeCard c, String languageTag) {
  String? field(String label, List<String> items) {
    final f = _facts(items);
    return f.isEmpty ? null : '- $label: $f';
  }

  final legal = sanitizeFreeText(c.legal, maxFactChars);
  return [
    'Card ${index + 1}: ${cardName(c, languageTag)} (id ${c.id})',
    '- Group: ${groupWords(c.group)}',
    '- Safety level: ${safetyWords(c.safety)}',
    if (sanitizeFreeText(c.summary, maxFactChars).isNotEmpty)
      '- Summary: ${sanitizeFreeText(c.summary, maxFactChars)}',
    ?field('Signs', c.signs),
    ?field('Look-alikes', c.lookAlikes),
    ?field('Health risks', c.healthRisks),
    ?field('Safe steps', c.safeSteps),
    ?field('Call a professional when', c.callProfessionalWhen),
    ?field('First aid', c.firstAid),
    if (legal.isNotEmpty) '- Legal: $legal',
    '- Review status: ${sanitizeFreeText(c.reviewStatus, 40).replaceAll('-', ' ')}',
  ];
}

PestPrompt renderGuidePrompt(PestGuideInput input) {
  final tag = normalizeLanguageTag(input.languageTag);
  final a = input.analysis;
  final agreeing = (a.agreement.clamp(0.0, 1.0) * a.samples).round();
  final question = sanitizeFreeText(input.question, 200);
  final cards = input.cards.take(maxGuideCards).toList();
  return PestPrompt(
    systemInstruction: guideSystemInstruction(tag),
    languageTag: tag,
    prompt: [
      'AI analysis (estimated on this phone, not calibrated):',
      '- Label: ${sanitizeFreeText(a.commonName, 80)} '
          '(card ${a.cardId ?? noMatchLabel})',
      '- The model\'s own confidence: ${percentWords(a.aiConfidence)}',
      '- Agreement between independent runs: $agreeing of ${a.samples}',
      '- Safety level: ${safetyWords(a.safety)}',
      'Card facts:',
      for (var i = 0; i < cards.length; i++) ..._cardLines(i, cards[i], tag),
      question.isEmpty
          ? 'Explain what this may be and what the user can do next.'
          : 'User question: $question',
    ].join('\n'),
  );
}

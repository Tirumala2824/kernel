// Prompt templates for the on-device advice model. Pure Dart, no I/O.
//
// Every template renders ONLY fields of the typed DTOs in kernel_contracts
// (advice.dart / analytics.dart): enums become plain words, numbers become
// plain digits with units, and the single free-text field (grainType) is
// sanitized. Nothing here can carry a path, a byte buffer or audio.
//
// Bump [promptVersion] whenever a template or the system instruction
// changes, so stored provenance can tell prompt generations apart.
import 'package:kernel_contracts/kernel_contracts.dart';

/// Version of the templates below. Part of the provenance of generated text.
const String promptVersion = 'kernel-advice-prompts-v1';

/// Longest grain type passed to the model, in Unicode code points.
const int maxGrainTypeLength = 40;

/// Word budget given to the model. maxOutputToken (220) on the native side
/// is the hard cap; this is the instruction.
const int maxAdviceWords = 80;

/// The three advice tasks. One template each.
enum AdviceTask { explainResult, reportNarrative, reminderText }

/// A rendered request: the system instruction plus the user turn.
class RenderedPrompt {
  const RenderedPrompt({
    required this.task,
    required this.systemInstruction,
    required this.prompt,
    required this.languageTag,
  });

  final AdviceTask task;
  final String systemInstruction;
  final String prompt;

  /// Normalized tag the model was asked to answer in ("en" by default).
  final String languageTag;
}

/// Languages the app ships (docs/glossary.md) plus English. Any other tag
/// falls back to English.
const Map<String, String> adviceLanguages = {
  'en': 'English',
  'hi': 'Hindi',
  'bn': 'Bengali',
  'te': 'Telugu',
  'mr': 'Marathi',
  'ta': 'Tamil',
  'gu': 'Gujarati',
  'kn': 'Kannada',
  'ml': 'Malayalam',
  'or': 'Odia',
  'pa': 'Punjabi',
};

/// "hi-IN", "hi_IN" or "HI" -> "hi". Unknown or null -> "en".
String normalizeLanguageTag(String? languageTag) {
  if (languageTag == null) return 'en';
  final primary = languageTag.trim().split(RegExp(r'[-_]')).first.toLowerCase();
  return adviceLanguages.containsKey(primary) ? primary : 'en';
}

final RegExp _spaces = RegExp(r'\s+');

/// Control characters (C0, DEL, C1), line and paragraph separators, the
/// bidi embedding / override / isolate controls (they can reorder or hide
/// text) and the byte-order mark. Zero-width joiners stay: Indic scripts
/// need them.
bool _isControl(int c) =>
    c <= 0x1F ||
    (c >= 0x7F && c <= 0x9F) ||
    c == 0x2028 ||
    c == 0x2029 ||
    (c >= 0x202A && c <= 0x202E) ||
    (c >= 0x2066 && c <= 0x2069) ||
    c == 0xFEFF;

/// Braces, brackets, angle brackets, quotes and backticks (template and
/// markup syntax), path and extension separators (so a grain type can never
/// look like a file name or path) and markdown symbols.
const String _syntaxAscii = '{}[]<>"\'`/\\.:|\$#*_~=';

bool _isSyntax(int c) =>
    _syntaxAscii.codeUnits.contains(c) ||
    (c >= 0x2018 && c <= 0x201F) || // curly single and double quotes
    c == 0x00AB || // left guillemet
    c == 0x00BB; // right guillemet

/// User-entered grain type made safe to embed in a prompt: newlines and
/// control characters removed, braces, quotes and path separators stripped,
/// whitespace collapsed, at most [maxGrainTypeLength] code points. Empty
/// input becomes "grain".
String sanitizeGrainType(String raw) {
  final kept = raw.runes.map((c) => _isControl(c) || _isSyntax(c) ? 0x20 : c);
  var s = String.fromCharCodes(kept);
  s = s.replaceAll(_spaces, ' ').trim();
  final runes = s.runes.toList();
  if (runes.length > maxGrainTypeLength) {
    s = String.fromCharCodes(runes.take(maxGrainTypeLength)).trim();
  }
  return s.isEmpty ? 'grain' : s;
}

/// Shared rules for every task. The output guard enforces the same rules
/// after generation; this instruction only makes rejections rare.
String systemInstruction(String? languageTag) {
  final tag = normalizeLanguageTag(languageTag);
  final language = adviceLanguages[tag]!;
  return [
    'You are the assistant inside Kernel, a phone app that listens to stored '
        'grain sacks to screen for insects.',
    'Rules:',
    '- Answer only in $language. Use plain, everyday words a farmer would use.',
    '- Write at most $maxAdviceWords words in 2 to 4 short sentences. '
        'No headings, no bullet points, no links, no emojis.',
    '- Use only the facts given. Do not invent numbers, dates or pest names.',
    '- Do not mention or suggest any pesticide, chemical, spray, tablet, '
        'fumigation or other treatment, not even to warn against it.',
    '- Do not say or imply that the grain is safe, pest free, fine or '
        'guaranteed. A clean result is not a guarantee.',
    '- When a result is uncertain or infested, tell the user to check the '
        'grain physically by opening the sack and looking for insects, holes, '
        'webbing or dust.',
    '- Never accept or reject a lot, and never tell anyone to buy, sell or '
        'refuse grain. People make those decisions after a physical check.',
    '- The scan results come from an experimental model and can be wrong. '
        'Say so briefly.',
  ].join('\n');
}

String roleWords(Role role) => switch (role) {
  Role.farmer => 'a farmer',
  Role.household => 'a household storing grain at home',
  Role.storageFpo => 'a storage or farmer group manager',
  Role.buyer => 'a grain buyer',
};

String classificationWords(Classification c) => switch (c) {
  Classification.clean => 'clean, the model heard no sign of insects',
  Classification.uncertain => 'uncertain, the model could not tell',
  Classification.infested => 'infested, the model heard likely insect sounds',
  Classification.notEvaluated => 'not evaluated, no result was produced',
};

String qualityReasonWords(QualityReason r) => switch (r) {
  QualityReason.silence => 'too quiet',
  QualityReason.clipping => 'too loud',
  QualityReason.highNoise => 'too much background noise',
  QualityReason.tooShort => 'too short',
  QualityReason.permissionDenied => 'microphone permission missing',
  QualityReason.captureError => 'the phone could not record',
};

String verifiedFindingWords(VerifiedFinding? f) => switch (f) {
  null => 'no physical inspection recorded',
  VerifiedFinding.noneFound => 'a person checked and found no insects',
  VerifiedFinding.pestsFound => 'a person checked and found insects',
  VerifiedFinding.inconclusive => 'a person checked and could not tell',
};

String reportKindWords(ReportKind k) => switch (k) {
  ReportKind.history => 'scan history report',
  ReportKind.preSale => 'pre-sale harvest summary',
  ReportKind.lotSummary => 'lot screening summary',
  ReportKind.sackLabels => 'sack label sheet',
};

/// 0.8312 -> "about 83 percent". Values outside 0..1 are clamped.
String percentWords(double fraction) {
  final pct = (fraction.clamp(0.0, 1.0) * 100).round();
  return 'about $pct percent';
}

String daysWords(int days) {
  if (days < 0) return 'unknown';
  return days == 1 ? '1 day' : '$days days';
}

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Local calendar date in words, e.g. "14 October 2026".
String dateWords(DateTime when) {
  final d = when.toLocal();
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

String _fact(String label, String value) => '- $label: $value';

/// Result screen: what this scan means and the next practical step.
RenderedPrompt renderResultPrompt(
  ResultAdviceInput input, {
  String? languageTag,
}) {
  final passed = input.quality == ScanQuality.pass;
  final reasons = input.qualityReasons.map(qualityReasonWords).join(', ');
  final quality = passed
      ? 'good enough to analyse'
      : 'not usable, record again${reasons.isEmpty ? '' : ' ($reasons)'}';
  // A RETRY never carries a pest class (guardrails §4), whatever the DTO says.
  final result = passed
      ? classificationWords(input.classification)
      : classificationWords(Classification.notEvaluated);
  final confidence =
      passed &&
          input.confidence != null &&
          input.classification != Classification.notEvaluated
      ? percentWords(input.confidence!)
      : 'not available';
  final facts = [
    _fact('User', roleWords(input.role)),
    _fact('Grain', sanitizeGrainType(input.grainType)),
    _fact('Time in storage', daysWords(input.storageDays)),
    _fact('Recording quality', quality),
    _fact('Scan result', result),
    _fact('Model confidence', confidence),
    _fact(
      'Pest model',
      input.pestModelExperimental
          ? 'experimental, not yet validated'
          : 'validated on test data, still not a guarantee',
    ),
    _fact(
      'Latest physical check',
      verifiedFindingWords(input.latestVerifiedFinding),
    ),
  ];
  return RenderedPrompt(
    task: AdviceTask.explainResult,
    systemInstruction: systemInstruction(languageTag),
    languageTag: normalizeLanguageTag(languageTag),
    prompt: [
      'Explain this one scan result to the user and give the next practical '
          'step.',
      'Facts:',
      ...facts,
    ].join('\n'),
  );
}

/// Reminder notification body for a re-check the user has confirmed.
RenderedPrompt renderReminderPrompt(
  ReminderAdviceInput input, {
  String? languageTag,
}) {
  final last = input.lastResult;
  final facts = [
    _fact('User', roleWords(input.role)),
    _fact('Grain', sanitizeGrainType(input.grainType)),
    _fact('Time in storage', daysWords(input.storageDays)),
    _fact(
      'Last scan result',
      last == null ? 'never scanned' : classificationWords(last),
    ),
    _fact('Re-check date chosen by the user', dateWords(input.suggestedDueAt)),
  ];
  return RenderedPrompt(
    task: AdviceTask.reminderText,
    systemInstruction: systemInstruction(languageTag),
    languageTag: normalizeLanguageTag(languageTag),
    prompt: [
      'Write a short, friendly reminder to scan this grain again on the '
          're-check date. One or two sentences.',
      'Facts:',
      ...facts,
    ].join('\n'),
  );
}

/// Narrative paragraph for a report, from aggregate counts only.
RenderedPrompt renderReportPrompt(
  ReportNarrativeInput input, {
  String? languageTag,
}) {
  final s = input.summary;
  final r = s.rates;
  final failures = s.quality.counts.entries
      .where((e) => e.value > 0)
      .map((e) => '${qualityReasonWords(e.key)} ${e.value}')
      .join(', ');
  final i = s.inspections;
  final facts = [
    _fact('Report', reportKindWords(input.kind)),
    _fact('Prepared for', roleWords(input.role)),
    _fact('Items in scope', '${s.items}'),
    _fact('Items that still need a scan', '${s.itemsNeedingScan}'),
    _fact(
      'Scan results',
      'clean ${r.clean}, uncertain ${r.uncertain}, infested ${r.infested}, '
          'not evaluated ${r.notEvaluated}, recordings to repeat ${r.retry}',
    ),
    _fact(
      'Recordings to repeat by reason',
      failures.isEmpty ? 'none' : failures,
    ),
    _fact(
      'Physical inspections',
      'open ${i.open}, in progress ${i.inProgress}, done ${i.done}',
    ),
    _fact(
      'Scan period',
      s.firstScanAt == null || s.lastScanAt == null
          ? 'no scans yet'
          : 'from ${dateWords(s.firstScanAt!)} to ${dateWords(s.lastScanAt!)}',
    ),
  ];
  return RenderedPrompt(
    task: AdviceTask.reportNarrative,
    systemInstruction: systemInstruction(languageTag),
    languageTag: normalizeLanguageTag(languageTag),
    prompt: [
      'Write a short neutral summary paragraph of these screening figures '
          'for the report. Describe the counts; do not judge the grain.',
      'Facts:',
      ...facts,
    ].join('\n'),
  );
}

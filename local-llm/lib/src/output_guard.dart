// On-device output filter for generated advice. Pure Dart, no I/O, never
// logs the text it checks.
//
// The guard is deliberately conservative: a false rejection only means the
// app shows its static localized copy instead (docs/guardrails.md §8), while
// a false acceptance could put treatment advice, a safety claim or a lot
// decision in front of a user. When in doubt, reject.

/// Why a generated text was dropped.
enum GuardCategory {
  /// Nothing usable was generated.
  empty,

  /// Far beyond the word budget; probably rambling.
  tooLong,

  /// Pesticides, chemicals, fumigation, sprays or any other treatment.
  treatment,

  /// Says or implies the grain is safe, pest free or guaranteed.
  safetyClaim,

  /// Accepts, rejects or approves a lot, or tells someone to buy or sell.
  decision,

  /// Links, domains or e-mail addresses.
  url,

  /// Markdown headings or code fences.
  markup,
}

class GuardResult {
  const GuardResult._(this.category);

  static const GuardResult pass = GuardResult._(null);

  /// Null when the text may be shown.
  final GuardCategory? category;

  bool get allowed => category == null;
}

/// Longest text accepted, in characters. 80 words is roughly 500 Latin
/// characters; Indic scripts need more code units per word.
const int maxGuardedChars = 1500;

/// Checks [text] (already tidied) against every rule. Pure and synchronous.
GuardResult checkOutput(String text) {
  if (text.trim().isEmpty) return const GuardResult._(GuardCategory.empty);
  if (text.length > maxGuardedChars) {
    return const GuardResult._(GuardCategory.tooLong);
  }
  if (_markup.any((r) => r.hasMatch(text))) {
    return const GuardResult._(GuardCategory.markup);
  }

  final n = normalizeForGuard(text);
  if (_url.any((r) => r.hasMatch(n))) {
    return const GuardResult._(GuardCategory.url);
  }
  if (_treatmentLatin.any((r) => r.hasMatch(n)) ||
      _treatmentIndic.any(n.contains)) {
    return const GuardResult._(GuardCategory.treatment);
  }
  final s = _stripAllowedNegations(n);
  if (_safetyLatin.any((r) => r.hasMatch(s)) || _safetyIndic.any(s.contains)) {
    return const GuardResult._(GuardCategory.safetyClaim);
  }
  if (_decisionLatin.any((r) => r.hasMatch(n)) ||
      _decisionIndic.any(n.contains)) {
    return const GuardResult._(GuardCategory.decision);
  }
  return GuardResult.pass;
}

/// Cosmetic cleanup before [checkOutput]: trims, removes markdown emphasis
/// markers (`**`, `__`) and collapses runs of blank lines. It never removes
/// words, so it cannot hide anything from the guard.
String tidyOutput(String raw) {
  var s = raw.replaceAll('**', '').replaceAll('__', '');
  s = s.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}

// ---------------------------------------------------------------------------
// Normalization

/// Precomposed nukta letters -> base letter (the nukta itself is dropped
/// below), so "ज़हर" and "जहर", "छिड़क" and "छिडक" match the same term.
const Map<int, int> _nuktaLetters = {
  // Devanagari
  0x0958: 0x0915, 0x0959: 0x0916, 0x095A: 0x0917, 0x095B: 0x091C,
  0x095C: 0x0921, 0x095D: 0x0922, 0x095E: 0x092B, 0x095F: 0x092F,
  // Bengali
  0x09DC: 0x09A1, 0x09DD: 0x09A2, 0x09DF: 0x09AF,
  // Gurmukhi
  0x0A33: 0x0A32, 0x0A36: 0x0A38, 0x0A59: 0x0A16, 0x0A5A: 0x0A17,
  0x0A5B: 0x0A1C, 0x0A5E: 0x0A2B,
  // Oriya
  0x0B5C: 0x0B21, 0x0B5D: 0x0B22,
};

/// Nukta signs, zero-width (non-)joiners, zero-width space, word joiner,
/// soft hyphen and the byte-order mark: invisible, and able to split a word
/// so it slips past a substring match.
const Set<int> _dropped = {
  0x093C, 0x09BC, 0x0A3C, 0x0ABC, 0x0B3C, 0x0CBC, // nukta
  0x200B, 0x200C, 0x200D, 0x2060, 0x00AD, 0xFEFF,
};

/// Lowercase, invisible characters removed, nukta folded, typographic
/// apostrophes and dashes made ASCII, whitespace collapsed.
String normalizeForGuard(String text) {
  final out = StringBuffer();
  for (final c in text.toLowerCase().runes) {
    if (_dropped.contains(c)) continue;
    final folded = _nuktaLetters[c] ?? c;
    out.writeCharCode(switch (folded) {
      0x2018 || 0x2019 || 0x02BC => 0x27, // ' (curly apostrophes)
      0x2010 || 0x2011 || 0x2012 || 0x2013 || 0x2014 => 0x2D, // -
      _ => folded,
    });
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ');
}

String _fold(String term) => normalizeForGuard(term);

RegExp _w(String pattern) => RegExp(pattern, caseSensitive: false);

// ---------------------------------------------------------------------------
// Markup and links

final List<RegExp> _markup = [
  RegExp(r'^\s{0,3}#{1,6}(\s|$)', multiLine: true), // ATX heading
  RegExp(r'^\s*(=+|-{3,})\s*$', multiLine: true), // setext underline / rule
  RegExp(r'```'),
];

final List<RegExp> _url = [
  _w(r'\b[a-z][a-z0-9+.-]*://'),
  _w(r'\bwww\.'),
  _w(r'\b[a-z0-9-]+\.(com|org|net|in|gov|edu|io|info|co|app|ai|ly|me)\b'),
  _w(r'\S+@\S+\.[a-z]{2,}'),
];

// ---------------------------------------------------------------------------
// Treatment and chemicals

final List<RegExp> _treatmentLatin = [
  _w(r'\bfumig\w*'),
  _w(r'\bphosph(ine|ide|ene)s?\b'),
  _w(
    r'\b(celphos|celfos|selphos|selfos|quickphos|phostoxin|fumitoxin|'
    r'sulphas|sulfas|alphos)\b',
  ),
  _w(r'\w*(pesti|insecti|fungi|larvi|rodenti|acari|herbi|ovi)cid\w*'),
  _w(r'\bspray\w*'),
  _w(r'\bchemicals?\b'),
  _w(r'\bpoison\w*'),
  _w(r'\btoxic\b'),
  _w(
    r'\b(malathion|deltamethrin|dichlorvos|ddvp|permethrin|cypermethrin|'
    r'pirimiphos|chlorpyrifos|spinosad|methoprene|carbaryl|lindane|bhc|ddt)\b',
  ),
  _w(r'\bmethyl bromide\b'),
  _w(r'\b(boric|diatomaceous|neem|camphor|naphthalene|mothballs?)\b'),
  _w(r'\btreat(s|ed|ing|ment|ments)?\b'),
  _w(r'\bkill\w*'),
  _w(r'\btablets?\b'),
  _w(r'\bmedicines?\b'),
  // Common romanized Hindi and other Indic forms.
  _w(r'\bk(i|ee|ii)t(a|aa)?k?n(a|aa)?sh\w*'), // keetnashak, kitnashak, ...
  _w(r'\bjantunash\w*'),
  _w(r'\bpurugu ?mand\w*'),
  _w(r'\bpoochi ?(kolli|marund\w*)'),
  _w(r'\b(dawa|dawai|davai|dava|daway|davaa|dawaa)\b'),
  _w(r'\bch?hi(d|r)ka\w*'), // chhidkav, chidkaav, chhirkav
  _w(r'\b(zahar|jahar|zehar|zeher)\b'),
  _w(r'\b(rasayan|rasayanik|keemiyai)\w*'),
];

/// Matched as substrings of the normalized text (\b does not work for
/// Indic scripts). Folded through [normalizeForGuard] like the input.
final List<String> _treatmentIndic = [
  // Hindi / Marathi (Devanagari)
  'कीटनाशक', 'कीटकनाशक', 'कीड़ेमार', 'कीड़े मार', 'दवा', 'छिड़क', 'स्प्रे',
  'फ्यूमिगेशन', 'फ्यूमिगेट', 'धूमन', 'धूम्रीकरण', 'फॉस्फीन', 'फास्फीन',
  'फॉस्फाइड', 'फास्फाइड', 'सल्फास', 'सेल्फॉस', 'सेलफास', 'सेल्फास',
  'क्विकफॉस', 'रसायन', 'केमिकल', 'ज़हर', 'पेस्टिसाइड',
  'इंसेक्टिसाइड', 'उपचार', 'गोली',
  // Bengali
  'কীটনাশক', 'স্প্রে', 'ওষুধ', 'রাসায়নিক', 'কেমিক্যাল', 'ফিউমিগেশন',
  // Telugu
  'పురుగుమందు', 'పురుగు మందు', 'క్రిమిసంహారక', 'స్ప్రే', 'రసాయన',
  // Tamil
  'பூச்சிக்கொல்லி', 'பூச்சி மருந்து', 'ஸ்ப்ரே', 'ரசாயன', 'இரசாயன',
  // Gujarati
  'જંતુનાશક', 'સ્પ્રે', 'રસાયણ', 'દવા',
  // Kannada
  'ಕೀಟನಾಶಕ', 'ಸ್ಪ್ರೇ', 'ರಾಸಾಯನಿಕ', 'ಔಷಧ',
  // Malayalam
  'കീടനാശിനി', 'സ്പ്രേ', 'രാസവസ്തു', 'രാസ',
  // Odia
  'କୀଟନାଶକ', 'ସ୍ପ୍ରେ', 'ରାସାୟନିକ',
  // Punjabi (Gurmukhi)
  'ਕੀਟਨਾਸ਼ਕ', 'ਸਪਰੇ', 'ਸਪ੍ਰੇ', 'ਦਵਾਈ', 'ਰਸਾਇਣ', 'ਜ਼ਹਿਰ',
].map(_fold).toList();

// ---------------------------------------------------------------------------
// Safety claims

/// Honest negations the system instruction asks for; removed before the
/// safety check so "a clean result is not a guarantee" is allowed.
final List<RegExp> _allowedNegations = [
  _w(r"\b(is |are )?not (a |any )?guarantee(d)?\b"),
  _w(r"\bno guarantee\b"),
  _w(r"\b(cannot|can't|can not|does not|doesn't|do not|don't) guarantee\b"),
  RegExp(_fold('गारंटी नहीं')),
];

String _stripAllowedNegations(String normalized) {
  var s = normalized;
  for (final r in _allowedNegations) {
    s = s.replaceAll(r, ' ');
  }
  return s;
}

final List<RegExp> _safetyLatin = [
  _w(r'\b(safe|safely|safer|safest|safety|unsafe)\b'),
  _w(r'\b(pest|insect|infestation|bug|weevil|worm)s?[ -]?free\b'),
  _w(r'\bfree (of|from) (any )?(pests?|insects?|infestation|bugs?|weevils?)\b'),
  _w(r'\b(uninfested|not infested)\b'),
  // "There are no insects" claims absence; "the scan heard no insect
  // sounds" only describes the model result and stays allowed.
  _w(
    r'\b(there is|there are|there were|has|have|had|contains?) no '
    r'(pests?|insects?|infestation|bugs?|weevils?)\b',
  ),
  _w(
    r'\bno (pests?|insects?|infestation|bugs?|weevils?) (in|inside|present|at all)\b',
  ),
  _w(
    r'\b(grain|grains|sack|sacks|lot|lots|stock|crop|harvest)'
    r"( is| are|'s) (clean|fine|good|healthy|ok|okay|perfect|fit)\b",
  ),
  _w(r'\bguarante\w*'),
  _w(r'\bcertif\w*'),
  _w(r'\b100 ?(%|percent)'),
  _w(r'\bno need (to|for) (an? )?(physical )?(inspect|check|worry)\w*'),
  _w(r'\bnothing to worry\b'),
  _w(r'\b(surakshit|keet ?mukt)\w*'),
];

final List<String> _safetyIndic = [
  // Hindi / Marathi
  'सुरक्षित',
  'सुरक्षा',
  'कीटमुक्त',
  'कीट मुक्त',
  'कीट-मुक्त',
  'कीड़ों से मुक्त',
  'गारंटी',
  // Bengali
  'নিরাপদ', 'পোকামুক্ত',
  // Telugu
  'సురక్షిత',
  // Tamil
  'பாதுகாப்பான',
  // Gujarati
  'સુરક્ષિત',
  // Kannada
  'ಸುರಕ್ಷಿತ',
  // Malayalam
  'സുരക്ഷിത',
  // Odia
  'ସୁରକ୍ଷିତ',
  // Punjabi
  'ਸੁਰੱਖਿਅਤ', 'ਸੁਰਖਿਅਤ',
].map(_fold).toList();

// ---------------------------------------------------------------------------
// Lot decisions

final List<RegExp> _decisionLatin = [
  _w(r'\b(accept|accepts|accepted|accepting|acceptable|acceptance)\b'),
  _w(r'\b(reject|rejects|rejected|rejecting|rejection)\b'),
  _w(r'\b(approve|approves|approved|approving|approval|disapprove\w*)\b'),
  _w(r'\brefus\w*'),
  _w(
    r"\b(do not|don't|dont|should not|shouldn't|should|must|can|cannot|"
    r"can't|ok to|okay to|fine to) (buy|sell|purchase|reject|accept)\b",
  ),
  _w(
    r'\b(sweekar|swikar|svikar|asvikar|asweekar|manzoor|manjoor|namanzoor|'
    r'kharij)\w*',
  ),
];

final List<String> _decisionIndic = [
  'स्वीकार',
  'मंज़ूर',
  'नामंज़ूर',
  'ख़ारिज',
  'रिजेक्ट',
  'एक्सेप्ट',
  'রিজেক্ট',
  'গ্রহণযোগ্য',
  'ਮਨਜ਼ੂਰ',
  'ਰੱਦ',
  'ਸਵੀਕਾਰ',
].map(_fold).toList();

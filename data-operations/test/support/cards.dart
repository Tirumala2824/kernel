// Test-only knowledge card packs. The text is placeholder fixture content,
// not curated guidance; the real pack ships in app-ui/assets/knowledge/.
import 'dart:convert';

Map<String, Object?> testCard(
  String id, {
  Map<String, String>? names,
  String group = 'insect',
  String safety = 'caution',
  String summary = 'Fixture summary.',
  List<String> signs = const [],
  List<String> sources = const ['https://fixture.invalid/source'],
  String? legal,
  String reviewStatus = 'needs-expert-review',
}) => {
  'id': id,
  'names': names ?? {'en': id.replaceAll('_', ' ')},
  'group': group,
  'safety': safety,
  'summary': summary,
  'signs': signs,
  'lookAlikes': const <String>[],
  'healthRisks': const <String>[],
  'safeSteps': const ['Fixture step.'],
  'callProfessionalWhen': const <String>[],
  'firstAid': const <String>[],
  'legal': legal,
  'sources': sources,
  'reviewStatus': reviewStatus,
};

/// Four valid fixture cards.
List<Map<String, Object?>> validTestCards() => [
  testCard(
    'german_cockroach',
    names: {'en': 'German cockroach', 'hi': 'तिलचट्टा'},
    summary: 'Small brown cockroach of kitchens.',
    signs: ['Pepper-like droppings', 'Egg cases (oothecae)'],
  ),
  testCard(
    'house_rat',
    names: {'en': 'House rat'},
    group: 'rodent',
    safety: 'medicalRisk',
    summary: 'Rodent that gnaws stored food.',
    signs: ['Gnaw marks on sacks', 'Greasy rub marks'],
  ),
  testCard(
    'indian_red_scorpion',
    names: {'en': 'Indian red scorpion'},
    group: 'arachnid',
    safety: 'venomous',
    summary: 'Venomous scorpion; keep distance.',
    signs: ['Seen under stones at night'],
  ),
  testCard(
    'bengal_monitor',
    names: {'en': 'Bengal monitor'},
    group: 'reptile',
    safety: 'protectedWildlife',
    summary: 'Large lizard with scales; protected.',
    signs: ['Tail drag marks'],
    legal: 'Fixture legal text.',
  ),
];

String testPack({
  String version = 'kernel-cards-test-0.1',
  List<Map<String, Object?>>? cards,
}) => jsonEncode({'version': version, 'cards': cards ?? validTestCards()});

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/src/pest_parsing.dart';
import 'package:local_llm/src/pest_prompts.dart';

const Set<String> ids = {'german_cockroach', 'rice_weevil', 'none'};

Map<String, Object?> analysisJson({
  Object? cardId = 'german_cockroach',
  Object? commonName = 'German cockroach',
  Object? group = 'insect',
  Object? taxonomyPath = const ['Insect', 'Cockroach', 'German cockroach'],
  Object? aiConfidence = 0.72,
  Object? keyFeatures = const ['Two dark stripes behind the head'],
  Object? anomalies = const <String>[],
  Object? insights = const ['Seen near the sink'],
  Object? safety = 'caution',
  Object? isPest = true,
}) => {
  'cardId': cardId,
  'commonName': commonName,
  'group': group,
  'taxonomyPath': taxonomyPath,
  'aiConfidence': aiConfidence,
  'keyFeatures': keyFeatures,
  'anomalies': anomalies,
  'insights': insights,
  'safety': safety,
  'isPest': isPest,
};

void main() {
  group('analysis JSON', () {
    test('a valid object maps every field', () {
      final a = parseAnalysis(jsonEncode(analysisJson()), ids)!;
      expect(a.cardId, 'german_cockroach');
      expect(a.commonName, 'German cockroach');
      expect(a.group, PestGroup.insect);
      expect(a.effectiveGroup, PestGroup.insect);
      expect(a.taxonomyPath, ['Insect', 'Cockroach', 'German cockroach']);
      expect(a.aiConfidence, 0.72);
      expect(a.keyFeatures, ['Two dark stripes behind the head']);
      expect(a.anomalies, isEmpty);
      expect(a.insights, ['Seen near the sink']);
      expect(a.safety, SafetyLevel.caution);
      expect(a.isPest, isTrue);
    });

    test('code fences and surrounding text are tolerated', () {
      final body = jsonEncode(analysisJson());
      expect(parseAnalysis('```json\n$body\n```', ids), isNotNull);
      expect(parseAnalysis('Here is the result: $body Thanks.', ids), isNotNull);
    });

    test('a card id outside the constrained set is rejected', () {
      expect(parseAnalysis(jsonEncode(analysisJson(cardId: 'cobra')), ids), isNull);
      expect(parseAnalysis(jsonEncode(analysisJson(cardId: 3)), ids), isNull);
      expect(
        parseAnalysis(jsonEncode(analysisJson(cardId: 'none')), ids)!.cardId,
        'none',
      );
    });

    test('missing or unusable required fields are rejected', () {
      for (final bad in [
        analysisJson(commonName: null),
        analysisJson(commonName: '   '),
        analysisJson(commonName: 'x' * 81),
        analysisJson(aiConfidence: null),
        analysisJson(aiConfidence: 'high'),
      ]) {
        expect(parseAnalysis(jsonEncode(bad), ids), isNull, reason: '$bad');
      }
      expect(parseAnalysis('not json at all', ids), isNull);
      expect(parseAnalysis('[1, 2]', ids), isNull);
      expect(parseAnalysis('', ids), isNull);
    });

    test('confidence is clamped to 0..1', () {
      expect(parseAnalysis(jsonEncode(analysisJson(aiConfidence: 7)), ids)!.aiConfidence, 1.0);
      expect(parseAnalysis(jsonEncode(analysisJson(aiConfidence: -1)), ids)!.aiConfidence, 0.0);
    });

    test('enum names are matched loosely; unknown safety is caution', () {
      final a = parseAnalysis(
        jsonEncode(analysisJson(group: 'NOT_A_PEST', safety: 'medical_risk')),
        ids,
      )!;
      expect(a.group, PestGroup.notAPest);
      expect(a.safety, SafetyLevel.medicalRisk);
      final b = parseAnalysis(
        jsonEncode(analysisJson(group: 'dragon', safety: 'fine')),
        ids,
      )!;
      expect(b.group, PestGroup.unknown);
      expect(b.safety, SafetyLevel.caution, reason: 'never silently low');
      expect(
        parseAnalysis(jsonEncode(analysisJson(safety: 'protectedWildlife')), ids)!.safety,
        SafetyLevel.protectedWildlife,
      );
    });

    test('isPest false means not a pest; a contradiction means unknown', () {
      final notPest = parseAnalysis(jsonEncode(analysisJson(isPest: false)), ids)!;
      expect(notPest.effectiveGroup, PestGroup.notAPest);
      final contradiction = parseAnalysis(
        jsonEncode(analysisJson(group: 'notAPest', isPest: true)),
        ids,
      )!;
      expect(contradiction.effectiveGroup, PestGroup.unknown);
      final silent = parseAnalysis(jsonEncode(analysisJson(isPest: 'maybe')), ids)!;
      expect(silent.isPest, isNull);
      expect(silent.effectiveGroup, PestGroup.insect);
    });

    test('lists drop non-strings and blanks and are capped', () {
      final a = parseAnalysis(
        jsonEncode(
          analysisJson(
            keyFeatures: ['a', 3, '', '  b  ', null, 'c', 'd', 'e', 'f', 'g'],
            taxonomyPath: 'Insect',
          ),
        ),
        ids,
      )!;
      expect(a.keyFeatures, ['a', 'b', 'c', 'd', 'e']);
      expect(a.taxonomyPath, isEmpty);
    });

    test('the schema constrains cardId and lists every field', () {
      final schema = jsonDecode(analysisSchema(['rice_weevil'])) as Map;
      final props = schema['properties'] as Map;
      expect((props['cardId'] as Map)['enum'], ['rice_weevil']);
      expect(schema['required'], analysisFields);
      expect(schema['additionalProperties'], isFalse);
      expect((props['group'] as Map)['enum'], contains('notAPest'));
      expect((props['safety'] as Map)['enum'], contains('protectedWildlife'));
      expect((props['aiConfidence'] as Map)['maximum'], 1);
    });
  });

  group('self-consistency', () {
    test('labels must be in the constrained set', () {
      expect(parseLabel('rice_weevil', ids), 'rice_weevil');
      expect(parseLabel(' "rice_weevil". ', ids), 'rice_weevil');
      expect(parseLabel('none', ids), 'none');
      expect(parseLabel('rice_weevil because of the snout', ids), 'rice_weevil');
      expect(parseLabel('cobra', ids), isNull);
      expect(parseLabel('', ids), isNull);
    });

    test('majority vote and agreement', () {
      expect(majorityVote(['a', 'a', 'b']), ('a', 2));
      expect(majorityVote(['b', 'a', 'a']), ('a', 2));
      expect(majorityVote(['a', 'a', 'a']), ('a', 3));
      // A three-way split: the first vote wins the tie, with count 1.
      expect(majorityVote(['c', 'b', 'a']), ('c', 1));
      expect(majorityVote([null, 'b', null]), ('b', 1));
      expect(majorityVote([null, null, null]), (null, 0));

      expect(agreementFor(['a', 'a', 'b'], 'a'), closeTo(2 / 3, 1e-9));
      expect(agreementFor(['a', 'a', 'a'], 'a'), 1.0);
      expect(agreementFor(['c', 'b', 'a'], 'd'), 0.0);
      expect(agreementFor([], 'a'), 0.0);
    });

    test('the vote pattern is an alternation of the choices', () {
      expect(labelPattern(['a_b', 'c', 'none']), '(a_b|c|none)');
      expect(
        sanitizeCardIds([
          'german_cockroach',
          'German Cockroach',
          'rice_weevil',
          'german_cockroach',
          'none',
          '../etc',
          'a|b',
          '',
        ]),
        ['german_cockroach', 'rice_weevil'],
      );
    });
  });

  group('box_2d', () {
    test('Gemma boxes map to normalised left/top/width/height', () {
      final boxes = parseBoxes(
        '[{"box_2d": [100, 200, 500, 600], "label": "insect"}]',
        labels: {'insect'},
      );
      expect(boxes, hasLength(1));
      final b = boxes.single;
      expect(b.top, closeTo(0.1, 1e-9));
      expect(b.left, closeTo(0.2, 1e-9));
      expect(b.height, closeTo(0.4, 1e-9));
      expect(b.width, closeTo(0.4, 1e-9));
    });

    test('reversed corners are ordered, out-of-range values clamped', () {
      final b = parseBoxes('[{"box_2d": [900, 800, 100, -50], "label": "x"}]').single;
      expect(b.top, closeTo(0.1, 1e-9));
      expect(b.left, 0.0);
      expect(b.height, closeTo(0.8, 1e-9));
      expect(b.width, closeTo(0.8, 1e-9));
      final clamped = parseBoxes('[{"box_2d": [0, 0, 1200, 1000], "label": "x"}]').single;
      expect(clamped.height, 1.0);
    });

    test('degenerate, malformed and off-label items are skipped', () {
      final boxes = parseBoxes(
        jsonEncode([
          {'box_2d': [100, 100, 100, 400], 'label': 'insect'},
          {'box_2d': [1, 2, 3], 'label': 'insect'},
          {'box_2d': ['a', 2, 3, 4], 'label': 'insect'},
          {'box': [1, 2, 3, 4], 'label': 'insect'},
          {'box_2d': [10, 10, 50, 50], 'label': 'cat'},
          'text',
          {'box_2d': [10, 10, 50, 50], 'label': 'insect'},
        ]),
        labels: {'insect'},
      );
      expect(boxes, hasLength(1));
    });

    test('wrapped objects, fences and garbage', () {
      expect(
        parseBoxes('{"boxes": [{"box_2d": [0, 0, 500, 500], "label": "rat"}]}'),
        hasLength(1),
      );
      expect(
        parseBoxes('```json\n[{"box_2d": [0, 0, 500, 500], "label": "rat"}]\n```'),
        hasLength(1),
      );
      expect(parseBoxes('no boxes here'), isEmpty);
      expect(parseBoxes('[]'), isEmpty);
      final many = jsonEncode([
        for (var i = 0; i < 30; i++) {'box_2d': [0, 0, 10, 10], 'label': 'x'},
      ]);
      expect(parseBoxes(many), hasLength(20));
    });
  });

  group('sound labels', () {
    test('cleaned, sorted top first and capped', () {
      final l = cleanScoredLabels([
        const ScoredLabel(label: 'Speech', score: 0.1),
        const ScoredLabel(label: 'Insect {buzz}', score: 0.62),
        const ScoredLabel(label: '', score: 0.9),
        const ScoredLabel(label: 'Cricket', score: double.nan),
        const ScoredLabel(label: 'Mosquito', score: 1.7),
      ]);
      expect(l.map((e) => e.label), ['Mosquito', 'Insect buzz', 'Speech']);
      expect(l.first.score, 1.0);
    });

    test('group hint comes from the top classifier label only', () {
      PestGroup hint(String label, double score) =>
          groupHintFromLabels([ScoredLabel(label: label, score: score)]);
      expect(hint('Insect', 0.6), PestGroup.insect);
      expect(hint('Mosquito', 0.4), PestGroup.insect);
      expect(hint('Rodents, rats, mice', 0.5), PestGroup.rodent);
      expect(hint('Snake', 0.5), PestGroup.reptile);
      expect(hint('Bird vocalization', 0.5), PestGroup.other);
      expect(hint('Speech', 0.9), PestGroup.unknown);
      expect(hint('Insect', 0.2), PestGroup.unknown, reason: 'too weak');
      expect(groupHintFromLabels(const []), PestGroup.unknown);
    });
  });
}

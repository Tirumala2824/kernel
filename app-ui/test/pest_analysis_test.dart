// Pest ID analysis screen: the "not calibrated" confidence, agreement,
// safety banners per level, the knowledge card, the null fallback, the
// streamed explanation, the user's card pick and the distance gate.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';
import 'support/test_pest.dart';

PestEnv _env({
  PestAnalysis? analysis,
  SafetyLevel cardSafety = SafetyLevel.caution,
}) {
  final env = PestEnv(role: Role.household);
  env.knowledge.cards = [
    testCard('test_cockroach', name: 'Test cockroach', safety: cardSafety),
    testCard('test_rat', name: 'Test rat', group: PestGroup.rodent),
  ];
  env.analyzer.analysis = analysis;
  return env;
}

/// Opens the analysis screen the way a user does: confirm a live box.
Future<void> _openAnalysis(
  WidgetTester tester,
  PestEnv env, {
  SignalCandidate? candidate,
}) async {
  await pumpKernelApp(tester, env, location: Routes.pestCamera);
  final c = candidate ?? testCandidate('c1');
  env.sense.candidates.add([c]);
  await tester.pumpAndSettle();
  await tapVisible(tester, find.byKey(Key('pest-box-${c.id}')));
}

void main() {
  testWidgets('shows the AI label, taxonomy, "not calibrated" confidence and '
      'agreement, with model provenance', (tester) async {
    final env = _env(analysis: testAnalysis());
    await _openAnalysis(tester, env);

    expect(find.text(en.pestAiLabel), findsOneWidget);
    expect(find.text('Test cockroach'), findsWidgets);
    expect(find.byKey(const Key('pest-taxonomy')), findsOneWidget);
    expect(find.text('Insect'), findsWidgets);
    expect(find.text(en.pestConfidenceLabel), findsOneWidget);
    expect(en.pestConfidenceLabel, contains('not calibrated'));
    expect(find.text(en.pestConfidenceValue(62)), findsOneWidget);
    expect(find.text(en.pestAgreement(2, 3)), findsOneWidget);
    expect(en.pestAgreement(2, 3), 'Agreement 2 of 3 runs');
    expect(find.text('Flat oval body'), findsOneWidget);
    expect(find.text('Seen in daylight'), findsOneWidget);
    expect(find.text('Often near warm, damp places'), findsOneWidget);
    expect(
      find.text(en.pestModelLine('gemma-test-vision-1', 'pest-prompt-1')),
      findsOneWidget,
    );
    expect(find.text(en.experimentalBadge), findsWidgets);
    // The knowledge card for the AI label.
    expect(
      find.byKey(const Key('knowledge-card-test_cockroach')),
      findsOneWidget,
    );
    expect(find.text(en.pestCardSafeSteps), findsOneWidget);
    expect(find.text(en.pestCardCallPro), findsOneWidget);
    expect(find.text(en.pestCardSources), findsOneWidget);
    expect(find.text(en.pestCardNeedsReview), findsOneWidget);
    // No buyer decision or treatment action exists.
    expect(
      find.textContaining(
        RegExp('fumigat|pesticide|accept|reject', caseSensitive: false),
      ),
      findsNothing,
    );
  });

  for (final (level, title, body) in [
    (
      SafetyLevel.venomous,
      en.pestSafetyVenomousTitle,
      en.pestSafetyDistanceBody,
    ),
    (
      SafetyLevel.medicalRisk,
      en.pestSafetyMedicalTitle,
      en.pestSafetyDistanceBody,
    ),
    (
      SafetyLevel.protectedWildlife,
      en.pestSafetyProtectedTitle,
      en.pestSafetyProtectedBody,
    ),
    (SafetyLevel.caution, en.pestSafetyCautionTitle, en.pestSafetyCautionBody),
  ]) {
    testWidgets('safety banner for ${level.name}', (tester) async {
      final env = _env(
        analysis: testAnalysis(safety: level),
        cardSafety: SafetyLevel.low,
      );
      await _openAnalysis(tester, env);

      expect(find.byKey(Key('pest-safety-${level.name}')), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.text(body), findsOneWidget);
    });
  }

  test('safety copy follows the glossary wording', () {
    expect(en.pestSafetyDistanceBody, contains('medical care'));
    expect(en.pestSafetyDistanceBody, contains('home remedies'));
    expect(en.pestSafetyProtectedBody, contains('Forest Department'));
    expect(
      en.pestSafetyProtectedBody,
      contains('Do not harm, capture or kill'),
    );
  });

  testWidgets('low safety shows no banner; the card level wins when higher', (
    tester,
  ) async {
    final env = _env(
      analysis: testAnalysis(safety: SafetyLevel.low),
      cardSafety: SafetyLevel.venomous,
    );
    await _openAnalysis(tester, env);

    expect(find.byKey(const Key('pest-safety-low')), findsNothing);
    expect(find.byKey(const Key('pest-safety-venomous')), findsOneWidget);
  });

  testWidgets('no match is never presented as proof of absence', (
    tester,
  ) async {
    final env = _env(
      analysis: testAnalysis(cardId: null, commonName: 'Unclear'),
    );
    await _openAnalysis(tester, env);

    expect(find.byKey(const Key('pest-not-proof')), findsOneWidget);
    expect(find.text(en.pestNoMatch), findsOneWidget);
    expect(en.pestNoMatch, contains('Inspect physically'));
  });

  testWidgets('null analysis falls back to the top knowledge card for the '
      'hint, labelled "AI analysis unavailable"', (tester) async {
    final env = _env(analysis: null);
    await _openAnalysis(
      tester,
      env,
      candidate: testCandidate(
        'c9',
        kind: SignalKind.embeddingMatch,
        hint: 'test_rat',
      ),
    );

    expect(find.text(en.pestAnalysisUnavailable), findsOneWidget);
    expect(find.byKey(const Key('pest-ai-analysis')), findsNothing);
    expect(env.knowledge.queries, ['test rat']);
    expect(find.byKey(const Key('knowledge-card-test_rat')), findsOneWidget);
    // No confidence or explanation without an AI analysis.
    expect(find.text(en.pestConfidenceLabel), findsNothing);
    expect(find.byKey(const Key('pest-explain')), findsNothing);
  });

  testWidgets('Explain streams card-grounded text with provenance', (
    tester,
  ) async {
    final env = _env(analysis: testAnalysis());
    final controller = StreamController<AdviceText>();
    env.analyzer.guideController = controller;
    await _openAnalysis(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-explain')));
    expect(find.text(en.pestExplainTitle), findsOneWidget);
    final input = env.analyzer.guideInputs.single;
    expect(input.cards.single.id, 'test_cockroach');
    expect(input.analysis.cardId, 'test_cockroach');

    for (final event in adviceEvents(['Keep food sealed.', 'Seal gaps.'])) {
      controller.add(event);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Keep food sealed. Seal gaps.'), findsOneWidget);
    expect(find.byKey(const Key('advice-provenance')), findsOneWidget);
    unawaited(controller.close());
  });

  testWidgets('an empty guide stream falls back to the static note', (
    tester,
  ) async {
    final env = _env(analysis: testAnalysis());
    await _openAnalysis(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-explain')));

    expect(find.byKey(const Key('pest-explain-fallback')), findsOneWidget);
  });

  testWidgets('"Pick a different card" sets the user pick, AI label kept', (
    tester,
  ) async {
    final env = _env(analysis: testAnalysis());
    await _openAnalysis(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-pick-card')));
    await tapVisible(tester, find.byKey(const Key('pest-pick-test_rat')));

    expect(find.byKey(const Key('knowledge-card-test_rat')), findsOneWidget);
    expect(find.byKey(const Key('pest-card-user-pick')), findsOneWidget);
    // The AI analysis still shows its own label.
    expect(find.byKey(const Key('pest-common-name')), findsOneWidget);
    expect(find.text('Test cockroach'), findsWidgets);

    await tapVisible(tester, find.byKey(const Key('pest-save')));
    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    final draft = env.sightings.drafts.single;
    expect(draft.userCardId, 'test_rat');
    expect(draft.analysis?.cardId, 'test_cockroach');
    expect(draft.userValidated, isTrue);
  });

  testWidgets('"Measure distance" only when the phone supports it', (
    tester,
  ) async {
    final env = _env(analysis: testAnalysis());
    await _openAnalysis(tester, env);
    expect(find.byKey(const Key('pest-measure')), findsNothing);
  });

  testWidgets('measure shows "Distance not available" with the reason', (
    tester,
  ) async {
    final env = _env(analysis: testAnalysis());
    env.sense.capability = const DistanceCapability(
      arcoreDepth: false,
      focusDistance: true,
    );
    await _openAnalysis(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-measure')));

    expect(env.sense.measureTargets, hasLength(1));
    expect(find.text(en.pestDistanceUnavailable), findsOneWidget);
    expect(find.text(en.pestDistanceReason('test: too far')), findsOneWidget);
  });

  testWidgets('a reliable measurement is shown with its method', (
    tester,
  ) async {
    final env = _env(analysis: testAnalysis());
    env.sense
      ..capability = const DistanceCapability(
        arcoreDepth: true,
        focusDistance: false,
      )
      ..measurement = const DistanceEstimate(
        method: DistanceMethod.arcoreDepth,
        meters: 0.42,
        lowMeters: 0.38,
        highMeters: 0.47,
        confidence: 0.8,
      );
    await _openAnalysis(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-measure')));

    expect(
      find.text(
        en.pestDistanceValue(
          '0.42',
          '0.38',
          '0.47',
          en.pestDistanceMethodDepth,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Discard drops media and saves nothing', (tester) async {
    final env = _env(analysis: testAnalysis());
    await _openAnalysis(tester, env);

    await tapVisible(tester, find.byKey(const Key('pest-discard')));

    expect(env.sense.discardCalls, greaterThanOrEqualTo(1));
    expect(env.sightings.all, isEmpty);
  });
}

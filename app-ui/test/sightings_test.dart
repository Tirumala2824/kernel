// Sightings list and detail: empty state, three separate records (AI
// analysis, the user's confirmation, the human verified finding) and the
// set-once verified finding.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/copy.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_pest.dart';

void main() {
  testWidgets('empty list has one next action into Pest ID', (tester) async {
    final env = PestEnv(role: Role.household);
    await pumpKernelApp(tester, env, location: Routes.sightings);

    expect(find.byKey(const Key('sightings-empty')), findsOneWidget);
    expect(find.text(en.pestSightingsEmpty), findsOneWidget);
    await tapVisible(tester, find.text(en.pestHeroAction));
    expect(find.byKey(const Key('pest-hub')), findsOneWidget);
  });

  testWidgets('lists the role\'s sightings from the repository', (
    tester,
  ) async {
    final env = PestEnv(role: Role.household);
    env.knowledge.cards = [testCard('test_rat', name: 'Test rat')];
    await env.sightings.add(analysis: testAnalysis(commonName: 'AI cockroach'));
    await env.sightings.add(userCardId: 'test_rat');
    await env.sightings.add(role: Role.farmer);
    await pumpKernelApp(tester, env, location: Routes.sightings);

    expect(find.text('AI cockroach'), findsOneWidget);
    expect(find.text('Test rat'), findsOneWidget);
    expect(find.text(en.pestCardYourPick), findsOneWidget);
    expect(find.text(en.pestAiEstimated), findsOneWidget);
    expect(find.text(en.pestNoFindingYet), findsNWidgets(2));
  });

  testWidgets('detail keeps AI analysis, confirmation and verified finding '
      'separate; the finding is set once', (tester) async {
    final env = PestEnv(role: Role.household);
    env.knowledge.cards = [
      testCard('test_cockroach', name: 'Test cockroach'),
      testCard('test_rat', name: 'Test rat'),
    ];
    final s = await env.sightings.add(userCardId: 'test_rat');
    await pumpKernelApp(tester, env, location: Routes.sighting(s.id));

    expect(find.byKey(const Key('pest-ai-analysis')), findsOneWidget);
    expect(find.text(en.pestDetailAiNote), findsOneWidget);
    expect(find.byKey(const Key('sighting-validation')), findsOneWidget);
    expect(find.text(en.pestDetailYourPick('Test rat')), findsOneWidget);
    expect(find.byKey(const Key('sighting-finding')), findsOneWidget);
    // The AI label is still the AI's own.
    expect(find.byKey(const Key('pest-common-name')), findsOneWidget);
    expect(find.text('Test cockroach'), findsWidgets);

    final save = find.byKey(const Key('sighting-finding-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tapVisible(
      tester,
      find.byKey(const Key('sighting-finding-pestsFound')),
    );
    await tapVisible(tester, save);
    await tapVisible(tester, find.byKey(const Key('confirm-ok')));

    expect(
      (await env.sightings.get(s.id))?.verifiedFinding,
      VerifiedFinding.pestsFound,
    );
    expect(find.byKey(const Key('sighting-finding-value')), findsOneWidget);
    expect(find.text(VerifiedFinding.pestsFound.label(en)), findsWidgets);
    expect(save, findsNothing);
    // The AI analysis itself is unchanged.
    expect((await env.sightings.get(s.id))?.analysis?.cardId, 'test_cockroach');
  });

  testWidgets('a pinned sighting links to the map', (tester) async {
    final env = PestEnv(role: Role.household);
    final s = await env.sightings.add(
      latitude: 12.97161,
      longitude: 77.59456,
      accuracyMeters: 9,
    );
    await pumpKernelApp(tester, env, location: Routes.sighting(s.id));

    expect(
      find.text(en.pestDetailPin('12.97161', '77.59456', 9)),
      findsOneWidget,
    );
    await tapVisible(tester, find.byKey(const Key('sighting-show-map')));
    expect(find.text(en.mapTitle), findsWidgets);
  });

  testWidgets('an unknown id says so', (tester) async {
    final env = PestEnv(role: Role.household);
    await pumpKernelApp(tester, env, location: Routes.sighting('missing'));
    expect(find.text(en.pestNotFound), findsOneWidget);
  });
}

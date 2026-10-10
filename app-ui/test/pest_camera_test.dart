// Pest ID camera flow with a scripted sense engine: live boxes labelled by
// kind, torch, capture with tiles ranked by embedding hint, confirming a
// tile or a box, and "Not a pest / nothing here".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_pest.dart';

Future<PestEnv> _env() async {
  final env = PestEnv(role: Role.household);
  env.knowledge.cards = [
    testCard('test_cockroach', name: 'Test cockroach'),
    testCard('test_rat', name: 'Test rat', group: PestGroup.rodent),
  ];
  return env;
}

void main() {
  testWidgets('live boxes are labelled by kind over the preview', (
    tester,
  ) async {
    final env = await _env();
    await pumpKernelApp(tester, env, location: Routes.pestCamera);

    expect(find.byKey(const Key('camera-preview')), findsOneWidget);
    expect(find.text(en.pestCandidatesNone), findsOneWidget);

    env.sense.candidates.add([
      testCandidate('c1', kind: SignalKind.motion),
      testCandidate('c2', kind: SignalKind.darkSpecks),
      testCandidate('c3', kind: SignalKind.eyeshine),
    ]);
    await tester.pumpAndSettle();

    expect(find.text(en.pestKindMotion), findsOneWidget);
    expect(find.text(en.pestKindSpecks), findsOneWidget);
    expect(find.text(en.pestKindEyeshine), findsOneWidget);
    expect(find.text(en.pestCandidatesCount(3)), findsOneWidget);
    // Nothing is analysed before the user confirms a signal.
    expect(env.analyzer.imageRequests, isEmpty);
  });

  testWidgets('the torch slider drives setTorch', (tester) async {
    final env = await _env();
    await pumpKernelApp(tester, env, location: Routes.pestCamera);

    final slider = find.byKey(const Key('pest-torch'));
    await tester.ensureVisible(slider);
    await tester.tapAt(tester.getTopRight(slider) - const Offset(30, -20));
    await tester.pumpAndSettle();

    expect(env.sense.torchLevels, isNotEmpty);
    expect(env.sense.torchLevels.last, greaterThan(0.5));
  });

  testWidgets('capture shows tiles ranked by embedding hint; a tap confirms '
      'and analyses that tile', (tester) async {
    final env = await _env();
    await pumpKernelApp(tester, env, location: Routes.pestCamera);
    final candidates = [
      testCandidate('plain', kind: SignalKind.motion, score: 0.9),
      testCandidate(
        'hinted',
        kind: SignalKind.embeddingMatch,
        score: 0.4,
        hint: 'test_rat',
      ),
    ];
    env.sense.candidates.add(candidates);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('pest-capture')));

    expect(env.sense.captureCalls.single.map((c) => c.id), ['plain', 'hinted']);
    expect(find.byKey(const Key('pest-tiles')), findsOneWidget);
    expect(find.text(en.pestTileHint('Test rat')), findsOneWidget);
    // The hinted tile is ranked first.
    final hinted = tester.getTopLeft(find.byKey(const Key('pest-tile-hinted')));
    final plain = tester.getTopLeft(find.byKey(const Key('pest-tile-plain')));
    expect(
      hinted.dy < plain.dy || (hinted.dy == plain.dy && hinted.dx < plain.dx),
      isTrue,
    );

    await tapVisible(tester, find.byKey(const Key('pest-tile-hinted')));

    final request = env.analyzer.imageRequests.single;
    expect(request.candidate?.id, 'hinted');
    expect(request.crop, testPng);
    expect(request.allowedCardIds, ['test_cockroach', 'test_rat']);
    expect(find.text(en.pestAnalysisTitle), findsWidgets);
  });

  testWidgets('tapping a live box confirms it', (tester) async {
    final env = await _env();
    await pumpKernelApp(tester, env, location: Routes.pestCamera);
    env.sense.candidates.add([
      testCandidate('box1', kind: SignalKind.eyeshine),
    ]);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('pest-box-box1')));

    expect(env.sense.captureCalls.single.single.id, 'box1');
    expect(env.analyzer.imageRequests.single.candidate?.id, 'box1');
    expect(find.byKey(const Key('pest-ai-analysis')), findsOneWidget);
  });

  testWidgets('"Not a pest / nothing here" discards media and saves nothing', (
    tester,
  ) async {
    final env = await _env();
    await pumpKernelApp(tester, env, location: Routes.pestCamera);

    await tapVisible(tester, find.byKey(const Key('pest-nothing-here')));

    expect(env.sense.discardCalls, greaterThanOrEqualTo(1));
    expect(env.sightings.all, isEmpty);
    expect(env.analyzer.imageRequests, isEmpty);
    expect(find.text(en.pestNothingHereDone), findsOneWidget);
  });

  testWidgets('a failed capture says so and keeps the preview', (tester) async {
    final env = await _env();
    env.sense.failCapture = true;
    await pumpKernelApp(tester, env, location: Routes.pestCamera);

    await tapVisible(tester, find.byKey(const Key('pest-capture')));

    expect(find.text(en.pestCaptureFailed), findsOneWidget);
    expect(find.byKey(const Key('camera-preview')), findsOneWidget);
  });

  testWidgets('camera denied explains and offers settings', (tester) async {
    final env = await _env();
    env.permissions.camera = PermissionAccess.denied;
    await pumpKernelApp(tester, env, location: Routes.pestCamera);

    expect(find.byKey(const Key('pest-camera-denied')), findsOneWidget);
    expect(find.byKey(const Key('camera-preview')), findsNothing);
    await tapVisible(tester, find.text(en.actionOpenSettings));
    expect(env.permissions.settingsOpened, 1);
  });
}

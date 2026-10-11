// Pest ID listen mode: modes, live sound events with classifier labels,
// confirming one, the experimental description and the matching cards.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_pest.dart';

PestEnv _env() {
  final env = PestEnv(role: Role.household);
  env.knowledge.cards = [
    testCard(
      'test_mosquito',
      name: 'Test mosquito',
      safety: SafetyLevel.medicalRisk,
    ),
    testCard('test_rat', name: 'Test rat', group: PestGroup.rodent),
  ];
  return env;
}

SignalCandidate _sound(String id) => testCandidate(
  id,
  kind: SignalKind.soundEvent,
  source: SignalSource.microphone,
  box: null,
);

void main() {
  for (final receivedSound in [false, true]) {
    testWidgets(
      'listen failure before/after candidate ($receivedSound) is visible and retryable',
      (tester) async {
        final env = _env();
        await pumpKernelApp(tester, env, location: Routes.pestListen);
        await tapVisible(tester, find.byKey(const Key('pest-listen-start')));
        if (receivedSound) {
          env.sense.sounds.add(_sound('before-error'));
          await tester.pumpAndSettle();
        }
        env.sense.sounds.addError(StateError('capture failed'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('pest-listen-failed')), findsOneWidget);
        expect(find.byKey(const Key('pest-listening')), findsNothing);
        expect(find.byKey(const Key('pest-listen-none')), findsNothing);
        expect(find.byKey(const Key('pest-listen-start')), findsOneWidget);
        await tapVisible(tester, find.byKey(const Key('pest-listen-start')));
        expect(env.sense.listenModes, hasLength(2));
        expect(find.byKey(const Key('pest-listen-failed')), findsNothing);
      },
    );
  }

  testWidgets('subscription alone is not a confirmed listening status', (
    tester,
  ) async {
    await pumpKernelApp(tester, _env(), location: Routes.pestListen);
    await tapVisible(tester, find.byKey(const Key('pest-listen-start')));
    expect(find.byKey(const Key('pest-listening')), findsNothing);
    expect(find.byKey(const Key('pest-listen-none')), findsNothing);
    expect(find.byKey(const Key('pest-listen-stop')), findsOneWidget);
  });

  testWidgets('listen screen exposes no dead upload action', (tester) async {
    await pumpKernelApp(tester, _env(), location: Routes.pestListen);
    expect(find.byKey(const Key('pest-listen-start')), findsOneWidget);
    expect(find.byKey(const Key('pest-upload-audio')), findsNothing);
  });

  testWidgets('pest hub describes the actual insect sound chat', (
    tester,
  ) async {
    await pumpKernelApp(tester, _env(), location: Routes.pestHub);
    expect(find.text('Insect sound & photo chat'), findsOneWidget);
    expect(find.textContaining('grain proxy'), findsNothing);
    expect(find.textContaining('Autonomous Multimodal'), findsNothing);
  });

  testWidgets('general listen shows sound events with raw labels; confirming '
      'describes the clip and shows matching cards', (tester) async {
    final env = _env();
    env.sense
      ..labels['s1'] = const [
        ScoredLabel(label: 'Mosquito', score: 0.71),
        ScoredLabel(label: 'Insect', score: 0.2),
      ]
      ..clips['s1'] = testPng;
    env.analyzer.sound = const SoundAnalysis(
      preFilter: [ScoredLabel(label: 'Mosquito', score: 0.71)],
      groupHint: PestGroup.insect,
      modelVersion: 'yamnet-test-1',
      description: 'A high, thin whine.',
    );
    await pumpKernelApp(tester, env, location: Routes.pestListen);

    await tapVisible(tester, find.byKey(const Key('pest-listen-start')));
    expect(env.sense.listenModes, [ListenMode.general]);
    // The engine exposes candidates, not a microphone-running status.
    expect(find.text(en.pestListening), findsNothing);

    env.sense.sounds.add(_sound('s1'));
    await tester.pumpAndSettle();
    expect(find.text(en.pestSoundScore('Mosquito', 71)), findsOneWidget);
    expect(find.text(en.pestSoundRawNote), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('pest-sound-s1')));

    expect(env.sense.stopCalls, greaterThanOrEqualTo(1));
    final request = env.analyzer.soundRequests.single;
    expect(request.wav, testPng);
    expect(request.preFilter.first.label, 'Mosquito');
    expect(request.allowedCardIds, ['test_mosquito', 'test_rat']);
    expect(find.text(en.pestSoundDescription), findsOneWidget);
    expect(find.text('A high, thin whine.'), findsOneWidget);
    expect(find.text(en.pestSoundModel('yamnet-test-1')), findsOneWidget);
    expect(find.text(en.experimentalBadge), findsWidgets);
    expect(
      find.byKey(const Key('pest-sound-card-test_mosquito')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pest-safety-medicalRisk')), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('pest-save')));
    await tapVisible(tester, find.byKey(const Key('pest-save-confirm')));
    final draft = env.sightings.drafts.single;
    expect(draft.source, SignalSource.microphone);
    expect(draft.sound?.modelVersion, 'yamnet-test-1');
    expect(draft.analysis, isNull);
    expect(draft.userValidated, isTrue);
    expect(env.sense.discardCalls, greaterThanOrEqualTo(1));
  });

  testWidgets(
    'sound result keeps every matched concern after a low-risk pick',
    (tester) async {
      final env = _env();
      const protected = KnowledgeCard(
        id: 'test_protected',
        names: {'en': 'Test protected animal'},
        group: PestGroup.reptile,
        safety: SafetyLevel.venomous,
        extraSafety: {SafetyLevel.protectedWildlife, SafetyLevel.low},
        summary: 'Test protected animal card.',
        signs: [],
        lookAlikes: [],
        healthRisks: [],
        safeSteps: ['Keep away from the animal.'],
        trapSteps: ['Catch it in a trap.'],
        callProfessionalWhen: [],
        firstAid: [],
        legal: null,
        sources: [],
        reviewStatus: 'needs-expert-review',
      );
      final picked = testCard('test_low', safety: SafetyLevel.low);
      env.knowledge
        ..cards = [
          protected,
          picked,
          testCard('test_medical', safety: SafetyLevel.medicalRisk),
          testCard('unrelated', safety: SafetyLevel.caution),
        ]
        ..hits = [
          const KnowledgeHit(card: protected, score: 0.8),
          KnowledgeHit(card: picked, score: 0.4),
        ];
      env.sense.clips['multi'] = testPng;
      env.analyzer.sound = const SoundAnalysis(
        preFilter: [],
        groupHint: PestGroup.unknown,
        modelVersion: 'test-sound',
        cardIds: ['test_medical'],
      );
      await pumpKernelApp(tester, env, location: Routes.pestListen);
      await tapVisible(tester, find.byKey(const Key('pest-listen-start')));
      env.sense.sounds.add(_sound('multi'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('pest-sound-multi')));
      // The displayed protected card must not expose its trapping steps.
      expect(find.text('Keep away from the animal.'), findsOneWidget);
      expect(find.text('Catch it in a trap.'), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const Key('pest-sound-card-test_low')),
      );

      expect(
        find.byKey(const Key('pest-safety-protectedWildlife')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('pest-safety-venomous')), findsOneWidget);
      expect(find.byKey(const Key('pest-safety-medicalRisk')), findsOneWidget);
      expect(find.byKey(const Key('pest-safety-caution')), findsNothing);
      expect(find.byKey(const Key('pest-safety-low')), findsNothing);
      expect(find.text(en.pestSafetyProtectedBody), findsOneWidget);
      expect(find.text(en.pestSafetyDistanceBody), findsNWidgets(2));
      expect(find.byKey(const Key('knowledge-card-test_low')), findsOneWidget);
    },
  );

  testWidgets('mosquito close-up mode is passed to the engine', (tester) async {
    final env = _env();
    await pumpKernelApp(tester, env, location: Routes.pestListen);

    await tapVisible(
      tester,
      find.byKey(const Key('pest-mode-mosquitoCloseUp')),
    );
    expect(find.text(en.pestListenModeMosquitoBody), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('pest-listen-start')));

    expect(env.sense.listenModes, [ListenMode.mosquitoCloseUp]);
    await tapVisible(tester, find.byKey(const Key('pest-listen-stop')));
    expect(env.sense.stopCalls, 1);
  });

  testWidgets('night mode asks for notifications and starts when allowed', (
    tester,
  ) async {
    final env = _env();
    await pumpKernelApp(tester, env, location: Routes.pestListen);

    await tapVisible(tester, find.byKey(const Key('pest-mode-night')));
    expect(find.text(en.pestListenModeNightBody), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('pest-listen-start')));

    expect(env.permissions.notificationRequests, 1);
    expect(env.sense.listenModes, [ListenMode.night]);
  });

  testWidgets('night mode without notifications does not start', (
    tester,
  ) async {
    final env = _env();
    env.permissions.notifications = PermissionAccess.denied;
    await pumpKernelApp(tester, env, location: Routes.pestListen);

    await tapVisible(tester, find.byKey(const Key('pest-mode-night')));
    await tapVisible(tester, find.byKey(const Key('pest-listen-start')));

    expect(env.sense.listenModes, isEmpty);
    expect(find.byKey(const Key('pest-night-blocked')), findsOneWidget);
  });

  testWidgets('mic denied explains and does not listen', (tester) async {
    final env = _env();
    env.permissions.microphone = PermissionAccess.denied;
    await pumpKernelApp(tester, env, location: Routes.pestListen);

    await tapVisible(tester, find.byKey(const Key('pest-listen-start')));

    expect(find.byKey(const Key('pest-mic-denied')), findsOneWidget);
    expect(env.sense.listenModes, isEmpty);
  });

  testWidgets('a missing clip asks to listen again', (tester) async {
    final env = _env();
    await pumpKernelApp(tester, env, location: Routes.pestListen);
    await tapVisible(tester, find.byKey(const Key('pest-listen-start')));
    env.sense.sounds.add(_sound('gone'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('pest-sound-gone')));

    expect(find.byKey(const Key('pest-clip-gone')), findsOneWidget);
    expect(env.analyzer.soundRequests, isEmpty);
  });

  testWidgets('no description still shows labels as unavailable AI', (
    tester,
  ) async {
    final env = _env();
    env.sense.clips['s2'] = testPng;
    env.analyzer.sound = null;
    await pumpKernelApp(tester, env, location: Routes.pestListen);
    await tapVisible(tester, find.byKey(const Key('pest-listen-start')));
    env.sense.sounds.add(_sound('s2'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('pest-sound-s2')));

    expect(find.byKey(const Key('pest-sound-unavailable')), findsOneWidget);
  });
}

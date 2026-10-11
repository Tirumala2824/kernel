// Pest ID camera flow with a scripted sense engine: live boxes labelled by
// kind, capture with tiles ranked by embedding hint, confirming a
// tile or a box, and "Not a pest / nothing here".

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/pest_id/pest_providers.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sense_ai/sense_ai.dart';
import 'package:sense_ai/src/sense_api.g.dart';

import '../../sense-ai/test/support/test_sense_host.dart';

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

// The UI uses the production adapter; only the native boundary is scripted.
class _NativeCameraEnv extends PestEnv {
  _NativeCameraEnv(this.productionSense) : super(role: Role.household);

  final SenseEngine productionSense;

  @override
  List<Override> get overrides => [
    for (final override in super.overrides)
      if (override.origin != pestSenseEngineProvider) override,
    pestSenseEngineProvider.overrideWithValue(productionSense),
  ];
}

void main() {
  for (final interruption in ['inactive', 'bridge error', 'stream done']) {
    testWidgets(
      'production $interruption camera removes boxes until real recovery',
      (tester) async {
        final host = TestSenseHost();
        final engine = SenseEngine(host: host);
        final env = _NativeCameraEnv(engine);
        addTearDown(() async {
          await engine.dispose();
          await host.batches.close();
        });
        await pumpKernelApp(tester, env, location: Routes.pestCamera);
        host.batches.add(nativeBatch([nativeCandidate('old')]));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('pest-box-old')), findsOneWidget);

        if (interruption == 'inactive') {
          host.batches.add(nativeBatch([], active: false));
        } else if (interruption == 'bridge error') {
          host.batches.addError(StateError('native bridge disconnected'));
        } else {
          await host.batches.close();
        }
        await tester.pumpAndSettle();
        expect(find.text(en.errorCouldNotLoad), findsOneWidget);
        expect(find.text(en.pestCandidatesNone), findsNothing);
        expect(find.byKey(const Key('pest-box-old')), findsNothing);
        await tapVisible(tester, find.byKey(const Key('pest-capture')));
        expect(
          host.captureCalls.single,
          isEmpty,
          reason: 'stale boxes must not seed capture',
        );

        if (interruption == 'stream done') {
          host.batches = StreamController<NativeCameraBatch>.broadcast();
          final container = ProviderScope.containerOf(
            tester.element(find.byType(KernelApp)),
          );
          container.invalidate(cameraCandidatesProvider);
          await tester.pumpAndSettle();
        }
        host.batches.add(nativeBatch([]));
        await tester.pumpAndSettle();
        expect(find.text(en.errorCouldNotLoad), findsNothing);
        expect(find.text(en.pestCandidatesNone), findsOneWidget);
        host.batches.add(nativeBatch([nativeCandidate('fresh')]));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('pest-box-fresh')), findsOneWidget);
        expect(find.byKey(const Key('pest-box-old')), findsNothing);
      },
    );
  }

  testWidgets('camera pending and refreshing are not an empty observation', (
    tester,
  ) async {
    final env = await _env();
    await pumpKernelApp(tester, env, location: Routes.pestCamera);
    expect(find.text(en.pestCandidatesNone), findsNothing);
    expect(find.text(en.loading), findsOneWidget);
    expect(find.byKey(const Key('pest-capture')), findsOneWidget);
    env.sense.candidates.add([]);
    await tester.pumpAndSettle();
    expect(find.text(en.pestCandidatesNone), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(KernelApp)),
    );
    container.invalidate(cameraCandidatesProvider);
    await tester.pump();
    final refreshing = container.read(cameraCandidatesProvider);
    expect(refreshing.isLoading, isTrue);
    expect(refreshing.hasValue, isTrue);
    expect(find.text(en.pestCandidatesNone), findsNothing);
    expect(find.text(en.loading), findsOneWidget);
  });

  for (final observed in <List<SignalCandidate>?>[
    null,
    [],
    [testCandidate('old')],
  ]) {
    testWidgets(
      'camera error after ${observed?.length} observations is not absence',
      (tester) async {
        final env = await _env();
        await pumpKernelApp(tester, env, location: Routes.pestCamera);
        if (observed != null) {
          env.sense.candidates.add(observed);
          await tester.pumpAndSettle();
        }
        env.sense.candidates.addError(StateError('camera unavailable'));
        await tester.pumpAndSettle();
        expect(find.text(en.pestCandidatesNone), findsNothing);
        expect(find.text(en.errorCouldNotLoad), findsOneWidget);
        expect(find.byKey(const Key('pest-box-old')), findsNothing);
        expect(find.byKey(const Key('pest-capture')), findsOneWidget);
        await tapVisible(tester, find.byKey(const Key('pest-capture')));
        expect(
          env.sense.captureCalls.single,
          isEmpty,
          reason: 'failed candidate data must not seed stale capture tiles',
        );
      },
    );
  }

  testWidgets('live boxes are labelled by kind over the preview', (
    tester,
  ) async {
    final env = await _env();
    await pumpKernelApp(tester, env, location: Routes.pestCamera);

    expect(find.byKey(const Key('camera-preview')), findsOneWidget);
    env.sense.candidates.add([]);
    await tester.pumpAndSettle();
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

  testWidgets('live camera does not invent detections from gallery imports', (
    tester,
  ) async {
    final env = await _env();
    await pumpKernelApp(tester, env, location: Routes.pestCamera);

    expect(find.byKey(const Key('camera-preview')), findsOneWidget);
    expect(find.byKey(const Key('pest-capture')), findsOneWidget);
    env.sense.candidates.add([]);
    await tester.pumpAndSettle();
    expect(find.text(en.pestCandidatesNone), findsOneWidget);
    expect(find.byKey(const Key('pest-upload-photo')), findsNothing);
    expect(find.textContaining('Gallery'), findsNothing);
    expect(env.sense.captureCalls, isEmpty);
    expect(env.analyzer.imageRequests, isEmpty);
  });

  testWidgets('camera does not offer unsupported torch brightness', (
    tester,
  ) async {
    final env = await _env();
    await pumpKernelApp(tester, env, location: Routes.pestCamera);

    expect(find.byKey(const Key('pest-torch')), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.text(en.pestTorch), findsNothing);
    expect(env.sense.torchLevels, isEmpty);
    expect(find.byKey(const Key('camera-preview')), findsOneWidget);
    expect(find.byKey(const Key('pest-capture')), findsOneWidget);
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

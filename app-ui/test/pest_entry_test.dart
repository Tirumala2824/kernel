// Pest ID entry points: the Household hero, the action on the other homes,
// the Scan tab segment and the Pest ID next-step kinds.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kernel_app/features/pest_id/pest_providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/home/next_actions.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_pest.dart';

class _HubEnv extends PestEnv {
  _HubEnv() : super(role: Role.household);

  int recentReads = 0;

  @override
  List<Override> get overrides => [
    ...super.overrides,
    recentSightingsProvider(Role.household).overrideWith((ref) {
      recentReads++;
      return sightings.watchRecent(role: Role.household);
    }),
  ];
}

void main() {
  testWidgets(
    'hub does not subscribe to a capped count; sightings route stays real',
    (tester) async {
      final env = _HubEnv();
      await env.sightings.add(role: Role.household);
      await pumpKernelApp(tester, env, location: Routes.pestHub);
      expect(env.recentReads, 0);
      expect(find.text(en.pestSightingsSubtitle), findsOneWidget);
      expect(find.text(en.pestSightingsCount(1)), findsNothing);
      await tapVisible(tester, find.byKey(const Key('pest-hub-sightings')));
      expect(routerOf(tester).state.uri.path, Routes.sightings);
      expect(env.recentReads, 1);
    },
  );

  testWidgets('Household home has a Pest & animal ID hero into the hub', (
    tester,
  ) async {
    final env = PestEnv(role: Role.household);
    await pumpKernelApp(tester, env);

    final hero = find.byKey(const Key('pest-id-hero'));
    expect(hero, findsOneWidget);
    await tapVisible(tester, hero);

    expect(find.byKey(const Key('pest-hub')), findsOneWidget);
    expect(find.text(en.pestSightingsSubtitle), findsOneWidget);
  });

  for (final role in [Role.farmer, Role.storageFpo, Role.buyer]) {
    testWidgets('${role.name} home has the Pest ID action', (tester) async {
      final env = PestEnv(role: role);
      await pumpKernelApp(tester, env);

      expect(find.byKey(const Key('pest-id-hero')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('pest-id-action')));
      expect(find.byKey(const Key('pest-hub')), findsOneWidget);
    });
  }

  testWidgets('Scan tab: "Grain sack | Pest & animal" segment', (tester) async {
    final env = PestEnv(role: Role.farmer);
    await env.sightings.add(role: Role.farmer);
    await pumpKernelApp(tester, env, location: Routes.scan);

    expect(find.text(en.pestSegmentGrain), findsOneWidget);
    expect(find.text(en.pestSegmentPest), findsOneWidget);
    expect(find.byKey(const Key('pest-hub')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('scan-mode-pest')));
    expect(find.byKey(const Key('pest-hub')), findsOneWidget);
    expect(find.text(en.pestSightingsSubtitle), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('pest-hub-listen')));
    expect(find.text(en.pestListenTitle), findsWidgets);
  });

  testWidgets('the Scan tab opens on the pest segment from its route', (
    tester,
  ) async {
    final env = PestEnv(role: Role.household);
    await pumpKernelApp(tester, env, location: Routes.scanPest);
    expect(find.byKey(const Key('pest-hub')), findsOneWidget);
  });

  test('Pest ID next steps open the sightings with attention', () {
    final repeated = describeNextAction(
      en,
      Role.household,
      const NextAction(
        kind: NextActionKind.pestSightingsRepeated,
        priority: 1,
        count: 3,
        label: 'Kitchen',
      ),
    );
    expect(repeated.title, en.pestNextRepeatedOne('Kitchen', 3));
    expect(repeated.location, Routes.sightings);
    expect(repeated.attention, isTrue);

    final safety = describeNextAction(
      en,
      Role.household,
      const NextAction(kind: NextActionKind.pestSafetyAlert, priority: 0),
    );
    expect(safety.title, en.pestNextSafety);
    expect(safety.location, Routes.sightings);
  });
}

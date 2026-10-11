import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/data_providers.dart';
import 'package:kernel_app/widgets/kernel_card.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_engine.dart';

class _HomeEnv extends TestEnv {
  _HomeEnv(this.role) : super(role: role);

  final Role role;
  final stats = StreamController<InspectionStats>.broadcast();
  final upcoming = StreamController<List<Reminder>>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    inspectionStatsProvider(roleScope(role))
        .overrideWith((ref) => stats.stream),
    upcomingRemindersProvider.overrideWith((ref) => upcoming.stream),
  ];
}

class _FarmerHomeEnv extends TestEnv {
  _FarmerHomeEnv() : super(role: Role.farmer);

  final observedInspections = StreamController<List<Inspection>>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    openInspectionsProvider.overrideWith((ref) => observedInspections.stream),
  ];
}

class _FarmerItemRefreshEnv extends TestEnv {
  _FarmerItemRefreshEnv() : super(role: Role.farmer);

  bool holdRefresh = false;
  final observedItems = StreamController<List<GrainItem>>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    itemsByRoleProvider(Role.farmer).overrideWith(
      (ref) =>
          holdRefresh ? observedItems.stream : items.watchByRole(Role.farmer),
    ),
  ];
}

class _ActivityHomeEnv extends TestEnv {
  _ActivityHomeEnv(this.role) : super(role: role);

  final Role role;
  final observedActivity = StreamController<ScanActivity>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    scanActivityProvider(roleScope(role))
        .overrideWith((ref) => observedActivity.stream),
  ];
}

class _QueueHomeEnv extends TestEnv {
  _QueueHomeEnv(Role role) : super(role: role);

  late QueueScope scope;
  final observedQueue = StreamController<InspectionQueue>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    inspectionQueueProvider(scope).overrideWith((ref) => observedQueue.stream),
  ];
}

class _HarvestHomeEnv extends TestEnv {
  _HarvestHomeEnv() : super(role: Role.farmer);

  final observedHarvests = StreamController<List<Harvest>>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    harvestsProvider.overrideWith((ref) => observedHarvests.stream),
  ];
}

void main() {
  for (final role in [Role.storageFpo, Role.buyer]) {
    for (final refresh in [false, true]) {
      testWidgets(
        '${role.name} queue summary drops retained zero on ${refresh ? 'refresh' : 'error'}',
        (tester) async {
          final env = _QueueHomeEnv(role);
          addTearDown(env.observedQueue.close);
          final buyer = role == Role.buyer;
          final lot = buyer
              ? await env.lots.create(
                  LotDraft(
                    code: 'Incoming',
                    grainType: 'Rice',
                    declaredQuantity: 10,
                    quantityUnit: 'kg',
                    receivedAt: DateTime(2026, 9, 1),
                  ),
                )
              : null;
          env.scope = (
            role: buyer ? null : role,
            locationId: null,
            lotId: lot?.id,
          );
          if (!buyer) await env.addItem(role: role);
          await pumpKernelApp(tester, env);
          final cardKey = Key(buyer ? 'lot-${lot!.id}' : 'queue-card');
          KernelCard summary() =>
              tester.widget<KernelCard>(find.byKey(cardKey));
          expect(summary().subtitle, en.loading);
          expect(summary().onTap, isNotNull);

          env.observedQueue.add(
            const InspectionQueue(
              ranked: [],
              needsScan: [],
              modelVersion: null,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            summary().subtitle,
            buyer ? en.lotNoSacks : en.queueSummary(0, 0),
          );
          final provider = inspectionQueueProvider(env.scope);
          final container = ProviderScope.containerOf(
            tester.element(find.byType(KernelApp)),
          );
          if (refresh) {
            container.invalidate(provider);
            await tester.pump();
            expect(container.read(provider).isLoading, isTrue);
          } else {
            env.observedQueue.addError(
              StateError('queue unavailable after zero'),
            );
            await tester.pumpAndSettle();
            expect(container.read(provider).hasError, isTrue);
          }
          expect(container.read(provider).hasValue, isTrue);
          expect(
            summary().subtitle,
            refresh ? en.loading : en.errorCouldNotLoad,
          );
          expect(summary().tone, KernelCardTone.ivory);
          expect(summary().onTap, isNotNull);

          final item = await env.addItem(role: role, lotId: lot?.id);
          final scan = await env.scans.record(
            modelOutcome(item.id, Classification.uncertain),
          );
          env.observedQueue.add(
            InspectionQueue(
              ranked: [QueueEntry(item: item, latestValidScan: scan)],
              needsScan: [],
              modelVersion: scan.modelVersion,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            summary().subtitle,
            buyer ? en.lotScreenedCount(1, 1) : en.queueSummary(1, 0),
          );
          if (!buyer) expect(summary().tone, KernelCardTone.attention);
          env.observedQueue.addError(StateError('queue failed after recovery'));
          await tester.pumpAndSettle();
          expect(summary().subtitle, en.errorCouldNotLoad);
          expect(summary().tone, KernelCardTone.ivory);
          await tapVisible(tester, find.byKey(cardKey));
          expect(
            routerOf(tester).state.uri.path,
            buyer ? Routes.lot(lot!.id) : Routes.queue,
          );
        },
      );
    }
  }

  for (final role in [Role.storageFpo, Role.household]) {
    for (final refresh in [false, true]) {
      testWidgets(
        '${role.name} activity summary drops retained zero on ${refresh ? 'refresh' : 'error'}',
        (tester) async {
          final env = _ActivityHomeEnv(role);
          addTearDown(env.observedActivity.close);
          final item = await env.addItem(role: role);
          await pumpKernelApp(tester, env);
          final household = role == Role.household;
          KernelCard summary() =>
              tester.widget<KernelCard>(find.byKey(const Key('items-summary')));
          final activityNote = find.byKey(const Key('household-activity'));
          if (household) {
            expect(activityNote, findsNothing);
          } else {
            expect(summary().subtitle, en.loading);
          }

          env.observedActivity.add(const ScanActivity(today: 0, last7Days: 0));
          await tester.pumpAndSettle();
          expect(
            find.text(
              household ? en.scanActivityLine(0, 0) : en.scansTodayCount(0),
            ),
            findsOneWidget,
          );
          final provider = scanActivityProvider(roleScope(role));
          final container = ProviderScope.containerOf(
            tester.element(find.byType(KernelApp)),
          );
          if (refresh) {
            container.invalidate(provider);
            await tester.pump();
            expect(container.read(provider).isLoading, isTrue);
          } else {
            env.observedActivity.addError(StateError('activity unavailable'));
            await tester.pumpAndSettle();
            expect(container.read(provider).hasError, isTrue);
          }
          expect(container.read(provider).hasValue, isTrue);
          if (household) {
            expect(activityNote, findsNothing);
            expect(
              tester
                  .widget<OutlinedButton>(find.byKey(Key('remind-${item.id}')))
                  .onPressed,
              isNotNull,
            );
          } else {
            expect(
              summary().subtitle,
              refresh ? en.loading : en.errorCouldNotLoad,
            );
            expect(summary().onTap, isNotNull);
          }
          expect(
            tester
                .widget<HeroActionCard>(find.byKey(const Key('hero-scan')))
                .onTap,
            isNotNull,
          );

          env.observedActivity.add(const ScanActivity(today: 2, last7Days: 3));
          await tester.pumpAndSettle();
          expect(
            find.text(
              household ? en.scanActivityLine(2, 3) : en.scansTodayCount(2),
            ),
            findsOneWidget,
          );
          env.observedActivity.addError(
            StateError('activity failed after recovery'),
          );
          await tester.pumpAndSettle();
          if (household) {
            expect(activityNote, findsNothing);
          } else {
            expect(summary().subtitle, en.errorCouldNotLoad);
            await tapVisible(tester, find.byKey(const Key('items-summary')));
            expect(routerOf(tester).state.uri.path, Routes.scansToday);
          }
        },
      );
    }
  }

  for (final refresh in [false, true]) {
    testWidgets(
      'buyer inspection summary drops retained zero on ${refresh ? 'refresh' : 'error'}',
      (tester) async {
        final env = _HomeEnv(Role.buyer);
        addTearDown(env.stats.close);
        addTearDown(env.upcoming.close);
        await env.lots.create(
          LotDraft(
            code: 'Incoming',
            grainType: 'Rice',
            declaredQuantity: 10,
            quantityUnit: 'kg',
            receivedAt: DateTime(2026, 9, 1),
          ),
        );
        await pumpKernelApp(tester, env);
        final summary = find.byKey(const Key('buyer-inspections'));
        expect(summary, findsNothing);
        env.stats.addError(StateError('stats unavailable'));
        await tester.pumpAndSettle();
        expect(summary, findsNothing);

        const zero = InspectionStats(open: 0, inProgress: 0, done: 1);
        env.stats.add(zero);
        await tester.pumpAndSettle();
        expect(find.text(en.assignedNone), findsOneWidget);
        final provider = inspectionStatsProvider(roleScope(Role.buyer));
        final container = ProviderScope.containerOf(
          tester.element(find.byType(KernelApp)),
        );
        if (refresh) {
          container.invalidate(provider);
          await tester.pump();
          expect(container.read(provider).isLoading, isTrue);
        } else {
          env.stats.addError(StateError('stats unavailable after zero'));
          await tester.pumpAndSettle();
          expect(container.read(provider).hasError, isTrue);
        }
        expect(container.read(provider).hasValue, isTrue);
        expect(summary, findsNothing, reason: 'retained zero is not current');
        expect(
          tester
              .widget<HeroActionCard>(
                find.byKey(const Key('hero-register-lot')),
              )
              .onTap,
          isNotNull,
        );

        env.stats.add(const InspectionStats(open: 1, inProgress: 1, done: 1));
        await tester.pumpAndSettle();
        expect(find.text(en.inspectionsOpen(2)), findsOneWidget);
        await tapVisible(tester, find.byKey(const Key('hero-register-lot')));
        expect(routerOf(tester).state.uri.path, Routes.newLot);
      },
    );
  }

  testWidgets(
    'harvest pending, failure and refresh cannot imply empty or create new',
    (tester) async {
      final env = _HarvestHomeEnv();
      addTearDown(env.observedHarvests.close);
      final harvest = await env.harvests.create(
        HarvestDraft(
          name: 'Observed harvest',
          grainType: 'Wheat',
          harvestedAt: DateTime(2026, 9, 1),
        ),
      );
      await pumpKernelApp(tester, env);
      KernelCard card() =>
          tester.widget<KernelCard>(find.byKey(const Key('harvests-card')));
      expect(card().subtitle, en.loading);
      expect(card().onTap, isNull);
      env.observedHarvests.addError(StateError('harvests unavailable'));
      await tester.pumpAndSettle();
      expect(card().subtitle, en.errorCouldNotLoad);
      expect(card().onTap, isNull);
      env.observedHarvests.add([]);
      await tester.pumpAndSettle();
      expect(card().subtitle, en.harvestsEmptyCard);
      expect(card().onTap, isNotNull);
      env.observedHarvests.add([harvest]);
      await tester.pumpAndSettle();
      expect(card().subtitle, en.harvestsCount(1));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(KernelApp)),
      );
      container.invalidate(harvestsProvider);
      await tester.pump();
      final refreshing = container.read(harvestsProvider);
      expect(refreshing.isLoading, isTrue);
      expect(refreshing.hasValue, isTrue);
      expect(card().subtitle, en.loading);
      expect(card().onTap, isNull);
      env.observedHarvests.addError(StateError('harvests refresh failed'));
      await tester.pumpAndSettle();
      expect(card().subtitle, en.errorCouldNotLoad);
      expect(card().onTap, isNull);
      env.observedHarvests.add([harvest]);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('harvests-card')));
      expect(routerOf(tester).state.uri.path, Routes.harvest(harvest.id));
    },
  );

  testWidgets('observed empty harvests still opens create harvest', (
    tester,
  ) async {
    final env = TestEnv(role: Role.farmer);
    await pumpKernelApp(tester, env);
    expect(find.text(en.harvestsEmptyCard), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('harvests-card')));
    expect(routerOf(tester).state.uri.path, Routes.newHarvest);
  });

  testWidgets(
    'household reminders do not treat pending or failed data as zero',
    (tester) async {
      final env = _HomeEnv(Role.household);
      addTearDown(env.stats.close);
      addTearDown(env.upcoming.close);
      final item = await env.addItem(role: Role.household);
      final other = await env.addItem(role: Role.farmer);
      final due = DateTime.now().add(const Duration(days: 1));
      final mine = await env.reminders.schedule(item.id, due);
      final theirs = await env.reminders.schedule(other.id, due);
      await pumpKernelApp(tester, env);
      KernelCard summary() =>
          tester.widget<KernelCard>(find.byKey(const Key('reminders-card')));

      expect(summary().title, en.remindersCardTitle);
      expect(summary().subtitle, isNull, reason: 'no reminders have arrived');
      expect(find.text(en.remindersCardEmpty), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(Key('remind-${item.id}')))
            .onPressed,
        isNotNull,
      );

      env.upcoming.addError(StateError('reminders unavailable'));
      await tester.pumpAndSettle();
      expect(summary().subtitle, isNull);

      env.upcoming.add([]);
      await tester.pumpAndSettle();
      expect(summary().subtitle, en.remindersCardEmpty);

      env.upcoming.add([mine, theirs]);
      await tester.pumpAndSettle();
      expect(summary().subtitle, en.remindersScheduled(1));

      env.upcoming.addError(StateError('reminders unavailable after data'));
      await tester.pumpAndSettle();
      expect(summary().subtitle, isNull, reason: 'error is not current data');
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(Key('remind-${item.id}')))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('FPO inspections do not treat pending or failed data as zero', (
    tester,
  ) async {
    final env = _HomeEnv(Role.storageFpo);
    addTearDown(env.stats.close);
    addTearDown(env.upcoming.close);
    await env.addItem(role: Role.storageFpo);
    await pumpKernelApp(tester, env);
    KernelCard summary() =>
        tester.widget<KernelCard>(find.byKey(const Key('assigned-card')));

    expect(summary().title, en.assignedTitle);
    expect(summary().onTap, isNotNull);
    expect(summary().subtitle, isNull, reason: 'no statistics have arrived');
    expect(find.text(en.assignedNone), findsNothing);

    env.stats.addError(StateError('stats unavailable'));
    await tester.pumpAndSettle();
    expect(summary().subtitle, isNull);

    env.stats.add(const InspectionStats(open: 0, inProgress: 0, done: 1));
    await tester.pumpAndSettle();
    expect(summary().subtitle, en.assignedNone);

    env.stats.add(const InspectionStats(open: 1, inProgress: 1, done: 1));
    await tester.pumpAndSettle();
    expect(summary().subtitle, en.inspectionsOpen(2));

    env.stats.addError(StateError('stats unavailable after data'));
    await tester.pumpAndSettle();
    expect(summary().subtitle, isNull, reason: 'error is not current data');
    expect(summary().onTap, isNotNull);
  });

  testWidgets(
    'farmer follow-ups wait for a current item scope during refresh',
    (tester) async {
      final env = _FarmerItemRefreshEnv();
      addTearDown(env.observedItems.close);
      final item = await env.addItem();
      await pumpKernelApp(tester, env);
      KernelCard summary() =>
          tester.widget<KernelCard>(find.byKey(const Key('items-summary')));
      expect(summary().subtitle, en.noFollowUps);
      final provider = itemsByRoleProvider(Role.farmer);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(KernelApp)),
      );
      env.holdRefresh = true;
      container.invalidate(provider);
      await tester.pump();
      expect(container.read(provider).isLoading, isTrue);
      expect(container.read(provider).hasValue, isTrue);
      expect(summary().subtitle, isNull);
      expect(summary().onTap, isNotNull);
      env.observedItems.add([item]);
      await tester.pumpAndSettle();
      expect(summary().subtitle, en.noFollowUps);
    },
  );

  testWidgets('farmer follow-ups do not treat pending or failed data as zero', (
    tester,
  ) async {
    final env = _FarmerHomeEnv();
    addTearDown(env.observedInspections.close);
    final item = await env.addItem();
    final first = await env.addInspection(
      item.id,
      VerifiedFinding.inconclusive,
    );
    final second = await env.addInspection(
      item.id,
      VerifiedFinding.inconclusive,
      status: FollowUpStatus.inProgress,
    );
    await pumpKernelApp(tester, env);
    KernelCard summary() =>
        tester.widget<KernelCard>(find.byKey(const Key('items-summary')));

    expect(summary().title, en.registeredSacks(1));
    expect(summary().onTap, isNotNull);
    expect(summary().subtitle, isNull, reason: 'no inspections have arrived');
    expect(find.text(en.noFollowUps), findsNothing);

    env.observedInspections.addError(StateError('inspections unavailable'));
    await tester.pumpAndSettle();
    expect(summary().subtitle, isNull);

    env.observedInspections.add([]);
    await tester.pumpAndSettle();
    expect(summary().subtitle, en.noFollowUps);
    env.observedInspections.addError(
      StateError('inspections unavailable after zero'),
    );
    await tester.pumpAndSettle();
    expect(summary().subtitle, isNull);

    env.observedInspections.add([first, second]);
    await tester.pumpAndSettle();
    expect(summary().subtitle, en.sacksRequireFollowUp(1));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(KernelApp)),
    );
    container.invalidate(openInspectionsProvider);
    await tester.pump();
    expect(container.read(openInspectionsProvider).isLoading, isTrue);
    expect(container.read(openInspectionsProvider).hasValue, isTrue);
    expect(summary().subtitle, isNull);
    env.observedInspections.addError(StateError('inspections refresh failed'));
    await tester.pumpAndSettle();
    expect(summary().subtitle, isNull, reason: 'error is not current data');
    expect(summary().onTap, isNotNull);
    env.observedInspections.add([first, second]);
    await tester.pumpAndSettle();
    expect(summary().subtitle, en.sacksRequireFollowUp(1));
    await tapVisible(tester, find.byKey(const Key('items-summary')));
    expect(routerOf(tester).state.uri.path, Routes.inventory);
  });
}

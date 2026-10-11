import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/data_providers.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/widgets/record_tiles.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/test_engine.dart';

class _RecordEnv extends TestEnv {
  _RecordEnv(Role role) : super(role: role);

  late String itemId;
  final scanHistory = StreamController<List<ScanRecord>>.broadcast();
  final checkHistory = StreamController<List<Inspection>>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    scansForItemProvider(itemId).overrideWith((ref) => scanHistory.stream),
    inspectionsForItemProvider(itemId)
        .overrideWith((ref) => checkHistory.stream),
  ];
}

class _TodayEnv extends TestEnv {
  _TodayEnv() : super(role: Role.farmer);
  final observedItems = StreamController<List<GrainItem>>.broadcast();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    itemsByRoleProvider(Role.farmer)
        .overrideWith((ref) => observedItems.stream),
  ];
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(KernelApp)));

Future<Lot> _lot(TestEnv env) => env.lots.create(
  LotDraft(
    code: 'Observed lot',
    grainType: 'Rice',
    declaredQuantity: 10,
    quantityUnit: 'kg',
    receivedAt: DateTime(2026, 9, 1),
  ),
);

void main() {
  testWidgets(
    'today never invents archive status from unavailable item labels',
    (tester) async {
      final env = _TodayEnv();
      addTearDown(env.observedItems.close);
      final item = await env.addItem(label: 'Active observed sack');
      final scan = await env.scans.record(notEvaluatedOutcome(item.id));
      await pumpKernelApp(tester, env, location: Routes.scansToday);
      ScanRecordTile tile() =>
          tester.widget<ScanRecordTile>(find.byType(ScanRecordTile));
      void expectUnresolvedLabel() {
        expect(tile().scan.id, scan.id);
        expect(tile().itemLabel, isNull);
        expect(tile().onTap, isNotNull);
        expect(find.textContaining('Archived'), findsNothing);
      }

      expectUnresolvedLabel();
      env.observedItems.addError(StateError('items unavailable'));
      await tester.pumpAndSettle();
      expectUnresolvedLabel();
      env.observedItems.add([]);
      await tester.pumpAndSettle();
      expectUnresolvedLabel();
      env.observedItems.add([item]);
      await tester.pumpAndSettle();
      expect(tile().itemLabel, item.label);
      final provider = itemsByRoleProvider(Role.farmer);
      _container(tester).invalidate(provider);
      await tester.pump();
      expect(_container(tester).read(provider).isLoading, isTrue);
      expect(_container(tester).read(provider).hasValue, isTrue);
      expectUnresolvedLabel();
      env.observedItems.addError(StateError('items refresh failed'));
      await tester.pumpAndSettle();
      expectUnresolvedLabel();
      env.observedItems.add([item]);
      await tester.pumpAndSettle();
      expect(tile().itemLabel, item.label);
      await tester.tap(find.byType(ScanRecordTile));
      await tester.pumpAndSettle();
      expect(routerOf(tester).state.uri.path, Routes.result(item.id, scan.id));
    },
  );

  for (final harvestMode in [false, true]) {
    testWidgets(
      '${harvestMode ? 'harvest' : 'lot'} scan footers require current history',
      (tester) async {
        final role = harvestMode ? Role.farmer : Role.buyer;
        final env = _RecordEnv(role);
        addTearDown(env.scanHistory.close);
        addTearDown(env.checkHistory.close);
        final lot = harvestMode ? null : await _lot(env);
        final harvest = harvestMode
            ? await env.harvests.create(
                HarvestDraft(
                  name: 'Observed harvest',
                  grainType: 'Rice',
                  harvestedAt: DateTime(2026, 9, 1),
                ),
              )
            : null;
        final item = await env.addItem(
          role: role,
          lotId: lot?.id,
          harvestId: harvest?.id,
        );
        env.itemId = item.id;
        final scan = await env.scans.record(notEvaluatedOutcome(item.id));
        await pumpKernelApp(
          tester,
          env,
          location: harvestMode
              ? Routes.harvest(harvest!.id)
              : Routes.lot(lot!.id),
        );
        final tile = harvestMode
            ? find.byType(ItemTile)
            : find.byKey(Key('sample-${item.id}'));
        Finder footer(String text) =>
            find.descendant(of: tile, matching: find.text(text));
        final result = find.descendant(
          of: tile,
          matching: find.byType(ScanResultChip),
        );
        expect(footer(en.notScannedYet), findsNothing);
        expect(footer(en.loading), findsOneWidget);
        expect(tester.widget<ItemTile>(tile).onTap, isNotNull);
        env.scanHistory.addError(StateError('history unavailable'));
        await tester.pumpAndSettle();
        expect(footer(en.notScannedYet), findsNothing);
        expect(footer(en.errorCouldNotLoad), findsOneWidget);
        env.scanHistory.add([]);
        await tester.pumpAndSettle();
        expect(footer(en.notScannedYet), findsOneWidget);
        final provider = scansForItemProvider(item.id);
        _container(tester).invalidate(provider);
        await tester.pump();
        expect(_container(tester).read(provider).isLoading, isTrue);
        expect(_container(tester).read(provider).hasValue, isTrue);
        expect(footer(en.notScannedYet), findsNothing);
        expect(footer(en.loading), findsOneWidget);
        env.scanHistory.add([scan]);
        await tester.pumpAndSettle();
        expect(
          tester.widget<ScanResultChip>(result).result,
          Classification.notEvaluated,
        );
        env.scanHistory.addError(StateError('history unavailable after data'));
        await tester.pumpAndSettle();
        expect(result, findsNothing);
        expect(footer(en.errorCouldNotLoad), findsOneWidget);
      },
    );
  }

  testWidgets('physical checks distinguish unavailable history from no check', (
    tester,
  ) async {
    final env = _RecordEnv(Role.buyer);
    addTearDown(env.scanHistory.close);
    addTearDown(env.checkHistory.close);
    final lot = await _lot(env);
    final item = await env.addItem(role: Role.buyer, lotId: lot.id);
    env.itemId = item.id;
    final inspection = await env.addInspection(
      item.id,
      VerifiedFinding.pestsFound,
    );
    await pumpKernelApp(tester, env, location: Routes.lot(lot.id));
    final tile = find.byKey(Key('check-${item.id}'));
    Finder footer(String text) =>
        find.descendant(of: tile, matching: find.text(text));
    expect(footer('No physical check yet'), findsNothing);
    expect(footer(en.loading), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(Key('record-check-${item.id}')))
          .onPressed,
      isNotNull,
    );

    env.checkHistory.addError(StateError('history unavailable'));
    await tester.pumpAndSettle();
    expect(footer('No physical check yet'), findsNothing);
    expect(footer(en.errorCouldNotLoad), findsOneWidget);

    env.checkHistory.add([]);
    await tester.pumpAndSettle();
    expect(footer('No physical check yet'), findsOneWidget);

    final provider = inspectionsForItemProvider(item.id);
    _container(tester).invalidate(provider);
    await tester.pump();
    expect(_container(tester).read(provider).isLoading, isTrue);
    expect(_container(tester).read(provider).hasValue, isTrue);
    expect(footer('No physical check yet'), findsNothing);
    expect(footer(en.loading), findsOneWidget);

    env.checkHistory.add([inspection]);
    await tester.pumpAndSettle();
    final recorded = en.verifiedFindingLine(en.findingPestsFound);
    expect(footer(recorded), findsOneWidget);
    env.checkHistory.addError(StateError('history unavailable after data'));
    await tester.pumpAndSettle();
    expect(footer(recorded), findsNothing);
    expect(footer(en.errorCouldNotLoad), findsOneWidget);
  });
}

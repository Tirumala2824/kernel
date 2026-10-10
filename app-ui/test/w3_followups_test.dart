import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/inventory/item_form_screen.dart';
import 'package:kernel_app/features/scan/scan_tab_screen.dart';
import 'package:kernel_app/features/settings/language_picker.dart';
import 'package:kernel_app/l10n/l10n.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

void main() {
  group('Onboarding hands navigation to the router', () {
    final orders = <(String, Duration, Duration)>[
      (
        'role emits first',
        const Duration(milliseconds: 60),
        const Duration(milliseconds: 450),
      ),
      (
        'onboarding emits first',
        const Duration(milliseconds: 450),
        const Duration(milliseconds: 60),
      ),
    ];
    for (final (name, roleDelay, onboardingDelay) in orders) {
      testWidgets('lands on Home when settings emit late ($name)', (
        tester,
      ) async {
        final env = TestEnv(
          settings: InMemorySettingsRepository(
            onboardingDone: false,
            roleEmitDelay: roleDelay,
            onboardingEmitDelay: onboardingDelay,
          ),
        );
        await pumpKernelApp(tester, env);
        expect(find.byKey(const Key('onboarding-page-0')), findsOneWidget);

        await tester.tap(find.byKey(const Key('onboarding-skip')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('role-farmer')));
        // Settings have not emitted yet: still on onboarding, not navigated.
        await tester.pump();
        expect(find.byType(NavigationBar), findsNothing);
        // A second tap while saving is ignored.
        await tester.tap(find.byKey(const Key('role-buyer')));
        await tester.pump();

        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.pumpAndSettle();

        expect(env.settings.roleWrites, [Role.farmer]);
        expect(env.settings.onboardingDone, isTrue);
        expect(find.text(en.farmerHomeTitle), findsOneWidget);
        final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(nav.selectedIndex, 0);
        expect(find.byType(ScanTabScreen), findsNothing);
        expect(find.byKey(const Key('onboarding-page-2')), findsNothing);
      });
    }
  });

  group('Language picker', () {
    test('English first, then by native name', () {
      final order = pickerLanguageOrder([
        for (final l in AppLocalizations.supportedLocales) l.languageCode,
      ]);
      expect(order.first, 'en');
      final names = [for (final t in order.skip(1)) nativeLanguageNames[t]!];
      expect(names, [...names]..sort());
      expect(order, [
        'en',
        'mr',
        'hi',
        'bn',
        'pa',
        'gu',
        'or',
        'ta',
        'te',
        'kn',
        'ml',
      ]);
    });

    testWidgets('the sheet lists languages in that order', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.settings);
      await tapVisible(tester, find.byKey(const Key('language-tile')));
      expect(find.text(en.languageSheetBody), findsOneWidget);
      expect(find.textContaining('on the way'), findsNothing);
      double y(String tag) =>
          tester.getTopLeft(find.byKey(Key('language-$tag'))).dy;
      expect(y('device') < y('en'), isTrue);
      expect(y('en') < y('mr'), isTrue);
      expect(y('mr') < y('hi'), isTrue);
      expect(y('kn') < y('ml'), isTrue);
    });
  });

  group('Zero-sack harvests and lots offer to add sacks', () {
    testWidgets('harvest detail', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final harvest = await env.harvests.create(
        HarvestDraft(
          name: 'Kharif',
          grainType: 'Rice',
          harvestedAt: DateTime(2026, 10, 1),
        ),
      );
      await pumpKernelApp(tester, env, location: Routes.harvest(harvest.id));
      final empty = find.byKey(const Key('empty-harvest-sacks'));
      await tapVisible(
        tester,
        find.descendant(of: empty, matching: find.byType(FilledButton)),
      );
      final form = tester.widget<ItemFormScreen>(find.byType(ItemFormScreen));
      expect(form.harvestId, harvest.id);
    });

    testWidgets('lot detail', (tester) async {
      final env = TestEnv(role: Role.buyer);
      final lot = await env.lots.create(
        LotDraft(
          code: 'LOT-9',
          grainType: 'Wheat',
          declaredQuantity: 5,
          quantityUnit: 'tonne',
          receivedAt: DateTime(2026, 10, 1),
        ),
      );
      await pumpKernelApp(tester, env, location: Routes.lot(lot.id));
      final empty = find.byKey(const Key('empty-lot-sacks'));
      expect(empty, findsOneWidget);
      await tapVisible(
        tester,
        find.descendant(of: empty, matching: find.byType(FilledButton)),
      );
      final form = tester.widget<ItemFormScreen>(find.byType(ItemFormScreen));
      expect(form.lotId, lot.id);
    });
  });

  group('New screens at 200% text', () {
    Future<void> scrollTo(WidgetTester tester, Finder finder) =>
        tester.scrollUntilVisible(
          finder,
          400,
          scrollable: find.byType(Scrollable).first,
        );

    void largeText(WidgetTester tester) {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    for (final code in ['en', 'ta', 'ml', 'hi']) {
      final l = lookupAppLocalizations(Locale(code));

      testWidgets('$code: next-step home', (tester) async {
        final env = TestEnv(role: Role.farmer);
        await env.settings.setLanguageTag(code);
        final sack = await env.addItem(label: 'A rather long sack label R-004');
        env.analytics.setNextActions(Role.farmer, [
          NextAction(
            kind: NextActionKind.inspectFlagged,
            priority: 0,
            itemId: sack.id,
            label: 'A rather long sack label R-004',
          ),
          const NextAction(
            kind: NextActionKind.scanNeeded,
            priority: 1,
            count: 12,
          ),
          const NextAction(
            kind: NextActionKind.exportPreSale,
            priority: 2,
            label: 'Rabi 2026',
          ),
        ]);
        largeText(tester);
        await pumpKernelApp(tester, env);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('next-step-hero')), findsOneWidget);
        expect(find.text(l.nextStepEyebrow.toUpperCase()), findsOneWidget);
      });

      testWidgets('$code: result with on-phone explanation', (tester) async {
        final env = TestEnv(role: Role.household);
        await env.settings.setLanguageTag(code);
        final tin = await env.addItem(role: Role.household, label: 'Tin 1');
        final scan = await env.scans.record(
          modelOutcome(tin.id, Classification.uncertain),
        );
        await env.enableAdvice();
        env.advice.explainScript = adviceEvents([
          'A long generated explanation that wraps over several lines',
          'and must not clip at large text sizes.',
        ], languageTag: code);
        largeText(tester);
        await pumpKernelApp(
          tester,
          env,
          location: Routes.result(tin.id, scan.id),
        );
        await scrollTo(tester, find.byKey(const Key('explain-result')));
        await tapVisible(tester, find.byKey(const Key('explain-result')));
        expect(tester.takeException(), isNull);
        expect(
          find.text(l.adviceProvenance(testAdviceModelVersion)),
          findsOneWidget,
        );
        expect(find.text(l.adviceNotDecision), findsOneWidget);
      });

      testWidgets('$code: reminder sheet with suggestion and wording', (
        tester,
      ) async {
        final env = TestEnv(role: Role.household);
        await env.settings.setLanguageTag(code);
        final tin = await env.addItem(role: Role.household, label: 'Tin 2');
        await env.enableAdvice();
        env.advice.reminderScript = adviceEvents(['Check the tin.']);
        largeText(tester);
        await pumpKernelApp(tester, env);
        await tapVisible(tester, find.byKey(Key('remind-${tin.id}')));
        expect(tester.takeException(), isNull);
        expect(find.text(l.reminderSuggestedLabel), findsOneWidget);
        expect(find.byKey(const Key('reminder-wording')), findsOneWidget);
      });

      testWidgets('$code: settings assistant and narrative preview', (
        tester,
      ) async {
        final env = TestEnv(role: Role.farmer);
        await env.settings.setLanguageTag(code);
        await env.enableAdvice();
        env.advice.narrativeScript = adviceEvents(['A short draft.']);
        largeText(tester);
        await pumpKernelApp(tester, env, location: Routes.settings);
        expect(tester.takeException(), isNull);
        await scrollTo(tester, find.text(l.adviceStatusReady));
        expect(find.text(l.adviceStatusReady), findsOneWidget);

        routerOf(tester).go(Routes.reports);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const Key('ai-summary')));
        await tapVisible(tester, find.byKey(const Key('export-csv')));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('narrative-preview')), findsOneWidget);
        await tapVisible(tester, find.byKey(const Key('narrative-skip')));
      });
    }
  });
}

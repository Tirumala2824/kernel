// Pumps role selection and the result states in every shipped locale at
// 200% text to catch overflow from longer scripts and words.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/copy.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/l10n/app_localizations.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

const _proxyInfo = EngineInfo(
  modelPresent: true,
  modelVersion: 'proxy-1',
  experimental: true,
  targetSampleRate: 16000,
  effectiveSampleRate: 16000,
  delegate: InferenceDelegate.cpu,
  deviceModel: 'test-device',
  osVersion: 'test-os',
  modelNote: 'Experimental proxy model, not validated',
);

Future<TestEnv> _envIn(String code, {Role? role}) async {
  final env = TestEnv(role: role);
  await env.settings.setLanguageTag(code);
  return env;
}

void _largeText(WidgetTester tester) {
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    final code = locale.languageCode;
    final l = lookupAppLocalizations(locale);

    group('$code at 200% text', () {
      testWidgets('role selection', (tester) async {
        final env = await _envIn(code);
        _largeText(tester);
        await pumpKernelApp(tester, env);

        expect(tester.takeException(), isNull);
        expect(find.text(l.roleSelectTitle), findsOneWidget);
        for (final role in Role.values) {
          expect(find.text(role.title(l)), findsOneWidget, reason: role.name);
          expect(find.text(role.tagline(l)), findsOneWidget, reason: role.name);
        }
      });

      for (final role in Role.values) {
        testWidgets('${role.name} home and bottom navigation', (tester) async {
          final env = await _envIn(code, role: role);
          await env.addItem(role: role, label: 'A long label for scaling');
          _largeText(tester);
          await pumpKernelApp(tester, env);

          expect(tester.takeException(), isNull);
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(find.text(l.navHome), findsWidgets);
        });
      }

      testWidgets('RETRY result', (tester) async {
        final env = await _envIn(code, role: Role.farmer);
        final item = await env.addItem(label: 'R-004');
        final scan = await env.scans.record(
          retryOutcome(
            item.id,
            reasons: const [QualityReason.highNoise, QualityReason.clipping],
          ),
        );
        _largeText(tester);
        await pumpKernelApp(
          tester,
          env,
          location: Routes.result(item.id, scan.id),
        );

        expect(tester.takeException(), isNull);
        expect(find.text(l.headlineRetry), findsOneWidget);
        expect(
          find.text(QualityReason.highNoise.explanation(l)),
          findsOneWidget,
        );
        expect(find.byKey(const Key('retry')), findsOneWidget);
        expect(find.text(l.provenanceNone), findsWidgets);
      });

      testWidgets('NOT_EVALUATED result', (tester) async {
        final env = await _envIn(code, role: Role.household);
        final item = await env.addItem(role: Role.household, label: 'Tin 1');
        final scan = await env.scans.record(notEvaluatedOutcome(item.id));
        _largeText(tester);
        await pumpKernelApp(
          tester,
          env,
          location: Routes.result(item.id, scan.id),
        );

        expect(tester.takeException(), isNull);
        expect(find.text(l.headlineNotEvaluated), findsOneWidget);
        expect(find.text(l.provenanceNone), findsWidgets);
        expect(find.text(l.physicalInspectionNote), findsOneWidget);
      });

      testWidgets('model results (inspection needed, no signal)', (
        tester,
      ) async {
        final env = await _envIn(code, role: Role.buyer);
        env.engine.engineInfo = _proxyInfo;
        final item = await env.addItem(role: Role.buyer, label: 'LOT-1 / 7');
        final uncertain = await env.scans.record(
          modelOutcome(item.id, Classification.uncertain),
        );
        final clean = await env.scans.record(
          modelOutcome(item.id, Classification.clean),
        );
        _largeText(tester);

        await pumpKernelApp(
          tester,
          env,
          location: Routes.result(item.id, uncertain.id),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(l.headlineInspectionNeeded), findsOneWidget);
        expect(find.text(l.provenanceExperimental('proxy-1')), findsWidgets);
        expect(find.text(l.experimentalBadge), findsWidgets);

        routerOf(tester).go(Routes.result(item.id, clean.id));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(l.headlineClean), findsOneWidget);
        expect(find.text(l.physicalInspectionNote), findsOneWidget);
      });
    });
  }
}

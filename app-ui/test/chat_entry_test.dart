import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kernel_app/app/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/router.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/chat/chat_copy.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

Future<void> pumpActualLaunch(WidgetTester tester, TestEnv env) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(overrides: env.overrides, child: const KernelApp()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('operational chat shortcut uses the notebook label', (
    tester,
  ) async {
    await pumpKernelApp(tester, TestEnv(role: Role.farmer));
    final button = tester.widget<IconButton>(
      find.byKey(const Key('open-chat')),
    );
    expect(button.tooltip, ChatCopy.title);
    expect((button.icon as Icon).icon, Icons.chat_bubble_outline_rounded);
    await tester.tap(find.byKey(const Key('open-chat')));
    await tester.pumpAndSettle();
    expect(find.text(ChatCopy.emptyTitle), findsOneWidget);
  });

  testWidgets('cold operational deep link survives settings loading', (
    tester,
  ) async {
    final env = TestEnv(role: Role.farmer);
    final item = await env.addItem(label: 'Cold-link target');
    tester.platformDispatcher.defaultRouteNameTestValue = Routes.item(item.id);
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    final roles = StreamController<Role?>();
    addTearDown(roles.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides,
          activeRoleProvider.overrideWith((ref) => roles.stream),
        ],
        child: const KernelApp(),
      ),
    );
    await tester.pump();
    roles.add(Role.farmer);
    await tester.pumpAndSettle();
    expect(routerOf(tester).state.uri.path, Routes.item(item.id));
    expect(find.text('Cold-link target'), findsWidgets);
  });

  testWidgets('reminder waits for operational setup without hijacking chat', (
    tester,
  ) async {
    final env = TestEnv(onboardingDone: false);
    final item = await env.addItem(label: 'Deferred reminder');
    env.reminders.launchItemId = item.id;
    await pumpActualLaunch(tester, env);
    expect(find.text(ChatCopy.emptyTitle), findsOneWidget);
    expect(env.reminders.launchTakes, 0);
    await env.settings.setOnboardingDone(true);
    await env.settings.setActiveRole(Role.farmer);
    await tester.pumpAndSettle();
    expect(routerOf(tester).state.uri.path, Routes.item(item.id));
    expect(env.reminders.launchTakes, 1);
  });

  testWidgets('tools remain reachable and back preserves chat draft', (
    tester,
  ) async {
    final env = TestEnv(role: Role.farmer);
    await pumpActualLaunch(tester, env);
    await tester.enterText(find.byKey(const Key('chat-input')), 'unsent draft');
    await tester.tap(find.byTooltip(ChatCopy.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.tools));
    await tester.pumpAndSettle();
    expect(find.text('Farmer dashboard'), findsOneWidget);
    routerOf(tester).pop();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-input')))
          .controller!
          .text,
      'unsent draft',
    );
  });

  testWidgets('reminder launch still opens its real item', (tester) async {
    final env = TestEnv(role: Role.farmer);
    final item = await env.addItem(label: 'Real reminder target');
    env.reminders.launchItemId = item.id;
    await pumpActualLaunch(tester, env);
    expect(routerOf(tester).state.uri.path, Routes.item(item.id));
    expect(find.text('Real reminder target'), findsWidgets);
    expect(env.reminders.launchTakes, 1);
    routerOf(tester).go(Routes.home);
    await tester.pumpAndSettle();
    expect(env.reminders.launchTakes, 1);
  });
  testWidgets('fresh launch opens chat without choosing a role', (
    tester,
  ) async {
    final env = TestEnv(onboardingDone: false);
    await pumpActualLaunch(tester, env);
    expect(find.text(ChatCopy.emptyTitle), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(env.settings.roleWrites, isEmpty);
    expect(env.settings.onboardingDone, isFalse);
    expect(env.settings.localAdviceWrites, isEmpty);
  });

  test('chat and settings are independent of operational setup', () {
    for (final path in [Routes.chat, Routes.settings, Routes.models]) {
      expect(
        kernelRedirect(
          const AsyncData(null),
          Uri.parse(path),
          onboardingDone: const AsyncData(false),
        ),
        isNull,
      );
    }
    expect(
      kernelRedirect(
        const AsyncData(null),
        Uri.parse(Routes.home),
        onboardingDone: const AsyncData(false),
      ),
      Routes.onboarding,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/router.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  group('Onboarding (first launch)', () {
    testWidgets('three pages: privacy, how to scan, pick a role', (
      tester,
    ) async {
      final env = TestEnv(onboardingDone: false);
      await pumpKernelApp(tester, env);

      expect(find.byKey(const Key('onboarding-page-0')), findsOneWidget);
      expect(find.text(en.onboardingPrivacyTitle), findsOneWidget);
      expect(find.text(en.onboardingPrivacy2), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      expect(find.text(en.onboardingHowTitle), findsOneWidget);
      expect(find.text(en.onboardingHow1), findsOneWidget);
      expect(find.text(en.onboardingHow3), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      expect(find.text(en.onboardingRoleTitle), findsOneWidget);
      for (final role in Role.values) {
        expect(find.byKey(Key('role-${role.name}')), findsOneWidget);
      }
      // Nothing is saved until a role is picked.
      expect(env.settings.onboardingDone, isFalse);
      expect(env.settings.roleWrites, isEmpty);

      await tapVisible(tester, find.byKey(const Key('role-household')));
      expect(env.settings.activeRole, Role.household);
      expect(env.settings.onboardingDone, isTrue);
      expect(find.text(en.householdHomeTitle), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('skip jumps to the role page', (tester) async {
      final env = TestEnv(onboardingDone: false);
      await pumpKernelApp(tester, env);
      await tester.tap(find.byKey(const Key('onboarding-skip')));
      await tester.pumpAndSettle();
      expect(find.text(en.onboardingRoleTitle), findsOneWidget);
      expect(find.byKey(const Key('onboarding-skip')), findsNothing);
    });

    testWidgets('a returning user is not sent to onboarding', (tester) async {
      final env = TestEnv(role: Role.buyer);
      await pumpKernelApp(tester, env);
      expect(find.byKey(const Key('onboarding-page-0')), findsNothing);
      expect(find.text(en.buyerHomeTitle), findsOneWidget);
    });

    test('redirect sends unfinished onboarding to /onboarding', () {
      expect(
        kernelRedirect(
          const AsyncData(null),
          Uri.parse(Routes.home),
          onboardingDone: const AsyncData(false),
        ),
        Routes.onboarding,
      );
      expect(
        kernelRedirect(
          const AsyncData(Role.farmer),
          Uri.parse(Routes.onboarding),
          onboardingDone: const AsyncData(false),
        ),
        isNull,
      );
      expect(
        kernelRedirect(
          const AsyncData(Role.farmer),
          Uri.parse(Routes.onboarding),
          onboardingDone: const AsyncData(true),
        ),
        Routes.home,
      );
      expect(
        kernelRedirect(
          const AsyncData(Role.farmer),
          Uri.parse(Routes.home),
          onboardingDone: const AsyncLoading(),
        ),
        Routes.start,
      );
    });
  });
}

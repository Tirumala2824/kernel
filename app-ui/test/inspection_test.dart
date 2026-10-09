import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

void main() {
  group('Record inspection (F09)', () {
    testWidgets('AI prediction and verified finding are separate panels', (
      tester,
    ) async {
      final env = TestEnv(role: Role.storageFpo);
      final item = await env.addItem(role: Role.storageFpo, label: 'S-7');
      final scan = await env.scans.record(notEvaluatedOutcome(item.id));
      await pumpKernelApp(
        tester,
        env,
        location: Routes.inspect(item.id, scanId: scan.id),
      );

      final ai = find.byKey(const Key('ai-prediction-panel'));
      final verified = find.byKey(const Key('verified-finding-panel'));
      expect(ai, findsOneWidget);
      expect(verified, findsOneWidget);

      // The AI panel is read-only and labelled as unverified.
      expect(
        find.descendant(
          of: ai,
          matching: find.text('AI prediction (not verified)'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ai, matching: find.text('Not evaluated')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ai, matching: find.byType(InkWell)),
        findsNothing,
      );
      // Finding options live only in the verified panel.
      for (final f in VerifiedFinding.values) {
        final option = find.byKey(Key('finding-${f.name}'));
        expect(find.descendant(of: verified, matching: option), findsOneWidget);
        expect(find.descendant(of: ai, matching: option), findsNothing);
      }
      // Panels are styled differently.
      final aiBox = tester.widget<Container>(ai).decoration! as BoxDecoration;
      final verifiedBox =
          tester.widget<Container>(verified).decoration! as BoxDecoration;
      expect(aiBox.color, isNot(verifiedBox.color));
    });

    testWidgets('finding is never pre-filled and is required', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      final scan = await env.scans.record(notEvaluatedOutcome(item.id));
      await pumpKernelApp(
        tester,
        env,
        location: Routes.inspect(item.id, scanId: scan.id),
      );

      await tester.enterText(
        find.byKey(const Key('field-inspector')),
        'A. Kumar',
      );
      await tapVisible(tester, find.byKey(const Key('save')));

      expect(find.byKey(const Key('finding-missing')), findsOneWidget);
      expect(env.inspections.drafts, isEmpty);
    });

    testWidgets('saves the human finding separately from the scan', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      final scan = await env.scans.record(notEvaluatedOutcome(item.id));
      await pumpKernelApp(tester, env, location: Routes.item(item.id));
      // Open the form from a result-like path to keep a back stack.
      routerOf(tester).push(Routes.inspect(item.id, scanId: scan.id));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('finding-pestsFound')));
      await tester.enterText(
        find.byKey(const Key('field-inspector')),
        'A. Kumar',
      );
      await tester.enterText(
        find.byKey(const Key('field-observations')),
        'Live weevils near the seam',
      );
      await tapVisible(tester, find.byKey(const Key('follow-up-inProgress')));
      await tapVisible(tester, find.byKey(const Key('save')));

      final draft = env.inspections.drafts.single;
      expect(draft.itemId, item.id);
      expect(draft.scanId, scan.id);
      expect(draft.inspector, 'A. Kumar');
      expect(draft.observations, 'Live weevils near the seam');
      expect(draft.verifiedFinding, VerifiedFinding.pestsFound);
      expect(draft.followUpStatus, FollowUpStatus.inProgress);
      // The stored scan is untouched (append-only, prediction unchanged).
      expect(env.scans.scans.single.result, Classification.notEvaluated);

      // Back on the item detail, the inspection is listed as verified.
      expect(find.text('Verified finding: Pests found'), findsOneWidget);
    });

    testWidgets('no treatment or fumigation advice is offered', (tester) async {
      final env = TestEnv(role: Role.buyer);
      final item = await env.addItem(role: Role.buyer);
      await pumpKernelApp(tester, env, location: Routes.inspect(item.id));

      for (final word in [
        'fumigat',
        'pesticide',
        'treat',
        'Accept',
        'Reject',
      ]) {
        expect(
          find.textContaining(RegExp(word, caseSensitive: false)),
          findsNothing,
          reason: word,
        );
      }
      expect(
        find.text('No scan linked. This inspection stands on its own.'),
        findsOneWidget,
      );
    });
  });
}

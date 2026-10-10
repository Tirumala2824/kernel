import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

void main() {
  group('Inspection photos', () {
    testWidgets('photos are stored app-private and saved with the finding', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem(label: 'R-2');
      await pumpKernelApp(tester, env, location: Routes.item(item.id));
      routerOf(tester).push(Routes.inspect(item.id));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('photo-camera')));
      await tapVisible(tester, find.byKey(const Key('photo-gallery')));
      expect(env.photos.captured, [PhotoSource.camera, PhotoSource.gallery]);
      // The camera asks for permission first; the gallery does not.
      expect(find.byKey(const Key('photo-0')), findsOneWidget);
      expect(find.byKey(const Key('photo-1')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('finding-noneFound')));
      await tester.enterText(
        find.byKey(const Key('field-inspector')),
        'S. Rao',
      );
      await tapVisible(tester, find.byKey(const Key('save')));

      final draft = env.inspections.drafts.single;
      expect(draft.photoPaths, hasLength(2));
      expect(draft.photoPaths.first, contains('/inspection_photos/'));
      expect(env.photos.discarded, isEmpty);
      // Thumbnails show on the saved inspection.
      expect(find.byKey(const Key('photo-0')), findsOneWidget);
    });

    testWidgets('photos of an unsaved inspection are discarded', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      await pumpKernelApp(tester, env, location: Routes.item(item.id));
      routerOf(tester).push(Routes.inspect(item.id));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('photo-gallery')));
      routerOf(tester).pop();
      await tester.pumpAndSettle();
      expect(env.inspections.drafts, isEmpty);
      expect(env.photos.discarded, hasLength(1));
    });

    testWidgets('camera denied: no capture, explanation shown', (tester) async {
      final env = TestEnv(role: Role.farmer);
      env.permissions.camera = PermissionAccess.denied;
      final item = await env.addItem();
      await pumpKernelApp(tester, env, location: Routes.inspect(item.id));
      await tapVisible(tester, find.byKey(const Key('photo-camera')));
      expect(env.photos.captured, isEmpty);
      expect(find.text(en.cameraDeniedPhoto), findsOneWidget);
    });
  });

  group('Assigned inspections (FPO)', () {
    testWidgets('filter by assignee, assign, and update task status', (
      tester,
    ) async {
      final env = TestEnv(role: Role.storageFpo);
      final a = await env.addItem(role: Role.storageFpo, label: 'S-1');
      final b = await env.addItem(role: Role.storageFpo, label: 'S-2');
      final first = await env.addInspection(
        a.id,
        VerifiedFinding.inconclusive,
        assignedTo: 'Meena',
      );
      final second = await env.addInspection(b.id, VerifiedFinding.pestsFound);
      await pumpKernelApp(tester, env, location: Routes.assignedInspections);

      expect(find.byKey(Key('task-${first.id}')), findsOneWidget);
      expect(find.byKey(Key('task-${second.id}')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('filter-Meena')));
      expect(find.byKey(Key('task-${second.id}')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('filter-unassigned')));
      expect(find.byKey(Key('task-${first.id}')), findsNothing);
      expect(find.byKey(Key('task-${second.id}')), findsOneWidget);

      await tapVisible(tester, find.byKey(Key('assign-${second.id}')));
      await tester.enterText(find.byKey(const Key('prompt-field')), 'Ravi');
      await tapVisible(tester, find.byKey(const Key('prompt-ok')));
      expect(env.inspections.assignCalls.single, (second.id, 'Ravi'));
      // The finding is untouched by assignment.
      expect(
        env.inspections.inspections
            .singleWhere((i) => i.id == second.id)
            .verifiedFinding,
        VerifiedFinding.pestsFound,
      );

      await tapVisible(tester, find.byKey(const Key('filter-all')));
      await tapVisible(tester, find.byKey(Key('follow-up-menu-${first.id}')));
      await tapVisible(tester, find.text(en.followUpDone).last);
      expect(
        env.inspections.inspections
            .singleWhere((i) => i.id == first.id)
            .followUpStatus,
        FollowUpStatus.done,
      );
      // Done tasks leave the open list.
      expect(find.byKey(Key('task-${first.id}')), findsNothing);
    });

    testWidgets('FPO home links to assigned inspections and today', (
      tester,
    ) async {
      final env = TestEnv(role: Role.storageFpo);
      final a = await env.addItem(role: Role.storageFpo, label: 'S-1');
      await env.scans.record(notEvaluatedOutcome(a.id));
      await pumpKernelApp(tester, env);
      expect(find.text(en.scansTodayCount(1)), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('items-summary')));
      expect(find.text(en.scansTodayTitle), findsWidgets);
      expect(find.textContaining('S-1'), findsWidgets);
    });
  });
}

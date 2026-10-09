import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/app/rules.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  group('QR payload parser', () {
    test('accepts kernel:item:<itemId> only', () {
      expect(parseKernelItemPayload('kernel:item:item-42'), 'item-42');
      expect(
        parseKernelItemPayload(
          ' kernel:item:3f2b8c1e-9d4a-4c1e-8f00-1a2b3c4d5e6f\n',
        ),
        '3f2b8c1e-9d4a-4c1e-8f00-1a2b3c4d5e6f',
      );
      expect(parseKernelItemPayload('KERNEL:ITEM:abc'), 'abc');
      expect(kernelItemPayload('abc'), 'kernel:item:abc');
      expect(parseKernelItemPayload(kernelItemPayload('x_1.2')), 'x_1.2');
    });

    test('ignores anything else', () {
      for (final raw in [
        '',
        'kernel:item:',
        'kernel:lot:abc',
        'kernel:itemabc',
        'https://example.com/kernel:item:abc',
        'kernel:item:abc def',
        'kernel:item:abc/../x',
        'kernel:item:${'a' * 129}',
        'item:abc',
      ]) {
        expect(parseKernelItemPayload(raw), isNull, reason: raw);
      }
    });
  });

  group('QR screen', () {
    testWidgets('a Kernel label opens that sack', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem(label: 'R-77');
      env.qr.payloads = [kernelItemPayload(item.id)];
      await pumpKernelApp(tester, env, location: Routes.qr);

      await tapVisible(tester, find.byKey(const Key('qr-payload-0')));
      expect(find.text('R-77'), findsWidgets);
      expect(find.text(en.scanHistoryTitle), findsOneWidget);
    });

    testWidgets('other codes get a friendly message', (tester) async {
      final env = TestEnv(role: Role.farmer);
      env.qr.payloads = ['https://example.com/promo', 'kernel:item:missing'];
      await pumpKernelApp(tester, env, location: Routes.qr);

      await tapVisible(tester, find.byKey(const Key('qr-payload-0')));
      expect(find.text(en.qrNotKernel), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('qr-try-again')));
      await tapVisible(tester, find.byKey(const Key('qr-payload-1')));
      expect(find.text(en.qrUnknownItem), findsOneWidget);
      expect(find.text(en.scanHistoryTitle), findsNothing);
    });

    testWidgets('asks for the camera with a rationale first', (tester) async {
      final env = TestEnv(role: Role.farmer);
      env.permissions.camera = PermissionAccess.denied;
      await pumpKernelApp(tester, env, location: Routes.qr);

      expect(find.byKey(const Key('qr-rationale')), findsOneWidget);
      expect(find.text(en.qrRationaleBody), findsOneWidget);
      expect(env.permissions.cameraRequests, 0);

      await tapVisible(tester, find.byKey(const Key('qr-allow-camera')));
      expect(env.permissions.cameraRequests, 1);
      expect(find.text(en.qrCameraDenied), findsOneWidget);
    });

    testWidgets('app bar QR button opens the scanner', (tester) async {
      final env = TestEnv(role: Role.storageFpo);
      await pumpKernelApp(tester, env);
      await tapVisible(tester, find.byKey(const Key('open-qr')));
      expect(find.text(en.qrInstructions), findsOneWidget);
    });
  });

  group('Sack labels', () {
    testWidgets('print labels exports a sackLabels PDF and shares it', (
      tester,
    ) async {
      final env = TestEnv(role: Role.storageFpo);
      final room = await env.locations.create(
        const LocationDraft(type: LocationType.room, name: 'Room 3'),
      );
      await pumpKernelApp(tester, env, location: Routes.location(room.id));

      final button = find.byKey(const Key('export-sackLabels-pdf'));
      expect(find.byKey(const Key('export-sackLabels-csv')), findsNothing);
      await tapVisible(tester, button);
      final (scope, format) = env.reports.calls.single;
      expect(scope.kind, ReportKind.sackLabels);
      expect(scope.locationId, room.id);
      expect(format, ReportFormat.pdf);
      expect(env.sharer.shared, hasLength(1));
    });
  });
}

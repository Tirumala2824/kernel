import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/features/home/next_actions.dart';
import 'package:kernel_app/features/sensors/sensor_copy.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

const payload = 'kernel:sensor:v1:AABBCCDDEE01.6b6579';

/// Visible copy that would claim absence; never allowed for sensors.
final absenceClaim = RegExp(
  r'no pests|pest[- ]free|all clear|nothing (found|detected)|\bsafe\b',
  caseSensitive: false,
);

List<String> allText(WidgetTester tester) => [
  for (final w in tester.widgetList<Text>(find.byType(Text)))
    w.data ?? w.textSpan?.toPlainText() ?? '',
];

Finder textContaining(String part) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? w.textSpan?.toPlainText() ?? '').contains(part),
);

SensorStatus status(
  String nodeId,
  Set<SensorHealth> health, {
  SensorLinkState link = SensorLinkState.authenticated,
  int? battery = 64,
}) => SensorStatus(
  nodeId: nodeId,
  linkState: link,
  health: health,
  batteryPercent: battery,
);

void main() {
  group('sensor QR payload', () {
    test('accepts kernel:sensor:v1:... only', () {
      expect(parseSensorQrPayload(payload), payload);
      expect(parseSensorQrPayload('  $payload\n'), payload);
      expect(
        parseSensorQrPayload('KERNEL:SENSOR:V1:abc'),
        'KERNEL:SENSOR:V1:abc',
      );
      for (final raw in [
        '',
        'kernel:sensor:v1:',
        'kernel:sensor:v2:abc',
        'kernel:item:abc',
        'kernel:sensor:v1:ab cd',
        'https://example.com/kernel:sensor:v1:abc',
      ]) {
        expect(parseSensorQrPayload(raw), isNull, reason: raw);
      }
    });
  });

  group('pairing', () {
    testWidgets('scan, associate, save, then place on a sack', (tester) async {
      final env = TestEnv(role: Role.storageFpo);
      final room = await env.locations.create(
        const LocationDraft(type: LocationType.room, name: 'Room 2'),
      );
      final sack = await env.addItem(
        role: Role.storageFpo,
        label: 'S-17',
        locationId: room.id,
      );
      final node = testNode(id: 'node-1', name: 'US node 1');
      env.sensorLink.associateResult = node;
      env.qr.payloads = ['https://example.com/promo', payload];
      await pumpKernelApp(tester, env, location: Routes.sensors);
      await tapVisible(
        tester,
        find.descendant(
          of: find.byKey(const Key('sensors-empty')),
          matching: find.byType(FilledButton),
        ),
      );

      // Not a sensor label: friendly message, nothing associated.
      await tapVisible(tester, find.byKey(const Key('qr-payload-0')));
      expect(find.text(en.sensorPairNotSensor), findsOneWidget);
      expect(env.sensorLink.associatePayloads, isEmpty);
      await tapVisible(tester, find.byKey(const Key('sensor-pair-again')));

      await tapVisible(tester, find.byKey(const Key('qr-payload-1')));
      expect(env.sensorLink.associatePayloads, [payload]);
      expect(env.sensorNodes['node-1'], isNotNull, reason: 'node saved');
      // The payload (which holds the key) is never shown.
      expect(textContaining('6b6579'), findsNothing);

      // Placement through the existing location and item lists.
      expect(find.text(en.sensorPlaceTitle), findsWidgets);
      await tapVisible(tester, find.byKey(const Key('sensor-place-location')));
      await tapVisible(
        tester,
        find.text(en.nameWithType('Room 2', en.locationTypeRoom)).last,
      );
      await tapVisible(tester, find.byKey(const Key('sensor-place-item')));
      await tapVisible(
        tester,
        find.text(en.nameWithType('S-17', 'Wheat')).last,
      );
      await tapVisible(tester, find.byKey(const Key('sensor-place-save')));

      expect(env.sensorNodes.placements, hasLength(1));
      final (id, placement) = env.sensorNodes.placements.single;
      expect(id, 'node-1');
      expect(placement.locationId, room.id);
      expect(placement.itemId, sack.id);
      expect(find.byKey(const Key('sensor-node-node-1')), findsOneWidget);
    });

    testWidgets('a cancelled pairing saves nothing', (tester) async {
      final env = TestEnv(role: Role.farmer);
      env.qr.payloads = [payload];
      await pumpKernelApp(tester, env, location: Routes.sensorPair);
      await tapVisible(tester, find.byKey(const Key('qr-payload-0')));

      expect(env.sensorLink.associatePayloads, [payload]);
      expect(find.text(en.sensorPairCancelled), findsOneWidget);
      expect(env.sensorNodes.placements, isEmpty);
      expect(await env.sensorNodes.watchAll().first, isEmpty);
    });

    testWidgets('camera denied shows the rationale, not the scanner', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      env.permissions.camera = PermissionAccess.denied;
      await pumpKernelApp(tester, env, location: Routes.sensorPair);
      expect(find.byKey(const Key('sensor-pair-rationale')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('sensor-pair-allow-camera')),
      );
      expect(env.permissions.cameraRequests, 1);
      expect(find.text(en.qrCameraDenied), findsOneWidget);
    });
  });

  group('node list', () {
    testWidgets('empty state has one next action', (tester) async {
      await pumpKernelApp(
        tester,
        TestEnv(role: Role.farmer),
        location: Routes.sensors,
      );
      expect(find.text(en.sensorEmpty), findsOneWidget);
      expect(find.text(en.sensorPairAction), findsOneWidget);
    });

    testWidgets('type, battery, link state and health chips', (tester) async {
      final env = TestEnv(role: Role.storageFpo);
      await env.sensorNodes.upsert(
        testNode(id: 'n1', name: 'Rafters', type: SensorType.usAir),
      );
      await env.sensorNodes.upsert(
        testNode(id: 'n2', name: 'Sack probe', type: SensorType.contactPiezo),
      );
      await env.sensorNodes.upsert(testNode(id: 'n3', name: 'Corner'));
      env.sensorLink
        ..setStatus(status('n1', {SensorHealth.jammed}))
        ..setStatus(status('n2', {SensorHealth.clipped}, battery: 9))
        ..setStatus(
          status('n3', {SensorHealth.surveyNeeded}, link: SensorLinkState.disconnected),
        );
      await pumpKernelApp(tester, env, location: Routes.sensors);

      expect(find.text(en.sensorTypeUsAir), findsNWidgets(2));
      expect(find.text(en.sensorTypeContactPiezo), findsOneWidget);
      expect(find.text(en.sensorBattery(64)), findsNWidgets(2));
      expect(find.text(en.sensorBattery(9)), findsOneWidget);
      expect(find.text(en.sensorLinkAuthenticated), findsNWidgets(2));
      expect(find.text(en.sensorLinkDisconnected), findsOneWidget);
      expect(
        en.sensorHealthJammed,
        'Jammed — ultrasonic source nearby (e.g. a repeller); results not '
        'evaluated',
      );
      expect(en.sensorHealthClipped, 'Clipped');
      expect(en.sensorHealthSurveyNeeded, 'Survey needed');
      expect(find.text(en.sensorHealthJammed), findsOneWidget);
      expect(find.text(en.sensorHealthClipped), findsOneWidget);
      expect(find.text(en.sensorHealthSurveyNeeded), findsOneWidget);
      for (final id in ['n1', 'n2', 'n3']) {
        expect(
          find.byKey(Key('sensor-not-evaluated-$id')),
          findsOneWidget,
          reason: 'jammed, clipped and survey-needed are not evaluated',
        );
      }
      expect(find.text(en.sensorNotEvaluatedBody), findsNWidgets(3));
      for (final text in allText(tester)) {
        expect(absenceClaim.hasMatch(text), isFalse, reason: text);
      }
    });

    testWidgets('a working node says the sensor works, not that grain is', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await env.sensorNodes.upsert(testNode(id: 'ok'));
      env.sensorLink.setStatus(status('ok', {SensorHealth.ok}));
      await pumpKernelApp(tester, env, location: Routes.sensors);
      expect(find.text(en.sensorHealthOk), findsOneWidget);
      expect(find.byKey(const Key('sensor-not-evaluated-ok')), findsNothing);
      for (final text in allText(tester)) {
        expect(absenceClaim.hasMatch(text), isFalse, reason: text);
      }
    });
  });

  group('node detail', () {
    Future<TestEnv> detailEnv() async {
      final env = TestEnv(role: Role.storageFpo);
      await env.sensorNodes.upsert(testNode(id: 'n1', name: 'Rafters'));
      env.sensorLink.setStatus(status('n1', {SensorHealth.ok}));
      return env;
    }

    testWidgets('live bands show range and level in words', (tester) async {
      final env = await detailEnv();
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      expect(find.byKey(const Key('sensor-live-waiting')), findsOneWidget);

      env.sensorLink.setBands(
        BandFrame(
          nodeId: 'n1',
          seq: 1,
          at: DateTime(2026, 10, 1),
          frameMs: 250,
          noiseFloorDbfs: -80,
          bandEdgesHz: const [20000, 30000, 45000, 60000],
          bandsDbAboveFloor: const [3, 12.4, 0],
          peakHz: 38500,
          peakDbfs: -52,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.sensorBandRange('20.0', '30.0')), findsOneWidget);
      expect(find.text(en.sensorBandRange('45.0', '60.0')), findsOneWidget);
      expect(find.text(en.sensorBandLevel('12')), findsOneWidget);
      expect(find.text(en.sensorBandLevel('0')), findsOneWidget);
      expect(find.text(en.sensorLivePeak('38.5')), findsOneWidget);
    });

    testWidgets('survey runs for 5 minutes with progress', (tester) async {
      final env = await detailEnv();
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      await tapVisible(tester, find.byKey(const Key('sensor-survey-start')));
      expect(env.sensorLink.surveys, [('n1', const Duration(minutes: 5))]);

      Text status() =>
          tester.widget<Text>(find.byKey(const Key('sensor-survey-status')));
      expect(status().data, en.sensorSurveyRunning(0, 5));
      await tester.pump(const Duration(minutes: 2));
      expect(status().data, en.sensorSurveyRunning(2, 5));
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('sensor-survey-progress')),
      );
      expect(bar.value, closeTo(0.4, 0.01));
      await tester.pump(const Duration(minutes: 3));
      expect(status().data, en.sensorSurveyDone);
    });

    testWidgets('overnight session explains the notification and battery', (
      tester,
    ) async {
      final env = await detailEnv();
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      expect(textContaining('notification'), findsWidgets);
      expect(textContaining('battery optimisation'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('sensor-session-start')));
      expect(env.permissions.notificationRequests, 1);
      expect(env.sensorLink.sessionsStarted, ['n1']);
      expect(find.byKey(const Key('sensor-session-running')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('sensor-session-stop')));
      expect(env.sensorLink.sessionsStopped, ['n1']);
      expect(find.byKey(const Key('sensor-session-running')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('sensor-battery-settings')));
      expect(env.permissions.settingsOpened, 1);
    });

    testWidgets('sync records events; timeline says N events in M minutes', (
      tester,
    ) async {
      final env = await detailEnv();
      final t0 = DateTime.now().subtract(const Duration(hours: 1));
      env.sensorLink.toSync = [
        testEvent('n1', 1, at: t0),
        testEvent('n1', 2, at: t0.add(const Duration(minutes: 4))),
        testEvent('n1', 3, at: t0.add(const Duration(minutes: 9, seconds: 30))),
        testEvent(
          'n1',
          4,
          at: t0.add(const Duration(minutes: 2)),
          signatureId: null,
          eventClass: SensorEventClass.impulseBurst,
        ),
      ];
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      expect(find.byKey(const Key('sensor-timeline-empty')), findsOneWidget);
      expect(find.text(en.sensorTimelineEmptyDetail), findsOneWidget);

      await tapVisible(
        tester,
        find.descendant(
          of: find.byKey(const Key('sensor-timeline-empty')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(env.sensorLink.syncCalls, ['n1']);
      expect(find.text(en.sensorSynced(4)), findsOneWidget);
      expect(env.sensorEvents.all, hasLength(4), reason: 'recorded');

      // 3 mouse-like events from t0 to t0+9:30 (+120 ms) -> 10 minutes.
      expect(en.sensorEventsSummary(3, 10), '3 events in 10 minutes');
      expect(en.sensorEventsSummary(1, 1), '1 event in 1 minute');
      final summary = find.byKey(const Key('sensor-summary-mouse_usv'));
      expect(
        find.descendant(of: summary, matching: find.text(en.sensorSigMouseUsv)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: summary,
          matching: find.text(en.sensorEventsSummary(3, 10)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: summary, matching: find.text(en.experimentalBadge)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('sensor-summary-unmatched')),
          matching: find.text(en.sensorEventsSummary(1, 1)),
        ),
        findsOneWidget,
      );
      expect(find.text(en.sensorSignalNotDiagnosis), findsOneWidget);
      // Each event in the timeline is marked experimental too.
      expect(find.byKey(const Key('sensor-event-n1-3')), findsOneWidget);
      expect(find.text(en.experimentalBadge), findsNWidgets(6));
      expect(find.text(en.sensorScore('0.71')), findsNWidgets(3));

      // Syncing again is idempotent on (nodeId, seq).
      await tapVisible(tester, find.byKey(const Key('sensor-sync')));
      expect(env.sensorEvents.all, hasLength(4));
      for (final text in allText(tester)) {
        expect(absenceClaim.hasMatch(text), isFalse, reason: text);
      }
    });

    testWidgets('jammed node: not evaluated, never "nothing there"', (
      tester,
    ) async {
      final env = await detailEnv();
      env.sensorLink.setStatus(status('n1', {SensorHealth.jammed}));
      await pumpKernelApp(tester, env, location: Routes.sensor('n1'));
      expect(find.byKey(const Key('sensor-not-evaluated-n1')), findsOneWidget);
      expect(find.text(en.sensorHealthJammed), findsOneWidget);
      for (final text in allText(tester)) {
        expect(absenceClaim.hasMatch(text), isFalse, reason: text);
      }
    });
  });

  group('item Sensor evidence', () {
    testWidgets('shown in its own section, separate from scans', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final sack = await env.addItem(label: 'R-9');
      await env.sensorNodes.upsert(
        testNode(id: 'n1', name: 'Probe 1', itemId: sack.id),
      );
      env.sensorLink.setStatus(status('n1', {SensorHealth.ok}));
      final now = DateTime.now();
      await env.sensorEvents.record([
        testEvent('n1', 1, at: now.subtract(const Duration(minutes: 30))),
        testEvent('n1', 2, at: now.subtract(const Duration(minutes: 25))),
      ]);
      await pumpKernelApp(tester, env, location: Routes.item(sack.id));

      final evidence = find.byKey(const Key('sensor-evidence'));
      expect(evidence, findsOneWidget);
      expect(
        find.descendant(of: evidence, matching: find.text(en.sensorEvidenceTitle)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: evidence,
          matching: find.text(en.sensorEventsSummary(2, 5)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: evidence, matching: find.text(en.experimentalBadge)),
        findsWidgets,
      );
      // Scan history stays its own section, without sensor content, and no
      // scan record was created or changed.
      expect(
        find.descendant(of: evidence, matching: find.text(en.scanHistoryTitle)),
        findsNothing,
      );
      expect(find.text(en.scanHistoryTitle), findsOneWidget);
      expect(await env.scans.watchForItem(sack.id).first, isEmpty);
      for (final text in allText(tester)) {
        expect(absenceClaim.hasMatch(text), isFalse, reason: text);
      }

      await tapVisible(tester, find.byKey(const Key('sensor-evidence-open-n1')));
      expect(find.text(en.sensorLiveTitle), findsWidgets);
    });

    testWidgets('a placed node with no events says it is not proof', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final sack = await env.addItem(label: 'R-10');
      await env.sensorNodes.upsert(testNode(id: 'n1', itemId: sack.id));
      await pumpKernelApp(tester, env, location: Routes.item(sack.id));
      expect(find.byKey(const Key('sensor-evidence-empty')), findsOneWidget);
      expect(find.text(en.sensorEvidenceEmpty(7)), findsOneWidget);
    });

    testWidgets('no section without sensors', (tester) async {
      final env = TestEnv(role: Role.farmer);
      final sack = await env.addItem(label: 'R-11');
      await pumpKernelApp(tester, env, location: Routes.item(sack.id));
      expect(find.byKey(const Key('sensor-evidence')), findsNothing);
      expect(find.text(en.scanHistoryTitle), findsOneWidget);
    });
  });

  group('next actions', () {
    test('sensor kinds lead to sensors, with not-evaluated wording', () {
      final attention = describeNextAction(
        en,
        Role.storageFpo,
        const NextAction(
          kind: NextActionKind.sensorNeedsAttention,
          priority: 0,
          count: 2,
        ),
      );
      expect(attention.location, Routes.sensors);
      expect(attention.title, en.sensorNextAttentionMany(2));
      expect(attention.subtitle, contains('not evaluated'));

      final activity = describeNextAction(
        en,
        Role.farmer,
        const NextAction(
          kind: NextActionKind.sensorActivity,
          priority: 0,
          itemId: 'item-1',
          label: 'R-9',
        ),
      );
      expect(activity.location, Routes.item('item-1'));
      expect(activity.title, en.sensorNextActivityOne('R-9'));
      expect(absenceClaim.hasMatch(activity.subtitle), isFalse);
    });
  });
}

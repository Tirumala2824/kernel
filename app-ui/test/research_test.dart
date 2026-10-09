import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/app/rules.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';
import 'support/in_memory.dart';

Inspection _insp(VerifiedFinding finding, {String id = 'i1'}) => Inspection(
  id: id,
  itemId: 'item',
  scanId: null,
  inspectedAt: DateTime(2026, 10, 1),
  inspector: 'A',
  observations: '',
  verifiedFinding: finding,
  followUpStatus: FollowUpStatus.done,
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  syncState: SyncState.localOnly,
);

bool _enabled(WidgetTester tester, SampleLabel label) =>
    tester.widget<InkWell>(find.byKey(Key('label-${label.name}'))).onTap !=
    null;

void main() {
  group('Research label rule', () {
    test('unknown only when no inspection agrees', () {
      expect(allowedSampleLabels(const []), {SampleLabel.unknown});
      expect(
        allowedSampleLabels([_insp(VerifiedFinding.inconclusive)]),
        {SampleLabel.unknown},
      );
      expect(
        allowedSampleLabels([_insp(VerifiedFinding.noneFound)]),
        {SampleLabel.unknown, SampleLabel.clean},
      );
      expect(
        allowedSampleLabels([
          _insp(VerifiedFinding.noneFound),
          _insp(VerifiedFinding.pestsFound, id: 'i2'),
        ]),
        SampleLabel.values.toSet(),
      );
    });

    test('a label needs evidence with the matching finding', () {
      final none = _insp(VerifiedFinding.noneFound);
      final pests = _insp(VerifiedFinding.pestsFound);
      expect(sampleLabelSupported(SampleLabel.unknown, null), isTrue);
      expect(sampleLabelSupported(SampleLabel.clean, none), isTrue);
      expect(sampleLabelSupported(SampleLabel.clean, pests), isFalse);
      expect(sampleLabelSupported(SampleLabel.clean, null), isFalse);
      expect(sampleLabelSupported(SampleLabel.infested, pests), isTrue);
      expect(sampleLabelSupported(SampleLabel.infested, none), isFalse);
    });
  });

  group('Research recording flow', () {
    testWidgets('records with retainAudio, then only unknown is allowed', (
      tester,
    ) async {
      final env = TestEnv(role: Role.storageFpo);
      await env.settings.setResearchModeOptIn(true);
      final item = await env.addItem(role: Role.storageFpo, label: 'S-9');
      await env.addInspection(item.id, VerifiedFinding.inconclusive);
      await pumpKernelApp(tester, env, location: Routes.item(item.id));

      await tapVisible(tester, find.byKey(const Key('action-research')));
      expect(find.text(en.researchScanNoticeTitle), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('start-capture')));

      // Research capture always keeps the audio.
      expect(env.engine.calls.single.retainAudio, isTrue);
      expect(find.text(en.labelSampleTitle), findsWidgets);
      expect(_enabled(tester, SampleLabel.unknown), isTrue);
      expect(_enabled(tester, SampleLabel.clean), isFalse);
      expect(_enabled(tester, SampleLabel.infested), isFalse);
      expect(find.text(en.labelCleanNeedsInspection), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('save')));
      final sample = env.samples.samples.single;
      expect(sample.label, SampleLabel.unknown);
      expect(sample.inspectionId, isNull);
      expect(sample.scanId, env.scans.scans.single.id);
    });

    testWidgets('clean is allowed with an agreeing inspection', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await env.settings.setResearchModeOptIn(true);
      final item = await env.addItem(label: 'R-3');
      final ok = await env.addInspection(item.id, VerifiedFinding.noneFound);
      final scan = await env.scans.record(
        notEvaluatedOutcome(item.id, retained: true),
      );
      await pumpKernelApp(
        tester,
        env,
        location: Routes.labelSample(item.id, scan.id),
      );

      expect(_enabled(tester, SampleLabel.clean), isTrue);
      expect(_enabled(tester, SampleLabel.infested), isFalse);
      await tapVisible(tester, find.byKey(const Key('label-clean')));
      expect(find.byKey(Key('evidence-${ok.id}')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('save')));

      final sample = env.samples.samples.single;
      expect(sample.label, SampleLabel.clean);
      expect(sample.inspectionId, ok.id);
    });

    testWidgets('unusable or not-kept recordings cannot be labelled', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      final item = await env.addItem();
      final scan = await env.scans.record(retryOutcome(item.id));
      await pumpKernelApp(
        tester,
        env,
        location: Routes.labelSample(item.id, scan.id),
      );
      expect(find.byKey(const Key('sample-unusable')), findsOneWidget);
      expect(find.byKey(const Key('save')), findsNothing);
    });

    testWidgets('samples list counts labels and exports the dataset', (
      tester,
    ) async {
      final env = TestEnv(role: Role.farmer);
      await env.settings.setResearchModeOptIn(true);
      final item = await env.addItem();
      final scan = await env.scans.record(
        notEvaluatedOutcome(item.id, retained: true),
      );
      await env.samples.create(
        LabeledSampleDraft(
          scanId: scan.id,
          label: SampleLabel.unknown,
          grainType: 'Wheat',
        ),
      );
      await pumpKernelApp(tester, env, location: Routes.researchSamples);

      expect(
        find.descendant(
          of: find.byKey(const Key('count-unknown')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('count-clean')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('export-dataset')));
      expect(env.dataset.calls, 1);
      expect(env.sharer.shared.single, endsWith('dataset.zip'));
    });

    testWidgets('turning research mode on asks for consent', (tester) async {
      final env = TestEnv(role: Role.farmer);
      await pumpKernelApp(tester, env, location: Routes.settings);

      await tapVisible(tester, find.byKey(const Key('research-toggle')));
      expect(find.text(en.researchConsentTitle), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('confirm-cancel')));
      expect(env.settings.researchMode, isFalse);

      await tapVisible(tester, find.byKey(const Key('research-toggle')));
      await tapVisible(tester, find.byKey(const Key('confirm-ok')));
      expect(env.settings.researchMode, isTrue);
      expect(find.byKey(const Key('open-samples')), findsOneWidget);
    });
  });
}

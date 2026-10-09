import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late GrainItem item;
  late GrainItem otherItem;
  late ScanRecord retained;

  setUp(() async {
    h = await Harness.create();
    item = await h.addItem(label: 'Sack R-001');
    otherItem = await h.addItem(label: 'Sack R-002');
    retained = await h.recordScan(item.id, audioRetained: true);
    await h.ops.settings.setResearchModeOptIn(true);
  });
  tearDown(() => h.dispose());

  LabeledSampleDraft draft(
    SampleLabel label, {
    String? scanId,
    String? inspectionId,
    String grainType = 'Wheat',
  }) => LabeledSampleDraft(
    scanId: scanId ?? retained.id,
    label: label,
    inspectionId: inspectionId,
    grainType: grainType,
    sackMaterial: ' jute ',
    environment: 'quiet room',
    notes: '',
  );

  Matcher argumentError(String messagePart) => throwsA(
    isA<ArgumentError>().having(
      (e) => '${e.message}',
      'message',
      contains(messagePart),
    ),
  );

  test('clean needs a no-pests inspection of the same item; the sample keeps '
      'its fields', () async {
    final inspection = await h.addInspection(
      item.id,
      VerifiedFinding.noneFound,
      scanId: retained.id,
    );
    final sample = await h.ops.labeledSamples.create(
      draft(SampleLabel.clean, inspectionId: inspection.id),
    );
    expect(sample.id, isUuid);
    expect(sample.scanId, retained.id);
    expect(sample.itemId, item.id, reason: 'taken from the scan');
    expect(sample.label, SampleLabel.clean);
    expect(sample.inspectionId, inspection.id);
    expect(sample.grainType, 'Wheat');
    expect(sample.sackMaterial, 'jute');
    expect(sample.environment, 'quiet room');
    expect(sample.notes, isNull);
    expect(sample.createdAt, h.clock.now);
    expect(sample.syncState, SyncState.localOnly);
    expect((await h.ops.labeledSamples.watchAll().first).single.id, sample.id);
  });

  test('infested needs a pests-found inspection; unknown needs none', () async {
    final pests = await h.addInspection(item.id, VerifiedFinding.pestsFound);
    final infested = await h.ops.labeledSamples.create(
      draft(SampleLabel.infested, inspectionId: pests.id),
    );
    expect(infested.label, SampleLabel.infested);

    final second = await h.recordScan(
      item.id,
      minutesAgo: 1,
      audioRetained: true,
    );
    h.clock.advance(const Duration(seconds: 1));
    final unknown = await h.ops.labeledSamples.create(
      draft(SampleLabel.unknown, scanId: second.id),
    );
    expect(unknown.inspectionId, isNull);

    // A RETRY recording can still be kept as unknown.
    final retry = await h.recordScan(
      item.id,
      minutesAgo: 2,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.highNoise],
      audioRetained: true,
    );
    h.clock.advance(const Duration(seconds: 1));
    final retryUnknown = await h.ops.labeledSamples.create(
      draft(SampleLabel.unknown, scanId: retry.id),
    );

    // Oldest first.
    final all = await h.ops.labeledSamples.watchAll().first;
    expect(all.map((s) => s.id), [infested.id, unknown.id, retryUnknown.id]);
  });

  test('rejected while the research opt-in is off (the default)', () async {
    await h.ops.settings.setResearchModeOptIn(false);
    await expectLater(
      h.ops.labeledSamples.create(draft(SampleLabel.unknown)),
      throwsStateError,
    );

    final fresh = await Harness.create();
    addTearDown(fresh.dispose);
    final sack = await fresh.addItem();
    final scan = await fresh.recordScan(sack.id, audioRetained: true);
    await expectLater(
      fresh.ops.labeledSamples.create(
        LabeledSampleDraft(
          scanId: scan.id,
          label: SampleLabel.unknown,
          grainType: 'Wheat',
        ),
      ),
      throwsStateError,
    );
    expect(await fresh.ops.labeledSamples.watchAll().first, isEmpty);
  });

  test('rejected for an unknown scan or one without retained audio', () async {
    await expectLater(
      h.ops.labeledSamples.create(draft(SampleLabel.unknown, scanId: 'nope')),
      argumentError('unknown scan'),
    );
    final notRetained = await h.recordScan(item.id, minutesAgo: 1);
    await expectLater(
      h.ops.labeledSamples.create(
        draft(SampleLabel.unknown, scanId: notRetained.id),
      ),
      argumentError('no retained audio'),
    );
  });

  test('clean/infested without an agreeing inspection are rejected', () async {
    final none = await h.addInspection(item.id, VerifiedFinding.noneFound);
    final pests = await h.addInspection(item.id, VerifiedFinding.pestsFound);
    final unsure = await h.addInspection(item.id, VerifiedFinding.inconclusive);
    final elsewhere = await h.addInspection(
      otherItem.id,
      VerifiedFinding.noneFound,
    );

    for (final label in [SampleLabel.clean, SampleLabel.infested]) {
      await expectLater(
        h.ops.labeledSamples.create(draft(label)),
        argumentError('needs an inspection'),
        reason: '$label without inspection',
      );
      await expectLater(
        h.ops.labeledSamples.create(draft(label, inspectionId: unsure.id)),
        argumentError('does not confirm'),
        reason: '$label with inconclusive',
      );
      await expectLater(
        h.ops.labeledSamples.create(draft(label, inspectionId: 'nope')),
        argumentError('unknown inspection'),
      );
    }
    await expectLater(
      h.ops.labeledSamples.create(
        draft(SampleLabel.clean, inspectionId: pests.id),
      ),
      argumentError('does not confirm'),
    );
    await expectLater(
      h.ops.labeledSamples.create(
        draft(SampleLabel.infested, inspectionId: none.id),
      ),
      argumentError('does not confirm'),
    );
    await expectLater(
      h.ops.labeledSamples.create(
        draft(SampleLabel.clean, inspectionId: elsewhere.id),
      ),
      argumentError('different item'),
    );
    // An optional inspection on unknown must still be for this item.
    await expectLater(
      h.ops.labeledSamples.create(
        draft(SampleLabel.unknown, inspectionId: elsewhere.id),
      ),
      argumentError('different item'),
    );
    expect(await h.ops.labeledSamples.watchAll().first, isEmpty);
  });

  test('a RETRY recording is never stored with a pest class', () async {
    final retry = await h.recordScan(
      item.id,
      minutesAgo: 1,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.silence],
      audioRetained: true,
    );
    final pests = await h.addInspection(item.id, VerifiedFinding.pestsFound);
    final none = await h.addInspection(item.id, VerifiedFinding.noneFound);
    await expectLater(
      h.ops.labeledSamples.create(
        draft(SampleLabel.infested, scanId: retry.id, inspectionId: pests.id),
      ),
      argumentError('RETRY'),
    );
    await expectLater(
      h.ops.labeledSamples.create(
        draft(SampleLabel.clean, scanId: retry.id, inspectionId: none.id),
      ),
      argumentError('RETRY'),
    );
  });

  test('one label per recording, and a blank grain type is rejected', () async {
    await expectLater(
      h.ops.labeledSamples.create(draft(SampleLabel.unknown, grainType: ' ')),
      throwsArgumentError,
    );
    await h.ops.labeledSamples.create(draft(SampleLabel.unknown));
    await expectLater(
      h.ops.labeledSamples.create(draft(SampleLabel.unknown)),
      throwsStateError,
    );
    expect(await h.ops.labeledSamples.watchAll().first, hasLength(1));
  });

  test('a label never changes the scan prediction or the inspection', () async {
    final pests = await h.addInspection(item.id, VerifiedFinding.pestsFound);
    await h.ops.labeledSamples.create(
      draft(SampleLabel.infested, inspectionId: pests.id),
    );
    final scan = await h.ops.scans.get(retained.id);
    expect(scan!.result, Classification.notEvaluated);
    final inspection =
        (await h.ops.inspections.watchForItem(item.id).first).single;
    expect(inspection.verifiedFinding, VerifiedFinding.pestsFound);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  test('activeRole is null until set, then streams changes', () async {
    final stream = h.ops.settings.watchActiveRole();
    expect(await stream.first, isNull);

    await h.ops.settings.setActiveRole(Role.storageFpo);
    expect(await firstWhere(stream, (r) => r != null), Role.storageFpo);

    await h.ops.settings.setActiveRole(Role.buyer);
    expect(await firstWhere(stream, (r) => r == Role.buyer), Role.buyer);
  });

  test('retainAudioOptIn defaults to false and can be toggled', () async {
    final stream = h.ops.settings.watchRetainAudioOptIn();
    expect(await stream.first, isFalse);

    await h.ops.settings.setRetainAudioOptIn(true);
    expect(await firstWhere(stream, (v) => v), isTrue);

    await h.ops.settings.setRetainAudioOptIn(false);
    expect(await firstWhere(stream, (v) => !v), isFalse);
  });

  test('switching role never deletes records', () async {
    await h.ops.settings.setActiveRole(Role.farmer);
    final sack = await h.addItem(role: Role.farmer, label: 'Sack');
    final bag = await h.addItem(role: Role.buyer, label: 'Sample bag');
    final tin = await h.addItem(role: Role.household, label: 'Tin');
    await h.recordScan(sack.id);
    await h.recordScan(bag.id);
    await h.ops.inspections.create(
      InspectionDraft(
        itemId: bag.id,
        inspectedAt: DateTime.utc(2026, 10, 1),
        inspector: 'Buyer QA',
        observations: '',
        verifiedFinding: VerifiedFinding.noneFound,
      ),
    );
    await h.ops.reminders.schedule(
      tin.id,
      h.clock.now.add(const Duration(days: 7)),
    );

    for (final role in [
      Role.buyer,
      Role.household,
      Role.storageFpo,
      Role.farmer,
    ]) {
      await h.ops.settings.setActiveRole(role);
    }

    expect(await h.ops.settings.watchActiveRole().first, Role.farmer);
    expect(
      (await h.ops.items.watchByRole(Role.farmer).first).single.id,
      sack.id,
    );
    expect((await h.ops.items.watchByRole(Role.buyer).first).single.id, bag.id);
    expect(
      (await h.ops.items.watchByRole(Role.household).first).single.id,
      tin.id,
    );
    expect(await h.ops.scans.watchRecent().first, hasLength(2));
    expect(await h.ops.inspections.watchForItem(bag.id).first, hasLength(1));
    expect(await h.ops.reminders.watchUpcoming().first, hasLength(1));
  });
}

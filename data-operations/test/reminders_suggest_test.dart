import 'package:data_operations/src/repositories/reminder_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late DateTime now;

  setUp(() async {
    h = await Harness.create();
    now = h.clock.now;
  });
  tearDown(() => h.dispose());

  /// 09:00 local on the local calendar day [days] after [from].
  DateTime nineAm(DateTime from, int days) {
    final local = from.toLocal();
    return DateTime(local.year, local.month, local.day + days, 9);
  }

  Future<DateTime> suggest(String itemId) =>
      h.ops.reminders.suggestDueAt(itemId);

  Future<GrainItem> itemStoredOn(DateTime storageDate) => h.ops.items.create(
    GrainItemDraft(
      ownerRole: Role.household,
      label: 'Old tin',
      grainType: 'Rice',
      quantity: 10,
      quantityUnit: 'kg',
      storageDate: storageDate,
    ),
  );

  test('never scanned, RETRY-only or not evaluated: tomorrow 09:00', () async {
    final never = await h.addItem(label: 'Never');
    final retry = await h.addItem(label: 'Retry');
    final notEvaluated = await h.addItem(label: 'NE');
    await h.recordScan(
      retry.id,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.silence],
    );
    await h.recordScan(notEvaluated.id);
    for (final item in [never, retry, notEvaluated]) {
      final due = await suggest(item.id);
      expect(due, nineAm(now, 1), reason: item.label);
      expect(due.isAfter(now), isTrue);
      expect(due.isUtc, isFalse);
    }
  });

  test('infested or uncertain: in 3 days at 09:00', () async {
    final infested = await h.addItem(label: 'I');
    final uncertain = await h.addItem(label: 'U');
    await h.recordModelScan(infested.id, Classification.infested);
    await h.recordModelScan(uncertain.id, Classification.uncertain);
    expect(await suggest(infested.id), nineAm(now, 3));
    expect(await suggest(uncertain.id), nineAm(now, 3));
  });

  test('clean: in 14 days, or 7 days once stored over 90 days', () async {
    final recent = await h.addItem(label: 'Recent'); // stored 2026-09-01
    await h.recordModelScan(recent.id, Classification.clean);
    expect(await suggest(recent.id), nineAm(now, 14));

    final at90 = await itemStoredOn(now.subtract(const Duration(days: 90)));
    await h.recordModelScan(at90.id, Classification.clean);
    expect(await suggest(at90.id), nineAm(now, 14));

    final old = await itemStoredOn(DateTime.utc(2026, 6, 1));
    await h.recordModelScan(old.id, Classification.clean);
    expect(await suggest(old.id), nineAm(now, 7));
  });

  test('the latest PASS scan decides; a later RETRY is ignored', () async {
    final item = await h.addItem();
    await h.recordModelScan(item.id, Classification.infested, minutesAgo: 60);
    await h.recordScan(
      item.id,
      minutesAgo: 10,
      quality: ScanQuality.retry,
      reasons: const [QualityReason.clipping],
    );
    expect(await suggest(item.id), nineAm(now, 3));

    await h.recordModelScan(item.id, Classification.clean, minutesAgo: 5);
    expect(await suggest(item.id), nineAm(now, 14));

    await h.recordScan(item.id); // PASS, no model
    expect(await suggest(item.id), nineAm(now, 1));
  });

  test('it never schedules or stores anything', () async {
    final item = await h.addItem();
    await suggest(item.id);
    expect(h.scheduler.scheduled, isEmpty);
    expect(await h.ops.reminders.watchForItem(item.id).first, isEmpty);
  });

  test('unknown or archived items are rejected', () async {
    expect(suggest('no-such-item'), throwsArgumentError);
    final item = await h.addItem();
    await h.ops.items.archive(item.id);
    expect(suggest(item.id), throwsArgumentError);
  });

  test('late in the day the suggestion is still after now', () async {
    final local = now.toLocal();
    h.clock.now = DateTime(local.year, local.month, local.day, 23, 59);
    final item = await h.addItem();
    final due = await suggest(item.id);
    expect(due, nineAm(h.clock.now, 1));
    expect(due.isAfter(h.clock.now), isTrue);
  });

  test('suggestedLocalTime rounds to 09:00 local and clamps to the '
      'future', () {
    final morning = DateTime(2026, 10, 1, 8);
    final noon = DateTime(2026, 10, 1, 12);
    expect(suggestedLocalTime(morning, 0), DateTime(2026, 10, 1, 9));
    expect(suggestedLocalTime(noon, 0), DateTime(2026, 10, 2, 9));
    expect(
      suggestedLocalTime(DateTime(2026, 10, 1, 9), 0),
      DateTime(2026, 10, 2, 9),
    );
    expect(suggestedLocalTime(noon, 3), DateTime(2026, 10, 4, 9));
    // Month and year boundaries.
    expect(
      suggestedLocalTime(DateTime(2026, 12, 30, 15), 14),
      DateTime(2027, 1, 13, 9),
    );
  });
}

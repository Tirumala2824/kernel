import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late GrainItem item;

  setUp(() async {
    h = await Harness.create();
    item = await h.addItem(role: Role.household, label: 'Rice tin');
  });
  tearDown(() => h.dispose());

  test(
    'schedule persists the reminder and hands it to the scheduler',
    () async {
      final upcoming = h.ops.reminders.watchUpcoming();
      expect(await upcoming.first, isEmpty);

      final due = h.clock.now.add(const Duration(days: 14));
      final reminder = await h.ops.reminders.schedule(item.id, due);
      expect(reminder.id, isUuid);
      expect(reminder.itemId, item.id);
      expect(reminder.dueAt, due);
      expect(reminder.status, ReminderStatus.scheduled);
      expect(reminder.syncState, SyncState.localOnly);

      final call = h.scheduler.scheduled.single;
      expect(call.reminderId, reminder.id);
      expect(call.itemId, item.id);
      expect(call.itemLabel, 'Rice tin');
      expect(call.dueAt, due);

      expect(
        (await firstWhere(upcoming, (l) => l.isNotEmpty)).single.id,
        reminder.id,
      );
      expect(
        (await h.ops.reminders.watchForItem(item.id).first).single.id,
        reminder.id,
      );
    },
  );

  test('each reminder gets its own notification id', () async {
    await h.ops.reminders.schedule(
      item.id,
      h.clock.now.add(const Duration(days: 1)),
    );
    await h.ops.reminders.schedule(
      item.id,
      h.clock.now.add(const Duration(days: 2)),
    );
    final ids = h.scheduler.scheduled.map((n) => n.notificationId).toSet();
    expect(ids, hasLength(2));
  });

  test('rejects past due dates and unknown items without scheduling', () async {
    expect(
      () => h.ops.reminders.schedule(
        item.id,
        h.clock.now.subtract(const Duration(minutes: 1)),
      ),
      throwsArgumentError,
    );
    expect(
      () => h.ops.reminders.schedule(item.id, h.clock.now),
      throwsArgumentError,
    );
    await expectLater(
      h.ops.reminders.schedule(
        'missing',
        h.clock.now.add(const Duration(days: 1)),
      ),
      throwsArgumentError,
    );
    expect(h.scheduler.scheduled, isEmpty);
    expect(await h.ops.reminders.watchForItem(item.id).first, isEmpty);
  });

  test('a scheduler failure leaves nothing persisted', () async {
    h.scheduler.failSchedulesWith = StateError('notifications unavailable');
    await expectLater(
      h.ops.reminders.schedule(
        item.id,
        h.clock.now.add(const Duration(days: 1)),
      ),
      throwsStateError,
    );
    expect(await h.ops.reminders.watchForItem(item.id).first, isEmpty);
  });

  test('cancel cancels the notification and leaves upcoming', () async {
    final reminder = await h.ops.reminders.schedule(
      item.id,
      h.clock.now.add(const Duration(days: 3)),
    );
    final notificationId = h.scheduler.scheduled.single.notificationId;

    await h.ops.reminders.cancel(reminder.id);
    expect(h.scheduler.cancelled, [notificationId]);
    expect(h.scheduler.pending, isEmpty);
    expect(await h.ops.reminders.watchUpcoming().first, isEmpty);
    final stored = (await h.ops.reminders.watchForItem(item.id).first).single;
    expect(stored.status, ReminderStatus.cancelled);

    // Idempotent; cancelled reminders cannot be completed.
    await h.ops.reminders.cancel(reminder.id);
    expect(h.scheduler.cancelled, [notificationId]);
    expect(() => h.ops.reminders.markDone(reminder.id), throwsStateError);
    expect(() => h.ops.reminders.cancel('missing'), throwsArgumentError);
  });

  test('markDone cancels the pending notification and completes it', () async {
    final reminder = await h.ops.reminders.schedule(
      item.id,
      h.clock.now.add(const Duration(days: 3)),
    );
    await h.ops.reminders.markDone(reminder.id);
    expect(h.scheduler.cancelled, [
      h.scheduler.scheduled.single.notificationId,
    ]);
    final stored = (await h.ops.reminders.watchForItem(item.id).first).single;
    expect(stored.status, ReminderStatus.done);
    expect(await h.ops.reminders.watchUpcoming().first, isEmpty);
    expect(() => h.ops.reminders.markDone('missing'), throwsArgumentError);
  });

  test(
    'restore marks past-due reminders fired and reschedules the rest',
    () async {
      final soon = await h.ops.reminders.schedule(
        item.id,
        h.clock.now.add(const Duration(hours: 1)),
      );
      final later = await h.ops.reminders.schedule(
        item.id,
        h.clock.now.add(const Duration(days: 10)),
      );
      h.scheduler.scheduled.clear();

      h.clock.advance(const Duration(hours: 2));
      await h.ops.restoreReminders();

      final byId = {
        for (final r in await h.ops.reminders.watchForItem(item.id).first)
          r.id: r,
      };
      expect(byId[soon.id]!.status, ReminderStatus.fired);
      expect(byId[later.id]!.status, ReminderStatus.scheduled);
      expect(h.scheduler.scheduled.map((n) => n.reminderId), [later.id]);

      // Fired reminders still need action, so they stay in upcoming.
      final upcoming = await h.ops.reminders.watchUpcoming().first;
      expect(upcoming.map((r) => r.id), [soon.id, later.id]);
    },
  );

  test(
    'reminders survive an app restart and are rescheduled on open',
    () async {
      final dir = await Directory.systemTemp.createTemp('kernel_db_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/kernel.sqlite');

      final first = await Harness.create(executor: NativeDatabase(file));
      final tin = await first.addItem(role: Role.household, label: 'Dal jar');
      final due = first.clock.now.add(const Duration(days: 5));
      final reminder = await first.ops.reminders.schedule(tin.id, due);
      final notificationId = first.scheduler.scheduled.single.notificationId;
      await first.dispose();

      final second = await Harness.create(executor: NativeDatabase(file));
      addTearDown(second.dispose);
      expect(second.scheduler.scheduled, isEmpty);
      await second.ops.restoreReminders();

      final restored = second.scheduler.scheduled.single;
      expect(restored.reminderId, reminder.id);
      expect(restored.notificationId, notificationId);
      expect(restored.dueAt, due);
      expect(restored.itemLabel, 'Dal jar');
    },
  );
}

import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../reminders/reminder_scheduler.dart';
import '../support.dart';

/// Reminders are persisted first and mirrored into the OS scheduler, so they
/// survive app restarts ([restore]) and, through the plugin's boot receiver,
/// device reboots.
class DriftReminderRepository implements ReminderRepository {
  DriftReminderRepository(this._db, this._scheduler, this._clock);

  final KernelDatabase _db;
  final ReminderScheduler _scheduler;
  final Clock _clock;

  static const _active = [ReminderStatus.scheduled, ReminderStatus.fired];

  /// Throws [ArgumentError] for an unknown item or a [dueAt] that is not in
  /// the future. If the OS scheduler fails, nothing is persisted.
  @override
  Future<Reminder> schedule(String itemId, DateTime dueAt) async {
    final due = dueAt.toUtc();
    final now = _clock().toUtc();
    if (!due.isAfter(now)) {
      throw ArgumentError.value(dueAt, 'dueAt', 'must be in the future');
    }
    return _db.transaction(() async {
      final item = await (_db.select(
        _db.items,
      )..where((i) => i.id.equals(itemId))).getSingleOrNull();
      if (item == null) {
        throw ArgumentError.value(itemId, 'itemId', 'unknown item');
      }
      final maxId = _db.reminders.notificationId.max();
      final current = await (_db.selectOnly(
        _db.reminders,
      )..addColumns([maxId])).map((row) => row.read(maxId)).getSingle();
      final row = await _db
          .into(_db.reminders)
          .insertReturning(
            RemindersCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              itemId: itemId,
              dueAt: due,
              status: ReminderStatus.scheduled,
              notificationId: (current ?? 0) + 1,
            ),
          );
      await _scheduler.schedule(_notificationFor(row, item.label));
      return row.toModel();
    });
  }

  /// Cancels a scheduled (or already fired) reminder. Done or cancelled
  /// reminders are left as they are.
  @override
  Future<void> cancel(String id) async {
    final row = await _require(id);
    if (!_active.contains(row.status)) return;
    await _scheduler.cancel(row.notificationId);
    await _setStatus(id, ReminderStatus.cancelled);
  }

  @override
  Future<void> markDone(String id) async {
    final row = await _require(id);
    switch (row.status) {
      case ReminderStatus.done:
        return;
      case ReminderStatus.cancelled:
        throw StateError('Reminder $id was cancelled and cannot be done');
      case ReminderStatus.scheduled || ReminderStatus.fired:
        await _scheduler.cancel(row.notificationId);
        await _setStatus(id, ReminderStatus.done);
    }
  }

  /// All reminders for the item, soonest first.
  @override
  Stream<List<Reminder>> watchForItem(String itemId) {
    final query = _db.select(_db.reminders)
      ..where((r) => r.itemId.equals(itemId))
      ..orderBy(_soonestFirst);
    return query.watch().map(_toModels);
  }

  /// Reminders still needing action (scheduled, or fired but not yet done),
  /// soonest first. Overdue ones stay in the list until done or cancelled.
  @override
  Stream<List<Reminder>> watchUpcoming() {
    final query = _db.select(_db.reminders)
      ..where((r) => r.status.isInValues(_active))
      ..orderBy(_soonestFirst);
    return query.watch().map(_toModels);
  }

  /// Re-syncs the OS scheduler with the database after an app start:
  /// future reminders are rescheduled (idempotent, same notification id) and
  /// past-due ones are marked fired.
  Future<void> restore() async {
    final now = _clock().toUtc();
    final query = _db.select(_db.reminders).join([
      innerJoin(_db.items, _db.items.id.equalsExp(_db.reminders.itemId)),
    ])..where(_db.reminders.status.equalsValue(ReminderStatus.scheduled));
    for (final joined in await query.get()) {
      final row = joined.readTable(_db.reminders);
      if (row.dueAt.isAfter(now)) {
        final label = joined.readTable(_db.items).label;
        await _scheduler.schedule(_notificationFor(row, label));
      } else {
        await _setStatus(row.id, ReminderStatus.fired);
      }
    }
  }

  /// Cancels every OS notification that belongs to an active reminder.
  /// Used by the history wipe before rows are deleted.
  Future<void> cancelAllNotifications() async {
    final rows = await (_db.select(
      _db.reminders,
    )..where((r) => r.status.isInValues(_active))).get();
    for (final row in rows) {
      await _scheduler.cancel(row.notificationId);
    }
  }

  Future<ReminderRow> _require(String id) async {
    final row = await (_db.select(
      _db.reminders,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw ArgumentError.value(id, 'id', 'unknown reminder');
    }
    return row;
  }

  Future<void> _setStatus(String id, ReminderStatus status) async {
    await (_db.update(_db.reminders)..where((r) => r.id.equals(id))).write(
      RemindersCompanion(
        status: Value(status),
        updatedAt: Value(_clock().toUtc()),
      ),
    );
  }

  static ReminderNotification _notificationFor(ReminderRow row, String label) =>
      ReminderNotification(
        notificationId: row.notificationId,
        reminderId: row.id,
        itemId: row.itemId,
        itemLabel: label,
        dueAt: row.dueAt,
      );

  static final _soonestFirst = <OrderClauseGenerator<$RemindersTable>>[
    (r) => OrderingTerm.asc(r.dueAt),
    (r) => OrderingTerm.asc(r.createdAt),
    (r) => OrderingTerm.asc(r.id),
  ];

  static List<Reminder> _toModels(List<ReminderRow> rows) => [
    for (final row in rows) row.toModel(),
  ];
}

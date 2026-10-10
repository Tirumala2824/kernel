import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../mappers.dart';
import '../reminders/reminder_scheduler.dart';
import '../support.dart';

/// Reminders are persisted first and mirrored into the OS scheduler, so they
/// survive app restarts ([restore]) and, through the plugin's boot receiver,
/// device reboots.
///
/// While an item is archived its reminders keep their stored status but
/// their OS notifications are cancelled, and they are hidden from
/// [watchUpcoming]. Unarchiving brings them back.
class DriftReminderRepository implements ReminderRepository {
  DriftReminderRepository(this._db, this._scheduler, this._clock);

  final KernelDatabase _db;
  final ReminderScheduler _scheduler;
  final Clock _clock;

  bool _launchTaken = false;

  static const _active = [ReminderStatus.scheduled, ReminderStatus.fired];

  /// Throws [ArgumentError] for an unknown or archived item or a [dueAt]
  /// that is not in the future. If the OS scheduler fails, nothing is
  /// persisted.
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
      if (item.archivedAt != null) {
        throw ArgumentError.value(itemId, 'itemId', 'item is archived');
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

  /// All reminders for the item, soonest first, including while the item is
  /// archived.
  @override
  Stream<List<Reminder>> watchForItem(String itemId) {
    final query = _db.select(_db.reminders)
      ..where((r) => r.itemId.equals(itemId))
      ..orderBy(_soonestFirst);
    return query.watch().map(_toModels);
  }

  /// Reminders still needing action (scheduled, or fired but not yet done)
  /// for items that are not archived, soonest first. Overdue ones stay in
  /// the list until done or cancelled.
  @override
  Stream<List<Reminder>> watchUpcoming() {
    final reminders = _db.reminders;
    final query =
        _db.select(reminders).join([
            innerJoin(_db.items, _db.items.id.equalsExp(reminders.itemId)),
          ])
          ..where(
            reminders.status.isInValues(_active) &
                _db.items.archivedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(reminders.dueAt),
            OrderingTerm.asc(reminders.createdAt),
            OrderingTerm.asc(reminders.id),
          ]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(reminders).toModel()],
    );
  }

  /// Item id from the reminder notification that launched the app, if it
  /// still names a stored item. Returns it at most once per app process.
  @override
  Future<String?> takeLaunchItemId() async {
    if (_launchTaken) return null;
    _launchTaken = true;
    final itemId = itemIdFromReminderPayload(await _scheduler.launchPayload());
    if (itemId == null) return null;
    final item = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(itemId))).getSingleOrNull();
    return item?.id;
  }

  /// Rule-based suggestion for the next check of [itemId]. It only reads;
  /// nothing is persisted or scheduled.
  ///
  /// The latest PASS scan decides (a RETRY carries no result):
  /// - infested or uncertain: in 3 days;
  /// - clean: in 14 days, or in 7 days when the grain has been stored for
  ///   more than 90 days;
  /// - notEvaluated, only RETRY scans, or never scanned: in 1 day.
  ///
  /// The day is then set to [suggestedReminderHour]:00 local time, and
  /// moved a day later while that is not after now. Returned in local
  /// time. Throws [ArgumentError] for an unknown or archived item.
  @override
  Future<DateTime> suggestDueAt(String itemId) async {
    final item = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(itemId))).getSingleOrNull();
    if (item == null) {
      throw ArgumentError.value(itemId, 'itemId', 'unknown item');
    }
    if (item.archivedAt != null) {
      throw ArgumentError.value(itemId, 'itemId', 'item is archived');
    }
    final latestPass =
        await (_db.select(_db.scans)
              ..where(
                (s) =>
                    s.itemId.equals(itemId) &
                    s.quality.equalsValue(ScanQuality.pass),
              )
              ..orderBy([
                (s) => OrderingTerm.desc(s.capturedAt),
                (s) => OrderingTerm.desc(s.createdAt),
                (s) => OrderingTerm.desc(s.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    final now = _clock();
    final storedDays = now.difference(item.storageDate).inDays;
    final days = switch (latestPass?.result) {
      Classification.infested || Classification.uncertain => 3,
      Classification.clean => storedDays > 90 ? 7 : 14,
      Classification.notEvaluated || null => 1,
    };
    return suggestedLocalTime(now, days);
  }

  /// Re-syncs the OS scheduler with the database after an app start:
  /// future reminders are rescheduled (idempotent, same notification id) and
  /// past-due ones are marked fired. Reminders of archived items stay
  /// silent and keep their status until the item is unarchived.
  Future<void> restore() => _restoreWhere(const Constant(true));

  /// Cancels the OS notifications of [itemId]'s active reminders. Their
  /// stored status is kept so [resumeForItem] can bring them back.
  Future<void> suspendForItem(String itemId) async {
    final rows =
        await (_db.select(_db.reminders)..where(
              (r) => r.itemId.equals(itemId) & r.status.isInValues(_active),
            ))
            .get();
    for (final row in rows) {
      await _scheduler.cancel(row.notificationId);
    }
  }

  /// Reschedules [itemId]'s future reminders; past-due ones become fired.
  Future<void> resumeForItem(String itemId) =>
      _restoreWhere(_db.reminders.itemId.equals(itemId));

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

  Future<void> _restoreWhere(Expression<bool> filter) async {
    final now = _clock().toUtc();
    final query =
        _db.select(_db.reminders).join([
          innerJoin(_db.items, _db.items.id.equalsExp(_db.reminders.itemId)),
        ])..where(
          _db.reminders.status.equalsValue(ReminderStatus.scheduled) & filter,
        );
    for (final joined in await query.get()) {
      final row = joined.readTable(_db.reminders);
      final item = joined.readTable(_db.items);
      if (item.archivedAt != null) {
        // Idempotent; covers a suspend that failed part-way.
        await _scheduler.cancel(row.notificationId);
      } else if (row.dueAt.isAfter(now)) {
        await _scheduler.schedule(_notificationFor(row, item.label));
      } else {
        await _setStatus(row.id, ReminderStatus.fired);
      }
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

/// Local hour of day used by [DriftReminderRepository.suggestDueAt].
const suggestedReminderHour = 9;

/// The local calendar day [days] after [now], at [suggestedReminderHour]:00
/// local time, moved forward a day at a time until it is after [now].
DateTime suggestedLocalTime(DateTime now, int days) {
  final local = now.toLocal();
  var offset = days;
  DateTime at(int offset) => DateTime(
    local.year,
    local.month,
    local.day + offset,
    suggestedReminderHour,
  );
  var due = at(offset);
  while (!due.isAfter(now)) {
    due = at(++offset);
  }
  return due;
}

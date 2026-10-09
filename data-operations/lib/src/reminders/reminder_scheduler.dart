/// Everything the OS notification layer needs to show one reminder.
class ReminderNotification {
  const ReminderNotification({
    required this.notificationId,
    required this.reminderId,
    required this.itemId,
    required this.itemLabel,
    required this.dueAt,
  });

  /// Stable 32-bit id, persisted with the reminder.
  final int notificationId;
  final String reminderId;
  final String itemId;

  /// User-entered item label shown in the notification text.
  final String itemLabel;

  /// UTC.
  final DateTime dueAt;
}

/// On-device notification scheduling used by the reminder repository.
///
/// Production: [LocalNotificationReminderScheduler]. Tests inject their own
/// implementation from `test/`.
abstract interface class ReminderScheduler {
  /// Schedules (or reschedules, replacing any earlier one with the same
  /// [ReminderNotification.notificationId]) a one-shot notification.
  Future<void> schedule(ReminderNotification notification);

  /// Cancels a pending notification and removes it if already shown.
  Future<void> cancel(int notificationId);

  /// Asks the OS for permission to post notifications (Android 13+).
  /// Returns whether notifications are allowed.
  Future<bool> requestPermission();
}

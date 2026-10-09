import 'dart:convert';

/// Notification payload: JSON `{"reminderId": ..., "itemId": ...}`.
String encodeReminderPayload({
  required String reminderId,
  required String itemId,
}) => jsonEncode({'reminderId': reminderId, 'itemId': itemId});

/// Item id carried by a reminder notification [payload], or null if it
/// carries none. Accepts the JSON payload written by
/// [encodeReminderPayload] and, for robustness, a bare item id.
String? itemIdFromReminderPayload(String? payload) {
  final value = payload?.trim();
  if (value == null || value.isEmpty) return null;
  if (!value.startsWith('{')) return value;
  final Object? decoded;
  try {
    decoded = jsonDecode(value);
  } on FormatException {
    return null;
  }
  if (decoded case {'itemId': final String itemId} when itemId.isNotEmpty) {
    return itemId;
  }
  return null;
}

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

  /// Payload of the reminder notification whose tap launched the app from
  /// closed, or null when the app was not launched by a notification. The
  /// OS keeps returning it for the life of the process; the repository
  /// makes it consumable once.
  Future<String?> launchPayload();
}

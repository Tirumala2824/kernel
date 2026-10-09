import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_scheduler.dart';

/// Called when the user taps a reminder notification while the app is
/// running.
typedef ReminderTapCallback = void Function(String reminderId, String itemId);

/// [ReminderScheduler] backed by flutter_local_notifications.
///
/// Reminders are one-shot, so they are scheduled at the exact instant in
/// UTC; no tz database or device time zone lookup is needed. Scheduling is
/// inexact (allowed while idle), so no exact-alarm permission is required
/// and Android may deliver a few minutes late.
class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    this.androidSmallIcon = '@mipmap/ic_launcher',
    this.onReminderTapped,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'kernel_reminders';
  static const channelName = 'Inspection reminders';
  static const channelDescription =
      'Reminders to re-scan or physically inspect stored grain';

  final FlutterLocalNotificationsPlugin _plugin;

  /// Android drawable or mipmap resource used as the status-bar icon.
  final String androidSmallIcon;
  final ReminderTapCallback? onReminderTapped;

  Future<void>? _initialized;

  /// Initialises the plugin once. Safe to call repeatedly.
  Future<void> initialize() async {
    final pending = _initialized ??= _initialize();
    try {
      await pending;
    } catch (_) {
      if (identical(_initialized, pending)) _initialized = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    await _plugin.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings(androidSmallIcon),
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );
  }

  void _onResponse(NotificationResponse response) {
    final callback = onReminderTapped;
    final payload = response.payload;
    if (callback == null || payload == null) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return;
    }
    if (decoded case {
      'reminderId': final String reminderId,
      'itemId': final String itemId,
    }) {
      callback(reminderId, itemId);
    }
  }

  @override
  Future<void> schedule(ReminderNotification notification) async {
    await initialize();
    await _plugin.zonedSchedule(
      id: notification.notificationId,
      scheduledDate: tz.TZDateTime.from(notification.dueAt.toUtc(), tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Grain check due',
      body: 'Time to re-scan or inspect "${notification.itemLabel}".',
      payload: jsonEncode({
        'reminderId': notification.reminderId,
        'itemId': notification.itemId,
      }),
    );
  }

  @override
  Future<void> cancel(int notificationId) async {
    await initialize();
    await _plugin.cancel(id: notificationId);
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    return await android.requestNotificationsPermission() ?? false;
  }
}

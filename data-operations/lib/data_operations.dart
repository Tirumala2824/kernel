/// Kernel local data and operations layer: drift-backed implementations of
/// the repository and service interfaces in `package:kernel_contracts`.
///
/// Only [DataOperations] and the reminder scheduling types are public. The
/// database and its tables are internal; the UI works through the contracts
/// interfaces only. Everything runs offline and makes no network calls.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'src/db/database.dart';
import 'src/reminders/local_notification_scheduler.dart';
import 'src/reminders/reminder_scheduler.dart';
import 'src/repositories/inspection_repository.dart';
import 'src/repositories/item_repository.dart';
import 'src/repositories/location_repository.dart';
import 'src/repositories/lot_repository.dart';
import 'src/repositories/reminder_repository.dart';
import 'src/repositories/scan_repository.dart';
import 'src/repositories/settings_repository.dart';
import 'src/services/privacy_service.dart';
import 'src/services/ranking_service.dart';
import 'src/services/report_service.dart';
import 'src/support.dart';

export 'src/reminders/local_notification_scheduler.dart'
    show LocalNotificationReminderScheduler, ReminderTapCallback;
export 'src/reminders/reminder_scheduler.dart'
    show ReminderNotification, ReminderScheduler;
export 'src/services/privacy_service.dart' show RetainedAudioDeleter;

/// The data layer, wired once at app start and closed on shutdown.
class DataOperations {
  /// Builds the data layer over [executor].
  ///
  /// Tests pass an in-memory executor, their own [reminderScheduler] and a
  /// temporary [reportDirectory]. [clock] defaults to the device clock.
  /// [deleteRetainedAudio] is called by `privacy.deleteAllHistory()`.
  factory DataOperations({
    required QueryExecutor executor,
    required ReminderScheduler reminderScheduler,
    required Directory reportDirectory,
    DateTime Function()? clock,
    RetainedAudioDeleter? deleteRetainedAudio,
  }) {
    final db = KernelDatabase(executor);
    final now = clock ?? systemClock;
    final reminders = DriftReminderRepository(db, reminderScheduler, now);
    return DataOperations._(
      db,
      reminderScheduler,
      reminders,
      items: DriftItemRepository(db, now),
      locations: DriftLocationRepository(db, now),
      lots: DriftLotRepository(db, now),
      scans: DriftScanRepository(db, now),
      inspections: DriftInspectionRepository(db, now),
      settings: DriftSettingsRepository(db, now),
      ranking: DriftRankingService(db),
      reports: DriftReportService(db, reportDirectory, now),
      privacy: DriftPrivacyService(db, reminders, deleteRetainedAudio),
    );
  }

  DataOperations._(
    this._db,
    this._scheduler,
    this._reminders, {
    required this.items,
    required this.locations,
    required this.lots,
    required this.scans,
    required this.inspections,
    required this.settings,
    required this.ranking,
    required this.reports,
    required this.privacy,
  });

  /// Opens the on-device database (`kernel.sqlite` in the app-private
  /// support directory) with the flutter_local_notifications scheduler, then
  /// restores pending reminders.
  ///
  /// [deleteRetainedAudio] should delete audio retained by the scan engine;
  /// it runs as part of `privacy.deleteAllHistory()`.
  /// [onReminderTapped] is called when a reminder notification is tapped
  /// while the app is running. [notificationIcon] is the Android resource
  /// for the status-bar icon.
  static Future<DataOperations> open({
    RetainedAudioDeleter? deleteRetainedAudio,
    ReminderTapCallback? onReminderTapped,
    String notificationIcon = '@mipmap/ic_launcher',
  }) async {
    final support = await getApplicationSupportDirectory();
    final scheduler = LocalNotificationReminderScheduler(
      androidSmallIcon: notificationIcon,
      onReminderTapped: onReminderTapped,
    );
    await scheduler.initialize();
    final ops = DataOperations(
      executor: driftDatabase(
        name: 'kernel',
        native: DriftNativeOptions(databaseDirectory: () async => support),
      ),
      reminderScheduler: scheduler,
      reportDirectory: Directory(p.join(support.path, 'reports')),
      deleteRetainedAudio: deleteRetainedAudio,
    );
    try {
      await ops.restoreReminders();
    } catch (_) {
      await ops.close();
      rethrow;
    }
    return ops;
  }

  final KernelDatabase _db;
  final ReminderScheduler _scheduler;
  final DriftReminderRepository _reminders;

  final ItemRepository items;
  final LocationRepository locations;
  final LotRepository lots;
  final ScanRepository scans;
  final InspectionRepository inspections;
  ReminderRepository get reminders => _reminders;
  final SettingsRepository settings;
  final RankingService ranking;
  final ReportService reports;
  final PrivacyService privacy;

  /// Reschedules future reminders and marks past-due ones fired. [open]
  /// calls this; the app may call it again, e.g. on resume.
  Future<void> restoreReminders() => _reminders.restore();

  /// Asks for the Android 13+ notification permission. Call from a user
  /// action (for example when the first reminder is set).
  Future<bool> requestNotificationPermission() =>
      _scheduler.requestPermission();

  Future<void> close() => _db.close();
}

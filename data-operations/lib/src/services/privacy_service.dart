import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../repositories/reminder_repository.dart';

/// Deletes retained audio kept outside this package (the audio-ai plugin's
/// app-private recordings folder). Wired by the app.
typedef RetainedAudioDeleter = Future<void> Function();

/// User-initiated wipe. Items, lots, locations and settings remain.
class DriftPrivacyService implements PrivacyService {
  DriftPrivacyService(this._db, this._reminders, this._deleteRetainedAudio);

  final KernelDatabase _db;
  final DriftReminderRepository _reminders;
  final RetainedAudioDeleter? _deleteRetainedAudio;

  /// Cancels reminder notifications, then deletes all scans, inspections and
  /// reminders in one transaction, then deletes retained audio if a deleter
  /// was provided. Safe to call again after a partial failure.
  @override
  Future<void> deleteAllHistory() async {
    await _reminders.cancelAllNotifications();
    await _db.transaction(() async {
      // Inspections reference scans, so they go first.
      await _db.delete(_db.inspections).go();
      await _db.delete(_db.scans).go();
      await _db.delete(_db.reminders).go();
    });
    final deleteAudio = _deleteRetainedAudio;
    if (deleteAudio != null) await deleteAudio();
  }
}

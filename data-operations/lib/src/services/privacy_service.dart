import 'dart:io';

import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../repositories/reminder_repository.dart';

/// Deletes retained audio kept outside this package (the audio-ai plugin's
/// app-private recordings folder). Wired by the app.
typedef RetainedAudioDeleter = Future<void> Function();

/// User-initiated wipe. Items, lots, locations, harvests and settings
/// remain.
class DriftPrivacyService implements PrivacyService {
  DriftPrivacyService(
    this._db,
    this._reminders,
    this._deleteRetainedAudio,
    this._datasetDirectory,
  );

  final KernelDatabase _db;
  final DriftReminderRepository _reminders;
  final RetainedAudioDeleter? _deleteRetainedAudio;

  /// Where DatasetExportService writes ZIPs that contain copies of retained
  /// audio; they are wiped together with the audio.
  final Directory _datasetDirectory;

  /// In order: cancels reminder notifications; deletes inspection photo
  /// files (missing files are ignored); deletes all labeled samples, scans,
  /// inspections and reminders in one transaction; deletes retained audio
  /// if a deleter was provided; deletes exported dataset ZIPs. Photos go
  /// before the rows that list them, so after a partial failure calling it
  /// again finishes the job.
  @override
  Future<void> deleteAllHistory() async {
    await _reminders.cancelAllNotifications();
    final inspections = await _db.select(_db.inspections).get();
    for (final inspection in inspections) {
      for (final path in inspection.photoPaths) {
        await _deletePhoto(path);
      }
    }
    await _db.transaction(() async {
      // Children first: samples reference scans and inspections, and
      // inspections reference scans.
      await _db.delete(_db.labeledSamples).go();
      await _db.delete(_db.inspections).go();
      await _db.delete(_db.scans).go();
      await _db.delete(_db.reminders).go();
    });
    final deleteAudio = _deleteRetainedAudio;
    if (deleteAudio != null) await deleteAudio();
    if (await _datasetDirectory.exists()) {
      await _datasetDirectory.delete(recursive: true);
    }
  }

  /// Deletes a photo file. Missing files are fine; directories are never
  /// touched.
  static Future<void> _deletePhoto(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    try {
      switch (type) {
        case FileSystemEntityType.file:
          await File(path).delete();
        case FileSystemEntityType.link:
          // Remove the link only, never its target.
          await Link(path).delete();
        default:
          return;
      }
    } on PathNotFoundException {
      // Already gone.
    }
  }
}

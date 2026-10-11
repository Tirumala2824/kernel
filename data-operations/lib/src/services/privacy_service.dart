import 'dart:io';

import 'package:drift/drift.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../db/database.dart';
import '../repositories/reminder_repository.dart';
import '../support.dart';

/// Deletes retained audio kept outside this package (the audio-ai plugin's
/// app-private recordings folder). Wired by the app.
typedef RetainedAudioDeleter = Future<void> Function();

/// User-initiated wipe. Items, lots, locations, harvests, settings,
/// knowledge cards and paired sensor nodes remain.
class DriftPrivacyService implements PrivacyService {
  DriftPrivacyService(
    this._db,
    this._reminders,
    this._deleteRetainedAudio,
    this._datasetDirectory,
    this._clock,
  );

  final KernelDatabase _db;
  final DriftReminderRepository _reminders;
  final RetainedAudioDeleter? _deleteRetainedAudio;

  /// Where DatasetExportService writes ZIPs that contain copies of retained
  /// audio; they are wiped together with the audio.
  final Directory _datasetDirectory;
  final Clock _clock;

  /// In order:
  /// 1. cancels reminder notifications;
  /// 2. deletes inspection photo files and kept sighting media files
  ///    (missing files are ignored);
  /// 3. in one transaction, deletes all labeled samples, inspections,
  ///    scans, reminders, sightings, sensor events and health, and records on each
  ///    node the highest event seq it cleared, so the node's
  ///    store-and-forward buffer never brings those events back. A separate
  ///    time cutoff prevents replay of wiped health observations;
  /// 4. deletes retained audio if a deleter was provided;
  /// 5. deletes exported dataset ZIPs.
  ///
  /// Files go before the rows that list them, so after a partial failure
  /// calling it again finishes the job. Paired nodes, their placement and
  /// key fingerprints are kept.
  @override
  Future<void> deleteAllHistory() async {
    await _reminders.cancelAllNotifications();
    final inspections = await _db.select(_db.inspections).get();
    for (final inspection in inspections) {
      for (final path in inspection.photoPaths) {
        await deleteFileIfPresent(path);
      }
    }
    final media =
        await (_db.selectOnly(_db.sightings)
              ..addColumns([_db.sightings.mediaPath])
              ..where(_db.sightings.mediaPath.isNotNull()))
            .map((row) => row.read(_db.sightings.mediaPath)!)
            .get();
    for (final path in media) {
      await deleteFileIfPresent(path);
    }
    await _db.transaction(() async {
      // Children first: samples reference scans and inspections, and
      // inspections reference scans.
      await _db.delete(_db.labeledSamples).go();
      await _db.delete(_db.inspections).go();
      await _db.delete(_db.scans).go();
      await _db.delete(_db.reminders).go();
      await _db.delete(_db.sightings).go();
      await _markClearedSeqs();
      await _db.delete(_db.sensorEvents).go();
      await _markClearedHealth();
      await _db.delete(_db.sensorHealthChanges).go();
    });
    final deleteAudio = _deleteRetainedAudio;
    if (deleteAudio != null) await deleteAudio();
    if (await _datasetDirectory.exists()) {
      await _datasetDirectory.delete(recursive: true);
    }
  }

  Future<void> _markClearedHealth() async {
    final now = _clock().toUtc();
    final health = _db.sensorHealthChanges;
    for (final node in await _db.select(_db.sensorNodes).get()) {
      final latest =
          await (_db.select(health)
                ..where((h) => h.nodeId.equals(node.id))
                ..orderBy([(h) => OrderingTerm.desc(h.at)])
                ..limit(1))
              .getSingleOrNull();
      var cutoff = node.healthClearedThroughAt;
      if (cutoff == null || now.isAfter(cutoff)) cutoff = now;
      if (latest != null && latest.at.isAfter(cutoff)) cutoff = latest.at;
      await (_db.update(
        _db.sensorNodes,
      )..where((n) => n.id.equals(node.id))).write(
        SensorNodesCompanion(
          healthClearedThroughAt: Value(cutoff),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<void> _markClearedSeqs() async {
    final events = _db.sensorEvents;
    final maxSeq = events.seq.max();
    final highest =
        await (_db.selectOnly(events)
              ..addColumns([events.nodeId, maxSeq])
              ..groupBy([events.nodeId]))
            .map((row) => (row.read(events.nodeId)!, row.read(maxSeq)!))
            .get();
    if (highest.isEmpty) return;
    final nodes = {
      for (final row in await _db.select(_db.sensorNodes).get()) row.id: row,
    };
    final now = _clock().toUtc();
    for (final (nodeId, seq) in highest) {
      final cleared = nodes[nodeId]?.eventsClearedThroughSeq;
      if (cleared != null && cleared >= seq) continue;
      await (_db.update(
        _db.sensorNodes,
      )..where((n) => n.id.equals(nodeId))).write(
        SensorNodesCompanion(
          eventsClearedThroughSeq: Value(seq),
          updatedAt: Value(now),
        ),
      );
    }
  }
}

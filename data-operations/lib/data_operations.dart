/// Kernel local data and operations layer: drift-backed implementations of
/// the repository and service interfaces in `package:kernel_contracts`.
///
/// Only [DataOperations] and the wiring types (scheduler, callbacks, font
/// loader, card pack source) are public. The database and its tables are
/// internal; the UI works through the contracts interfaces only. Everything
/// runs offline and makes no network calls.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'src/db/database.dart';
import 'src/reminders/local_notification_scheduler.dart';
import 'src/reminders/reminder_scheduler.dart';
import 'src/reports/report_fonts.dart';
import 'src/repositories/harvest_repository.dart';
import 'src/repositories/inspection_repository.dart';
import 'src/repositories/item_repository.dart';
import 'src/repositories/labeled_sample_repository.dart';
import 'src/repositories/location_repository.dart';
import 'src/repositories/lot_repository.dart';
import 'src/repositories/reminder_repository.dart';
import 'src/repositories/scan_repository.dart';
import 'src/repositories/sensor_repositories.dart';
import 'src/repositories/settings_repository.dart';
import 'src/repositories/sighting_repository.dart';
import 'src/services/analytics_service.dart';
import 'src/services/dataset_export_service.dart';
import 'src/services/knowledge_service.dart';
import 'src/services/privacy_service.dart';
import 'src/services/ranking_service.dart';
import 'src/services/report_service.dart';
import 'src/support.dart';

export 'src/reminders/local_notification_scheduler.dart'
    show LocalNotificationReminderScheduler, ReminderTapCallback;
export 'src/reminders/reminder_scheduler.dart'
    show ReminderNotification, ReminderScheduler;
export 'src/reports/report_fonts.dart'
    show ReportFontLoader, bundledReportFont, reportFontFamilies;
export 'src/services/dataset_export_service.dart'
    show RetainedAudioPathResolver;
export 'src/services/knowledge_service.dart' show KnowledgeCardsSource;
export 'src/services/privacy_service.dart' show RetainedAudioDeleter;
export 'src/services/report_service.dart' show ModelNoteSource;

/// The data layer, wired once at app start and closed on shutdown.
class DataOperations {
  /// Builds the data layer over [executor].
  ///
  /// Tests pass an in-memory executor, their own [reminderScheduler] and a
  /// temporary [reportDirectory]. [clock] defaults to the device clock.
  /// - [datasetDirectory]: where dataset ZIPs go; defaults to
  ///   `<reportDirectory>/datasets`.
  /// - [deleteRetainedAudio]: called by `privacy.deleteAllHistory()`.
  /// - [retainedAudioPath]: locates a scan's retained WAV for
  ///   `datasetExport.exportZip()`; without it every WAV is listed missing.
  /// - [currentModelNote]: the installed model's note for report headers.
  /// - [reportFonts]: loads the bundled Noto fonts for PDFs. Without it,
  ///   PDFs use the built-in Latin-1 fonts and other characters become `?`.
  /// - [knowledgeCardsJson]: returns the knowledge card pack JSON; read on
  ///   first use of `knowledge`. Without it, `knowledge` serves the cards
  ///   already stored (none on a fresh install).
  /// - [embedder]: on-device text embedder for `knowledge.search`. Without
  ///   it, search is keyword-only.
  /// - [sensorAttention]: ids of sensor nodes that are jammed, clipped, low
  ///   on battery or need a survey, for the `sensorNeedsAttention` next
  ///   action. Listened to from construction until [close].
  factory DataOperations({
    required QueryExecutor executor,
    required ReminderScheduler reminderScheduler,
    required Directory reportDirectory,
    Directory? datasetDirectory,
    DateTime Function()? clock,
    RetainedAudioDeleter? deleteRetainedAudio,
    RetainedAudioPathResolver? retainedAudioPath,
    ModelNoteSource? currentModelNote,
    ReportFontLoader? reportFonts,
    KnowledgeCardsSource? knowledgeCardsJson,
    Embedder? embedder,
    Stream<Set<String>>? sensorAttention,
  }) {
    final db = KernelDatabase(executor);
    final now = clock ?? systemClock;
    final datasets =
        datasetDirectory ?? Directory(p.join(reportDirectory.path, 'datasets'));
    final reminders = DriftReminderRepository(db, reminderScheduler, now);
    return DataOperations._(
      db,
      reminderScheduler,
      reminders,
      items: DriftItemRepository(db, now, reminders),
      locations: DriftLocationRepository(db, now),
      lots: DriftLotRepository(db, now),
      harvests: DriftHarvestRepository(db, now),
      scans: DriftScanRepository(db, now),
      inspections: DriftInspectionRepository(db, now),
      labeledSamples: DriftLabeledSampleRepository(db, now),
      settings: DriftSettingsRepository(db, now),
      ranking: DriftRankingService(db, now),
      analytics: DriftAnalyticsService(db, now, sensorAttention),
      reports: DriftReportService(
        db,
        reportDirectory,
        now,
        fontLoader: reportFonts,
        modelNote: currentModelNote,
      ),
      datasetExport: DriftDatasetExportService(
        db,
        datasets,
        now,
        retainedAudioPath,
      ),
      privacy: DriftPrivacyService(
        db,
        reminders,
        deleteRetainedAudio,
        datasets,
        now,
      ),
      sightings: DriftSightingRepository(db, now),
      sensorNodes: DriftSensorNodeRepository(db, now),
      sensorEvents: DriftSensorEventRepository(db, now),
      knowledge: DriftKnowledgeService(
        db,
        now,
        cardsJson: knowledgeCardsJson,
        embedder: embedder,
      ),
    );
  }

  DataOperations._(
    this._db,
    this._scheduler,
    this._reminders, {
    required this.items,
    required this.locations,
    required this.lots,
    required this.harvests,
    required this.scans,
    required this.inspections,
    required this.labeledSamples,
    required this.settings,
    required this.ranking,
    required this._analytics,
    required this.reports,
    required this.datasetExport,
    required this.privacy,
    required this.sightings,
    required this.sensorNodes,
    required this.sensorEvents,
    required this._knowledge,
  });

  /// Opens the on-device database (`kernel.sqlite` in the app-private
  /// support directory) with the flutter_local_notifications scheduler, then
  /// restores pending reminders. PDFs use the bundled Noto fonts, and their
  /// OFL licence is registered with the app's LicenseRegistry.
  ///
  /// - [deleteRetainedAudio]: `ScanEngine.deleteRetainedAudio`; runs as
  ///   part of `privacy.deleteAllHistory()`.
  /// - [retainedAudioPath]: `ScanEngine.retainedAudioPath`, used by the
  ///   dataset export.
  /// - [currentModelNote]: returns `EngineInfo.modelNote`, shown in report
  ///   headers.
  /// - [onReminderTapped]: called when a reminder notification is tapped
  ///   while the app is running (a launch from closed goes through
  ///   `reminders.takeLaunchItemId()`).
  /// - [notificationIcon]: Android resource for the status-bar icon.
  /// - [knowledgeCardsJson]: the card pack, e.g.
  ///   `() => rootBundle.loadString('assets/knowledge/pest_cards.json')`.
  /// - [embedder]: the on-device EmbeddingGemma embedder (local-llm), for
  ///   semantic card search.
  /// - [sensorAttention]: node ids needing attention, derived by the app
  ///   from `SensorLink.watchStatus`.
  static Future<DataOperations> open({
    RetainedAudioDeleter? deleteRetainedAudio,
    RetainedAudioPathResolver? retainedAudioPath,
    ModelNoteSource? currentModelNote,
    ReminderTapCallback? onReminderTapped,
    String notificationIcon = '@mipmap/ic_launcher',
    KnowledgeCardsSource? knowledgeCardsJson,
    Embedder? embedder,
    Stream<Set<String>>? sensorAttention,
  }) async {
    final support = await getApplicationSupportDirectory();
    final scheduler = LocalNotificationReminderScheduler(
      androidSmallIcon: notificationIcon,
      onReminderTapped: onReminderTapped,
    );
    await scheduler.initialize();
    _registerFontLicense();
    final ops = DataOperations(
      executor: driftDatabase(
        name: 'kernel',
        native: DriftNativeOptions(databaseDirectory: () async => support),
      ),
      reminderScheduler: scheduler,
      reportDirectory: Directory(p.join(support.path, 'reports')),
      datasetDirectory: Directory(p.join(support.path, 'datasets')),
      deleteRetainedAudio: deleteRetainedAudio,
      retainedAudioPath: retainedAudioPath,
      currentModelNote: currentModelNote,
      reportFonts: bundledReportFont,
      knowledgeCardsJson: knowledgeCardsJson,
      embedder: embedder,
      sensorAttention: sensorAttention,
    );
    try {
      await ops.restoreReminders();
    } catch (_) {
      await ops.close();
      rethrow;
    }
    return ops;
  }

  static bool _licenseRegistered = false;

  static void _registerFontLicense() {
    if (_licenseRegistered) return;
    _licenseRegistered = true;
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString(bundledFontLicenseAsset);
      yield LicenseEntryWithLineBreaks(const [
        'Noto Sans (Kernel PDF reports)',
      ], text);
    });
  }

  final KernelDatabase _db;
  final ReminderScheduler _scheduler;
  final DriftReminderRepository _reminders;
  final DriftAnalyticsService _analytics;
  final DriftKnowledgeService _knowledge;

  final ItemRepository items;
  final LocationRepository locations;
  final LotRepository lots;
  final HarvestRepository harvests;
  final ScanRepository scans;
  final InspectionRepository inspections;
  ReminderRepository get reminders => _reminders;
  final LabeledSampleRepository labeledSamples;
  final SettingsRepository settings;
  final RankingService ranking;

  /// On-device analytics and next actions, computed from stored records.
  AnalyticsService get analytics => _analytics;
  final ReportService reports;
  final DatasetExportService datasetExport;
  final PrivacyService privacy;

  /// Pest ID sightings: AI analysis, user validation and verified finding
  /// kept separate.
  final SightingRepository sightings;

  /// Paired BLE sensor nodes.
  final SensorNodeRepository sensorNodes;

  /// Signature-matched sensor events (features only).
  final SensorEventRepository sensorEvents;

  /// Curated knowledge cards with on-device semantic search.
  KnowledgeService get knowledge => _knowledge;

  /// Reschedules future reminders and marks past-due ones fired. [open]
  /// calls this; the app may call it again, e.g. on resume.
  Future<void> restoreReminders() => _reminders.restore();

  /// Asks for the Android 13+ notification permission. Call from a user
  /// action (for example when the first reminder is set).
  Future<bool> requestNotificationPermission() =>
      _scheduler.requestPermission();

  /// Stops background card indexing and the sensor attention subscription,
  /// then closes the database.
  Future<void> close() async {
    await _knowledge.dispose();
    await _analytics.dispose();
    await _db.close();
  }
}

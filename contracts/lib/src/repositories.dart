import 'enums.dart';
import 'models.dart';
import 'scan_outcome.dart';

// Local-only, offline repositories owned by data-operations. Streams emit on
// every change so the UI stays reactive. Unless stated otherwise, watch*
// methods exclude archived records.

abstract interface class ItemRepository {
  Future<GrainItem> create(GrainItemDraft draft);
  Future<GrainItem> update(GrainItem item);

  /// Returns archived items too, so history screens can still resolve them.
  Future<GrainItem?> get(String id);
  Stream<List<GrainItem>> watchByRole(Role role);
  Stream<List<GrainItem>> watchByLocation(String locationId);
  Stream<List<GrainItem>> watchByLot(String lotId);
  Stream<List<GrainItem>> watchByHarvest(String harvestId);

  /// Soft delete; scans and inspections are kept.
  Future<void> archive(String id);
  Future<void> unarchive(String id);
}

abstract interface class LocationRepository {
  Future<Location> create(LocationDraft draft);
  Future<Location?> get(String id);

  /// Top-level locations when [parentId] is null.
  Stream<List<Location>> watchChildren(String? parentId);
  Stream<List<Location>> watchAll();
  Future<void> archive(String id);
}

abstract interface class LotRepository {
  Future<Lot> create(LotDraft draft);
  Future<Lot?> get(String id);
  Stream<List<Lot>> watchAll();

  /// Set by a human. Never set automatically from predictions.
  Future<Lot> updateScreeningStatus(String id, ScreeningStatus status);
  Future<void> archive(String id);
}

abstract interface class HarvestRepository {
  Future<Harvest> create(HarvestDraft draft);
  Future<Harvest?> get(String id);
  Stream<List<Harvest>> watchAll();
  Future<void> archive(String id);
}

/// Append-only. There is no update or single delete.
abstract interface class ScanRepository {
  /// Throws [ArgumentError] if [ScanOutcome.invariantViolations] is non-empty.
  Future<ScanRecord> record(ScanOutcome outcome);

  /// Newest first.
  Stream<List<ScanRecord>> watchForItem(String itemId);

  /// Newest first.
  Stream<List<ScanRecord>> watchRecent({int limit = 50});

  /// Scans captured at or after [since], newest first; optionally only for
  /// items owned by [role].
  Stream<List<ScanRecord>> watchSince(DateTime since, {Role? role});
  Future<ScanRecord?> get(String scanId);
  Future<ScanRecord?> latestValidForItem(String itemId);
}

abstract interface class InspectionRepository {
  Future<Inspection> create(InspectionDraft draft);

  /// Newest first.
  Stream<List<Inspection>> watchForItem(String itemId);

  /// Follow-up status open or inProgress, oldest first.
  Stream<List<Inspection>> watchOpen();
  Future<Inspection> updateFollowUp(String id, FollowUpStatus status);

  /// Sets or clears the assignee. Does not touch the verified finding.
  Future<Inspection> assign(String id, String? assignee);
}

abstract interface class ReminderRepository {
  /// Persists and schedules an on-device notification.
  Future<Reminder> schedule(String itemId, DateTime dueAt);
  Future<void> cancel(String id);
  Future<void> markDone(String id);
  Stream<List<Reminder>> watchForItem(String itemId);
  Stream<List<Reminder>> watchUpcoming();

  /// Item id of the reminder notification that launched the app, if any.
  /// Consumed once.
  Future<String?> takeLaunchItemId();
}

/// Research recordings for building training data. Requires the research
/// opt-in. clean/infested labels must reference an inspection whose verified
/// finding agrees (noneFound / pestsFound); otherwise ArgumentError.
abstract interface class LabeledSampleRepository {
  Future<LabeledSample> create(LabeledSampleDraft draft);
  Stream<List<LabeledSample>> watchAll();
}

abstract interface class SettingsRepository {
  /// Null until the user has picked a role.
  Stream<Role?> watchActiveRole();
  Future<void> setActiveRole(Role role);
  Stream<bool> watchRetainAudioOptIn();
  Future<void> setRetainAudioOptIn(bool value);

  /// Research recording mode (explicit, separate opt-in). Default false.
  Stream<bool> watchResearchModeOptIn();
  Future<void> setResearchModeOptIn(bool value);

  /// BCP-47 language tag (e.g. "hi", "ta"). Null means follow the device.
  Stream<String?> watchLanguageTag();
  Future<void> setLanguageTag(String? tag);

  /// Default true.
  Stream<bool> watchHaptics();
  Future<void> setHaptics(bool value);

  /// Spoken prompts during scans. Default false.
  Stream<bool> watchVoicePrompts();
  Future<void> setVoicePrompts(bool value);

  /// Default false until onboarding is completed once.
  Stream<bool> watchOnboardingDone();
  Future<void> setOnboardingDone(bool value);
}

abstract interface class RankingService {
  /// Ranks items by their latest valid scan; see docs/contracts.md.
  Stream<InspectionQueue> watchQueue({Role? role, String? locationId, String? lotId});
}

abstract interface class ReportService {
  /// Writes a report built only from stored records to app-private storage
  /// and returns its absolute path. [ReportKind.sackLabels] supports PDF only.
  Future<String> export(ReportScope scope, ReportFormat format);
}

abstract interface class DatasetExportService {
  /// Builds a ZIP of retained WAVs plus a CSV manifest of labeled samples in
  /// app-private storage and returns its path. Shared by the user through
  /// the share sheet; never uploaded by the app.
  Future<String> exportZip();
}

abstract interface class PrivacyService {
  /// User-initiated wipe of scans, inspections (and their photos), reminders,
  /// labeled samples and retained audio.
  Future<void> deleteAllHistory();
}

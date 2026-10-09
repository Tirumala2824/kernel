import 'enums.dart';
import 'models.dart';
import 'scan_outcome.dart';

// Local-only, offline repositories owned by data-operations. Streams emit on
// every change so the UI stays reactive.

abstract interface class ItemRepository {
  Future<GrainItem> create(GrainItemDraft draft);
  Future<GrainItem> update(GrainItem item);
  Future<GrainItem?> get(String id);
  Stream<List<GrainItem>> watchByRole(Role role);
  Stream<List<GrainItem>> watchByLocation(String locationId);
  Stream<List<GrainItem>> watchByLot(String lotId);
}

abstract interface class LocationRepository {
  Future<Location> create(LocationDraft draft);
  Future<Location?> get(String id);

  /// Top-level locations when [parentId] is null.
  Stream<List<Location>> watchChildren(String? parentId);
}

abstract interface class LotRepository {
  Future<Lot> create(LotDraft draft);
  Future<Lot?> get(String id);
  Stream<List<Lot>> watchAll();

  /// Set by a human. Never set automatically from predictions.
  Future<Lot> updateScreeningStatus(String id, ScreeningStatus status);
}

/// Append-only. There is no update or single delete.
abstract interface class ScanRepository {
  /// Throws [ArgumentError] if [ScanOutcome.invariantViolations] is non-empty.
  Future<ScanRecord> record(ScanOutcome outcome);
  Stream<List<ScanRecord>> watchForItem(String itemId);
  Stream<List<ScanRecord>> watchRecent({int limit = 50});
  Future<ScanRecord?> latestValidForItem(String itemId);
}

abstract interface class InspectionRepository {
  Future<Inspection> create(InspectionDraft draft);
  Stream<List<Inspection>> watchForItem(String itemId);
  Stream<List<Inspection>> watchOpen();
  Future<Inspection> updateFollowUp(String id, FollowUpStatus status);
}

abstract interface class ReminderRepository {
  /// Persists and schedules an on-device notification.
  Future<Reminder> schedule(String itemId, DateTime dueAt);
  Future<void> cancel(String id);
  Future<void> markDone(String id);
  Stream<List<Reminder>> watchForItem(String itemId);
  Stream<List<Reminder>> watchUpcoming();
}

abstract interface class SettingsRepository {
  /// Null until the user has picked a role.
  Stream<Role?> watchActiveRole();
  Future<void> setActiveRole(Role role);
  Stream<bool> watchRetainAudioOptIn();
  Future<void> setRetainAudioOptIn(bool value);
}

abstract interface class RankingService {
  /// Ranks items by their latest valid scan; see docs/contracts.md.
  Stream<InspectionQueue> watchQueue({Role? role, String? locationId, String? lotId});
}

abstract interface class ReportService {
  /// Writes a report built only from stored records to app-private storage
  /// and returns its absolute path.
  Future<String> export(ReportScope scope, ReportFormat format);
}

abstract interface class PrivacyService {
  /// User-initiated wipe of scans, inspections, reminders and retained audio.
  Future<void> deleteAllHistory();
}

// Test-only in-memory scans, inspections, reminders and labeled samples.

import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';
import 'in_memory_inventory.dart';

class InMemoryScanRepository implements ScanRepository {
  InMemoryScanRepository(this.items);

  final InMemoryItemRepository items;
  final scans = <ScanRecord>[];
  final _changes = Changes();
  Stream<void> get changes => _changes.stream;

  List<ScanRecord> get _newestFirst =>
      [...scans]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

  @override
  Future<ScanRecord> record(ScanOutcome outcome) async {
    final violations = outcome.invariantViolations();
    if (violations.isNotEmpty) throw ArgumentError(violations.join('; '));
    final now = DateTime.now().toUtc();
    final record = ScanRecord(
      id: outcome.scanId,
      itemId: outcome.itemId,
      capturedAt: outcome.capturedAt,
      durationMs: outcome.durationMs,
      sampleRate: outcome.sampleRate,
      quality: outcome.quality,
      qualityReasons: outcome.qualityReasons,
      modelVersion: outcome.modelVersion,
      result: outcome.classification,
      confidence: outcome.confidence,
      experimental: outcome.experimental,
      latencyMs: outcome.latencyMs,
      deviceModel: outcome.deviceModel,
      osVersion: outcome.osVersion,
      audioRetained: outcome.audioRetained,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    scans.add(record);
    _changes.notify();
    return record;
  }

  @override
  Stream<List<ScanRecord>> watchForItem(String itemId) => _changes.watch(
    () => _newestFirst.where((s) => s.itemId == itemId).toList(),
  );

  @override
  Stream<List<ScanRecord>> watchRecent({int limit = 50, Role? role}) =>
      _changes.watch(() {
        final owned = {
          for (final item in items.items)
            if (!item.isArchived && (role == null || item.ownerRole == role))
              item.id,
        };
        return _newestFirst
            .where((scan) => owned.contains(scan.itemId))
            .take(limit)
            .toList();
      });

  @override
  Stream<List<ScanRecord>> watchSince(DateTime since, {Role? role}) =>
      _changes.watch(() {
        final owned = role == null
            ? null
            : {
                for (final i in items.items)
                  if (i.ownerRole == role) i.id,
              };
        return _newestFirst
            .where(
              (s) =>
                  !s.capturedAt.isBefore(since) &&
                  (owned == null || owned.contains(s.itemId)),
            )
            .toList();
      });

  @override
  Future<ScanRecord?> get(String scanId) async =>
      scans.where((s) => s.id == scanId).firstOrNull;

  @override
  Future<ScanRecord?> latestValidForItem(String itemId) async =>
      _newestFirst.where((s) => s.itemId == itemId && s.isValid).firstOrNull;

  void clear() {
    scans.clear();
    _changes.notify();
  }
}

class InMemoryInspectionRepository implements InspectionRepository {
  final inspections = <Inspection>[];
  final drafts = <InspectionDraft>[];
  final assignCalls = <(String, String?)>[];
  final _changes = Changes();
  Stream<void> get changes => _changes.stream;

  Inspection _copy(
    Inspection old, {
    FollowUpStatus? status,
    String? assignee,
    bool setAssignee = false,
  }) => Inspection(
    id: old.id,
    itemId: old.itemId,
    scanId: old.scanId,
    inspectedAt: old.inspectedAt,
    inspector: old.inspector,
    observations: old.observations,
    verifiedFinding: old.verifiedFinding,
    followUpStatus: status ?? old.followUpStatus,
    assignedTo: setAssignee ? assignee : old.assignedTo,
    photoPaths: old.photoPaths,
    createdAt: old.createdAt,
    updatedAt: DateTime.now().toUtc(),
    syncState: old.syncState,
  );

  @override
  Future<Inspection> create(InspectionDraft draft) async {
    drafts.add(draft);
    final now = DateTime.now().toUtc();
    final inspection = Inspection(
      id: testId('insp'),
      itemId: draft.itemId,
      scanId: draft.scanId,
      inspectedAt: draft.inspectedAt,
      inspector: draft.inspector,
      observations: draft.observations,
      verifiedFinding: draft.verifiedFinding,
      followUpStatus: draft.followUpStatus,
      assignedTo: draft.assignedTo,
      photoPaths: draft.photoPaths,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    inspections.add(inspection);
    _changes.notify();
    return inspection;
  }

  @override
  Stream<List<Inspection>> watchForItem(String itemId) => _changes.watch(
    () =>
        inspections.where((i) => i.itemId == itemId).toList()
          ..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt)),
  );

  @override
  Stream<List<Inspection>> watchOpen() => _changes.watch(
    () =>
        inspections
            .where((i) => i.followUpStatus != FollowUpStatus.done)
            .toList()
          ..sort((a, b) => a.inspectedAt.compareTo(b.inspectedAt)),
  );

  @override
  Future<Inspection> updateFollowUp(String id, FollowUpStatus status) async {
    final index = inspections.indexWhere((i) => i.id == id);
    inspections[index] = _copy(inspections[index], status: status);
    _changes.notify();
    return inspections[index];
  }

  @override
  Future<Inspection> assign(String id, String? assignee) async {
    assignCalls.add((id, assignee));
    final index = inspections.indexWhere((i) => i.id == id);
    inspections[index] = _copy(
      inspections[index],
      assignee: assignee,
      setAssignee: true,
    );
    _changes.notify();
    return inspections[index];
  }

  void clear() {
    inspections.clear();
    _changes.notify();
  }
}

class InMemoryReminderRepository implements ReminderRepository {
  final reminders = <Reminder>[];
  final _changes = Changes();

  /// Item id the next takeLaunchItemId returns (then cleared).
  String? launchItemId;
  int launchTakes = 0;

  Reminder _with(Reminder r, ReminderStatus status) => Reminder(
    id: r.id,
    itemId: r.itemId,
    dueAt: r.dueAt,
    status: status,
    createdAt: r.createdAt,
    updatedAt: DateTime.now().toUtc(),
    syncState: r.syncState,
  );

  @override
  Future<Reminder> schedule(String itemId, DateTime dueAt) async {
    final now = DateTime.now().toUtc();
    final reminder = Reminder(
      id: testId('rem'),
      itemId: itemId,
      dueAt: dueAt,
      status: ReminderStatus.scheduled,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    reminders.add(reminder);
    _changes.notify();
    return reminder;
  }

  void _set(String id, ReminderStatus status) {
    final index = reminders.indexWhere((r) => r.id == id);
    reminders[index] = _with(reminders[index], status);
    _changes.notify();
  }

  @override
  Future<void> cancel(String id) async => _set(id, ReminderStatus.cancelled);

  @override
  Future<void> markDone(String id) async => _set(id, ReminderStatus.done);

  @override
  Stream<List<Reminder>> watchForItem(String itemId) =>
      _changes.watch(() => reminders.where((r) => r.itemId == itemId).toList());

  @override
  Stream<List<Reminder>> watchUpcoming() => _changes.watch(
    () => reminders.where((r) => r.status == ReminderStatus.scheduled).toList(),
  );

  @override
  Future<String?> takeLaunchItemId() async {
    launchTakes++;
    final id = launchItemId;
    launchItemId = null;
    return id;
  }

  /// Scripted rule-based suggestion; defaults to 10 days from now at 09:00.
  DateTime? suggestion;
  final suggestCalls = <String>[];

  @override
  Future<DateTime> suggestDueAt(String itemId) async {
    suggestCalls.add(itemId);
    final scripted = suggestion;
    if (scripted != null) return scripted;
    final day = DateTime.now().add(const Duration(days: 10));
    return DateTime(day.year, day.month, day.day, 9);
  }

  void clear() {
    reminders.clear();
    _changes.notify();
  }
}

/// Enforces the contract rule: clean/infested need an inspection of the
/// same item whose verified finding agrees.
class InMemoryLabeledSampleRepository implements LabeledSampleRepository {
  InMemoryLabeledSampleRepository(this.scans, this.inspections);

  final InMemoryScanRepository scans;
  final InMemoryInspectionRepository inspections;
  final samples = <LabeledSample>[];
  final _changes = Changes();

  @override
  Future<LabeledSample> create(LabeledSampleDraft draft) async {
    final scan = scans.scans.where((s) => s.id == draft.scanId).firstOrNull;
    if (scan == null) throw ArgumentError('Unknown scan ${draft.scanId}');
    final needed = switch (draft.label) {
      SampleLabel.clean => VerifiedFinding.noneFound,
      SampleLabel.infested => VerifiedFinding.pestsFound,
      SampleLabel.unknown => null,
    };
    if (needed != null) {
      final evidence = inspections.inspections
          .where((i) => i.id == draft.inspectionId)
          .firstOrNull;
      if (evidence == null ||
          evidence.itemId != scan.itemId ||
          evidence.verifiedFinding != needed) {
        throw ArgumentError(
          'Label ${draft.label.name} needs an agreeing inspection',
        );
      }
    }
    final now = DateTime.now().toUtc();
    final sample = LabeledSample(
      id: testId('sample'),
      scanId: draft.scanId,
      itemId: scan.itemId,
      label: draft.label,
      inspectionId: draft.inspectionId,
      grainType: draft.grainType,
      sackMaterial: draft.sackMaterial,
      environment: draft.environment,
      notes: draft.notes,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    samples.add(sample);
    _changes.notify();
    return sample;
  }

  @override
  Stream<List<LabeledSample>> watchAll() =>
      _changes.watch(() => List.of(samples));

  void clear() {
    samples.clear();
    _changes.notify();
  }
}

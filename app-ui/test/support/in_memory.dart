// Test-only in-memory implementations of the contracts interfaces and the
// app-shell platform services. Never imported from lib/.

import 'dart:async';

import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

/// Broadcast change signal with "emit current value on listen" semantics,
/// like a drift watch query.
class _Changes {
  final _controller = StreamController<void>.broadcast(sync: true);

  void notify() => _controller.add(null);

  Stream<void> get stream => _controller.stream;

  // onCancel deliberately returns void: returning the broadcast
  // subscription's cancel future (a root-zone future) would stall
  // `Stream.first` under the widget-test FakeAsync zone.
  Stream<T> watch<T>(T Function() read) => Stream<T>.multi((sink) {
    sink.add(read());
    final sub = _controller.stream.listen((_) => sink.add(read()));
    sink.onCancel = () {
      sub.cancel();
    };
  });
}

int _seq = 0;
String _id(String prefix) => '$prefix-${++_seq}';

class InMemoryItemRepository implements ItemRepository {
  final items = <GrainItem>[];
  final _changes = _Changes();
  Stream<void> get changes => _changes.stream;

  @override
  Future<GrainItem> create(GrainItemDraft draft) async {
    final now = DateTime.now().toUtc();
    final item = GrainItem(
      id: _id('item'),
      ownerRole: draft.ownerRole,
      label: draft.label,
      grainType: draft.grainType,
      quantity: draft.quantity,
      quantityUnit: draft.quantityUnit,
      storageDate: draft.storageDate,
      locationId: draft.locationId,
      lotId: draft.lotId,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    items.add(item);
    _changes.notify();
    return item;
  }

  @override
  Future<GrainItem> update(GrainItem item) async {
    final index = items.indexWhere((i) => i.id == item.id);
    items[index] = item;
    _changes.notify();
    return item;
  }

  @override
  Future<GrainItem?> get(String id) async =>
      items.where((i) => i.id == id).firstOrNull;

  @override
  Stream<List<GrainItem>> watchByRole(Role role) =>
      _changes.watch(() => items.where((i) => i.ownerRole == role).toList());

  @override
  Stream<List<GrainItem>> watchByLocation(String locationId) => _changes.watch(
    () => items.where((i) => i.locationId == locationId).toList(),
  );

  @override
  Stream<List<GrainItem>> watchByLot(String lotId) =>
      _changes.watch(() => items.where((i) => i.lotId == lotId).toList());
}

class InMemoryLocationRepository implements LocationRepository {
  final locations = <Location>[];
  final _changes = _Changes();

  @override
  Future<Location> create(LocationDraft draft) async {
    final now = DateTime.now().toUtc();
    final location = Location(
      id: _id('loc'),
      type: draft.type,
      name: draft.name,
      parentId: draft.parentId,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    locations.add(location);
    _changes.notify();
    return location;
  }

  @override
  Future<Location?> get(String id) async =>
      locations.where((l) => l.id == id).firstOrNull;

  @override
  Stream<List<Location>> watchChildren(String? parentId) => _changes.watch(
    () => locations.where((l) => l.parentId == parentId).toList(),
  );
}

class InMemoryLotRepository implements LotRepository {
  final lots = <Lot>[];
  final _changes = _Changes();

  @override
  Future<Lot> create(LotDraft draft) async {
    final now = DateTime.now().toUtc();
    final lot = Lot(
      id: _id('lot'),
      code: draft.code,
      supplierId: draft.supplierId,
      supplierName: draft.supplierName,
      grainType: draft.grainType,
      declaredQuantity: draft.declaredQuantity,
      quantityUnit: draft.quantityUnit,
      receivedAt: draft.receivedAt,
      screeningStatus: ScreeningStatus.pending,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    lots.add(lot);
    _changes.notify();
    return lot;
  }

  @override
  Future<Lot?> get(String id) async =>
      lots.where((l) => l.id == id).firstOrNull;

  @override
  Stream<List<Lot>> watchAll() => _changes.watch(() => List.of(lots));

  @override
  Future<Lot> updateScreeningStatus(String id, ScreeningStatus status) async {
    final index = lots.indexWhere((l) => l.id == id);
    final old = lots[index];
    final lot = Lot(
      id: old.id,
      code: old.code,
      supplierId: old.supplierId,
      supplierName: old.supplierName,
      grainType: old.grainType,
      declaredQuantity: old.declaredQuantity,
      quantityUnit: old.quantityUnit,
      receivedAt: old.receivedAt,
      screeningStatus: status,
      createdAt: old.createdAt,
      updatedAt: DateTime.now().toUtc(),
      syncState: old.syncState,
    );
    lots[index] = lot;
    _changes.notify();
    return lot;
  }
}

class InMemoryScanRepository implements ScanRepository {
  final scans = <ScanRecord>[];
  final _changes = _Changes();
  Stream<void> get changes => _changes.stream;

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
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
    );
    scans.add(record);
    _changes.notify();
    return record;
  }

  @override
  Stream<List<ScanRecord>> watchForItem(String itemId) =>
      _changes.watch(() => scans.where((s) => s.itemId == itemId).toList());

  @override
  Stream<List<ScanRecord>> watchRecent({int limit = 50}) =>
      _changes.watch(() => scans.reversed.take(limit).toList());

  @override
  Future<ScanRecord?> latestValidForItem(String itemId) async =>
      scans.reversed.where((s) => s.itemId == itemId && s.isValid).firstOrNull;

  void clear() {
    scans.clear();
    _changes.notify();
  }
}

class InMemoryInspectionRepository implements InspectionRepository {
  final inspections = <Inspection>[];
  final drafts = <InspectionDraft>[];
  final _changes = _Changes();

  @override
  Future<Inspection> create(InspectionDraft draft) async {
    drafts.add(draft);
    final now = DateTime.now().toUtc();
    final inspection = Inspection(
      id: _id('insp'),
      itemId: draft.itemId,
      scanId: draft.scanId,
      inspectedAt: draft.inspectedAt,
      inspector: draft.inspector,
      observations: draft.observations,
      verifiedFinding: draft.verifiedFinding,
      followUpStatus: draft.followUpStatus,
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
    () => inspections.where((i) => i.itemId == itemId).toList(),
  );

  @override
  Stream<List<Inspection>> watchOpen() => _changes.watch(
    () => inspections
        .where((i) => i.followUpStatus != FollowUpStatus.done)
        .toList(),
  );

  @override
  Future<Inspection> updateFollowUp(String id, FollowUpStatus status) async {
    final index = inspections.indexWhere((i) => i.id == id);
    final old = inspections[index];
    final updated = Inspection(
      id: old.id,
      itemId: old.itemId,
      scanId: old.scanId,
      inspectedAt: old.inspectedAt,
      inspector: old.inspector,
      observations: old.observations,
      verifiedFinding: old.verifiedFinding,
      followUpStatus: status,
      createdAt: old.createdAt,
      updatedAt: DateTime.now().toUtc(),
      syncState: old.syncState,
    );
    inspections[index] = updated;
    _changes.notify();
    return updated;
  }

  void clear() {
    inspections.clear();
    _changes.notify();
  }
}

class InMemoryReminderRepository implements ReminderRepository {
  final reminders = <Reminder>[];
  final _changes = _Changes();

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
      id: _id('rem'),
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

  void clear() {
    reminders.clear();
    _changes.notify();
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({Role? activeRole}) : _role = activeRole;

  Role? _role;
  bool _retain = false;
  final roleWrites = <Role>[];
  final _changes = _Changes();

  Role? get activeRole => _role;
  bool get retainAudio => _retain;

  @override
  Stream<Role?> watchActiveRole() => _changes.watch(() => _role);

  @override
  Future<void> setActiveRole(Role role) async {
    roleWrites.add(role);
    _role = role;
    _changes.notify();
  }

  @override
  Stream<bool> watchRetainAudioOptIn() => _changes.watch(() => _retain);

  @override
  Future<void> setRetainAudioOptIn(bool value) async {
    _retain = value;
    _changes.notify();
  }
}

/// Follows the contract ranking rule for the test data it is given: rank
/// only items whose latest valid scan shares one model version.
class InMemoryRankingService implements RankingService {
  InMemoryRankingService(this.items, this.scans);

  final InMemoryItemRepository items;
  final InMemoryScanRepository scans;

  InspectionQueue _build(Role? role, String? locationId, String? lotId) {
    final scoped = items.items.where(
      (i) =>
          (role == null || i.ownerRole == role) &&
          (locationId == null || i.locationId == locationId) &&
          (lotId == null || i.lotId == lotId),
    );
    final ranked = <QueueEntry>[];
    final needsScan = <GrainItem>[];
    for (final item in scoped) {
      final valid = scans.scans.reversed
          .where((s) => s.itemId == item.id && s.isValid)
          .firstOrNull;
      if (valid == null) {
        needsScan.add(item);
      } else {
        ranked.add(QueueEntry(item: item, latestValidScan: valid));
      }
    }
    return InspectionQueue(
      ranked: ranked,
      needsScan: needsScan,
      modelVersion: ranked.isEmpty
          ? null
          : ranked.first.latestValidScan.modelVersion,
    );
  }

  @override
  Stream<InspectionQueue> watchQueue({
    Role? role,
    String? locationId,
    String? lotId,
  }) => Stream<InspectionQueue>.multi((sink) {
    void emit(void _) => sink.add(_build(role, locationId, lotId));
    emit(null);
    final subs = [items.changes.listen(emit), scans.changes.listen(emit)];
    sink.onCancel = () {
      for (final sub in subs) {
        sub.cancel();
      }
    };
  });
}

class RecordingReportService implements ReportService {
  final calls = <(ReportScope, ReportFormat)>[];
  Object? failWith;

  @override
  Future<String> export(ReportScope scope, ReportFormat format) async {
    calls.add((scope, format));
    final error = failWith;
    if (error != null) throw error;
    return '/data/user/0/com.kernel.kernel_app/files/report.${format.name}';
  }
}

class RecordingPrivacyService implements PrivacyService {
  RecordingPrivacyService({this.onDelete});

  final void Function()? onDelete;
  int deleteCalls = 0;

  @override
  Future<void> deleteAllHistory() async {
    deleteCalls++;
    onDelete?.call();
  }
}

/// Scan engine double that returns a scripted outcome per call.
class ScriptedScanEngine implements ScanEngine {
  ScriptedScanEngine({ScanOutcome Function(String itemId)? next})
    : next = next ?? notEvaluatedOutcome;

  ScanOutcome Function(String itemId) next;
  final calls = <({String itemId, bool retainAudio})>[];

  @override
  Future<ScanOutcome> captureAndAnalyze(
    String itemId, {
    bool retainAudio = false,
  }) async {
    calls.add((itemId: itemId, retainAudio: retainAudio));
    return next(itemId);
  }

  @override
  Future<EngineInfo> info() async => const EngineInfo(
    modelPresent: false,
    modelVersion: noModelVersion,
    experimental: true,
    targetSampleRate: 16000,
    effectiveSampleRate: null,
    delegate: InferenceDelegate.none,
    deviceModel: 'test-device',
    osVersion: 'test-os',
  );
}

ScanOutcome notEvaluatedOutcome(String itemId, {DateTime? at}) => ScanOutcome(
  scanId: _id('scan'),
  itemId: itemId,
  capturedAt: (at ?? DateTime.now()).toUtc(),
  quality: ScanQuality.pass,
  qualityReasons: const [],
  classification: Classification.notEvaluated,
  confidence: null,
  experimental: true,
  modelVersion: noModelVersion,
  latencyMs: 40,
  durationMs: 2000,
  sampleRate: 16000,
  deviceModel: 'test-device',
  osVersion: 'test-os',
);

ScanOutcome retryOutcome(
  String itemId, {
  List<QualityReason> reasons = const [QualityReason.highNoise],
  DateTime? at,
}) => ScanOutcome(
  scanId: _id('scan'),
  itemId: itemId,
  capturedAt: (at ?? DateTime.now()).toUtc(),
  quality: ScanQuality.retry,
  qualityReasons: reasons,
  classification: Classification.notEvaluated,
  confidence: null,
  experimental: true,
  modelVersion: noModelVersion,
  latencyMs: 35,
  durationMs: 2000,
  sampleRate: 16000,
  deviceModel: 'test-device',
  osVersion: 'test-os',
);

class ScriptedPermissions implements DevicePermissions {
  ScriptedPermissions({
    this.microphone = PermissionAccess.granted,
    this.afterRequest,
  });

  PermissionAccess microphone;

  /// Result of a request; defaults to the current [microphone] status.
  PermissionAccess? afterRequest;
  int micRequests = 0;
  int settingsOpened = 0;

  @override
  Future<PermissionAccess> microphoneStatus() async => microphone;

  @override
  Future<PermissionAccess> requestMicrophone() async {
    micRequests++;
    microphone = afterRequest ?? microphone;
    return microphone;
  }

  @override
  Future<PermissionAccess> requestNotifications() async =>
      PermissionAccess.granted;

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

class RecordingSharer implements ReportSharer {
  final shared = <String>[];

  @override
  Future<void> shareFile(String path, {required String subject}) async {
    shared.add(path);
  }
}

class RecordingFeedback implements ScanFeedback {
  final events = <String>[];

  @override
  Future<void> captureStarted() async => events.add('start');

  @override
  Future<void> captureFinished(ScanQuality quality) async =>
      events.add('end:${quality.name}');
}

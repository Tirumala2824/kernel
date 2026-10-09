// Test-only settings, ranking, report, privacy and dataset services.

import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';
import 'in_memory_inventory.dart';
import 'in_memory_records.dart';

export 'in_memory_records.dart' show InMemoryLabeledSampleRepository;

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({Role? activeRole, bool onboardingDone = true})
    : _role = activeRole,
      _onboarding = onboardingDone;

  Role? _role;
  bool _retain = false;
  bool _research = false;
  String? _language;
  bool _haptics = true;
  bool _voice = false;
  bool _onboarding;
  final roleWrites = <Role>[];
  final languageWrites = <String?>[];
  final _changes = Changes();

  Role? get activeRole => _role;
  bool get retainAudio => _retain;
  bool get researchMode => _research;
  String? get languageTag => _language;
  bool get haptics => _haptics;
  bool get voicePrompts => _voice;
  bool get onboardingDone => _onboarding;

  Future<void> _set(void Function() change) async {
    change();
    _changes.notify();
  }

  @override
  Stream<Role?> watchActiveRole() => _changes.watch(() => _role);

  @override
  Future<void> setActiveRole(Role role) => _set(() {
    roleWrites.add(role);
    _role = role;
  });

  @override
  Stream<bool> watchRetainAudioOptIn() => _changes.watch(() => _retain);

  @override
  Future<void> setRetainAudioOptIn(bool value) => _set(() => _retain = value);

  @override
  Stream<bool> watchResearchModeOptIn() => _changes.watch(() => _research);

  @override
  Future<void> setResearchModeOptIn(bool value) =>
      _set(() => _research = value);

  @override
  Stream<String?> watchLanguageTag() => _changes.watch(() => _language);

  @override
  Future<void> setLanguageTag(String? tag) => _set(() {
    languageWrites.add(tag);
    _language = tag;
  });

  @override
  Stream<bool> watchHaptics() => _changes.watch(() => _haptics);

  @override
  Future<void> setHaptics(bool value) => _set(() => _haptics = value);

  @override
  Stream<bool> watchVoicePrompts() => _changes.watch(() => _voice);

  @override
  Future<void> setVoicePrompts(bool value) => _set(() => _voice = value);

  @override
  Stream<bool> watchOnboardingDone() => _changes.watch(() => _onboarding);

  @override
  Future<void> setOnboardingDone(bool value) =>
      _set(() => _onboarding = value);
}

/// Follows the contract ranking rule for the test data it is given: rank
/// only items whose latest valid scan shares one model version. Location
/// scope includes nested places (decision 8).
class InMemoryRankingService implements RankingService {
  InMemoryRankingService(this.items, this.scans, this.locations);

  final InMemoryItemRepository items;
  final InMemoryScanRepository scans;
  final InMemoryLocationRepository locations;

  bool _within(String? locationId, String scope) {
    var current = locationId;
    for (var depth = 0; current != null && depth < 10; depth++) {
      if (current == scope) return true;
      current = locations.locations
          .where((x) => x.id == current)
          .firstOrNull
          ?.parentId;
    }
    return false;
  }

  InspectionQueue _build(Role? role, String? locationId, String? lotId) {
    final scoped = items.items.where(
      (i) =>
          !i.isArchived &&
          (role == null || i.ownerRole == role) &&
          (locationId == null || _within(i.locationId, locationId)) &&
          (lotId == null || i.lotId == lotId),
    );
    final ranked = <QueueEntry>[];
    final needsScan = <GrainItem>[];
    for (final item in scoped) {
      final valid = (scans.scans.where((s) => s.itemId == item.id && s.isValid)
            .toList()
          ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt)))
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

class RecordingDatasetExport implements DatasetExportService {
  int calls = 0;

  @override
  Future<String> exportZip() async {
    calls++;
    return '/data/user/0/com.kernel.kernel_app/files/dataset.zip';
  }
}

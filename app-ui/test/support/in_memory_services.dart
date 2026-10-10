// Test-only settings, ranking, report, privacy and dataset services.

import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';
import 'in_memory_inventory.dart';
import 'in_memory_records.dart';

export 'in_memory_records.dart' show InMemoryLabeledSampleRepository;

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({
    Role? activeRole,
    bool onboardingDone = true,
    bool localAdviceOptIn = false,
    this.roleEmitDelay,
    this.onboardingEmitDelay,
  }) : _role = activeRole,
       _onboarding = onboardingDone,
       _localAdvice = localAdviceOptIn;

  /// When set, watchActiveRole delivers every value this much later, like a
  /// slow database query (used to reproduce the onboarding race).
  final Duration? roleEmitDelay;

  /// Same for watchOnboardingDone.
  final Duration? onboardingEmitDelay;

  Role? _role;
  bool _retain = false;
  bool _research = false;
  String? _language;
  bool _haptics = true;
  bool _voice = false;
  bool _onboarding;
  bool _localAdvice;
  final roleWrites = <Role>[];
  final languageWrites = <String?>[];
  final localAdviceWrites = <bool>[];
  final _changes = Changes();

  Role? get activeRole => _role;
  bool get retainAudio => _retain;
  bool get researchMode => _research;
  String? get languageTag => _language;
  bool get haptics => _haptics;
  bool get voicePrompts => _voice;
  bool get onboardingDone => _onboarding;
  bool get localAdviceOptIn => _localAdvice;

  Future<void> _set(void Function() change) async {
    change();
    _changes.notify();
  }

  static Stream<T> _delayed<T>(Stream<T> source, Duration? delay) =>
      delay == null
      ? source
      : source.asyncMap((value) async {
          await Future<void>.delayed(delay);
          return value;
        });

  @override
  Stream<Role?> watchActiveRole() =>
      _delayed(_changes.watch(() => _role), roleEmitDelay);

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
  Stream<bool> watchOnboardingDone() =>
      _delayed(_changes.watch(() => _onboarding), onboardingEmitDelay);

  @override
  Future<void> setOnboardingDone(bool value) => _set(() => _onboarding = value);

  @override
  Stream<bool> watchLocalAdviceOptIn() => _changes.watch(() => _localAdvice);

  @override
  Future<void> setLocalAdviceOptIn(bool value) => _set(() {
    localAdviceWrites.add(value);
    _localAdvice = value;
  });

  bool _mapsConsent = false;
  bool _keepSightingMedia = false;
  final mapsConsentWrites = <bool>[];
  final keepSightingMediaWrites = <bool>[];

  bool get mapsConsent => _mapsConsent;
  bool get keepSightingMedia => _keepSightingMedia;

  @override
  Stream<bool> watchMapsConsent() => _changes.watch(() => _mapsConsent);

  @override
  Future<void> setMapsConsent(bool value) => _set(() {
    mapsConsentWrites.add(value);
    _mapsConsent = value;
  });

  @override
  Stream<bool> watchKeepSightingMedia() =>
      _changes.watch(() => _keepSightingMedia);

  @override
  Future<void> setKeepSightingMedia(bool value) => _set(() {
    keepSightingMediaWrites.add(value);
    _keepSightingMedia = value;
  });
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

  /// Every watchQueue call, so tests can assert the filters sent.
  final calls =
      <
        ({
          Role? role,
          String? locationId,
          String? lotId,
          Classification? result,
          Duration? maxAge,
        })
      >[];

  static int _severity(Classification c) => switch (c) {
    Classification.infested => 0,
    Classification.uncertain => 1,
    _ => 2,
  };

  InspectionQueue _build(
    Role? role,
    String? locationId,
    String? lotId,
    Classification? result,
    Duration? maxAge,
  ) {
    final now = DateTime.now();
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
      final valid =
          (scans.scans.where((s) => s.itemId == item.id && s.isValid).toList()
                ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt)))
              .firstOrNull;
      if (valid == null ||
          (maxAge != null && now.difference(valid.capturedAt) > maxAge)) {
        needsScan.add(item);
      } else if (result == null || valid.result == result) {
        ranked.add(
          QueueEntry(
            item: item,
            latestValidScan: valid,
            ageDays: now.difference(valid.capturedAt).inDays,
          ),
        );
      }
    }
    ranked.sort((a, b) {
      final bySeverity = _severity(a.latestValidScan.result)
          .compareTo(_severity(b.latestValidScan.result));
      if (bySeverity != 0) return bySeverity;
      return a.latestValidScan.capturedAt.compareTo(
        b.latestValidScan.capturedAt,
      );
    });
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
    Classification? result,
    Duration? maxAge,
  }) => Stream<InspectionQueue>.multi((sink) {
    calls.add((
      role: role,
      locationId: locationId,
      lotId: lotId,
      result: result,
      maxAge: maxAge,
    ));
    void emit(void _) =>
        sink.add(_build(role, locationId, lotId, result, maxAge));
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

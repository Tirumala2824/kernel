import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'providers.dart';

// Reactive read models over the repository interfaces. Every number on
// screen is derived from one of these streams; nothing is hard-coded.

// ---------------------------------------------------------------------------
// Settings.

final activeRoleProvider = StreamProvider<Role?>(
  (ref) => ref.watch(settingsRepositoryProvider).watchActiveRole(),
  name: 'activeRoleProvider',
);

final onboardingDoneProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchOnboardingDone(),
  name: 'onboardingDoneProvider',
);

final retainAudioOptInProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchRetainAudioOptIn(),
  name: 'retainAudioOptInProvider',
);

final researchModeProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchResearchModeOptIn(),
  name: 'researchModeProvider',
);

final languageTagProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).watchLanguageTag(),
  name: 'languageTagProvider',
);

final hapticsProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchHaptics(),
  name: 'hapticsProvider',
);

final voicePromptsProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchVoicePrompts(),
  name: 'voicePromptsProvider',
);

/// On-phone AI assistant opt-in. Off by default.
final localAdviceOptInProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchLocalAdviceOptIn(),
  name: 'localAdviceOptInProvider',
);

// ---------------------------------------------------------------------------
// Items, places, lots, harvests.

final itemsByRoleProvider = StreamProvider.autoDispose
    .family<List<GrainItem>, Role>(
      (ref, role) => ref.watch(itemRepositoryProvider).watchByRole(role),
    );

final itemsByLocationProvider = StreamProvider.autoDispose
    .family<List<GrainItem>, String>(
      (ref, locationId) =>
          ref.watch(itemRepositoryProvider).watchByLocation(locationId),
    );

final itemsByLotProvider = StreamProvider.autoDispose
    .family<List<GrainItem>, String>(
      (ref, lotId) => ref.watch(itemRepositoryProvider).watchByLot(lotId),
    );

final itemsByHarvestProvider = StreamProvider.autoDispose
    .family<List<GrainItem>, String>(
      (ref, harvestId) =>
          ref.watch(itemRepositoryProvider).watchByHarvest(harvestId),
    );

/// One item, including archived ones (history screens still resolve them).
/// Re-reads whenever the role's item list changes so archive/restore show
/// up immediately.
final itemProvider = FutureProvider.autoDispose.family<GrainItem?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(itemRepositoryProvider);
  final first = await repo.get(id);
  if (first != null) ref.watch(itemsByRoleProvider(first.ownerRole));
  return repo.get(id);
});

/// Top-level locations when the argument is null.
final childLocationsProvider = StreamProvider.autoDispose
    .family<List<Location>, String?>(
      (ref, parentId) =>
          ref.watch(locationRepositoryProvider).watchChildren(parentId),
    );

/// Every non-archived location, for pickers and the batch setup.
final allLocationsProvider = StreamProvider.autoDispose<List<Location>>(
  (ref) => ref.watch(locationRepositoryProvider).watchAll(),
);

final locationProvider = FutureProvider.autoDispose.family<Location?, String>((
  ref,
  id,
) {
  // Refresh when the location set changes (e.g. after archiving).
  ref.watch(allLocationsProvider);
  return ref.watch(locationRepositoryProvider).get(id);
});

final lotsProvider = StreamProvider.autoDispose<List<Lot>>(
  (ref) => ref.watch(lotRepositoryProvider).watchAll(),
);

/// Reactive single lot. Falls back to `get` so an archived lot (hidden from
/// watchAll) still resolves for history.
final lotProvider = FutureProvider.autoDispose.family<Lot?, String>((
  ref,
  id,
) async {
  final lots = await ref.watch(lotsProvider.future);
  return lots.where((lot) => lot.id == id).firstOrNull ??
      await ref.watch(lotRepositoryProvider).get(id);
});

final harvestsProvider = StreamProvider.autoDispose<List<Harvest>>(
  (ref) => ref.watch(harvestRepositoryProvider).watchAll(),
);

final harvestProvider = FutureProvider.autoDispose.family<Harvest?, String>((
  ref,
  id,
) async {
  final harvests = await ref.watch(harvestsProvider.future);
  return harvests.where((h) => h.id == id).firstOrNull ??
      await ref.watch(harvestRepositoryProvider).get(id);
});

// ---------------------------------------------------------------------------
// Scans (append-only history).

List<ScanRecord> newestFirst(List<ScanRecord> scans) =>
    [...scans]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

/// Immutable scan history for one item, newest first.
final scansForItemProvider = StreamProvider.autoDispose
    .family<List<ScanRecord>, String>(
      (ref, itemId) => ref
          .watch(scanRepositoryProvider)
          .watchForItem(itemId)
          .map(newestFirst),
    );

final recentScansProvider = StreamProvider.autoDispose
    .family<List<ScanRecord>, int>(
      (ref, limit) => ref
          .watch(scanRepositoryProvider)
          .watchRecent(limit: limit)
          .map(newestFirst),
    );

/// Arguments for [scansSinceProvider]. Records compare by value.
typedef ScansSince = ({DateTime since, Role? role});

final scansSinceProvider = StreamProvider.autoDispose
    .family<List<ScanRecord>, ScansSince>(
      (ref, args) => ref
          .watch(scanRepositoryProvider)
          .watchSince(args.since, role: args.role)
          .map(newestFirst),
    );

final scanProvider = FutureProvider.autoDispose.family<ScanRecord?, String>(
  (ref, scanId) => ref.watch(scanRepositoryProvider).get(scanId),
);

// ---------------------------------------------------------------------------
// Inspections, reminders, queue.

final inspectionsForItemProvider = StreamProvider.autoDispose
    .family<List<Inspection>, String>((ref, itemId) {
      return ref
          .watch(inspectionRepositoryProvider)
          .watchForItem(itemId)
          .map(
            (list) =>
                [...list]
                  ..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt)),
          );
    });

/// Open and in-progress inspections, oldest first.
final openInspectionsProvider = StreamProvider.autoDispose<List<Inspection>>(
  (ref) => ref.watch(inspectionRepositoryProvider).watchOpen(),
);

final remindersForItemProvider = StreamProvider.autoDispose
    .family<List<Reminder>, String>(
      (ref, itemId) =>
          ref.watch(reminderRepositoryProvider).watchForItem(itemId),
    );

final upcomingRemindersProvider = StreamProvider.autoDispose<List<Reminder>>(
  (ref) => ref.watch(reminderRepositoryProvider).watchUpcoming(),
);

/// Arguments for [inspectionQueueProvider]. Records compare by value.
typedef QueueScope = ({Role? role, String? locationId, String? lotId});

final inspectionQueueProvider = StreamProvider.autoDispose
    .family<InspectionQueue, QueueScope>(
      (ref, scope) => ref
          .watch(rankingServiceProvider)
          .watchQueue(
            role: scope.role,
            locationId: scope.locationId,
            lotId: scope.lotId,
          ),
    );

/// Arguments for [filteredQueueProvider]. Records compare by value.
typedef QueueFilter = ({
  Role? role,
  String? locationId,
  Classification? result,
  int? maxAgeDays,
});

/// The inspection queue narrowed by the queue screen's filter chips. The
/// ranking rule itself stays in RankingService.
final filteredQueueProvider = StreamProvider.autoDispose
    .family<InspectionQueue, QueueFilter>(
      (ref, filter) => ref
          .watch(rankingServiceProvider)
          .watchQueue(
            role: filter.role,
            locationId: filter.locationId,
            result: filter.result,
            maxAge: filter.maxAgeDays == null
                ? null
                : Duration(days: filter.maxAgeDays!),
          ),
    );

// ---------------------------------------------------------------------------
// On-device analytics (computed locally by AnalyticsService).

/// Arguments for the analytics providers. Records compare by value, unlike
/// AnalyticsFilter, so each scope gets one stream.
typedef AnalyticsScope = ({
  Role? role,
  String? locationId,
  String? lotId,
  Duration? window,
});

AnalyticsFilter analyticsFilterOf(AnalyticsScope scope) => AnalyticsFilter(
  role: scope.role,
  locationId: scope.locationId,
  lotId: scope.lotId,
  window: scope.window,
);

/// Scope covering everything a role owns, all time.
AnalyticsScope roleScope(Role role, {Duration? window}) =>
    (role: role, locationId: null, lotId: null, window: window);

/// Next steps for a role, most urgent (lowest priority value) first.
final nextActionsProvider = StreamProvider.autoDispose
    .family<List<NextAction>, Role>(
      (ref, role) => ref
          .watch(analyticsServiceProvider)
          .watchNextActions(role)
          .map(
            (actions) =>
                [...actions]..sort((a, b) => a.priority.compareTo(b.priority)),
          ),
    );

final resultRatesProvider = StreamProvider.autoDispose
    .family<ResultRates, AnalyticsScope>(
      (ref, scope) => ref
          .watch(analyticsServiceProvider)
          .watchResultRates(analyticsFilterOf(scope)),
    );

final qualityFailuresProvider = StreamProvider.autoDispose
    .family<QualityFailures, AnalyticsScope>(
      (ref, scope) => ref
          .watch(analyticsServiceProvider)
          .watchQualityFailures(analyticsFilterOf(scope)),
    );

final itemFreshnessProvider = StreamProvider.autoDispose
    .family<List<ItemFreshness>, AnalyticsScope>(
      (ref, scope) => ref
          .watch(analyticsServiceProvider)
          .watchItemFreshness(analyticsFilterOf(scope)),
    );

final inspectionStatsProvider = StreamProvider.autoDispose
    .family<InspectionStats, AnalyticsScope>(
      (ref, scope) => ref
          .watch(analyticsServiceProvider)
          .watchInspectionStats(analyticsFilterOf(scope)),
    );

final scanActivityProvider = StreamProvider.autoDispose
    .family<ScanActivity, AnalyticsScope>(
      (ref, scope) => ref
          .watch(analyticsServiceProvider)
          .watchScanActivity(analyticsFilterOf(scope)),
    );

// ---------------------------------------------------------------------------
// On-phone AI assistant status. An unbound or failing engine surfaces as an
// error value, which every caller treats as "not ready".

final adviceStatusProvider = StreamProvider.autoDispose<AdviceStatus>(
  (ref) => ref.watch(adviceEngineProvider).watchStatus(),
);

/// Status as the user should see it: the settings opt-in wins, so an
/// opted-out user always sees [AdviceStatus.optedOut].
final effectiveAdviceStatusProvider = Provider.autoDispose<AdviceStatus?>((
  ref,
) {
  final optIn = ref.watch(localAdviceOptInProvider).value;
  if (optIn == null) return null;
  if (!optIn) return AdviceStatus.optedOut;
  final status = ref.watch(adviceStatusProvider);
  if (status.hasError) return AdviceStatus.failed;
  return status.value;
});

/// True only when the user opted in and the model is loaded and idle.
/// Advice entry points are hidden otherwise.
final adviceReadyProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(effectiveAdviceStatusProvider) == AdviceStatus.ready,
);

/// Installed model details, re-read whenever the engine status changes.
final adviceModelInfoProvider = FutureProvider.autoDispose<AdviceModelInfo?>((
  ref,
) async {
  final engine = ref.watch(adviceEngineProvider);
  ref.watch(adviceStatusProvider);
  return engine.modelInfo();
});

// ---------------------------------------------------------------------------
// Engine and research samples.

final engineInfoProvider = FutureProvider.autoDispose<EngineInfo>(
  (ref) => ref.watch(scanEngineProvider).info(),
);

final labeledSamplesProvider = StreamProvider.autoDispose<List<LabeledSample>>(
  (ref) => ref.watch(labeledSampleRepositoryProvider).watchAll(),
);

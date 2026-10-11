// Test harness: builds KernelApp over in-memory test doubles.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_app/app/kernel_app.dart';
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/app/router.dart';
import 'package:kernel_app/app/routes.dart';
import 'package:kernel_app/l10n/app_localizations.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'in_memory.dart';

/// English strings, for asserting on copy without a BuildContext.
final en = lookupAppLocalizations(const Locale('en'));

class TestEnv {
  TestEnv({
    Role? role,
    this.offline = true,
    bool onboardingDone = true,
    InMemorySettingsRepository? settings,
  }) : settings =
           settings ??
           InMemorySettingsRepository(
             activeRole: role,
             onboardingDone: onboardingDone,
           ) {
    scans = InMemoryScanRepository(items);
    ranking = InMemoryRankingService(items, scans, locations);
    analytics = InMemoryAnalyticsService(items, scans, inspections, locations);
    samples = InMemoryLabeledSampleRepository(scans, inspections);
    privacy = RecordingPrivacyService(
      onDelete: () {
        scans.clear();
        inspections.clear();
        reminders.clear();
        samples.clear();
      },
    );
    provisioner = ScriptedModelProvisioner(modelRegistry);
    sensorEvents = InMemorySensorEventRepository(sensorNodes);
  }

  // Phase 4: model hub, knowledge cards and sensors.
  final modelCatalog = ScriptedModelCatalog();
  final modelRegistry = InMemoryModelRegistry();
  late final ScriptedModelProvisioner provisioner;
  final modelSearch = ScriptedModelSearch();
  final knowledge = ScriptedKnowledgeService();
  final sensorLink = ScriptedSensorLink();
  final sensorNodes = InMemorySensorNodeRepository();
  late final InMemorySensorEventRepository sensorEvents;

  final bool offline;
  final InMemorySettingsRepository settings;
  final items = InMemoryItemRepository();
  final locations = InMemoryLocationRepository();
  final lots = InMemoryLotRepository();
  final harvests = InMemoryHarvestRepository();
  late final InMemoryScanRepository scans;
  final inspections = InMemoryInspectionRepository();
  final reminders = InMemoryReminderRepository();
  late final InMemoryLabeledSampleRepository samples;
  late final InMemoryRankingService ranking;
  final reports = RecordingReportService();
  final dataset = RecordingDatasetExport();
  late final RecordingPrivacyService privacy;
  final engine = ScriptedScanEngine();
  final permissions = ScriptedPermissions();
  final sharer = RecordingSharer();
  final voice = RecordingVoicePrompter();
  final photos = ScriptedPhotoStore();
  final qr = ScriptedQrScanner();
  late final InMemoryAnalyticsService analytics;
  final advice = ScriptedAdviceEngine();
  final adviceModels = ScriptedAdviceModelManager();

  /// What the model file picker returns (null = the user cancelled).
  String? pickedModelUri;
  int pickerCalls = 0;

  Future<String?> _pickModel() async {
    pickerCalls++;
    return pickedModelUri;
  }

  /// Opts in to the on-phone assistant with a loaded, idle model.
  Future<void> enableAdvice() async {
    advice
      ..info = testAdviceModel
      ..status = AdviceStatus.ready;
    await settings.setLocalAdviceOptIn(true);
  }

  List<Override> get overrides => [
    analyticsServiceProvider.overrideWithValue(analytics),
    adviceEngineProvider.overrideWithValue(advice),
    adviceModelManagerProvider.overrideWithValue(adviceModels),
    modelFilePickerProvider.overrideWithValue(_pickModel),
    scanEngineProvider.overrideWithValue(engine),
    itemRepositoryProvider.overrideWithValue(items),
    locationRepositoryProvider.overrideWithValue(locations),
    lotRepositoryProvider.overrideWithValue(lots),
    harvestRepositoryProvider.overrideWithValue(harvests),
    scanRepositoryProvider.overrideWithValue(scans),
    inspectionRepositoryProvider.overrideWithValue(inspections),
    reminderRepositoryProvider.overrideWithValue(reminders),
    settingsRepositoryProvider.overrideWithValue(settings),
    labeledSampleRepositoryProvider.overrideWithValue(samples),
    rankingServiceProvider.overrideWithValue(ranking),
    reportServiceProvider.overrideWithValue(reports),
    datasetExportServiceProvider.overrideWithValue(dataset),
    privacyServiceProvider.overrideWithValue(privacy),
    connectivityResultsProvider.overrideWith(
      (ref) => Stream.value([
        offline ? ConnectivityResult.none : ConnectivityResult.wifi,
      ]),
    ),
    devicePermissionsProvider.overrideWithValue(permissions),
    reportSharerProvider.overrideWithValue(sharer),
    voicePrompterProvider.overrideWithValue(voice),
    photoStoreProvider.overrideWithValue(photos),
    photoImageProvider.overrideWithValue((_) => transparentPixel),
    qrScannerBuilderProvider.overrideWithValue(qr.build),
    appVersionProvider.overrideWith((ref) async => '0.1.0+1'),
    modelCatalogProvider.overrideWithValue(modelCatalog),
    modelRegistryProvider.overrideWithValue(modelRegistry),
    modelProvisionerProvider.overrideWithValue(provisioner),
    modelSearchProvider.overrideWithValue(modelSearch),
    knowledgeServiceProvider.overrideWithValue(knowledge),
    sensorLinkProvider.overrideWithValue(sensorLink),
    sensorNodeRepositoryProvider.overrideWithValue(sensorNodes),
    sensorEventRepositoryProvider.overrideWithValue(sensorEvents),
  ];

  Future<GrainItem> addItem({
    Role role = Role.farmer,
    String label = 'Sack A',
    String grain = 'Wheat',
    String? locationId,
    String? lotId,
    String? harvestId,
  }) => items.create(
    GrainItemDraft(
      ownerRole: role,
      label: label,
      grainType: grain,
      quantity: 50,
      quantityUnit: 'kg',
      storageDate: DateTime(2026, 9, 1),
      locationId: locationId,
      lotId: lotId,
      harvestId: harvestId,
    ),
  );

  Future<Inspection> addInspection(
    String itemId,
    VerifiedFinding finding, {
    String inspector = 'R. Devi',
    String? assignedTo,
    FollowUpStatus status = FollowUpStatus.open,
  }) => inspections.create(
    InspectionDraft(
      itemId: itemId,
      inspectedAt: DateTime.now(),
      inspector: inspector,
      observations: '',
      verifiedFinding: finding,
      assignedTo: assignedTo,
      followUpStatus: status,
    ),
  );
}

/// Pumps the full app at phone width (360 dp). The viewport is tall so
/// lazily built list sections exist without scrolling. Decorative motion
/// is reduced (as with the system setting) unless [reduceMotion] is false.
Future<void> pumpKernelApp(
  WidgetTester tester,
  TestEnv env, {
  String? location,
  bool reduceMotion = true,
}) async {
  tester.view.physicalSize = const Size(1080, 12000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    ProviderScope(overrides: env.overrides, child: const KernelApp()),
  );
  await tester.pumpAndSettle();
  if (location != null) {
    routerOf(tester).go(location);
    await tester.pumpAndSettle();
  } else if (env.settings.activeRole != null &&
      env.settings.onboardingDone &&
      routerOf(tester).routeInformationProvider.value.uri.path == Routes.chat) {
    // Legacy feature tests are explicit about their target screen; keep their
    // no-location default on Home while production startup remains chat-first.
    routerOf(tester).go(Routes.home);
    await tester.pumpAndSettle();
  }
}

GoRouter routerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(KernelApp)))
        .read(routerProvider);

/// Brings an already-built widget on screen, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

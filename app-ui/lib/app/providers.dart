import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

// One provider per contracts interface. All of them are unbound here on
// purpose: the real implementations (audio_ai's NativeScanEngine and
// data_operations' DataOperations fields) are bound in
// lib/bootstrap.dart via ProviderScope overrides. Widget tests bind
// in-memory test doubles that live only under test/.

Never _unbound(String provider, String interface, String package) {
  throw UnimplementedError(
    '$provider is not bound. Override it in bootstrapOverrides() '
    '(lib/bootstrap.dart) with the real $interface from package:$package.',
  );
}

final scanEngineProvider = Provider<ScanEngine>(
  (ref) => _unbound('scanEngineProvider', 'ScanEngine', 'audio_ai'),
  name: 'scanEngineProvider',
);

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) =>
      _unbound('itemRepositoryProvider', 'ItemRepository', 'data_operations'),
  name: 'itemRepositoryProvider',
);

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => _unbound(
    'locationRepositoryProvider',
    'LocationRepository',
    'data_operations',
  ),
  name: 'locationRepositoryProvider',
);

final lotRepositoryProvider = Provider<LotRepository>(
  (ref) =>
      _unbound('lotRepositoryProvider', 'LotRepository', 'data_operations'),
  name: 'lotRepositoryProvider',
);

final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) =>
      _unbound('scanRepositoryProvider', 'ScanRepository', 'data_operations'),
  name: 'scanRepositoryProvider',
);

final inspectionRepositoryProvider = Provider<InspectionRepository>(
  (ref) => _unbound(
    'inspectionRepositoryProvider',
    'InspectionRepository',
    'data_operations',
  ),
  name: 'inspectionRepositoryProvider',
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => _unbound(
    'reminderRepositoryProvider',
    'ReminderRepository',
    'data_operations',
  ),
  name: 'reminderRepositoryProvider',
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => _unbound(
    'settingsRepositoryProvider',
    'SettingsRepository',
    'data_operations',
  ),
  name: 'settingsRepositoryProvider',
);

final rankingServiceProvider = Provider<RankingService>(
  (ref) =>
      _unbound('rankingServiceProvider', 'RankingService', 'data_operations'),
  name: 'rankingServiceProvider',
);

final reportServiceProvider = Provider<ReportService>(
  (ref) =>
      _unbound('reportServiceProvider', 'ReportService', 'data_operations'),
  name: 'reportServiceProvider',
);

final privacyServiceProvider = Provider<PrivacyService>(
  (ref) =>
      _unbound('privacyServiceProvider', 'PrivacyService', 'data_operations'),
  name: 'privacyServiceProvider',
);

final harvestRepositoryProvider = Provider<HarvestRepository>(
  (ref) => _unbound(
    'harvestRepositoryProvider',
    'HarvestRepository',
    'data_operations',
  ),
  name: 'harvestRepositoryProvider',
);

final labeledSampleRepositoryProvider = Provider<LabeledSampleRepository>(
  (ref) => _unbound(
    'labeledSampleRepositoryProvider',
    'LabeledSampleRepository',
    'data_operations',
  ),
  name: 'labeledSampleRepositoryProvider',
);

final datasetExportServiceProvider = Provider<DatasetExportService>(
  (ref) => _unbound(
    'datasetExportServiceProvider',
    'DatasetExportService',
    'data_operations',
  ),
  name: 'datasetExportServiceProvider',
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => _unbound(
    'analyticsServiceProvider',
    'AnalyticsService',
    'data_operations',
  ),
  name: 'analyticsServiceProvider',
);

// On-phone AI assistant (opt-in, experimental). Bound to local_llm in
// bootstrap.dart. Every advice read in the UI tolerates an unbound or
// failing engine by falling back to the static localized copy.

final adviceEngineProvider = Provider<AdviceEngine>(
  (ref) => _unbound('adviceEngineProvider', 'AdviceEngine', 'local_llm'),
  name: 'adviceEngineProvider',
);

final adviceModelManagerProvider = Provider<AdviceModelManager>(
  (ref) => _unbound(
    'adviceModelManagerProvider',
    'AdviceModelManager',
    'local_llm',
  ),
  name: 'adviceModelManagerProvider',
);

/// Opens the system file picker for a `.litertlm` model and returns its
/// SAF content:// URI, or null when the user cancels.
typedef ModelFilePicker = Future<String?> Function();

/// Platform hook, bound to local_llm's `pickLitertlmUri` in bootstrap.dart.
final modelFilePickerProvider = Provider<ModelFilePicker>(
  (ref) => _unbound('modelFilePickerProvider', 'pickLitertlmUri', 'local_llm'),
  name: 'modelFilePickerProvider',
);

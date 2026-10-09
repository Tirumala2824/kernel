import 'package:flutter_riverpod/misc.dart' show Override;

/// Binds the providers in lib/app/providers.dart to real implementations.
///
/// Intentionally empty in this slice: the lead binds the real
/// implementations here during integration, for example
///
/// ```dart
/// final ops = await DataOperations.open();
/// return [
///   scanEngineProvider.overrideWithValue(NativeScanEngine()),
///   itemRepositoryProvider.overrideWithValue(ops.items),
///   locationRepositoryProvider.overrideWithValue(ops.locations),
///   lotRepositoryProvider.overrideWithValue(ops.lots),
///   scanRepositoryProvider.overrideWithValue(ops.scans),
///   inspectionRepositoryProvider.overrideWithValue(ops.inspections),
///   reminderRepositoryProvider.overrideWithValue(ops.reminders),
///   settingsRepositoryProvider.overrideWithValue(ops.settings),
///   rankingServiceProvider.overrideWithValue(ops.ranking),
///   reportServiceProvider.overrideWithValue(ops.reports),
///   privacyServiceProvider.overrideWithValue(ops.privacy),
/// ];
/// ```
///
/// Until then every unbound provider throws an UnimplementedError, which the
/// start screen reports as an incomplete setup.
Future<List<Override>> bootstrapOverrides() async {
  return const [];
}

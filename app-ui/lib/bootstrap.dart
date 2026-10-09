import 'package:audio_ai/audio_ai.dart';
import 'package:data_operations/data_operations.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/misc.dart' show Override;

import 'app/providers.dart';

/// Binds the providers in lib/app/providers.dart to the real on-device
/// implementations: the native scan engine and the local SQLite data layer.
///
/// If opening local data fails, the start screen reports an incomplete setup
/// because the unbound providers throw.
Future<List<Override>> bootstrapOverrides() async {
  final engine = NativeScanEngine();
  final DataOperations ops;
  try {
    ops = await DataOperations.open(
      deleteRetainedAudio: engine.deleteRetainedAudio,
      retainedAudioPath: engine.retainedAudioPath,
      currentModelNote: () async => (await engine.info()).modelNote,
    );
  } catch (error, stack) {
    debugPrint('Kernel: local data failed to open: $error\n$stack');
    return const [];
  }
  return [
    scanEngineProvider.overrideWithValue(engine),
    itemRepositoryProvider.overrideWithValue(ops.items),
    locationRepositoryProvider.overrideWithValue(ops.locations),
    lotRepositoryProvider.overrideWithValue(ops.lots),
    scanRepositoryProvider.overrideWithValue(ops.scans),
    inspectionRepositoryProvider.overrideWithValue(ops.inspections),
    reminderRepositoryProvider.overrideWithValue(ops.reminders),
    settingsRepositoryProvider.overrideWithValue(ops.settings),
    rankingServiceProvider.overrideWithValue(ops.ranking),
    reportServiceProvider.overrideWithValue(ops.reports),
    privacyServiceProvider.overrideWithValue(ops.privacy),
    harvestRepositoryProvider.overrideWithValue(ops.harvests),
    labeledSampleRepositoryProvider.overrideWithValue(ops.labeledSamples),
    datasetExportServiceProvider.overrideWithValue(ops.datasetExport),
  ];
}

import 'package:audio_ai/audio_ai.dart';
import 'package:data_operations/data_operations.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kernel_contracts/kernel_contracts.dart' show ModelCapability;
import 'package:local_llm/local_llm.dart';
import 'package:model_hub/model_hub.dart';
import 'package:sense_ai/sense_ai.dart';

import 'app/providers.dart';

/// Binds the providers in lib/app/providers.dart to the real on-device
/// implementations: the grain scan engine, the local SQLite data layer, the
/// model hub, the on-phone LLM/embedder and the Pest ID sensing engine.
///
/// No plugin imports another; they are joined only here. The grain pest path
/// (audio_ai) and the LLM path (local_llm) stay separate (guardrails §8).
/// model_hub is the only package with network code, and only for catalogs
/// and model files after consent (§7). Each engine gets its model file
/// through model_hub, so nothing is selected by hand.
///
/// If opening local data fails, the start screen reports an incomplete setup
/// because the unbound providers throw.
Future<List<Override>> bootstrapOverrides() async {
  final engine = NativeScanEngine();

  // The hub needs an embedder for semantic model search, and the embedder
  // finds its model through the hub, so the hub is created lazily here.
  late final ModelHub hub;
  Future<String?> pathFor(ModelCapability capability) =>
      hub.pathFor(capability);
  final embedder = LocalEmbedder(
    modelPath: () => pathFor(ModelCapability.embedText),
  );
  hub = ModelHub.create(probe: LiteRtModelProbe(), embedder: embedder);

  final DataOperations ops;
  try {
    ops = await DataOperations.open(
      deleteRetainedAudio: engine.deleteRetainedAudio,
      retainedAudioPath: engine.retainedAudioPath,
      currentModelNote: () async => (await engine.info()).modelNote,
      knowledgeCardsJson: () =>
          rootBundle.loadString('assets/knowledge/pest_cards.json'),
      embedder: embedder,
    );
  } catch (error, stack) {
    debugPrint('Kernel: local data failed to open: $error\n$stack');
    return const [];
  }

  final advice = LocalAdviceEngine(
    optIn: ops.settings.watchLocalAdviceOptIn(),
    modelPath: () => pathFor(ModelCapability.textGen),
  );
  final analyzer = LocalPestAnalyzer(
    modelPath: () => pathFor(ModelCapability.imageIn),
  );
  final sense = SenseEngine(
    embedder: embedder,
    soundModelPath: () => pathFor(ModelCapability.audioClassify),
  );

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
    analyticsServiceProvider.overrideWithValue(ops.analytics),
    adviceEngineProvider.overrideWithValue(advice),
    adviceModelManagerProvider.overrideWithValue(LocalModelManager()),
    modelFilePickerProvider.overrideWithValue(pickLitertlmUri),
    // Phase 4: model hub, Pest ID and knowledge.
    modelCatalogProvider.overrideWithValue(hub.catalog),
    modelRegistryProvider.overrideWithValue(hub.registry),
    modelProvisionerProvider.overrideWithValue(hub.provisioner),
    modelSearchProvider.overrideWithValue(hub.search),
    embedderProvider.overrideWithValue(embedder),
    pestAnalyzerProvider.overrideWithValue(analyzer),
    pestSenseEngineProvider.overrideWithValue(sense),
    senseCameraPreviewBuilderProvider.overrideWithValue(
      (context) => const SenseCameraPreview(),
    ),
    knowledgeServiceProvider.overrideWithValue(ops.knowledge),
    sightingRepositoryProvider.overrideWithValue(ops.sightings),
    sensorNodeRepositoryProvider.overrideWithValue(ops.sensorNodes),
    sensorEventRepositoryProvider.overrideWithValue(ops.sensorEvents),
  ];
}

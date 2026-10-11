import 'dart:async';

import 'package:audio_ai/audio_ai.dart';
import 'package:data_operations/data_operations.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/local_llm.dart';
import 'package:model_hub/model_hub.dart';
import 'package:sense_ai/sense_ai.dart';
import 'package:sensor_link/sensor_link.dart';

import 'app/providers.dart';
import 'features/sensors/sensor_providers.dart';

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
  // This pinned classifier is bundled with sense-ai. It needs neither local
  // records nor model downloads, so it remains available if storage fails.
  final soundBindings = <Override>[
    insectSoundClassifierProvider.overrideWithValue(
      NativeInsectSoundClassifier(),
    ),
  ];

  // The hub needs an embedder for semantic model search, and the embedder
  // finds its model through the hub, so the hub is created lazily here.
  late final ModelHub hub;
  Future<String?> pathFor(ModelCapability capability) =>
      hub.pathFor(capability);
  final embedder = LocalEmbedder(
    modelPath: () => pathFor(ModelCapability.embedText),
  );
  hub = ModelHub.create(probe: LiteRtModelProbe(), embedder: embedder);

  // Sensor nodes needing attention (jammed, clipped, low battery, survey
  // needed, auth failed, link error), fed from the BLE link below.
  final sensorAttention = StreamController<Set<String>>.broadcast();

  final DataOperations ops;
  try {
    ops = await DataOperations.open(
      deleteRetainedAudio: engine.deleteRetainedAudio,
      retainedAudioPath: engine.retainedAudioPath,
      currentModelNote: () async => (await engine.info()).modelNote,
      knowledgeCardsJson: () =>
          rootBundle.loadString('assets/knowledge/pest_cards.json'),
      embedder: embedder,
      sensorAttention: sensorAttention.stream,
    );
  } catch (error, stack) {
    debugPrint('Kernel: local data failed to open: $error\n$stack');
    return soundBindings;
  }

  // BLE frequency-detection nodes (guardrails §10). Events are persisted for
  // the whole app session (idempotent on node + seq), so a night of
  // store-and-forward events is never lost because no sensor screen was open.
  final sensorLink = BleSensorLink(lastSeqOf: ops.sensorEvents.lastSeq);
  final sensorBindings = bootstrapSensorOverrides(
    link: sensorLink,
    nodes: ops.sensorNodes,
    events: ops.sensorEvents,
    attention: sensorAttention,
  );

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
    ...soundBindings,
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
    ...sensorBindings,
  ];
}

/// Starts app-wide sensor observation and returns its provider bindings.
/// Kept separate so the real bootstrap ordering can run over local test data.
List<Override> bootstrapSensorOverrides({
  required SensorLink link,
  required SensorNodeRepository nodes,
  required SensorEventRepository events,
  required StreamController<Set<String>> attention,
}) {
  link.events().listen(
    (event) => events.record([event]),
    onError: (Object error) => debugPrint('Kernel: sensor event: $error'),
  );
  // Both streams are non-replaying. Attach persistence before watchStatus
  // can connect paired nodes and immediately report (or replay) health.
  link.healthChanges().listen(
    (change) => unawaited(
      events
          .recordHealth([change])
          .then(
            (_) {},
            onError: (Object error) =>
                debugPrint('Kernel: sensor health: $error'),
          ),
    ),
    onError: (Object error) => debugPrint('Kernel: sensor health: $error'),
  );
  _watchSensorAttention(link, nodes, attention);
  return [
    sensorNodeRepositoryProvider.overrideWithValue(nodes),
    sensorEventRepositoryProvider.overrideWithValue(events),
    sensorLinkProvider.overrideWithValue(link),
    // The app-session listeners above already own persistence. Screens only
    // observe readiness; they must not start another pair of subscriptions.
    sensorEventRecorderProvider.overrideWithValue(true),
  ];
}

const _attentionHealth = {
  SensorHealth.jammed,
  SensorHealth.clipped,
  SensorHealth.lowBattery,
  SensorHealth.surveyNeeded,
  SensorHealth.authFailed,
};

/// Keeps [sink] at the set of paired node ids whose latest status needs the
/// user (jammed/clipped mean "not evaluated", never "nothing there").
void _watchSensorAttention(
  SensorLink link,
  SensorNodeRepository nodes,
  StreamController<Set<String>> sink,
) {
  final needs = <String>{};
  final subs = <String, StreamSubscription<SensorStatus>>{};
  void publish() => sink.add(Set.unmodifiable(needs));
  nodes.watchAll().listen((list) {
    final ids = {for (final n in list) n.id};
    for (final gone in subs.keys.where((id) => !ids.contains(id)).toList()) {
      subs.remove(gone)?.cancel();
      needs.remove(gone);
    }
    for (final id in ids.where((id) => !subs.containsKey(id))) {
      subs[id] = link.watchStatus(id).listen((s) {
        final attention =
            s.linkState == SensorLinkState.error ||
            s.health.any(_attentionHealth.contains);
        final changed = attention ? needs.add(id) : needs.remove(id);
        if (changed) publish();
      });
    }
    publish();
  });
}

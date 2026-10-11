import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';

// Reactive read models for paired BLE sensor nodes (guardrails §10). Nodes
// send band energies and events only, never audio.

/// How far back the item "Sensor evidence" section looks.
const sensorEvidenceWindow = Duration(days: 7);

/// Default survey length (SensorLink.startSurvey).
const sensorSurveyDuration = Duration(minutes: 5);

final sensorNodesProvider = StreamProvider.autoDispose<List<SensorNode>>(
  (ref) => ref.watch(sensorNodeRepositoryProvider).watchAll(),
  name: 'sensorNodesProvider',
);

/// One paired node from the reactive list (null when not on this phone).
final sensorNodeProvider = Provider.autoDispose
    .family<AsyncValue<SensorNode?>, String>(
      (ref, id) => ref
          .watch(sensorNodesProvider)
          .whenData((nodes) => nodes.where((n) => n.id == id).firstOrNull),
      name: 'sensorNodeProvider',
    );

final sensorStatusProvider = StreamProvider.autoDispose
    .family<SensorStatus, String>(
      (ref, id) => ref.watch(sensorLinkProvider).watchStatus(id),
      name: 'sensorStatusProvider',
    );

/// A frame is live only within the observed authenticated connection.
/// Null clears the cached frame across a disconnect or unavailable status;
/// reconnecting alone must not revive the previous connection's last frame.
final sensorBandsProvider = StreamProvider.autoDispose
    .family<BandFrame?, String>((ref, id) {
      final link = ref.watch(sensorLinkProvider);
      final frames = StreamController<BandFrame?>();
      var connected = false;
      ref.listen(sensorStatusProvider(id), (_, status) {
        connected =
            !status.isLoading &&
            !status.hasError &&
            status.value?.linkState == SensorLinkState.authenticated;
        if (!connected) frames.add(null);
      }, fireImmediately: true);
      final sub = link
          .liveBands(id)
          .listen(
            (frame) {
              if (connected) frames.add(frame);
            },
            onError: frames.addError,
            onDone: () => frames.add(null),
          );
      ref.onDispose(() {
        unawaited(sub.cancel());
        unawaited(frames.close());
      });
      return frames.stream;
    }, name: 'sensorBandsProvider');

/// Newest first.
final sensorEventsForNodeProvider = StreamProvider.autoDispose
    .family<List<SensorEvent>, String>(
      (ref, id) => ref.watch(sensorEventRepositoryProvider).watchForNode(id),
      name: 'sensorEventsForNodeProvider',
    );

/// Events from nodes placed on one sack or container, last 7 days.
final sensorEventsForItemProvider = StreamProvider.autoDispose
    .family<List<SensorEvent>, String>(
      (ref, itemId) => ref
          .watch(sensorEventRepositoryProvider)
          .watchForItem(itemId, window: sensorEvidenceWindow),
      name: 'sensorEventsForItemProvider',
    );

/// Health gaps overlapping the same window as the item evidence.
final sensorNotEvaluatedForItemProvider = StreamProvider.autoDispose
    .family<List<SensorNotEvaluatedPeriod>, String>(
      (ref, itemId) => ref
          .watch(sensorEventRepositoryProvider)
          .watchNotEvaluated(itemId: itemId, window: sensorEvidenceWindow),
      name: 'sensorNotEvaluatedForItemProvider',
    );

/// The node timeline is not limited to the item's seven-day window.
final sensorNotEvaluatedForNodeProvider = StreamProvider.autoDispose
    .family<List<SensorNotEvaluatedPeriod>, String>(
      (ref, nodeId) => ref
          .watch(sensorEventRepositoryProvider)
          .watchNotEvaluated(nodeId: nodeId),
      name: 'sensorNotEvaluatedForNodeProvider',
    );

/// Standalone-scope fallback for recording events and health changes.
/// Production bootstrap starts recording before connecting paired nodes and
/// overrides this with true so opening a sensor screen cannot subscribe twice.
/// Without bootstrap, starts on first use and stays alive for the scope.
/// False when the sensor providers are not bound.
final sensorEventRecorderProvider = Provider<bool>((ref) {
  final SensorLink link;
  final SensorEventRepository repo;
  try {
    link = ref.watch(sensorLinkProvider);
    repo = ref.watch(sensorEventRepositoryProvider);
  } on Object {
    return false;
  }
  final sub = link.events().listen(
    (event) =>
        unawaited(repo.record([event]).then((_) {}, onError: (Object _) {})),
    onError: (Object _) {},
  );
  final healthSub = link.healthChanges().listen(
    (change) => unawaited(
      repo.recordHealth([change]).then((_) {}, onError: (Object _) {}),
    ),
    onError: (Object _) {},
  );
  ref.onDispose(() {
    unawaited(sub.cancel());
    unawaited(healthSub.cancel());
  });
  return true;
}, name: 'sensorEventRecorderProvider');

// ---------------------------------------------------------------------------
// Survey command state is separate from node telemetry. The current
// SensorStatus contract reports neither survey progress nor completion.

class SurveyState {
  const SurveyState({this.commandPending = false, this.error});

  final bool commandPending;
  final String? error;
}

class SurveyController extends Notifier<SurveyState> {
  SurveyController(this.nodeId);

  final String nodeId;

  @override
  SurveyState build() => const SurveyState();

  /// Requests a survey. Command return is not proof that it ran; radio
  /// problems are reported separately through SensorLink.watchStatus.
  Future<void> start() async {
    if (state.commandPending) return;
    state = const SurveyState(commandPending: true);
    try {
      await ref
          .read(sensorLinkProvider)
          .startSurvey(nodeId, duration: sensorSurveyDuration);
      if (ref.mounted) state = const SurveyState();
    } on Object catch (e) {
      if (ref.mounted) state = SurveyState(error: '$e');
    }
  }
}

final sensorSurveyProvider =
    NotifierProvider.family<SurveyController, SurveyState, String>(
      SurveyController.new,
      name: 'sensorSurveyProvider',
    );

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

final sensorBandsProvider = StreamProvider.autoDispose
    .family<BandFrame, String>(
      (ref, id) => ref.watch(sensorLinkProvider).liveBands(id),
      name: 'sensorBandsProvider',
    );

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

/// Records every event that connected nodes report (live or after a sync)
/// into the event repository; `record` is idempotent on (nodeId, seq).
/// Started by the sensor screens and kept alive for the app's lifetime.
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
    (event) => unawaited(
      repo.record([event]).then((_) {}, onError: (Object _) {}),
    ),
    onError: (Object _) {},
  );
  ref.onDispose(() => unawaited(sub.cancel()));
  return true;
}, name: 'sensorEventRecorderProvider');

// ---------------------------------------------------------------------------
// Survey and overnight session state, kept per node while the app runs so
// leaving the screen does not lose progress.

class SurveyState {
  const SurveyState({
    this.started = false,
    this.elapsed = Duration.zero,
    this.done = false,
    this.error,
  });

  final bool started;
  final Duration elapsed;
  final bool done;
  final String? error;

  bool get running => started && !done && error == null;

  /// Progress in 0..1 of the survey window.
  double get progress => done
      ? 1
      : (elapsed.inMilliseconds / sensorSurveyDuration.inMilliseconds).clamp(
          0.0,
          1.0,
        );
}

class SurveyController extends Notifier<SurveyState> {
  SurveyController(this.nodeId);

  static const _tickEvery = Duration(seconds: 1);

  final String nodeId;
  Timer? _ticker;
  bool _commandDone = false;

  @override
  SurveyState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const SurveyState();
  }

  /// Starts a 5-minute survey. It counts as finished once the node call has
  /// returned and the survey window has passed.
  Future<void> start() async {
    if (state.running) return;
    _commandDone = false;
    state = const SurveyState(started: true);
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickEvery, (_) => _advance(_tickEvery));
    try {
      await ref
          .read(sensorLinkProvider)
          .startSurvey(nodeId, duration: sensorSurveyDuration);
      _commandDone = true;
      _advance(Duration.zero);
    } on Object catch (e) {
      _ticker?.cancel();
      state = SurveyState(started: true, elapsed: state.elapsed, error: '$e');
    }
  }

  void _advance(Duration by) {
    if (!state.running) {
      _ticker?.cancel();
      return;
    }
    final elapsed = state.elapsed + by;
    if (_commandDone && elapsed >= sensorSurveyDuration) {
      _ticker?.cancel();
      state = SurveyState(started: true, elapsed: elapsed, done: true);
    } else {
      state = SurveyState(started: true, elapsed: elapsed);
    }
  }
}

final sensorSurveyProvider =
    NotifierProvider.family<SurveyController, SurveyState, String>(
      SurveyController.new,
      name: 'sensorSurveyProvider',
    );

/// Nodes with an overnight session started from this app run. SensorLink
/// has no session-state stream, so this is the app's own record.
class SessionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  Future<void> start(String nodeId) async {
    await ref.read(sensorLinkProvider).startSession(nodeId);
    state = {...state, nodeId};
  }

  Future<void> stop(String nodeId) async {
    await ref.read(sensorLinkProvider).stopSession(nodeId);
    state = {...state}..remove(nodeId);
  }
}

final sensorSessionsProvider =
    NotifierProvider<SessionController, Set<String>>(
      SessionController.new,
      name: 'sensorSessionsProvider',
    );

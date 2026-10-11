import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../advice/advice_card.dart';
import 'pest_copy.dart';
import 'pest_listen_sections.dart';
import 'pest_providers.dart';
import 'pest_session.dart';

/// Search words for knowledge cards from a confirmed sound.
String soundQuery(List<ScoredLabel> labels, SoundAnalysis? sound) => [
  for (final label in labels.take(3)) label.label,
  if (sound != null && sound.groupHint != PestGroup.unknown)
    sound.groupHint.name,
].join(' ');

/// Listen mode: live sound-event candidates with sound-classifier labels.
/// The user confirms one, then the clip is described on the phone.
class PestListenScreen extends ConsumerStatefulWidget {
  const PestListenScreen({super.key});

  @override
  ConsumerState<PestListenScreen> createState() => _PestListenScreenState();
}

class _PestListenScreenState extends ConsumerState<PestListenScreen> {
  late final PestSenseEngine _engine = ref.read(pestSenseEngineProvider);
  ListenMode _mode = ListenMode.general;
  StreamSubscription<SignalCandidate>? _sub;
  final _events = <SignalCandidate>[];
  final _labels = <String, List<ScoredLabel>>{};
  bool _micDenied = false;
  bool _nightBlocked = false;
  bool _confirming = false;
  bool _clipGone = false;
  bool _listenFailed = false;

  bool get _listening => _sub != null;

  @override
  void dispose() {
    unawaited(_stop());
    super.dispose();
  }

  Future<void> _start() async {
    final permissions = ref.read(devicePermissionsProvider);
    setState(() {
      _micDenied = false;
      _listenFailed = false;
      _nightBlocked = false;
      _clipGone = false;
    });
    var mic = await permissions.microphoneStatus();
    if (mic != PermissionAccess.granted) {
      mic = await permissions.requestMicrophone();
    }
    if (mic != PermissionAccess.granted) {
      if (mounted) setState(() => _micDenied = true);
      return;
    }
    if (_mode == ListenMode.night) {
      // Night listening runs as a foreground service with a visible
      // notification, so the user can always see and stop it.
      final notices = await permissions.requestNotifications();
      if (notices != PermissionAccess.granted) {
        if (mounted) setState(() => _nightBlocked = true);
        return;
      }
    }
    if (!mounted) return;
    // A new listen drops any earlier clip first.
    await ref.read(pestSessionProvider.notifier).finish();
    if (!mounted) return;
    setState(() {
      _events.clear();
      _labels.clear();
      _sub = _engine
          .listen(_mode)
          .listen(_onEvent, onError: _onError, onDone: _onDone);
    });
  }

  void _onError(Object error) {
    if (mounted) setState(() => _listenFailed = true);
    unawaited(_stop());
  }

  void _onDone() {
    if (mounted) setState(() => _sub = null);
  }

  Future<void> _onEvent(SignalCandidate candidate) async {
    if (!mounted || _events.any((e) => e.id == candidate.id)) return;
    setState(() => _events.insert(0, candidate));
    List<ScoredLabel> labels;
    try {
      labels = await _engine.soundLabelsFor(candidate.id);
    } on Object {
      labels = const [];
    }
    if (mounted) setState(() => _labels[candidate.id] = labels);
  }

  Future<void> _stop() async {
    final sub = _sub;
    _sub = null;
    if (sub == null) return;
    // Not awaited: the engine's stopListening is the real stop.
    unawaited(sub.cancel());
    try {
      await _engine.stopListening();
    } on Object {
      // Already stopped.
    }
  }

  Future<void> _confirm(SignalCandidate candidate) async {
    final lang = adviceLanguageTag(context);
    setState(() => _confirming = true);
    await _stop();
    Uint8List? clip;
    try {
      clip = await _engine.clipFor(candidate.id);
    } on Object {
      clip = null;
    }
    var labels = _labels[candidate.id];
    if (labels == null) {
      try {
        labels = await _engine.soundLabelsFor(candidate.id);
      } on Object {
        labels = const [];
      }
    }
    final session = ref.read(pestSessionProvider.notifier)
      ..confirmSound(candidate, labels, clip);
    if (clip == null) {
      if (mounted) {
        setState(() {
          _confirming = false;
          _clipGone = true;
        });
      }
      return;
    }
    final cards = await loadKnowledgeCards(ref.read(knowledgeServiceProvider));
    SoundAnalysis? sound;
    try {
      sound = await ref
          .read(pestAnalyzerProvider)
          .describeSound(
            PestSoundRequest(
              wav: clip,
              preFilter: labels,
              allowedCardIds: [for (final c in cards) c.id],
              languageTag: lang,
            ),
          );
    } on Object {
      sound = null;
    }
    var matches = const <KnowledgeCard>[];
    try {
      final hits = await ref
          .read(knowledgeServiceProvider)
          .search(soundQuery(labels, sound), limit: 3);
      matches = [for (final h in hits) h.card];
    } on Object {
      matches = const [];
    }
    if (!mounted) return;
    session.setSound(sound, soundCards: matches, cards: cards);
    setState(() => _confirming = false);
  }

  Future<void> _listenAgain() async {
    await ref.read(pestSessionProvider.notifier).finish();
    if (!mounted) return;
    setState(() {
      _events.clear();
      _labels.clear();
      _clipGone = false;
    });
  }

  Future<void> _discard() async {
    final router = GoRouter.of(context);
    await ref.read(pestSessionProvider.notifier).finish();
    router.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = ref.watch(pestSessionProvider);
    final confirmed =
        session.source == SignalSource.microphone && session.candidate != null;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(ref.read(pestSessionProvider.notifier).finish());
      },
      child: Scaffold(
        appBar: KernelAppBar(title: l.pestListenTitle),
        body: PageList(
          children: [
            if (!confirmed || _clipGone) ..._listenControls(l),
            if (_confirming)
              Text(l.pestSoundDescribing, key: const Key('pest-describing')),
            if (confirmed && !_confirming && !_clipGone)
              PestSoundResult(
                session: session,
                onPick: (id) =>
                    ref.read(pestSessionProvider.notifier).pickCard(id),
                onSave: () => context.push(Routes.pestSave),
                onDiscard: _discard,
                onListenAgain: _listenAgain,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _listenControls(AppLocalizations l) => [
    Wrap(
      key: const Key('pest-listen-mode'),
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in ListenMode.values)
          ChoiceChip(
            key: Key('pest-mode-${mode.name}'),
            label: Text(mode.label(l)),
            selected: _mode == mode,
            onSelected: _listening
                ? null
                : (_) => setState(() {
                    _mode = mode;
                    _nightBlocked = false;
                  }),
          ),
      ],
    ),
    QuietNote(_mode.help(l), icon: Icons.tips_and_updates_rounded),
    if (_micDenied)
      NoticeBanner(
        key: const Key('pest-mic-denied'),
        text: l.pestListenMicDenied,
        icon: Icons.mic_off_rounded,
      ),
    if (_nightBlocked)
      NoticeBanner(
        key: const Key('pest-night-blocked'),
        text: l.pestListenNightNeedsNotice,
        icon: Icons.notifications_off_rounded,
      ),
    if (_clipGone)
      NoticeBanner(key: const Key('pest-clip-gone'), text: l.pestClipGone),
    if (_listening)
      FilledButton.tonalIcon(
        key: const Key('pest-listen-stop'),
        onPressed: () async {
          await _stop();
          if (mounted) setState(() {});
        },
        icon: const Icon(Icons.stop_rounded),
        label: Text(l.pestListenStop),
      )
    else
      FilledButton.icon(
        key: const Key('pest-listen-start'),
        onPressed: _confirming ? null : _start,
        icon: const Icon(Icons.hearing_rounded),
        label: Text(l.pestListenStart),
      ),

    // A candidate subscription is not microphone status telemetry.
    if (_listenFailed)
      NoticeBanner(
        key: const Key('pest-listen-failed'),
        text: l.qualityShortCaptureError,
        icon: Icons.mic_off_rounded,
      ),
    if (_events.isNotEmpty) ...[
      Text(l.pestListenTapToConfirm),
      for (final event in _events)
        PestSoundEventTile(
          candidate: event,
          labels: _labels[event.id],
          onConfirm: _confirming ? null : () => _confirm(event),
        ),
    ],
  ];
}

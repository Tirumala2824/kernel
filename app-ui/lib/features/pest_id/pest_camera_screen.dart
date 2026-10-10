import 'dart:async';

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
import 'pest_camera_overlay.dart';
import 'pest_providers.dart';
import 'pest_ranking.dart';
import 'pest_session.dart';
import 'pest_tiles.dart';

/// Live preview with candidate boxes, a torch slider and Capture. The user
/// confirms a box or a close-up tile; only then is anything analysed.
class PestCameraScreen extends ConsumerStatefulWidget {
  const PestCameraScreen({super.key});

  @override
  ConsumerState<PestCameraScreen> createState() => _PestCameraScreenState();
}

class _PestCameraScreenState extends ConsumerState<PestCameraScreen> {
  PermissionAccess? _camera;
  double _torch = 0;
  bool _busy = false;
  bool _captureFailed = false;
  CapturedStill? _still;
  List<RankedTile>? _ranked;

  @override
  void initState() {
    super.initState();
    unawaited(_checkCamera());
  }

  Future<void> _checkCamera() async {
    final permissions = ref.read(devicePermissionsProvider);
    var access = await permissions.cameraStatus();
    if (access != PermissionAccess.granted) {
      access = await permissions.requestCamera();
    }
    if (mounted) setState(() => _camera = access);
  }

  Future<void> _setTorch(double level) async {
    setState(() => _torch = level);
    try {
      await ref.read(pestSenseEngineProvider).setTorch(level);
    } on Object {
      // No torch on this camera; the slider simply has no effect.
    }
  }

  Future<CapturedStill?> _capture(List<SignalCandidate> candidates) async {
    setState(() {
      _busy = true;
      _captureFailed = false;
    });
    CapturedStill? still;
    try {
      still = await ref
          .read(pestSenseEngineProvider)
          .captureStill(candidates: candidates);
    } on Object {
      still = null;
    }
    if (!mounted) return null;
    setState(() {
      _busy = false;
      _captureFailed = still == null;
    });
    return still;
  }

  /// Capture: show the tiles ranked by embedding hint.
  Future<void> _captureAll() async {
    final candidates = ref.read(cameraCandidatesProvider).value ?? const [];
    final still = await _capture(candidates);
    if (still == null || !mounted) return;
    setState(() => _busy = true);
    final cards = await loadKnowledgeCards(ref.read(knowledgeServiceProvider));
    Embedder? embedder;
    try {
      embedder = ref.read(embedderProvider);
    } on Object {
      embedder = null;
    }
    final ranked = await rankTiles(
      still,
      candidates,
      embedder: embedder,
      cards: cards,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _still = still;
      _ranked = ranked;
    });
  }

  /// Tapping a live box confirms it: grab a still for just that box.
  Future<void> _confirmBox(SignalCandidate candidate) async {
    final still = await _capture([candidate]);
    if (still == null || !mounted) return;
    final tile =
        still.tiles.where((t) => t.candidateId == candidate.id).firstOrNull ??
        still.tiles.firstOrNull;
    if (tile == null) {
      setState(() {
        _still = still;
        _ranked = const [];
      });
      return;
    }
    _openAnalysis(still, tile, candidate);
  }

  void _confirmTile(RankedTile ranked) =>
      _openAnalysis(_still!, ranked.tile, ranked.candidate);

  void _openAnalysis(
    CapturedStill still,
    ImageTile tile,
    SignalCandidate? candidate,
  ) {
    ref.read(pestSessionProvider.notifier).confirmTile(still, tile, candidate);
    context.push(Routes.pestAnalysis);
  }

  Future<void> _nothingHere() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.pestNothingHereDone;
    final router = GoRouter.of(context);
    await ref.read(pestSessionProvider.notifier).finish();
    messenger.showSnackBar(SnackBar(content: Text(message)));
    if (router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(ref.read(pestSessionProvider.notifier).finish());
      },
      child: Scaffold(
        appBar: KernelAppBar(title: l.pestCameraTitle),
        body: PageList(
          children: [
            QuietNote(l.pestCameraTip, icon: Icons.tips_and_updates_rounded),
            ..._body(l),
            OutlinedButton.icon(
              key: const Key('pest-nothing-here'),
              onPressed: _busy ? null : _nothingHere,
              icon: const Icon(Icons.do_not_disturb_alt_rounded),
              label: Text(l.pestNothingHere, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(AppLocalizations l) {
    final camera = _camera;
    if (camera == null) {
      return const [Center(child: CircularProgressIndicator())];
    }
    if (camera != PermissionAccess.granted) {
      return [
        NoticeBanner(
          key: const Key('pest-camera-denied'),
          text: l.pestCameraDenied,
          icon: Icons.no_photography_rounded,
        ),
        OutlinedButton.icon(
          onPressed: () => ref.read(devicePermissionsProvider).openSettings(),
          icon: const Icon(Icons.settings_rounded),
          label: Text(l.actionOpenSettings),
        ),
      ];
    }
    final ranked = _ranked;
    if (ranked != null) {
      final cards = ref.watch(knowledgeCardsProvider).value ?? const [];
      return [
        PestTilesView(tiles: ranked, cards: cards, onConfirm: _confirmTile),
        FilledButton.tonalIcon(
          key: const Key('pest-capture-again'),
          onPressed: () => setState(() {
            _ranked = null;
            _still = null;
          }),
          icon: const Icon(Icons.replay_rounded),
          label: Text(l.pestRetake),
        ),
      ];
    }
    final candidates =
        ref.watch(cameraCandidatesProvider).value ?? const <SignalCandidate>[];
    return [
      PestLivePreview(candidates: candidates, onConfirm: _confirmBox),
      Text(
        candidates.isEmpty
            ? l.pestCandidatesNone
            : l.pestCandidatesCount(candidates.length),
        key: const Key('pest-candidate-count'),
      ),
      PestTorchSlider(value: _torch, onChanged: _setTorch),
      if (_captureFailed) ErrorNote(l.pestCaptureFailed),
      FilledButton.icon(
        key: const Key('pest-capture'),
        onPressed: _busy ? null : _captureAll,
        icon: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.camera_rounded),
        label: Text(_busy ? l.pestCapturing : l.pestCapture),
      ),
    ];
  }
}

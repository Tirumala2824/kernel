import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../app/rules.dart';
import '../../brand/kernel_brand.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/level_meter.dart';

/// Gap after a spoken prompt so its tail never reaches the recording.
const voiceSettleDelay = Duration(milliseconds: 400);

enum CapturePhase { ready, requesting, prompting, capturing, saving, failed }

/// One guided capture for [itemId]: microphone permission, optional voice
/// prompts, live levels from [ScanEngine.captureLevels], then
/// [ScanEngine.captureAndAnalyze] and an append-only save. The stored
/// record is handed to [onRecorded].
class CapturePanel extends ConsumerStatefulWidget {
  const CapturePanel({
    super.key,
    required this.itemId,
    required this.onRecorded,
    required this.onDenied,
    this.research = false,
    this.autoStart = false,
  });

  final String itemId;
  final ValueChanged<ScanRecord> onRecorded;
  final ValueChanged<PermissionAccess> onDenied;

  /// Research recording: the audio is always retained for labelling.
  final bool research;

  /// Start immediately (e.g. after "Try again" on the mic-denied view).
  final bool autoStart;

  @override
  ConsumerState<CapturePanel> createState() => _CapturePanelState();
}

class _CapturePanelState extends ConsumerState<CapturePanel> {
  CapturePhase _phase = CapturePhase.ready;
  final List<CaptureLevel> _levels = [];
  StreamSubscription<CaptureLevel>? _levelSub;
  String? _error;
  bool _disposed = false;
  late final VoicePrompter _prompter;

  @override
  void initState() {
    super.initState();
    _prompter = ref.read(voicePrompterProvider);
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _levelSub?.cancel();
    _prompter.stop();
    super.dispose();
  }

  void _set(CapturePhase phase, {String? error}) {
    if (!mounted) return;
    setState(() {
      _phase = phase;
      _error = error;
    });
  }

  Future<void> _start() async {
    final l = context.l10n;
    final languageTag = Localizations.localeOf(context).languageCode;
    _set(CapturePhase.requesting);
    _levels.clear();

    final permissions = ref.read(devicePermissionsProvider);
    var access = await permissions.microphoneStatus();
    if (access != PermissionAccess.granted) {
      access = await permissions.requestMicrophone();
    }
    if (_disposed) return;
    if (access != PermissionAccess.granted) {
      _set(CapturePhase.ready);
      widget.onDenied(access);
      return;
    }

    // Explicit opt-in only: anything but a loaded `true` discards audio.
    final retainAudio =
        widget.research || (ref.read(retainAudioOptInProvider).value ?? false);
    final haptics = ref.read(hapticsProvider).value ?? true;
    final voice = ref.read(voicePromptsProvider).value ?? false;
    final prompter = _prompter;
    final engine = ref.read(scanEngineProvider);
    final scans = ref.read(scanRepositoryProvider);

    if (voice) {
      _set(CapturePhase.prompting);
      await prompter.speak(l.voicePlacePhone, languageTag: languageTag);
      if (_disposed) return;
      await prompter.speak(l.voiceListening, languageTag: languageTag);
      await Future<void>.delayed(voiceSettleDelay);
      if (_disposed) return;
    }

    // Subscribe before starting so the first levels are not missed.
    _levelSub = engine.captureLevels().listen(
      (level) {
        if (!mounted) return;
        setState(() => _levels.add(level));
      },
      onError: (Object _) {},
    );
    _set(CapturePhase.capturing);

    final ScanOutcome outcome;
    try {
      outcome = await engine.captureAndAnalyze(
        widget.itemId,
        retainAudio: retainAudio,
        haptics: haptics,
      );
    } on Object catch (e) {
      _levelSub?.cancel();
      _levelSub = null;
      _set(CapturePhase.failed, error: l.scanCouldNotRun('$e'));
      return;
    }
    _levelSub?.cancel();
    _levelSub = null;
    if (voice && !_disposed) {
      unawaited(prompter.speak(l.voiceDone, languageTag: languageTag));
    }
    if (_disposed) return;
    _set(CapturePhase.saving);

    try {
      final record = await scans.record(outcome);
      if (_disposed) return;
      widget.onRecorded(record);
    } on Object catch (e) {
      _set(CapturePhase.failed, error: l.scanCouldNotSave('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the settings streams alive so their values are ready on start.
    ref.watch(retainAudioOptInProvider);
    ref.watch(hapticsProvider);
    ref.watch(voicePromptsProvider);
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final item = ref.watch(itemProvider(widget.itemId)).value;
    final kind = item?.ownerRole.itemKind ?? 'sack';
    final busy =
        _phase == CapturePhase.requesting ||
        _phase == CapturePhase.prompting ||
        _phase == CapturePhase.capturing ||
        _phase == CapturePhase.saving;
    final last = _levels.isEmpty ? null : _levels.last;
    final hint = levelHint(_levels);
    final title = switch (_phase) {
      CapturePhase.capturing => l.captureListening,
      CapturePhase.saving => l.captureSaving,
      CapturePhase.requesting => l.captureCheckingMic,
      CapturePhase.prompting => l.captureGetReady,
      _ => l.captureReady,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('hero-capture'),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [KernelColors.forestSoft, KernelColors.forestDeep],
            ),
            borderRadius: BorderRadius.circular(KernelRadii.xl),
            boxShadow: KernelShadows.lifted,
          ),
          padding: const EdgeInsets.all(KernelSpace.xl - 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox.square(
                  dimension: 132,
                  child: ListeningRings(
                    rings: 4,
                    animate: busy,
                    intensity: _phase == CapturePhase.capturing && last != null
                        ? levelFraction(last.rmsDbfs)
                        : null,
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: KernelColors.ivory,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: _phase == CapturePhase.capturing
                            ? const Icon(
                                Icons.mic_rounded,
                                color: KernelColors.forest,
                                size: 32,
                              )
                            : const KernelMark(size: 44),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: KernelSpace.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: KernelColors.onForest,
                  ),
                ),
              ),
              const SizedBox(height: KernelSpace.xs),
              Text(
                widget.research
                    ? l.captureResearchSubtitle
                    : l.captureSubtitle(kind),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: KernelColors.onForest.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: KernelSpace.lg),
              if (_phase == CapturePhase.capturing ||
                  _phase == CapturePhase.saving)
                _LiveSection(levels: _levels, hint: hint, saving: _phase == CapturePhase.saving)
              else
                FilledButton.icon(
                  key: const Key('start-capture'),
                  style: FilledButton.styleFrom(
                    backgroundColor: KernelColors.amber,
                    foregroundColor: KernelColors.ink,
                    disabledBackgroundColor: KernelColors.amber.withValues(
                      alpha: 0.6,
                    ),
                    disabledForegroundColor: KernelColors.ink,
                    minimumSize: const Size.fromHeight(56),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: busy ? null : _start,
                  icon: const Icon(Icons.mic_rounded),
                  label: Text(
                    _phase == CapturePhase.failed
                        ? l.captureStartAgain
                        : widget.research
                        ? l.captureStartResearch
                        : l.captureStart,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: KernelSpace.md),
          ErrorNote(_error!),
        ],
      ],
    );
  }
}

class _LiveSection extends StatelessWidget {
  const _LiveSection({
    required this.levels,
    required this.hint,
    required this.saving,
  });

  final List<CaptureLevel> levels;
  final LevelHint hint;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final last = levels.isEmpty ? null : levels.last;
    final progress = last?.progress;
    final targetSeconds = (last?.targetMs ?? 2000) / 1000;
    final elapsedSeconds = (last?.elapsedMs ?? 0) / 1000;
    final (hintText, hintIcon, attention) = switch (hint) {
      LevelHint.waiting => (l.hintWaiting, Icons.hearing_rounded, false),
      LevelHint.tooQuiet => (l.hintTooQuiet, Icons.volume_down_rounded, true),
      LevelHint.tooLoud => (l.hintTooLoud, Icons.volume_up_rounded, true),
      LevelHint.holdStill => (l.hintHoldStill, Icons.back_hand_rounded, false),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiveLevelMeter(levels: levels),
        const SizedBox(height: KernelSpace.md),
        Semantics(
          label: l.captureProgressLabel,
          value: progress == null
              ? null
              : l.percentValue((progress * 100).round()),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(KernelRadii.pill),
            child: LinearProgressIndicator(
              key: const Key('capture-progress'),
              // Real elapsed progress from the engine; 0 until it reports.
              value: saving ? 1 : (progress ?? 0),
              minHeight: 8,
              color: KernelColors.amber,
              backgroundColor: KernelColors.onForest.withValues(alpha: 0.18),
            ),
          ),
        ),
        const SizedBox(height: KernelSpace.sm),
        Text(
          saving || (progress ?? 0) >= 1
              ? l.captureChecking
              : l.captureElapsed(
                  elapsedSeconds.toStringAsFixed(1),
                  targetSeconds.toStringAsFixed(1),
                ),
          key: const Key('capture-elapsed'),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: KernelColors.onForest),
        ),
        if (!saving) ...[
          const SizedBox(height: KernelSpace.md),
          Center(
            child: Semantics(
              liveRegion: true,
              child: Container(
                key: const Key('level-hint'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: attention
                      ? KernelColors.amber
                      : KernelColors.onForest.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(KernelRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hintIcon,
                      size: 20,
                      color: attention ? KernelColors.ink : KernelColors.onForest,
                    ),
                    const SizedBox(width: KernelSpace.sm),
                    Flexible(
                      child: Text(
                        hintText,
                        style: textTheme.labelLarge?.copyWith(
                          color: attention
                              ? KernelColors.ink
                              : KernelColors.onForest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// "Model ... — Experimental" plus the model's own provenance note.
class EngineProvenanceNote extends ConsumerWidget {
  const EngineProvenanceNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final info = ref.watch(engineInfoProvider).value;
    if (info == null) return const SizedBox.shrink();
    return Text(
      [
        provenanceLine(
          l,
          modelVersion: info.modelVersion,
          experimental: info.experimental,
        ),
        if (info.modelNote case final note? when note.trim().isNotEmpty) note,
      ].join('\n'),
    );
  }
}

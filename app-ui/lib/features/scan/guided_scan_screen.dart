import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import 'mic_denied_view.dart';

/// Nominal capture length shown by the progress bar (the engine records
/// ~2 s; the bar never waits longer than the engine does).
const captureDuration = Duration(seconds: 2);

/// Positioning tip shown before every scan.
const positioningTip = 'Press phone against sack, keep still and quiet';

enum _Phase { ready, requesting, denied, capturing, saving, failed }

/// F03 guided scan: positioning tip, mic permission, ~2 s capture with
/// progress, then the outcome is persisted and the result screen opens.
class GuidedScanScreen extends ConsumerStatefulWidget {
  const GuidedScanScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<GuidedScanScreen> createState() => _GuidedScanScreenState();
}

class _GuidedScanScreenState extends ConsumerState<GuidedScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: captureDuration,
  );
  _Phase _phase = _Phase.ready;
  PermissionAccess _access = PermissionAccess.denied;
  String? _error;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.requesting;
      _error = null;
    });

    final permissions = ref.read(devicePermissionsProvider);
    var access = await permissions.microphoneStatus();
    if (access != PermissionAccess.granted) {
      access = await permissions.requestMicrophone();
    }
    if (!mounted) return;
    if (access != PermissionAccess.granted) {
      setState(() {
        _access = access;
        _phase = _Phase.denied;
      });
      return;
    }

    // Explicit opt-in only; anything other than a loaded `true` discards
    // the audio after analysis.
    final retainAudio = ref.read(retainAudioOptInProvider).value ?? false;
    final feedback = ref.read(scanFeedbackProvider);
    final engine = ref.read(scanEngineProvider);
    final scans = ref.read(scanRepositoryProvider);

    setState(() => _phase = _Phase.capturing);
    _progress.forward(from: 0);
    await feedback.captureStarted();

    final ScanOutcome outcome;
    try {
      outcome = await engine.captureAndAnalyze(
        widget.itemId,
        retainAudio: retainAudio,
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error = 'The scan could not run: $e';
      });
      return;
    }
    await feedback.captureFinished(outcome.quality);
    if (!mounted) return;
    setState(() => _phase = _Phase.saving);

    try {
      final record = await scans.record(outcome);
      if (!mounted) return;
      context.pushReplacement(Routes.result(widget.itemId, record.id));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error =
            'The scan result could not be saved, so nothing was stored. '
            'Details: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the opt-in stream alive so its value is ready when capture starts.
    ref.watch(retainAudioOptInProvider);
    final item = ref.watch(itemProvider(widget.itemId)).value;
    final info = ref.watch(engineInfoProvider).value;

    return Scaffold(
      appBar: const KernelAppBar(title: 'Scan'),
      body: _phase == _Phase.denied
          ? MicDeniedView(access: _access, onTryAgain: _start)
          : PageList(
              children: [
                ScreenHeader(
                  title: 'Guided acoustic scan',
                  subtitle: item == null
                      ? null
                      : '${item.grainType} • ${item.label}',
                ),
                const KernelCard(
                  key: Key('positioning-tip'),
                  tone: KernelCardTone.ivory,
                  icon: Icons.back_hand_outlined,
                  title: positioningTip,
                  subtitle:
                      'Hold the phone flat on the sack with the microphone '
                      'touching it. Stop talking and avoid moving the sack.',
                ),
                _HeroCapture(
                  phase: _phase,
                  progress: _progress,
                  onStart: _start,
                ),
                if (_error != null) ErrorNote(_error!),
                KernelCard(
                  icon: Icons.tune,
                  title: 'Recording quality',
                  subtitle:
                      'Checked for background noise, clipping and silence '
                      'before any result is shown.',
                ),
                KernelCard(
                  icon: Icons.timer_outlined,
                  title: 'Capture duration',
                  subtitle: info == null
                      ? '2 s'
                      : '2 s at ${_khz(info.targetSampleRate)} kHz',
                ),
                KernelCard(
                  icon: Icons.phonelink_lock,
                  title: 'On-device inference',
                  subtitle: info == null
                      ? 'No upload required'
                      : 'No upload required. ${provenanceLine(modelVersion: info.modelVersion, experimental: info.experimental)}',
                ),
              ],
            ),
    );
  }

  static String _khz(int hz) {
    final khz = hz / 1000;
    return khz == khz.roundToDouble() ? khz.toStringAsFixed(0) : '$khz';
  }
}

class _HeroCapture extends StatelessWidget {
  const _HeroCapture({
    required this.phase,
    required this.progress,
    required this.onStart,
  });

  final _Phase phase;
  final AnimationController progress;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final busy =
        phase == _Phase.requesting ||
        phase == _Phase.capturing ||
        phase == _Phase.saving;
    return KernelCard(
      key: const Key('hero-capture'),
      tone: KernelCardTone.hero,
      icon: Icons.hearing,
      title: switch (phase) {
        _Phase.capturing => 'Listening — keep still',
        _Phase.saving => 'Saving on this phone',
        _Phase.requesting => 'Checking microphone access',
        _ => 'Ready to listen',
      },
      subtitle: 'Press phone against sack',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (phase == _Phase.capturing)
            AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                final done = progress.value >= 1;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Recording progress',
                      value: '${(progress.value * 100).round()} percent',
                      child: LinearProgressIndicator(
                        key: const Key('capture-progress'),
                        value: progress.value,
                        minHeight: 10,
                        color: KernelColors.amber,
                        backgroundColor: KernelColors.sage,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      done
                          ? 'Checking the recording on this phone…'
                          : '${(progress.value * captureDuration.inMilliseconds / 1000).toStringAsFixed(1)} s of 2 s',
                      style: const TextStyle(color: KernelColors.onForest),
                    ),
                  ],
                );
              },
            )
          else
            FilledButton.icon(
              key: const Key('start-capture'),
              style: FilledButton.styleFrom(
                backgroundColor: KernelColors.amber,
                foregroundColor: KernelColors.ink,
              ),
              onPressed: busy ? null : onStart,
              icon: const Icon(Icons.mic),
              label: Text(
                phase == _Phase.failed
                    ? 'Try the 2-second recording again'
                    : 'Start 2-second recording',
              ),
            ),
        ],
      ),
    );
  }
}

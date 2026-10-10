import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/status_chip.dart';

/// UI-side safety net on top of the engine's own 25 s timeout: if nothing
/// complete has arrived by then, the static copy is shown.
const adviceUiTimeout = Duration(seconds: 30);

/// Language the advice should be written in: the app's active locale.
String adviceLanguageTag(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// "Generated on this phone — experimental · {modelVersion}" chip.
class AdviceProvenanceChip extends StatelessWidget {
  const AdviceProvenanceChip({super.key, required this.modelVersion});

  final String modelVersion;

  @override
  Widget build(BuildContext context) => StatusChip(
    key: const Key('advice-provenance'),
    label: context.l10n.adviceProvenance(modelVersion),
    tone: StatusTone.info,
    icon: Icons.phone_android_rounded,
  );
}

/// Streams on-phone generated text into a labelled card. While generating
/// it shows a shimmer; the text grows as events arrive. If the stream
/// fails, times out or ends without a complete event, the card is replaced
/// by [fallback] (the static localized copy) without any error message.
class AdviceStreamCard extends StatefulWidget {
  const AdviceStreamCard({
    super.key,
    required this.request,
    required this.title,
    this.fallback = const SizedBox.shrink(),
    this.onComplete,
  });

  /// Starts generation. Called once.
  final Stream<AdviceText> Function() request;
  final String title;
  final Widget fallback;
  final ValueChanged<AdviceText>? onComplete;

  @override
  State<AdviceStreamCard> createState() => _AdviceStreamCardState();
}

enum _AdviceState { waiting, streaming, complete, fallback }

class _AdviceStreamCardState extends State<AdviceStreamCard> {
  StreamSubscription<AdviceText>? _sub;
  Timer? _silence;
  AdviceText? _latest;
  _AdviceState _state = _AdviceState.waiting;

  @override
  void initState() {
    super.initState();
    try {
      _sub = widget.request().listen(
        _onText,
        onError: (Object _) => _fallBack(),
        onDone: () {
          if (_state != _AdviceState.complete) _fallBack();
        },
        cancelOnError: true,
      );
      _armTimeout();
    } on Object {
      // The engine never throws by contract; treat it as "static copy".
      _state = _AdviceState.fallback;
    }
  }

  /// Falls back when nothing arrives for [adviceUiTimeout]. A plain timer
  /// rather than Stream.timeout, so the engine's done event always reaches
  /// the listener.
  void _armTimeout() {
    _silence?.cancel();
    _silence = Timer(adviceUiTimeout, () {
      unawaited(_sub?.cancel());
      _fallBack();
    });
  }

  void _onText(AdviceText text) {
    final open =
        _state == _AdviceState.waiting || _state == _AdviceState.streaming;
    if (!mounted || !open) return;
    setState(() {
      _latest = text;
      _state = text.complete ? _AdviceState.complete : _AdviceState.streaming;
    });
    if (text.complete) {
      _silence?.cancel();
      unawaited(_sub?.cancel());
      widget.onComplete?.call(text);
    } else {
      _armTimeout();
    }
  }

  void _fallBack() {
    _silence?.cancel();
    if (!mounted || _state == _AdviceState.complete) return;
    setState(() => _state = _AdviceState.fallback);
  }

  @override
  void dispose() {
    _silence?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _AdviceState.fallback) {
      return KeyedSubtree(
        key: const Key('advice-fallback'),
        child: widget.fallback,
      );
    }
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final latest = _latest;
    final done = _state == _AdviceState.complete;
    return Container(
      key: const Key('advice-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(KernelSpace.lg),
      decoration: BoxDecoration(
        color: KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        border: Border.all(color: KernelColors.outline),
      ),
      child: Semantics(
        liveRegion: done,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: KernelColors.forest,
                ),
                const SizedBox(width: KernelSpace.sm),
                Expanded(
                  child: Text(
                    widget.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: KernelColors.forest,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KernelSpace.sm),
            if (latest != null)
              AdviceProvenanceChip(modelVersion: latest.modelVersion)
            else
              Text(
                l.adviceGenerating,
                key: const Key('advice-generating'),
                style: textTheme.bodyMedium?.copyWith(
                  color: KernelColors.inkMuted,
                ),
              ),
            const SizedBox(height: KernelSpace.md),
            if (latest != null && latest.text.isNotEmpty)
              Text(
                latest.text,
                key: const Key('advice-text'),
                style: textTheme.bodyLarge?.copyWith(color: KernelColors.ink),
              ),
            if (!done) ...[
              const SizedBox(height: KernelSpace.sm),
              const AdviceShimmer(),
            ],
            const SizedBox(height: KernelSpace.md),
            Text(
              l.adviceNotDecision,
              key: const Key('advice-not-decision'),
              style: textTheme.bodyMedium?.copyWith(
                color: KernelColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder lines while text is generated. Static when the platform
/// asks for reduced motion.
class AdviceShimmer extends StatefulWidget {
  const AdviceShimmer({super.key});

  @override
  State<AdviceShimmer> createState() => _AdviceShimmerState();
}

class _AdviceShimmerState extends State<AdviceShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.adviceGenerating,
      child: AnimatedBuilder(
        key: const Key('advice-shimmer'),
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final shade = Color.lerp(
            KernelColors.sage,
            KernelColors.sageDeep,
            (t < 0.5 ? t : 1 - t) * 2,
          )!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final width in const [1.0, 0.85, 0.6])
                Padding(
                  padding: const EdgeInsets.only(bottom: KernelSpace.sm),
                  child: FractionallySizedBox(
                    widthFactor: width,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: shade,
                        borderRadius: BorderRadius.circular(KernelRadii.sm),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

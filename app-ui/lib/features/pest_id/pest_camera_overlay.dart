import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import 'pest_copy.dart';

/// Live camera preview with the engine's candidate boxes on top. Each box
/// is a button labelled by its kind; tapping it confirms that signal.
class PestLivePreview extends ConsumerWidget {
  const PestLivePreview({
    super.key,
    required this.candidates,
    required this.onConfirm,
  });

  final List<SignalCandidate> candidates;
  final ValueChanged<SignalCandidate> onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(senseCameraPreviewBuilderProvider);
    final l = context.l10n;
    return ClipRRect(
      borderRadius: BorderRadius.circular(KernelRadii.lg),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: LayoutBuilder(
          builder: (context, size) => Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: KernelColors.forestDeep,
                child: preview(context),
              ),
              for (final c in candidates)
                if (c.box case final box?)
                  Positioned(
                    left: box.left.clamp(0.0, 1.0) * size.maxWidth,
                    top: box.top.clamp(0.0, 1.0) * size.maxHeight,
                    width: (box.width.clamp(0.0, 1.0) * size.maxWidth).clamp(
                      48.0,
                      size.maxWidth,
                    ),
                    height: (box.height.clamp(0.0, 1.0) * size.maxHeight)
                        .clamp(48.0, size.maxHeight),
                    child: _CandidateBox(
                      candidate: c,
                      label: c.kind.label(l),
                      onTap: () => onConfirm(c),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateBox extends StatelessWidget {
  const _CandidateBox({
    required this.candidate,
    required this.label,
    required this.onTap,
  });

  final SignalCandidate candidate;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.pestConfirmBox(label),
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('pest-box-${candidate.id}'),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: KernelColors.amber, width: 3),
              borderRadius: BorderRadius.circular(KernelRadii.sm),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                color: KernelColors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(candidate.kind.icon, size: 14, color: KernelColors.ink),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: KernelColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Torch brightness, 0 (off) to 1.
class PestTorchSlider extends StatelessWidget {
  const PestTorchSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        Icon(
          value > 0 ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
          color: KernelColors.forest,
        ),
        const SizedBox(width: KernelSpace.sm),
        Flexible(
          child: Text(l.pestTorch, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Expanded(
          flex: 2,
          child: Slider(
            key: const Key('pest-torch'),
            value: value,
            divisions: 4,
            label: l.pestTorchValue(percentOf(value)),
            semanticFormatterCallback: (v) => l.pestTorchValue(percentOf(v)),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

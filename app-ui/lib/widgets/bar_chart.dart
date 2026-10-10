import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Track behind every bar (decorative).
const barTrackColor = KernelColors.sage;

/// Bar fill for ordinary values; >= 3:1 against [barTrackColor].
const barFillColor = KernelColors.forest;

/// Bar fill for values that need attention; >= 3:1 against the track.
const barAttentionColor = KernelColors.amberInk;

/// Text colour for bar labels and values; >= 4.5:1 on paper and ivory.
const barTextColor = KernelColors.ink;

class BarDatum {
  const BarDatum({
    required this.label,
    required this.value,
    required this.valueLabel,
    this.attention = false,
    this.id,
  });

  /// What the bar counts, in words (never colour alone).
  final String label;
  final int value;

  /// Value text printed on the bar row, e.g. "3 · 25%".
  final String valueLabel;
  final bool attention;

  /// Stable id for widget keys (`bar-<id>`).
  final String? id;
}

/// Horizontal bars: a text label above each bar and its value printed at the
/// end of the bar. The label sits on its own line so long words and 200%
/// text wrap instead of clipping. Attention bars also carry a warning icon,
/// so meaning never depends on colour.
class LabeledBarChart extends StatelessWidget {
  const LabeledBarChart({super.key, required this.bars});

  final List<BarDatum> bars;

  @override
  Widget build(BuildContext context) {
    final max = bars.fold<int>(0, (m, b) => b.value > m ? b.value : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final bar in bars)
          Padding(
            padding: const EdgeInsets.only(bottom: KernelSpace.md),
            child: _BarRow(bar: bar, max: max),
          ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.bar, required this.max});

  final BarDatum bar;
  final int max;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = max == 0 || bar.value == 0
        ? 0.0
        : (bar.value / max).clamp(0.04, 1.0);
    final fill = bar.attention ? barAttentionColor : barFillColor;
    return Semantics(
      key: bar.id == null ? null : Key('bar-${bar.id}'),
      label: '${bar.label}: ${bar.valueLabel}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bar.attention) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: barAttentionColor,
                ),
                const SizedBox(width: KernelSpace.xs),
              ],
              Expanded(
                child: Text(
                  bar.label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: barTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KernelSpace.xs),
          LayoutBuilder(
            builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: barTrackColor,
                    borderRadius: BorderRadius.circular(KernelRadii.pill),
                  ),
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: fraction,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(KernelRadii.pill),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: KernelSpace.sm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.45,
                ),
                child: Text(
                  bar.valueLabel,
                  key: bar.id == null ? null : Key('bar-value-${bar.id}'),
                  style: textTheme.labelLarge?.copyWith(color: barTextColor),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}

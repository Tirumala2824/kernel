import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/tokens.dart';

enum StatusTone { neutral, positive, attention, danger, info }

/// Colours for a [StatusTone]: background, foreground (text and icon) and
/// border. Every pair meets 4.5:1 (see test/theme_test.dart).
(Color, Color, Color) statusColors(StatusTone tone) => switch (tone) {
  StatusTone.neutral => (
    KernelColors.paper,
    KernelColors.ink,
    KernelColors.outline,
  ),
  StatusTone.positive => (
    KernelColors.sage,
    KernelColors.forest,
    KernelColors.forestSoft,
  ),
  StatusTone.attention => (
    KernelColors.amberSoft,
    KernelColors.amberInk,
    KernelColors.amber,
  ),
  StatusTone.danger => (
    KernelColors.dangerSoft,
    KernelColors.danger,
    KernelColors.danger,
  ),
  StatusTone.info => (
    KernelColors.paper,
    KernelColors.forest,
    KernelColors.forest,
  ),
};

IconData _defaultIcon(StatusTone tone) => switch (tone) {
  StatusTone.neutral => Icons.info_outline_rounded,
  StatusTone.positive => Icons.check_circle_outline_rounded,
  StatusTone.attention => Icons.warning_amber_rounded,
  StatusTone.danger => Icons.error_outline_rounded,
  StatusTone.info => Icons.science_outlined,
};

/// Status label. Colour is always paired with an icon and text, never used
/// on its own. Wraps instead of clipping at large font sizes.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = statusColors(tone);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(KernelRadii.pill),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? _defaultIcon(tone), size: 18, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Experimental" badge shown next to every model-derived value.
class ExperimentalBadge extends StatelessWidget {
  const ExperimentalBadge({super.key});

  @override
  Widget build(BuildContext context) => StatusChip(
    label: context.l10n.experimentalBadge,
    tone: StatusTone.info,
    icon: Icons.science_rounded,
  );
}

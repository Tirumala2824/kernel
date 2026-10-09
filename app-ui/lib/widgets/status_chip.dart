import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum StatusTone { neutral, positive, attention, danger, info }

/// Status label. Colour is always paired with text and an icon, never used
/// on its own.
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
    final (bg, fg, border, defaultIcon) = switch (tone) {
      StatusTone.neutral => (
        KernelColors.ivory,
        KernelColors.ink,
        KernelColors.outline,
        Icons.info_outline,
      ),
      StatusTone.positive => (
        KernelColors.sage,
        KernelColors.forest,
        KernelColors.forest,
        Icons.check_circle_outline,
      ),
      StatusTone.attention => (
        KernelColors.amber,
        KernelColors.ink,
        KernelColors.amber,
        Icons.warning_amber_rounded,
      ),
      StatusTone.danger => (
        KernelColors.danger,
        KernelColors.onForest,
        KernelColors.danger,
        Icons.error_outline,
      ),
      StatusTone.info => (
        Colors.white,
        KernelColors.forest,
        KernelColors.forest,
        Icons.science_outlined,
      ),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? defaultIcon, size: 18, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: fg, fontWeight: FontWeight.w600),
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
  Widget build(BuildContext context) =>
      const StatusChip(label: 'Experimental', tone: StatusTone.info);
}

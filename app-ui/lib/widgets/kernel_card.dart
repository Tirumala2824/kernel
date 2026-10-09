import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum KernelCardTone {
  /// Forest hero card for the primary action on a screen.
  hero,

  /// Sage secondary card.
  sage,

  /// Ivory tertiary card with an outline.
  ivory,

  /// Amber attention card (warnings, retry, inspection needed).
  attention,
}

/// Card matching the PRD wireframes: icon, title, subtitle and optional
/// body. Tappable cards keep a >=48dp target and expose a button role.
class KernelCard extends StatelessWidget {
  const KernelCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.tone = KernelCardTone.sage,
    this.onTap,
    this.trailing,
    this.child,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final KernelCardTone tone;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? child;
  final String? semanticLabel;

  Color get _background => switch (tone) {
    KernelCardTone.hero => KernelColors.forest,
    KernelCardTone.sage => KernelColors.sage,
    KernelCardTone.ivory => KernelColors.ivory,
    KernelCardTone.attention => KernelColors.amber,
  };

  Color get _foreground =>
      tone == KernelCardTone.hero ? KernelColors.onForest : KernelColors.ink;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fg = _foreground;
    final content = Padding(
      padding: const EdgeInsets.all(KernelSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: 28),
                const SizedBox(width: KernelSizes.gap),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          (tone == KernelCardTone.hero
                                  ? textTheme.titleLarge
                                  : textTheme.titleMedium)
                              ?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: textTheme.bodyMedium?.copyWith(color: fg),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: KernelSizes.gap),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: KernelSizes.gap),
                Icon(Icons.chevron_right, color: fg),
              ],
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: KernelSizes.gap),
            DefaultTextStyle.merge(
              style: TextStyle(color: fg),
              child: IconTheme.merge(
                data: IconThemeData(color: fg),
                child: child!,
              ),
            ),
          ],
        ],
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KernelSizes.cardRadius),
      side: tone == KernelCardTone.ivory
          ? const BorderSide(color: KernelColors.outline)
          : BorderSide.none,
    );

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Card(
        color: _background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: KernelSizes.minTouchTarget,
                  ),
                  child: content,
                ),
              ),
      ),
    );
  }
}

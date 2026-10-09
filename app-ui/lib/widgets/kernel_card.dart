import 'package:flutter/material.dart';

import '../brand/kernel_brand.dart';
import '../theme/tokens.dart';

enum KernelCardTone {
  /// Forest hero card for the primary action on a screen.
  hero,

  /// Sage secondary card.
  sage,

  /// Paper card with a hairline, for tertiary content.
  ivory,

  /// Amber attention card (warnings, retry, inspection needed).
  attention,
}

/// Card matching the PRD wireframes: icon well, title, subtitle and optional
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

  bool get _isHero => tone == KernelCardTone.hero;

  Color get _foreground => _isHero ? KernelColors.onForest : KernelColors.ink;

  Color get _wellColor => switch (tone) {
    KernelCardTone.hero => const Color(0x26FFFFFF),
    KernelCardTone.sage => KernelColors.paper,
    KernelCardTone.ivory => KernelColors.sage,
    KernelCardTone.attention => const Color(0x40FFFFFF),
  };

  Color get _iconColor => switch (tone) {
    KernelCardTone.hero => KernelColors.amber,
    KernelCardTone.attention => KernelColors.ink,
    _ => KernelColors.forest,
  };

  BoxDecoration get _decoration => switch (tone) {
    KernelCardTone.hero => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [KernelColors.forestSoft, KernelColors.forest],
      ),
      borderRadius: BorderRadius.circular(KernelRadii.lg),
      boxShadow: KernelShadows.lifted,
    ),
    KernelCardTone.sage => BoxDecoration(
      color: KernelColors.sage,
      borderRadius: BorderRadius.circular(KernelRadii.lg),
    ),
    KernelCardTone.ivory => BoxDecoration(
      color: KernelColors.paper,
      borderRadius: BorderRadius.circular(KernelRadii.lg),
      border: Border.all(color: KernelColors.hairline),
      boxShadow: KernelShadows.soft,
    ),
    KernelCardTone.attention => BoxDecoration(
      color: KernelColors.amber,
      borderRadius: BorderRadius.circular(KernelRadii.lg),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fg = _foreground;
    final content = Padding(
      padding: const EdgeInsets.all(KernelSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _wellColor,
                    borderRadius: BorderRadius.circular(KernelRadii.md),
                  ),
                  child: Icon(icon, color: _iconColor, size: 24),
                ),
                const SizedBox(width: KernelSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (_isHero
                              ? textTheme.titleLarge
                              : textTheme.titleMedium)
                          ?.copyWith(color: fg, fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: KernelSpace.xs),
                      Text(
                        subtitle!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _isHero
                              ? KernelColors.onForest.withValues(alpha: 0.92)
                              : fg,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: KernelSpace.md),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: KernelSpace.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Icon(Icons.chevron_right_rounded, color: fg),
                ),
              ],
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: KernelSpace.md),
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

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Container(
        decoration: _decoration,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(KernelRadii.lg),
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
      ),
    );
  }
}

/// The memorable primary action on each home screen: a forest card with the
/// brand mark on an ivory disc and amber listening rings pulsing around it.
class HeroActionCard extends StatelessWidget {
  const HeroActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.eyebrow,
    this.icon = Icons.graphic_eq_rounded,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final String? eyebrow;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
    final badge = SizedBox.square(
      dimension: 112,
      child: ListeningRings(
        child: Center(
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: KernelColors.ivory,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const KernelMark(size: 40),
          ),
        ),
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: KernelColors.amber,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: KernelSpace.xs),
        ],
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            color: KernelColors.onForest,
          ),
        ),
        const SizedBox(height: KernelSpace.xs),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: KernelColors.onForest.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: KernelSpace.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: KernelColors.amber,
            borderRadius: BorderRadius.circular(KernelRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: KernelColors.ink),
              const SizedBox(width: KernelSpace.sm),
              Flexible(
                child: Text(
                  actionLabel,
                  style: textTheme.labelLarge?.copyWith(
                    color: KernelColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [KernelColors.forestSoft, KernelColors.forestDeep],
          ),
          borderRadius: BorderRadius.circular(KernelRadii.xl),
          boxShadow: KernelShadows.lifted,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(KernelRadii.xl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(KernelSpace.xl - 4),
              child: largeText
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [badge, const SizedBox(height: 8), text],
                    )
                  : Row(
                      children: [
                        Expanded(child: text),
                        const SizedBox(width: KernelSpace.sm),
                        badge,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

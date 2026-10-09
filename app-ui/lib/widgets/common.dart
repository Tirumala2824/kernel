import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/kernel_brand.dart';
import '../l10n/l10n.dart';
import '../theme/tokens.dart';
import 'status_chip.dart';

/// Screen title and subtitle at the top of a page body. Wraps freely so it
/// does not clip at 200% font scale.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
  });

  final String title;
  final String? subtitle;

  /// Small amber-ink overline above the title.
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: KernelSpace.xs, bottom: KernelSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: KernelColors.amberInk,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: KernelSpace.xs),
          ],
          Semantics(
            header: true,
            child: Text(
              title,
              style: textTheme.headlineMedium?.copyWith(
                color: KernelColors.forest,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: KernelSpace.xs),
            Text(
              subtitle!,
              style: textTheme.bodyLarge?.copyWith(
                color: KernelColors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: KernelSpace.lg),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: KernelSpace.sm,
        runSpacing: KernelSpace.xs,
        children: [
          Semantics(
            header: true,
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: KernelColors.forest,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Plain-language empty state with an illustration and exactly one next
/// action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.detail,
    required this.actionLabel,
    required this.onAction,
    this.illustration,
    this.actionIcon = Icons.add_rounded,
  });

  final String message;
  final String? detail;
  final String actionLabel;
  final VoidCallback onAction;

  /// SVG source from brand/illustrations.dart.
  final String? illustration;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KernelSpace.xl - 4),
      decoration: BoxDecoration(
        color: KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        border: Border.all(color: KernelColors.hairline),
        boxShadow: KernelShadows.soft,
      ),
      child: Column(
        children: [
          if (illustration != null) ...[
            KernelIllustration(illustration!, height: 112),
            const SizedBox(height: KernelSpace.md),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(color: KernelColors.forest),
          ),
          if (detail != null) ...[
            const SizedBox(height: KernelSpace.sm),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: KernelColors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: KernelSpace.lg),
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// Quiet inline note for "nothing here yet" inside a section (no action).
class QuietNote extends StatelessWidget {
  const QuietNote(this.text, {super.key, this.icon = Icons.info_outline_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KernelSpace.md),
      decoration: BoxDecoration(
        color: KernelColors.sage,
        borderRadius: BorderRadius.circular(KernelRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KernelColors.forest, size: 20),
          const SizedBox(width: KernelSpace.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Banner for honesty notes (experimental model, physical inspection).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    this.title,
    this.tone = StatusTone.attention,
    this.icon,
  });

  final String text;
  final String? title;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = statusColors(tone);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KernelSpace.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KernelRadii.md),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline_rounded, color: fg),
          const SizedBox(width: KernelSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: textTheme.titleSmall?.copyWith(color: fg),
                  ),
                Text(text, style: textTheme.bodyMedium?.copyWith(color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders an [AsyncValue] with a small loading indicator and a readable
/// error, so every screen handles all three states the same way.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.errorPrefix,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String? errorPrefix;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Padding(
        padding: EdgeInsets.all(KernelSpace.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ErrorNote(
        context.l10n.errorWithDetail(
          errorPrefix ?? context.l10n.errorCouldNotLoad,
          '$error',
        ),
      ),
    );
  }
}

class ErrorNote extends StatelessWidget {
  const ErrorNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KernelSpace.md),
      decoration: BoxDecoration(
        color: KernelColors.dangerSoft,
        borderRadius: BorderRadius.circular(KernelRadii.md),
        border: Border.all(color: KernelColors.danger),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: KernelColors.danger),
          const SizedBox(width: KernelSpace.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: KernelColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label/value row for detail cards.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Wrap(
        spacing: KernelSpace.sm,
        children: [
          Text(
            context.l10n.fieldLabel(label),
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Standard scrollable page body.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children, this.gap = KernelSpace.md});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          KernelSpace.page,
          KernelSpace.sm,
          KernelSpace.page,
          KernelSpace.xxl,
        ),
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Shown when a record id from a route is not on this phone.
class NotFoundNote extends StatelessWidget {
  const NotFoundNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(KernelSpace.page),
    child: QuietNote(message, icon: Icons.search_off_rounded),
  );
}

/// A row of action buttons that wraps on narrow screens and large text.
class ActionWrap extends StatelessWidget {
  const ActionWrap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: KernelSpace.sm,
    runSpacing: KernelSpace.sm,
    children: children,
  );
}

/// Small count + label tile used in dashboard summaries.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.attention = false,
  });

  final String value;
  final String label;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(KernelSpace.md),
      decoration: BoxDecoration(
        color: attention ? KernelColors.amberSoft : KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.md),
        border: Border.all(
          color: attention ? KernelColors.amber : KernelColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              color: attention ? KernelColors.amberInk : KernelColors.forest,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: attention ? KernelColors.amberInk : KernelColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';

/// Screen title and subtitle at the top of a page body. Wraps freely so it
/// does not clip at 200% font scale.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: KernelSizes.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: KernelColors.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
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
      padding: const EdgeInsets.only(top: KernelSizes.gap * 2, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: KernelColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Plain-language empty state with exactly one next action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.detail,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.inventory_2_outlined,
  });

  final String message;
  final String? detail;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KernelSizes.pagePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KernelSizes.cardRadius),
        border: Border.all(color: KernelColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: KernelColors.forest),
              const SizedBox(width: KernelSizes.gap),
              Expanded(
                child: Text(
                  message,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail!, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: KernelSizes.gap),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
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
    this.errorPrefix = 'Could not load',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String errorPrefix;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Padding(
        padding: EdgeInsets.all(KernelSizes.pagePadding),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ErrorNote('$errorPrefix: $error'),
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
      padding: const EdgeInsets.all(KernelSizes.gap),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KernelColors.danger),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: KernelColors.danger),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          Text(
            '$label:',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Standard scrollable page body.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(KernelSizes.pagePadding),
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: KernelSizes.gap),
            children[i],
          ],
        ],
      ),
    );
  }
}

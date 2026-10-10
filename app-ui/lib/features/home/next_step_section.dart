import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_card.dart';
import 'next_actions.dart';

/// How many lower-priority steps are listed under the hero.
const maxSecondarySteps = 2;

/// "Next step" hero from AnalyticsService.watchNextActions: the most urgent
/// action as the forest hero card, up to two more as rows, and a compact
/// scan shortcut whenever the hero is not itself a scan. With nothing
/// pending, the role's usual hero ([fallback]) is shown instead.
class NextStepSection extends ConsumerWidget {
  const NextStepSection({
    super.key,
    required this.role,
    required this.fallback,
    this.shortcut,
  });

  final Role role;

  /// The role's everyday primary action (scan, batch scan, register lot).
  final Widget fallback;

  /// Extra everyday action kept next to the scan shortcut while the hero
  /// shows a next step (e.g. "Register delivery" for buyers).
  final Widget? shortcut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final actions = ref.watch(nextActionsProvider(role));
    return actions.when(
      loading: () => fallback,
      // Analytics unavailable: keep the everyday action, never block.
      error: (_, _) => fallback,
      data: (actions) {
        if (actions.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fallback,
              const SizedBox(height: KernelSpace.md),
              QuietNote(
                l.nextNothingPending,
                key: const Key('next-none'),
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          );
        }
        final steps = [
          for (final action in actions.take(1 + maxSecondarySteps))
            describeNextAction(l, role, action),
        ];
        final top = steps.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroActionCard(
              key: const Key('next-step-hero'),
              eyebrow: l.nextStepEyebrow,
              title: top.title,
              subtitle: top.subtitle,
              actionLabel: top.actionLabel,
              icon: top.icon,
              onTap: () => top.open(context),
            ),
            for (final (i, step) in steps.skip(1).indexed) ...[
              const SizedBox(height: KernelSpace.sm),
              KernelCard(
                key: Key('next-step-${i + 1}'),
                tone: step.attention
                    ? KernelCardTone.attention
                    : KernelCardTone.ivory,
                icon: step.icon,
                title: step.title,
                subtitle: step.actionLabel,
                onTap: () => step.open(context),
              ),
            ],
            if (!top.scan || shortcut != null) ...[
              const SizedBox(height: KernelSpace.md),
              ActionWrap(
                children: [
                  if (!top.scan) QuickScanAction(role: role),
                  ?shortcut,
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Compact scan shortcut, so scanning stays one tap away from Home.
class QuickScanAction extends StatelessWidget {
  const QuickScanAction({super.key, required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final batch = role == Role.storageFpo;
    return OutlinedButton.icon(
      key: const Key('quick-scan'),
      onPressed: () =>
          batch ? context.push(Routes.batchSetup) : context.go(Routes.scan),
      icon: Icon(
        batch ? Icons.playlist_play_rounded : Icons.graphic_eq_rounded,
      ),
      label: Text(batch ? l.heroStartBatch : l.quickScanAction),
    );
  }
}

/// Home card that opens the Insights screen.
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return KernelCard(
      key: const Key('open-insights'),
      tone: KernelCardTone.ivory,
      icon: Icons.insights_rounded,
      title: l.insightsTitle,
      subtitle: l.insightsCardSubtitle,
      onTap: () => context.push(Routes.insights),
    );
  }
}

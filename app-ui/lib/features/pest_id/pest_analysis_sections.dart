import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';
import 'pest_copy.dart';
import 'pest_widgets.dart';

/// The AI analysis, always labelled as an experimental estimate. Kept
/// visually separate from the user's pick and any verified finding.
class PestAiAnalysisCard extends StatelessWidget {
  const PestAiAnalysisCard({super.key, required this.analysis});

  final PestAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final noMatch = analysis.cardId == null;
    return Container(
      key: const Key('pest-ai-analysis'),
      width: double.infinity,
      padding: const EdgeInsets.all(KernelSpace.lg),
      decoration: BoxDecoration(
        color: KernelColors.sage,
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        border: Border.all(color: KernelColors.forestSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: KernelSpace.sm,
            runSpacing: KernelSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l.pestAiLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: KernelColors.inkMuted,
                ),
              ),
              const ExperimentalBadge(),
            ],
          ),
          const SizedBox(height: KernelSpace.xs),
          Text(
            analysis.commonName,
            key: const Key('pest-common-name'),
            style: textTheme.headlineSmall?.copyWith(
              color: KernelColors.forest,
            ),
          ),
          const SizedBox(height: KernelSpace.sm),
          StatusChip(
            label: analysis.group.label(l),
            icon: Icons.category_rounded,
          ),
          const SizedBox(height: KernelSpace.sm),
          PestTaxonomyChips(path: analysis.taxonomyPath),
          const SizedBox(height: KernelSpace.md),
          PestConfidenceBar(analysis: analysis),
          if (noMatch || analysis.group == PestGroup.notAPest) ...[
            const SizedBox(height: KernelSpace.md),
            NoticeBanner(
              key: const Key('pest-not-proof'),
              text: noMatch ? l.pestNoMatch : l.pestNotAPest,
            ),
          ],
          PestBulletSection(
            title: l.pestKeyFeatures,
            items: analysis.keyFeatures,
          ),
          PestBulletSection(title: l.pestAnomalies, items: analysis.anomalies),
          PestBulletSection(title: l.pestInsights, items: analysis.insights),
          const SizedBox(height: KernelSpace.md),
          Text(
            l.pestModelLine(analysis.modelVersion, analysis.promptVersion),
            key: const Key('pest-model-line'),
            style: textTheme.bodySmall?.copyWith(color: KernelColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Shown when analyzeImage returned null: the top knowledge-search card,
/// clearly labelled as not an AI analysis.
class PestAnalysisUnavailable extends StatelessWidget {
  const PestAnalysisUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return NoticeBanner(
      key: const Key('pest-ai-unavailable'),
      title: l.pestAnalysisUnavailable,
      text: l.pestAnalysisUnavailableBody,
      tone: StatusTone.neutral,
      icon: Icons.psychology_alt_rounded,
    );
  }
}

/// Distance result, or "Distance not available" with the reason.
class PestDistanceNote extends StatelessWidget {
  const PestDistanceNote({super.key, required this.estimate});

  final DistanceEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!estimate.isAvailable) {
      final reason = estimate.unavailableReason;
      return NoticeBanner(
        key: const Key('pest-distance-unavailable'),
        title: l.pestDistanceUnavailable,
        text: reason == null || reason.trim().isEmpty
            ? l.pestDistanceNoReason
            : l.pestDistanceReason(reason),
        tone: StatusTone.neutral,
        icon: Icons.straighten_rounded,
      );
    }
    final m = estimate.meters!;
    final method = estimate.method == DistanceMethod.arcoreDepth
        ? l.pestDistanceMethodDepth
        : l.pestDistanceMethodFocus;
    return QuietNote(
      l.pestDistanceValue(
        _m(m),
        _m(estimate.lowMeters ?? m),
        _m(estimate.highMeters ?? m),
        method,
      ),
      key: const Key('pest-distance'),
      icon: Icons.straighten_rounded,
    );
  }

  static String _m(double value) => value.toStringAsFixed(2);
}

import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';
import 'pest_copy.dart';

/// Safety banner for a [SafetyLevel] (guardrails §9). Nothing for [low].
class PestSafetyBanner extends StatelessWidget {
  const PestSafetyBanner({super.key, required this.level});

  final SafetyLevel level;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (String title, String body, StatusTone tone, IconData icon)? copy =
        switch (level) {
          SafetyLevel.low => null,
          SafetyLevel.caution => (
            l.pestSafetyCautionTitle,
            l.pestSafetyCautionBody,
            StatusTone.attention,
            Icons.back_hand_rounded,
          ),
          SafetyLevel.medicalRisk => (
            l.pestSafetyMedicalTitle,
            l.pestSafetyDistanceBody,
            StatusTone.danger,
            Icons.medical_services_rounded,
          ),
          SafetyLevel.venomous => (
            l.pestSafetyVenomousTitle,
            l.pestSafetyDistanceBody,
            StatusTone.danger,
            Icons.warning_rounded,
          ),
          SafetyLevel.protectedWildlife => (
            l.pestSafetyProtectedTitle,
            l.pestSafetyProtectedBody,
            StatusTone.attention,
            Icons.park_rounded,
          ),
        };
    if (copy == null) return const SizedBox.shrink();
    final (title, body, tone, icon) = copy;
    return Semantics(
      liveRegion: true,
      child: NoticeBanner(
        key: Key('pest-safety-${level.name}'),
        title: title,
        text: body,
        tone: tone,
        icon: icon,
      ),
    );
  }
}

/// "AI-estimated confidence — not calibrated" bar plus the agreement line.
class PestConfidenceBar extends StatelessWidget {
  const PestConfidenceBar({super.key, required this.analysis});

  final PestAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final percent = percentOf(analysis.aiConfidence);
    final runs = analysis.samples;
    final agree = (analysis.agreement.clamp(0.0, 1.0) * runs).round();
    return Column(
      key: const Key('pest-confidence'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.pestConfidenceLabel,
          style: textTheme.titleSmall?.copyWith(color: KernelColors.ink),
        ),
        const SizedBox(height: KernelSpace.xs),
        Semantics(
          label: l.pestConfidenceValue(percent),
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(KernelRadii.pill),
            child: LinearProgressIndicator(
              value: analysis.aiConfidence.clamp(0.0, 1.0),
              minHeight: 10,
              color: KernelColors.outline,
              backgroundColor: KernelColors.sageDeep,
            ),
          ),
        ),
        const SizedBox(height: KernelSpace.xs),
        Text(l.pestConfidenceValue(percent), style: textTheme.bodyMedium),
        if (runs > 0)
          Text(
            l.pestAgreement(agree, runs),
            key: const Key('pest-agreement'),
            style: textTheme.bodyMedium,
          ),
      ],
    );
  }
}

/// Titled bullet list; renders nothing when [items] is empty.
class PestBulletSection extends StatelessWidget {
  const PestBulletSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final cleaned = [
      for (final item in items)
        if (item.trim().isNotEmpty) item.trim(),
    ];
    if (cleaned.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: KernelSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: KernelColors.forest,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: KernelSpace.xs),
          for (final item in cleaned)
            Padding(
              padding: const EdgeInsets.only(bottom: KernelSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: KernelColors.forest,
                    ),
                  ),
                  const SizedBox(width: KernelSpace.sm),
                  Expanded(child: Text(item, style: textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Taxonomy path as chips, coarse to fine.
class PestTaxonomyChips extends StatelessWidget {
  const PestTaxonomyChips({super.key, required this.path});

  final List<String> path;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();
    return Wrap(
      key: const Key('pest-taxonomy'),
      spacing: KernelSpace.xs,
      runSpacing: KernelSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, step) in path.indexed) ...[
          if (i > 0)
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: KernelColors.inkMuted,
            ),
          StatusChip(label: step, icon: Icons.account_tree_rounded),
        ],
      ],
    );
  }
}

/// A curated knowledge card: names, signs, safe steps, when to call a
/// professional, first aid pointers, legal status and sources.
class KnowledgeCardView extends StatelessWidget {
  const KnowledgeCardView({
    super.key,
    required this.card,
    this.userPicked = false,
  });

  final KnowledgeCard card;
  final bool userPicked;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final name = cardName(card, lang);
    final otherNames = {
      for (final e in card.names.entries)
        if (e.value.trim().isNotEmpty && e.value != name) e.value,
    }.toList();
    return Container(
      key: Key('knowledge-card-${card.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(KernelSpace.lg),
      decoration: BoxDecoration(
        color: KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        border: Border.all(color: KernelColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pestCardTitle,
            style: textTheme.labelLarge?.copyWith(color: KernelColors.inkMuted),
          ),
          const SizedBox(height: KernelSpace.xs),
          Text(
            name,
            style: textTheme.titleLarge?.copyWith(color: KernelColors.forest),
          ),
          const SizedBox(height: KernelSpace.sm),
          Wrap(
            spacing: KernelSpace.sm,
            runSpacing: KernelSpace.xs,
            children: [
              StatusChip(
                label: card.group.label(l),
                icon: Icons.category_rounded,
              ),
              if (userPicked)
                StatusChip(
                  key: const Key('pest-card-user-pick'),
                  label: l.pestCardYourPick,
                  tone: StatusTone.positive,
                  icon: Icons.person_rounded,
                ),
              if (card.reviewStatus != 'reviewed')
                StatusChip(
                  label: l.pestCardNeedsReview,
                  tone: StatusTone.attention,
                  icon: Icons.rate_review_rounded,
                ),
            ],
          ),
          if (otherNames.isNotEmpty) ...[
            const SizedBox(height: KernelSpace.sm),
            Text(
              l.pestCardOtherNames(otherNames.join(', ')),
              style: textTheme.bodyMedium,
            ),
          ],
          if (card.summary.trim().isNotEmpty) ...[
            const SizedBox(height: KernelSpace.sm),
            Text(card.summary, style: textTheme.bodyLarge),
          ],
          PestBulletSection(title: l.pestCardSigns, items: card.signs),
          PestBulletSection(
            title: l.pestCardHealthRisks,
            items: card.healthRisks,
          ),
          PestBulletSection(title: l.pestCardSafeSteps, items: card.safeSteps),
          PestBulletSection(
            title: l.pestCardCallPro,
            items: card.callProfessionalWhen,
          ),
          PestBulletSection(title: l.pestCardFirstAid, items: card.firstAid),
          PestBulletSection(
            title: l.pestCardLookAlikes,
            items: card.lookAlikes,
          ),
          if (card.legal != null && card.legal!.trim().isNotEmpty)
            PestBulletSection(title: l.pestCardLegal, items: [card.legal!]),
          PestBulletSection(title: l.pestCardSources, items: card.sources),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';
import 'pest_copy.dart';
import 'pest_session.dart';
import 'pest_widgets.dart';

/// Raw sound-classifier labels (e.g. YAMNet), never calibrated.
class PestSoundLabels extends StatelessWidget {
  const PestSoundLabels({super.key, required this.labels});

  final List<ScoredLabel> labels;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (labels.isEmpty) return Text(l.pestSoundNoLabels);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: KernelSpace.xs,
          runSpacing: KernelSpace.xs,
          children: [
            for (final label in labels.take(3))
              StatusChip(
                label: l.pestSoundScore(label.label, percentOf(label.score)),
                icon: Icons.graphic_eq_rounded,
              ),
          ],
        ),
        const SizedBox(height: KernelSpace.xs),
        Text(
          l.pestSoundRawNote,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: KernelColors.inkMuted),
        ),
      ],
    );
  }
}

/// One live sound event; tapping confirms the user heard it too.
class PestSoundEventTile extends StatelessWidget {
  const PestSoundEventTile({
    super.key,
    required this.candidate,
    required this.labels,
    required this.onConfirm,
  });

  final SignalCandidate candidate;
  final List<ScoredLabel>? labels;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: KernelColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KernelRadii.md),
        side: const BorderSide(color: KernelColors.outline),
      ),
      child: InkWell(
        key: Key('pest-sound-${candidate.id}'),
        borderRadius: BorderRadius.circular(KernelRadii.md),
        onTap: onConfirm,
        child: Padding(
          padding: const EdgeInsets.all(KernelSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.pestSoundAt(formatTime(context, candidate.detectedAt)),
                style: textTheme.titleSmall?.copyWith(
                  color: KernelColors.forest,
                ),
              ),
              const SizedBox(height: KernelSpace.xs),
              if (labels != null) PestSoundLabels(labels: labels!),
              const SizedBox(height: KernelSpace.xs),
              Text(l.pestSoundConfirm, style: textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

/// After a sound is confirmed: the classifier labels, the experimental
/// description, the matching cards and the save action.
class PestSoundResult extends StatelessWidget {
  const PestSoundResult({
    super.key,
    required this.session,
    required this.onPick,
    required this.onSave,
    required this.onDiscard,
    required this.onListenAgain,
  });

  final PestSessionState session;
  final ValueChanged<String?> onPick;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onListenAgain;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final sound = session.sound;
    final lang = Localizations.localeOf(context).languageCode;
    final matches = session.soundCards;
    final shown = session.cardById(session.userCardId) ?? matches.firstOrNull;
    return Column(
      key: const Key('pest-sound-result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shown != null) ...[
          PestSafetyBanner(level: shown.safety),
          const SizedBox(height: KernelSpace.md),
        ],
        Container(
          key: const Key('pest-sound-analysis'),
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
                    l.pestSoundDescription,
                    style: textTheme.titleSmall?.copyWith(
                      color: KernelColors.forest,
                    ),
                  ),
                  const ExperimentalBadge(),
                ],
              ),
              const SizedBox(height: KernelSpace.sm),
              PestSoundLabels(labels: sound?.preFilter ?? session.soundLabels),
              const SizedBox(height: KernelSpace.sm),
              if (sound == null)
                Text(
                  l.pestAnalysisUnavailable,
                  key: const Key('pest-sound-unavailable'),
                )
              else ...[
                if (sound.groupHint != PestGroup.unknown)
                  Text(l.pestGroupHint(sound.groupHint.label(l))),
                const SizedBox(height: KernelSpace.xs),
                Text(
                  sound.description?.trim().isNotEmpty == true
                      ? sound.description!
                      : l.pestSoundNoDescription,
                  key: const Key('pest-sound-description'),
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: KernelSpace.sm),
                Text(
                  l.pestSoundModel(sound.modelVersion),
                  style: textTheme.bodySmall?.copyWith(
                    color: KernelColors.inkMuted,
                  ),
                ),
              ],
              const SizedBox(height: KernelSpace.sm),
              Text(l.pestNotCertainNote, style: textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: KernelSpace.md),
        SectionTitle(l.pestSoundCards),
        const SizedBox(height: KernelSpace.sm),
        if (matches.isEmpty)
          QuietNote(l.pestSoundNoCards, key: const Key('pest-sound-no-cards'))
        else ...[
          for (final card in matches)
            ListTile(
              key: Key('pest-sound-card-${card.id}'),
              minTileHeight: 48,
              leading: Icon(
                card.id == shown?.id
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: KernelColors.forest,
              ),
              title: Text(cardName(card, lang)),
              subtitle: Text(card.group.label(l)),
              onTap: () => onPick(card.id),
            ),
          if (shown != null) ...[
            const SizedBox(height: KernelSpace.sm),
            KnowledgeCardView(
              card: shown,
              userPicked: session.userCardId == shown.id,
            ),
          ],
        ],
        const SizedBox(height: KernelSpace.md),
        FilledButton.icon(
          key: const Key('pest-save'),
          onPressed: onSave,
          icon: const Icon(Icons.bookmark_add_rounded),
          label: Text(l.pestSave),
        ),
        const SizedBox(height: KernelSpace.sm),
        ActionWrap(
          children: [
            OutlinedButton.icon(
              key: const Key('pest-listen-again'),
              onPressed: onListenAgain,
              icon: const Icon(Icons.replay_rounded),
              label: Text(l.pestListenAgain),
            ),
            TextButton.icon(
              key: const Key('pest-discard'),
              onPressed: onDiscard,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l.pestDiscard),
            ),
          ],
        ),
      ],
    );
  }
}

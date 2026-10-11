import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/status_chip.dart';
import 'pest_analysis_sections.dart';
import 'pest_copy.dart';
import 'pest_listen_sections.dart';
import 'pest_providers.dart';
import 'pest_widgets.dart';
import 'sighting_finding.dart';
import 'sightings_screen.dart';

/// One saved sighting. Three separate records, top to bottom: the AI
/// analysis (read-only), the user's confirmation or correction, and the
/// human verified finding.
class SightingDetailScreen extends ConsumerWidget {
  const SightingDetailScreen({super.key, required this.sightingId});

  final String sightingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sighting = ref.watch(sightingProvider(sightingId));
    return Scaffold(
      appBar: KernelAppBar(title: l.pestDetailTitle),
      body: AsyncView<Sighting?>(
        value: sighting,
        data: (s) => s == null
            ? NotFoundNote(l.pestNotFound)
            : _SightingBody(sighting: s),
      ),
    );
  }
}

class _SightingBody extends ConsumerWidget {
  const _SightingBody({required this.sighting});

  final Sighting sighting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = sighting;
    final lang = Localizations.localeOf(context).languageCode;
    final cards = ref.watch(knowledgeCardsProvider).value ?? const [];
    final shownId = s.userCardId ?? s.analysis?.cardId;
    final card = shownId == null
        ? null
        : ref.watch(knowledgeCardProvider(shownId)).value;
    final place = s.locationId == null
        ? null
        : ref.watch(locationProvider(s.locationId!)).value;
    final concerns = safetyConcerns(
      aiLevel: s.analysis?.safety,
      cards: [
        card,
        if (s.analysis?.cardId case final id?)
          ref.watch(knowledgeCardProvider(id)).value,
        for (final id in s.sound?.cardIds ?? const <String>[])
          ref.watch(knowledgeCardProvider(id)).value,
      ],
    );
    final pin = s.latitude != null && s.longitude != null;
    final pickName = s.userCardId == null
        ? null
        : card == null
        ? s.userCardId!
        : cardName(card, lang);
    return PageList(
      children: [
        ScreenHeader(
          title: sightingTitle(l, s, cards, lang),
          subtitle: [
            formatDateTime(context, s.observedAt),
            s.source.label(l),
          ].join(' · '),
        ),
        for (final level in concerns) PestSafetyBanner(level: level),
        SectionTitle(l.pestDetailAiSection),
        QuietNote(l.pestDetailAiNote, icon: Icons.science_rounded),
        if (s.analysis case final analysis?)
          PestAiAnalysisCard(analysis: analysis)
        else if (s.sound case final sound?)
          _SoundRecord(sound: sound)
        else
          const PestAnalysisUnavailable(),
        SectionTitle(l.pestDetailValidation),
        Container(
          key: const Key('sighting-validation'),
          width: double.infinity,
          padding: const EdgeInsets.all(KernelSpace.lg),
          decoration: BoxDecoration(
            color: KernelColors.ivory,
            borderRadius: BorderRadius.circular(KernelRadii.lg),
            border: Border.all(color: KernelColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(
                label: s.userValidated
                    ? l.pestDetailConfirmed
                    : l.pestDetailNotConfirmed,
                tone: s.userValidated
                    ? StatusTone.positive
                    : StatusTone.neutral,
                icon: Icons.person_rounded,
              ),
              if (pickName != null) ...[
                const SizedBox(height: KernelSpace.sm),
                Text(
                  l.pestDetailYourPick(pickName),
                  key: const Key('sighting-user-pick'),
                ),
              ],
            ],
          ),
        ),
        SightingFindingSection(sighting: s),
        SectionTitle(l.pestDetailPlace),
        if (place != null) FieldRow(label: l.pestSaveRoom, value: place.name),
        if (pin) ...[
          FieldRow(
            label: l.pestDetailPinLabel,
            value: l.pestDetailPin(
              s.latitude!.toStringAsFixed(5),
              s.longitude!.toStringAsFixed(5),
              (s.accuracyMeters ?? 0).round(),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('sighting-show-map'),
              onPressed: () =>
                  context.push(Routes.sightingsMap(sightingId: s.id)),
              icon: const Icon(Icons.map_rounded),
              label: Text(l.pestDetailShowMap),
            ),
          ),
        ] else if (place == null)
          QuietNote(l.pestDetailNoPlace),
        if (s.distance case final distance?)
          PestDistanceNote(estimate: distance),
        if (s.notes case final notes? when notes.trim().isNotEmpty)
          FieldRow(label: l.pestNotes, value: notes),
        if (s.mediaPath != null) QuietNote(l.pestDetailMediaKept),
        if (card != null)
          KnowledgeCardView(card: card, userPicked: s.userCardId != null),
      ],
    );
  }
}

class _SoundRecord extends StatelessWidget {
  const _SoundRecord({required this.sound});

  final SoundAnalysis sound;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: const Key('sighting-sound'),
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
          const ExperimentalBadge(),
          const SizedBox(height: KernelSpace.sm),
          PestSoundLabels(labels: sound.preFilter),
          if (sound.groupHint != PestGroup.unknown) ...[
            const SizedBox(height: KernelSpace.xs),
            Text(l.pestGroupHint(sound.groupHint.label(l))),
          ],
          if (sound.description case final d? when d.trim().isNotEmpty) ...[
            const SizedBox(height: KernelSpace.sm),
            Text(l.pestSoundDescription, style: textTheme.titleSmall),
            Text(d, style: textTheme.bodyLarge),
          ],
          const SizedBox(height: KernelSpace.sm),
          Text(
            l.pestSoundModel(sound.modelVersion),
            style: textTheme.bodySmall?.copyWith(color: KernelColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../agents/orchestrator_agent.dart';
import '../../theme/tokens.dart';

import 'package:kernel_contracts/kernel_contracts.dart';

import '../../l10n/l10n.dart';
import '../pest_id/pest_widgets.dart';
import 'chat_copy.dart';

class ChatResponseView extends StatelessWidget {
  const ChatResponseView({super.key, required this.response});
  final OrchestratorResponse response;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final analysis = response.analysis;
    final generated = response.generated;
    final sound = response.sound;
    final levels = <SafetyLevel>{
      ...response.safetyLevels,
      ...safetyConcerns(
        aiLevel: response.analysis?.safety,
        cards: response.cards,
      ),
    };
    Widget paragraph(String text, {bool quiet = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: quiet ? 13 : 16,
          height: 1.5,
          color: quiet ? KernelColors.inkMuted : KernelColors.ink,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final notice in response.notices)
          paragraph(ChatCopy.notice(notice)),
        if (response.notices.contains(ChatNotice.imageUnavailable))
          paragraph(ChatCopy.unknownAnimal),
        if (sound != null) ...[
          if (sound.status == InsectSoundStatus.evaluated) ...[
            paragraph(ChatCopy.soundIdentification(sound)),
            paragraph(ChatCopy.soundDisclaimer),
            paragraph(ChatCopy.model(sound.modelVersion), quiet: true),
            paragraph(ChatCopy.soundScope),
            paragraph(ChatCopy.inspection),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(ChatCopy.modelDetails),
              children: [
                paragraph(ChatCopy.modelId(sound.modelId), quiet: true),
                if (sound.modelRevision != null)
                  paragraph(
                    ChatCopy.revision(sound.modelRevision!),
                    quiet: true,
                  ),
              ],
            ),
          ] else
            for (final reason in ChatCopy.soundFailureReasons(sound))
              paragraph(reason),
        ],
        if (analysis != null) ...[
          paragraph(ChatCopy.image(analysis.commonName)),
          paragraph(ChatCopy.model(analysis.modelVersion), quiet: true),
          paragraph(l.pestNotCertainNote),
          if (analysis.cardId == null || analysis.group == PestGroup.notAPest)
            paragraph(l.pestNoMatch),
        ],
        // Never collapse medical/protected warnings into one priority badge.
        for (final level in levels)
          if (level != SafetyLevel.low)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PestSafetyBanner(level: level),
            ),
        if (generated != null) ...[
          paragraph(generated.text),
          paragraph(ChatCopy.generated(generated.modelVersion), quiet: true),
        ],
        if (response.cards.isNotEmpty)
          paragraph(ChatCopy.knowledge, quiet: true),
        for (final card in response.cards) ...[
          paragraph(
            card.names[Localizations.localeOf(context).languageCode] ??
                card.names['en'] ??
                card.id,
          ),
          if (generated == null && card.summary.isNotEmpty)
            paragraph(card.summary),
          for (final step in card.safeSteps) paragraph('• $step'),
          for (final step in card.callProfessionalWhen) paragraph(step),
          for (final step in card.firstAid) paragraph(step),
          if (card.legal?.isNotEmpty == true) paragraph(card.legal!),
          if (card.reviewStatus != 'reviewed')
            paragraph(l.pestCardNeedsReview, quiet: true),
          if (card.sources.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l.pestCardSources),
              children: [
                for (final source in card.sources)
                  paragraph(source, quiet: true),
              ],
            ),
        ],
      ],
    );
  }
}

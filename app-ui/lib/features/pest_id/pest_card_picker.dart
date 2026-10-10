import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import 'pest_copy.dart';

/// Bottom sheet to correct the AI label with a different knowledge card.
/// The pick is stored as `userCardId`; the AI analysis is never changed.
Future<void> showPestCardPicker(
  BuildContext context, {
  required List<KnowledgeCard> cards,
  required String? selectedId,
  required ValueChanged<String?> onPicked,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  final sorted = [...cards]
    ..sort(
      (a, b) => cardName(
        a,
        lang,
      ).toLowerCase().compareTo(cardName(b, lang).toLowerCase()),
    );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final l = sheetContext.l10n;
      final textTheme = Theme.of(sheetContext).textTheme;
      void pick(String? id) {
        onPicked(id);
        Navigator.of(sheetContext).pop();
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
          ),
          child: ListView(
            key: const Key('pest-card-picker'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              KernelSpace.page,
              0,
              KernelSpace.page,
              KernelSpace.xl,
            ),
            children: [
              Text(
                l.pestPickCardTitle,
                style: textTheme.titleLarge?.copyWith(
                  color: KernelColors.forest,
                ),
              ),
              const SizedBox(height: KernelSpace.xs),
              Text(l.pestPickCardBody, style: textTheme.bodyMedium),
              const SizedBox(height: KernelSpace.sm),
              if (selectedId != null)
                ListTile(
                  key: const Key('pest-pick-clear'),
                  minTileHeight: 48,
                  leading: const Icon(Icons.undo_rounded),
                  title: Text(l.pestPickCardClear),
                  onTap: () => pick(null),
                ),
              for (final card in sorted)
                ListTile(
                  key: Key('pest-pick-${card.id}'),
                  minTileHeight: 48,
                  leading: Icon(
                    card.id == selectedId
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: KernelColors.forest,
                  ),
                  title: Text(cardName(card, lang)),
                  subtitle: Text(card.group.label(l)),
                  onTap: () => pick(card.id),
                ),
            ],
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import 'pest_copy.dart';
import 'pest_ranking.dart';

/// Close-up tiles from a capture, ranked by embedding hint. Tapping one
/// confirms it as a real signal (userValidated).
class PestTilesView extends StatelessWidget {
  const PestTilesView({
    super.key,
    required this.tiles,
    required this.cards,
    required this.onConfirm,
  });

  final List<RankedTile> tiles;
  final List<KnowledgeCard> cards;
  final ValueChanged<RankedTile> onConfirm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    String? hintName(String? id) {
      if (id == null) return null;
      for (final card in cards) {
        if (card.id == id) return cardName(card, lang);
      }
      return id.replaceAll('_', ' ');
    }

    return Column(
      key: const Key('pest-tiles'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l.pestTilesTitle,
            style: textTheme.titleLarge?.copyWith(color: KernelColors.forest),
          ),
        ),
        const SizedBox(height: KernelSpace.sm),
        if (tiles.isEmpty)
          Text(l.pestTilesEmpty, key: const Key('pest-tiles-empty'))
        else
          Wrap(
            spacing: KernelSpace.md,
            runSpacing: KernelSpace.md,
            children: [
              for (final ranked in tiles)
                _TileButton(
                  ranked: ranked,
                  hintName: hintName(ranked.hintCardId),
                  onTap: () => onConfirm(ranked),
                ),
            ],
          ),
      ],
    );
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton({
    required this.ranked,
    required this.hintName,
    required this.onTap,
  });

  final RankedTile ranked;
  final String? hintName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final kind = ranked.candidate?.kind;
    final hint = hintName;
    return SizedBox(
      width: 150,
      child: Material(
        color: KernelColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KernelRadii.md),
          side: const BorderSide(color: KernelColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('pest-tile-${ranked.tile.candidateId}'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.memory(
                  ranked.tile.image,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  semanticLabel: kind?.label(l),
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: KernelColors.sageDeep,
                    child: Icon(Icons.broken_image_rounded),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(KernelSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kind != null)
                      Text(
                        kind.label(l),
                        style: textTheme.labelLarge?.copyWith(
                          color: KernelColors.forest,
                        ),
                      ),
                    if (hint != null)
                      Text(l.pestTileHint(hint), style: textTheme.bodySmall),
                    const SizedBox(height: KernelSpace.xs),
                    Text(
                      l.pestTileConfirm,
                      style: textTheme.labelLarge?.copyWith(
                        color: KernelColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

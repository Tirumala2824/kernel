import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';

class FindingOption extends StatelessWidget {
  const FindingOption({
    super.key,
    required this.finding,
    required this.selected,
    required this.onTap,
  });

  final VerifiedFinding finding;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fg = selected ? KernelColors.onForest : KernelColors.ink;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? KernelColors.forest : KernelColors.ivory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KernelRadii.md),
          side: const BorderSide(color: KernelColors.forest),
        ),
        child: InkWell(
          key: Key('finding-${finding.name}'),
          borderRadius: BorderRadius.circular(KernelRadii.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: KernelSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? KernelColors.onForest : KernelColors.forest,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          finding.label(l),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                        ),
                        Text(
                          finding.help(l),
                          style: TextStyle(
                            color: selected
                                ? KernelColors.onForest
                                : KernelColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only AI output, visually distinct from the human finding: sage
/// background, grey outline, "AI prediction (not verified)" label and the
/// experimental badge, versus the white, forest-bordered finding panel.
class AiPredictionPanel extends StatelessWidget {
  const AiPredictionPanel({super.key, required this.scan, required this.linked});

  final ScanRecord? scan;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scan = this.scan;
    return Container(
      key: const Key('ai-prediction-panel'),
      padding: const EdgeInsets.all(KernelSpace.lg),
      decoration: BoxDecoration(
        color: KernelColors.sage,
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        border: Border.all(color: KernelColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory_rounded, color: KernelColors.inkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.aiPanelTitle,
                  style: textTheme.titleSmall?.copyWith(
                    color: KernelColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (scan == null)
            Text(linked ? l.aiPanelLoading : l.aiPanelNoScan)
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ScanResultChip(quality: scan.quality, result: scan.result),
                if (scan.experimental) const ExperimentalBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              provenanceLine(
                l,
                modelVersion: scan.modelVersion,
                experimental: scan.experimental,
              ),
            ),
            Text(l.scannedAt(formatDateTime(context, scan.capturedAt))),
          ],
          const SizedBox(height: 8),
          StatusChip(
            label: l.aiPanelNotUsed,
            tone: StatusTone.neutral,
            icon: Icons.link_off_rounded,
          ),
        ],
      ),
    );
  }
}

/// Evidence photos for the inspection being recorded.
class PhotosSection extends StatelessWidget {
  const PhotosSection({
    super.key,
    required this.photos,
    required this.busy,
    required this.onTake,
    required this.onPick,
    required this.onRemove,
  });

  final List<String> photos;
  final bool busy;
  final VoidCallback onTake;
  final VoidCallback onPick;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const Key('photos-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.photosTitle, style: textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          l.photosBody,
          style: textTheme.bodySmall?.copyWith(color: KernelColors.inkMuted),
        ),
        const SizedBox(height: 8),
        if (photos.isNotEmpty) ...[
          PhotoThumbs(paths: photos, onRemove: onRemove),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('photo-camera'),
              onPressed: busy ? null : onTake,
              icon: const Icon(Icons.photo_camera_rounded),
              label: Text(l.photoTake),
            ),
            OutlinedButton.icon(
              key: const Key('photo-gallery'),
              onPressed: busy ? null : onPick,
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(l.photoPick),
            ),
          ],
        ),
      ],
    );
  }
}

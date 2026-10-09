import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../app/copy.dart';
import '../app/platform_providers.dart';
import '../l10n/l10n.dart';
import '../theme/tokens.dart';
import 'status_chip.dart';

BoxDecoration _tileDecoration({Color? border}) => BoxDecoration(
  color: KernelColors.paper,
  borderRadius: BorderRadius.circular(KernelRadii.md),
  border: Border.all(color: border ?? KernelColors.hairline),
  boxShadow: KernelShadows.soft,
);

/// Tappable tile shell with a >=56dp target.
class _TileShell extends StatelessWidget {
  const _TileShell({required this.child, this.onTap, this.border});

  final Widget child;
  final VoidCallback? onTap;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KernelSpace.sm),
      child: Container(
        decoration: _tileDecoration(border: border),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(KernelRadii.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconWell extends StatelessWidget {
  const _IconWell(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: KernelColors.sage,
      borderRadius: BorderRadius.circular(KernelRadii.sm),
    ),
    child: Icon(icon, color: KernelColors.forest, size: 22),
  );
}

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
    this.footer,
  });

  final GrainItem item;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Extra content under the subtitle (chips, actions).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return _TileShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(KernelSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconWell(
              item.ownerRole == Role.household
                  ? Icons.kitchen_rounded
                  : Icons.inventory_2_rounded,
            ),
            const SizedBox(width: KernelSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    l.itemTileSubtitle(
                      item.grainType,
                      formatQuantity(item.quantity, item.quantityUnit),
                      formatDate(context, item.storageDate),
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      color: KernelColors.inkMuted,
                    ),
                  ),
                  if (item.isArchived) ...[
                    const SizedBox(height: KernelSpace.xs),
                    StatusChip(
                      label: l.archivedBadge,
                      icon: Icons.inventory_rounded,
                    ),
                  ],
                  if (footer != null) ...[
                    const SizedBox(height: KernelSpace.sm),
                    footer!,
                  ],
                ],
              ),
            ),
            const SizedBox(width: KernelSpace.sm),
            trailing ??
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: KernelColors.inkMuted,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Chip describing the model output of one scan. Never a verdict: RETRY and
/// notEvaluated never show a class; real classes are marked unverified.
class ScanResultChip extends StatelessWidget {
  const ScanResultChip({
    super.key,
    required this.quality,
    required this.result,
  });

  final ScanQuality quality;
  final Classification result;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (quality == ScanQuality.retry) {
      return StatusChip(
        label: l.chipRetryNeeded,
        tone: StatusTone.attention,
        icon: Icons.replay_rounded,
      );
    }
    return switch (result) {
      Classification.notEvaluated => StatusChip(
        label: l.predictionNotEvaluated,
        tone: StatusTone.neutral,
        icon: Icons.help_outline_rounded,
      ),
      Classification.infested || Classification.uncertain => StatusChip(
        label: l.chipAiUnverified(result.predictionLabel(l)),
        tone: StatusTone.attention,
        icon: Icons.manage_search_rounded,
      ),
      Classification.clean => StatusChip(
        label: l.chipAiUnverified(result.predictionLabel(l)),
        tone: StatusTone.neutral,
        icon: Icons.graphic_eq_rounded,
      ),
    };
  }
}

/// One immutable scan-history entry: time, quality, result, model version
/// and experimental status.
class ScanRecordTile extends StatelessWidget {
  const ScanRecordTile({
    super.key,
    required this.scan,
    this.itemLabel,
    this.onTap,
  });

  final ScanRecord scan;
  final String? itemLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final when = formatDateTime(context, scan.capturedAt);
    return _TileShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(KernelSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    itemLabel == null
                        ? when
                        : l.scanTileTitle(itemLabel!, when),
                    style: textTheme.titleSmall,
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: KernelColors.inkMuted,
                  ),
              ],
            ),
            const SizedBox(height: KernelSpace.sm),
            Wrap(
              spacing: KernelSpace.sm,
              runSpacing: KernelSpace.sm,
              children: [
                StatusChip(
                  label: l.qualityChip(scan.quality.label(l)),
                  tone: scan.quality == ScanQuality.pass
                      ? StatusTone.positive
                      : StatusTone.attention,
                  icon: scan.quality == ScanQuality.pass
                      ? Icons.graphic_eq_rounded
                      : Icons.replay_rounded,
                ),
                ScanResultChip(quality: scan.quality, result: scan.result),
                if (scan.experimental) const ExperimentalBadge(),
                if (scan.audioRetained)
                  StatusChip(
                    label: l.chipAudioKept,
                    icon: Icons.lock_rounded,
                  ),
              ],
            ),
            const SizedBox(height: KernelSpace.sm),
            Text(
              provenanceLine(
                l,
                modelVersion: scan.modelVersion,
                experimental: scan.experimental,
              ),
              style: textTheme.bodySmall?.copyWith(
                color: KernelColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Evidence photo thumbnails. Tapping one opens it full screen.
class PhotoThumbs extends ConsumerWidget {
  const PhotoThumbs({super.key, required this.paths, this.onRemove});

  final List<String> paths;

  /// When set, each thumbnail gets a remove button (unsaved photos).
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final image = ref.watch(photoImageProvider);
    return Wrap(
      spacing: KernelSpace.sm,
      runSpacing: KernelSpace.sm,
      children: [
        for (final (index, path) in paths.indexed)
          Stack(
            key: Key('photo-$index'),
            children: [
              Semantics(
                button: true,
                label: l.photoSemantics(index + 1),
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(KernelRadii.sm),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => Dialog(
                      clipBehavior: Clip.antiAlias,
                      child: Image(
                        image: image(path),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Padding(
                          padding: const EdgeInsets.all(KernelSpace.xl),
                          child: Text(l.photoMissing),
                        ),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(KernelRadii.sm),
                    child: SizedBox.square(
                      dimension: 72,
                      child: Image(
                        image: image(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: KernelColors.sage,
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: KernelColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: IconButton(
                    tooltip: l.photoRemove,
                    style: IconButton.styleFrom(
                      backgroundColor: KernelColors.paper,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => onRemove!(path),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Human-verified inspection. Rendered differently from AI output: it has
/// a "Verified finding" label, a forest border and a person icon, never a
/// model badge.
class InspectionTile extends StatelessWidget {
  const InspectionTile({
    super.key,
    required this.inspection,
    this.onFollowUpChanged,
    this.onAssign,
    this.itemLabel,
    this.onOpenItem,
  });

  final Inspection inspection;
  final ValueChanged<FollowUpStatus>? onFollowUpChanged;
  final VoidCallback? onAssign;
  final String? itemLabel;
  final VoidCallback? onOpenItem;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final assignee = inspection.assignedTo;
    return Padding(
      padding: const EdgeInsets.only(bottom: KernelSpace.sm),
      child: Container(
        decoration: BoxDecoration(
          color: KernelColors.paper,
          borderRadius: BorderRadius.circular(KernelRadii.md),
          border: Border.all(color: KernelColors.forest, width: 2),
        ),
        padding: const EdgeInsets.all(KernelSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (itemLabel != null)
              InkWell(
                onTap: onOpenItem,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: KernelSpace.xs),
                  child: Text(
                    itemLabel!,
                    style: textTheme.titleMedium?.copyWith(
                      color: KernelColors.forest,
                      decoration: onOpenItem == null
                          ? null
                          : TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                const Icon(
                  Icons.person_search_rounded,
                  color: KernelColors.forest,
                ),
                const SizedBox(width: KernelSpace.sm),
                Expanded(
                  child: Text(
                    l.verifiedFindingLine(
                      inspection.verifiedFinding.label(l),
                    ),
                    style: textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KernelSpace.xs),
            Text(
              l.inspectorLine(
                inspection.inspector,
                formatDateTime(context, inspection.inspectedAt),
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: KernelColors.inkMuted,
              ),
            ),
            if (inspection.observations.isNotEmpty) ...[
              const SizedBox(height: KernelSpace.xs),
              Text(inspection.observations, style: textTheme.bodyMedium),
            ],
            if (inspection.photoPaths.isNotEmpty) ...[
              const SizedBox(height: KernelSpace.sm),
              PhotoThumbs(paths: inspection.photoPaths),
            ],
            const SizedBox(height: KernelSpace.sm),
            Wrap(
              spacing: KernelSpace.sm,
              runSpacing: KernelSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(
                  label: l.followUpChip(inspection.followUpStatus.label(l)),
                  tone: inspection.followUpStatus == FollowUpStatus.done
                      ? StatusTone.positive
                      : StatusTone.attention,
                  icon: inspection.followUpStatus == FollowUpStatus.done
                      ? Icons.task_alt_rounded
                      : Icons.pending_actions_rounded,
                ),
                StatusChip(
                  label: assignee == null || assignee.isEmpty
                      ? l.unassigned
                      : l.assignedToChip(assignee),
                  icon: Icons.assignment_ind_rounded,
                ),
                if (onFollowUpChanged != null)
                  PopupMenuButton<FollowUpStatus>(
                    key: Key('follow-up-menu-${inspection.id}'),
                    tooltip: l.followUpChangeTooltip,
                    onSelected: onFollowUpChanged,
                    itemBuilder: (_) => [
                      for (final status in FollowUpStatus.values)
                        PopupMenuItem(
                          value: status,
                          child: Text(status.label(l)),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        l.followUpUpdate,
                        style: textTheme.labelLarge?.copyWith(
                          color: KernelColors.forest,
                        ),
                      ),
                    ),
                  ),
                if (onAssign != null)
                  TextButton.icon(
                    key: Key('assign-${inspection.id}'),
                    onPressed: onAssign,
                    icon: const Icon(Icons.person_add_alt_rounded),
                    label: Text(l.assignAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LocationTile extends StatelessWidget {
  const LocationTile({
    super.key,
    required this.location,
    required this.onTap,
    this.subtitle,
  });

  final Location location;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return _TileShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(KernelSpace.md),
        child: Row(
          children: [
            _IconWell(location.type.icon),
            const SizedBox(width: KernelSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location.name, style: textTheme.titleMedium),
                  Text(
                    subtitle ?? location.type.label(l),
                    style: textTheme.bodyMedium?.copyWith(
                      color: KernelColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: KernelColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

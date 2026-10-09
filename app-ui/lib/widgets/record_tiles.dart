import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../app/copy.dart';
import '../theme/tokens.dart';
import 'status_chip.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
  });

  final GrainItem item;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: KernelColors.outline),
      ),
      child: ListTile(
        minTileHeight: KernelSizes.minTouchTarget + 16,
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(item.label),
        subtitle: Text(
          '${item.grainType} · ${formatQuantity(item.quantity, item.quantityUnit)}'
          ' · stored ${formatDate(context, item.storageDate)}',
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
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
    if (quality == ScanQuality.retry) {
      return const StatusChip(
        label: 'Retry needed',
        tone: StatusTone.attention,
        icon: Icons.replay,
      );
    }
    return switch (result) {
      Classification.notEvaluated => const StatusChip(
        label: 'Not evaluated',
        tone: StatusTone.neutral,
        icon: Icons.help_outline,
      ),
      Classification.infested || Classification.uncertain => StatusChip(
        label: 'AI: ${result.predictionLabel} (unverified)',
        tone: StatusTone.attention,
      ),
      Classification.clean => StatusChip(
        label: 'AI: ${result.predictionLabel} (unverified)',
        tone: StatusTone.positive,
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
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: KernelColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(KernelSizes.gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      itemLabel == null
                          ? formatDateTime(context, scan.capturedAt)
                          : '$itemLabel · ${formatDateTime(context, scan.capturedAt)}',
                      style: textTheme.titleSmall,
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: 'Quality: ${scan.quality.label}',
                    tone: scan.quality == ScanQuality.pass
                        ? StatusTone.positive
                        : StatusTone.attention,
                    icon: scan.quality == ScanQuality.pass
                        ? Icons.graphic_eq
                        : Icons.replay,
                  ),
                  ScanResultChip(quality: scan.quality, result: scan.result),
                  if (scan.experimental) const ExperimentalBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                provenanceLine(
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
      ),
    );
  }
}

/// Human-verified inspection. Rendered differently from AI output: it has
/// a "Verified finding" label and a person icon, never a model badge.
class InspectionTile extends StatelessWidget {
  const InspectionTile({
    super.key,
    required this.inspection,
    this.onFollowUpChanged,
  });

  final Inspection inspection;
  final ValueChanged<FollowUpStatus>? onFollowUpChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: KernelColors.ivory,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: KernelColors.forest, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KernelSizes.gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_search, color: KernelColors.forest),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verified finding: ${inspection.verifiedFinding.label}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${inspection.inspector} · '
              '${formatDateTime(context, inspection.inspectedAt)}',
            ),
            if (inspection.observations.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(inspection.observations),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(
                  label: 'Follow-up: ${inspection.followUpStatus.label}',
                  tone: inspection.followUpStatus == FollowUpStatus.done
                      ? StatusTone.positive
                      : StatusTone.attention,
                ),
                if (onFollowUpChanged != null)
                  PopupMenuButton<FollowUpStatus>(
                    tooltip: 'Change follow-up status',
                    onSelected: onFollowUpChanged,
                    itemBuilder: (_) => [
                      for (final status in FollowUpStatus.values)
                        PopupMenuItem(value: status, child: Text(status.label)),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Update status'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

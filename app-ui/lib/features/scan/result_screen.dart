import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';
import '../inventory/item_detail_screen.dart';

/// F06 screening result for one stored scan. Never a confident verdict:
/// RETRY and notEvaluated show no class, and model provenance plus
/// experimental status are always visible.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.itemId, required this.scanId});

  final String itemId;
  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scans = ref.watch(scansForItemProvider(itemId));
    return Scaffold(
      appBar: const KernelAppBar(title: 'Result'),
      body: AsyncView<List<ScanRecord>>(
        value: scans,
        data: (scans) {
          final scan = scans.where((s) => s.id == scanId).firstOrNull;
          if (scan == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('This scan was not found on this phone.'),
            );
          }
          return _ResultBody(scan: scan);
        },
      ),
    );
  }
}

class _ResultBody extends ConsumerWidget {
  const _ResultBody({required this.scan});

  final ScanRecord scan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemProvider(scan.itemId)).value;
    final isRetry = scan.quality == ScanQuality.retry;
    final hasClass = !isRetry && scan.result != Classification.notEvaluated;
    final attention =
        isRetry ||
        scan.result == Classification.infested ||
        scan.result == Classification.uncertain;
    final provenance = provenanceLine(
      modelVersion: scan.modelVersion,
      experimental: scan.experimental,
    );
    final headline = resultHeadline(
      quality: scan.quality,
      classification: scan.result,
      modelVersion: scan.modelVersion,
    );
    final micBlocked = scan.qualityReasons.contains(
      QualityReason.permissionDenied,
    );

    return PageList(
      children: [
        ScreenHeader(title: 'Screening result', subtitle: provenance),
        KernelCard(
          key: const Key('result-headline'),
          tone: attention ? KernelCardTone.attention : KernelCardTone.hero,
          icon: isRetry
              ? Icons.replay
              : hasClass
              ? Icons.science_outlined
              : Icons.help_outline,
          title: headline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRetry) ...[
                for (final reason in scan.qualityReasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(reason.explanation)),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                const Text('Nothing about pests was saved for this recording.'),
              ],
              if (hasClass) ...[
                Text(
                  'Model prediction (unverified): '
                  '${scan.result.predictionLabel}',
                  key: const Key('predicted-class'),
                ),
                if (scan.confidence != null)
                  Text(
                    'Model score: ${scan.confidence!.toStringAsFixed(2)} '
                    '(experimental, not an accuracy figure)',
                  ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    key: const Key('provenance-chip'),
                    label: provenance,
                    tone: StatusTone.info,
                    icon: Icons.memory,
                  ),
                  if (scan.experimental) const ExperimentalBadge(),
                ],
              ),
            ],
          ),
        ),
        if (isRetry)
          FilledButton.icon(
            key: const Key('retry'),
            onPressed: () =>
                context.pushReplacement(Routes.scanItem(scan.itemId)),
            icon: const Icon(Icons.replay),
            label: const Text('Retry'),
          ),
        if (micBlocked)
          OutlinedButton.icon(
            onPressed: () => ref.read(devicePermissionsProvider).openSettings(),
            icon: const Icon(Icons.settings),
            label: const Text('Open settings'),
          ),
        const Text(physicalInspectionNote, key: Key('inspection-note')),
        if (item != null)
          ItemSummaryCard(
            item: item,
            onTap: () => context.push(Routes.item(item.id)),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              key: const Key('record-inspection'),
              onPressed: () =>
                  context.push(Routes.inspect(scan.itemId, scanId: scan.id)),
              icon: const Icon(Icons.person_search),
              label: const Text('Record inspection'),
            ),
            OutlinedButton.icon(
              key: const Key('scan-another'),
              onPressed: () => context.go(Routes.scan),
              icon: const Icon(Icons.graphic_eq),
              label: const Text('Scan another'),
            ),
          ],
        ),
        const SectionTitle('Recording details'),
        ScanRecordTile(scan: scan),
        FieldRow(
          label: 'Captured',
          value: formatDateTime(context, scan.capturedAt),
        ),
        FieldRow(label: 'Duration', value: '${scan.durationMs} ms'),
        FieldRow(label: 'Sample rate', value: '${scan.sampleRate} Hz'),
        FieldRow(label: 'Analysis time', value: '${scan.latencyMs} ms'),
        FieldRow(
          label: 'Device',
          value: '${scan.deviceModel} (${scan.osVersion})',
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../brand/illustrations.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';
import 'label_options.dart';

/// Research samples: counts per label and a local dataset export (ZIP of
/// retained WAVs plus a CSV manifest) that the user shares themselves.
class SamplesScreen extends ConsumerStatefulWidget {
  const SamplesScreen({super.key});

  @override
  ConsumerState<SamplesScreen> createState() => _SamplesScreenState();
}

class _SamplesScreenState extends ConsumerState<SamplesScreen> {
  bool _exporting = false;
  String? _error;

  Future<void> _export() async {
    final l = context.l10n;
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final path = await ref.read(datasetExportServiceProvider).exportZip();
      if (!mounted) return;
      await ref
          .read(reportSharerProvider)
          .shareFile(path, subject: l.shareSubject(l.datasetTitle));
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.datasetExportFailed('$e'));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final samples = ref.watch(labeledSamplesProvider);
    final research = ref.watch(researchModeProvider).value ?? false;
    return Scaffold(
      appBar: KernelAppBar(title: l.samplesTitle),
      body: AsyncView<List<LabeledSample>>(
        value: samples,
        data: (samples) {
          int count(SampleLabel label) =>
              samples.where((s) => s.label == label).length;
          return PageList(
            children: [
              ScreenHeader(
                title: l.samplesTitle,
                subtitle: l.samplesSubtitle(samples.length),
              ),
              if (!research) QuietNote(l.samplesResearchOff),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in SampleLabel.values)
                    StatTile(
                      key: Key('count-${label.name}'),
                      value: '${count(label)}',
                      label: label.label(l),
                    ),
                ],
              ),
              KernelCard(
                key: const Key('dataset-export'),
                tone: KernelCardTone.sage,
                icon: Icons.folder_zip_rounded,
                title: l.datasetTitle,
                subtitle: l.datasetBody,
                child: FilledButton.icon(
                  key: const Key('export-dataset'),
                  onPressed: samples.isEmpty || _exporting ? null : _export,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(l.datasetExport),
                ),
              ),
              if (_error != null) ErrorNote(_error!),
              if (samples.isEmpty)
                EmptyState(
                  illustration: KernelIllustrations.recordings,
                  message: l.samplesEmpty,
                  detail: l.samplesEmptyDetail,
                  actionLabel: l.actionBrowseInventory,
                  actionIcon: Icons.inventory_2_rounded,
                  onAction: () => context.go(Routes.inventory),
                )
              else
                for (final sample in [...samples]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                  _SampleTile(sample: sample),
            ],
          );
        },
      ),
    );
  }
}

class _SampleTile extends ConsumerWidget {
  const _SampleTile({required this.sample});

  final LabeledSample sample;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final item = ref.watch(itemProvider(sample.itemId)).value;
    final material = sample.sackMaterial;
    return KernelCard(
      key: Key('sample-${sample.id}'),
      tone: KernelCardTone.ivory,
      icon: Icons.graphic_eq_rounded,
      title: item?.label ?? l.archivedBadge,
      subtitle: [
        formatDateTime(context, sample.createdAt),
        sample.grainType,
        if (material != null) sackMaterialLabel(l, material),
        ?sample.environment,
      ].join(' · '),
      onTap: () => context.push(Routes.result(sample.itemId, sample.scanId)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusChip(
            label: l.sampleLabelChip(sample.label.label(l)),
            tone: sample.label == SampleLabel.unknown
                ? StatusTone.neutral
                : StatusTone.info,
            icon: Icons.label_rounded,
          ),
          if (sample.inspectionId != null)
            StatusChip(
              label: l.sampleConfirmed,
              icon: Icons.verified_user_rounded,
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';
import 'download_consent_sheet.dart';
import 'hub_copy.dart';
import 'hub_providers.dart';
import 'hub_search.dart';

/// Model Hub: optional Pest ID downloads, consent, progress, installed files
/// and on-phone semantic search. The subtitle describes Android's bundled
/// insect WAV checks; their availability is not inferred from this registry.
/// Only catalogs and model files use the network here (guardrails §7).
class ModelHubScreen extends ConsumerWidget {
  const ModelHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: KernelAppBar(title: l.hubTitle),
      body: PageList(
        children: [
          ScreenHeader(title: l.hubTitle, subtitle: l.hubSubtitle),
          const PestIdStatusCard(),
          const _DownloadsSection(),
          QuietNote(
            l.hubGalleryNote,
            key: const Key('hub-gallery-note'),
            icon: Icons.folder_off_rounded,
          ),
          SectionTitle(l.hubInstalledTitle),
          const _InstalledList(),
          SectionTitle(l.hubSearchAction),
          const HubSearchPanel(),
        ],
      ),
    );
  }
}

/// Starts the Pest ID downloads, asking for the one-time consent first.
/// `ensure` is never reached without consent.
Future<void> startPestIdDownloads(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final provisioner = ref.read(modelProvisionerProvider);
    final consent = await provisioner.watchConsent().first;
    if (!consent.granted) {
      final entries = await ref.read(pestIdPlanProvider.future);
      if (!context.mounted) return;
      final choice = await showDownloadConsentSheet(
        context,
        entries: entries,
        initialWifiOnly: consent.wifiOnly,
      );
      if (choice == null || !choice.granted) return;
      await provisioner.setConsent(choice);
    }
    await ref.read(hubDownloadsProvider.notifier).start();
  } on Object catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l.hubDownloadFailed('$e'))),
    );
  }
}

/// Optional image, search and live sound models, each shown as installed or
/// missing based only on the downloadable-model registry, plus remaining files.
class PestIdStatusCard extends ConsumerWidget {
  const PestIdStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final installed = ref.watch(installedModelsProvider);
    final plan = ref.watch(pestIdPlanProvider);
    final downloads = ref.watch(hubDownloadsProvider);
    return KernelCard(
      key: const Key('hub-status'),
      icon: Icons.pest_control_rounded,
      title: l.hubNeedsTitle,
      child: AsyncView<List<InstalledModel>>(
        value: installed,
        errorPrefix: l.hubInstalledUnavailable,
        data: (models) {
          final missing = [
            for (final c in pestIdNeeds)
              if (!hasCapability(models, c)) c,
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final need in pestIdNeeds)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: KernelSpace.xs,
                  ),
                  child: Wrap(
                    spacing: KernelSpace.sm,
                    runSpacing: KernelSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        pestIdNeedLabel(l, need),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      StatusChip(
                        key: Key('hub-need-${need.name}'),
                        label: hasCapability(models, need)
                            ? l.hubInstalledChip
                            : l.hubMissingChip,
                        tone: hasCapability(models, need)
                            ? StatusTone.positive
                            : StatusTone.attention,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: KernelSpace.sm),
              if (missing.isEmpty)
                Text(l.hubAllInstalled, key: const Key('hub-all-installed'))
              else
                AsyncView<List<CatalogEntry>>(
                  value: plan,
                  errorPrefix: l.hubCatalogUnavailable,
                  data: (entries) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (entries.isNotEmpty)
                        Text(
                          l.hubDownloadSummary(
                            entries.length,
                            formatBytes(l, totalBytes(entries)),
                          ),
                          key: const Key('hub-plan-summary'),
                        )
                      else
                        Text(
                          l.hubNothingToDownload,
                          key: const Key('hub-plan-empty'),
                        ),
                      const SizedBox(height: KernelSpace.sm),
                      if (entries.isNotEmpty)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FilledButton.icon(
                            key: const Key('hub-download'),
                            onPressed: downloads.running
                                ? null
                                : () => startPestIdDownloads(context, ref),
                            icon: const Icon(Icons.download_rounded),
                            label: Text(l.hubDownloadAction),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Consent state (with the Wi-Fi switch once given) and live progress per
/// file, with cancel.
class _DownloadsSection extends ConsumerWidget {
  const _DownloadsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final consent = ref.watch(downloadConsentProvider).value;
    final downloads = ref.watch(hubDownloadsProvider);
    final names = {
      for (final e in ref.watch(catalogEntriesProvider).value ?? <CatalogEntry>[])
        e.id: e.name,
      for (final e in ref.watch(pestIdPlanProvider).value ?? <CatalogEntry>[])
        e.id: e.name,
    };
    final children = <Widget>[
      if (consent?.granted == true)
        KernelCard(
          key: const Key('hub-consent-given'),
          tone: KernelCardTone.ivory,
          icon: Icons.verified_user_rounded,
          title: l.hubConsentGrantedTitle,
          child: SwitchListTile(
            key: const Key('hub-wifi-only'),
            contentPadding: EdgeInsets.zero,
            value: consent!.wifiOnly,
            onChanged: (v) => ref
                .read(modelProvisionerProvider)
                .setConsent(DownloadConsent(granted: true, wifiOnly: v)),
            title: Text(l.hubWifiOnly),
            subtitle: Text(l.hubWifiOnlyBody),
          ),
        ),
      if (downloads.progress.isNotEmpty)
        KernelCard(
          key: const Key('hub-downloads'),
          tone: KernelCardTone.ivory,
          icon: Icons.downloading_rounded,
          title: l.hubDownloadsTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in downloads.progress.values)
                _ProgressRow(progress: p, name: names[p.entryId] ?? p.entryId),
            ],
          ),
        ),
      if (downloads.error != null)
        ErrorNote(
          l.hubDownloadFailed(downloads.error!),
          key: const Key('hub-download-error'),
        ),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: KernelSpace.md),
          children[i],
        ],
      ],
    );
  }
}

class _ProgressRow extends ConsumerWidget {
  const _ProgressRow({required this.progress, required this.name});

  final ProvisionProgress progress;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = progress;
    final waitingForSpace = p.phase == ProvisionPhase.waitingForSpace;
    final free = waitingForSpace
        ? ref.watch(modelFreeSpaceProvider).value
        : null;
    // Always determinate: the phase text says what is happening.
    final fraction = p.phase == ProvisionPhase.installed
        ? 1.0
        : p.totalBytes <= 0
        ? 0.0
        : (p.bytesDone / p.totalBytes).clamp(0.0, 1.0);
    final busy = !isFinalPhase(p.phase);
    return Padding(
      key: Key('hub-progress-${p.entryId}'),
      padding: const EdgeInsets.symmetric(vertical: KernelSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: KernelSpace.xs),
          LinearProgressIndicator(value: fraction, semanticsLabel: name),
          const SizedBox(height: KernelSpace.xs),
          Text(
            provisionPhaseLine(l, p),
            key: Key('hub-phase-${p.entryId}'),
          ),
          if (free != null)
            Text(
              l.hubFreeSpace(formatBytes(l, free)),
              key: Key('hub-free-${p.entryId}'),
            ),
          if (busy)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: Key('hub-cancel-${p.entryId}'),
                onPressed: () =>
                    ref.read(hubDownloadsProvider.notifier).cancel(p.entryId),
                icon: const Icon(Icons.close_rounded),
                label: Text(l.hubCancel),
              ),
            ),
        ],
      ),
    );
  }
}

/// Installed files: path, size, version, capabilities, backends, a
/// "matches Gallery" badge, and remove.
class _InstalledList extends ConsumerWidget {
  const _InstalledList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final installed = ref.watch(installedModelsProvider);
    final catalog = {
      for (final e in ref.watch(catalogEntriesProvider).value ?? <CatalogEntry>[])
        e.id: e,
    };
    return AsyncView<List<InstalledModel>>(
      value: installed,
      errorPrefix: l.hubInstalledUnavailable,
      data: (models) {
        if (models.isEmpty) {
          return EmptyState(
            key: const Key('hub-installed-empty'),
            message: l.hubInstalledEmpty,
            detail: l.hubInstalledEmptyDetail,
            actionLabel: l.hubDownloadAction,
            actionIcon: Icons.download_rounded,
            onAction: () => startPestIdDownloads(context, ref),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final m in models) ...[
              _InstalledCard(
                model: m,
                entry: m.catalogEntryId == null
                    ? null
                    : catalog[m.catalogEntryId],
              ),
              const SizedBox(height: KernelSpace.md),
            ],
          ],
        );
      },
    );
  }
}

class _InstalledCard extends ConsumerWidget {
  const _InstalledCard({required this.model, this.entry});

  final InstalledModel model;
  final CatalogEntry? entry;

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await confirmAction(
      context,
      icon: Icons.delete_outline_rounded,
      title: l.hubRemoveConfirmTitle,
      body: l.hubRemoveConfirmBody,
      confirmLabel: l.hubRemove,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(modelProvisionerProvider).remove(model.path);
      await ref.read(modelRegistryProvider).rescan();
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.hubRemoveFailed('$e'))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fileName = model.path.split(RegExp(r'[\\/]')).last;
    final fromGallery = entry?.source == ModelSource.galleryCatalog;
    return KernelCard(
      key: Key('hub-installed-${model.path}'),
      tone: KernelCardTone.ivory,
      icon: Icons.memory_rounded,
      title: entry?.name ?? fileName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fromGallery) ...[
            StatusChip(
              key: Key('hub-gallery-match-${model.path}'),
              label: l.hubMatchesGallery,
              tone: StatusTone.positive,
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: KernelSpace.xs),
          ],
          FieldRow(label: l.hubFieldPath, value: model.path),
          FieldRow(
            label: l.hubFieldSize,
            value: formatBytes(l, model.sizeBytes),
          ),
          FieldRow(label: l.hubFieldVersion, value: model.version),
          FieldRow(
            label: l.hubFieldCapabilities,
            value: model.capabilities.isEmpty
                ? '-'
                : [for (final c in model.capabilities) c.label(l)].join(', '),
          ),
          FieldRow(
            label: l.hubFieldBackends,
            value: model.backends.isEmpty
                ? '-'
                : model.backends.map((b) => b.toUpperCase()).join(', '),
          ),
          const SizedBox(height: KernelSpace.sm),
          OutlinedButton.icon(
            key: Key('hub-remove-${model.path}'),
            onPressed: () => _remove(context, ref),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l.hubRemove),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';
import 'settings_sections.dart';

/// Settings → "On-phone AI assistant (experimental)": the opt-in, the
/// engine status, model details, import from a file the user already has,
/// and delete. Nothing is downloaded by the app.
class AdviceSettingsSection extends ConsumerWidget {
  const AdviceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final optIn = ref.watch(localAdviceOptInProvider);
    final status = ref.watch(effectiveAdviceStatusProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          children: [
            SwitchListTile(
              key: const Key('advice-toggle'),
              secondary: const Icon(Icons.auto_awesome_rounded),
              value: optIn.value ?? false,
              onChanged: optIn.hasValue
                  ? ref.read(settingsRepositoryProvider).setLocalAdviceOptIn
                  : null,
              title: Text(l.adviceToggle),
              subtitle: Text(l.adviceToggleBody),
            ),
          ],
        ),
        const SizedBox(height: KernelSpace.md),
        KernelCard(
          key: const Key('advice-status'),
          tone: KernelCardTone.ivory,
          icon: Icons.memory_rounded,
          title: l.adviceStatusTitle,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusChip(
              key: const Key('advice-status-chip'),
              label: status == null ? l.loading : status.label(l),
              tone: switch (status) {
                AdviceStatus.ready => StatusTone.positive,
                AdviceStatus.failed => StatusTone.attention,
                _ => StatusTone.neutral,
              },
            ),
          ),
        ),
        const SizedBox(height: KernelSpace.md),
        const _ModelCard(),
        const SizedBox(height: KernelSpace.md),
        QuietNote(
          l.adviceHelp,
          key: const Key('advice-help'),
          icon: Icons.help_outline_rounded,
        ),
      ],
    );
  }
}

class _ModelCard extends ConsumerStatefulWidget {
  const _ModelCard();

  @override
  ConsumerState<_ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends ConsumerState<_ModelCard> {
  StreamSubscription<ModelImportProgress>? _sub;
  ModelImportProgress? _progress;
  String? _error;
  bool _imported = false;
  bool _busy = false;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  Future<void> _import() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
      _imported = false;
      _progress = null;
    });
    try {
      final uri = await ref.read(modelFilePickerProvider)();
      if (!mounted) return;
      if (uri == null) {
        setState(() => _busy = false);
        return;
      }
      final manager = ref.read(adviceModelManagerProvider);
      final free = await manager.freeSpaceBytes();
      if (!mounted) return;
      await _sub?.cancel();
      _sub = manager
          .importFromUri(uri)
          .listen(
            (p) => _onProgress(p, free),
            onError: (Object e) => _fail(l.adviceImportFailed('$e')),
            onDone: () {
              if (mounted && _busy) setState(() => _busy = false);
            },
          );
    } on Object catch (e) {
      _fail(l.adviceImportFailed('$e'));
    }
  }

  void _onProgress(ModelImportProgress p, int free) {
    if (!mounted) return;
    final l = context.l10n;
    final total = p.totalBytes;
    if (total != null && total > free && p.phase == ModelImportPhase.copying) {
      unawaited(_sub?.cancel());
      _fail(l.adviceImportNoSpace(formatBytes(l, total), formatBytes(l, free)));
      return;
    }
    switch (p.phase) {
      case ModelImportPhase.failed:
        _fail(l.adviceImportFailed(p.error ?? '-'));
      case ModelImportPhase.done:
        setState(() {
          _progress = p;
          _busy = false;
          _imported = true;
        });
        ref.invalidate(adviceModelInfoProvider);
      case ModelImportPhase.copying || ModelImportPhase.verifying:
        setState(() => _progress = p);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
      _error = message;
    });
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final confirmed = await confirmAction(
      context,
      icon: Icons.delete_outline_rounded,
      title: l.adviceDeleteConfirmTitle,
      body: l.adviceDeleteConfirmBody,
      confirmLabel: l.adviceDeleteAction,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(adviceModelManagerProvider).deleteModel();
      if (!mounted) return;
      setState(() => _imported = false);
      ref.invalidate(adviceModelInfoProvider);
    } on Object catch (e) {
      _fail(l.adviceDeleteFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final info = ref.watch(adviceModelInfoProvider).value;
    final progress = _progress;
    return KernelCard(
      key: const Key('advice-model'),
      tone: KernelCardTone.sage,
      icon: Icons.inventory_2_rounded,
      title: l.adviceModelTitle,
      subtitle: info == null ? l.adviceModelNone : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (info != null) ...[
            FieldRow(label: l.adviceModelId, value: info.id),
            FieldRow(label: l.adviceModelVersion, value: info.version),
            FieldRow(
              label: l.adviceModelSize,
              value: formatBytes(l, info.sizeBytes),
            ),
            FieldRow(
              label: l.adviceModelBackend,
              value: switch (info.backend) {
                'gpu' => l.adviceBackendGpu,
                'cpu' => l.adviceBackendCpu,
                _ => l.adviceBackendNone,
              },
            ),
            const SizedBox(height: KernelSpace.sm),
          ],
          if (_busy && progress != null) ...[
            LinearProgressIndicator(
              key: const Key('advice-import-progress'),
              value: progress.totalBytes == null || progress.totalBytes == 0
                  ? null
                  : (progress.bytesCopied / progress.totalBytes!).clamp(
                      0.0,
                      1.0,
                    ),
              semanticsLabel: l.adviceImporting,
            ),
            const SizedBox(height: KernelSpace.xs),
            Text(
              progress.phase == ModelImportPhase.verifying
                  ? l.adviceImportVerifying
                  : progress.totalBytes == null
                  ? l.adviceImportCopied(formatBytes(l, progress.bytesCopied))
                  : l.adviceImportCopying(
                      formatBytes(l, progress.bytesCopied),
                      formatBytes(l, progress.totalBytes!),
                    ),
              key: const Key('advice-import-status'),
            ),
            const SizedBox(height: KernelSpace.sm),
          ],
          if (_imported) ...[
            Text(l.adviceImportDone, key: const Key('advice-import-done')),
            const SizedBox(height: KernelSpace.sm),
          ],
          if (_error != null) ...[
            ErrorNote(_error!, key: const Key('advice-import-error')),
            const SizedBox(height: KernelSpace.sm),
          ],
          ActionWrap(
            children: [
              FilledButton.icon(
                key: const Key('advice-import'),
                onPressed: _busy ? null : _import,
                // Progress is shown by the bar above, not by a spinner.
                icon: const Icon(Icons.file_open_rounded),
                label: Text(l.adviceImportAction),
              ),
              if (info != null)
                OutlinedButton.icon(
                  key: const Key('advice-delete'),
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l.adviceDeleteAction),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

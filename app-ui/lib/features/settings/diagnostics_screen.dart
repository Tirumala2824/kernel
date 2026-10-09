import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/rules.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';

/// Engine diagnostics for device validation: model version and note,
/// delegate, sample rates, audio source, device and OS, plus a row ready to
/// paste into docs/device-validation.md.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final info = ref.watch(engineInfoProvider);
    final version = ref.watch(appVersionProvider).value ?? '…';
    return Scaffold(
      appBar: KernelAppBar(title: l.diagnosticsTitle),
      body: AsyncView<EngineInfo>(
        value: info,
        errorPrefix: l.engineUnavailable,
        data: (info) {
          String hz(int? v) => v == null ? l.notMeasured : l.unitHz(v);
          final row = deviceLogRow(
            date: DateTime.now(),
            build: version,
            info: info,
          );
          final note = info.modelNote?.trim();
          return PageList(
            children: [
              ScreenHeader(
                title: l.diagnosticsTitle,
                subtitle: l.diagnosticsSubtitle,
              ),
              KernelCard(
                key: const Key('diag-model'),
                icon: Icons.memory_rounded,
                title: provenanceLine(
                  l,
                  modelVersion: info.modelVersion,
                  experimental: info.experimental,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldRow(
                      label: l.diagModelInstalled,
                      value: info.modelPresent ? l.yes : l.no,
                    ),
                    FieldRow(
                      label: l.diagModelNote,
                      value: note == null || note.isEmpty ? '-' : note,
                    ),
                    FieldRow(
                      label: l.diagDelegate,
                      value: info.delegate.name,
                    ),
                    if (info.experimental) ...[
                      const SizedBox(height: 6),
                      const ExperimentalBadge(),
                    ],
                  ],
                ),
              ),
              KernelCard(
                key: const Key('diag-audio'),
                icon: Icons.mic_rounded,
                title: l.diagAudioTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldRow(
                      label: l.diagTargetRate,
                      value: l.unitHz(info.targetSampleRate),
                    ),
                    FieldRow(
                      label: l.diagEffectiveRate,
                      value: hz(info.effectiveSampleRate),
                    ),
                    FieldRow(
                      label: l.diagDeviceRate,
                      value: hz(info.deviceInputSampleRate),
                    ),
                    FieldRow(
                      label: l.diagAudioSource,
                      value: info.audioSource ?? l.notMeasured,
                    ),
                  ],
                ),
              ),
              KernelCard(
                key: const Key('diag-device'),
                icon: Icons.smartphone_rounded,
                title: l.diagDeviceTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldRow(label: l.fieldDevice, value: info.deviceModel),
                    FieldRow(label: l.diagOs, value: info.osVersion),
                    FieldRow(label: l.diagAppVersion, value: version),
                  ],
                ),
              ),
              SectionTitle(l.diagLogRowTitle),
              Text(l.diagLogRowBody),
              Container(
                padding: const EdgeInsets.all(KernelSpace.md),
                decoration: BoxDecoration(
                  color: KernelColors.sage,
                  borderRadius: BorderRadius.circular(KernelRadii.md),
                ),
                child: SelectableText(
                  row,
                  key: const Key('device-log-row'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              FilledButton.icon(
                key: const Key('copy-device-row'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: row));
                  messenger.showSnackBar(
                    SnackBar(content: Text(l.diagCopied)),
                  );
                },
                icon: const Icon(Icons.content_copy_rounded),
                label: Text(l.diagCopyRow),
              ),
            ],
          );
        },
      ),
    );
  }
}

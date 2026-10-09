import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';

/// Privacy settings (F12) and on-device engine information.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text(
          'This deletes every scan, inspection, reminder and kept recording '
          'on this phone. Your registered items, places and lots stay. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: KernelColors.danger,
              foregroundColor: KernelColors.onForest,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete history'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting = true);
    try {
      await ref.read(privacyServiceProvider).deleteAllHistory();
      messenger.showSnackBar(
        const SnackBar(content: Text('All history deleted')),
      );
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete history: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final retain = ref.watch(retainAudioOptInProvider);
    final info = ref.watch(engineInfoProvider);
    return Scaffold(
      appBar: const KernelAppBar(title: 'Settings'),
      body: PageList(
        children: [
          const ScreenHeader(
            title: 'Settings',
            subtitle: 'Privacy and on-device information',
          ),
          Card(
            color: Colors.white,
            child: SwitchListTile(
              key: const Key('retain-audio'),
              value: retain.value ?? false,
              onChanged: retain.hasValue
                  ? (v) => ref
                        .read(settingsRepositoryProvider)
                        .setRetainAudioOptIn(v)
                  : null,
              title: const Text('Keep recordings on this phone'),
              subtitle: const Text(
                'Off by default: each 2-second recording is deleted right '
                'after it is checked. When on, recordings are kept privately '
                'inside the app so they can be checked again. They are never '
                'uploaded. "Delete all history" removes them.',
              ),
            ),
          ),
          KernelCard(
            tone: KernelCardTone.ivory,
            icon: Icons.delete_forever_outlined,
            title: 'Delete all history',
            subtitle:
                'Removes scans, inspections, reminders and kept recordings.',
            child: FilledButton.icon(
              key: const Key('delete-history'),
              style: FilledButton.styleFrom(
                backgroundColor: KernelColors.danger,
                foregroundColor: KernelColors.onForest,
              ),
              onPressed: _deleting ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete all history'),
            ),
          ),
          const SectionTitle('On-device scanning'),
          AsyncView<EngineInfo>(
            value: info,
            errorPrefix: 'Scan engine information is unavailable',
            data: (info) => KernelCard(
              icon: Icons.memory,
              title: provenanceLine(
                modelVersion: info.modelVersion,
                experimental: info.experimental,
              ),
              subtitle: info.modelPresent
                  ? 'Results are experimental and not verified.'
                  : 'No model is installed, so scans check recording '
                        'quality only and results show "Not evaluated".',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldRow(
                    label: 'Target sample rate',
                    value: '${info.targetSampleRate} Hz',
                  ),
                  FieldRow(
                    label: 'Device sample rate',
                    value: info.effectiveSampleRate == null
                        ? 'Not measured yet'
                        : '${info.effectiveSampleRate} Hz',
                  ),
                  FieldRow(label: 'Processor', value: info.delegate.name),
                  FieldRow(
                    label: 'Device',
                    value: '${info.deviceModel} (${info.osVersion})',
                  ),
                ],
              ),
            ),
          ),
          const Text(
            'All scanning runs on this phone. Kernel works without a '
            'network connection and never uploads audio.',
          ),
        ],
      ),
    );
  }
}

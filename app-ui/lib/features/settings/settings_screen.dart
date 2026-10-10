import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import 'advice_settings.dart';
import 'language_picker.dart';
import 'pest_id_settings.dart';
import 'settings_sections.dart';

/// Language, scan feedback, privacy (F12), research mode and on-device
/// engine information.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_rounded,
          color: KernelColors.danger,
        ),
        title: Text(l.deleteHistoryConfirmTitle),
        content: Text(l.deleteHistoryConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: KernelColors.danger,
              foregroundColor: KernelColors.onForest,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.deleteHistoryConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting = true);
    try {
      await ref.read(privacyServiceProvider).deleteAllHistory();
      messenger.showSnackBar(SnackBar(content: Text(l.deleteHistoryDone)));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.deleteHistoryFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final research = ref.watch(researchModeProvider).value ?? false;
    return Scaffold(
      appBar: KernelAppBar(title: l.menuSettings),
      body: PageList(
        children: [
          ScreenHeader(title: l.menuSettings, subtitle: l.settingsSubtitle),
          const SettingsGroup(children: [LanguageTile()]),
          SectionTitle(l.settingsScanning),
          const ScanTogglesGroup(),
          SectionTitle(l.settingsResearchSection),
          const ResearchToggle(),
          if (research)
            KernelCard(
              key: const Key('open-samples'),
              tone: KernelCardTone.ivory,
              icon: Icons.folder_zip_rounded,
              title: l.samplesTitle,
              subtitle: l.settingsSamplesCard,
              onTap: () => context.push(Routes.researchSamples),
            ),
          SectionTitle(l.settingsPrivacy),
          KernelCard(
            tone: KernelCardTone.ivory,
            icon: Icons.delete_forever_rounded,
            title: l.deleteHistoryTitle,
            subtitle: l.deleteHistoryBody,
            child: FilledButton.icon(
              key: const Key('delete-history'),
              style: FilledButton.styleFrom(
                backgroundColor: KernelColors.danger,
                foregroundColor: KernelColors.onForest,
              ),
              onPressed: _deleting ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l.deleteHistoryTitle),
            ),
          ),
          SectionTitle(l.settingsAdviceSection),
          const AdviceSettingsSection(),
          SectionTitle(l.settingsOnDevice),
          const EngineCard(),
          KernelCard(
            key: const Key('open-diagnostics'),
            tone: KernelCardTone.ivory,
            icon: Icons.developer_board_rounded,
            title: l.diagnosticsTitle,
            subtitle: l.diagnosticsCard,
            onTap: () => context.push(Routes.diagnostics),
          ),
          SectionTitle(l.hubSettingsSection),
          const PestIdSettingsSection(),
          QuietNote(l.settingsFooter, icon: Icons.phonelink_lock_rounded),
        ],
      ),
    );
  }
}

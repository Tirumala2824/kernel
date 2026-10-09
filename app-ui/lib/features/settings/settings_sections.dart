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

/// Paper group box for settings rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KernelColors.paper,
        borderRadius: BorderRadius.circular(KernelRadii.lg),
        border: Border.all(color: KernelColors.hairline),
        boxShadow: KernelShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(indent: 16, endIndent: 16),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Haptics, voice prompts and keep-recordings toggles.
class ScanTogglesGroup extends ConsumerWidget {
  const ScanTogglesGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final haptics = ref.watch(hapticsProvider);
    final voice = ref.watch(voicePromptsProvider);
    final retain = ref.watch(retainAudioOptInProvider);
    return SettingsGroup(
      children: [
        SwitchListTile(
          key: const Key('haptics-toggle'),
          secondary: const Icon(Icons.vibration_rounded),
          value: haptics.value ?? true,
          onChanged: haptics.hasValue ? settings.setHaptics : null,
          title: Text(l.settingsHaptics),
          subtitle: Text(l.settingsHapticsBody),
        ),
        SwitchListTile(
          key: const Key('voice-toggle'),
          secondary: const Icon(Icons.record_voice_over_rounded),
          value: voice.value ?? false,
          onChanged: voice.hasValue ? settings.setVoicePrompts : null,
          title: Text(l.settingsVoice),
          subtitle: Text(l.settingsVoiceBody),
        ),
        SwitchListTile(
          key: const Key('retain-audio'),
          secondary: const Icon(Icons.lock_rounded),
          value: retain.value ?? false,
          onChanged: retain.hasValue ? settings.setRetainAudioOptIn : null,
          title: Text(l.settingsRetain),
          subtitle: Text(l.settingsRetainBody),
        ),
      ],
    );
  }
}

/// Research recording mode: a separate, explicit opt-in with consent.
class ResearchToggle extends ConsumerWidget {
  const ResearchToggle({super.key});

  Future<void> _change(BuildContext context, WidgetRef ref, bool on) async {
    final l = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    if (!on) {
      await settings.setResearchModeOptIn(false);
      return;
    }
    final agreed = await confirmAction(
      context,
      icon: Icons.science_rounded,
      title: l.researchConsentTitle,
      body: l.researchConsentBody,
      confirmLabel: l.researchConsentAgree,
    );
    if (agreed) await settings.setResearchModeOptIn(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final research = ref.watch(researchModeProvider);
    return SettingsGroup(
      children: [
        SwitchListTile(
          key: const Key('research-toggle'),
          secondary: const Icon(Icons.science_rounded),
          value: research.value ?? false,
          onChanged: research.hasValue ? (v) => _change(context, ref, v) : null,
          title: Text(l.settingsResearch),
          subtitle: Text(l.settingsResearchBody),
        ),
      ],
    );
  }
}

/// Model provenance and the model's own note.
class EngineCard extends ConsumerWidget {
  const EngineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final info = ref.watch(engineInfoProvider);
    return AsyncView<EngineInfo>(
      value: info,
      errorPrefix: l.engineUnavailable,
      data: (info) {
        final note = info.modelNote?.trim();
        return KernelCard(
          key: const Key('engine-card'),
          icon: Icons.memory_rounded,
          title: provenanceLine(
            l,
            modelVersion: info.modelVersion,
            experimental: info.experimental,
          ),
          subtitle: info.modelPresent
              ? l.engineModelPresent
              : l.engineNoModel,
          child: note == null || note.isEmpty
              ? null
              : Text(note, key: const Key('settings-model-note')),
        );
      },
    );
  }
}

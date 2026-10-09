import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';

/// Value used in the picker for "follow the phone's language".
const _deviceLanguage = '';

/// Display name for a language tag (native name when known).
String languageName(AppLocalizations l, String? tag) => tag == null
    ? l.languageFollowDevice
    : nativeLanguageNames[tag] ?? tag;

/// Settings row that opens the language picker.
class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tag = ref.watch(languageTagProvider).value;
    return ListTile(
      key: const Key('language-tile'),
      leading: const Icon(Icons.translate_rounded),
      title: Text(l.languageTitle),
      subtitle: Text(languageName(l, tag)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const LanguagePickerSheet(),
      ),
    );
  }
}

/// Lists only the locales the app ships (AppLocalizations.supportedLocales)
/// plus "follow the phone".
class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final current = ref.watch(languageTagProvider).value ?? _deviceLanguage;
    final tags = [
      for (final locale in AppLocalizations.supportedLocales)
        locale.languageCode,
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          KernelSpace.page,
          0,
          KernelSpace.page,
          KernelSpace.xl,
        ),
        child: RadioGroup<String>(
          groupValue: current,
          onChanged: (value) async {
            if (value == null) return;
            final navigator = Navigator.of(context);
            await ref
                .read(settingsRepositoryProvider)
                .setLanguageTag(value == _deviceLanguage ? null : value);
            navigator.pop();
          },
          child: Column(
            key: const Key('language-sheet'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.languageTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: KernelColors.forest,
                ),
              ),
              const SizedBox(height: KernelSpace.xs),
              Text(l.languageSheetBody),
              const SizedBox(height: KernelSpace.md),
              RadioListTile<String>(
                key: const Key('language-device'),
                value: _deviceLanguage,
                title: Text(l.languageFollowDevice),
              ),
              for (final tag in tags)
                RadioListTile<String>(
                  key: Key('language-$tag'),
                  value: tag,
                  title: Text(nativeLanguageNames[tag] ?? tag),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

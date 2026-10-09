import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../theme/kernel_theme.dart';
import 'data_providers.dart';
import 'router.dart';

class KernelApp extends ConsumerWidget {
  const KernelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Null (or still loading) follows the phone's language.
    final tag = ref.watch(languageTagProvider).value;
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildKernelTheme(),
      locale: tag == null ? null : Locale(tag),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../theme/kernel_theme.dart';
import 'data_providers.dart';
import 'providers.dart';
import 'router.dart';
import 'routes.dart';

class KernelApp extends ConsumerStatefulWidget {
  const KernelApp({super.key});
  @override
  ConsumerState<KernelApp> createState() => _KernelAppState();
}

class _KernelAppState extends ConsumerState<KernelApp> {
  bool _launchChecked = false;

  Future<void> _openLaunchItem() async {
    if (!mounted) return;
    try {
      final itemId = await ref
          .read(reminderRepositoryProvider)
          .takeLaunchItemId();
      if (!mounted || itemId == null) return;
      ref.read(routerProvider).push(Routes.item(itemId));
    } on Object {
      // No sensitive exception details are surfaced in chat. A failed
      // notification handoff does not prevent an ordinary chat launch.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag = ref.watch(languageTagProvider).value;
    final role = ref.watch(activeRoleProvider);
    final onboarding = ref.watch(onboardingDoneProvider);
    // Do not consume a notification until its operational route is ready.
    // A first-run chat must not be replaced by onboarding unexpectedly.
    if (!_launchChecked &&
        role.hasValue &&
        role.value != null &&
        onboarding.hasValue &&
        onboarding.value == true) {
      _launchChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openLaunchItem());
    }
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

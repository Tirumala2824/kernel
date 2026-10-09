import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/data_providers.dart';
import '../../brand/kernel_brand.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';

/// Shown only while local settings are being read (it continues the native
/// splash: ivory with the centred mark), or when the app has not been wired
/// to its data layer.
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final role = ref.watch(activeRoleProvider);
    final onboarding = ref.watch(onboardingDoneProvider);
    final error = role.error ?? onboarding.error;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KernelSpace.xxl),
            child: error != null
                ? ErrorNote(l.startDataError('$error'))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KernelMark(size: 96, label: l.appTitle),
                      const SizedBox(height: KernelSpace.xl),
                      const SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/data_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';

/// Shown only while the active role is being read from local settings, or
/// when the app has not been wired to its data layer.
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(KernelSizes.pagePadding * 2),
            child: role.hasError
                ? ErrorNote(
                    'Kernel could not open its local data on this phone. '
                    'Please restart the app.\n\nDetails: ${role.error}',
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kernel',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: KernelColors.forest),
                      ),
                      const SizedBox(height: KernelSizes.gap),
                      const CircularProgressIndicator(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

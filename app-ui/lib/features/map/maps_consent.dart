import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';

/// Explains what Google receives before any map tile or route request
/// (guardrails §7). Stores the consent only when the user allows it.
Future<bool> showMapsConsentSheet(BuildContext context, WidgetRef ref) async {
  final allowed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final l = sheetContext.l10n;
      final textTheme = Theme.of(sheetContext).textTheme;
      return SafeArea(
        child: SingleChildScrollView(
          key: const Key('maps-consent-sheet'),
          padding: const EdgeInsets.fromLTRB(
            KernelSpace.page,
            0,
            KernelSpace.page,
            KernelSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.mapConsentTitle,
                style: textTheme.titleLarge?.copyWith(
                  color: KernelColors.forest,
                ),
              ),
              const SizedBox(height: KernelSpace.sm),
              Text(l.mapConsentBody, style: textTheme.bodyLarge),
              const SizedBox(height: KernelSpace.sm),
              Text(l.mapConsentNever, style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: KernelSpace.lg),
              FilledButton(
                key: const Key('maps-consent-allow'),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Text(l.mapConsentAllow),
              ),
              const SizedBox(height: KernelSpace.sm),
              TextButton(
                key: const Key('maps-consent-decline'),
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(l.mapConsentDecline),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (allowed != true) return false;
  await ref.read(settingsRepositoryProvider).setMapsConsent(true);
  return true;
}

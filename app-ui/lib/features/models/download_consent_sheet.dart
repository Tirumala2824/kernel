import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_card.dart';
import 'hub_copy.dart';
import 'hub_providers.dart';

/// One-time download consent (guardrails §7). Lists every file with its
/// size, licence, model card and source, a Wi-Fi only switch (on by
/// default) and the total. Resolves to the consent to store, or null when
/// the user declines; nothing is downloaded from here.
Future<DownloadConsent?> showDownloadConsentSheet(
  BuildContext context, {
  required List<CatalogEntry> entries,
  bool initialWifiOnly = true,
}) => showModalBottomSheet<DownloadConsent>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) =>
      _ConsentSheet(entries: entries, initialWifiOnly: initialWifiOnly),
);

class _ConsentSheet extends StatefulWidget {
  const _ConsentSheet({required this.entries, required this.initialWifiOnly});

  final List<CatalogEntry> entries;
  final bool initialWifiOnly;

  @override
  State<_ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends State<_ConsentSheet> {
  late bool _wifiOnly = widget.initialWifiOnly;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        key: const Key('hub-consent-sheet'),
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          KernelSpace.page,
          0,
          KernelSpace.page,
          KernelSpace.xxl,
        ),
        children: [
          ScreenHeader(title: l.hubConsentTitle, subtitle: l.hubConsentBody),
          const SizedBox(height: KernelSpace.md),
          for (final entry in widget.entries) ...[
            KernelCard(
              key: Key('hub-consent-entry-${entry.id}'),
              tone: KernelCardTone.ivory,
              icon: Icons.download_rounded,
              title: entry.name,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.hubConsentSize(formatBytes(l, entry.sizeBytes))),
                  Text(l.hubConsentLicense(entry.license)),
                  SelectableText(
                    l.hubConsentModelCard(modelCardUrl(entry)),
                    style: textTheme.bodyMedium?.copyWith(
                      color: KernelColors.forest,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(modelSourceLine(l, entry)),
                ],
              ),
            ),
            const SizedBox(height: KernelSpace.sm),
          ],
          SwitchListTile(
            key: const Key('hub-consent-wifi'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.wifi_rounded),
            value: _wifiOnly,
            onChanged: (v) => setState(() => _wifiOnly = v),
            title: Text(l.hubWifiOnly),
            subtitle: Text(l.hubWifiOnlyBody),
          ),
          const SizedBox(height: KernelSpace.sm),
          Text(
            l.hubConsentTotal(formatBytes(l, totalBytes(widget.entries))),
            key: const Key('hub-consent-total'),
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: KernelSpace.md),
          QuietNote(l.hubGalleryNote, icon: Icons.folder_off_rounded),
          const SizedBox(height: KernelSpace.lg),
          ActionWrap(
            children: [
              FilledButton.icon(
                key: const Key('hub-consent-agree'),
                onPressed: () => Navigator.of(
                  context,
                ).pop(DownloadConsent(granted: true, wifiOnly: _wifiOnly)),
                icon: const Icon(Icons.download_rounded),
                label: Text(l.hubConsentAgree),
              ),
              OutlinedButton(
                key: const Key('hub-consent-decline'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.hubConsentNotNow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/record_tiles.dart';

/// Scans recorded since local midnight for the active role
/// (ScanRepository.watchSince), newest first.
class ScansTodayScreen extends ConsumerWidget {
  const ScansTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final role = ref.watch(activeRoleProvider).value;
    final since = startOfToday();
    final scans = ref.watch(scansSinceProvider((since: since, role: role)));
    final items = role == null
        ? const <GrainItem>[]
        : ref.watch(itemsByRoleProvider(role)).value ?? const <GrainItem>[];
    final labels = {for (final item in items) item.id: item.label};
    return Scaffold(
      appBar: KernelAppBar(title: l.scansTodayTitle),
      body: AsyncView<List<ScanRecord>>(
        value: scans,
        data: (scans) => PageList(
          children: [
            ScreenHeader(
              title: l.scansTodayTitle,
              subtitle: l.scansTodaySummary(
                scans.length,
                scans.map((s) => s.itemId).toSet().length,
              ),
            ),
            if (scans.isEmpty)
              QuietNote(l.scansTodayEmpty, icon: Icons.today_rounded)
            else
              for (final scan in scans)
                ScanRecordTile(
                  scan: scan,
                  itemLabel: labels[scan.itemId] ?? l.archivedBadge,
                  onTap: () =>
                      context.push(Routes.result(scan.itemId, scan.id)),
                ),
          ],
        ),
      ),
    );
  }
}

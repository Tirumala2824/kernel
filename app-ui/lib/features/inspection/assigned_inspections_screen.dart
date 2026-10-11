import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../brand/illustrations.dart';
import '../../brand/kernel_brand.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/record_tiles.dart';
import '../inventory/item_sections.dart';

/// Filter value for "no assignee".
const _unassigned = '\u0000unassigned';

/// Open and in-progress inspections (oldest first) for the active role's
/// items, filterable by assignee, with follow-up status updates.
class AssignedInspectionsScreen extends ConsumerStatefulWidget {
  const AssignedInspectionsScreen({super.key});

  @override
  ConsumerState<AssignedInspectionsScreen> createState() =>
      _AssignedInspectionsScreenState();
}

class _AssignedInspectionsScreenState
    extends ConsumerState<AssignedInspectionsScreen> {
  /// Null shows everything.
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final roleValue = ref.watch(activeRoleProvider);
    final role = roleValue.value;
    final itemData = role == null
        ? const AsyncLoading<List<GrainItem>>()
        : ref.watch(itemsByRoleProvider(role));
    final open = ref.watch(openInspectionsProvider);
    // Missing or stale dependencies are not an empty inspection queue.
    final failed = roleValue.hasError || itemData.hasError || open.hasError;
    final loading = roleValue.isLoading || itemData.isLoading || open.isLoading;
    if (failed || loading || role == null) {
      return Scaffold(
        appBar: KernelAppBar(title: l.assignedTitle),
        body: failed
            ? ErrorNote(l.errorCouldNotLoad)
            : roleValue.hasValue && role == null
                ? QuietNote(l.menuSwitchRole)
                : const Center(child: CircularProgressIndicator()),
      );
    }
    final items = itemData.requireValue;
    final labels = {for (final item in items) item.id: item.label};

    return Scaffold(
      appBar: KernelAppBar(title: l.assignedTitle),
      body: AsyncView<List<Inspection>>(
        value: open,
        data: (open) {
          final mine = open.where((i) => labels.containsKey(i.itemId)).toList();
          final names =
              {
                for (final i in mine)
                  if (i.assignedTo case final a? when a.isNotEmpty) a,
              }.toList()
                ..sort();
          final shown = mine.where((i) {
            final a = i.assignedTo;
            return switch (_filter) {
              null => true,
              _unassigned => a == null || a.isEmpty,
              final name => a == name,
            };
          }).toList();
          return PageList(
            children: [
              ScreenHeader(
                title: l.assignedTitle,
                subtitle: l.inspectionsOpen(mine.length),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('filter-all'),
                    label: Text(l.filterAll),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  ChoiceChip(
                    key: const Key('filter-unassigned'),
                    label: Text(l.unassigned),
                    selected: _filter == _unassigned,
                    onSelected: (_) => setState(() => _filter = _unassigned),
                  ),
                  for (final name in names)
                    ChoiceChip(
                      key: Key('filter-$name'),
                      label: Text(name),
                      selected: _filter == name,
                      onSelected: (_) => setState(() => _filter = name),
                    ),
                ],
              ),
              if (shown.isEmpty) ...[
                Center(
                  child: KernelIllustration(
                    KernelIllustrations.inspection,
                    height: 100,
                  ),
                ),
                QuietNote(mine.isEmpty ? l.assignedNone : l.filterNoMatch),
              ] else
                for (final inspection in shown)
                  InspectionTile(
                    key: Key('task-${inspection.id}'),
                    inspection: inspection,
                    itemLabel: labels[inspection.itemId],
                    onOpenItem: () =>
                        context.push(Routes.item(inspection.itemId)),
                    onFollowUpChanged: (status) => ref
                        .read(inspectionRepositoryProvider)
                        .updateFollowUp(inspection.id, status),
                    onAssign: () => assignInspection(
                      context,
                      ref,
                      inspection,
                      suggestions: names,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

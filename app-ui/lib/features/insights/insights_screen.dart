import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/data_providers.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import 'insights_sections.dart';

/// Period the insight figures cover.
enum InsightsWindow {
  days7(Duration(days: 7)),
  days30(Duration(days: 30)),
  all(null);

  const InsightsWindow(this.duration);

  final Duration? duration;

  String label(AppLocalizations l) => switch (this) {
    InsightsWindow.days7 => l.insightsWindow7,
    InsightsWindow.days30 => l.insightsWindow30,
    InsightsWindow.all => l.insightsWindowAll,
  };
}

/// Local analytics for the active role, computed on this phone by
/// AnalyticsService from stored records only.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightsWindow _window = InsightsWindow.days30;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = ref.watch(activeRoleProvider).value;
    return Scaffold(
      appBar: KernelAppBar(title: l.insightsTitle),
      body: role == null
          ? const SizedBox.shrink()
          : PageList(
              children: [
                ScreenHeader(
                  title: l.insightsTitle,
                  subtitle: l.insightsSubtitle,
                ),
                Semantics(
                  label: l.insightsWindowLabel,
                  child: Wrap(
                    key: const Key('insights-window'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final window in InsightsWindow.values)
                        ChoiceChip(
                          key: Key('window-${window.name}'),
                          label: Text(window.label(l)),
                          selected: _window == window,
                          onSelected: (_) => setState(() => _window = window),
                        ),
                    ],
                  ),
                ),
                ActivitySection(scope: roleScope(role)),
                ResultRatesSection(
                  scope: roleScope(role, window: _window.duration),
                ),
                QualityFailuresSection(
                  scope: roleScope(role, window: _window.duration),
                ),
                InspectionStatsSection(
                  scope: roleScope(role, window: _window.duration),
                ),
                StaleItemsSection(role: role),
              ],
            ),
    );
  }
}

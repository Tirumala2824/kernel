import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';

/// The four role cards. Used by role selection and the last onboarding
/// page.
class RolePicker extends StatelessWidget {
  const RolePicker({
    super.key,
    required this.current,
    required this.onSelect,
    this.enabled = true,
  });

  final Role? current;
  final ValueChanged<Role> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final role in Role.values)
          Padding(
            padding: const EdgeInsets.only(bottom: KernelSpace.md),
            child: KernelCard(
              key: Key('role-${role.name}'),
              title: role.title(l),
              subtitle: role.tagline(l),
              icon: role.icon,
              tone: role == current ? KernelCardTone.hero : KernelCardTone.ivory,
              trailing: role == current
                  ? StatusChip(label: l.roleCurrent, tone: StatusTone.positive)
                  : null,
              onTap: enabled ? () => onSelect(role) : null,
            ),
          ),
      ],
    );
  }
}

/// F01: pick one of four workflows. Switching only changes the active role;
/// records from every role stay on the phone.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key, this.switching = false});

  /// True when opened from the Switch role menu (a role is already set).
  final bool switching;

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _saving = false;
  String? _error;

  Future<void> _select(Role role) async {
    final l = context.l10n;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(settingsRepositoryProvider).setActiveRole(role);
      if (!mounted) return;
      context.go(Routes.home);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _error = l.roleSaveFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = ref.watch(activeRoleProvider).value;
    return Scaffold(
      appBar: KernelAppBar(title: widget.switching ? l.menuSwitchRole : null),
      body: PageList(
        children: [
          ScreenHeader(title: l.roleSelectTitle, subtitle: l.roleSelectSubtitle),
          if (widget.switching) QuietNote(l.roleSwitchKeepsRecords),
          RolePicker(
            current: current,
            enabled: !_saving,
            onSelect: _select,
          ),
          if (_error != null) ErrorNote(_error!),
        ],
      ),
    );
  }
}

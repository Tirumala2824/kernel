import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';

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
      setState(() => _error = 'Could not save your role: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(activeRoleProvider).value;
    return Scaffold(
      appBar: KernelAppBar(title: widget.switching ? 'Switch role' : 'Kernel'),
      body: PageList(
        children: [
          const ScreenHeader(
            title: 'Select your role',
            subtitle: 'One app. Four workflows.',
          ),
          if (widget.switching)
            const Text(
              'Switching role keeps every record on this phone. You can '
              'switch back at any time.',
            ),
          for (final role in Role.values)
            KernelCard(
              key: Key('role-${role.name}'),
              title: role.title,
              subtitle: role.tagline,
              icon: role.icon,
              tone: role == current ? KernelCardTone.hero : KernelCardTone.sage,
              trailing: role == current
                  ? const StatusChip(
                      label: 'Current',
                      tone: StatusTone.positive,
                    )
                  : null,
              onTap: _saving ? null : () => _select(role),
            ),
          if (_error != null) ErrorNote(_error!),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/form_fields.dart';

/// Opens the reminder sheet for [itemId]. Asks for POST_NOTIFICATIONS, then
/// schedules an on-device reminder via ReminderRepository.schedule.
Future<void> showReminderSheet(
  BuildContext context, {
  required String itemId,
  required String itemLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ReminderSheet(itemId: itemId, itemLabel: itemLabel),
  );
}

class ReminderSheet extends ConsumerStatefulWidget {
  const ReminderSheet({
    super.key,
    required this.itemId,
    required this.itemLabel,
  });

  final String itemId;
  final String itemLabel;

  @override
  ConsumerState<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<ReminderSheet> {
  late DateTime _date = DateUtils.dateOnly(
    DateTime.now().add(const Duration(days: 7)),
  );
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false;
  String? _error;

  DateTime get _dueAt =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _save() async {
    final l = context.l10n;
    if (!_dueAt.isAfter(DateTime.now())) {
      setState(() => _error = l.reminderPastError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final access = await ref
        .read(devicePermissionsProvider)
        .requestNotifications();
    try {
      await ref.read(reminderRepositoryProvider).schedule(widget.itemId, _dueAt);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            access == PermissionAccess.granted
                ? l.reminderSet
                : l.reminderSetNotificationsOff,
          ),
        ),
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l.reminderFailed('$e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final today = DateUtils.dateOnly(DateTime.now());
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          KernelSpace.page,
          0,
          KernelSpace.page,
          KernelSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          key: const Key('reminder-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.reminderSheetTitle,
              style: textTheme.headlineSmall?.copyWith(
                color: KernelColors.forest,
              ),
            ),
            const SizedBox(height: KernelSpace.xs),
            Text(l.reminderSheetSubtitle(widget.itemLabel)),
            const SizedBox(height: KernelSpace.lg),
            Wrap(
              spacing: KernelSpace.sm,
              runSpacing: KernelSpace.sm,
              children: [
                for (final days in const [7, 14, 30])
                  ChoiceChip(
                    key: Key('reminder-preset-$days'),
                    label: Text(l.reminderInDays(days)),
                    selected: _date == today.add(Duration(days: days)),
                    onSelected: (_) => setState(
                      () => _date = today.add(Duration(days: days)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KernelSpace.lg),
            DateField(
              key: const Key('reminder-date'),
              label: l.reminderDateLabel,
              value: _date,
              firstDate: today,
              lastDate: today.add(const Duration(days: 366)),
              onChanged: (d) => setState(() => _date = DateUtils.dateOnly(d)),
            ),
            const SizedBox(height: KernelSpace.md),
            TimeField(
              key: const Key('reminder-time'),
              label: l.reminderTimeLabel,
              value: _time,
              onChanged: (t) => setState(() => _time = t),
            ),
            const SizedBox(height: KernelSpace.md),
            Text(
              l.reminderOnDeviceNote,
              style: textTheme.bodySmall?.copyWith(
                color: KernelColors.inkMuted,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: KernelSpace.md),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: KernelSpace.lg),
            FilledButton.icon(
              key: const Key('reminder-save'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.alarm_add_rounded),
              label: Text(l.reminderSave),
            ),
          ],
        ),
      ),
    );
  }
}

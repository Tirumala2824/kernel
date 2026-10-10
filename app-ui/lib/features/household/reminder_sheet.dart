import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/form_fields.dart';
import '../advice/advice_card.dart';

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

  /// Rule-based suggestion from ReminderRepository.suggestDueAt. Only a
  /// prefill: the user confirms or changes the date and time.
  DateTime? _suggested;

  /// True once the user changed the date or time themselves.
  bool _touched = false;
  bool _adviceRequested = false;

  /// Input for the optional on-phone wording, once the suggestion is known.
  ReminderAdviceInput? _adviceInput;
  String? _languageTag;

  DateTime get _dueAt =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  @override
  void initState() {
    super.initState();
    _loadSuggestion();
  }

  Future<void> _loadSuggestion() async {
    final DateTime suggested;
    try {
      suggested =
          (await ref
                  .read(reminderRepositoryProvider)
                  .suggestDueAt(widget.itemId))
              .toLocal();
    } on Object {
      return; // Keep the plain default; the user picks a date anyway.
    }
    if (!mounted) return;
    setState(() {
      _suggested = suggested;
      // Never overwrite a date the user already picked.
      if (_touched) return;
      _date = DateUtils.dateOnly(suggested);
      if (DateUtils.isSameDay(suggested, DateTime.now())) {
        _time = TimeOfDay.fromDateTime(suggested);
      }
    });
  }

  /// Starts the optional wording once, when both the suggestion and a
  /// ready assistant are known.
  void _maybeRequestAdvice(bool adviceReady) {
    final suggested = _suggested;
    if (!adviceReady || suggested == null || _adviceRequested) return;
    _adviceRequested = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _prepareAdvice(suggested),
    );
  }

  Future<void> _prepareAdvice(DateTime suggested) async {
    try {
      final item = await ref.read(itemRepositoryProvider).get(widget.itemId);
      if (item == null) return;
      final last = await ref
          .read(scanRepositoryProvider)
          .latestValidForItem(widget.itemId);
      if (!mounted) return;
      setState(() {
        _languageTag = adviceLanguageTag(context);
        _adviceInput = ReminderAdviceInput(
          role: item.ownerRole,
          grainType: item.grainType,
          storageDays: daysSince(item.storageDate),
          lastResult: last?.result,
          suggestedDueAt: suggested,
        );
      });
    } on Object {
      // Optional wording only; the sheet works without it.
    }
  }

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
      await ref
          .read(reminderRepositoryProvider)
          .schedule(widget.itemId, _dueAt);
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
    _maybeRequestAdvice(ref.watch(adviceReadyProvider));
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
                    onSelected: (_) => setState(() {
                      _touched = true;
                      _date = today.add(Duration(days: days));
                    }),
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
              onChanged: (d) => setState(() {
                _touched = true;
                _date = DateUtils.dateOnly(d);
              }),
            ),
            if (_suggested case final suggested?) ...[
              const SizedBox(height: KernelSpace.xs),
              Row(
                key: const Key('reminder-suggested'),
                children: [
                  Icon(
                    DateUtils.isSameDay(suggested, _date)
                        ? Icons.lightbulb_outline_rounded
                        : Icons.edit_calendar_rounded,
                    size: 18,
                    color: KernelColors.forest,
                  ),
                  const SizedBox(width: KernelSpace.xs),
                  Expanded(
                    child: Text(
                      DateUtils.isSameDay(suggested, _date)
                          ? l.reminderSuggestedLabel
                          : l.reminderSuggestedOther(
                              formatDate(context, suggested),
                            ),
                      style: textTheme.bodyMedium?.copyWith(
                        color: KernelColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: KernelSpace.md),
            TimeField(
              key: const Key('reminder-time'),
              label: l.reminderTimeLabel,
              value: _time,
              onChanged: (t) => setState(() {
                _touched = true;
                _time = t;
              }),
            ),
            if (_adviceInput case final input?) ...[
              const SizedBox(height: KernelSpace.md),
              AdviceStreamCard(
                key: const Key('reminder-wording'),
                title: l.reminderWordingTitle,
                request: () => ref
                    .read(adviceEngineProvider)
                    .suggestReminderText(input, languageTag: _languageTag),
              ),
            ],
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

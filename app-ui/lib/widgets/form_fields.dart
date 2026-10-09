import 'package:flutter/material.dart';

import '../app/copy.dart';
import '../l10n/l10n.dart';
import '../theme/tokens.dart';

/// Quantity units offered in registration forms (unit symbols, not
/// translated).
const quantityUnits = ['kg', 'quintal', 'tonne', 'bags'];

/// Returns [message] when [value] is blank.
String? requiredText(String? value, String message) =>
    (value == null || value.trim().isEmpty) ? message : null;

/// Parses a positive quantity, accepting a decimal comma.
double? parseQuantity(String? value) {
  if (value == null) return null;
  final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
  if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed <= 0) {
    return null;
  }
  return parsed;
}

String? validateQuantity(AppLocalizations l, String? value) {
  if (value == null || value.trim().isEmpty) return l.validationQuantityEmpty;
  return parseQuantity(value) == null ? l.validationQuantityPositive : null;
}

/// Date picker field with a >=48dp target. Past dates only unless
/// [lastDate] says otherwise.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(KernelRadii.md),
      onTap: () async {
        final now = DateTime.now();
        final last = lastDate ?? now;
        final first = firstDate ?? DateTime(now.year - 10);
        var initial = value;
        if (initial.isAfter(last)) initial = last;
        if (initial.isBefore(first)) initial = first;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: first,
          lastDate: last,
          helpText: label,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(formatDate(context, value)),
      ),
    );
  }
}

/// Time picker field.
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(KernelRadii.md),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
          helpText: label,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule_rounded),
        ),
        child: Text(MaterialLocalizations.of(context).formatTimeOfDay(value)),
      ),
    );
  }
}

/// Scrollable form body with a primary save button at the end.
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.formKey,
    required this.children,
    required this.saveLabel,
    required this.onSave,
    this.saving = false,
    this.error,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final String saveLabel;
  final VoidCallback? onSave;
  final bool saving;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            KernelSpace.page,
            KernelSpace.sm,
            KernelSpace.page,
            KernelSpace.xxl,
          ),
          children: [
            for (final child in children) ...[
              child,
              const SizedBox(height: KernelSpace.lg),
            ],
            if (error != null) ...[
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: KernelSpace.lg),
            ],
            FilledButton.icon(
              key: const Key('save'),
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(saveLabel),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/rules.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/record_tiles.dart';
import '../../widgets/status_chip.dart';
import 'label_options.dart';

/// Labels a research recording. Clean and infested need an inspection of
/// this item whose verified finding agrees; otherwise only Unknown can be
/// chosen. Saved via LabeledSampleRepository.create.
class SampleLabelScreen extends ConsumerWidget {
  const SampleLabelScreen({
    super.key,
    required this.itemId,
    required this.scanId,
  });

  final String itemId;
  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scan = ref.watch(scanProvider(scanId));
    return Scaffold(
      appBar: KernelAppBar(title: l.labelSampleTitle),
      body: AsyncView<ScanRecord?>(
        value: scan,
        data: (scan) {
          if (scan == null) return NotFoundNote(l.scanNotFound);
          if (!recordingUsableForResearch(scan)) {
            return PageList(
              children: [
                ScreenHeader(title: l.labelSampleTitle),
                ScanRecordTile(scan: scan),
                NoticeBanner(
                  key: const Key('sample-unusable'),
                  text: scan.quality == ScanQuality.retry
                      ? l.sampleUnusableRetry
                      : l.sampleUnusableNotKept,
                  tone: StatusTone.attention,
                  icon: Icons.mic_off_rounded,
                ),
                FilledButton.icon(
                  key: const Key('sample-record-again'),
                  onPressed: () =>
                      context.pushReplacement(Routes.researchScan(itemId)),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l.sampleRecordAgain),
                ),
              ],
            );
          }
          return _LabelForm(itemId: itemId, scan: scan);
        },
      ),
    );
  }
}

class _LabelForm extends ConsumerStatefulWidget {
  const _LabelForm({required this.itemId, required this.scan});

  final String itemId;
  final ScanRecord scan;

  @override
  ConsumerState<_LabelForm> createState() => _LabelFormState();
}

class _LabelFormState extends ConsumerState<_LabelForm> {
  final _formKey = GlobalKey<FormState>();
  final _grain = TextEditingController();
  final _environment = TextEditingController();
  final _notes = TextEditingController();
  SampleLabel _label = SampleLabel.unknown;
  String? _inspectionId;
  String? _material;
  bool _grainSet = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _grain.dispose();
    _environment.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _choose(SampleLabel label, List<Inspection> inspections) {
    final agreeing = agreeingInspections(label, inspections);
    setState(() {
      _label = label;
      _inspectionId = agreeing.firstOrNull?.id;
    });
  }

  Future<void> _save(List<Inspection> inspections) async {
    final l = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final evidence = inspections.where((i) => i.id == _inspectionId).firstOrNull;
    if (!sampleLabelSupported(_label, evidence)) {
      setState(() => _error = l.labelNeedsEvidence);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? opt(TextEditingController c) =>
          c.text.trim().isEmpty ? null : c.text.trim();
      await ref
          .read(labeledSampleRepositoryProvider)
          .create(
            LabeledSampleDraft(
              scanId: widget.scan.id,
              label: _label,
              inspectionId: _label == SampleLabel.unknown ? null : evidence?.id,
              grainType: _grain.text.trim(),
              sackMaterial: _material,
              environment: opt(_environment),
              notes: opt(_notes),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.sampleSaved)));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.item(widget.itemId));
      }
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = l.sampleRejected('${e.message}'));
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final item = ref.watch(itemProvider(widget.itemId)).value;
    final inspections =
        ref.watch(inspectionsForItemProvider(widget.itemId)).value ??
        const <Inspection>[];
    if (!_grainSet && item != null) {
      _grainSet = true;
      _grain.text = item.grainType;
    }
    final allowed = allowedSampleLabels(inspections);
    final agreeing = agreeingInspections(_label, inspections);

    return FormPage(
      formKey: _formKey,
      saveLabel: l.sampleSave,
      saving: _saving,
      error: _error,
      onSave: () => _save(inspections),
      children: [
        ScreenHeader(
          title: l.labelSampleTitle,
          subtitle: item == null
              ? null
              : l.grainAndLabel(item.grainType, item.label),
        ),
        ScanRecordTile(scan: widget.scan),
        QuietNote(l.labelRuleNote, icon: Icons.verified_user_rounded),
        for (final label in SampleLabel.values)
          LabelOption(
            label: label,
            selected: _label == label,
            enabled: allowed.contains(label),
            onTap: () => _choose(label, inspections),
          ),
        if (!allowed.contains(SampleLabel.clean) ||
            !allowed.contains(SampleLabel.infested))
          OutlinedButton.icon(
            key: const Key('label-record-inspection'),
            onPressed: () => context.push(
              Routes.inspect(widget.itemId, scanId: widget.scan.id),
            ),
            icon: const Icon(Icons.person_search_rounded),
            label: Text(l.actionRecordInspection),
          ),
        if (_label != SampleLabel.unknown && agreeing.isNotEmpty)
          EvidencePicker(
            inspections: agreeing,
            selectedId: _inspectionId,
            onChanged: (id) => setState(() => _inspectionId = id),
          ),
        TextFormField(
          key: const Key('field-sample-grain'),
          controller: _grain,
          decoration: InputDecoration(labelText: l.grainTypeField),
          validator: (v) => requiredText(v, l.validationGrain),
        ),
        DropdownButtonFormField<String?>(
          key: const Key('field-material'),
          initialValue: _material,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.sackMaterialField),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l.notRecorded)),
            for (final code in sackMaterials)
              DropdownMenuItem<String?>(
                value: code,
                child: Text(sackMaterialLabel(l, code)),
              ),
          ],
          onChanged: (v) => setState(() => _material = v),
        ),
        TextFormField(
          key: const Key('field-environment'),
          controller: _environment,
          decoration: InputDecoration(
            labelText: l.environmentField,
            helperText: l.environmentHelper,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in [
              l.envQuietRoom,
              l.envWarehouse,
              l.envFansOn,
              l.envOutdoors,
            ])
              ActionChip(
                label: Text(preset),
                onPressed: () => setState(() => _environment.text = preset),
              ),
          ],
        ),
        TextFormField(
          key: const Key('field-sample-notes'),
          controller: _notes,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: l.notesFieldOptional),
        ),
      ],
    );
  }
}

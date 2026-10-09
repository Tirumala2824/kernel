import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/kernel_app_bar.dart';
import 'inspection_panels.dart';

/// F09 record a physical inspection. The verified finding is entered by a
/// person and is never pre-filled from, or merged with, the AI prediction.
/// Evidence photos are copied into app-private storage.
class InspectionFormScreen extends ConsumerStatefulWidget {
  const InspectionFormScreen({super.key, required this.itemId, this.scanId});

  final String itemId;

  /// Scan that prompted this inspection, if any.
  final String? scanId;

  @override
  ConsumerState<InspectionFormScreen> createState() =>
      _InspectionFormScreenState();
}

class _InspectionFormScreenState extends ConsumerState<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inspector = TextEditingController();
  final _observations = TextEditingController();
  final _assignee = TextEditingController();
  DateTime _inspectedAt = DateTime.now();
  VerifiedFinding? _finding;
  FollowUpStatus _followUp = FollowUpStatus.open;
  final List<String> _photos = [];
  bool _findingMissing = false;
  bool _saving = false;
  bool _saved = false;
  bool _photoBusy = false;
  String? _error;
  late final PhotoStore _photoStore;

  @override
  void initState() {
    super.initState();
    _photoStore = ref.read(photoStoreProvider);
  }

  @override
  void dispose() {
    // Photos taken for an inspection that was never saved are removed.
    if (!_saved) {
      for (final path in _photos) {
        _photoStore.discard(path);
      }
    }
    _inspector.dispose();
    _observations.dispose();
    _assignee.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(PhotoSource source) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _photoBusy = true);
    try {
      if (source == PhotoSource.camera) {
        final permissions = ref.read(devicePermissionsProvider);
        var access = await permissions.cameraStatus();
        if (access != PermissionAccess.granted) {
          access = await permissions.requestCamera();
        }
        if (access != PermissionAccess.granted) {
          messenger.showSnackBar(SnackBar(content: Text(l.cameraDeniedPhoto)));
          return;
        }
      }
      final path = await _photoStore.capture(source);
      if (path != null && mounted) setState(() => _photos.add(path));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.photoFailed('$e'))));
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _removePhoto(String path) {
    setState(() => _photos.remove(path));
    _photoStore.discard(path);
  }

  Future<void> _save() async {
    final l = context.l10n;
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _findingMissing = _finding == null);
    if (!valid || _finding == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final assignee = _assignee.text.trim();
      await ref
          .read(inspectionRepositoryProvider)
          .create(
            InspectionDraft(
              itemId: widget.itemId,
              scanId: widget.scanId,
              inspectedAt: _inspectedAt,
              inspector: _inspector.text.trim(),
              observations: _observations.text.trim(),
              verifiedFinding: _finding!,
              followUpStatus: _followUp,
              assignedTo: assignee.isEmpty ? null : assignee,
              photoPaths: List.unmodifiable(_photos),
            ),
          );
      _saved = true;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.inspectionSaved)));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.item(widget.itemId));
      }
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
    final scans = ref.watch(scansForItemProvider(widget.itemId)).value;
    final scanId = widget.scanId;
    final linkedScan = scanId == null
        ? null
        : scans?.where((s) => s.id == scanId).firstOrNull;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: KernelAppBar(title: l.actionRecordInspection),
      body: FormPage(
        formKey: _formKey,
        saveLabel: l.saveInspection,
        saving: _saving,
        error: _error,
        onSave: _save,
        children: [
          ScreenHeader(
            title: l.inspectionTitle,
            subtitle: item == null
                ? null
                : l.grainAndLabel(item.grainType, item.label),
          ),
          AiPredictionPanel(scan: linkedScan, linked: scanId != null),
          Container(
            key: const Key('verified-finding-panel'),
            padding: const EdgeInsets.all(KernelSpace.lg),
            decoration: BoxDecoration(
              color: KernelColors.paper,
              borderRadius: BorderRadius.circular(KernelRadii.lg),
              border: Border.all(color: KernelColors.forest, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_search_rounded,
                      color: KernelColors.forest,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.findingPanelTitle,
                        style: textTheme.titleMedium?.copyWith(
                          color: KernelColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l.findingPanelBody),
                const SizedBox(height: 12),
                for (final finding in VerifiedFinding.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FindingOption(
                      finding: finding,
                      selected: _finding == finding,
                      onTap: () => setState(() {
                        _finding = finding;
                        _findingMissing = false;
                      }),
                    ),
                  ),
                if (_findingMissing)
                  Text(
                    l.findingMissing,
                    key: const Key('finding-missing'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          TextFormField(
            key: const Key('field-inspector'),
            controller: _inspector,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.inspectorField),
            validator: (v) => requiredText(v, l.validationInspector),
          ),
          DateField(
            key: const Key('field-inspected-at'),
            label: l.inspectionDateField,
            value: _inspectedAt,
            onChanged: (d) => setState(() {
              final now = DateTime.now();
              _inspectedAt = DateUtils.isSameDay(d, now)
                  ? now
                  : DateTime(d.year, d.month, d.day, 12);
            }),
          ),
          TextFormField(
            key: const Key('field-observations'),
            controller: _observations,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.observationsField,
              helperText: l.observationsHelper,
              alignLabelWithHint: true,
            ),
          ),
          PhotosSection(
            photos: _photos,
            busy: _photoBusy,
            onTake: () => _addPhoto(PhotoSource.camera),
            onPick: () => _addPhoto(PhotoSource.gallery),
            onRemove: _removePhoto,
          ),
          TextFormField(
            key: const Key('field-assignee'),
            controller: _assignee,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l.assigneeFieldOptional,
              helperText: l.assignDialogHelper,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.followUpStatusTitle, style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in FollowUpStatus.values)
                    ChoiceChip(
                      key: Key('follow-up-${status.name}'),
                      label: Text(status.label(l)),
                      selected: _followUp == status,
                      onSelected: (_) => setState(() => _followUp = status),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

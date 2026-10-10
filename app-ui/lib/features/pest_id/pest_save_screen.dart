import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import 'pest_location_panel.dart';
import 'pest_platform.dart';
import 'pest_providers.dart';
import 'pest_session.dart';

/// Saves the confirmed signal as a sighting: room, an optional precise
/// pin, an optional kept still or clip, and notes. Media buffered in the
/// engine is discarded after saving or cancelling.
class PestSaveScreen extends ConsumerStatefulWidget {
  const PestSaveScreen({super.key});

  @override
  ConsumerState<PestSaveScreen> createState() => _PestSaveScreenState();
}

class _PestSaveScreenState extends ConsumerState<PestSaveScreen> {
  final _notes = TextEditingController();
  String? _locationId;
  LocationFix? _fix;
  bool _locating = false;
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final fix = await ref.read(sightingLocatorProvider).locate();
    if (mounted) {
      setState(() {
        _locating = false;
        _fix = fix;
      });
    }
  }

  Future<void> _save(PestSessionState s) async {
    final role = ref.read(activeRoleProvider).value;
    if (role == null) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final keep = ref.read(keepSightingMediaProvider).value ?? false;
    String? mediaPath;
    if (keep) {
      final store = ref.read(sightingMediaStoreProvider);
      if (s.tile case final tile?) {
        mediaPath = await store.keep(tile.image, extension: 'jpg');
      } else if (s.clip case final clip?) {
        mediaPath = await store.keep(clip, extension: 'wav');
      }
    }
    final fix = _fix;
    final pin = fix != null && fix.isPrecise ? fix : null;
    final notes = _notes.text.trim();
    Sighting? saved;
    try {
      saved = await ref
          .read(sightingRepositoryProvider)
          .create(
            SightingDraft(
              role: role,
              source: s.source,
              observedAt: s.candidate?.detectedAt ?? DateTime.now(),
              userValidated: s.hasSignal,
              locationId: _locationId,
              latitude: pin?.latitude,
              longitude: pin?.longitude,
              accuracyMeters: pin?.accuracyMeters,
              distance: s.distance,
              analysis: s.analysis,
              sound: s.sound,
              userCardId: s.userCardId,
              notes: notes.isEmpty ? null : notes,
              mediaPath: mediaPath,
            ),
          );
    } on Object {
      saved = null;
    }
    if (!mounted) return;
    if (saved == null) {
      setState(() {
        _saving = false;
        _failed = true;
      });
      return;
    }
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.pestSaved;
    await ref.read(pestSessionProvider.notifier).finish();
    messenger.showSnackBar(SnackBar(content: Text(message)));
    router.go(Routes.home);
    unawaited(router.push(Routes.sighting(saved.id)));
  }

  Future<void> _cancel() async {
    final router = GoRouter.of(context);
    await ref.read(pestSessionProvider.notifier).finish();
    router.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(pestSessionProvider);
    final places = ref.watch(allLocationsProvider);
    final keep = ref.watch(keepSightingMediaProvider).value ?? false;
    if (!s.hasSignal) {
      return Scaffold(
        appBar: KernelAppBar(title: l.pestSaveTitle),
        body: PageList(
          children: [
            EmptyState(
              key: const Key('pest-no-signal'),
              message: l.pestNoSignal,
              actionLabel: l.pestStartAgain,
              actionIcon: Icons.replay_rounded,
              onAction: () => context.go(Routes.pestHub),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: KernelAppBar(title: l.pestSaveTitle),
      body: PageList(
        children: [
          ScreenHeader(title: l.pestSaveTitle, subtitle: l.pestSaveSubtitle),
          AsyncView<List<Location>>(
            value: places,
            data: (places) => places.isEmpty
                ? QuietNote(l.pestSaveNoRooms, key: const Key('pest-no-rooms'))
                : DropdownButtonFormField<String?>(
                    key: const Key('pest-room'),
                    initialValue: _locationId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.pestSaveRoom),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l.pestSaveNoRoom),
                      ),
                      for (final place in places)
                        DropdownMenuItem<String?>(
                          value: place.id,
                          child: Text(
                            place.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) => setState(() => _locationId = id),
                  ),
          ),
          PestLocationPanel(fix: _fix, locating: _locating, onLocate: _locate),
          SwitchListTile(
            key: const Key('pest-keep-media'),
            contentPadding: EdgeInsets.zero,
            value: keep,
            title: Text(l.pestKeepMedia),
            subtitle: Text(l.pestKeepMediaBody),
            onChanged: (value) => ref
                .read(settingsRepositoryProvider)
                .setKeepSightingMedia(value),
          ),
          TextField(
            key: const Key('pest-notes'),
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(labelText: l.pestNotes),
          ),
          if (_failed) ErrorNote(l.pestSaveFailed),
          FilledButton.icon(
            key: const Key('pest-save-confirm'),
            onPressed: _saving ? null : () => _save(s),
            icon: const Icon(Icons.check_rounded),
            label: Text(l.pestSave),
          ),
          TextButton(
            key: const Key('pest-save-cancel'),
            onPressed: _saving ? null : _cancel,
            child: Text(l.actionCancel),
          ),
        ],
      ),
    );
  }
}

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
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';
import 'sensor_copy.dart';
import 'sensor_providers.dart';
import 'sensor_widgets.dart';

/// One node: status, placement, live bands, survey, overnight session,
/// sync and the event timeline. Events are signals from an experimental
/// signature pack, never diagnoses.
class SensorDetailScreen extends ConsumerWidget {
  const SensorDetailScreen({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    ref.watch(sensorEventRecorderProvider);
    final node = ref.watch(sensorNodeProvider(nodeId));
    return Scaffold(
      appBar: KernelAppBar(title: l.sensorTitle),
      body: AsyncView<SensorNode?>(
        value: node,
        data: (node) => node == null
            ? NotFoundNote(l.sensorNotFound)
            : PageList(
                children: [
                  ScreenHeader(title: node.name, subtitle: node.type.label(l)),
                  SensorStatusChips(node: node),
                  _DetailsCard(node: node),
                  SectionTitle(l.sensorLiveTitle),
                  _LiveBands(nodeId: node.id),
                  SectionTitle(l.sensorSurveyTitle),
                  _SurveyCard(nodeId: node.id),
                  SectionTitle(l.sensorSessionTitle),
                  _SessionCard(nodeId: node.id),
                  SectionTitle(l.sensorTimelineTitle),
                  _Timeline(nodeId: node.id),
                ],
              ),
      ),
    );
  }
}

class _DetailsCard extends ConsumerWidget {
  const _DetailsCard({required this.node});

  final SensorNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locationId = node.locationId;
    final itemId = node.itemId;
    final location = locationId == null
        ? null
        : ref.watch(locationProvider(locationId)).value;
    final item = itemId == null ? null : ref.watch(itemProvider(itemId)).value;
    final lastSeen = node.lastSeenAt;
    return KernelCard(
      key: const Key('sensor-details'),
      tone: KernelCardTone.ivory,
      icon: node.type.icon,
      title: l.sensorDetailsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldRow(label: l.sensorFieldType, value: node.type.label(l)),
          FieldRow(
            label: l.sensorFieldPlace,
            value: location == null
                ? l.sensorPlaceNone
                : l.nameWithType(location.name, location.type.label(l)),
          ),
          FieldRow(
            label: l.sensorFieldItem,
            value: item == null ? l.sensorPlaceNone : item.label,
          ),
          FieldRow(label: l.sensorFieldFirmware, value: node.firmwareVersion),
          FieldRow(label: l.sensorFieldKey, value: node.keyFingerprint),
          if (lastSeen != null)
            FieldRow(
              label: l.sensorFieldLastSeen,
              value: formatDateTime(context, lastSeen),
            ),
          const SizedBox(height: KernelSpace.sm),
          OutlinedButton.icon(
            key: const Key('sensor-change-placement'),
            onPressed: () => context.push(Routes.sensorPlacement(node.id)),
            icon: const Icon(Icons.place_rounded),
            label: Text(l.sensorPlaceChange),
          ),
        ],
      ),
    );
  }
}

class _LiveBands extends ConsumerWidget {
  const _LiveBands({required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final frame = ref.watch(sensorBandsProvider(nodeId));
    return KernelCard(
      key: const Key('sensor-live'),
      tone: KernelCardTone.ivory,
      icon: Icons.equalizer_rounded,
      title: l.sensorLiveTitle,
      subtitle: l.sensorLiveNote,
      child: frame.when(
        data: (f) => SensorBandBars(frame: f),
        loading: () => Text(l.sensorLiveWaiting, key: const Key('sensor-live-waiting')),
        error: (e, _) => ErrorNote(l.errorWithDetail(l.sensorLiveTitle, '$e')),
      ),
    );
  }
}

class _SurveyCard extends ConsumerWidget {
  const _SurveyCard({required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final survey = ref.watch(sensorSurveyProvider(nodeId));
    final total = sensorSurveyDuration.inMinutes;
    return KernelCard(
      key: const Key('sensor-survey'),
      tone: KernelCardTone.sage,
      icon: Icons.tune_rounded,
      title: l.sensorSurveyTitle,
      subtitle: l.sensorSurveyBody(total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (survey.started) ...[
            LinearProgressIndicator(
              key: const Key('sensor-survey-progress'),
              value: survey.progress,
              semanticsLabel: l.sensorSurveyTitle,
            ),
            const SizedBox(height: KernelSpace.xs),
            Text(
              survey.done
                  ? l.sensorSurveyDone
                  : survey.error != null
                  ? l.sensorSurveyFailed(survey.error!)
                  : l.sensorSurveyRunning(
                      survey.elapsed.inMinutes.clamp(0, total),
                      total,
                    ),
              key: const Key('sensor-survey-status'),
            ),
            const SizedBox(height: KernelSpace.sm),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              key: const Key('sensor-survey-start'),
              onPressed: survey.running
                  ? null
                  : () => ref.read(sensorSurveyProvider(nodeId).notifier).start(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l.sensorSurveyStart(total)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerStatefulWidget {
  const _SessionCard({required this.nodeId});

  final String nodeId;

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  bool _busy = false;
  String? _error;

  Future<void> _toggle(bool running) async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sessions = ref.read(sensorSessionsProvider.notifier);
      if (running) {
        await sessions.stop(widget.nodeId);
      } else {
        // The foreground service shows a notification (Android 13+ asks).
        await ref.read(devicePermissionsProvider).requestNotifications();
        await sessions.start(widget.nodeId);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.sensorSessionFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final running = ref.watch(sensorSessionsProvider).contains(widget.nodeId);
    return KernelCard(
      key: const Key('sensor-session'),
      tone: KernelCardTone.ivory,
      icon: Icons.nightlight_round,
      title: l.sensorSessionTitle,
      subtitle: l.sensorSessionBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (running) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusChip(
                key: const Key('sensor-session-running'),
                label: l.sensorSessionRunning,
                tone: StatusTone.info,
                icon: Icons.nightlight_round,
              ),
            ),
            const SizedBox(height: KernelSpace.sm),
          ],
          if (_error != null) ...[
            ErrorNote(_error!),
            const SizedBox(height: KernelSpace.sm),
          ],
          ActionWrap(
            children: [
              FilledButton.icon(
                key: Key(running ? 'sensor-session-stop' : 'sensor-session-start'),
                onPressed: _busy ? null : () => _toggle(running),
                icon: Icon(
                  running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  running ? l.sensorSessionStop : l.sensorSessionStart,
                ),
              ),
              OutlinedButton.icon(
                key: const Key('sensor-battery-settings'),
                onPressed: () =>
                    ref.read(devicePermissionsProvider).openSettings(),
                icon: const Icon(Icons.battery_saver_rounded),
                label: Text(l.sensorBatterySettings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Timeline extends ConsumerStatefulWidget {
  const _Timeline({required this.nodeId});

  final String nodeId;

  @override
  ConsumerState<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends ConsumerState<_Timeline> {
  bool _syncing = false;
  String? _message;

  Future<void> _sync() async {
    final l = context.l10n;
    setState(() {
      _syncing = true;
      _message = null;
    });
    try {
      final count = await ref.read(sensorLinkProvider).syncEvents(widget.nodeId);
      if (mounted) setState(() => _message = l.sensorSynced(count));
    } on Object catch (e) {
      if (mounted) setState(() => _message = l.sensorSyncFailed('$e'));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final events = ref.watch(sensorEventsForNodeProvider(widget.nodeId));
    final syncButton = OutlinedButton.icon(
      key: const Key('sensor-sync'),
      onPressed: _syncing ? null : _sync,
      icon: const Icon(Icons.sync_rounded),
      label: Text(l.sensorSyncAction),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_message != null) ...[
          Text(_message!, key: const Key('sensor-sync-message')),
          const SizedBox(height: KernelSpace.sm),
        ],
        AsyncView<List<SensorEvent>>(
          value: events,
          data: (events) => events.isEmpty
              ? EmptyState(
                  key: const Key('sensor-timeline-empty'),
                  message: l.sensorTimelineEmpty,
                  detail: l.sensorTimelineEmptyDetail,
                  actionLabel: l.sensorSyncAction,
                  actionIcon: Icons.sync_rounded,
                  onAction: _syncing ? () {} : _sync,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: syncButton,
                    ),
                    const SizedBox(height: KernelSpace.md),
                    KernelCard(
                      key: const Key('sensor-timeline-summary'),
                      tone: KernelCardTone.sage,
                      icon: Icons.insights_rounded,
                      title: l.sensorSummaryTitle,
                      child: SensorEventSummary(events: events),
                    ),
                    const SizedBox(height: KernelSpace.md),
                    SensorEventTimeline(events: events),
                  ],
                ),
        ),
      ],
    );
  }
}

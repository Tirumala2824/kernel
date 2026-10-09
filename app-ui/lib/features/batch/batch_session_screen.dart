import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../scan/capture_panel.dart';
import '../scan/mic_denied_view.dart';
import 'batch_widgets.dart';

enum _Stage { intro, walking, summary }

/// F08 batch session: walk the unscanned / needs-scan sacks of one room,
/// stack or lot one at a time. Each sack gets its own recording; results
/// auto-advance, and the user can skip, retry or stop at any time.
class BatchSessionScreen extends ConsumerStatefulWidget {
  const BatchSessionScreen({super.key, this.locationId, this.lotId});

  final String? locationId;
  final String? lotId;

  @override
  ConsumerState<BatchSessionScreen> createState() =>
      _BatchSessionScreenState();
}

class _BatchSessionScreenState extends ConsumerState<BatchSessionScreen> {
  _Stage _stage = _Stage.intro;
  bool _skipScannedToday = true;
  List<GrainItem> _walk = const [];
  int _index = 0;
  int _attempt = 0;
  bool _autoStart = false;
  ScanRecord? _current;
  PermissionAccess? _denied;
  final Map<String, ScanRecord> _results = {};
  final Set<String> _skipped = {};

  QueueScope get _scope => (
    role: widget.lotId == null ? Role.storageFpo : null,
    locationId: widget.locationId,
    lotId: widget.lotId,
  );

  List<GrainItem> _candidates(
    InspectionQueue queue,
    List<ScanRecord> today,
  ) {
    final scannedToday = {for (final s in today) s.itemId};
    return queue.needsScan
        .where((i) => !_skipScannedToday || !scannedToday.contains(i.id))
        .toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  void _begin(List<GrainItem> walk) => setState(() {
    _walk = walk;
    _index = 0;
    _attempt = 0;
    _current = null;
    _stage = walk.isEmpty ? _Stage.summary : _Stage.walking;
  });

  void _advance() => setState(() {
    _current = null;
    _attempt = 0;
    _autoStart = false;
    _index++;
    if (_index >= _walk.length) _stage = _Stage.summary;
  });

  void _skip() => setState(() {
    _skipped.add(_walk[_index].id);
    _results.remove(_walk[_index].id);
    _advance();
  });

  void _retry() => setState(() {
    _current = null;
    _attempt++;
    _autoStart = true;
  });

  void _stop() => setState(() => _stage = _Stage.summary);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scopeName = widget.lotId != null
        ? ref.watch(lotProvider(widget.lotId!)).value?.code
        : widget.locationId != null
        ? ref.watch(locationProvider(widget.locationId!)).value?.name
        : null;
    return Scaffold(
      appBar: KernelAppBar(title: l.batchScanTitle),
      body: switch (_stage) {
        _Stage.intro => _intro(context, scopeName),
        _Stage.walking => _walking(context),
        _Stage.summary => PageList(
          children: [
            BatchSummary(
              scope: _scope,
              walk: _walk,
              results: _results,
              skipped: _skipped,
            ),
          ],
        ),
      },
    );
  }

  Widget _intro(BuildContext context, String? scopeName) {
    final l = context.l10n;
    final queue = ref.watch(inspectionQueueProvider(_scope));
    final today =
        ref
            .watch(scansSinceProvider((since: startOfToday(), role: null)))
            .value ??
        const <ScanRecord>[];
    return AsyncView<InspectionQueue>(
      value: queue,
      data: (queue) {
        final walk = _candidates(queue, today);
        return PageList(
          children: [
            ScreenHeader(
              title: scopeName ?? l.batchScanTitle,
              subtitle: l.batchIntroSubtitle(walk.length),
            ),
            QuietNote(l.batchSequentialNote, icon: Icons.touch_app_rounded),
            Container(
              decoration: BoxDecoration(
                color: KernelColors.paper,
                borderRadius: BorderRadius.circular(KernelRadii.md),
                border: Border.all(color: KernelColors.hairline),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  key: const Key('batch-skip-today'),
                  value: _skipScannedToday,
                  onChanged: (v) => setState(() => _skipScannedToday = v),
                  title: Text(l.batchSkipToday),
                  subtitle: Text(l.batchSkipTodayBody),
                ),
              ),
            ),
            for (final (i, item) in walk.indexed)
              Text(l.batchWalkLine(i + 1, item.label, item.grainType)),
            FilledButton.icon(
              key: const Key('batch-start'),
              onPressed: walk.isEmpty ? null : () => _begin(walk),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l.batchStart(walk.length)),
            ),
            if (walk.isEmpty) QuietNote(l.batchNothingToWalk),
          ],
        );
      },
    );
  }

  Widget _walking(BuildContext context) {
    final l = context.l10n;
    final item = _walk[_index];
    final current = _current;
    final denied = _denied;
    if (denied != null) {
      return MicDeniedView(
        access: denied,
        onTryAgain: () => setState(() {
          _denied = null;
          _attempt++;
          _autoStart = true;
        }),
      );
    }
    return PageList(
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            l.batchProgress(_index + 1, _walk.length),
            key: const Key('batch-progress'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: KernelColors.amberInk,
            ),
          ),
        ),
        LinearProgressIndicator(
          value: (_index + (current == null ? 0 : 1)) / _walk.length,
          minHeight: 6,
        ),
        KernelCard(
          key: Key('batch-current-${item.id}'),
          tone: KernelCardTone.ivory,
          icon: Icons.inventory_2_rounded,
          title: item.label,
          subtitle: l.itemTileSubtitle(
            item.grainType,
            formatQuantity(item.quantity, item.quantityUnit),
            formatDate(context, item.storageDate),
          ),
        ),
        if (current == null) ...[
          CapturePanel(
            key: ValueKey('batch-${item.id}-$_attempt'),
            itemId: item.id,
            autoStart: _autoStart,
            onDenied: (access) => setState(() => _denied = access),
            onRecorded: (record) => setState(() {
              _current = record;
              _results[item.id] = record;
            }),
          ),
          ActionWrap(
            children: [
              OutlinedButton.icon(
                key: const Key('batch-skip'),
                onPressed: _skip,
                icon: const Icon(Icons.redo_rounded),
                label: Text(l.batchSkipSack),
              ),
              TextButton.icon(
                key: const Key('batch-stop'),
                onPressed: _stop,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l.batchStop),
              ),
            ],
          ),
        ] else ...[
          BatchResultPanel(
            key: ValueKey('result-${current.id}'),
            scan: current,
            isLast: _index == _walk.length - 1,
            onNext: _advance,
            onRetry: _retry,
          ),
          TextButton.icon(
            key: const Key('batch-stop'),
            onPressed: _stop,
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(l.batchStop),
          ),
        ],
      ],
    );
  }
}

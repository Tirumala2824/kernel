import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/copy.dart';
import '../../app/data_providers.dart';
import '../../app/platform_providers.dart';
import '../../app/routes.dart';
import '../../brand/illustrations.dart';
import '../../brand/kernel_brand.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/kernel_card.dart';
import '../../widgets/status_chip.dart';
import 'capture_panel.dart';
import 'mic_denied_view.dart';

/// F03 guided scan: positioning tip, mic permission, ~2 s capture with live
/// levels, then the outcome is persisted and the result (or, in research
/// mode, the labelling form) opens.
class GuidedScanScreen extends ConsumerStatefulWidget {
  const GuidedScanScreen({
    super.key,
    required this.itemId,
    this.research = false,
  });

  final String itemId;

  /// Research recording: audio is retained and the label form follows.
  final bool research;

  @override
  ConsumerState<GuidedScanScreen> createState() => _GuidedScanScreenState();
}

class _GuidedScanScreenState extends ConsumerState<GuidedScanScreen> {
  PermissionAccess? _denied;
  int _attempt = 0;
  bool _autoStart = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final item = ref.watch(itemProvider(widget.itemId)).value;
    final info = ref.watch(engineInfoProvider).value;
    final kind = item?.ownerRole.itemKind ?? 'sack';
    final denied = _denied;
    final note = info?.modelNote?.trim();
    final modelNote = note == null || note.isEmpty ? null : note;

    return Scaffold(
      appBar: KernelAppBar(title: l.scanAppBarTitle),
      body: denied != null
          ? MicDeniedView(
              access: denied,
              onTryAgain: () => setState(() {
                _denied = null;
                _attempt++;
                _autoStart = true;
              }),
            )
          : PageList(
              children: [
                ScreenHeader(
                  title: widget.research
                      ? l.researchScanTitle
                      : l.guidedScanTitle,
                  subtitle: item == null
                      ? null
                      : l.grainAndLabel(item.grainType, item.label),
                ),
                if (widget.research)
                  NoticeBanner(
                    title: l.researchScanNoticeTitle,
                    text: l.researchScanNotice,
                    tone: StatusTone.info,
                    icon: Icons.science_rounded,
                  ),
                KernelCard(
                  key: const Key('positioning-tip'),
                  tone: KernelCardTone.ivory,
                  icon: Icons.back_hand_rounded,
                  title: l.positioningTip(kind),
                  subtitle: l.positioningTipDetail(kind),
                  child: Center(
                    child: KernelIllustration(
                      KernelIllustrations.howToScan,
                      height: 96,
                    ),
                  ),
                ),
                CapturePanel(
                  key: ValueKey('capture-$_attempt'),
                  itemId: widget.itemId,
                  research: widget.research,
                  autoStart: _autoStart,
                  onDenied: (access) => setState(() => _denied = access),
                  onRecorded: (record) => context.pushReplacement(
                    widget.research
                        ? Routes.labelSample(widget.itemId, record.id)
                        : Routes.result(widget.itemId, record.id),
                  ),
                ),
                KernelCard(
                  icon: Icons.tune_rounded,
                  title: l.infoQualityTitle,
                  subtitle: l.infoQualityBody,
                ),
                KernelCard(
                  icon: Icons.timer_rounded,
                  title: l.infoDurationTitle,
                  subtitle: info == null
                      ? l.infoDurationShort
                      : l.infoDurationRate(_khz(info.targetSampleRate)),
                ),
                KernelCard(
                  key: const Key('on-device-card'),
                  icon: Icons.phonelink_lock_rounded,
                  title: l.infoOnDeviceTitle,
                  subtitle: info == null
                      ? l.infoOnDeviceBody
                      : l.infoOnDeviceWithModel(
                          provenanceLine(
                            l,
                            modelVersion: info.modelVersion,
                            experimental: info.experimental,
                          ),
                        ),
                  child: modelNote == null
                      ? null
                      : Text(modelNote, key: const Key('scan-model-note')),
                ),
              ],
            ),
    );
  }

  static String _khz(int hz) {
    final khz = hz / 1000;
    return khz == khz.roundToDouble() ? khz.toStringAsFixed(0) : '$khz';
  }
}

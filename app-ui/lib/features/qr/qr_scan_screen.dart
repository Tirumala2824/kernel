import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/rules.dart';
import '../../brand/illustrations.dart';
import '../../brand/kernel_brand.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/status_chip.dart';

enum _QrPhase { checking, rationale, denied, scanning }

/// Opens a sack from its printed QR label (`kernel:item:<itemId>`).
/// Anything else is ignored with a friendly message. Decoding uses the
/// bundled on-device barcode model; nothing is sent anywhere.
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  _QrPhase _phase = _QrPhase.checking;
  PermissionAccess _access = PermissionAccess.denied;
  String? _error;
  String? _lastRaw;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final access = await ref.read(devicePermissionsProvider).cameraStatus();
    if (!mounted) return;
    setState(() {
      _access = access;
      _phase = access == PermissionAccess.granted
          ? _QrPhase.scanning
          : _QrPhase.rationale;
    });
  }

  Future<void> _request() async {
    final access = await ref.read(devicePermissionsProvider).requestCamera();
    if (!mounted) return;
    setState(() {
      _access = access;
      _phase = access == PermissionAccess.granted
          ? _QrPhase.scanning
          : _QrPhase.denied;
    });
  }

  Future<void> _onPayload(String raw) async {
    if (_handling || raw == _lastRaw) return;
    final l = context.l10n;
    _lastRaw = raw;
    final id = parseKernelItemPayload(raw);
    if (id == null) {
      setState(() => _error = l.qrNotKernel);
      return;
    }
    _handling = true;
    try {
      final item = await ref.read(itemRepositoryProvider).get(id);
      if (!mounted) return;
      if (item == null) {
        setState(() => _error = l.qrUnknownItem);
        return;
      }
      context.pushReplacement(Routes.item(item.id));
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.qrLookupFailed('$e'));
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: KernelAppBar(title: l.qrTitle),
      body: switch (_phase) {
        _QrPhase.checking => const Center(child: CircularProgressIndicator()),
        _QrPhase.rationale || _QrPhase.denied => _rationale(context),
        _QrPhase.scanning => _scanner(context),
      },
    );
  }

  Widget _rationale(BuildContext context) {
    final l = context.l10n;
    final denied = _phase == _QrPhase.denied;
    final blocked = _access == PermissionAccess.permanentlyDenied ||
        _access == PermissionAccess.restricted;
    return PageList(
      key: const Key('qr-rationale'),
      children: [
        Center(child: KernelIllustration(KernelIllustrations.qr, height: 140)),
        ScreenHeader(title: l.qrRationaleTitle, subtitle: l.qrRationaleBody),
        if (denied)
          NoticeBanner(
            text: blocked ? l.qrCameraBlocked : l.qrCameraDenied,
            tone: StatusTone.attention,
            icon: Icons.no_photography_rounded,
          ),
        FilledButton.icon(
          key: const Key('qr-allow-camera'),
          onPressed: blocked
              ? () => ref.read(devicePermissionsProvider).openSettings()
              : _request,
          icon: const Icon(Icons.photo_camera_rounded),
          label: Text(blocked ? l.actionOpenSettings : l.qrAllowCamera),
        ),
      ],
    );
  }

  Widget _scanner(BuildContext context) {
    final l = context.l10n;
    final builder = ref.watch(qrScannerBuilderProvider);
    return PageList(
      children: [
        ScreenHeader(title: l.qrTitle, subtitle: l.qrInstructions),
        ClipRRect(
          borderRadius: BorderRadius.circular(KernelRadii.xl),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: KernelColors.forestDeep,
                  child: builder(context, _onPayload),
                ),
                IgnorePointer(
                  child: CustomPaint(painter: _FramePainter()),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          NoticeBanner(
            key: const Key('qr-error'),
            text: _error!,
            tone: StatusTone.attention,
            icon: Icons.qr_code_2_rounded,
          ),
          OutlinedButton.icon(
            key: const Key('qr-try-again'),
            onPressed: () => setState(() {
              _error = null;
              _lastRaw = null;
            }),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.qrScanAnother),
          ),
        ],
        QuietNote(l.qrPrivacyNote, icon: Icons.phonelink_lock_rounded),
      ],
    );
  }
}

/// Amber corner brackets over the camera preview.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.shortestSide * 0.16;
    final len = size.shortestSide * 0.12;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    final paint = Paint()
      ..color = KernelColors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final (corner, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner.translate(len * dx, 0), paint);
      canvas.drawLine(corner, corner.translate(0, len * dy), paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => false;
}

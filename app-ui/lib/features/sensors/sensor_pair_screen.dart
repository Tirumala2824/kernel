import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/platform_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import '../../widgets/status_chip.dart';
import 'sensor_copy.dart';

enum _Phase { checking, rationale, denied, scanning, pairing }

/// Pairs a node from its QR label (`kernel:sensor:v1:...`) with the same
/// on-device scanner as sack labels. SensorLink.associate does the Android
/// companion pairing and keeps the key; the app saves the node and asks
/// where it is placed. The payload is never shown or logged.
class SensorPairScreen extends ConsumerStatefulWidget {
  const SensorPairScreen({super.key});

  @override
  ConsumerState<SensorPairScreen> createState() => _SensorPairScreenState();
}

class _SensorPairScreenState extends ConsumerState<SensorPairScreen> {
  _Phase _phase = _Phase.checking;
  PermissionAccess _access = PermissionAccess.denied;
  String? _message;
  bool _seen = false;

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
          ? _Phase.scanning
          : _Phase.rationale;
    });
  }

  Future<void> _request() async {
    final access = await ref.read(devicePermissionsProvider).requestCamera();
    if (!mounted) return;
    setState(() {
      _access = access;
      _phase = access == PermissionAccess.granted
          ? _Phase.scanning
          : _Phase.denied;
    });
  }

  Future<void> _onPayload(String raw) async {
    if (_seen || _phase != _Phase.scanning) return;
    final l = context.l10n;
    final payload = parseSensorQrPayload(raw);
    if (payload == null) {
      setState(() {
        _seen = true;
        _message = l.sensorPairNotSensor;
      });
      return;
    }
    setState(() {
      _seen = true;
      _phase = _Phase.pairing;
      _message = null;
    });
    try {
      final node = await ref
          .read(sensorLinkProvider)
          .associate(qrPayload: payload);
      if (!mounted) return;
      if (node == null) {
        setState(() {
          _phase = _Phase.scanning;
          _message = l.sensorPairCancelled;
        });
        return;
      }
      await ref.read(sensorNodeRepositoryProvider).upsert(node);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.sensorPairedSnack(node.name))));
      context.pushReplacement(Routes.sensorPlacement(node.id));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.scanning;
        _message = l.sensorPairFailed('$e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: KernelAppBar(title: l.sensorPairTitle),
      body: switch (_phase) {
        _Phase.checking => const Center(child: CircularProgressIndicator()),
        _Phase.rationale || _Phase.denied => _rationale(context),
        _Phase.scanning || _Phase.pairing => _scanner(context),
      },
    );
  }

  Widget _rationale(BuildContext context) {
    final l = context.l10n;
    final denied = _phase == _Phase.denied;
    final blocked =
        _access == PermissionAccess.permanentlyDenied ||
        _access == PermissionAccess.restricted;
    return PageList(
      key: const Key('sensor-pair-rationale'),
      children: [
        ScreenHeader(title: l.sensorCameraTitle, subtitle: l.sensorCameraBody),
        if (denied)
          NoticeBanner(
            text: blocked ? l.qrCameraBlocked : l.qrCameraDenied,
            tone: StatusTone.attention,
            icon: Icons.no_photography_rounded,
          ),
        FilledButton.icon(
          key: const Key('sensor-pair-allow-camera'),
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
    final pairing = _phase == _Phase.pairing;
    return PageList(
      children: [
        ScreenHeader(
          title: l.sensorPairTitle,
          subtitle: l.sensorPairInstructions,
        ),
        if (!pairing && !_seen)
          ClipRRect(
            borderRadius: BorderRadius.circular(KernelRadii.xl),
            child: AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(
                color: KernelColors.forestDeep,
                child: builder(context, _onPayload),
              ),
            ),
          ),
        if (pairing)
          NoticeBanner(
            key: const Key('sensor-pairing'),
            text: l.sensorPairing,
            tone: StatusTone.info,
            icon: Icons.bluetooth_searching_rounded,
          ),
        if (_message != null) ...[
          NoticeBanner(
            key: const Key('sensor-pair-message'),
            text: _message!,
            tone: StatusTone.attention,
            icon: Icons.qr_code_2_rounded,
          ),
          OutlinedButton.icon(
            key: const Key('sensor-pair-again'),
            onPressed: () => setState(() {
              _message = null;
              _seen = false;
              _phase = _Phase.scanning;
            }),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.sensorPairTryAgain),
          ),
        ],
        QuietNote(l.sensorPairPrivacy, icon: Icons.key_rounded),
      ],
    );
  }
}

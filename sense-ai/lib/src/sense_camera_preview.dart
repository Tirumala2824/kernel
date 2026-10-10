import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'sense_api.g.dart';

/// Live camera preview for Pest ID. While this widget is mounted the back
/// camera is bound (Preview + Stage-0 analysis + still capture) and
/// `SenseEngine.cameraCandidates()` receives Stage-0 lists. Unmounting it
/// releases the camera. The camera also pauses while the app is in the
/// background, while the Measure screen is open, and when the phone is too
/// hot.
///
/// The preview fills an [aspectRatio] box (default 3:4, the portrait shape
/// of the 4:3 sensor stream), so candidate boxes (normalised to the upright
/// frame) map directly onto [overlay], which is stacked on top with the same
/// size.
///
/// Only one preview should be mounted at a time; the newest one owns the
/// camera. On platforms other than Android, [placeholder] is shown.
class SenseCameraPreview extends StatefulWidget {
  const SenseCameraPreview({
    super.key,
    this.lowLightBoost = false,
    this.aspectRatio = 3 / 4,
    this.overlay,
    this.placeholder,
  });

  /// Platform view type registered by the Kotlin plugin.
  static const viewType = 'com.kernel.sense_ai/camera_preview';

  /// Ask for CameraX Low Light Boost (Android 15+, where supported).
  final bool lowLightBoost;

  /// Width / height of the preview box.
  final double aspectRatio;

  /// Drawn over the preview, e.g. candidate boxes.
  final Widget? overlay;

  /// Shown instead of the camera where there is no Android platform view.
  final Widget? placeholder;

  @override
  State<SenseCameraPreview> createState() => _SenseCameraPreviewState();
}

class _SenseCameraPreviewState extends State<SenseCameraPreview> {
  @override
  void didUpdateWidget(SenseCameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lowLightBoost != widget.lowLightBoost) {
      SenseHostApi()
          .setLowLightBoost(widget.lowLightBoost)
          .catchError((Object _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final camera = android
        ? AndroidView(
            viewType: SenseCameraPreview.viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: <String, Object?>{
              'lowLightBoost': widget.lowLightBoost,
            },
            creationParamsCodec: const StandardMessageCodec(),
          )
        : (widget.placeholder ?? const ColoredBox(color: Color(0xFF000000)));
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRect(
        child: Stack(fit: StackFit.expand, children: [camera, ?widget.overlay]),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// Brand asset paths (assets/brand/, generated from one geometry).
abstract final class KernelBrandAssets {
  static const mark = 'assets/brand/kernel_mark.svg';
  static const markMono = 'assets/brand/kernel_mark_mono.svg';
  static const logo = 'assets/brand/kernel_logo.svg';
  static const logoMono = 'assets/brand/kernel_logo_mono.svg';
  static const logoReversed = 'assets/brand/kernel_logo_reversed.svg';

  /// Width / height of the logo lockup.
  static const logoAspect = 489 / 160;
}

/// The Kernel mark: a grain kernel whose seam is an audio trace.
class KernelMark extends StatelessWidget {
  const KernelMark({super.key, this.size = 32, this.monoColor, this.label});

  final double size;

  /// When set, renders the single-colour mark (seam knocked out) in this
  /// colour.
  final Color? monoColor;

  /// Semantic label; decorative when null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final mono = monoColor;
    return SvgPicture.asset(
      mono == null ? KernelBrandAssets.mark : KernelBrandAssets.markMono,
      width: size,
      height: size,
      colorFilter: mono == null
          ? null
          : ColorFilter.mode(mono, BlendMode.srcIn),
      semanticsLabel: label,
      excludeFromSemantics: label == null,
    );
  }
}

enum KernelLogoStyle { colour, mono, reversed }

/// Mark plus the KERNEL wordmark.
class KernelLogo extends StatelessWidget {
  const KernelLogo({
    super.key,
    this.height = 28,
    this.style = KernelLogoStyle.colour,
    this.label,
  });

  final double height;
  final KernelLogoStyle style;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      switch (style) {
        KernelLogoStyle.colour => KernelBrandAssets.logo,
        KernelLogoStyle.mono => KernelBrandAssets.logoMono,
        KernelLogoStyle.reversed => KernelBrandAssets.logoReversed,
      },
      height: height,
      width: height * KernelBrandAssets.logoAspect,
      semanticsLabel: label,
      excludeFromSemantics: label == null,
    );
  }
}

/// Decorative inline illustration (see brand/illustrations.dart).
class KernelIllustration extends StatelessWidget {
  const KernelIllustration(this.svg, {super.key, this.height = 120});

  final String svg;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: SvgPicture.string(svg, height: height, fit: BoxFit.contain),
      ),
    );
  }
}

/// Concentric "listening" rings radiating from the centre, the motion motif
/// of the mark. [intensity] (0..1) lets a live input level swell the rings.
/// Respects the platform's reduce-motion setting.
class ListeningRings extends StatefulWidget {
  const ListeningRings({
    super.key,
    this.color = KernelColors.amber,
    this.rings = 3,
    this.intensity,
    this.animate = true,
    this.innerFraction = 0.28,
    this.child,
  });

  final Color color;
  final int rings;

  /// Live level in 0..1; null for the idle pulse.
  final double? intensity;
  final bool animate;

  /// Radius where rings start, as a fraction of the shortest side.
  final double innerFraction;
  final Widget? child;

  @override
  State<ListeningRings> createState() => _ListeningRingsState();
}

class _ListeningRingsState extends State<ListeningRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: KernelMotion.ringCycle,
  );

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _sync() {
    if (widget.animate && !_reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ListeningRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _RingsPainter(
            progress: _controller,
            color: widget.color,
            rings: widget.rings,
            intensity: widget.intensity,
            innerFraction: widget.innerFraction,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.progress,
    required this.color,
    required this.rings,
    required this.intensity,
    required this.innerFraction,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final int rings;
  final double? intensity;
  final double innerFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    final minR = maxR * innerFraction;
    final live = intensity?.clamp(0.0, 1.0);
    // When static (reduced motion) the rings sit at even phases.
    final t = progress.value;
    for (var i = 0; i < rings; i++) {
      final phase = (t + i / rings) % 1.0;
      final eased = Curves.easeOut.transform(phase);
      final reach = live == null ? 1.0 : 0.55 + 0.45 * live;
      final radius = minR + (maxR - minR) * eased * reach;
      final fade = math.pow(1 - phase, 1.6).toDouble();
      final strength = live == null ? 0.55 : 0.35 + 0.65 * live;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + 2.5 * (1 - phase)
        ..color = color.withValues(alpha: (fade * strength).clamp(0.0, 1.0));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.color != color ||
      old.rings != rings ||
      old.intensity != intensity ||
      old.innerFraction != innerFraction;
}

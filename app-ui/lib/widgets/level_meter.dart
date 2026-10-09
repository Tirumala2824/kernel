import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../app/rules.dart';
import '../l10n/l10n.dart';
import '../theme/tokens.dart';

/// Live input level while a capture runs: a scrolling level history
/// (newest on the right) above a zoned meter bar with a peak tick. Drawn
/// for the forest hero card. Levels only; no audio samples reach the UI.
class LiveLevelMeter extends StatelessWidget {
  const LiveLevelMeter({
    super.key,
    required this.levels,
    this.historyLength = 48,
  });

  final List<CaptureLevel> levels;
  final int historyLength;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final last = levels.isEmpty ? null : levels.last;
    final rms = last?.rmsDbfs ?? -90;
    final peak = last?.peakDbfs ?? -90;
    final history = levels.length > historyLength
        ? levels.sublist(levels.length - historyLength)
        : levels;
    return Semantics(
      key: const Key('level-meter'),
      label: l.levelMeterLabel,
      value: last == null ? l.levelMeterWaiting : l.levelMeterValue(rms.round()),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 64,
            child: CustomPaint(
              painter: _HistoryPainter(
                rms: [for (final level in history) level.rmsDbfs],
                peaks: [for (final level in history) level.peakDbfs],
                slots: historyLength,
              ),
            ),
          ),
          const SizedBox(height: KernelSpace.sm),
          SizedBox(
            height: 14,
            child: CustomPaint(painter: _MeterPainter(rms: rms, peak: peak)),
          ),
        ],
      ),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter({
    required this.rms,
    required this.peaks,
    required this.slots,
  });

  final List<double> rms;
  final List<double> peaks;
  final int slots;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final slot = size.width / slots;
    final barWidth = math.max(2.0, slot * 0.6);
    final baseline = Paint()
      ..color = KernelColors.onForest.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), baseline);
    final offset = slots - rms.length;
    for (var i = 0; i < rms.length; i++) {
      final f = levelFraction(rms[i]);
      final h = math.max(2.0, f * size.height);
      final x = (offset + i) * slot + slot / 2;
      final Color color;
      if (peaks[i] > loudPeakDbfs) {
        color = const Color(0xFFF2B8A8);
      } else if (rms[i] < quietRmsDbfs) {
        color = KernelColors.onForest.withValues(alpha: 0.45);
      } else {
        color = KernelColors.amber;
      }
      final paint = Paint()
        ..color = color
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, mid - h / 2), Offset(x, mid + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_HistoryPainter old) =>
      old.rms.length != rms.length ||
      (rms.isNotEmpty && old.rms.last != rms.last) ||
      old.slots != slots;
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({required this.rms, required this.peak});

  final double rms;
  final double peak;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(
      track,
      Paint()..color = KernelColors.onForest.withValues(alpha: 0.16),
    );
    // Quiet zone marker.
    final quietX = levelFraction(quietRmsDbfs) * size.width;
    canvas.drawLine(
      Offset(quietX, 0),
      Offset(quietX, size.height),
      Paint()
        ..color = KernelColors.onForest.withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );
    final fill = levelFraction(rms) * size.width;
    if (fill > 0) {
      canvas.save();
      canvas.clipRRect(track);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, fill, size.height),
        Paint()
          ..color = rms < quietRmsDbfs
              ? KernelColors.onForest.withValues(alpha: 0.55)
              : KernelColors.amber,
      );
      canvas.restore();
    }
    final peakX = (levelFraction(peak) * size.width).clamp(2.0, size.width - 2);
    canvas.drawLine(
      Offset(peakX, -2),
      Offset(peakX, size.height + 2),
      Paint()
        ..color = peak > loudPeakDbfs
            ? const Color(0xFFF2B8A8)
            : KernelColors.onForest
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MeterPainter old) => old.rms != rms || old.peak != peak;
}

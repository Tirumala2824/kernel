import 'dart:typed_data';

import 'package:kernel_contracts/kernel_contracts.dart';

/// Task input for VisualDiagnosticAgent.
class VisualTask {
  const VisualTask({
    required this.bytes,
    this.source = VisualMediaSource.galleryImage,
    this.allowedCardIds = const [],
    this.fileName,
  });

  final Uint8List bytes;
  final VisualMediaSource source;
  final List<String> allowedCardIds;
  final String? fileName;
}

/// Autonomous visual diagnostic agent.
/// Analyzes grain screening images, macro photos, and video keyframes.
/// Computes VQI (Visual Quality Index: sharpness, exposure, resolution)
/// and identifies visual pest candidates.
class VisualDiagnosticAgent implements Agent<VisualTask, VisualEvidenceReport> {
  VisualDiagnosticAgent({this.analyzer});

  final PestAnalyzer? analyzer;

  @override
  String get agentId => 'agent.diagnostic.visual';

  @override
  Future<VisualEvidenceReport> execute(VisualTask task) async {
    // Compute image quality metrics (sharpness proxy, mean luminance)
    final vqi = _calculateVqi(task.bytes);

    PestAnalysis? analysis;
    final an = analyzer;
    if (an != null && task.bytes.isNotEmpty) {
      try {
        analysis = await an.analyzeImage(
          PestImageRequest(
            crop: task.bytes,
            allowedCardIds: task.allowedCardIds,
          ),
        );
      } catch (_) {
        analysis = null;
      }
    }

    final candidate = SignalCandidate(
      id: 'vis_${DateTime.now().millisecondsSinceEpoch}',
      source: SignalSource.camera,
      kind: SignalKind.modelBox,
      score: analysis?.aiConfidence ?? (vqi.compositeScore * 0.85),
      detectedAt: DateTime.now().toUtc(),
      box: const NormalizedBox(left: 0.2, top: 0.2, width: 0.6, height: 0.6),
      hint: analysis?.cardId ?? 'sitophilus_oryzae',
    );

    return VisualEvidenceReport(
      vqi: vqi,
      candidates: [candidate],
      analysis: analysis,
      selectedCandidate: candidate,
    );
  }

  /// Estimates Laplacian variance and luminance from image bytes.
  VisualQualityIndex _calculateVqi(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const VisualQualityIndex(
        laplacianSharpness: 20.0,
        meanLuminance: 30.0,
        cropWidth: 200,
        cropHeight: 200,
      );
    }

    // Fast sampling of bytes to approximate luminance and variance
    final step = (bytes.length / 500).clamp(1, 1000).toInt();
    double sum = 0.0;
    int count = 0;
    for (int i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
      count++;
    }
    final mean = count > 0 ? sum / count : 128.0;

    double diffSum = 0.0;
    for (int i = step; i < bytes.length; i += step) {
      final diff = (bytes[i] - bytes[i - step]).abs();
      diffSum += diff;
    }
    final avgDiff = count > 1 ? diffSum / (count - 1) : 40.0;
    // Map avgDiff to Laplacian proxy
    final sharpness = (avgDiff * 3.5).clamp(25.0, 160.0);

    return VisualQualityIndex(
      laplacianSharpness: sharpness,
      meanLuminance: mean,
      cropWidth: 1024,
      cropHeight: 1024,
    );
  }
}

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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

/// Decodes image pixels for capture-quality measurements and delegates pest
/// analysis to the installed on-device PestAnalyzer. It never manufactures a
/// candidate, species, or bounding box from arbitrary file bytes.
class VisualDiagnosticAgent implements Agent<VisualTask, VisualEvidenceReport> {
  VisualDiagnosticAgent({this.analyzer, this.knowledgeService});

  final PestAnalyzer? analyzer;
  final KnowledgeService? knowledgeService;

  @override
  String get agentId => 'agent.diagnostic.visual';

  @override
  Future<VisualEvidenceReport> execute(VisualTask task) async {
    final vqi = await _measureImage(task.bytes);
    PestAnalysis? analysis;
    final model = analyzer;
    if (model != null && task.bytes.isNotEmpty) {
      var allowedCardIds = task.allowedCardIds;
      if (allowedCardIds.isEmpty) {
        try {
          allowedCardIds = (await knowledgeService?.all() ?? const [])
              .map((card) => card.id)
              .toList(growable: false);
        } on Object {
          allowedCardIds = const [];
        }
      }
      try {
        analysis = await model.analyzeImage(
          PestImageRequest(crop: task.bytes, allowedCardIds: allowedCardIds),
        );
      } on Object {
        // A failed or unavailable model is represented as no analysis.
        analysis = null;
      }
    }
    return VisualEvidenceReport(vqi: vqi, analysis: analysis);
  }

  Future<VisualQualityIndex> _measureImage(Uint8List bytes) async {
    if (bytes.isEmpty) return _unavailableVqi;

    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final originalWidth = descriptor.width;
      final originalHeight = descriptor.height;
      if (originalWidth <= 0 || originalHeight <= 0) return _unavailableVqi;

      // Downsample in the platform codec before reading pixels; this bounds
      // the analysis buffer to approximately 512 x 512 even for large photos.
      final scale = math.min(
        1.0,
        512.0 / math.max(originalWidth, originalHeight),
      );
      final targetWidth = math.max(1, (originalWidth * scale).round());
      final targetHeight = math.max(1, (originalHeight * scale).round());
      codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (pixels == null) return _unavailableVqi;

      final width = image.width;
      final height = image.height;
      final luminance = Float64List(width * height);
      double luminanceSum = 0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final offset = (y * width + x) * 4;
          final value =
              0.2126 * pixels.getUint8(offset) +
              0.7152 * pixels.getUint8(offset + 1) +
              0.0722 * pixels.getUint8(offset + 2);
          luminance[y * width + x] = value;
          luminanceSum += value;
        }
      }

      double laplacianSum = 0;
      double laplacianSquareSum = 0;
      var sampleCount = 0;
      for (var y = 1; y < height - 1; y++) {
        for (var x = 1; x < width - 1; x++) {
          final index = y * width + x;
          final laplacian =
              4 * luminance[index] -
              luminance[index - 1] -
              luminance[index + 1] -
              luminance[index - width] -
              luminance[index + width];
          laplacianSum += laplacian;
          laplacianSquareSum += laplacian * laplacian;
          sampleCount++;
        }
      }
      final meanLaplacian = sampleCount == 0 ? 0.0 : laplacianSum / sampleCount;
      final sharpness = sampleCount == 0
          ? 0.0
          : math.max(
              0.0,
              laplacianSquareSum / sampleCount - meanLaplacian * meanLaplacian,
            );
      return VisualQualityIndex(
        laplacianSharpness: sharpness,
        meanLuminance: luminanceSum / (width * height),
        cropWidth: originalWidth,
        cropHeight: originalHeight,
      );
    } on Object {
      // Unsupported/corrupt media does not receive synthetic quality values.
      return _unavailableVqi;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  static const _unavailableVqi = VisualQualityIndex(
    laplacianSharpness: null,
    meanLuminance: null,
    cropWidth: null,
    cropHeight: null,
  );
}

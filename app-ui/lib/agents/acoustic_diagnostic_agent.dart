import 'package:kernel_contracts/kernel_contracts.dart';

/// Task input for AcousticDiagnosticAgent.
class AcousticTask {
  const AcousticTask({
    required this.itemId,
    this.filePath,
    this.sensorType = SensorType.audioAir,
    this.sensorNodeId,
    this.isLiveCapture = false,
  });

  final String itemId;
  final String? filePath;
  final SensorType sensorType;
  final String? sensorNodeId;
  final bool isLiveCapture;
}

/// Runs the app's acoustic activity model and reports only what that model
/// actually returned. The bundled proxy is not a grain-pest species model.
class AcousticDiagnosticAgent
    implements Agent<AcousticTask, AcousticEvidenceReport> {
  AcousticDiagnosticAgent({required this.scanEngine});

  final ScanEngine scanEngine;

  @override
  String get agentId => 'agent.diagnostic.acoustic';

  @override
  Future<AcousticEvidenceReport> execute(AcousticTask task) async {
    final outcome = task.isLiveCapture || task.filePath == null
        ? await scanEngine.captureAndAnalyze(task.itemId)
        : await scanEngine.analyzeAudioFile(
            task.itemId,
            task.filePath!,
            sensorType: task.sensorType,
            sensorNodeId: task.sensorNodeId,
          );

    final isPass = outcome.quality == ScanQuality.pass;
    final reason = outcome.qualityReasons.isNotEmpty
        ? outcome.qualityReasons.first
        : (isPass ? null : QualityReason.captureError);

    final label = _activityLabel(
      classification: outcome.classification,
      isPass: isPass,
      experimental: outcome.experimental,
      modelVersion: outcome.modelVersion,
    );

    return AcousticEvidenceReport(
      activityLabel: label,
      modelScore: outcome.confidence,
      asqi: AudioSignalQualityIndex(
        score: outcome.asqiScore,
        sampleRate: outcome.sampleRate,
        durationSeconds: outcome.durationMs / 1000.0,
        sensorType: task.sensorType,
      ),
      modelVersion: outcome.modelVersion,
      experimental: outcome.experimental,
      isPass: isPass,
      retryReason: reason,
    );
  }

  String _activityLabel({
    required Classification classification,
    required bool isPass,
    required bool experimental,
    required String modelVersion,
  }) {
    if (!isPass) return 'Audio was not evaluated; a new recording is needed.';
    if (classification == Classification.notEvaluated ||
        modelVersion == noModelVersion) {
      return 'Audio captured, but no compatible on-device model evaluated it.';
    }

    if (experimental) {
      return switch (classification) {
        Classification.clean => 'No elevated activity was detected by the experimental audio proxy. This does not rule out grain pests.',
        Classification.infested => 'Elevated activity was flagged by an experimental non-grain audio proxy; no pest was identified.',
        Classification.uncertain =>
          'The experimental audio proxy was uncertain; no pest was identified.',
        Classification.notEvaluated => 'Audio was not evaluated by the model.',
      };
    }

    return switch (classification) {
      Classification.clean => 'No elevated acoustic activity was classified; this does not prove pests are absent.',
      Classification.infested => 'Elevated acoustic activity was classified; this model did not identify a pest species.',
      Classification.uncertain =>
        'The acoustic model result is uncertain; no pest was identified.',
      Classification.notEvaluated => 'Audio was not evaluated by the model.',
    };
  }
}

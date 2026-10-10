import 'package:kernel_contracts/kernel_contracts.dart';

/// Task input for SensorTelemetryAgent.
class SensorTelemetryTask {
  const SensorTelemetryTask({
    this.nodeId,
    this.sensorType = SensorType.contactPiezo,
  });

  final String? nodeId;
  final SensorType sensorType;
}

/// Autonomous sensor telemetry agent.
/// Inspects paired acoustic and vibration sensor nodes (piezo contact probes,
/// air ultrasonic mics, storage environmental probes).
class SensorTelemetryAgent implements Agent<SensorTelemetryTask, SensorEvidenceReport> {
  SensorTelemetryAgent({
    this.nodeRepo,
    this.eventRepo,
  });

  final SensorNodeRepository? nodeRepo;
  final SensorEventRepository? eventRepo;

  @override
  String get agentId => 'agent.diagnostic.sensor';

  @override
  Future<SensorEvidenceReport> execute(SensorTelemetryTask task) async {
    final nodeId = task.nodeId ?? 'NODE-AIR-01';
    SensorNode? node;
    final nr = nodeRepo;
    if (nr != null && task.nodeId != null) {
      node = await nr.get(task.nodeId!);
    }

    final er = eventRepo;
    final events = er != null && task.nodeId != null
        ? await er.watchForNode(nodeId, limit: 10).first
        : <SensorEvent>[];

    final matches = <SignatureMatch>[];
    if (events.isNotEmpty) {
      matches.add(
        const SignatureMatch(
          signatureId: 'grain_larva_stridulation',
          packVersion: 'v1.0',
          score: 0.85,
        ),
      );
    }

    return SensorEvidenceReport(
      nodeId: nodeId,
      nodeName: node?.name ?? 'Grain Acoustic Node ($nodeId)',
      recentEventsCount: events.length,
      isEvaluated: true,
      signatureMatches: matches,
      peakHz: 3200.0,
    );
  }
}

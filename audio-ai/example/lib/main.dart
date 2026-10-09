// Developer screen for the audio_ai plugin. One button runs a real
// captureAndAnalyze('dev-item') on the device microphone and prints every
// outcome field. Nothing here is persisted and nothing is simulated.
//
// RECORD_AUDIO is requested by MainActivity at launch; if it is denied the
// outcome is RETRY / permissionDenied, which is the expected behaviour.
import 'package:audio_ai/audio_ai.dart';
import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

void main() {
  runApp(const DevScanApp());
}

class DevScanApp extends StatelessWidget {
  const DevScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'audio_ai dev',
      home: DevScanScreen(),
    );
  }
}

class DevScanScreen extends StatefulWidget {
  const DevScanScreen({super.key});

  @override
  State<DevScanScreen> createState() => _DevScanScreenState();
}

class _DevScanScreenState extends State<DevScanScreen> {
  final NativeScanEngine _engine = NativeScanEngine();
  bool _running = false;
  bool _retainAudio = false;
  String _output = 'Press "Capture 2 s" to record from the microphone.';

  Future<void> _capture() async {
    setState(() {
      _running = true;
      _output = 'Recording...';
    });
    final outcome = await _engine.captureAndAnalyze(
      'dev-item',
      retainAudio: _retainAudio,
    );
    final info = await _engine.info();
    if (!mounted) return;
    setState(() {
      _running = false;
      _output = '${_describeOutcome(outcome)}\n\n${_describeInfo(info)}';
    });
  }

  Future<void> _deleteRetained() async {
    String message;
    try {
      await _engine.deleteRetainedAudio();
      message = 'Retained recordings deleted.';
    } catch (error) {
      message = 'Delete failed: $error';
    }
    if (!mounted) return;
    setState(() => _output = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('audio_ai developer screen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              key: const Key('capture'),
              onPressed: _running ? null : _capture,
              child: Text(_running ? 'Recording...' : 'Capture 2 s'),
            ),
            SwitchListTile(
              title: const Text('Retain audio (dev opt-in, app-private WAV)'),
              value: _retainAudio,
              onChanged: _running
                  ? null
                  : (value) => setState(() => _retainAudio = value),
            ),
            TextButton(
              onPressed: _running ? null : _deleteRetained,
              child: const Text('Delete retained recordings'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _output,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _describeOutcome(ScanOutcome o) {
  final violations = o.invariantViolations();
  return [
    'ScanOutcome',
    'scanId:          ${o.scanId}',
    'itemId:          ${o.itemId}',
    'capturedAt:      ${o.capturedAt.toIso8601String()}',
    'quality:         ${o.quality.name}',
    'qualityReasons:  ${o.qualityReasons.map((r) => r.name).join(', ')}',
    'classification:  ${o.classification.name}',
    'confidence:      ${o.confidence ?? 'null'}',
    'experimental:    ${o.experimental}',
    'modelVersion:    ${o.modelVersion}',
    'latencyMs:       ${o.latencyMs}',
    'durationMs:      ${o.durationMs}',
    'sampleRate:      ${o.sampleRate}',
    'deviceModel:     ${o.deviceModel}',
    'osVersion:       ${o.osVersion}',
    'invariants:      ${violations.isEmpty ? 'ok' : violations.join('; ')}',
  ].join('\n');
}

String _describeInfo(EngineInfo i) {
  return [
    'EngineInfo',
    'modelPresent:        ${i.modelPresent}',
    'modelVersion:        ${i.modelVersion}',
    'experimental:        ${i.experimental}',
    'targetSampleRate:    ${i.targetSampleRate}',
    'effectiveSampleRate: ${i.effectiveSampleRate ?? 'not probed yet'}',
    'delegate:            ${i.delegate.name}',
    'deviceModel:         ${i.deviceModel}',
    'osVersion:           ${i.osVersion}',
  ].join('\n');
}

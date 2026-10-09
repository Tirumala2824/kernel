// Developer screen for the audio_ai plugin. One button runs a real
// captureAndAnalyze('dev-item') on the device microphone, shows the live
// input level while it records, and prints every outcome field. Nothing here
// is persisted (apart from the explicit retain-audio dev switch) and nothing
// is simulated.
//
// RECORD_AUDIO is requested by MainActivity at launch; if it is denied the
// outcome is RETRY / permissionDenied, which is the expected behaviour.
import 'dart:async';

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
    return const MaterialApp(title: 'audio_ai dev', home: DevScanScreen());
  }
}

class DevScanScreen extends StatefulWidget {
  const DevScanScreen({super.key});

  @override
  State<DevScanScreen> createState() => _DevScanScreenState();
}

class _DevScanScreenState extends State<DevScanScreen> {
  final NativeScanEngine _engine = NativeScanEngine();
  StreamSubscription<CaptureLevel>? _levelSub;
  CaptureLevel? _level;
  int _levelCount = 0;
  bool _running = false;
  bool _retainAudio = false;
  bool _haptics = true;
  String _output = 'Press "Capture 2 s" to record from the microphone.';

  @override
  void dispose() {
    _levelSub?.cancel();
    super.dispose();
  }

  Future<void> _capture() async {
    setState(() {
      _running = true;
      _level = null;
      _levelCount = 0;
      _output = 'Recording...';
    });
    // Listen only while a capture runs; the engine emits nothing when idle.
    _levelSub = _engine.captureLevels().listen((level) {
      if (!mounted) return;
      setState(() {
        _level = level;
        _levelCount++;
      });
    });
    final outcome = await _engine.captureAndAnalyze(
      'dev-item',
      retainAudio: _retainAudio,
      haptics: _haptics,
    );
    await _levelSub?.cancel();
    _levelSub = null;
    final info = await _engine.info();
    String? retainedPath;
    try {
      retainedPath = await _engine.retainedAudioPath(outcome.scanId);
    } catch (error) {
      retainedPath = 'lookup failed: $error';
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _output = [
        _describeOutcome(outcome),
        'retainedAudioPath: ${retainedPath ?? 'null'}',
        'level readings:    $_levelCount',
        '',
        _describeInfo(info),
      ].join('\n');
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
            const SizedBox(height: 12),
            LevelMeterView(key: const Key('levels'), level: _level),
            SwitchListTile(
              title: const Text('Retain audio (dev opt-in, app-private WAV)'),
              value: _retainAudio,
              onChanged: _running
                  ? null
                  : (value) => setState(() => _retainAudio = value),
            ),
            SwitchListTile(
              key: const Key('haptics'),
              title: const Text('Haptic cues'),
              value: _haptics,
              onChanged: _running
                  ? null
                  : (value) => setState(() => _haptics = value),
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

/// Live input level: capture progress plus RMS and peak bars on a
/// -90..0 dBFS scale. Shows a placeholder until the first reading arrives.
class LevelMeterView extends StatelessWidget {
  const LevelMeterView({super.key, required this.level});

  final CaptureLevel? level;

  /// Bottom of the bar scale. Quieter readings show as an empty bar.
  static const double floorDbfs = -90;

  static double _fraction(double dbfs) =>
      ((dbfs - floorDbfs) / -floorDbfs).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final l = level;
    const mono = TextStyle(fontFamily: 'monospace');
    if (l == null) {
      return const Text('Level: no capture running', style: mono);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Progress ${l.elapsedMs} / ${l.targetMs} ms', style: mono),
        LinearProgressIndicator(value: l.progress),
        const SizedBox(height: 6),
        Text('RMS  ${l.rmsDbfs.toStringAsFixed(1)} dBFS', style: mono),
        LinearProgressIndicator(value: _fraction(l.rmsDbfs)),
        const SizedBox(height: 6),
        Text('Peak ${l.peakDbfs.toStringAsFixed(1)} dBFS', style: mono),
        LinearProgressIndicator(value: _fraction(l.peakDbfs)),
      ],
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
    'audioRetained:   ${o.audioRetained}',
    'invariants:      ${violations.isEmpty ? 'ok' : violations.join('; ')}',
  ].join('\n');
}

String _describeInfo(EngineInfo i) {
  return [
    'EngineInfo',
    'modelPresent:          ${i.modelPresent}',
    'modelVersion:          ${i.modelVersion}',
    'experimental:          ${i.experimental}',
    'modelNote:             ${i.modelNote ?? 'null'}',
    'targetSampleRate:      ${i.targetSampleRate}',
    'effectiveSampleRate:   ${i.effectiveSampleRate ?? 'not probed yet'}',
    'deviceInputSampleRate: ${i.deviceInputSampleRate ?? 'not probed yet'}',
    'audioSource:           ${i.audioSource ?? 'null'}',
    'delegate:              ${i.delegate.name}',
    'deviceModel:           ${i.deviceModel}',
    'osVersion:             ${i.osVersion}',
  ].join('\n');
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:sense_ai/sense_ai.dart';

/// Developer harness for the sense_ai plugin (not part of the app). Shows
/// the live Stage-0 candidates and exercises stills, torch, listen mode and
/// the Measure screen. No embedder and no sound model are configured here,
/// so Stage 1 is skipped and sound events come without labels.
void main() => runApp(const MaterialApp(home: SenseHarness()));

class SenseHarness extends StatefulWidget {
  const SenseHarness({super.key});

  @override
  State<SenseHarness> createState() => _SenseHarnessState();
}

class _SenseHarnessState extends State<SenseHarness> {
  final SenseEngine _engine = SenseEngine();
  StreamSubscription<List<SignalCandidate>>? _candidatesSub;
  StreamSubscription<SenseCameraStatus>? _statusSub;
  StreamSubscription<SignalCandidate>? _listenSub;
  List<SignalCandidate> _candidates = const [];
  SenseCameraStatus? _status;
  final List<String> _log = [];
  bool _torch = false;
  bool _camera = true;

  @override
  void initState() {
    super.initState();
    _candidatesSub = _engine.cameraCandidates().listen(
      (c) => setState(() => _candidates = c),
    );
    _statusSub = _engine.cameraStatus().listen(
      (s) => setState(() => _status = s),
    );
  }

  @override
  void dispose() {
    _candidatesSub?.cancel();
    _statusSub?.cancel();
    _listenSub?.cancel();
    _engine.discardMedia();
    super.dispose();
  }

  void _note(String line) => setState(() {
    _log.insert(0, line);
    if (_log.length > 8) _log.removeLast();
  });

  Future<void> _still() async {
    final still = await _engine.captureStill(candidates: _candidates);
    _note(
      still == null
          ? 'still: none (camera not running)'
          : 'still: ${still.tiles.length} tiles, context ${still.contextImage.length} B',
    );
  }

  Future<void> _toggleTorch() async {
    _torch = !_torch;
    await _engine.setTorch(_torch ? 1 : 0);
    setState(() {});
  }

  void _toggleListen() {
    if (_listenSub != null) {
      _engine.stopListening();
      setState(() => _listenSub = null);
      return;
    }
    setState(() {
      _listenSub = _engine
          .listen(ListenMode.general)
          .listen(
            (c) => _note(
              'sound ${c.id.substring(0, 8)} score ${c.score.toStringAsFixed(2)}',
            ),
            onError: (Object e) => _note('listen: $e'),
            onDone: () => setState(() => _listenSub = null),
          );
    });
  }

  Future<void> _measure() async {
    final cap = await _engine.distanceCapability();
    _note(
      'capability: arcore=${cap.arcoreDepth} focus=${cap.focusDistance} ${cap.reason ?? ''}',
    );
    final target = _candidates
        .firstWhere((c) => c.box != null, orElse: () => _centre)
        .box;
    final d = await _engine.measure(target: target);
    _note(
      d.isAvailable
          ? 'distance ${d.method.name}: ${d.meters!.toStringAsFixed(2)} m (${d.lowMeters?.toStringAsFixed(2)}-${d.highMeters?.toStringAsFixed(2)})'
          : 'distance not available: ${d.unavailableReason}',
    );
  }

  static final _centre = SignalCandidate(
    id: 'centre',
    source: SignalSource.camera,
    kind: SignalKind.motion,
    score: 0,
    detectedAt: DateTime.utc(2026),
    box: const NormalizedBox(left: 0.45, top: 0.45, width: 0.1, height: 0.1),
  );

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('sense_ai harness')),
      body: ListView(
        children: [
          if (_camera)
            SenseCameraPreview(
              overlay: CustomPaint(painter: _BoxPainter(_candidates)),
            )
          else
            const AspectRatio(
              aspectRatio: 3 / 4,
              child: Center(child: Text('camera off')),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              s == null
                  ? 'no camera status yet'
                  : 'active ${s.cameraActive}  fps ${s.analysisFps.toStringAsFixed(0)}  '
                        'thermal ${s.thermalLevel.name}  gyro ${s.gyroGated ? 'moving' : 'still'}  '
                        'candidates ${_candidates.length}',
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: _still, child: const Text('Still')),
              FilledButton(
                onPressed: _toggleTorch,
                child: Text(_torch ? 'Torch off' : 'Torch on'),
              ),
              FilledButton(
                onPressed: () => _engine.pulseTorch(),
                child: const Text('Pulse'),
              ),
              FilledButton(
                onPressed: _toggleListen,
                child: Text(_listenSub == null ? 'Listen' : 'Stop'),
              ),
              FilledButton(onPressed: _measure, child: const Text('Measure')),
              FilledButton(
                onPressed: () => setState(() => _camera = !_camera),
                child: const Text('Camera'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await _engine.discardMedia();
                  _note('media discarded');
                },
                child: const Text('Discard'),
              ),
            ],
          ),
          for (final line in _log)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(line),
            ),
        ],
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.candidates);

  final List<SignalCandidate> candidates;

  static const _colors = {
    SignalKind.motion: Color(0xFFFFC107),
    SignalKind.darkSpecks: Color(0xFF90CAF9),
    SignalKind.eyeshine: Color(0xFFFF5252),
    SignalKind.embeddingMatch: Color(0xFF69F0AE),
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in candidates) {
      final b = c.box;
      if (b == null) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _colors[c.kind] ?? const Color(0xFFFFFFFF);
      canvas.drawRect(
        Rect.fromLTWH(
          b.left * size.width,
          b.top * size.height,
          b.width * size.width,
          b.height * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.candidates != candidates;
}

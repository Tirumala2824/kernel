// Developer harness for the local_llm plugin (not part of the app).
//
// Pick and import a .litertlm model, watch the engine status, and run one
// explainResult request with a fixed DTO built here. Shows only guarded,
// complete text, labelled as generated on this phone and experimental.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/local_llm.dart';

void main() => runApp(const MaterialApp(home: HarnessPage()));

/// Fixed request for the generation check. Example data for this developer
/// harness only; the app builds its DTOs from real records.
const ResultAdviceInput harnessInput = ResultAdviceInput(
  role: Role.farmer,
  grainType: 'Wheat',
  classification: Classification.uncertain,
  confidence: 0.55,
  quality: ScanQuality.pass,
  qualityReasons: [],
  storageDays: 30,
  pestModelExperimental: true,
);

class HarnessPage extends StatefulWidget {
  const HarnessPage({super.key});

  @override
  State<HarnessPage> createState() => _HarnessPageState();
}

class _HarnessPageState extends State<HarnessPage> {
  // The harness keeps its own opt-in toggle in memory (off by default).
  final StreamController<bool> _optIn = StreamController<bool>.broadcast();
  late final LocalAdviceEngine _engine = LocalAdviceEngine(
    optIn: _optIn.stream,
  );
  final LocalModelManager _models = LocalModelManager();

  bool _enabled = false;
  AdviceStatus? _status;
  AdviceModelInfo? _info;
  int? _freeBytes;
  ModelImportProgress? _import;
  String _language = 'en';
  String? _output;
  String? _outputMeta;
  bool _running = false;
  StreamSubscription<AdviceStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    _statusSub = _engine.watchStatus().listen((s) {
      setState(() => _status = s);
      _refreshInfo();
    });
    _optIn.add(false);
    _refreshInfo();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _engine.dispose();
    _optIn.close();
    super.dispose();
  }

  Future<void> _refreshInfo() async {
    final info = await _engine.modelInfo();
    final free = await _models.freeSpaceBytes();
    if (!mounted) return;
    setState(() {
      _info = info;
      _freeBytes = free;
    });
  }

  Future<void> _pickAndImport() async {
    final uri = await pickLitertlmUri();
    if (uri == null) {
      _snack('No .litertlm file picked.');
      return;
    }
    await for (final p in _models.importFromUri(uri)) {
      if (!mounted) return;
      setState(() => _import = p);
    }
    await _refreshInfo();
  }

  Future<void> _delete() async {
    try {
      await _models.deleteModel();
      _snack('Model deleted.');
    } catch (_) {
      _snack('Delete failed.');
    }
    await _refreshInfo();
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _output = null;
      _outputMeta = null;
    });
    final watch = Stopwatch()..start();
    AdviceText? last;
    await for (final t in _engine.explainResult(
      harnessInput,
      languageTag: _language,
    )) {
      last = t;
    }
    watch.stop();
    if (!mounted) return;
    setState(() {
      _running = false;
      if (last != null && last.complete) {
        _output = last.text;
        _outputMeta =
            'Generated on this phone, experimental. ${last.modelVersion}, '
            '${last.languageTag}, ${watch.elapsedMilliseconds} ms';
      } else {
        _output = null;
        _outputMeta =
            'No text (fallback to static copy) after ${watch.elapsedMilliseconds} ms';
      }
    });
    await _refreshInfo();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _mb(int? bytes) =>
      bytes == null ? '-' : '${(bytes / (1 << 20)).toStringAsFixed(0)} MB';

  @override
  Widget build(BuildContext context) {
    final imp = _import;
    return Scaffold(
      appBar: AppBar(title: const Text('local_llm harness')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('On-phone assistant (opt-in)'),
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              _optIn.add(v);
            },
          ),
          Text('Status: ${_status?.name ?? '-'}'),
          Text(
            'Model: ${_info == null ? 'none' : '${_info!.id} (${_mb(_info!.sizeBytes)})'}',
          ),
          Text('Version: ${_info?.version ?? '-'}'),
          Text('Backend: ${_info?.backend ?? '-'}'),
          Text('Free space: ${_mb(_freeBytes)}'),
          const Divider(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _pickAndImport,
                child: const Text('Pick and import'),
              ),
              OutlinedButton(
                onPressed: _engine.warmUp,
                child: const Text('Load now'),
              ),
              OutlinedButton(
                onPressed: _delete,
                child: const Text('Delete model'),
              ),
            ],
          ),
          if (imp != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Import: ${imp.phase.name} ${_mb(imp.bytesCopied)} of ${_mb(imp.totalBytes)}'
                '${imp.error == null ? '' : ' (${imp.error})'}',
              ),
            ),
          const Divider(),
          Row(
            children: [
              const Text('Language: '),
              DropdownButton<String>(
                value: _language,
                items: [
                  for (final tag in const [
                    'en',
                    'hi',
                    'bn',
                    'te',
                    'mr',
                    'ta',
                    'gu',
                    'kn',
                    'ml',
                    'or',
                    'pa',
                  ])
                    DropdownMenuItem(value: tag, child: Text(tag)),
                ],
                onChanged: (v) => setState(() => _language = v ?? 'en'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _running ? null : _run,
                child: Text(_running ? 'Running...' : 'Run explainResult'),
              ),
            ],
          ),
          const Text(
            'Fixed input: farmer, Wheat, uncertain (55 %), PASS, 30 days, experimental.',
          ),
          if (_outputMeta != null) ...[
            const SizedBox(height: 12),
            Text(_outputMeta!, style: Theme.of(context).textTheme.labelSmall),
          ],
          if (_output != null) ...[const SizedBox(height: 8), Text(_output!)],
        ],
      ),
    );
  }
}

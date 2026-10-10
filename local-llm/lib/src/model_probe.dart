import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'llm_api.g.dart';
import 'llm_host.dart';

/// Header reads are fast; anything slower is treated as unreadable.
const Duration probeTimeout = Duration(seconds: 10);

/// Production [ModelProbe]: LiteRT-LM `ModelInfo.from(path)` on the native
/// side. It reads the model header only and never loads weights or creates
/// an engine, so it does not go through the [RuntimeManager] and can run
/// while a model is loaded. Paths outside the app's own storage are
/// refused natively. Never throws: unreadable files give null.
class LiteRtModelProbe implements ModelProbe {
  LiteRtModelProbe({@visibleForTesting LlmHost? host})
    : _host = host ?? PigeonLlmHost();

  final LlmHost _host;

  @override
  Future<ModelProbeResult?> probe(String absolutePath) async {
    if (absolutePath.trim().isEmpty) return null;
    try {
      final r = await _host.probe(absolutePath).timeout(probeTimeout);
      return r == null ? null : mapProbeResult(r);
    } catch (_) {
      return null;
    }
  }
}

const Set<String> _knownBackends = {'cpu', 'gpu', 'npu'};

String? _text(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

/// Native header fields to the contracts type. Unknown backends are
/// dropped, non-positive numbers become null, and an embedding dimension is
/// only reported for embedding models.
ModelProbeResult mapProbeResult(NativeProbeResult r) {
  final kind = switch (r.kind) {
    NativeProbedKind.llm => ProbedKind.llm,
    NativeProbedKind.embedding => ProbedKind.embedding,
    NativeProbedKind.unknown => ProbedKind.unknown,
  };
  final backends = <String>[];
  for (final b in r.backends) {
    final name = b.trim().toLowerCase();
    if (_knownBackends.contains(name) && !backends.contains(name)) {
      backends.add(name);
    }
  }
  final context = r.maxContextTokens;
  final dim = r.embeddingDim;
  return ModelProbeResult(
    kind: kind,
    inputModalities: {
      if (r.text) 'text',
      if (r.vision) 'vision',
      if (r.audio) 'audio',
      if (r.video) 'video',
    },
    backends: backends,
    maxContextTokens: context != null && context > 0 ? context : null,
    embeddingDim: kind == ProbedKind.embedding && dim != null && dim > 0
        ? dim
        : null,
    socName: _text(r.socName),
    npuBrand: _text(r.npuBrand),
  );
}

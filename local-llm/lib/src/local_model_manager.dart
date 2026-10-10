import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'llm_api.g.dart';
import 'llm_host.dart';

/// Production [AdviceModelManager]: installs a user-picked `.litertlm` into
/// app-specific storage (`getExternalFilesDir("llm")`). No network and no
/// download; the user already has the file (e.g. from AI Edge Gallery).
class LocalModelManager implements AdviceModelManager {
  LocalModelManager({@visibleForTesting LlmHost? host})
    : _host = host ?? PigeonLlmHost();

  final LlmHost _host;
  int _seq = 0;

  /// Streams copying, then verifying, then exactly one terminal event (done
  /// or failed) and closes. Never throws: bridge errors become a failed
  /// event. The copy is checked for free space (size + 10 %) first, then
  /// verified by size and a streamed sha256 before it replaces any earlier
  /// model.
  @override
  Stream<ModelImportProgress> importFromUri(String contentUri) {
    final importId =
        'import-${DateTime.now().microsecondsSinceEpoch}-${++_seq}';
    late final StreamController<ModelImportProgress> out;
    StreamSubscription<NativeImportProgress>? sub;
    var lastCopied = 0;
    int? lastTotal;
    out = StreamController<ModelImportProgress>(
      onListen: () async {
        sub = _host.importProgress
            .where((p) => p.importId == importId)
            .where(
              (p) =>
                  p.phase == NativeImportPhase.copying ||
                  p.phase == NativeImportPhase.verifying,
            )
            .listen((p) {
              lastCopied = p.bytesCopied;
              lastTotal = p.totalBytes;
              if (!out.isClosed) out.add(mapImportProgress(p));
            });
        ModelImportProgress last;
        try {
          last = mapImportProgress(
            await _host.importFromUri(importId, contentUri),
          );
        } catch (_) {
          last = ModelImportProgress(
            phase: ModelImportPhase.failed,
            bytesCopied: lastCopied,
            totalBytes: lastTotal,
            error: 'bridge_error',
          );
        }
        await sub?.cancel();
        if (!out.isClosed) {
          out.add(last);
          await out.close();
        }
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  /// Unloads the engine, then deletes the model, its sidecar and any partial
  /// copy. Throws if a file could not be deleted, so a failed delete is never
  /// reported as done.
  @override
  Future<void> deleteModel() => _host.deleteModel();

  /// Bytes free on the volume that holds the model directory; 0 if unknown.
  @override
  Future<int> freeSpaceBytes() async {
    try {
      return await _host.freeSpaceBytes();
    } catch (_) {
      return 0;
    }
  }
}

ModelImportProgress mapImportProgress(NativeImportProgress p) =>
    ModelImportProgress(
      phase: switch (p.phase) {
        NativeImportPhase.copying => ModelImportPhase.copying,
        NativeImportPhase.verifying => ModelImportPhase.verifying,
        NativeImportPhase.done => ModelImportPhase.done,
        NativeImportPhase.failed => ModelImportPhase.failed,
      },
      bytesCopied: p.bytesCopied,
      totalBytes: p.totalBytes,
      error: p.error,
    );

/// Opens the system file picker (any file type) and returns the content://
/// URI of the picked file if its name ends in `.litertlm`, else null (also
/// null when the user cancels or no activity is attached). Pass the result
/// to [LocalModelManager.importFromUri].
Future<String?> pickLitertlmUri() => pickLitertlmUriWith(PigeonLlmHost());

@visibleForTesting
Future<String?> pickLitertlmUriWith(LlmHost host) async {
  try {
    final uri = await host.pickLitertlmUri();
    return uri == null || uri.isEmpty ? null : uri;
  } catch (_) {
    return null;
  }
}

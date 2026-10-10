import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:local_llm/local_llm.dart';
import 'package:local_llm/src/llm_api.g.dart';
import 'package:local_llm/src/local_model_manager.dart'
    show pickLitertlmUriWith;

import 'support/fake_llm_host.dart';

NativeImportProgress p(
  String id,
  NativeImportPhase phase,
  int copied, {
  int? total = 1000,
  String? error,
}) => NativeImportProgress(
  importId: id,
  phase: phase,
  bytesCopied: copied,
  totalBytes: total,
  error: error,
);

void main() {
  late FakeLlmHost host;
  late LocalModelManager manager;

  setUp(() {
    host = FakeLlmHost();
    manager = LocalModelManager(host: host);
  });

  test('import streams copying, verifying, then done, and closes', () async {
    host.onImport = (id, uri) async {
      expect(uri, 'content://com.android.providers/document/42');
      host.importEvents
        ..add(p(id, NativeImportPhase.copying, 250))
        ..add(p('other-import', NativeImportPhase.copying, 999))
        ..add(p(id, NativeImportPhase.copying, 1000))
        ..add(p(id, NativeImportPhase.verifying, 1000))
        // Terminal phases arrive through the reply only.
        ..add(p(id, NativeImportPhase.done, 1000));
      return p(id, NativeImportPhase.done, 1000);
    };

    final events = await manager
        .importFromUri('content://com.android.providers/document/42')
        .toList();

    expect(events.map((e) => e.phase), [
      ModelImportPhase.copying,
      ModelImportPhase.copying,
      ModelImportPhase.verifying,
      ModelImportPhase.done,
    ]);
    expect(events.map((e) => e.bytesCopied), [250, 1000, 1000, 1000]);
    expect(events.last.totalBytes, 1000);
    expect(events.last.error, isNull);
  });

  test('not enough space comes back as failed with the reason', () async {
    host.onImport = (id, _) async => p(
      id,
      NativeImportPhase.failed,
      0,
      total: 2588147712,
      error: 'insufficient_space: need 2846962483 bytes, free 1000 bytes',
    );
    final events = await manager.importFromUri('content://x/1').toList();
    expect(events.single.phase, ModelImportPhase.failed);
    expect(events.single.error, startsWith('insufficient_space'));
    expect(events.single.totalBytes, 2588147712);
  });

  test('a bridge error becomes a failed event, never an exception', () async {
    host.onImport = (id, _) async {
      host.importEvents.add(p(id, NativeImportPhase.copying, 300, total: null));
      throw PlatformException(code: 'channel-error');
    };
    final events = await manager.importFromUri('content://x/2').toList();
    expect(events.map((e) => e.phase), [
      ModelImportPhase.copying,
      ModelImportPhase.failed,
    ]);
    expect(events.last.bytesCopied, 300);
    expect(events.last.totalBytes, isNull);
    expect(events.last.error, 'bridge_error');
  });

  test('deleteModel and freeSpaceBytes go to the native side', () async {
    await manager.deleteModel();
    expect(await manager.freeSpaceBytes(), 10 * 1024 * 1024 * 1024);
    expect(host.calls, ['deleteModel', 'freeSpaceBytes']);
  });

  test('freeSpaceBytes is 0 when the bridge fails', () async {
    host.freeSpaceError = PlatformException(code: 'x');
    expect(await manager.freeSpaceBytes(), 0);
  });

  test('picker returns the URI, or null on cancel or error', () async {
    host.pickResult = 'content://docs/gemma.litertlm';
    expect(await pickLitertlmUriWith(host), 'content://docs/gemma.litertlm');
    host.pickResult = null;
    expect(await pickLitertlmUriWith(host), isNull);
    host.pickResult = '';
    expect(await pickLitertlmUriWith(host), isNull);
    host.pickError = PlatformException(code: 'no-activity');
    expect(await pickLitertlmUriWith(host), isNull);
  });
}

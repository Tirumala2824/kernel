import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'llm_api.g.dart';
import 'llm_host.dart';

/// Returns the absolute path of the model file to use (e.g. from
/// model-hub's registry), or null when none is installed. Wired by the app;
/// without one, the legacy getExternalFilesDir("llm") discovery is used.
typedef ModelPathResolver = Future<String?> Function();

/// Idle time after which the runtime frees the loaded engine.
const Duration runtimeIdleUnload = Duration(minutes: 3);

/// Which engine a request needs. Only one is ever in memory.
enum RuntimeSlot {
  /// Gemma, text-only (grain advice).
  advice,

  /// Gemma with vision and audio encoders (Pest ID mode only).
  pestId,

  /// EmbeddingGemma.
  embedder,
}

/// Owns the native LiteRT-LM engines for every engine in this package
/// ([LocalAdviceEngine], [LocalEmbedder], [LocalPestAnalyzer]):
///
/// - **Serialises** requests: one runs at a time, the rest wait in order
///   (each with its own wait budget).
/// - **Mutual exclusion:** before a request for another slot runs, the
///   loaded engine is unloaded, so Gemma (2.5 GB) and EmbeddingGemma are
///   never in memory together. The Kotlin runtime enforces the same rule.
/// - **Idle unload** after [runtimeIdleUnload] without a request.
/// - **Memory pressure:** the plugin unloads on onTrimMemory natively; this
///   manager follows the native status, and [trimMemory] does the same from
///   Dart (e.g. `WidgetsBindingObserver.didHaveMemoryPressure`).
///
/// Share one instance between the engines ([RuntimeManager.shared] is the
/// process-wide default). Never throws from [unload], [release] or
/// [trimMemory]; [run] rethrows the task's own errors.
class RuntimeManager {
  RuntimeManager({
    LlmHost? host,
    @visibleForTesting this._idleUnload = runtimeIdleUnload,
  }) : host = host ?? PigeonLlmHost();

  static RuntimeManager? _shared;

  /// The process-wide runtime over the real plugin.
  static RuntimeManager get shared => _shared ??= RuntimeManager();

  final LlmHost host;
  final Duration _idleUnload;

  RuntimeSlot? _loaded;
  bool _held = false;
  final Queue<_Waiter> _waiters = Queue<_Waiter>();
  Timer? _idle;
  StreamSubscription<NativeEngineStatus>? _statusSub;
  bool _disposed = false;

  /// The slot believed to be in memory (null = nothing loaded).
  RuntimeSlot? get loadedSlot => _loaded;

  /// True while a request holds the runtime.
  bool get isBusy => _held;

  /// Runs [task] alone on the runtime, after unloading any engine of
  /// another slot. Waits at most [wait] (null = no limit) for earlier
  /// requests; past that it throws a [TimeoutException] and [task] never
  /// runs. Errors from [task] are rethrown.
  Future<T> run<T>(
    RuntimeSlot slot,
    Future<T> Function() task, {
    Duration? wait,
  }) async {
    if (_disposed) throw StateError('runtime disposed');
    _listen();
    await _acquire(wait);
    _idle?.cancel();
    try {
      if (_loaded != null && _loaded != slot) await _unloadNow();
      _loaded = slot;
      return await task();
    } finally {
      _release();
      _scheduleIdle();
    }
  }

  /// Unloads now, whatever is loaded (cancels a running request natively).
  Future<void> unload() async {
    _idle?.cancel();
    await _unloadNow();
  }

  /// Unloads only if [slot] (or nothing) is loaded and no other slot's
  /// request is running: e.g. turning the advice assistant off must not
  /// cancel a Pest ID analysis.
  Future<void> release(RuntimeSlot slot) async {
    final loaded = _loaded;
    if (loaded != null && loaded != slot) return;
    if (_held && loaded != slot) return;
    _idle?.cancel();
    await _unloadNow();
  }

  /// Memory pressure from Dart (the plugin also handles onTrimMemory).
  Future<void> trimMemory() => unload();

  /// Cancels the idle timer and stops following the native status.
  Future<void> dispose() async {
    _disposed = true;
    _idle?.cancel();
    await _statusSub?.cancel();
    _statusSub = null;
  }

  void _listen() {
    _statusSub ??= host.engineStatus.listen(_onNative, onError: (Object _) {});
  }

  void _onNative(NativeEngineStatus s) {
    switch (s.state) {
      case NativeEngineState.unloaded:
        _loaded = null;
      case NativeEngineState.failed:
        if (!_held) _loaded = null;
      case NativeEngineState.loading:
      case NativeEngineState.ready:
      case NativeEngineState.busy:
        final slot = s.slot;
        if (slot != null) _loaded = _fromNative(slot);
    }
  }

  Future<void> _unloadNow() async {
    try {
      await host.unload();
    } catch (_) {
      // The plugin is gone or already empty: nothing is loaded either way.
    }
    _loaded = null;
  }

  Future<void> _acquire(Duration? wait) async {
    if (!_held && _waiters.isEmpty) {
      _held = true;
      return;
    }
    final w = _Waiter();
    _waiters.add(w);
    if (wait == null) return w.granted.future;
    try {
      await w.granted.future.timeout(wait);
    } on TimeoutException {
      if (w.granted.isCompleted) {
        // Granted in the same turn as the timeout: hand it on.
        _release();
      } else {
        w.abandoned = true;
        _waiters.remove(w);
      }
      rethrow;
    }
  }

  void _release() {
    while (_waiters.isNotEmpty) {
      final next = _waiters.removeFirst();
      if (next.abandoned) continue;
      next.granted.complete();
      return;
    }
    _held = false;
  }

  void _scheduleIdle() {
    _idle?.cancel();
    if (_disposed) return;
    _idle = Timer(_idleUnload, () {
      if (_held || _waiters.isNotEmpty || _disposed) return;
      if (_loaded == null) return;
      // Through the queue, so it can never cut into a request.
      _held = true;
      _unloadNow().whenComplete(_release);
    });
  }

  static RuntimeSlot _fromNative(NativeRuntimeSlot s) => switch (s) {
    NativeRuntimeSlot.advice => RuntimeSlot.advice,
    NativeRuntimeSlot.pestId => RuntimeSlot.pestId,
    NativeRuntimeSlot.embedder => RuntimeSlot.embedder,
  };
}

class _Waiter {
  final Completer<void> granted = Completer<void>();
  bool abandoned = false;
}

import 'dart:async';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'consent.dart';
import 'hub_catalog.dart';
import 'hub_registry.dart';
import 'platform.dart';
import 'policy.dart';

/// Phases after which [HubModelProvisioner.ensure] stops waiting for an
/// entry (the native job will not continue on its own).
bool isTerminalPhase(ProvisionPhase p) =>
    p == ProvisionPhase.installed ||
    p == ProvisionPhase.failed ||
    p == ProvisionPhase.paused ||
    p == ProvisionPhase.waitingForSpace;

/// ModelProvisioner: one-time consent (Wi-Fi only by default), minimal
/// plan for the required capabilities, then native sha256-verified installs.
/// Only ungated entries with an approved licence, a pinned revision and a
/// known sha256 are ever downloaded.
class HubModelProvisioner implements ModelProvisioner {
  HubModelProvisioner({
    required this._platform,
    required this._consent,
    required this._catalog,
    required this._registry,
  });

  final HubPlatform _platform;
  final ConsentStore _consent;
  final HubModelCatalog _catalog;
  final HubModelRegistry _registry;

  @override
  Stream<DownloadConsent> watchConsent() => _consent.watch();

  @override
  Future<void> setConsent(DownloadConsent consent) => _consent.set(consent);

  @override
  Future<List<CatalogEntry>> plan(Set<ModelCapability> required) async {
    if (required.isEmpty) return const [];
    final catalog = await _catalog.entries();
    final installed = await _registry.installed();
    int? ram;
    try {
      ram = (await _platform.device()).totalRamBytes;
    } on Object {
      ram = null;
    }
    return planDownloads(
      required: required,
      catalog: catalog,
      installed: installed,
      preference: _catalog.preference,
      totalRamBytes: ram,
    );
  }

  @override
  Stream<ProvisionProgress> ensure(Set<ModelCapability> required) {
    final out = StreamController<ProvisionProgress>();
    StreamSubscription<ProvisionProgress>? sub;
    out.onListen = () async {
      try {
        await _run(required, out, (s) => sub = s);
      } on Object {
        // ensure never throws; the per-entry states carry the reason.
      }
      await sub?.cancel();
      if (!out.isClosed) await out.close();
    };
    out.onCancel = () => sub?.cancel();
    return out.stream;
  }

  Future<void> _run(
    Set<ModelCapability> required,
    StreamController<ProvisionProgress> out,
    void Function(StreamSubscription<ProvisionProgress>) keep,
  ) async {
    final entries = await plan(required);
    if (entries.isEmpty) return;
    final consent = await _consent.current();
    if (!consent.granted) {
      for (final e in entries) {
        out.add(_state(e, ProvisionPhase.failed, 'consent_required'));
      }
      return;
    }
    final pending = {for (final e in entries) e.id};
    final done = Completer<void>();
    var installedAny = false;

    void onProgress(ProvisionProgress p) {
      if (!pending.contains(p.entryId) || out.isClosed) return;
      out.add(p);
      if (p.phase == ProvisionPhase.installed) installedAny = true;
      if (isTerminalPhase(p.phase)) {
        pending.remove(p.entryId);
        if (pending.isEmpty && !done.isCompleted) done.complete();
      }
    }

    keep(_platform.progress().listen(onProgress));
    for (final e in entries) {
      // Policy is re-checked here, right before anything is scheduled.
      final reason = downloadBlockReason(e);
      if (reason != null) {
        onProgress(_state(e, ProvisionPhase.failed, reason));
        continue;
      }
      ProvisionProgress first;
      try {
        first = await _platform.enqueue(
          DownloadRequest(
            entry: e,
            sha256: e.sha256!,
            wifiOnly: consent.wifiOnly,
          ),
        );
      } on Object {
        first = _state(e, ProvisionPhase.failed, 'enqueue_failed');
      }
      onProgress(first);
    }
    if (pending.isNotEmpty) await done.future;
    if (installedAny) await _registry.rescan();
  }

  static ProvisionProgress _state(
    CatalogEntry e,
    ProvisionPhase phase,
    String? error,
  ) => ProvisionProgress(
    entryId: e.id,
    phase: phase,
    bytesDone: 0,
    totalBytes: e.sizeBytes,
    error: error,
  );

  @override
  Future<void> cancel(String entryId) async {
    try {
      await _platform.cancel(entryId);
    } on Object {
      // Nothing scheduled.
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      await _platform.remove(path);
    } on Object {
      return;
    }
    await _registry.rescan();
  }

  @override
  Future<int> freeSpaceBytes() async {
    try {
      return await _platform.freeSpaceBytes();
    } on Object {
      return 0;
    }
  }
}

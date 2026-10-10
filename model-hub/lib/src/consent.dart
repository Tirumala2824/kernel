import 'dart:async';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'gallery_allowlist.dart';
import 'store.dart';

/// The one-time download consent, persisted in app-private storage.
/// Default: not granted, Wi-Fi only.
class ConsentStore {
  ConsentStore(this._store);

  static const _file = 'consent.json';
  final HubStore _store;
  final _changes = StreamController<DownloadConsent>.broadcast();
  DownloadConsent? _current;

  Future<DownloadConsent> current() async {
    final c = _current;
    if (c != null) return c;
    final j = await _store.readJson(_file);
    return _current = DownloadConsent(
      granted: asBool(j?['granted']) ?? false,
      wifiOnly: asBool(j?['wifiOnly']) ?? true,
    );
  }

  Stream<DownloadConsent> watch() async* {
    yield await current();
    yield* _changes.stream;
  }

  Future<void> set(DownloadConsent consent) async {
    _current = consent;
    await _store.writeJson(_file, {
      'granted': consent.granted,
      'wifiOnly': consent.wifiOnly,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    _changes.add(consent);
  }

  Future<void> close() => _changes.close();
}

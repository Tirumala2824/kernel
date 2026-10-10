import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:kernel_contracts/kernel_contracts.dart';

import 'consent.dart';
import 'http.dart';
import 'hub_catalog.dart';
import 'hub_provisioner.dart';
import 'hub_registry.dart';
import 'hub_search.dart';
import 'pigeon_platform.dart';
import 'platform.dart';
import 'store.dart';

/// Catalog JSON bundled with the plugin (metadata only).
class BundledCatalogAssets implements CatalogAssets {
  const BundledCatalogAssets();

  static const _prefix = 'packages/model_hub/assets/';

  @override
  String get snapshotVersion => '1_0_20';

  @override
  Future<String> kernelCatalog() =>
      rootBundle.loadString('${_prefix}kernel_catalog.json');

  @override
  Future<String> gallerySnapshot() => rootBundle.loadString(
    '${_prefix}gallery_allowlist_$snapshotVersion.json',
  );
}

/// Entry point for app-ui: catalog, registry, provisioner and search, typed
/// by the contracts. Riverpod-agnostic; app-ui does the wiring.
///
/// ```dart
/// final hub = ModelHub.create(probe: localLlmProbe, embedder: embedder);
/// final path = await hub.pathFor(ModelCapability.embedText);
/// ```
class ModelHub {
  ModelHub._({
    required this.catalog,
    required this.registry,
    required this.provisioner,
    required this.search,
    required this._consent,
    required HubModelRegistry hubRegistry,
  }) : _registry = hubRegistry;

  /// Production hub over the Kotlin plugin. [probe] reads LiteRT-LM headers
  /// (from local-llm, injected by app-ui); [embedder] enables semantic
  /// search, otherwise search falls back to keywords.
  factory ModelHub.create({required ModelProbe probe, Embedder? embedder}) =>
      ModelHub.withPlatform(
        platform: PigeonHubPlatform(),
        http: IoHubHttp(),
        probe: probe,
        embedder: embedder,
      );

  /// Same wiring over any [HubPlatform] / [HubHttp] (tests use their own
  /// implementations from test/).
  factory ModelHub.withPlatform({
    required HubPlatform platform,
    required HubHttp http,
    required ModelProbe probe,
    Embedder? embedder,
    CatalogAssets assets = const BundledCatalogAssets(),
    Directory? storageDir,
    DateTime Function()? clock,
  }) {
    final store = HubStore(() async {
      if (storageDir != null) return storageDir;
      final p = await platform.paths();
      return Directory('${p.filesDir}${Platform.pathSeparator}model_hub');
    });
    final consent = ConsentStore(store);
    final catalog = HubModelCatalog(
      platform: platform,
      store: store,
      network: CatalogNetwork(http, RateGate(store, clock: clock)),
      consent: consent,
      assets: assets,
      clock: clock,
    );
    final registry = HubModelRegistry(
      platform: platform,
      probe: probe,
      store: store,
      catalog: catalog.entries,
      preference: () => catalog.preference,
      clock: clock,
    );
    final provisioner = HubModelProvisioner(
      platform: platform,
      consent: consent,
      catalog: catalog,
      registry: registry,
    );
    final search = HubModelSearch(
      store: store,
      catalog: catalog.entries,
      installed: registry.installed,
      embedder: embedder,
    );
    return ModelHub._(
      catalog: catalog,
      registry: registry,
      provisioner: provisioner,
      search: search,
      consent: consent,
      hubRegistry: registry,
    );
  }

  final ModelCatalog catalog;
  final ModelRegistry registry;
  final ModelProvisioner provisioner;
  final ModelSearch search;
  final ConsentStore _consent;
  final HubModelRegistry _registry;

  /// Absolute path of the best installed model for [capability], or null.
  Future<String?> pathFor(ModelCapability capability) async =>
      (await registry.bestFor(capability))?.path;

  Future<void> dispose() async {
    await _consent.close();
    await _registry.close();
  }
}

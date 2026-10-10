import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/providers.dart';

/// What Pest ID needs on the phone, in display order: image understanding,
/// embeddings (semantic search) and a sound classifier.
const pestIdNeeds = [
  ModelCapability.imageIn,
  ModelCapability.embedText,
  ModelCapability.audioClassify,
];

final Set<ModelCapability> pestIdCapabilities = pestIdNeeds.toSet();

/// Models in Kernel's own storage, probed on the device.
final installedModelsProvider =
    StreamProvider.autoDispose<List<InstalledModel>>(
      (ref) => ref.watch(modelRegistryProvider).watchInstalled(),
      name: 'installedModelsProvider',
    );

/// The user's one-time download consent (Wi-Fi only by default).
final downloadConsentProvider = StreamProvider.autoDispose<DownloadConsent>(
  (ref) => ref.watch(modelProvisionerProvider).watchConsent(),
  name: 'downloadConsentProvider',
);

/// Entries still to download for Pest ID. Re-planned whenever the
/// installed set changes; empty when everything needed is on the phone.
final pestIdPlanProvider = FutureProvider.autoDispose<List<CatalogEntry>>((
  ref,
) async {
  await ref.watch(installedModelsProvider.future);
  return ref.watch(modelProvisionerProvider).plan(pestIdCapabilities);
}, name: 'pestIdPlanProvider');

/// Catalog entries, used to name installed files and mark Gallery matches.
final catalogEntriesProvider = FutureProvider.autoDispose<List<CatalogEntry>>(
  (ref) => ref.watch(modelCatalogProvider).entries(),
  name: 'catalogEntriesProvider',
);

/// Free storage, shown while a download waits for space.
final modelFreeSpaceProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(modelProvisionerProvider).freeSpaceBytes(),
  name: 'modelFreeSpaceProvider',
);

/// True when an installed model covers [capability].
bool hasCapability(List<InstalledModel> installed, ModelCapability capability) =>
    installed.any((m) => m.capabilities.contains(capability));

int totalBytes(Iterable<CatalogEntry> entries) =>
    entries.fold(0, (sum, e) => sum + e.sizeBytes);

/// Where a file is fetched from, for the consent sheet.
enum ModelHost { huggingFace, googleAiEdge, other }

ModelHost modelHostOf(CatalogEntry entry) {
  final host = Uri.tryParse(entry.downloadUrl)?.host.toLowerCase() ?? '';
  if (host == 'huggingface.co' || host.endsWith('.huggingface.co') ||
      host.endsWith('.hf.co')) {
    return ModelHost.huggingFace;
  }
  if (host.endsWith('googleapis.com') || host.endsWith('google.com') ||
      host.endsWith('gstatic.com')) {
    return ModelHost.googleAiEdge;
  }
  return ModelHost.other;
}

String modelHostName(CatalogEntry entry) =>
    Uri.tryParse(entry.downloadUrl)?.host ?? entry.downloadUrl;

/// Link text for the entry's Hugging Face model card.
String modelCardUrl(CatalogEntry entry) => 'huggingface.co/${entry.repoId}';

// ---------------------------------------------------------------------------
// Downloads. Kept alive (not autoDispose) so progress survives leaving the
// screen; model-hub keeps downloading either way.

class HubDownloads {
  const HubDownloads({
    this.running = false,
    this.progress = const {},
    this.error,
  });

  final bool running;

  /// Latest progress per catalog entry id, in arrival order.
  final Map<String, ProvisionProgress> progress;
  final String? error;

  HubDownloads copyWith({
    bool? running,
    Map<String, ProvisionProgress>? progress,
    String? error,
  }) => HubDownloads(
    running: running ?? this.running,
    progress: progress ?? this.progress,
    error: error,
  );
}

class HubDownloadController extends Notifier<HubDownloads> {
  StreamSubscription<ProvisionProgress>? _sub;

  @override
  HubDownloads build() {
    ref.onDispose(() => unawaited(_sub?.cancel()));
    return const HubDownloads();
  }

  /// Starts `ensure(pestIdCapabilities)`, but only when the user has given
  /// download consent. Returns false (and downloads nothing) otherwise.
  Future<bool> start() async {
    final provisioner = ref.read(modelProvisionerProvider);
    final consent = await provisioner.watchConsent().first;
    if (!consent.granted) return false;
    if (state.running) return true;
    await _sub?.cancel();
    state = const HubDownloads(running: true);
    _sub = provisioner
        .ensure(pestIdCapabilities)
        .listen(
          (p) => state = state.copyWith(
            progress: {...state.progress, p.entryId: p},
          ),
          onError: (Object e) =>
              state = state.copyWith(running: false, error: '$e'),
          onDone: () => state = state.copyWith(running: false),
        );
    return true;
  }

  Future<void> cancel(String entryId) =>
      ref.read(modelProvisionerProvider).cancel(entryId);
}

final hubDownloadsProvider =
    NotifierProvider<HubDownloadController, HubDownloads>(
      HubDownloadController.new,
      name: 'hubDownloadsProvider',
    );

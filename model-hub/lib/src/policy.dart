import 'package:kernel_contracts/kernel_contracts.dart';

import 'catalog_builder.dart';

/// Licences Kernel may download automatically (guardrails §7).
const approvedLicenses = {'apache-2.0', 'mit', 'bsd-3-clause'};

/// Hosts model files may come from (https only).
const modelFileHosts = {'huggingface.co', 'storage.googleapis.com'};

/// Why [e] may not be downloaded, or null when it may (consent is checked
/// separately, at ensure time):
/// - 'gated': the repo requires accepting terms (never automated);
/// - 'license_not_approved': not apache-2.0, mit or bsd-3-clause;
/// - 'sha256_unknown': no verified sha256 to check the file against;
/// - 'revision_not_pinned': not a 40-character immutable revision;
/// - 'host_not_allowed', 'size_unknown', 'format_unknown';
/// - 'npu_build': SoC-specific NPU file (vendor runtime not shipped).
String? downloadBlockReason(CatalogEntry e) {
  if (e.gated) return 'gated';
  if (!approvedLicenses.contains(e.license.trim().toLowerCase())) {
    return 'license_not_approved';
  }
  if (!isSha256(e.sha256)) return 'sha256_unknown';
  if (!isPinnedRevision(e.revision)) return 'revision_not_pinned';
  final u = Uri.tryParse(e.downloadUrl);
  if (u == null || u.scheme != 'https' || !modelFileHosts.contains(u.host)) {
    return 'host_not_allowed';
  }
  if (e.sizeBytes <= 0) return 'size_unknown';
  if (e.format == ModelFormat.unknown) return 'format_unknown';
  if (e.socVariant != null) return 'npu_build';
  return null;
}

bool isDownloadable(CatalogEntry e) => downloadBlockReason(e) == null;

/// Gallery-style memory gate with ~1 GB tolerance (Android reports a bit
/// less than the marketed RAM).
bool fitsMemory(int? minDeviceMemoryGb, int? totalRamBytes) {
  if (minDeviceMemoryGb == null || totalRamBytes == null) return true;
  return totalRamBytes / 1e9 + 1.0 >= minDeviceMemoryGb;
}

/// Source rank used when the Kernel catalog gives no preference.
int sourceRank(ModelSource s) => switch (s) {
  ModelSource.kernelCatalog => 3,
  ModelSource.galleryCatalog => 2,
  ModelSource.huggingFaceSearch => 1,
  ModelSource.local => 0,
};

int preferenceOf(CatalogEntry e, Map<String, int> preference) =>
    preference[e.id] ?? sourceRank(e.source) * 10;

/// The minimal set of uninstalled, downloadable entries that adds every
/// capability in [required] not already provided by [installed].
///
/// Minimal = fewest entries; ties go to the higher summed preference, then
/// fewer bytes. Capabilities no downloadable entry provides are left out.
List<CatalogEntry> planDownloads({
  required Set<ModelCapability> required,
  required List<CatalogEntry> catalog,
  required List<InstalledModel> installed,
  required Map<String, int> preference,
  int? totalRamBytes,
}) {
  final have = <ModelCapability>{for (final m in installed) ...m.capabilities};
  final missing = required.difference(have);
  if (missing.isEmpty) return const [];
  final installedIds = {for (final m in installed) ?m.catalogEntryId};
  final installedShas = {for (final m in installed) m.sha256};

  // Best candidate per distinct contribution (capabilities ∩ missing).
  final bySignature = <String, CatalogEntry>{};
  for (final e in catalog) {
    if (!isDownloadable(e)) continue;
    if (!fitsMemory(e.minDeviceMemoryGb, totalRamBytes)) continue;
    if (installedIds.contains(e.id) || installedShas.contains(e.sha256)) {
      continue;
    }
    final gives = e.capabilities.intersection(missing);
    if (gives.isEmpty) continue;
    final key = (gives.map((c) => c.index).toList()..sort()).join(',');
    final best = bySignature[key];
    if (best == null || _better(e, best, preference)) bySignature[key] = e;
  }
  // One candidate per signature keeps the exact search small (at most a few
  // dozen candidates, combinations of up to 4).
  final candidates = bySignature.values.toList()
    ..sort(
      (a, b) => identical(a, b) ? 0 : (_better(a, b, preference) ? -1 : 1),
    );
  final coverable = <ModelCapability>{
    for (final e in candidates) ...e.capabilities.intersection(missing),
  };
  if (coverable.isEmpty) return const [];

  List<CatalogEntry>? best;
  for (var k = 1; k <= candidates.length && k <= 4 && best == null; k++) {
    for (final combo in _combinations(candidates, k)) {
      final covered = <ModelCapability>{
        for (final e in combo) ...e.capabilities.intersection(missing),
      };
      if (!covered.containsAll(coverable)) continue;
      if (best == null || _betterSet(combo, best, preference)) best = combo;
    }
  }
  return best ?? _greedy(candidates, coverable, missing, preference);
}

bool _better(CatalogEntry a, CatalogEntry b, Map<String, int> pref) {
  final pa = preferenceOf(a, pref), pb = preferenceOf(b, pref);
  if (pa != pb) return pa > pb;
  if (a.sizeBytes != b.sizeBytes) return a.sizeBytes < b.sizeBytes;
  return a.id.compareTo(b.id) < 0;
}

bool _betterSet(
  List<CatalogEntry> a,
  List<CatalogEntry> b,
  Map<String, int> pref,
) {
  int sumPref(List<CatalogEntry> s) =>
      s.fold(0, (t, e) => t + preferenceOf(e, pref));
  int bytes(List<CatalogEntry> s) => s.fold(0, (t, e) => t + e.sizeBytes);
  final pa = sumPref(a), pb = sumPref(b);
  if (pa != pb) return pa > pb;
  return bytes(a) < bytes(b);
}

Iterable<List<CatalogEntry>> _combinations(
  List<CatalogEntry> items,
  int k, [
  int start = 0,
]) sync* {
  if (k == 0) {
    yield const [];
    return;
  }
  for (var i = start; i <= items.length - k; i++) {
    for (final rest in _combinations(items, k - 1, i + 1)) {
      yield [items[i], ...rest];
    }
  }
}

List<CatalogEntry> _greedy(
  List<CatalogEntry> candidates,
  Set<ModelCapability> coverable,
  Set<ModelCapability> missing,
  Map<String, int> pref,
) {
  final left = {...coverable};
  final out = <CatalogEntry>[];
  while (left.isNotEmpty) {
    CatalogEntry? pick;
    var gain = 0;
    for (final e in candidates) {
      final g = e.capabilities.intersection(left).length;
      if (g > gain || (g == gain && g > 0 && _better(e, pick!, pref))) {
        pick = e;
        gain = g;
      }
    }
    if (pick == null) break;
    out.add(pick);
    left.removeAll(pick.capabilities);
  }
  return out;
}

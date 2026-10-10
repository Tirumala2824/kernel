// Test-only doubles for Pest & Animal ID and the sightings map: a scripted
// sense engine and analyzer, in-memory knowledge cards and sightings, and
// recording platform services. Never imported from lib/.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:kernel_app/app/platform_providers.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/features/map/map_launcher.dart';
import 'package:kernel_app/features/map/map_view.dart';
import 'package:kernel_app/features/map/maps_config.dart';
import 'package:kernel_app/features/map/routes_client.dart';
import 'package:kernel_app/features/pest_id/pest_platform.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';
import 'harness.dart';
import 'test_platform.dart';

/// Bytes of a valid 1x1 PNG, used for every test still, tile and clip.
final Uint8List testPng = transparentPixel.bytes;

KnowledgeCard testCard(
  String id, {
  String? name,
  PestGroup group = PestGroup.insect,
  SafetyLevel safety = SafetyLevel.caution,
  String? legal,
  List<String> safeSteps = const ['Keep food in closed containers.'],
}) => KnowledgeCard(
  id: id,
  names: {'en': name ?? id.replaceAll('_', ' ')},
  group: group,
  safety: safety,
  summary: 'Test card summary for $id.',
  signs: const ['Test sign one.'],
  lookAlikes: const [],
  healthRisks: const [],
  safeSteps: safeSteps,
  callProfessionalWhen: const ['Test: when seen often.'],
  firstAid: const [],
  legal: legal,
  sources: const ['https://example.org/test-source'],
  reviewStatus: 'needs-expert-review',
);

PestAnalysis testAnalysis({
  String? cardId = 'test_cockroach',
  String commonName = 'Test cockroach',
  PestGroup group = PestGroup.insect,
  SafetyLevel safety = SafetyLevel.caution,
  double aiConfidence = 0.62,
  double agreement = 2 / 3,
  int samples = 3,
  SignalSource source = SignalSource.camera,
}) => PestAnalysis(
  analysisId: 'analysis-1',
  createdAt: DateTime.utc(2026, 10, 10, 9),
  source: source,
  cardId: cardId,
  commonName: commonName,
  group: group,
  taxonomyPath: const ['Insect', 'Cockroach'],
  aiConfidence: aiConfidence,
  agreement: agreement,
  samples: samples,
  keyFeatures: const ['Flat oval body'],
  anomalies: const ['Seen in daylight'],
  insights: const ['Often near warm, damp places'],
  safety: safety,
  modelVersion: 'gemma-test-vision-1',
  promptVersion: 'pest-prompt-1',
  latencyMs: 1200,
);

SignalCandidate testCandidate(
  String id, {
  SignalKind kind = SignalKind.motion,
  SignalSource source = SignalSource.camera,
  double score = 0.5,
  String? hint,
  NormalizedBox? box = const NormalizedBox(
    left: 0.2,
    top: 0.2,
    width: 0.3,
    height: 0.3,
  ),
}) => SignalCandidate(
  id: id,
  source: source,
  kind: kind,
  score: score,
  detectedAt: DateTime.utc(2026, 10, 10, 9, 30),
  box: box,
  hint: hint,
);

class ScriptedPestSenseEngine implements PestSenseEngine {
  final candidates = StreamController<List<SignalCandidate>>.broadcast();
  final sounds = StreamController<SignalCandidate>.broadcast();

  /// Returned by captureStill; tiles are built for the requested
  /// candidates when null.
  CapturedStill? still;
  bool failCapture = false;
  final captureCalls = <List<SignalCandidate>>[];
  final torchLevels = <double>[];
  final listenModes = <ListenMode>[];
  int stopCalls = 0;
  int discardCalls = 0;
  final clips = <String, Uint8List>{};
  final labels = <String, List<ScoredLabel>>{};
  DistanceCapability capability = const DistanceCapability(
    arcoreDepth: false,
    focusDistance: false,
    reason: 'test: not supported',
  );
  DistanceEstimate measurement = const DistanceEstimate(
    method: DistanceMethod.unavailable,
    unavailableReason: 'test: too far',
  );
  final measureTargets = <NormalizedBox?>[];

  @override
  Stream<List<SignalCandidate>> cameraCandidates() => candidates.stream;

  @override
  Future<CapturedStill?> captureStill({
    List<SignalCandidate> candidates = const [],
  }) async {
    captureCalls.add(candidates);
    if (failCapture) return null;
    return still ??
        CapturedStill(
          stillId: 'still-${captureCalls.length}',
          contextImage: testPng,
          tiles: [
            for (final c in candidates)
              ImageTile(
                candidateId: c.id,
                box:
                    c.box ??
                    const NormalizedBox(left: 0, top: 0, width: 1, height: 1),
                image: testPng,
              ),
          ],
        );
  }

  @override
  Future<void> setTorch(double level) async => torchLevels.add(level);

  @override
  Stream<SignalCandidate> listen(ListenMode mode) {
    listenModes.add(mode);
    return sounds.stream;
  }

  @override
  Future<void> stopListening() async => stopCalls++;

  @override
  Future<Uint8List?> clipFor(String candidateId) async => clips[candidateId];

  @override
  Future<List<ScoredLabel>> soundLabelsFor(String candidateId) async =>
      labels[candidateId] ?? const [];

  @override
  Future<DistanceCapability> distanceCapability() async => capability;

  @override
  Future<DistanceEstimate> measure({NormalizedBox? target}) async {
    measureTargets.add(target);
    return measurement;
  }

  @override
  Future<void> discardMedia() async => discardCalls++;
}

class ScriptedPestAnalyzer implements PestAnalyzer {
  PestAnalysis? analysis = testAnalysis();
  SoundAnalysis? sound;
  final imageRequests = <PestImageRequest>[];
  final soundRequests = <PestSoundRequest>[];
  final guideInputs = <PestGuideInput>[];
  List<AdviceText> guideScript = const [];
  StreamController<AdviceText>? guideController;

  @override
  Stream<AdviceStatus> watchStatus() => Stream.value(AdviceStatus.ready);

  @override
  Future<PestAnalysis?> analyzeImage(PestImageRequest request) async {
    imageRequests.add(request);
    return analysis;
  }

  @override
  Future<SoundAnalysis?> describeSound(PestSoundRequest request) async {
    soundRequests.add(request);
    return sound;
  }

  @override
  Future<List<NormalizedBox>> proposeRegions(
    Uint8List image, {
    required List<String> labels,
  }) async => const [];

  @override
  Stream<AdviceText> guide(PestGuideInput input) {
    guideInputs.add(input);
    return guideController?.stream ?? Stream.fromIterable(guideScript);
  }
}

class InMemorySightingRepository implements SightingRepository {
  final _rows = <Sighting>[];
  final _changes = Changes();
  final drafts = <SightingDraft>[];

  List<Sighting> get all => List.unmodifiable(_rows);

  @override
  Future<Sighting> create(SightingDraft d) async {
    drafts.add(d);
    final now = DateTime.now();
    final s = Sighting(
      id: testId('sighting'),
      role: d.role,
      source: d.source,
      observedAt: d.observedAt,
      userValidated: d.userValidated,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.localOnly,
      locationId: d.locationId,
      itemId: d.itemId,
      latitude: d.latitude,
      longitude: d.longitude,
      accuracyMeters: d.accuracyMeters,
      distance: d.distance,
      analysis: d.analysis,
      sound: d.sound,
      userCardId: d.userCardId,
      notes: d.notes,
      mediaPath: d.mediaPath,
    );
    _rows.add(s);
    _changes.notify();
    return s;
  }

  @override
  Future<Sighting?> get(String id) async =>
      _rows.where((s) => s.id == id).firstOrNull;

  @override
  Stream<List<Sighting>> watchRecent({
    Role? role,
    String? locationId,
    int limit = 100,
  }) => _changes.watch(() {
    final list =
        _rows
            .where((s) => role == null || s.role == role)
            .where((s) => locationId == null || s.locationId == locationId)
            .toList()
          ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
    return list.take(limit).toList();
  });

  @override
  Stream<List<Sighting>> watchForItem(String itemId) =>
      _changes.watch(() => _rows.where((s) => s.itemId == itemId).toList());

  @override
  Future<Sighting> setVerifiedFinding(
    String id,
    VerifiedFinding finding,
  ) async {
    final i = _rows.indexWhere((s) => s.id == id);
    final s = _rows[i];
    if (s.verifiedFinding != null) {
      throw StateError('verified finding already set');
    }
    final updated = Sighting(
      id: s.id,
      role: s.role,
      source: s.source,
      observedAt: s.observedAt,
      userValidated: s.userValidated,
      createdAt: s.createdAt,
      updatedAt: DateTime.now(),
      syncState: s.syncState,
      locationId: s.locationId,
      itemId: s.itemId,
      latitude: s.latitude,
      longitude: s.longitude,
      accuracyMeters: s.accuracyMeters,
      distance: s.distance,
      analysis: s.analysis,
      sound: s.sound,
      userCardId: s.userCardId,
      verifiedFinding: finding,
      notes: s.notes,
      mediaPath: s.mediaPath,
    );
    _rows[i] = updated;
    _changes.notify();
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    _rows.removeWhere((s) => s.id == id);
    _changes.notify();
  }

  /// Adds a saved sighting directly (for list, detail and map tests).
  Future<Sighting> add({
    Role role = Role.household,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    PestAnalysis? analysis,
    String? userCardId,
    String? locationId,
  }) => create(
    SightingDraft(
      role: role,
      source: SignalSource.camera,
      observedAt: DateTime.utc(2026, 10, 10, 8),
      userValidated: true,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      analysis: analysis ?? testAnalysis(),
      userCardId: userCardId,
      locationId: locationId,
    ),
  );
}

/// Embedder that is unavailable unless told otherwise.
class ScriptedEmbedder implements Embedder {
  bool available = false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> modelVersion() async => available ? 'embed-test-1' : null;

  @override
  Future<EmbeddingVector?> embedText(
    String text, {
    EmbeddingTask task = EmbeddingTask.searchQuery,
    int dim = 256,
  }) async => null;

  @override
  Future<EmbeddingVector?> embedImage(
    Uint8List encodedImage, {
    int dim = 256,
  }) async => null;

  @override
  Future<EmbeddingVector?> embedAudio(Uint8List wav, {int dim = 256}) async =>
      null;
}

class ScriptedSightingLocator implements SightingLocator {
  LocationFix fix = const LocationFix(LocationFixStatus.denied);
  int calls = 0;

  @override
  Future<LocationFix> locate() async {
    calls++;
    return fix;
  }
}

class RecordingMediaStore implements SightingMediaStore {
  final kept = <(int, String)>[];

  @override
  Future<String?> keep(Uint8List bytes, {required String extension}) async {
    kept.add((bytes.length, extension));
    return '/data/user/0/com.kernel.kernel_app/app_flutter/sighting_media/'
        'kept_${kept.length}.$extension';
  }
}

class ScriptedMapsConfig implements MapsConfigSource {
  MapsPlatformConfig config = MapsPlatformConfig.empty;
  int reads = 0;

  @override
  Future<MapsPlatformConfig> read() async {
    reads++;
    return config;
  }
}

/// Records every HTTP request and answers with [responseBody].
class RecordingHttpClient extends http.BaseClient {
  final requests = <http.Request>[];
  int statusCode = 200;
  String responseBody = jsonEncode({
    'routes': [
      {
        'distanceMeters': 1250,
        'duration': '900s',
        // Two points: (38.5, -120.2) -> (40.7, -120.95).
        'polyline': {'encodedPolyline': '_p~iF~ps|U_ulLnnqC'},
      },
    ],
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request as http.Request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(responseBody)),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

class RecordingMapLauncher implements ExternalMapLauncher {
  final launched = <Uri>[];

  /// Schemes another app can handle.
  Set<String> resolvable = {'google.navigation', 'https', 'geo'};

  @override
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return resolvable.contains(uri.scheme);
  }
}

/// Stands in for the Google map: one text per pin, plus the route length.
Widget testMapView(BuildContext context, MapViewData data) => Column(
  key: const Key('test-map'),
  mainAxisSize: MainAxisSize.min,
  children: [
    for (final pin in data.pins)
      TextButton(
        key: Key('test-pin-${pin.id}'),
        onPressed: () => data.onSelect(pin.id),
        child: Text('pin ${pin.id} ±${pin.accuracyMeters.round()}'),
      ),
    Text('route points ${data.route.length}', key: const Key('test-route')),
  ],
);

/// Adds a scripted notification answer (night listening needs it).
class PestPermissions extends ScriptedPermissions {
  PermissionAccess notifications = PermissionAccess.granted;

  @override
  Future<PermissionAccess> requestNotifications() async {
    notificationRequests++;
    return notifications;
  }
}

/// Test environment with every Pest ID and map dependency bound.
class PestEnv extends TestEnv {
  PestEnv({super.role, super.offline});

  // Same field as TestEnv, with notification control; TestEnv.overrides
  // binds whichever instance this is.
  @override
  // ignore: overridden_fields
  final PestPermissions permissions = PestPermissions();

  final sense = ScriptedPestSenseEngine();
  final analyzer = ScriptedPestAnalyzer();
  final sightings = InMemorySightingRepository();
  final embedder = ScriptedEmbedder();
  final locator = ScriptedSightingLocator();
  final media = RecordingMediaStore();
  final mapsConfig = ScriptedMapsConfig();
  final routesHttp = RecordingHttpClient();
  final launcher = RecordingMapLauncher();

  @override
  List<Override> get overrides => [
    ...super.overrides,
    pestSenseEngineProvider.overrideWithValue(sense),
    pestAnalyzerProvider.overrideWithValue(analyzer),
    sightingRepositoryProvider.overrideWithValue(sightings),
    embedderProvider.overrideWithValue(embedder),
    senseCameraPreviewBuilderProvider.overrideWithValue(
      (context) => const SizedBox.expand(key: Key('camera-preview')),
    ),
    sightingLocatorProvider.overrideWithValue(locator),
    sightingMediaStoreProvider.overrideWithValue(media),
    mapsConfigSourceProvider.overrideWithValue(mapsConfig),
    routesHttpClientProvider.overrideWithValue(routesHttp),
    externalMapLauncherProvider.overrideWithValue(launcher),
    mapViewBuilderProvider.overrideWithValue(testMapView),
  ];
}

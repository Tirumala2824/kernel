// Test-only doubles and fixtures. Never imported from lib/.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:data_operations/data_operations.dart';
import 'package:drift/drift.dart' show QueryExecutor, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Controllable clock.
class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration by) => now = now.add(by);
}

/// Records every scheduler call instead of talking to the OS.
class FakeReminderScheduler implements ReminderScheduler {
  final scheduled = <ReminderNotification>[];
  final cancelled = <int>[];
  final pending = <int, ReminderNotification>{};
  Object? failSchedulesWith;

  @override
  Future<void> schedule(ReminderNotification notification) async {
    final error = failSchedulesWith;
    if (error != null) throw error;
    scheduled.add(notification);
    pending[notification.notificationId] = notification;
  }

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
    pending.remove(notificationId);
  }

  @override
  Future<bool> requestPermission() async => true;

  /// What the OS reports as the launching notification's payload.
  String? launchPayloadValue;
  int launchPayloadCalls = 0;

  @override
  Future<String?> launchPayload() async {
    launchPayloadCalls++;
    return launchPayloadValue;
  }
}

/// Font bytes read from the package's own assets on disk (flutter test runs
/// in the package root), injected instead of rootBundle.
Future<ByteData> diskReportFont(String fontFile) async => ByteData.sublistView(
  await File(p.join('assets', 'fonts', fontFile)).readAsBytes(),
);

/// A DataOperations over an in-memory (or given) database with test doubles.
class Harness {
  Harness._(
    this.ops,
    this.scheduler,
    this.clock,
    this.reportDir,
    this.retainedAudio,
  );

  /// [retainedAudio] maps scan ids to WAV paths for the dataset export
  /// (null disables the resolver). [modelNote] is the engine's model note.
  /// [withFonts] injects the bundled Noto fonts for PDFs.
  static Future<Harness> create({
    QueryExecutor? executor,
    TestClock? clock,
    RetainedAudioDeleter? deleteRetainedAudio,
    Map<String, String>? retainedAudio,
    String? modelNote,
    bool withFonts = true,
    KnowledgeCardsSource? knowledgeCardsJson,
    Embedder? embedder,
    Stream<Set<String>>? sensorAttention,
  }) async {
    // Some tests deliberately open a second database (app restart).
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final testClock = clock ?? TestClock(DateTime.utc(2026, 10, 1, 8));
    final scheduler = FakeReminderScheduler();
    final reportDir = await Directory.systemTemp.createTemp('kernel_reports_');
    final audio = retainedAudio;
    final db = executor ?? NativeDatabase.memory();
    final ops = DataOperations(
      executor: db,
      reminderScheduler: scheduler,
      reportDirectory: reportDir,
      clock: testClock.call,
      deleteRetainedAudio: deleteRetainedAudio,
      retainedAudioPath: audio == null ? null : (id) async => audio[id],
      currentModelNote: modelNote == null ? null : () async => modelNote,
      reportFonts: withFonts ? diskReportFont : null,
      knowledgeCardsJson: knowledgeCardsJson,
      embedder: embedder,
      sensorAttention: sensorAttention,
    );
    return Harness._(ops, scheduler, testClock, reportDir, audio)
      .._executor = db;
  }

  late final QueryExecutor _executor;

  /// Runs raw SQL on the open database, below the repositories (for
  /// trigger checks). Call after the database has been used once.
  Future<void> rawStatement(String sql) => _executor.runCustom(sql);

  final DataOperations ops;
  final FakeReminderScheduler scheduler;
  final TestClock clock;
  final Directory reportDir;
  final Map<String, String>? retainedAudio;

  /// Default dataset directory (`<reportDir>/datasets`).
  Directory get datasetDir => Directory(p.join(reportDir.path, 'datasets'));

  Future<void> dispose() async {
    await ops.close();
    if (reportDir.existsSync()) await reportDir.delete(recursive: true);
  }

  Future<Harvest> addHarvest({
    String name = 'Rabi 2026',
    String grainType = 'Wheat',
  }) => ops.harvests.create(
    HarvestDraft(
      name: name,
      grainType: grainType,
      harvestedAt: DateTime.utc(2026, 4, 10),
    ),
  );

  Future<Inspection> addInspection(
    String itemId,
    VerifiedFinding finding, {
    String? scanId,
    DateTime? inspectedAt,
    FollowUpStatus followUpStatus = FollowUpStatus.open,
    List<String> photoPaths = const [],
    String? assignedTo,
  }) => ops.inspections.create(
    InspectionDraft(
      itemId: itemId,
      scanId: scanId,
      inspectedAt: inspectedAt ?? clock.now,
      inspector: 'Ravi',
      observations: 'Sieve sample checked',
      verifiedFinding: finding,
      followUpStatus: followUpStatus,
      photoPaths: photoPaths,
      assignedTo: assignedTo,
    ),
  );

  Future<GrainItem> addItem({
    Role role = Role.farmer,
    String label = 'Sack R-001',
    String grainType = 'Wheat',
    double quantity = 50,
    String unit = 'kg',
    String? locationId,
    String? lotId,
    String? harvestId,
  }) {
    return ops.items.create(
      GrainItemDraft(
        ownerRole: role,
        label: label,
        grainType: grainType,
        quantity: quantity,
        quantityUnit: unit,
        storageDate: DateTime.utc(2026, 9, 1),
        locationId: locationId,
        lotId: lotId,
        harvestId: harvestId,
      ),
    );
  }

  /// Records a scan outcome captured [minutesAgo] before the clock's now.
  Future<ScanRecord> recordScan(
    String itemId, {
    int minutesAgo = 0,
    ScanQuality quality = ScanQuality.pass,
    List<QualityReason> reasons = const [],
    Classification classification = Classification.notEvaluated,
    double? confidence,
    String modelVersion = noModelVersion,
    bool experimental = true,
    bool audioRetained = false,
  }) {
    return ops.scans.record(
      outcome(
        itemId: itemId,
        capturedAt: clock.now.subtract(Duration(minutes: minutesAgo)),
        quality: quality,
        reasons: reasons,
        classification: classification,
        confidence: confidence,
        modelVersion: modelVersion,
        experimental: experimental,
        audioRetained: audioRetained,
      ),
    );
  }

  /// Records a scan outcome captured at [at]. A real [classification] gets
  /// a confidence and [modelVersion] (default `test-model-1`).
  Future<ScanRecord> recordScanAt(
    String itemId,
    DateTime at, {
    ScanQuality quality = ScanQuality.pass,
    List<QualityReason> reasons = const [],
    Classification classification = Classification.notEvaluated,
    String? modelVersion,
  }) {
    final real = classification != Classification.notEvaluated;
    return ops.scans.record(
      outcome(
        itemId: itemId,
        capturedAt: at,
        quality: quality,
        reasons: reasons,
        classification: classification,
        confidence: real ? 0.8 : null,
        modelVersion: modelVersion ?? (real ? 'test-model-1' : noModelVersion),
      ),
    );
  }

  Future<Lot> addLot({String code = 'LOT-A'}) => ops.lots.create(
    LotDraft(
      code: code,
      grainType: 'Wheat',
      declaredQuantity: 500,
      quantityUnit: 'kg',
      receivedAt: DateTime.utc(2026, 9, 20),
      supplierName: 'Supplier',
    ),
  );

  Future<Location> addLocation(
    String name, {
    LocationType type = LocationType.warehouse,
    String? parentId,
  }) => ops.locations.create(
    LocationDraft(type: type, name: name, parentId: parentId),
  );

  /// Saves a sighting observed [minutesAgo] before the clock's now.
  Future<Sighting> addSighting({
    Role role = Role.household,
    SignalSource source = SignalSource.camera,
    int minutesAgo = 0,
    String? locationId,
    String? itemId,
    bool userValidated = true,
    String? cardId = 'german_cockroach',
    SafetyLevel safety = SafetyLevel.caution,
    bool withAnalysis = true,
    SoundAnalysis? sound,
    DistanceEstimate? distance,
    String? userCardId,
    String? notes,
    String? mediaPath,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
  }) => ops.sightings.create(
    SightingDraft(
      role: role,
      source: source,
      observedAt: clock.now.subtract(Duration(minutes: minutesAgo)),
      userValidated: userValidated,
      locationId: locationId,
      itemId: itemId,
      analysis: withAnalysis
          ? pestAnalysis(cardId: cardId, safety: safety, source: source)
          : null,
      sound: sound,
      distance: distance,
      userCardId: userCardId,
      notes: notes,
      mediaPath: mediaPath,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
    ),
  );

  /// Pairs a node (test values; the fingerprint is a placeholder).
  Future<SensorNode> addNode({
    String id = 'node-1',
    String address = 'C0:FF:EE:00:00:01',
    String name = 'Kitchen node',
    SensorType type = SensorType.usAir,
    String? locationId,
    String? itemId,
  }) => ops.sensorNodes.upsert(
    SensorNode(
      id: id,
      deviceAddress: address,
      name: name,
      type: type,
      protocolVersion: 1,
      firmwareVersion: '0.1.0',
      keyFingerprint: '0a1b2c3d',
      locationId: locationId,
      itemId: itemId,
      createdAt: clock.now,
      updatedAt: clock.now,
      syncState: SyncState.localOnly,
    ),
  );

  /// A valid scan from a (test-only) model version.
  Future<ScanRecord> recordModelScan(
    String itemId,
    Classification classification, {
    int minutesAgo = 0,
    String modelVersion = 'test-model-1',
  }) {
    return recordScan(
      itemId,
      minutesAgo: minutesAgo,
      classification: classification,
      confidence: 0.8,
      modelVersion: modelVersion,
    );
  }
}

/// Builds a ScanOutcome as the engine would hand it over.
ScanOutcome outcome({
  required String itemId,
  String? scanId,
  DateTime? capturedAt,
  ScanQuality quality = ScanQuality.pass,
  List<QualityReason> reasons = const [],
  Classification classification = Classification.notEvaluated,
  double? confidence,
  String modelVersion = noModelVersion,
  bool experimental = true,
  bool audioRetained = false,
}) {
  return ScanOutcome(
    audioRetained: audioRetained,
    scanId: scanId ?? const Uuid().v4(),
    itemId: itemId,
    capturedAt: capturedAt ?? DateTime.utc(2026, 10, 1, 8),
    quality: quality,
    qualityReasons: reasons,
    classification: classification,
    confidence: confidence,
    experimental: experimental,
    modelVersion: modelVersion,
    latencyMs: 120,
    durationMs: 2000,
    sampleRate: 16000,
    deviceModel: 'test-device',
    osVersion: 'Android 16 (SDK 36)',
  );
}

/// A database file that outlives one DataOperations, to simulate an app
/// restart. Close every harness using it before [close].
class TestDatabase {
  TestDatabase._(this._dir);

  factory TestDatabase.shared() =>
      TestDatabase._(Directory.systemTemp.createTempSync('kernel_db_'));

  final Directory _dir;

  QueryExecutor connection() =>
      NativeDatabase(File(p.join(_dir.path, 'kernel.sqlite')));

  Future<void> close() => _dir.delete(recursive: true);
}

/// A Pest ID analysis as the on-device analyzer would hand it over.
PestAnalysis pestAnalysis({
  String? cardId = 'german_cockroach',
  String commonName = 'German cockroach',
  SafetyLevel safety = SafetyLevel.caution,
  SignalSource source = SignalSource.camera,
  double aiConfidence = 0.7,
  double agreement = 0.6,
  int samples = 5,
  bool experimental = true,
}) => PestAnalysis(
  analysisId: const Uuid().v4(),
  createdAt: DateTime.utc(2026, 10, 1, 7, 59),
  source: source,
  cardId: cardId,
  commonName: commonName,
  group: PestGroup.insect,
  taxonomyPath: const ['Insect', 'Cockroach', 'German cockroach'],
  aiConfidence: aiConfidence,
  agreement: agreement,
  samples: samples,
  keyFeatures: const ['two dark stripes'],
  anomalies: const [],
  insights: const ['seen near food'],
  safety: safety,
  modelVersion: 'gemma-test-e2b',
  promptVersion: 'pest-prompt-test-1',
  latencyMs: 900,
  experimental: experimental,
);

/// A sensor event as sensor-link would hand it over.
SensorEvent sensorEvent({
  String nodeId = 'node-1',
  required int seq,
  required DateTime startedAt,
  int durationMs = 40,
  String? signatureId = 'mouse_usv',
  double score = 0.8,
  SensorEventClass eventClass = SensorEventClass.fmSweep,
}) => SensorEvent(
  nodeId: nodeId,
  seq: seq,
  startedAt: startedAt,
  durationMs: durationMs,
  eventClass: eventClass,
  peakHz: 70000,
  minHz: 60000,
  maxHz: 80000,
  slopeHzPerMs: -150,
  snrDb: 14,
  peakDbfs: -32,
  impulses: 0,
  repRateHz: 0,
  harmonics: 1,
  match: signatureId == null
      ? null
      : SignatureMatch(
          signatureId: signatureId,
          packVersion: 'sig-pack-test-0.1',
          score: score,
        ),
);

/// Test-double embedder: maps text onto a few fixed "concept" axes by
/// keyword, so semantic results are predictable. Calls are counted, and it
/// can be switched off or made to fail.
class ConceptEmbedder implements Embedder {
  ConceptEmbedder({this.version = 'embed-test-1'});

  String? version;
  bool available = true;
  bool failing = false;

  /// When true, document embeddings return null (busy model).
  bool refuseDocuments = false;
  int documentCalls = 0;
  int queryCalls = 0;

  static const concepts = <List<String>>[
    ['cockroach', 'roach', 'oothecae', 'pepper-like'],
    ['rat', 'rodent', 'gnaw', 'burrow', 'whisker'],
    ['scorpion', 'sting', 'pincer'],
    ['lizard', 'monitor', 'reptile', 'scales'],
  ];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> modelVersion() async => version;

  @override
  Future<EmbeddingVector?> embedText(
    String text, {
    EmbeddingTask task = EmbeddingTask.searchQuery,
    int dim = 256,
  }) async {
    if (failing) throw StateError('embedder failed');
    if (task == EmbeddingTask.searchDocument) {
      documentCalls++;
      if (refuseDocuments) return null;
    } else {
      queryCalls++;
    }
    final lower = text.toLowerCase();
    final values = Float32List(dim);
    for (var c = 0; c < concepts.length; c++) {
      for (final word in concepts[c]) {
        if (lower.contains(word)) values[c] += 1;
      }
    }
    // A small constant axis keeps unrelated texts from being all zeros.
    values[dim - 1] = 0.1;
    var norm = 0.0;
    for (final v in values) {
      norm += v * v;
    }
    norm = norm == 0 ? 1 : math.sqrt(norm);
    for (var i = 0; i < dim; i++) {
      values[i] = values[i] / norm;
    }
    return EmbeddingVector(values: values, modelVersion: version ?? '');
  }

  @override
  Future<EmbeddingVector?> embedImage(
    Uint8List encodedImage, {
    int dim = 256,
  }) async => null;

  @override
  Future<EmbeddingVector?> embedAudio(Uint8List wav, {int dim = 256}) async =>
      null;
}

/// First value of [stream] that satisfies [test].
Future<T> firstWhere<T>(Stream<T> stream, bool Function(T value) test) =>
    stream.firstWhere(test).timeout(const Duration(seconds: 5));

final isUuid = matches(
  RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ),
);

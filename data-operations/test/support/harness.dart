// Test-only doubles and fixtures. Never imported from lib/.
import 'dart:io';

import 'package:data_operations/data_operations.dart';
import 'package:drift/drift.dart' show QueryExecutor, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';
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
}

/// A DataOperations over an in-memory (or given) database with test doubles.
class Harness {
  Harness._(this.ops, this.scheduler, this.clock, this.reportDir);

  static Future<Harness> create({
    QueryExecutor? executor,
    TestClock? clock,
    RetainedAudioDeleter? deleteRetainedAudio,
  }) async {
    // Some tests deliberately open a second database (app restart).
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final testClock = clock ?? TestClock(DateTime.utc(2026, 10, 1, 8));
    final scheduler = FakeReminderScheduler();
    final reportDir = await Directory.systemTemp.createTemp('kernel_reports_');
    final ops = DataOperations(
      executor: executor ?? NativeDatabase.memory(),
      reminderScheduler: scheduler,
      reportDirectory: reportDir,
      clock: testClock.call,
      deleteRetainedAudio: deleteRetainedAudio,
    );
    return Harness._(ops, scheduler, testClock, reportDir);
  }

  final DataOperations ops;
  final FakeReminderScheduler scheduler;
  final TestClock clock;
  final Directory reportDir;

  Future<void> dispose() async {
    await ops.close();
    if (reportDir.existsSync()) await reportDir.delete(recursive: true);
  }

  Future<GrainItem> addItem({
    Role role = Role.farmer,
    String label = 'Sack R-001',
    String grainType = 'Wheat',
    double quantity = 50,
    String unit = 'kg',
    String? locationId,
    String? lotId,
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
      ),
    );
  }

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
}) {
  return ScanOutcome(
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

/// First value of [stream] that satisfies [test].
Future<T> firstWhere<T>(Stream<T> stream, bool Function(T value) test) =>
    stream.firstWhere(test).timeout(const Duration(seconds: 5));

final isUuid = matches(
  RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ),
);

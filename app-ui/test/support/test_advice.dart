// Test-only doubles for the on-phone AI assistant (AdviceEngine and
// AdviceModelManager). They stream scripted AdviceText; no model runs.

import 'dart:async';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'changes.dart';

const testAdviceModelVersion = 'gemma-test-1';

const testAdviceModel = AdviceModelInfo(
  id: 'gemma-4-E2B-it',
  version: testAdviceModelVersion,
  sizeBytes: 2590000000,
  backend: 'gpu',
);

/// Growing AdviceText events, one per part. The last is complete unless
/// [complete] is false (which the UI must treat as "use static copy").
List<AdviceText> adviceEvents(
  List<String> parts, {
  bool complete = true,
  String modelVersion = testAdviceModelVersion,
  String? languageTag = 'en',
}) {
  final events = <AdviceText>[];
  var text = '';
  for (final (i, part) in parts.indexed) {
    text = text.isEmpty ? part : '$text $part';
    events.add(
      AdviceText(
        text: text,
        complete: complete && i == parts.length - 1,
        modelVersion: modelVersion,
        languageTag: languageTag,
        generatedAt: DateTime.utc(2026, 10, 10, 9),
      ),
    );
  }
  return events;
}

class ScriptedAdviceEngine implements AdviceEngine {
  AdviceStatus _status = AdviceStatus.noModel;
  final _changes = Changes();
  AdviceModelInfo? info;

  AdviceStatus get status => _status;
  set status(AdviceStatus value) {
    _status = value;
    _changes.notify();
  }

  List<AdviceText> explainScript = const [];
  List<AdviceText> narrativeScript = const [];
  List<AdviceText> reminderScript = const [];

  /// When set, the matching request streams from it instead of the script,
  /// so a test can hold generation open.
  StreamController<AdviceText>? explainController;
  StreamController<AdviceText>? narrativeController;

  final explainCalls = <(ResultAdviceInput, String?)>[];
  final narrativeCalls = <(ReportNarrativeInput, String?)>[];
  final reminderCalls = <(ReminderAdviceInput, String?)>[];

  @override
  Stream<AdviceStatus> watchStatus() => _changes.watch(() => _status);

  @override
  Future<AdviceModelInfo?> modelInfo() async => info;

  @override
  Stream<AdviceText> explainResult(
    ResultAdviceInput input, {
    String? languageTag,
  }) {
    explainCalls.add((input, languageTag));
    return explainController?.stream ?? Stream.fromIterable(explainScript);
  }

  @override
  Stream<AdviceText> draftReportNarrative(
    ReportNarrativeInput input, {
    String? languageTag,
  }) {
    narrativeCalls.add((input, languageTag));
    return narrativeController?.stream ?? Stream.fromIterable(narrativeScript);
  }

  @override
  Stream<AdviceText> suggestReminderText(
    ReminderAdviceInput input, {
    String? languageTag,
  }) {
    reminderCalls.add((input, languageTag));
    return Stream.fromIterable(reminderScript);
  }
}

class ScriptedAdviceModelManager implements AdviceModelManager {
  ScriptedAdviceModelManager({this.onDone, this.onDelete});

  int freeSpace = 8000000000;
  List<ModelImportProgress> importScript = const [];

  /// When set, imports stream from it so a test can show progress.
  StreamController<ModelImportProgress>? importController;
  final importedUris = <String>[];
  int deleteCalls = 0;
  int freeSpaceCalls = 0;

  /// Runs after a scripted import reaches [ModelImportPhase.done].
  void Function()? onDone;
  void Function()? onDelete;

  @override
  Stream<ModelImportProgress> importFromUri(String contentUri) {
    importedUris.add(contentUri);
    final source =
        importController?.stream ?? Stream.fromIterable(importScript);
    return source.map((p) {
      if (p.phase == ModelImportPhase.done) onDone?.call();
      return p;
    });
  }

  @override
  Future<void> deleteModel() async {
    deleteCalls++;
    onDelete?.call();
  }

  @override
  Future<int> freeSpaceBytes() async {
    freeSpaceCalls++;
    return freeSpace;
  }
}

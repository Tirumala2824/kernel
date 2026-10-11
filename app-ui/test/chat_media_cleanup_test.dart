import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/agents/agents.dart';
import 'package:kernel_app/features/chat/chat_copy.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'chat_screen_test.dart'
    show ControlledChat, ControlledPicker, pumpChat, chooseAudio;

class PendingMediaPicker extends ControlledPicker {
  final result = Completer<PickedMedia?>();
  @override
  Future<PickedMedia?> pickAudioFile({
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
  }) => result.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late File original;
  late Map<String, File> nativeLeases;
  const channel = MethodChannel('com.kernel.sense_ai/chat_media');

  PickedMedia owned(String name, {String type = 'audio'}) {
    final file = File('${root.path}/owned-$name')..writeAsBytesSync([1, 2, 3]);
    nativeLeases[name] = file;
    return PickedMedia(
      path: file.path,
      fileName: name,
      mediaType: type,
      bytes: Uint8List(type == 'image' ? 3 : 0),
      ownershipToken: name,
    );
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('chat-media-test-');
    original = File('${root.path}/original.wav')..writeAsBytesSync([1, 2, 3]);
    nativeLeases = {};
    // The native boundary is mocked, not Dart's ownership or UI lifecycle.
    // Real canonical containment/stream/deletion rules are JVM file tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'release');
          final file = nativeLeases.remove((call.arguments as Map)['token']);
          if (file != null && file.existsSync()) file.deleteSync();
          return null;
        });
  });
  tearDown(() {
    expect(original.existsSync(), isTrue, reason: 'User source is never owned');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    root.deleteSync(recursive: true);
  });

  testWidgets(
    'replacement removal cancellation and picker errors preserve originals',
    (tester) async {
      final first = owned('first.wav');
      final second = owned('second.wav');
      final picker = ControlledPicker()..audio = first;
      await pumpChat(tester, ControlledChat(), picker: picker);
      await chooseAudio(tester);
      picker.audio = null;
      await chooseAudio(tester);
      expect(File(first.path).existsSync(), isTrue);
      picker.fail = true;
      await chooseAudio(tester);
      expect(File(first.path).existsSync(), isTrue);
      picker
        ..fail = false
        ..audio = second;
      await chooseAudio(tester);
      expect(File(first.path).existsSync(), isFalse);
      expect(File(second.path).existsSync(), isTrue);
      await tester.tap(find.byTooltip('${ChatCopy.remove} second.wav'));
      await tester.pumpAndSettle();
      expect(File(second.path).existsSync(), isFalse);
    },
  );

  testWidgets(
    'retry keeps one owned copy then releases after its only attempt',
    (tester) async {
      final media = owned('retry.wav');
      final picker = ControlledPicker()..audio = media;
      final agent = ControlledChat()
        ..response = const OrchestratorResponse(retryable: true);
      await pumpChat(tester, agent, picker: picker);
      await chooseAudio(tester);
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(File(media.path).existsSync(), isTrue);
      expect(find.text(ChatCopy.retry), findsOneWidget);
      await tester.tap(find.text(ChatCopy.retry));
      await tester.pumpAndSettle();
      expect(agent.tasks, hasLength(2));
      expect(find.text(ChatCopy.retry), findsNothing);
      expect(File(media.path).existsSync(), isFalse);
    },
  );

  testWidgets('retry expires and a stale callback cannot reuse deleted media', (
    tester,
  ) async {
    final media = owned('expiry.wav');
    final picker = ControlledPicker()..audio = media;
    final agent = ControlledChat()
      ..response = const OrchestratorResponse(retryable: true);
    await pumpChat(tester, agent, picker: picker);
    await chooseAudio(tester);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    final stale = tester
        .widget<TextButton>(find.widgetWithText(TextButton, ChatCopy.retry))
        .onPressed!;
    await tester.pump(const Duration(minutes: 5));
    await tester.pumpAndSettle();
    expect(File(media.path).existsSync(), isFalse);
    stale();
    await tester.pumpAndSettle();
    expect(agent.tasks, hasLength(1));
  });

  testWidgets(
    'new turn releases previous retry without sweeping pending media',
    (tester) async {
      final previous = owned('previous.wav');
      final next = owned('next.wav');
      final picker = ControlledPicker()..audio = previous;
      final agent = ControlledChat()
        ..response = const OrchestratorResponse(retryable: true);
      await pumpChat(tester, agent, picker: picker);
      await chooseAudio(tester);
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      picker.audio = next;
      await chooseAudio(tester);
      final pending = Completer<OrchestratorResponse>();
      agent.pending = pending;
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(File(previous.path).existsSync(), isFalse);
      expect(File(next.path).existsSync(), isTrue);
      pending.complete(const OrchestratorResponse());
      await tester.pumpAndSettle();
      expect(File(next.path).existsSync(), isFalse);
    },
  );

  testWidgets('confirmed clear releases both retry and unsent photo', (
    tester,
  ) async {
    final audio = owned('clear.wav');
    final photo = owned('clear.jpg', type: 'image');
    final picker = ControlledPicker()
      ..audio = audio
      ..photo = photo;
    final agent = ControlledChat()
      ..response = const OrchestratorResponse(retryable: true);
    await pumpChat(tester, agent, picker: picker);
    await chooseAudio(tester);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.photo));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(ChatCopy.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.clear));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.cancel));
    await tester.pumpAndSettle();
    expect(File(audio.path).existsSync(), isTrue);
    expect(File(photo.path).existsSync(), isTrue);
    await tester.tap(find.byTooltip(ChatCopy.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.clear));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, ChatCopy.clear));
    await tester.pumpAndSettle();
    expect(File(audio.path).existsSync(), isFalse);
    expect(File(photo.path).existsSync(), isFalse);
  });

  testWidgets('clear rejects and releases a picker result arriving later', (
    tester,
  ) async {
    final media = owned('after-clear.wav');
    final picker = PendingMediaPicker();
    await pumpChat(tester, ControlledChat(), picker: picker);
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'a turn to clear',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    await chooseAudio(tester);
    await tester.tap(find.byTooltip(ChatCopy.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.clear));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, ChatCopy.clear));
    await tester.pumpAndSettle();
    picker.result.complete(media);
    await tester.pumpAndSettle();
    expect(File(media.path).existsSync(), isFalse);
    expect(find.text('after-clear.wav'), findsNothing);
  });

  testWidgets('late picker result after disposal is released', (tester) async {
    final media = owned('late.wav');
    final picker = PendingMediaPicker();
    await pumpChat(tester, ControlledChat(), picker: picker);
    await chooseAudio(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    picker.result.complete(media);
    await tester.pumpAndSettle();
    expect(File(media.path).existsSync(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposal releases pending turn and unsent draft media', (
    tester,
  ) async {
    final media = owned('pending.wav');
    final picker = ControlledPicker()..audio = media;
    final pending = Completer<OrchestratorResponse>();
    final agent = ControlledChat()..pending = pending;
    await pumpChat(tester, agent, picker: picker);
    await chooseAudio(tester);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(File(media.path).existsSync(), isFalse);
    pending.complete(const OrchestratorResponse(retryable: true));
    await tester.pumpAndSettle();
    final draft = owned('draft.wav');
    await pumpChat(
      tester,
      ControlledChat(),
      picker: ControlledPicker()..audio = draft,
    );
    await chooseAudio(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(File(draft.path).existsSync(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed audio turn deletes its owned copy only', (
    tester,
  ) async {
    final media = owned('field.wav');
    final picker = ControlledPicker()..audio = media;
    await pumpChat(tester, ControlledChat(), picker: picker);
    await chooseAudio(tester);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(File(media.path).existsSync(), isFalse);
    expect(find.text('field.wav'), findsOneWidget);
  });
}

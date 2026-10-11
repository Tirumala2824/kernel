import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kernel_app/agents/agents.dart';
import 'package:kernel_app/app/providers.dart';
import 'package:kernel_app/features/chat/chat_copy.dart';
import 'package:kernel_app/features/chat/kernel_chat_screen.dart';
import 'package:kernel_app/l10n/l10n.dart';
import 'package:kernel_app/theme/kernel_theme.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/chat_fixtures.dart';

class ControlledChat extends OrchestratorAgent {
  final tasks = <OrchestratorTask>[];
  Completer<OrchestratorResponse>? pending;
  bool failFirst = false;
  OrchestratorResponse response = const OrchestratorResponse(
    notices: {ChatNotice.noKnowledge},
  );
  @override
  Future<OrchestratorResponse> execute(OrchestratorTask task) async {
    tasks.add(task);
    if (failFirst && tasks.length == 1) throw StateError('/private/test-path');
    return pending == null ? response : await pending!.future;
  }
}

class ControlledPicker extends MediaPickerService {
  PickedMedia? audio;
  PickedMedia? photo;
  bool fail = false;
  int audioCalls = 0;
  @override
  Future<PickedMedia?> pickAudioFile({
    SensorType sensorType = SensorType.audioAir,
    String? sensorNodeId,
  }) async {
    audioCalls++;
    if (fail) throw StateError('test picker error');
    return audio;
  }

  @override
  Future<PickedMedia?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (fail) throw StateError('test picker error');
    return photo;
  }
}

Future<void> pumpChat(
  WidgetTester tester,
  ControlledChat agent, {
  ControlledPicker? picker,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orchestratorAgentProvider.overrideWithValue(agent),
        if (picker != null)
          mediaPickerServiceProvider.overrideWithValue(picker),
      ],
      child: MaterialApp(
        theme: buildKernelTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const KernelChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> chooseAudio(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('chat-attach')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(ChatCopy.audio));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('new recording clears stale photo follow-up context', (
    tester,
  ) async {
    final agent = ControlledChat()
      ..response = OrchestratorResponse(analysis: chatAnalysis());
    final picker = ControlledPicker()
      ..photo = chatPhoto()
      ..audio = chatAudio();
    await pumpChat(tester, agent, picker: picker);
    await tester.tap(find.byKey(const Key('chat-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.photo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    agent.response = const OrchestratorResponse(
      notices: {ChatNotice.audioUnavailable},
    );
    await chooseAudio(tester);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'what about that recording?',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(agent.tasks.last.contextAnalysis, isNull);
  });

  testWidgets('long multiline draft remains usable above a small keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final picker = ControlledPicker()
      ..audio = chatAudio()
      ..photo = chatPhoto();
    await pumpChat(tester, ControlledChat(), picker: picker);
    await chooseAudio(tester);
    await tester.tap(find.byKey(const Key('chat-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.photo));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      List.filled(8, 'Long draft').join('\n'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final send = tester.getRect(find.byKey(const Key('chat-send')));
    expect(send.bottom, lessThanOrEqualTo(400));
  });

  testWidgets('a reply does not move a reader away from earlier turns', (
    tester,
  ) async {
    final agent = ControlledChat();
    await pumpChat(tester, agent);
    for (var i = 0; i < 8; i++) {
      await tester.enterText(
        find.byKey(const Key('chat-input')),
        'Question $i ${List.filled(20, 'storage').join(' ')}',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
    }
    final gate = Completer<OrchestratorResponse>();
    agent.pending = gate;
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'last question',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    final scroll = tester
        .widget<ListView>(find.byKey(const Key('chat-transcript')))
        .controller!;
    expect(scroll.position.maxScrollExtent, greaterThan(120));
    scroll.jumpTo(0);
    await tester.pump();
    gate.complete(
      const OrchestratorResponse(notices: {ChatNotice.noKnowledge}),
    );
    await tester.pumpAndSettle();
    expect(scroll.offset, 0);
  });

  testWidgets('expired retry callback cannot resubmit released media', (
    tester,
  ) async {
    final agent = ControlledChat()..failFirst = true;
    await pumpChat(tester, agent);
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'failed question',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    final stale = tester
        .widget<TextButton>(find.widgetWithText(TextButton, ChatCopy.retry))
        .onPressed!;
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'another question',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(agent.tasks, hasLength(2));
  });

  testWidgets('notebook header aligns with its bounded reading column', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpChat(tester, ControlledChat());
    final list = tester.getRect(find.byKey(const Key('chat-transcript')));
    final title = tester.getRect(find.text(ChatCopy.title));
    final empty = tester.getRect(find.text(ChatCopy.emptyTitle));
    expect(list.width, 760);
    expect(title.left, list.left + 20);
    expect(empty.left, title.left);
    expect(empty.top - tester.getRect(find.byType(AppBar)).bottom, 32);
    expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 60);
  });

  testWidgets('oversized failed media is not retained for retry', (
    tester,
  ) async {
    final picker = ControlledPicker()
      ..audio = PickedMedia(
        path: '/test/large.wav',
        fileName: 'large.wav',
        mediaType: 'audio',
        bytes: Uint8List(24 * 1024 * 1024 + 1),
      );
    await pumpChat(tester, ControlledChat()..failFirst = true, picker: picker);
    await chooseAudio(tester);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text(ChatCopy.retry), findsNothing);
    expect(find.text(ChatCopy.retryExpired), findsOneWidget);
    expect(find.text('large.wav'), findsOneWidget);
  });

  testWidgets('starting another turn releases the previous retry', (
    tester,
  ) async {
    final agent = ControlledChat()..failFirst = true;
    final picker = ControlledPicker()..audio = chatAudio();
    await pumpChat(tester, agent, picker: picker);
    await chooseAudio(tester);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text(ChatCopy.retry), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'a new request',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text(ChatCopy.retry), findsNothing);
    expect(find.text('grain.wav'), findsOneWidget);
    expect(
      find.text('Reattach files or resend your message to try again.'),
      findsOneWidget,
    );
  });

  testWidgets('phone layout supports large text and keyboard', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final name = '${List.filled(180, 'x').join()}.wav';
    final picker = ControlledPicker()..audio = chatAudio(name: name);
    await pumpChat(tester, ControlledChat(), picker: picker);
    await chooseAudio(tester);
    expect(tester.takeException(), isNull);
    final send = tester.getSize(find.byKey(const Key('chat-send')));
    expect(send.width, greaterThanOrEqualTo(48));
    expect(send.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byTooltip('${ChatCopy.remove} $name'));
    await tester.pumpAndSettle();
    expect(find.text(name), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('clear requires confirmation and affects only chat', (
    tester,
  ) async {
    await pumpChat(tester, ControlledChat());
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'keep until confirmed',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(ChatCopy.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.clear));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.cancel));
    await tester.pumpAndSettle();
    expect(find.text('keep until confirmed'), findsOneWidget);
    await tester.tap(find.byTooltip(ChatCopy.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ChatCopy.clear));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, ChatCopy.clear));
    await tester.pumpAndSettle();
    expect(find.text(ChatCopy.emptyTitle), findsOneWidget);
    expect(find.text('keep until confirmed'), findsNothing);
  });
  testWidgets('audio selection submits without sensor setup', (tester) async {
    final picker = ControlledPicker()..audio = chatAudio();
    final agent = ControlledChat();
    await pumpChat(tester, agent, picker: picker);
    await chooseAudio(tester);
    expect(picker.audioCalls, 1);
    expect(find.textContaining('Transducer'), findsNothing);
    expect(find.text('grain.wav'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(agent.tasks.single.audioMedia, same(picker.audio));
    expect(agent.tasks.single.userMessage, isEmpty);
    expect(find.text('grain.wav'), findsOneWidget);
  });
  testWidgets('picker failure is visible and cancellation is silent', (
    tester,
  ) async {
    final picker = ControlledPicker()..fail = true;
    final agent = ControlledChat();
    await pumpChat(tester, agent, picker: picker);
    await chooseAudio(tester);
    expect(find.text(ChatCopy.pickerError), findsOneWidget);
    picker.fail = false;
    await chooseAudio(tester);
    expect(find.text(ChatCopy.pickerError), findsNothing);
    expect(agent.tasks, isEmpty);
    expect(find.text(ChatCopy.emptyTitle), findsOneWidget);
  });
  testWidgets('failed request retries without duplicating the user turn', (
    tester,
  ) async {
    final agent = ControlledChat()..failFirst = true;
    await pumpChat(tester, agent);
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'my unique question',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('/private/test-path'), findsNothing);
    await tester.tap(find.text(ChatCopy.retry));
    await tester.pumpAndSettle();
    expect(agent.tasks, hasLength(2));
    expect(agent.tasks[0], same(agent.tasks[1]));
    expect(find.text('my unique question'), findsOneWidget);
    expect(find.text(ChatCopy.retry), findsNothing);
  });
  testWidgets('reply after disposal does not call setState', (tester) async {
    final gate = Completer<OrchestratorResponse>();
    await pumpChat(tester, ControlledChat()..pending = gate);
    await tester.enterText(find.byKey(const Key('chat-input')), 'storage');
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete(const OrchestratorResponse());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('pending submission cannot be duplicated', (tester) async {
    final gate = Completer<OrchestratorResponse>();
    final agent = ControlledChat()..pending = gate;
    await pumpChat(tester, agent);
    await tester.enterText(find.byKey(const Key('chat-input')), 'storage');
    await tester.pump();
    final submit = tester
        .widget<IconButton>(find.byKey(const Key('chat-send')))
        .onPressed!;
    submit();
    await tester.pump();
    await tester.enterText(find.byKey(const Key('chat-input')), 'next draft');
    submit();
    await tester.pump();
    expect(agent.tasks, hasLength(1));
    expect(find.text(ChatCopy.working), findsOneWidget);
    await tester.enterText(find.byKey(const Key('chat-input')), 'next draft');
    gate.complete(
      const OrchestratorResponse(notices: {ChatNotice.noKnowledge}),
    );
    await tester.pumpAndSettle();
    expect(find.text(ChatCopy.working), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-input')))
          .controller!
          .text,
      'next draft',
    );
  });
  testWidgets('blank send is disabled', (tester) async {
    final agent = ControlledChat();
    await pumpChat(tester, agent);
    await tester.enterText(find.byKey(const Key('chat-input')), '   ');
    await tester.pump();
    final send = tester.widget<IconButton>(find.byKey(const Key('chat-send')));
    expect(send.onPressed, isNull);
    expect(agent.tasks, isEmpty);
  });
  testWidgets('empty chat is a composer, not a dashboard', (tester) async {
    await pumpChat(tester, ControlledChat());
    expect(find.text(ChatCopy.emptyTitle), findsOneWidget);
    expect(find.byKey(const Key('chat-input')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.textContaining('Welcome to Kernel Autonomous'), findsNothing);
    expect(find.byIcon(Icons.mic), findsNothing);
    expect(find.byIcon(Icons.videocam), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

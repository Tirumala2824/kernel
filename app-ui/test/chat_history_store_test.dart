import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/features/chat/chat_history_store.dart';

void main() {
  late Directory directory;
  late ChatHistoryStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kernel-chat-history-');
    store = ChatHistoryStore(File('${directory.path}${Platform.pathSeparator}history.json'));
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('persists and restores only text, speaker, ID, and timestamp', () async {
    final timestamp = DateTime.utc(2026, 10, 11, 8, 0);
    await store.save([
      StoredChatMessage(
        id: 'user-1',
        isUser: true,
        text: 'Please inspect this image.',
        timestamp: timestamp,
      ),
      StoredChatMessage(
        id: 'assistant-1',
        isUser: false,
        text: 'No constrained model label was returned.',
        timestamp: timestamp.add(const Duration(seconds: 1)),
      ),
    ]);

    final restored = await store.load();
    expect(restored, hasLength(2));
    expect(restored.first.text, 'Please inspect this image.');
    expect(restored.first.isUser, isTrue);
    expect(restored.last.id, 'assistant-1');
    final raw = await store.file.readAsString();
    expect(raw, isNot(contains('bytes')));
    expect(raw, isNot(contains('filePath')));
  });

  test('bounds retained messages to the latest 200', () async {
    await store.save([
      for (var i = 0; i < 205; i++)
        StoredChatMessage(
          id: 'm$i',
          isUser: i.isEven,
          text: 'message $i',
          timestamp: DateTime.utc(2026, 10, 11).add(Duration(seconds: i)),
        ),
    ]);

    final restored = await store.load();
    expect(restored, hasLength(200));
    expect(restored.first.id, 'm5');
    expect(restored.last.id, 'm204');
  });

  test('malformed history returns an empty transcript without crashing', () async {
    await store.file.parent.create(recursive: true);
    await store.file.writeAsString('{not-json');

    expect(await store.load(), isEmpty);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A text-only chat-history record. Media bytes and source paths are never
/// serialized, so file attachments remain ephemeral by default.
class StoredChatMessage {
  const StoredChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;

  Map<String, Object?> toJson() => {
    'id': id,
    'isUser': isUser,
    'text': text,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };

  static StoredChatMessage? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final isUser = value['isUser'];
    final text = value['text'];
    final timestamp = value['timestamp'];
    if (id is! String ||
        isUser is! bool ||
        text is! String ||
        timestamp is! String) {
      return null;
    }
    final parsed = DateTime.tryParse(timestamp);
    if (parsed == null) return null;
    return StoredChatMessage(
      id: id,
      isUser: isUser,
      text: text,
      timestamp: parsed.toLocal(),
    );
  }
}

/// Local-only bounded history in app-private support storage.
class ChatHistoryStore {
  ChatHistoryStore(this.file);

  final File file;
  static const maxMessages = 200;

  static Future<ChatHistoryStore> open() async {
    final directory = await getApplicationSupportDirectory();
    return ChatHistoryStore(
      File(
        '${directory.path}${Platform.pathSeparator}kernel_chat_history.json',
      ),
    );
  }

  Future<List<StoredChatMessage>> load() async {
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      final messages = decoded
          .map(StoredChatMessage.fromJson)
          .whereType<StoredChatMessage>()
          .toList();
      return messages.length <= maxMessages
          ? messages
          : messages.sublist(messages.length - maxMessages);
    } on Object {
      return const [];
    }
  }

  Future<void> save(Iterable<StoredChatMessage> messages) async {
    final bounded = messages.toList(growable: false);
    final recent = bounded.length <= maxMessages
        ? bounded
        : bounded.sublist(bounded.length - maxMessages);
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(recent.map((message) => message.toJson()).toList()),
    );
    await temporary.rename(file.path);
  }
}

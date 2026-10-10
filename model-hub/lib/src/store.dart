import 'dart:convert';
import 'dart:io';

/// Small JSON files in app-private storage (catalog cache, consent, registry
/// state, search vectors). Writes are atomic (temp file + rename).
class HubStore {
  /// [dir] is resolved once, lazily (the native side reports filesDir).
  HubStore(Future<Directory> Function() dir) : _dirProvider = dir;

  HubStore.at(Directory dir) : _dirProvider = (() async => dir);

  final Future<Directory> Function() _dirProvider;
  Future<Directory>? _dir;

  Future<File> _file(String name) async {
    final dir = await (_dir ??= _dirProvider());
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  Future<Map<String, Object?>?> readJson(String name) async {
    final text = await readText(name);
    if (text == null) return null;
    try {
      final v = jsonDecode(text);
      return v is Map<String, Object?> ? v : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> writeJson(String name, Object value) =>
      writeText(name, jsonEncode(value));

  Future<String?> readText(String name) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return null;
      return await f.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  Future<void> writeText(String name, String text) async {
    try {
      final f = await _file(name);
      await f.parent.create(recursive: true);
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(text, flush: true);
      await tmp.rename(f.path);
    } on FileSystemException {
      // A lost cache only costs a refetch or re-index.
    }
  }

  Future<void> delete(String name) async {
    try {
      final f = await _file(name);
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // Nothing to do.
    }
  }
}

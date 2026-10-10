// Shared fixtures exported by firmware/reference (python -m kernel_ref.export).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

final vectorsDir = Directory('../firmware/reference/vectors');

Map<String, dynamic> loadJson(String name) =>
    jsonDecode(File('${vectorsDir.path}/$name').readAsStringSync()) as Map<String, dynamic>;

List<File> detectFiles() =>
    vectorsDir.listSync().whereType<File>().where((f) => f.uri.pathSegments.last.startsWith('detect_')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));

Map<String, dynamic> loadFile(File f) => jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

Uint8List hex(String s) => Uint8List.fromList([for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)]);

String toHex(List<int> b) => b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();

String packText() => File('assets/signature_pack_v0_1.properties').readAsStringSync();

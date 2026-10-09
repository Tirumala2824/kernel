// Test-only CSV report parsing.
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:data_operations/src/reports/report_csv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parsed CSV report: preamble rows and the record table as header maps.
class ParsedCsv {
  ParsedCsv(this.preamble, this.header, this.rows);

  final List<List<String>> preamble;
  final List<String> header;
  final List<Map<String, String>> rows;

  List<Map<String, String>> ofType(String type) =>
      rows.where((r) => r['row_type'] == type).toList();

  /// Value of the preamble line whose first cell is [key].
  String preambleValue(String key) =>
      preamble.firstWhere((r) => r.isNotEmpty && r.first == key)[1];

  /// Every preamble value for [key] (e.g. all disclaimer lines).
  List<String> preambleValues(String key) => [
    for (final r in preamble)
      if (r.length > 1 && r.first == key) r[1],
  ];
}

Future<ParsedCsv> readCsv(String path) async {
  final bytes = await File(path).readAsBytes();
  expect(bytes.take(3), [0xEF, 0xBB, 0xBF], reason: 'UTF-8 BOM');
  final text = utf8.decode(bytes.sublist(3));
  final all = [
    for (final row in Csv(autoDetect: false).decode(text))
      [for (final cell in row) '$cell'],
  ];
  final headerIndex = all.indexWhere((r) => r.first == csvTableMarker);
  expect(headerIndex, greaterThan(0));
  final header = all[headerIndex];
  final rows = <Map<String, String>>[];
  for (final row in all.skip(headerIndex + 1)) {
    expect(row, hasLength(header.length), reason: 'every row is complete');
    rows.add({for (var i = 0; i < header.length; i++) header[i]: row[i]});
  }
  return ParsedCsv(all.sublist(0, headerIndex), header, rows);
}

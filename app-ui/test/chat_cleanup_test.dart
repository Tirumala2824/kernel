import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat has no dormant grain verdict or heuristic quality output', () {
    final coordinator = File('lib/agents/orchestrator_agent.dart')
        .readAsStringSync();
    final view = File('lib/features/chat/chat_response_view.dart')
        .readAsStringSync();
    final copy = File('lib/features/chat/chat_copy.dart').readAsStringSync();
    expect(coordinator, isNot(contains('ScanOutcome')));
    expect(view, isNot(contains('response.scan')));
    expect(copy, isNot(contains('proxy model')));
    expect(view, isNot(contains('calibratedConfidence')));
    expect(view, isNot(contains('qualityWeight')));
  });
}

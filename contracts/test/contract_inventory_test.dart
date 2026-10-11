import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('retired heuristic quality and fusion contracts are removed', () {
    final source = File('lib/src/agents/agent_models.dart').readAsStringSync();
    final retired = RegExp(
      'QualityBadge|AudioSignalQualityIndex|VisualQualityIndex|'
      'QualityWeightedVerdict|GroundedGuidanceReport|calibratedConfidence',
    );
    expect(retired.allMatches(source).map((match) => match.group(0)).toSet(), isEmpty);
    expect(source, contains('abstract interface class Agent<TTask, TReport>'));
  });
}

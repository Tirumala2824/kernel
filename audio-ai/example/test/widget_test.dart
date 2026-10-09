import 'package:audio_ai_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

void main() {
  testWidgets('developer screen shows the capture button and idle meter', (
    tester,
  ) async {
    await tester.pumpWidget(const DevScanApp());

    expect(find.byKey(const Key('capture')), findsOneWidget);
    expect(find.text('Capture 2 s'), findsOneWidget);
    expect(find.text('Level: no capture running'), findsOneWidget);
    expect(find.byKey(const Key('haptics')), findsOneWidget);
  });

  testWidgets('level meter renders a reading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LevelMeterView(
            level: CaptureLevel(
              elapsedMs: 500,
              targetMs: 2000,
              rmsDbfs: -45,
              peakDbfs: -30.5,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Progress 500 / 2000 ms'), findsOneWidget);
    expect(find.text('RMS  -45.0 dBFS'), findsOneWidget);
    expect(find.text('Peak -30.5 dBFS'), findsOneWidget);
    final bars = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .map((b) => b.value)
        .toList();
    expect(bars, [0.25, 0.5, closeTo(0.661, 0.001)]);
  });
}

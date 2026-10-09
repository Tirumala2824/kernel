import 'package:audio_ai_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('developer screen shows the capture button', (tester) async {
    await tester.pumpWidget(const DevScanApp());

    expect(find.byKey(const Key('capture')), findsOneWidget);
    expect(find.text('Capture 2 s'), findsOneWidget);
  });
}

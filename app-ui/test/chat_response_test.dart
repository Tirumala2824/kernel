import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/agents/orchestrator_agent.dart';
import 'package:kernel_app/features/chat/chat_response_view.dart';
import 'package:kernel_app/l10n/l10n.dart';
import 'package:kernel_app/theme/kernel_theme.dart';

import 'package:kernel_contracts/kernel_contracts.dart';

import 'support/chat_fixtures.dart';

Future<void> pumpResponse(
  WidgetTester tester,
  OrchestratorResponse response,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKernelTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChatResponseView(response: response),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'rejected sound explains actual reason without a placeholder model',
    (tester) async {
      await pumpResponse(
        tester,
        const OrchestratorResponse(
          sound: InsectSoundResult(
            status: InsectSoundStatus.rejected,
            reasons: ['low_level_or_silence'],
          ),
        ),
      );
      expect(
        find.text(
          'The recording is too quiet. Try a closer, clearer recording.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Status:'), findsNothing);
      expect(find.textContaining('Model: none'), findsNothing);
      expect(find.text('Insect sound: unknown'), findsNothing);
    },
  );

  testWidgets(
    'insect model limits are visible but revision is progressively disclosed',
    (tester) async {
      await pumpResponse(
        tester,
        const OrchestratorResponse(
          sound: InsectSoundResult(
            status: InsectSoundStatus.evaluated,
            level: InsectIdentificationLevel.group,
            label: 'Orthoptera (crickets/grasshoppers)',
            modelVersion: '0.1.0-experimental',
            modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
          ),
        ),
      );
      expect(
        find.textContaining(
          'cannot confirm hidden grain pests or detect ultrasound',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('001425d7fab4b44af5cc571174410f1c78552d0e'),
        findsNothing,
      );
      await tester.tap(find.text('Model details'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('001425d7fab4b44af5cc571174410f1c78552d0e'),
        findsOneWidget,
      );
    },
  );

  testWidgets('silent selected windows explain how to choose another recording', (tester) async {
    await pumpResponse(
      tester,
      const OrchestratorResponse(
        sound: InsectSoundResult(
          status: InsectSoundStatus.rejected,
          reasons: ['no_signal_in_selected_windows'],
        ),
      ),
    );
    expect(find.text('No usable sound was found in the analyzed sections. Try a shorter recording around the sound.'), findsOneWidget);
    expect(find.textContaining('Model: none'), findsNothing);
    expect(find.text('Insect sound: unknown'), findsNothing);
  });

  for (final level in InsectIdentificationLevel.values) {
    testWidgets('sound ${level.name} warns about closed-set false matches', (
      tester,
    ) async {
      await pumpResponse(
        tester,
        OrchestratorResponse(
          sound: InsectSoundResult(
            status: InsectSoundStatus.evaluated,
            level: level,
            label: level == InsectIdentificationLevel.unknown
                ? null
                : 'Test match',
            modelVersion: 'test-sound-v2',
            modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
          ),
        ),
      );
      expect(
        find.textContaining('AI-estimated — not calibrated'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Noise and non-insect sounds can also match'),
        findsOneWidget,
      );
      expect(
        find.textContaining('does not confirm an insect is present'),
        findsOneWidget,
      );
    });
  }

  for (final entry in {
    'platform_unavailable': 'Sound analysis is not supported on this platform.',
    'asset_integrity':
        'The bundled sound model is damaged. Update or reinstall the app.',
    'model_unavailable':
        'The bundled sound model is missing. Update or reinstall the app.',
    'runtime_unavailable': 'The sound engine cannot run on this device. An app update may be required.',
  }.entries) {
    testWidgets(
      'permanent sound failure ${entry.key} does not promise a later retry',
      (tester) async {
        await pumpResponse(
          tester,
          OrchestratorResponse(
            sound: InsectSoundResult(
              status: InsectSoundStatus.unavailable,
              reasons: [entry.key],
            ),
          ),
        );
        expect(find.text(entry.value), findsOneWidget);
        expect(find.textContaining('Try again later'), findsNothing);
      },
    );
  }

  testWidgets('real photo output and generated provenance stay distinct', (
    tester,
  ) async {
    await pumpResponse(
      tester,
      OrchestratorResponse(
        analysis: chatAnalysis(),
        generated: AdviceText(
          text: 'Real test response',
          complete: true,
          modelVersion: 'guide-v3',
          languageTag: 'en',
          generatedAt: DateTime.utc(2026),
        ),
        notices: {ChatNotice.audioUnavailable},
      ),
    );
    expect(
      find.text('Photo: Test weevil — AI-estimated, not calibrated'),
      findsOneWidget,
    );
    expect(find.text('Model: test-model — experimental'), findsOneWidget);
    expect(find.text('Real test response'), findsOneWidget);
    expect(
      find.text('Generated on this phone — experimental · guide-v3'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Audio analysis is unavailable'),
      findsOneWidget,
    );
    expect(find.textContaining('60%'), findsNothing);
  });
  for (final level in InsectIdentificationLevel.values) {
    testWidgets('sound preserves ${level.name} hierarchy without confidence', (
      tester,
    ) async {
      await pumpResponse(
        tester,
        OrchestratorResponse(
          sound: InsectSoundResult(
            status: InsectSoundStatus.evaluated,
            level: level,
            label: level == InsectIdentificationLevel.unknown
                ? null
                : 'Test match',
            topLabels: const [
              ScoredLabel(label: 'Do not promote this species', score: 0.99),
            ],
            modelVersion: 'test-sound-v2',
            modelRevision: '001425d7fab4b44af5cc571174410f1c78552d0e',
          ),
        ),
      );
      expect(
        find.text(
          'Experimental insect sound match — not a grain-pest diagnosis',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Status:'), findsNothing);
      final expected = level == InsectIdentificationLevel.unknown
          ? 'Insect sound: unknown'
          : 'Insect sound: Test match (${level.name})';
      expect(find.text(expected), findsOneWidget);
      expect(find.text('Model: test-sound-v2 — experimental'), findsOneWidget);
      expect(
        find.textContaining('001425d7fab4b44af5cc571174410f1c78552d0e'),
        findsNothing,
      );
      await tester.tap(find.text('Model details'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('001425d7fab4b44af5cc571174410f1c78552d0e'),
        findsOneWidget,
      );
      expect(find.textContaining('Do not promote'), findsNothing);
      expect(find.textContaining('99%'), findsNothing);
    });
  }
  for (final status in [
    InsectSoundStatus.rejected,
    InsectSoundStatus.unavailable,
  ]) {
    testWidgets('sound ${status.name} remains unknown', (tester) async {
      await pumpResponse(
        tester,
        OrchestratorResponse(
          sound: InsectSoundResult(
            status: status,
            reasons: const ['test-reason'],
          ),
        ),
      );
      expect(find.textContaining('Status:'), findsNothing);
      expect(find.text('Insect sound: unknown'), findsNothing);
      expect(find.textContaining('Model: none'), findsNothing);
      expect(
        find.text(
          status == InsectSoundStatus.rejected
              ? 'This recording could not be analyzed. Try another WAV recording.'
              : 'Sound analysis is unavailable right now. Try again later.',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('all card safety levels and sources remain visible', (
    tester,
  ) async {
    await pumpResponse(
      tester,
      OrchestratorResponse(
        cards: [
          chatCard(
            extraSafety: {SafetyLevel.venomous, SafetyLevel.protectedWildlife},
          ),
        ],
      ),
    );
    expect(find.byKey(const Key('pest-safety-venomous')), findsOneWidget);
    expect(
      find.byKey(const Key('pest-safety-protectedWildlife')),
      findsOneWidget,
    );
    expect(find.text('Needs expert review'), findsOneWidget);
    expect(
      find.text('From the local knowledge library — not a diagnosis'),
      findsOneWidget,
    );
    expect(find.byType(ExpansionTile), findsOneWidget);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    for (final source in chatCard().sources) {
      expect(find.text(source), findsOneWidget);
    }
  });
}

import 'package:flutter/material.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../l10n/l10n.dart';

// Localized labels for the Pest ID enums. Every word on screen comes from
// the ARB files.

extension SignalKindCopy on SignalKind {
  String label(AppLocalizations l) => switch (this) {
    SignalKind.motion => l.pestKindMotion,
    SignalKind.darkSpecks => l.pestKindSpecks,
    SignalKind.eyeshine => l.pestKindEyeshine,
    SignalKind.embeddingMatch => l.pestKindEmbedding,
    SignalKind.modelBox => l.pestKindModelBox,
    SignalKind.soundEvent => l.pestKindSound,
  };

  IconData get icon => switch (this) {
    SignalKind.motion => Icons.directions_run_rounded,
    SignalKind.darkSpecks => Icons.grain_rounded,
    SignalKind.eyeshine => Icons.visibility_rounded,
    SignalKind.embeddingMatch => Icons.image_search_rounded,
    SignalKind.modelBox => Icons.crop_free_rounded,
    SignalKind.soundEvent => Icons.graphic_eq_rounded,
  };
}

extension PestGroupCopy on PestGroup {
  String label(AppLocalizations l) => switch (this) {
    PestGroup.insect => l.pestGroupInsect,
    PestGroup.arachnid => l.pestGroupArachnid,
    PestGroup.rodent => l.pestGroupRodent,
    PestGroup.reptile => l.pestGroupReptile,
    PestGroup.other => l.pestGroupOther,
    PestGroup.notAPest => l.pestGroupNotAPest,
    PestGroup.unknown => l.pestGroupUnknown,
  };
}

extension SignalSourceCopy on SignalSource {
  String label(AppLocalizations l) => switch (this) {
    SignalSource.camera => l.pestSourceCamera,
    SignalSource.microphone => l.pestSourceMic,
    SignalSource.sensor => l.pestSourceSensor,
  };

  IconData get icon => switch (this) {
    SignalSource.camera => Icons.photo_camera_rounded,
    SignalSource.microphone => Icons.hearing_rounded,
    SignalSource.sensor => Icons.sensors_rounded,
  };
}

extension ListenModeCopy on ListenMode {
  String label(AppLocalizations l) => switch (this) {
    ListenMode.general => l.pestListenModeGeneral,
    ListenMode.mosquitoCloseUp => l.pestListenModeMosquito,
    ListenMode.night => l.pestListenModeNight,
  };

  String help(AppLocalizations l) => switch (this) {
    ListenMode.general => l.pestListenModeGeneralBody,
    ListenMode.mosquitoCloseUp => l.pestListenModeMosquitoBody,
    ListenMode.night => l.pestListenModeNightBody,
  };
}

/// The more serious of two safety levels (the enum is ordered).
SafetyLevel moreSerious(SafetyLevel a, SafetyLevel? b) =>
    b == null || a.index >= b.index ? a : b;

/// Card name in the app language, falling back to English.
String cardName(KnowledgeCard card, String languageTag) =>
    card.names[languageTag] ?? card.names['en'] ?? card.id;

/// Whole percent for a 0..1 value, clamped.
int percentOf(double value) => (value.clamp(0.0, 1.0) * 100).round();

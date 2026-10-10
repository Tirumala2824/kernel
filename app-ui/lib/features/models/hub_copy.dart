import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/copy.dart';
import '../../l10n/l10n.dart';
import 'hub_providers.dart';

extension ModelCapabilityCopy on ModelCapability {
  String label(AppLocalizations l) => switch (this) {
    ModelCapability.textGen => l.hubCapTextGen,
    ModelCapability.imageIn => l.hubCapImageIn,
    ModelCapability.audioIn => l.hubCapAudioIn,
    ModelCapability.embedText => l.hubCapEmbedText,
    ModelCapability.embedImage => l.hubCapEmbedImage,
    ModelCapability.embedAudio => l.hubCapEmbedAudio,
    ModelCapability.audioClassify => l.hubCapAudioClassify,
    ModelCapability.imageClassify => l.hubCapImageClassify,
    ModelCapability.objectDetect => l.hubCapObjectDetect,
    ModelCapability.segment => l.hubCapSegment,
    ModelCapability.sensorClassify => l.hubCapSensorClassify,
  };
}

/// One Pest ID need on the status card.
String pestIdNeedLabel(AppLocalizations l, ModelCapability capability) =>
    switch (capability) {
      ModelCapability.imageIn => l.hubNeedImage,
      ModelCapability.embedText => l.hubNeedEmbeddings,
      ModelCapability.audioClassify => l.hubNeedSound,
      _ => capability.label(l),
    };

String modelSourceLine(AppLocalizations l, CatalogEntry entry) =>
    switch (modelHostOf(entry)) {
      ModelHost.huggingFace => l.hubSourceHf,
      ModelHost.googleAiEdge => l.hubSourceGoogle,
      ModelHost.other => l.hubSourceOther(modelHostName(entry)),
    };

/// Progress line for one download, e.g. "Downloading: 1.2 GB of 2.6 GB".
String provisionPhaseLine(AppLocalizations l, ProvisionProgress p) =>
    switch (p.phase) {
      ProvisionPhase.queued => l.hubPhaseQueued,
      ProvisionPhase.waitingForWifi => l.hubPhaseWifi,
      ProvisionPhase.waitingForSpace => l.hubPhaseSpace(
        formatBytes(l, p.totalBytes),
      ),
      ProvisionPhase.downloading => l.hubPhaseDownloading(
        formatBytes(l, p.bytesDone),
        formatBytes(l, p.totalBytes),
      ),
      ProvisionPhase.verifying => l.hubPhaseVerifying,
      ProvisionPhase.installed => l.hubInstalledChip,
      ProvisionPhase.paused => l.hubPhasePaused,
      ProvisionPhase.failed => l.hubPhaseFailed(p.error ?? '-'),
    };

bool isFinalPhase(ProvisionPhase phase) =>
    phase == ProvisionPhase.installed || phase == ProvisionPhase.failed;

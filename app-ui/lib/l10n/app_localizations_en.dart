// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get scanAppBarTitle => 'Scan';

  @override
  String get guidedScanTitle => 'Guided acoustic scan';

  @override
  String get researchScanTitle => 'Record labelled sample';

  @override
  String grainAndLabel(String grain, String label) {
    return '$grain • $label';
  }

  @override
  String get researchScanNoticeTitle => 'Research recording';

  @override
  String get researchScanNotice =>
      'This 2-second recording is kept privately on this phone so you can label it for training data. It is not shown as a pest result and is never uploaded.';

  @override
  String positioningTip(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Press phone against the container, keep still and quiet',
      'other': 'Press phone against sack, keep still and quiet',
    });
    return '$_temp0';
  }

  @override
  String positioningTipDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Lay the phone flat on the container with the microphone touching it, in a quiet room. Stop talking and do not move it for 2 seconds.',
      'other': 'Lay the phone flat on the sack with the microphone touching it, in a quiet place. Stop talking and do not move the sack for 2 seconds.',
    });
    return '$_temp0';
  }

  @override
  String get infoQualityTitle => 'Recording quality';

  @override
  String get infoQualityBody =>
      'Checked for background noise, clipping and silence before any result is shown.';

  @override
  String get infoDurationTitle => 'Capture duration';

  @override
  String get infoDurationShort => '2 s';

  @override
  String infoDurationRate(String khz) {
    return '2 s at $khz kHz';
  }

  @override
  String get infoOnDeviceTitle => 'On-device inference';

  @override
  String get infoOnDeviceBody => 'No upload required';

  @override
  String infoOnDeviceWithModel(String provenance) {
    return 'No upload required. $provenance';
  }

  @override
  String get micDeniedTitle => 'Microphone access is off';

  @override
  String get micDeniedSubtitle =>
      'Kernel needs the microphone to listen to grain.';

  @override
  String get micDeniedPrivacy =>
      'A scan records 2 seconds of sound and checks it on this phone. The sound is never uploaded, and it is deleted after the check unless you choose to keep recordings in Settings.';

  @override
  String get micDeniedBlocked =>
      'Microphone access is blocked for Kernel. Open the phone settings, choose Permissions, then allow Microphone.';

  @override
  String get micDeniedAskAgain =>
      'You can allow it the next time Kernel asks, or in the phone settings.';

  @override
  String get micDeniedStillUsable =>
      'Without the microphone you can still register items, browse your inventory, record physical inspections and export reports.';

  @override
  String get actionOpenSettings => 'Open settings';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionBrowseInventory => 'Browse inventory';

  @override
  String get resultAppBarTitle => 'Result';

  @override
  String get resultTitle => 'Screening result';

  @override
  String get scanNotFound => 'This scan was not found on this phone.';

  @override
  String get retryNothingSaved =>
      'Nothing about pests was saved for this recording.';

  @override
  String predictedClassLine(String label) {
    return 'Model prediction (unverified): $label';
  }

  @override
  String modelScoreLine(String score) {
    return 'Model score: $score (experimental, not an accuracy figure)';
  }

  @override
  String get modelNoteTitleExperimental => 'Experimental model — not validated';

  @override
  String get modelNoteTitle => 'About this model';

  @override
  String modelNoteOtherVersion(String version) {
    return 'This scan used model $version, which is no longer installed. Its provenance note is not stored with the scan, so treat the result as experimental.';
  }

  @override
  String get physicalInspectionNote =>
      'Acoustic screening is experimental. A physical inspection is required before any storage or sale decision.';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionRecordInspection => 'Record inspection';

  @override
  String get actionScanAnother => 'Scan another';

  @override
  String get recordingDetails => 'Recording details';

  @override
  String get fieldCaptured => 'Captured';

  @override
  String get fieldDuration => 'Duration';

  @override
  String get fieldSampleRate => 'Sample rate';

  @override
  String get fieldAnalysisTime => 'Analysis time';

  @override
  String get fieldDevice => 'Device';

  @override
  String unitMs(int value) {
    return '$value ms';
  }

  @override
  String unitHz(int value) {
    return '$value Hz';
  }

  @override
  String deviceAndOs(String device, String os) {
    return '$device ($os)';
  }

  @override
  String scanTabSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Choose the container to listen to',
      'other': 'Choose the sack to listen to',
    });
    return '$_temp0';
  }

  @override
  String get batchScanTitle => 'Batch scan';

  @override
  String get batchScanSubtitle => 'Scan sacks one at a time';

  @override
  String get qrCardTitle => 'Open from a QR label';

  @override
  String qrCardSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Point the camera at a Kernel label to open that container',
      'other': 'Point the camera at a Kernel sack label to open that sack',
    });
    return '$_temp0';
  }

  @override
  String get oneAtATimeTitle => 'One at a time';

  @override
  String get oneAtATimeBody =>
      'Each recording belongs to one item. Scan items one after another; a scan never covers several at once.';

  @override
  String emptyItemsMessage(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'No containers yet',
      'other': 'No sacks yet',
    });
    return '$_temp0';
  }

  @override
  String emptyItemsAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Add your first container',
      'other': 'Register your first sack',
    });
    return '$_temp0';
  }

  @override
  String get scanTabEmptyDetail =>
      'Register one first, then come back to scan it.';

  @override
  String get scansTodayTitle => 'Scanned today';

  @override
  String scansTodaySummary(int scans, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      scans,
      locale: localeName,
      other: '$scans scans',
      one: '1 scan',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
    );
    return '$_temp0 of $_temp1 since midnight';
  }

  @override
  String get scansTodayEmpty =>
      'No scans yet today. Scans you record appear here straight away.';

  @override
  String get experimentalBadge => 'Experimental';

  @override
  String get errorCouldNotLoad => 'Could not load';

  @override
  String errorWithDetail(String prefix, String detail) {
    return '$prefix: $detail';
  }

  @override
  String fieldLabel(String label) {
    return '$label:';
  }

  @override
  String get validationQuantityEmpty => 'Enter the quantity';

  @override
  String get validationQuantityPositive => 'Enter a number above 0';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get offlineLabel => 'Offline';

  @override
  String get onlineLabel => 'Online';

  @override
  String get offlineSemantics =>
      'Offline. Everything keeps working on this phone.';

  @override
  String get onlineSemantics => 'Online. Kernel does not need the network.';

  @override
  String get qrTooltip => 'Open a sack from its QR label';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get menuSwitchRole => 'Switch role';

  @override
  String get menuSettings => 'Settings';

  @override
  String itemTileSubtitle(String grain, String quantity, String date) {
    return '$grain · $quantity · stored $date';
  }

  @override
  String get archivedBadge => 'Archived';

  @override
  String get chipRetryNeeded => 'Retry needed';

  @override
  String chipAiUnverified(String label) {
    return 'AI: $label (unverified)';
  }

  @override
  String scanTileTitle(String item, String when) {
    return '$item · $when';
  }

  @override
  String qualityChip(String quality) {
    return 'Quality: $quality';
  }

  @override
  String get chipAudioKept => 'Audio kept on phone';

  @override
  String photoSemantics(int number) {
    return 'Evidence photo $number. Opens full size.';
  }

  @override
  String get photoMissing => 'This photo is no longer on this phone.';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String verifiedFindingLine(String finding) {
    return 'Verified finding: $finding';
  }

  @override
  String inspectorLine(String inspector, String when) {
    return '$inspector · $when';
  }

  @override
  String followUpChip(String status) {
    return 'Follow-up: $status';
  }

  @override
  String get unassigned => 'Unassigned';

  @override
  String assignedToChip(String name) {
    return 'Assigned to $name';
  }

  @override
  String get followUpChangeTooltip => 'Change follow-up status';

  @override
  String get followUpUpdate => 'Update status';

  @override
  String get assignAction => 'Assign';

  @override
  String get archiveAction => 'Archive';

  @override
  String archiveConfirmTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String get archiveConfirmItemBody =>
      'It will be hidden from lists, queues and new reports. Its scan history and inspections are kept on this phone and are not deleted.';

  @override
  String get archiveConfirmLotBody =>
      'The lot will be hidden from your lists and new reports. Its sacks, their scan history and inspections are kept on this phone.';

  @override
  String get archiveConfirmLocationBody =>
      'The place will be hidden from lists and pickers. Sacks stored there, their scan history and inspections are kept on this phone.';

  @override
  String get archiveConfirmHarvestBody =>
      'The harvest will be hidden from your lists and new reports. Its sacks, their scan history and inspections are kept on this phone.';

  @override
  String get levelMeterLabel => 'Microphone level';

  @override
  String get levelMeterWaiting => 'Waiting for sound';

  @override
  String levelMeterValue(int dbfs) {
    return '$dbfs dBFS';
  }

  @override
  String get voicePlacePhone => 'Place phone on the sack';

  @override
  String get voiceListening => 'Listening';

  @override
  String get voiceDone => 'Done';

  @override
  String scanCouldNotRun(String detail) {
    return 'The scan could not run: $detail';
  }

  @override
  String scanCouldNotSave(String detail) {
    return 'The scan result could not be saved, so nothing was stored. Details: $detail';
  }

  @override
  String get captureReady => 'Ready to listen';

  @override
  String get captureListening => 'Listening — keep still';

  @override
  String get captureSaving => 'Saving on this phone';

  @override
  String get captureCheckingMic => 'Checking microphone access';

  @override
  String get captureGetReady => 'Get ready — place the phone';

  @override
  String captureSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Press phone against the container',
      'other': 'Press phone against sack',
    });
    return '$_temp0';
  }

  @override
  String get captureResearchSubtitle =>
      'Research recording: the 2 seconds are kept privately on this phone for labelling';

  @override
  String get captureStart => 'Start 2-second recording';

  @override
  String get captureStartAgain => 'Try the 2-second recording again';

  @override
  String get captureStartResearch => 'Record labelled sample (2 s)';

  @override
  String get captureProgressLabel => 'Recording progress';

  @override
  String percentValue(int percent) {
    return '$percent percent';
  }

  @override
  String captureElapsed(String elapsed, String target) {
    return '$elapsed s of $target s';
  }

  @override
  String get captureChecking => 'Checking the recording on this phone…';

  @override
  String get hintWaiting => 'Listening…';

  @override
  String get hintTooQuiet => 'Too quiet — press closer';

  @override
  String get hintTooLoud => 'Too loud / rubbing';

  @override
  String get hintHoldStill => 'Hold still';

  @override
  String get appTitle => 'Kernel';

  @override
  String get roleFarmer => 'Farmer';

  @override
  String get roleHousehold => 'Household';

  @override
  String get roleStorageFpo => 'Storage/FPO';

  @override
  String get roleBuyer => 'Buyer';

  @override
  String get roleFarmerTagline => 'Harvest and pre-sale checks';

  @override
  String get roleHouseholdTagline => 'Containers and reminders';

  @override
  String get roleStorageFpoTagline => 'Warehouse and batch inspections';

  @override
  String get roleBuyerTagline => 'Supplier and lot screening';

  @override
  String get navHome => 'Home';

  @override
  String get navScan => 'Scan';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navReports => 'Reports';

  @override
  String get navInventoryFarmer => 'My Grain';

  @override
  String get navInventoryHousehold => 'My Containers';

  @override
  String get navInventoryFpo => 'Warehouse';

  @override
  String get navInventoryBuyer => 'Lots';

  @override
  String get reportTitleFarmer => 'Pre-sale report';

  @override
  String get reportTitleHousehold => 'Storage report';

  @override
  String get reportTitleFpo => 'Warehouse report';

  @override
  String get reportTitleBuyer => 'Lot screening report';

  @override
  String get locationTypeHome => 'Home';

  @override
  String get locationTypeContainer => 'Container';

  @override
  String get locationTypeWarehouse => 'Warehouse';

  @override
  String get locationTypeRoom => 'Room';

  @override
  String get locationTypeStack => 'Stack';

  @override
  String get screeningPending => 'Pending';

  @override
  String get screeningScreening => 'Screening';

  @override
  String get screeningNeedsPhysicalCheck => 'Pending physical check';

  @override
  String get screeningReviewed => 'Reviewed';

  @override
  String get findingNoneFound => 'None found';

  @override
  String get findingPestsFound => 'Pests found';

  @override
  String get findingInconclusive => 'Inconclusive';

  @override
  String get findingNoneFoundHelp => 'I checked and saw no insects or damage';

  @override
  String get findingPestsFoundHelp =>
      'I saw insects, larvae, webbing or damage';

  @override
  String get findingInconclusiveHelp => 'I could not tell from the check';

  @override
  String get followUpOpen => 'Open';

  @override
  String get followUpInProgress => 'In progress';

  @override
  String get followUpDone => 'Done';

  @override
  String get reminderScheduled => 'Scheduled';

  @override
  String get reminderFired => 'Due now';

  @override
  String get reminderDone => 'Done';

  @override
  String get reminderCancelled => 'Cancelled';

  @override
  String get reasonSilence =>
      'Too quiet: almost no sound reached the microphone. Press the phone firmly against the grain.';

  @override
  String get reasonClipping =>
      'Too loud: the sound was distorted. Do not tap, rub or knock while recording.';

  @override
  String get reasonHighNoise =>
      'Too much background noise. Move somewhere quieter and keep still.';

  @override
  String get reasonTooShort =>
      'The recording was too short. Keep the phone still for the full 2 seconds.';

  @override
  String get reasonPermissionDenied =>
      'Microphone access is off. Allow it in the phone settings to scan.';

  @override
  String get reasonCaptureError =>
      'The microphone could not record. Close other apps that use the microphone and try again.';

  @override
  String get qualityPass => 'Pass';

  @override
  String get qualityRetry => 'Retry';

  @override
  String get predictionClean => 'No signal detected';

  @override
  String get predictionUncertain => 'Uncertain';

  @override
  String get predictionInfested => 'Possible infestation';

  @override
  String get predictionNotEvaluated => 'Not evaluated';

  @override
  String get sampleLabelClean => 'Clean';

  @override
  String get sampleLabelInfested => 'Infested';

  @override
  String get sampleLabelUnknown => 'Unknown';

  @override
  String get headlineRetry => 'Recording not usable — try again';

  @override
  String get headlineNotEvaluated =>
      'Not evaluated — no model installed. Inspect physically.';

  @override
  String get headlineNotEvaluatedWithModel =>
      'Not evaluated — the model could not process this recording. Inspect physically.';

  @override
  String get headlineInspectionNeeded =>
      'Inspection needed — model result is not verified';

  @override
  String get headlineClean =>
      'No signal detected — not a guarantee; inspect before sale/storage decisions';

  @override
  String get provenanceNone => 'Model: none — Not evaluated';

  @override
  String provenanceExperimental(String version) {
    return 'Model $version — Experimental';
  }

  @override
  String provenanceValidated(String version) {
    return 'Model $version — Validated';
  }

  @override
  String dateTimeJoin(String date, String time) {
    return '$date, $time';
  }
}

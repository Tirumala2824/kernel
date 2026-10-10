// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageTitle => 'Language';

  @override
  String get languageFollowDevice => 'Follow phone language';

  @override
  String get languageSheetBody => 'Kernel\'s words change straight away.';

  @override
  String get settingsSubtitle =>
      'Language, scanning, privacy and on-device information';

  @override
  String get settingsScanning => 'Scanning';

  @override
  String get settingsHaptics => 'Vibrate at start and end';

  @override
  String get settingsHapticsBody =>
      'A short vibration when recording starts and stops, so you can keep the phone pressed against the sack.';

  @override
  String get settingsVoice => 'Spoken prompts';

  @override
  String get settingsVoiceBody =>
      'Off by default. Says \"Place phone on the sack\", \"Listening\" and \"Done\" with a voice installed on this phone. Nothing is fetched online.';

  @override
  String get settingsRetain => 'Keep recordings on this phone';

  @override
  String get settingsRetainBody =>
      'Off by default: each 2-second recording is deleted right after it is checked. When on, recordings are kept privately inside the app so they can be checked again. They are never uploaded. \"Delete all history\" removes them.';

  @override
  String get settingsResearchSection => 'Research';

  @override
  String get settingsResearch => 'Research recording mode';

  @override
  String get settingsResearchBody =>
      'Record labelled samples to help build a grain-pest model. Separate from keeping recordings; off by default.';

  @override
  String get researchConsentTitle => 'Turn on research recording?';

  @override
  String get researchConsentBody =>
      'When you choose \"Record labelled sample\", that 2-second recording is kept privately on this phone with the label you give it. Clean or Infested labels need a physical inspection that confirms them. Nothing is uploaded: you can export a dataset file and decide yourself who receives it. Turn this off at any time; \"Delete all history\" removes every recording and label.';

  @override
  String get researchConsentAgree => 'I agree, turn on';

  @override
  String get settingsSamplesCard => 'Counts per label and dataset export';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get deleteHistoryTitle => 'Delete all history';

  @override
  String get deleteHistoryBody =>
      'Removes scans, inspections and their photos, reminders, labelled samples and kept recordings.';

  @override
  String get deleteHistoryConfirmTitle => 'Delete all history?';

  @override
  String get deleteHistoryConfirmBody =>
      'This deletes every scan, inspection (with its photos), reminder, labelled sample and kept recording on this phone. Your registered items, places, harvests and lots stay. This cannot be undone.';

  @override
  String get deleteHistoryConfirmAction => 'Delete history';

  @override
  String get deleteHistoryDone => 'All history deleted';

  @override
  String deleteHistoryFailed(String detail) {
    return 'Could not delete history: $detail';
  }

  @override
  String get settingsOnDevice => 'On-device scanning';

  @override
  String get engineUnavailable => 'Scan engine information is unavailable';

  @override
  String get engineModelPresent => 'Results are experimental and not verified.';

  @override
  String get engineNoModel =>
      'No model is installed, so scans check recording quality only and results show \"Not evaluated\".';

  @override
  String get settingsFooter =>
      'All scanning runs on this phone. Kernel works without a network connection and never uploads audio.';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get diagnosticsCard =>
      'Model, processor, sample rates and device details for testing';

  @override
  String get diagnosticsSubtitle =>
      'What the scan engine reports on this phone';

  @override
  String get notMeasured => 'Not measured yet';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get diagModelInstalled => 'Model installed';

  @override
  String get diagModelNote => 'Model note';

  @override
  String get diagDelegate => 'Processor';

  @override
  String get diagAudioTitle => 'Audio input';

  @override
  String get diagTargetRate => 'Target sample rate';

  @override
  String get diagEffectiveRate => 'Effective sample rate';

  @override
  String get diagDeviceRate => 'Device input rate';

  @override
  String get diagAudioSource => 'Audio source';

  @override
  String get diagDeviceTitle => 'Device';

  @override
  String get diagOs => 'Android';

  @override
  String get diagAppVersion => 'App version';

  @override
  String get diagLogRowTitle => 'Device-log row';

  @override
  String get diagLogRowBody =>
      'Paste this row into the device log in docs/device-validation.md and add your name.';

  @override
  String get diagCopyRow => 'Copy device-log row';

  @override
  String get diagCopied => 'Row copied';

  @override
  String get qrTitle => 'Open from a QR label';

  @override
  String get qrInstructions =>
      'Hold the label inside the frame. It opens as soon as it is read.';

  @override
  String get qrNotKernel =>
      'This QR code is not a Kernel sack label. Point the camera at a label printed from Kernel.';

  @override
  String get qrUnknownItem =>
      'This label belongs to a sack that is not on this phone.';

  @override
  String qrLookupFailed(String detail) {
    return 'Could not open the sack: $detail';
  }

  @override
  String get qrScanAnother => 'Scan another label';

  @override
  String get qrRationaleTitle => 'Use the camera to read sack labels';

  @override
  String get qrRationaleBody =>
      'Kernel uses the camera only to read QR sack labels and to take inspection photos. Labels are read on this phone; camera images are not saved or uploaded.';

  @override
  String get qrAllowCamera => 'Allow camera';

  @override
  String get qrCameraDenied =>
      'Camera access was not allowed. You can still open sacks from your inventory.';

  @override
  String get qrCameraBlocked =>
      'Camera access is blocked for Kernel. Open the phone settings, choose Permissions, then allow Camera.';

  @override
  String get qrPrivacyNote =>
      'The label is read on this phone. Nothing is uploaded.';

  @override
  String get labelSampleTitle => 'Label research recording';

  @override
  String get labelRuleNote =>
      'Only label Clean or Infested when a physical inspection of this sack confirmed it. Otherwise choose Unknown.';

  @override
  String get labelCleanHelp => 'Confirmed by an inspection that found no pests';

  @override
  String get labelCleanNeedsInspection =>
      'Needs an inspection of this sack that found no pests';

  @override
  String get labelInfestedHelp => 'Confirmed by an inspection that found pests';

  @override
  String get labelInfestedNeedsInspection =>
      'Needs an inspection of this sack that found pests';

  @override
  String get labelUnknownHelp =>
      'No inspection confirms the state of this sack';

  @override
  String get labelNeedsEvidence =>
      'Clean and Infested need an inspection of this sack that agrees. Choose Unknown or record an inspection first.';

  @override
  String get evidenceTitle => 'Confirming inspection';

  @override
  String get evidenceBody => 'Choose the inspection done for this recording.';

  @override
  String get sackMaterialField => 'Sack or container material';

  @override
  String get notRecorded => 'Not recorded';

  @override
  String get environmentField => 'Environment';

  @override
  String get environmentHelper =>
      'Where it was recorded, for example a quiet room or a warehouse with fans';

  @override
  String get envQuietRoom => 'Quiet room';

  @override
  String get envWarehouse => 'Warehouse';

  @override
  String get envFansOn => 'Fans or machines on';

  @override
  String get envOutdoors => 'Outdoors';

  @override
  String get materialJute => 'Jute';

  @override
  String get materialWovenPp => 'Woven polypropylene';

  @override
  String get materialCotton => 'Cotton';

  @override
  String get materialPlastic => 'Plastic container';

  @override
  String get materialMetal => 'Metal container';

  @override
  String get materialOther => 'Other';

  @override
  String get sampleSave => 'Save labelled sample';

  @override
  String get sampleSaved => 'Labelled sample saved on this phone';

  @override
  String sampleRejected(String detail) {
    return 'The label was not saved: $detail';
  }

  @override
  String get sampleUnusableRetry =>
      'This recording was not usable, so it cannot be labelled. Record it again in a quiet place.';

  @override
  String get sampleUnusableNotKept =>
      'The audio for this recording was not kept, so it cannot be labelled.';

  @override
  String get sampleRecordAgain => 'Record again';

  @override
  String get samplesTitle => 'Research samples';

  @override
  String samplesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count labelled recordings on this phone',
      one: '1 labelled recording on this phone',
      zero: 'No labelled recordings yet',
    );
    return '$_temp0';
  }

  @override
  String get samplesResearchOff =>
      'Research recording mode is off. Turn it on in Settings to record new samples.';

  @override
  String get samplesEmpty => 'No labelled samples yet';

  @override
  String get samplesEmptyDetail =>
      'With research mode on, open a sack and choose \"Record labelled sample\".';

  @override
  String get datasetTitle => 'Training dataset';

  @override
  String get datasetBody =>
      'A ZIP of the kept recordings and a CSV of their labels, written on this phone. You choose where to share it; Kernel never uploads it.';

  @override
  String get datasetExport => 'Export dataset';

  @override
  String datasetExportFailed(String detail) {
    return 'The dataset could not be created or shared. $detail';
  }

  @override
  String sampleLabelChip(String label) {
    return 'Label: $label';
  }

  @override
  String get sampleConfirmed => 'Confirmed by inspection';

  @override
  String get inspectionTitle => 'Physical inspection';

  @override
  String get saveInspection => 'Save inspection';

  @override
  String get inspectionSaved => 'Inspection saved';

  @override
  String get aiPanelTitle => 'AI prediction (not verified)';

  @override
  String get aiPanelLoading => 'Loading the linked scan…';

  @override
  String get aiPanelNoScan =>
      'No scan linked. This inspection stands on its own.';

  @override
  String scannedAt(String when) {
    return 'Scanned $when';
  }

  @override
  String get aiPanelNotUsed => 'Not used to fill in your finding';

  @override
  String get findingPanelTitle => 'Your verified finding';

  @override
  String get findingPanelBody =>
      'What you saw yourself when you checked the grain. This is stored separately from the AI prediction.';

  @override
  String get findingMissing => 'Choose what you found';

  @override
  String get inspectorField => 'Inspector name';

  @override
  String get validationInspector => 'Enter who inspected';

  @override
  String get inspectionDateField => 'Inspection date';

  @override
  String get observationsField => 'Observations';

  @override
  String get observationsHelper => 'What you saw, where, and how much';

  @override
  String get assigneeFieldOptional => 'Assign follow-up to (optional)';

  @override
  String get followUpStatusTitle => 'Follow-up status';

  @override
  String get photosTitle => 'Evidence photos (optional)';

  @override
  String get photosBody =>
      'Photos stay privately on this phone with this inspection. They are evidence of what you saw, not acoustic results, and are never uploaded.';

  @override
  String get photoTake => 'Take photo';

  @override
  String get photoPick => 'Choose from gallery';

  @override
  String get cameraDeniedPhoto =>
      'Camera access is off. Allow it in the phone settings to take evidence photos.';

  @override
  String photoFailed(String detail) {
    return 'Could not add the photo: $detail';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterNoMatch => 'No open inspections match this filter.';

  @override
  String get batchSetupTitle => 'Choose a room or stack';

  @override
  String get batchSetupSubtitle =>
      'Kernel walks you through its sacks one at a time.';

  @override
  String get batchSequentialNote =>
      'One recording per sack. Kernel never scans several sacks at once.';

  @override
  String get batchNoPlaces => 'No rooms or stacks yet';

  @override
  String get batchNoPlacesDetail =>
      'Add a warehouse with its rooms and stacks, then register sacks in them.';

  @override
  String batchPlaceSubtitle(String type, int total, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total sacks',
      one: '1 sack',
    );
    return '$type · $_temp0 · $needScan need a scan';
  }

  @override
  String batchIntroSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sacks to walk, one at a time',
      one: '1 sack to walk, one at a time',
      zero: 'No sacks to walk',
    );
    return '$_temp0';
  }

  @override
  String get batchSkipToday => 'Skip sacks scanned today';

  @override
  String get batchSkipTodayBody =>
      'Leave out sacks that already have a recording from today.';

  @override
  String batchWalkLine(int position, String label, String grain) {
    return '$position. $label · $grain';
  }

  @override
  String batchStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Start with $count sacks',
      one: 'Start with 1 sack',
    );
    return '$_temp0';
  }

  @override
  String get batchNothingToWalk =>
      'Every sack here already has a usable scan or was scanned today.';

  @override
  String batchProgress(int position, int total) {
    return 'Sack $position of $total';
  }

  @override
  String get batchSkipSack => 'Skip this sack';

  @override
  String get batchStop => 'Stop session';

  @override
  String batchNextIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Next sack in $seconds seconds',
      one: 'Next sack in 1 second',
    );
    return '$_temp0';
  }

  @override
  String batchSummaryIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Summary in $seconds seconds',
      one: 'Summary in 1 second',
    );
    return '$_temp0';
  }

  @override
  String get batchNextSack => 'Next sack';

  @override
  String get batchFinish => 'Finish';

  @override
  String get batchRetrySack => 'Record this sack again';

  @override
  String get batchSummaryTitle => 'Session summary';

  @override
  String batchSummarySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sacks in this session',
      one: '1 sack in this session',
    );
    return '$_temp0';
  }

  @override
  String get batchStatRecorded => 'recorded';

  @override
  String get batchStatSkipped => 'skipped';

  @override
  String get batchStatRetry => 'need a retry';

  @override
  String get rankedTitle => 'Ranked';

  @override
  String rankLabel(int rank) {
    return '#$rank';
  }

  @override
  String get queueSuggestionNote =>
      'The order is a suggestion of what to check first. Inspect physically before any decision.';

  @override
  String get queueNothingRanked =>
      'No item has a usable model result yet, so nothing is ranked. Items without one are listed under \"Needs scan\".';

  @override
  String get queueNothingRankedShort => 'Nothing ranked yet';

  @override
  String needsScanTitle(int count) {
    return 'Needs scan ($count)';
  }

  @override
  String get needsScanChip => 'Needs scan';

  @override
  String get needsScanEmpty => 'Every item has a usable scan.';

  @override
  String get saveHarvest => 'Save harvest';

  @override
  String get harvestNameField => 'Harvest name';

  @override
  String get harvestNameHelper => 'For example \"Rabi wheat 2026\"';

  @override
  String get harvestedOnField => 'Harvested on';

  @override
  String get notesFieldOptional => 'Notes (optional)';

  @override
  String get harvestAppBar => 'Harvest';

  @override
  String get harvestNotFound => 'This harvest was not found on this phone.';

  @override
  String get harvestAddSack => 'Register sack in this harvest';

  @override
  String get harvestSacksTitle => 'Sacks from this harvest';

  @override
  String get harvestSacksEmpty => 'No sacks in this harvest yet';

  @override
  String get harvestSacksEmptyDetail =>
      'Register the sacks you filled from this harvest, then scan them before sale.';

  @override
  String get preSaleBody =>
      'A summary of this harvest\'s sacks for a buyer. Scans show their model version and experimental status, and verified inspection findings are listed separately. It is not a quality certificate.';

  @override
  String get notScannedYet => 'Not scanned yet';

  @override
  String get lotAppBar => 'Lot';

  @override
  String get lotNotFound => 'This lot was not found on this phone.';

  @override
  String get supplierNotRecorded => 'Supplier not recorded';

  @override
  String get fieldDeclaredQuantity => 'Declared quantity';

  @override
  String get fieldReceived => 'Received';

  @override
  String get fieldScreened => 'Screened';

  @override
  String get screeningStatusTitle => 'Screening status';

  @override
  String get screeningStatusBody =>
      'You set this after reviewing scans and physical checks. Scans never change it, and Kernel never accepts or rejects a lot.';

  @override
  String currentStatus(String status) {
    return 'Current: $status';
  }

  @override
  String get lotSacksTitle => 'Sacks in this lot';

  @override
  String get lotSacksEmpty => 'No sacks in this lot yet';

  @override
  String get lotSacksEmptyAction => 'Register a sack in this lot';

  @override
  String get sampleScansTitle => 'Sample scans';

  @override
  String get sampleScansBody =>
      'Scan sacks from this delivery one at a time. Each result is an unverified model output and does not change the lot\'s status.';

  @override
  String get sampleScansStart => 'Start sample scans';

  @override
  String get physicalChecksTitle => 'Physical checks';

  @override
  String get physicalChecksBody =>
      'Open and look inside each sack, then record what you found. Your findings are kept apart from the scans.';

  @override
  String get recordPhysicalCheck => 'Record physical check';

  @override
  String get noPhysicalCheckYet => 'No physical check yet';

  @override
  String lotSummaryTitle(String code) {
    return 'Lot $code summary report';
  }

  @override
  String get lotSummaryBody =>
      'Sample scans with model provenance, and physical check findings listed separately, from records on this phone. Use it to support your own decision.';

  @override
  String savedLot(String code) {
    return 'Saved lot $code';
  }

  @override
  String get saveLot => 'Save lot';

  @override
  String get lotCodeField => 'Lot code';

  @override
  String get lotCodeHelper => 'The reference on the delivery note';

  @override
  String get validationLotCode => 'Enter the lot code';

  @override
  String get supplierFieldOptional => 'Supplier name (optional)';

  @override
  String get declaredQuantityField => 'Declared quantity';

  @override
  String get receivedOnField => 'Received on';

  @override
  String shareSubject(String title) {
    return 'Kernel $title';
  }

  @override
  String exportFailed(String detail) {
    return 'The report could not be created or shared. $detail';
  }

  @override
  String get exportPanelBody =>
      'Built only from records stored on this phone. Every scan shows its model version and experimental status. AI predictions and verified inspection findings are listed separately.';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportLabelsPdf => 'Create labels PDF';

  @override
  String exportSavedAt(String path) {
    return 'Saved on this phone: $path';
  }

  @override
  String get sackLabelsTitle => 'Print sack labels';

  @override
  String get sackLabelsBody =>
      'A PDF of QR labels for these sacks. Print it and stick each label on its sack; scanning a label opens that sack in Kernel.';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsFarmerHint =>
      'The pre-sale summary for one harvest is on that harvest\'s page.';

  @override
  String get reportsBuyerHint =>
      'The lot summary report is on each lot\'s page.';

  @override
  String get recentScans => 'Recent scans';

  @override
  String get recentScansEmpty => 'No scans yet. Scans you record appear here.';

  @override
  String get inventorySubtitleFarmer => 'Your harvests and registered sacks';

  @override
  String get inventorySubtitleHousehold =>
      'Your grain containers and where they are kept';

  @override
  String get inventorySubtitleFpo => 'Warehouses, rooms, stacks and sacks';

  @override
  String get inventorySubtitleBuyer => 'Incoming lots and their sacks';

  @override
  String get newHarvestAction => 'New harvest';

  @override
  String registerItemAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Add container',
      'other': 'Register sack',
    });
    return '$_temp0';
  }

  @override
  String get addPlace => 'Add place';

  @override
  String get addLocation => 'Add location';

  @override
  String itemsSectionTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Containers',
      'other': 'Sacks',
    });
    return '$_temp0';
  }

  @override
  String get lotsSectionEmpty => 'No lots yet. Register a delivery to add one.';

  @override
  String get placesTitle => 'Places';

  @override
  String get locationsTitle => 'Locations';

  @override
  String get placesEmpty =>
      'No places yet. Add one to say where containers are kept.';

  @override
  String get locationsEmpty =>
      'No warehouse yet. Add one, then its rooms and stacks.';

  @override
  String get harvestsSectionEmpty =>
      'No harvests yet. Create one to group its sacks and build a pre-sale summary.';

  @override
  String harvestCardSubtitle(String grain, String date) {
    return '$grain · harvested $date';
  }

  @override
  String sackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sacks',
      one: '1 sack',
      zero: 'No sacks yet',
    );
    return '$_temp0';
  }

  @override
  String get itemDetailAppBar => 'Details';

  @override
  String get itemNotFound => 'This item was not found on this phone.';

  @override
  String archiveItemMenu(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Archive container',
      'other': 'Archive sack',
    });
    return '$_temp0';
  }

  @override
  String get archivedSnack => 'Archived. Its history is kept on this phone.';

  @override
  String get archivedItemNotice =>
      'Hidden from lists, queues and new reports. Its scan history and inspections are kept.';

  @override
  String get restoreAction => 'Restore';

  @override
  String scanThisItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Scan this container',
      'other': 'Scan this sack',
    });
    return '$_temp0';
  }

  @override
  String get setReminderAction => 'Set re-check reminder';

  @override
  String get researchRecordTitle => 'Record labelled sample';

  @override
  String get researchRecordSubtitle =>
      'Research mode: keep a 2-second recording and label it for training data';

  @override
  String get fieldQuantity => 'Quantity';

  @override
  String get fieldStoredSince => 'Stored since';

  @override
  String storedSinceValue(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$date ($_temp0)';
  }

  @override
  String get fieldLocation => 'Location';

  @override
  String get fieldLot => 'Lot';

  @override
  String get fieldHarvest => 'Harvest';

  @override
  String nameWithType(String name, String type) {
    return '$name ($type)';
  }

  @override
  String registeredAs(String role) {
    return 'Registered as $role';
  }

  @override
  String get scanHistoryTitle => 'Scan history';

  @override
  String get scanHistoryAppendOnly =>
      'Every scan is kept as recorded. A new scan never changes an earlier one.';

  @override
  String scanHistoryEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'No scans yet. Use \"Scan this container\" to record one.',
      'other': 'No scans yet. Use \"Scan this sack\" to record one.',
    });
    return '$_temp0';
  }

  @override
  String get inspectionsTitle => 'Inspections';

  @override
  String get inspectionsEmpty => 'No inspections recorded yet.';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersEmpty => 'No reminders set.';

  @override
  String recheckOn(String when) {
    return 'Re-check on $when';
  }

  @override
  String get reminderMarkDone => 'Mark done';

  @override
  String get reminderCancel => 'Cancel reminder';

  @override
  String get assignDialogTitle => 'Assign inspection';

  @override
  String get assignDialogLabel => 'Assigned to';

  @override
  String get assignDialogHelper => 'Who will do the follow-up check';

  @override
  String get assignClear => 'Unassign';

  @override
  String savedNamed(String name) {
    return 'Saved $name';
  }

  @override
  String saveFailed(String detail) {
    return 'Could not save: $detail';
  }

  @override
  String saveItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Save container',
      'other': 'Save sack',
    });
    return '$_temp0';
  }

  @override
  String itemLabelField(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Container label',
      'other': 'Sack label',
    });
    return '$_temp0';
  }

  @override
  String itemLabelHelper(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'The name written on the container',
      'other': 'The name written on the sack',
    });
    return '$_temp0';
  }

  @override
  String get validationLabel => 'Enter a label';

  @override
  String get grainTypeField => 'Grain type';

  @override
  String get validationGrain => 'Enter the grain type';

  @override
  String get quantityField => 'Quantity';

  @override
  String get unitField => 'Unit';

  @override
  String get storageDateField => 'Storage date';

  @override
  String get harvestFieldOptional => 'Harvest (optional)';

  @override
  String get harvestFieldNone => 'No harvests yet. Create one from My Grain.';

  @override
  String get none => 'None';

  @override
  String get locationFieldOptional => 'Location (optional)';

  @override
  String locationFieldNone(String where) {
    return 'No places yet. You can add them from $where.';
  }

  @override
  String get lotFieldOptional => 'Lot (optional)';

  @override
  String get lotFieldNone => 'No lots registered yet.';

  @override
  String get locationAppBar => 'Location';

  @override
  String get locationNotFound => 'This location was not found on this phone.';

  @override
  String get archivedLocationNotice =>
      'This place is archived. Its sacks and their history are kept.';

  @override
  String registerHere(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Add container here',
      'other': 'Register sack here',
    });
    return '$_temp0';
  }

  @override
  String get addInside => 'Add inside';

  @override
  String get batchHere => 'Batch scan here';

  @override
  String get insideTitle => 'Inside';

  @override
  String get insideEmpty => 'Nothing inside this location yet.';

  @override
  String itemsHereTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Containers here',
      'other': 'Sacks here',
    });
    return '$_temp0';
  }

  @override
  String itemsHereEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'No containers stored here yet.',
      'other': 'No sacks stored here yet.',
    });
    return '$_temp0';
  }

  @override
  String get saveLocation => 'Save location';

  @override
  String get typeField => 'Type';

  @override
  String get nameField => 'Name';

  @override
  String get validationName => 'Enter a name';

  @override
  String get parentFieldOptional => 'Inside (optional)';

  @override
  String get parentFieldHelper => 'For example a room inside a warehouse';

  @override
  String get parentTopLevel => 'Nothing (top level)';

  @override
  String get roleSelectTitle => 'Select your role';

  @override
  String get roleSelectSubtitle => 'One app. Four workflows.';

  @override
  String get roleCurrent => 'Current';

  @override
  String get roleSwitchKeepsRecords =>
      'Switching role keeps every record on this phone. You can switch back at any time.';

  @override
  String roleSaveFailed(String detail) {
    return 'Could not save your role: $detail';
  }

  @override
  String startDataError(String detail) {
    return 'Kernel could not open its local data on this phone. Please restart the app.\n\nDetails: $detail';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String onboardingStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingPrivacyTitle => 'Audio stays on your phone';

  @override
  String get onboardingPrivacy1 =>
      'Kernel listens to grain for 2 seconds and checks the sound right here on this phone.';

  @override
  String get onboardingPrivacy2 =>
      'Nothing is uploaded. There is no account and no cloud, and everything works offline.';

  @override
  String get onboardingPrivacy3 =>
      'Recordings are deleted after the check unless you choose to keep them in Settings.';

  @override
  String get onboardingHowTitle => 'How to scan';

  @override
  String get onboardingHow1 =>
      'Lay the phone flat against the sack or container, microphone touching it.';

  @override
  String get onboardingHow2 =>
      'Choose a quiet room. Stop talking and switch off fans if you can.';

  @override
  String get onboardingHow3 => 'Hold still for 2 seconds while Kernel listens.';

  @override
  String get onboardingHow4 =>
      'Results are experimental. Always inspect the grain yourself before deciding.';

  @override
  String get onboardingRoleTitle => 'Pick your role';

  @override
  String get heroEyebrowListen => 'Listen to your grain';

  @override
  String get heroStartScan => 'Start scan';

  @override
  String get heroStartBatch => 'Start batch';

  @override
  String get loading => 'Loading…';

  @override
  String get farmerHomeTitle => 'Farmer dashboard';

  @override
  String farmerHomeHarvestSubtitle(String name) {
    return 'Harvest: $name';
  }

  @override
  String get farmerHeroTitle => 'Scan grain';

  @override
  String get farmerHeroSubtitle => 'Start a guided 2-second recording';

  @override
  String get farmerEmptyDetail =>
      'Register a sack to start scanning and tracking it.';

  @override
  String registeredSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registered sacks',
      one: '1 registered sack',
    );
    return '$_temp0';
  }

  @override
  String get noFollowUps => 'No follow-up inspections open';

  @override
  String sacksRequireFollowUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sacks require follow-up inspection',
      one: '1 sack requires follow-up inspection',
    );
    return '$_temp0';
  }

  @override
  String get harvestsTitle => 'Harvests';

  @override
  String get harvestsEmptyCard =>
      'Create a harvest to group its sacks for the pre-sale report';

  @override
  String harvestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count harvests · open the latest',
      one: '1 harvest · open the latest',
    );
    return '$_temp0';
  }

  @override
  String get queueTitle => 'Inspection queue';

  @override
  String get queueCardSubtitle => 'Which sacks to check first';

  @override
  String get preSaleCardSubtitle =>
      'Export a summary built from your stored records';

  @override
  String preSaleCardHarvest(String name) {
    return 'Pre-sale summary for $name';
  }

  @override
  String get householdHomeTitle => 'Household storage';

  @override
  String get householdHomeSubtitle => 'Home grain tracker';

  @override
  String get householdHeroTitle => 'Scan a container';

  @override
  String get householdHeroSubtitle => 'Record grain condition';

  @override
  String get householdEmptyDetail =>
      'Add a grain container to track its storage time.';

  @override
  String get remindersCardTitle => 'Inspection reminders';

  @override
  String get remindersCardEmpty =>
      'No reminders scheduled. Open a container to set one.';

  @override
  String remindersScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders scheduled',
      one: '1 reminder scheduled',
    );
    return '$_temp0';
  }

  @override
  String containerTitle(String grain, String place) {
    return '$grain / $place';
  }

  @override
  String storedDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Stored $days days',
      one: 'Stored 1 day',
    );
    return '$_temp0';
  }

  @override
  String get reviewNeverScanned => 'Not scanned yet — review due';

  @override
  String reviewDueSince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Review due — last scanned $days days ago',
      one: 'Review due — last scanned 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String reviewNextIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Next review in $days days',
      one: 'Next review in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get reviewDue => 'Review due';

  @override
  String reminderOn(String date) {
    return 'Reminder $date';
  }

  @override
  String get recheckAction => 'Recheck';

  @override
  String get remindMeAction => 'Remind me';

  @override
  String get reminderSheetTitle => 'Set a re-check reminder';

  @override
  String reminderSheetSubtitle(String label) {
    return 'For $label. Kernel reminds you on this phone.';
  }

  @override
  String reminderInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days days',
      one: 'In 1 day',
    );
    return '$_temp0';
  }

  @override
  String get reminderDateLabel => 'Date';

  @override
  String get reminderTimeLabel => 'Time';

  @override
  String get reminderOnDeviceNote =>
      'The reminder is scheduled on this phone and works offline.';

  @override
  String get reminderSave => 'Save reminder';

  @override
  String get reminderPastError => 'Choose a time in the future.';

  @override
  String get reminderSet => 'Reminder set';

  @override
  String get reminderSetNotificationsOff =>
      'Reminder saved. Notifications are off, so it will only show inside the app.';

  @override
  String reminderFailed(String detail) {
    return 'Could not set reminder: $detail';
  }

  @override
  String get fpoHomeTitle => 'Warehouse overview';

  @override
  String get fpoHomeSubtitle => 'Warehouses, rooms and stacks';

  @override
  String get fpoEmptyDetail =>
      'Register sacks, then scan them one at a time to build an inspection queue.';

  @override
  String sacksScannedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sacks scanned today',
      one: '1 sack scanned today',
    );
    return '$_temp0';
  }

  @override
  String queueSummary(int flagged, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      needScan,
      locale: localeName,
      other: '$needScan sacks need a scan',
      one: '1 sack needs a scan',
    );
    return '$flagged flagged · $_temp0';
  }

  @override
  String get assignedTitle => 'Assigned inspections';

  @override
  String get assignedNone => 'No open inspections';

  @override
  String inspectionsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inspections open',
      one: '1 inspection open',
    );
    return '$_temp0';
  }

  @override
  String get fpoAddLocationTitle => 'Add warehouse, room or stack';

  @override
  String get fpoAddLocationSubtitle =>
      'Organise sacks by where they are stored';

  @override
  String get buyerHomeTitle => 'Incoming lots';

  @override
  String get buyerHomeSubtitle => 'Procurement screening';

  @override
  String get heroEyebrowDelivery => 'New delivery';

  @override
  String get buyerHeroTitle => 'Register delivery';

  @override
  String get buyerHeroSubtitle => 'Supplier, lot, grain, quantity';

  @override
  String get buyerHeroAction => 'Register';

  @override
  String get lotsEmptyMessage => 'No lots yet';

  @override
  String get lotsEmptyDetail => 'Register a delivery to screen its sacks.';

  @override
  String get lotsEmptyAction => 'Register your first delivery';

  @override
  String get buyerReportCardTitle => 'Inspection report';

  @override
  String get buyerReportCardSubtitle =>
      'Export lot screening from your stored records';

  @override
  String lotTitle(String code, String grain) {
    return '$code / $grain';
  }

  @override
  String get lotNoSacks => 'No sacks registered in this lot yet';

  @override
  String lotScreenedCount(int screened, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total sacks',
      one: '1 sack',
    );
    return '$screened of $_temp0 screened';
  }

  @override
  String supplierChip(String name) {
    return 'Supplier: $name';
  }

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

  @override
  String get nextStepEyebrow => 'Next step';

  @override
  String get nextNothingPending =>
      'Nothing urgent right now. Scan regularly to keep track.';

  @override
  String get quickScanAction => 'Scan now';

  @override
  String scansTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans today',
      one: '1 scan today',
      zero: 'No scans today',
    );
    return '$_temp0';
  }

  @override
  String scanActivityLine(int today, int week) {
    return 'Scans: $today today · $week in the last 7 days';
  }

  @override
  String nextRegisterFirst(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'Register your first container',
      'other': 'Register your first sack',
    });
    return '$_temp0';
  }

  @override
  String get nextRegisterFirstBody =>
      'Add a name, grain and quantity. It takes a minute.';

  @override
  String get nextRegisterFirstLot => 'Register your first delivery';

  @override
  String get nextRegisterFirstLotBody => 'Supplier, lot, grain and quantity.';

  @override
  String nextScanOne(String label) {
    return 'Scan $label';
  }

  @override
  String nextScanSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sacks need a scan',
      one: '1 sack needs a scan',
    );
    return '$_temp0';
  }

  @override
  String nextScanContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count containers need a scan',
      one: '1 container needs a scan',
    );
    return '$_temp0';
  }

  @override
  String nextScanBody(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container':
          'A 2-second listening check with the phone pressed on the container.',
      'other': 'A 2-second listening check, one sack at a time.',
    });
    return '$_temp0';
  }

  @override
  String nextInspectOne(String label) {
    return 'Inspect $label';
  }

  @override
  String nextInspectSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flagged sacks to inspect',
      one: '1 flagged sack to inspect',
    );
    return '$_temp0';
  }

  @override
  String nextInspectContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flagged containers to inspect',
      one: '1 flagged container to inspect',
    );
    return '$_temp0';
  }

  @override
  String get nextInspectBody =>
      'The model result is not verified. Check the grain by hand.';

  @override
  String nextReviewOne(String label) {
    return '$label: review due';
  }

  @override
  String nextReviewSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sacks due for review',
      one: '1 sack due for review',
    );
    return '$_temp0';
  }

  @override
  String nextReviewContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count containers due for review',
      one: '1 container due for review',
    );
    return '$_temp0';
  }

  @override
  String get nextReviewBody =>
      'It has been a while since the last check. Listen again or inspect.';

  @override
  String nextReminderOne(String label) {
    return '$label: reminder due';
  }

  @override
  String nextReminderMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders due',
      one: '1 reminder due',
    );
    return '$_temp0';
  }

  @override
  String get nextReminderBody =>
      'A re-check you scheduled is due. Check this grain.';

  @override
  String nextPhysicalOne(String label) {
    return 'Lot $label: physical check pending';
  }

  @override
  String nextPhysicalMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lots need a physical check',
      one: '1 lot needs a physical check',
    );
    return '$_temp0';
  }

  @override
  String get nextPhysicalBody =>
      'Open the lot and record what a person found. Kernel never accepts or rejects a lot.';

  @override
  String get nextFinishBatch => 'Finish the batch scan';

  @override
  String nextFinishBatchOne(String label) {
    return 'Finish the batch: $label';
  }

  @override
  String nextFinishBatchBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sacks left to scan, one at a time',
      one: '1 sack left to scan, one at a time',
      zero: 'Every sack in this batch has a scan',
    );
    return '$_temp0';
  }

  @override
  String get nextPreSale => 'Share a pre-sale report';

  @override
  String nextPreSaleOne(String label) {
    return 'Share the pre-sale report for $label';
  }

  @override
  String get nextLotSummary => 'Share a lot summary';

  @override
  String nextLotSummaryOne(String label) {
    return 'Share the lot summary for $label';
  }

  @override
  String get nextExportBody =>
      'Made on this phone from your records. You choose who to share it with.';

  @override
  String get nextActionRegister => 'Register';

  @override
  String get nextActionScan => 'Start scan';

  @override
  String get nextActionBatch => 'Start batch scan';

  @override
  String get nextActionOpen => 'Open';

  @override
  String get nextActionQueue => 'Open the queue';

  @override
  String get nextActionOpenLot => 'Open lot';

  @override
  String get nextActionContinueBatch => 'Continue batch';

  @override
  String get nextActionReport => 'Open report';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsSubtitle =>
      'Worked out on this phone from your own records';

  @override
  String get insightsCardSubtitle =>
      'Results, recording problems and what needs a check';

  @override
  String get insightsWindowLabel => 'Period';

  @override
  String get insightsWindow7 => '7 days';

  @override
  String get insightsWindow30 => '30 days';

  @override
  String get insightsWindowAll => 'All time';

  @override
  String get insightsActivityTitle => 'Scanning activity';

  @override
  String get insightsScansToday => 'Scans today';

  @override
  String get insightsScans7 => 'Scans in the last 7 days';

  @override
  String get insightsRatesTitle => 'Results';

  @override
  String get insightsRatesEmpty => 'No scans in this period';

  @override
  String get insightsRatesEmptyDetail =>
      'Scan a sack or container to see results here.';

  @override
  String get insightsExperimentalNote =>
      'Experimental model: these results are not verified and may be wrong. Inspect physically before any storage or sale decision.';

  @override
  String get insightsNoModelResults =>
      'No model results yet: no usable recording was evaluated by a model.';

  @override
  String get insightsRetryLabel => 'Recording not usable (retry)';

  @override
  String insightsBarValue(int count, int percent) {
    return '$count · $percent%';
  }

  @override
  String insightsTotalScans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans in this period',
      one: '1 scan in this period',
    );
    return '$_temp0';
  }

  @override
  String get insightsQualityTitle => 'Recording problems';

  @override
  String get insightsQualityEmpty => 'No unusable recordings in this period';

  @override
  String get insightsQualityHint =>
      'Most problems go away when the phone is pressed firmly on the sack in a quiet place.';

  @override
  String get insightsInspectionsTitle => 'Inspections';

  @override
  String get insightsInspectionsEmpty => 'No inspections recorded yet';

  @override
  String insightsClosureRate(int percent) {
    return '$percent% of inspections are done';
  }

  @override
  String get insightsStaleTitle => 'Longest since last check';

  @override
  String get staleNeverScanned => 'Never scanned';

  @override
  String get qualityShortSilence => 'Too quiet';

  @override
  String get qualityShortClipping => 'Too loud (clipping)';

  @override
  String get qualityShortHighNoise => 'Too noisy';

  @override
  String get qualityShortTooShort => 'Too short';

  @override
  String get qualityShortPermissionDenied => 'Microphone blocked';

  @override
  String get qualityShortCaptureError => 'Recording error';

  @override
  String get queueFilterResult => 'Model result';

  @override
  String get queueFilterAllResults => 'All results';

  @override
  String get queueFilterPlace => 'Place';

  @override
  String get queueFilterAllPlaces => 'All places';

  @override
  String get queueFilterAge => 'Last usable scan';

  @override
  String get queueFilterAnyAge => 'Any time';

  @override
  String queueFilterWithinDays(int days) {
    return 'Within $days days';
  }

  @override
  String queueFilterAgeNote(int days) {
    return 'Items whose last usable scan is older than $days days move to Needs scan.';
  }

  @override
  String get queueNoMatch => 'No ranked items match these filters.';

  @override
  String get rankReasonInfested =>
      'Why here: possible infestation (not verified)';

  @override
  String get rankReasonUncertain => 'Why here: the model was unsure';

  @override
  String get rankReasonClean =>
      'Why lower: no signal detected (not a guarantee)';

  @override
  String scannedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Scanned $days days ago',
      one: 'Scanned 1 day ago',
      zero: 'Scanned today',
    );
    return '$_temp0';
  }

  @override
  String get reminderSuggestedLabel => 'Suggested — you choose';

  @override
  String reminderSuggestedOther(String date) {
    return 'Suggested: $date — you choose';
  }

  @override
  String get reminderWordingTitle => 'Suggested wording';

  @override
  String get settingsAdviceSection => 'On-phone AI assistant (experimental)';

  @override
  String get adviceToggle => 'Use the on-phone AI assistant';

  @override
  String get adviceToggleBody =>
      'Off by default. It runs only on this phone and never hears your recordings; it only sees results and dates. It may be wrong. You can turn it off at any time.';

  @override
  String get adviceStatusTitle => 'Assistant status';

  @override
  String get adviceStatusOff => 'Off';

  @override
  String get adviceStatusNoModel => 'On — no model imported yet';

  @override
  String get adviceStatusLoading => 'Loading the model…';

  @override
  String get adviceStatusReady => 'Ready on this phone';

  @override
  String get adviceStatusBusy => 'Busy writing';

  @override
  String get adviceStatusFailed =>
      'Could not load the model — Kernel uses its standard text';

  @override
  String get adviceModelTitle => 'Assistant model';

  @override
  String get adviceModelNone => 'No model imported yet';

  @override
  String get adviceModelId => 'Model';

  @override
  String get adviceModelVersion => 'Version';

  @override
  String get adviceModelSize => 'Size';

  @override
  String get adviceModelBackend => 'Runs on';

  @override
  String get adviceBackendGpu => 'Phone graphics chip (GPU)';

  @override
  String get adviceBackendCpu => 'Phone processor (CPU)';

  @override
  String get adviceBackendNone => 'Not loaded yet';

  @override
  String get adviceImportAction => 'Import model';

  @override
  String get adviceImporting => 'Importing the model';

  @override
  String adviceImportCopying(String copied, String total) {
    return 'Copying $copied of $total';
  }

  @override
  String adviceImportCopied(String copied) {
    return 'Copied $copied';
  }

  @override
  String get adviceImportVerifying => 'Checking the model file…';

  @override
  String get adviceImportDone => 'Model imported. It stays on this phone.';

  @override
  String adviceImportFailed(String detail) {
    return 'The model could not be imported: $detail';
  }

  @override
  String adviceImportNoSpace(String needed, String free) {
    return 'Not enough space: the model needs $needed but only $free is free on this phone.';
  }

  @override
  String get adviceDeleteAction => 'Delete model';

  @override
  String get adviceDeleteConfirmTitle => 'Delete the assistant model?';

  @override
  String get adviceDeleteConfirmBody =>
      'This removes the model file from this phone. Your records are not affected. You can import it again later.';

  @override
  String adviceDeleteFailed(String detail) {
    return 'The model could not be deleted: $detail';
  }

  @override
  String get adviceHelp =>
      'Get a .litertlm model with Google AI Edge Gallery or from Hugging Face litert-community/gemma-4-E2B-it-litert-lm (Gemma terms apply), then import it here.';

  @override
  String adviceProvenance(String modelVersion) {
    return 'Generated on this phone — experimental · $modelVersion';
  }

  @override
  String get adviceNotDecision => 'Not a decision — inspect physically';

  @override
  String get adviceGenerating => 'Writing on this phone…';

  @override
  String get adviceExplainAction => 'Explain this result';

  @override
  String get adviceExplainTitle => 'What this result means';

  @override
  String get adviceStaticRetry =>
      'The recording could not be used, so no result was saved. Press the phone firmly against the sack or container, keep still and quiet, and record again.';

  @override
  String get adviceStaticNotEvaluated =>
      'No result was produced for this recording, so it says nothing about pests. Inspect the grain physically.';

  @override
  String get adviceStaticInspection =>
      'The experimental model picked up something that may need attention. This is not verified. Inspect the grain physically before any decision.';

  @override
  String get adviceStaticClean =>
      'The experimental model did not pick up a signal. This is not a guarantee. Inspect the grain physically before storage or sale decisions.';

  @override
  String get reportAiSummaryToggle => 'Add AI-drafted summary';

  @override
  String get reportAiSummaryBody =>
      'Drafted on this phone from the report\'s figures. You see it first and choose whether to include it. Experimental.';

  @override
  String get reportAiPreviewTitle => 'AI-drafted summary';

  @override
  String get reportAiPreviewBody =>
      'If you include it, it appears in its own labelled section, separate from your records and inspection findings. It cannot be edited.';

  @override
  String get reportAiSummaryTitle => 'Draft summary';

  @override
  String get reportAiInclude => 'Include';

  @override
  String get reportAiSkip => 'Skip';

  @override
  String unitGb(String value) {
    return '$value GB';
  }

  @override
  String unitMb(String value) {
    return '$value MB';
  }
}

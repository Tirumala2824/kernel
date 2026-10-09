// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
}

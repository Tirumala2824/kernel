import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('bn'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('or'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
  ];

  /// Settings row and picker title.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Use the device locale.
  ///
  /// In en, this message translates to:
  /// **'Follow phone language'**
  String get languageFollowDevice;

  /// Language picker explanation.
  ///
  /// In en, this message translates to:
  /// **'Kernel\'s words change straight away.'**
  String get languageSheetBody;

  /// Settings subtitle.
  ///
  /// In en, this message translates to:
  /// **'Language, scanning, privacy and on-device information'**
  String get settingsSubtitle;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get settingsScanning;

  /// Haptics toggle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate at start and end'**
  String get settingsHaptics;

  /// Haptics toggle explanation.
  ///
  /// In en, this message translates to:
  /// **'A short vibration when recording starts and stops, so you can keep the phone pressed against the sack.'**
  String get settingsHapticsBody;

  /// Voice prompts toggle.
  ///
  /// In en, this message translates to:
  /// **'Spoken prompts'**
  String get settingsVoice;

  /// Voice prompts explanation.
  ///
  /// In en, this message translates to:
  /// **'Off by default. Says \"Place phone on the sack\", \"Listening\" and \"Done\" with a voice installed on this phone. Nothing is fetched online.'**
  String get settingsVoiceBody;

  /// Audio retention opt-in.
  ///
  /// In en, this message translates to:
  /// **'Keep recordings on this phone'**
  String get settingsRetain;

  /// Audio retention explanation.
  ///
  /// In en, this message translates to:
  /// **'Off by default: each 2-second recording is deleted right after it is checked. When on, recordings are kept privately inside the app so they can be checked again. They are never uploaded. \"Delete all history\" removes them.'**
  String get settingsRetainBody;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get settingsResearchSection;

  /// Research opt-in toggle.
  ///
  /// In en, this message translates to:
  /// **'Research recording mode'**
  String get settingsResearch;

  /// Research toggle explanation.
  ///
  /// In en, this message translates to:
  /// **'Record labelled samples to help build a grain-pest model. Separate from keeping recordings; off by default.'**
  String get settingsResearchBody;

  /// Consent dialog title.
  ///
  /// In en, this message translates to:
  /// **'Turn on research recording?'**
  String get researchConsentTitle;

  /// Consent explanation.
  ///
  /// In en, this message translates to:
  /// **'When you choose \"Record labelled sample\", that 2-second recording is kept privately on this phone with the label you give it. Clean or Infested labels need a physical inspection that confirms them. Nothing is uploaded: you can export a dataset file and decide yourself who receives it. Turn this off at any time; \"Delete all history\" removes every recording and label.'**
  String get researchConsentBody;

  /// Consent button.
  ///
  /// In en, this message translates to:
  /// **'I agree, turn on'**
  String get researchConsentAgree;

  /// Link to research samples.
  ///
  /// In en, this message translates to:
  /// **'Counts per label and dataset export'**
  String get settingsSamplesCard;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// Privacy action.
  ///
  /// In en, this message translates to:
  /// **'Delete all history'**
  String get deleteHistoryTitle;

  /// Privacy action explanation.
  ///
  /// In en, this message translates to:
  /// **'Removes scans, inspections and their photos, reminders, labelled samples and kept recordings.'**
  String get deleteHistoryBody;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete all history?'**
  String get deleteHistoryConfirmTitle;

  /// Confirm dialog body.
  ///
  /// In en, this message translates to:
  /// **'This deletes every scan, inspection (with its photos), reminder, labelled sample and kept recording on this phone. Your registered items, places, harvests and lots stay. This cannot be undone.'**
  String get deleteHistoryConfirmBody;

  /// Confirm button.
  ///
  /// In en, this message translates to:
  /// **'Delete history'**
  String get deleteHistoryConfirmAction;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'All history deleted'**
  String get deleteHistoryDone;

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Could not delete history: {detail}'**
  String deleteHistoryFailed(String detail);

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'On-device scanning'**
  String get settingsOnDevice;

  /// Error prefix.
  ///
  /// In en, this message translates to:
  /// **'Scan engine information is unavailable'**
  String get engineUnavailable;

  /// Engine card with a model.
  ///
  /// In en, this message translates to:
  /// **'Results are experimental and not verified.'**
  String get engineModelPresent;

  /// Engine card without a model.
  ///
  /// In en, this message translates to:
  /// **'No model is installed, so scans check recording quality only and results show \"Not evaluated\".'**
  String get engineNoModel;

  /// Settings footer.
  ///
  /// In en, this message translates to:
  /// **'All scanning runs on this phone. Kernel works without a network connection and never uploads audio.'**
  String get settingsFooter;

  /// Diagnostics screen.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// Link to diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Model, processor, sample rates and device details for testing'**
  String get diagnosticsCard;

  /// Diagnostics subtitle.
  ///
  /// In en, this message translates to:
  /// **'What the scan engine reports on this phone'**
  String get diagnosticsSubtitle;

  /// Value not reported by the engine yet.
  ///
  /// In en, this message translates to:
  /// **'Not measured yet'**
  String get notMeasured;

  /// Boolean value.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Boolean value.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Model installed'**
  String get diagModelInstalled;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Model note'**
  String get diagModelNote;

  /// Inference delegate field.
  ///
  /// In en, this message translates to:
  /// **'Processor'**
  String get diagDelegate;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Audio input'**
  String get diagAudioTitle;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Target sample rate'**
  String get diagTargetRate;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Effective sample rate'**
  String get diagEffectiveRate;

  /// Hardware input rate before resampling.
  ///
  /// In en, this message translates to:
  /// **'Device input rate'**
  String get diagDeviceRate;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Audio source'**
  String get diagAudioSource;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get diagDeviceTitle;

  /// OS version field.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get diagOs;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get diagAppVersion;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Device-log row'**
  String get diagLogRowTitle;

  /// Instructions.
  ///
  /// In en, this message translates to:
  /// **'Paste this row into the device log in docs/device-validation.md and add your name.'**
  String get diagLogRowBody;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Copy device-log row'**
  String get diagCopyRow;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Row copied'**
  String get diagCopied;

  /// QR screen title.
  ///
  /// In en, this message translates to:
  /// **'Open from a QR label'**
  String get qrTitle;

  /// QR scanning instructions.
  ///
  /// In en, this message translates to:
  /// **'Hold the label inside the frame. It opens as soon as it is read.'**
  String get qrInstructions;

  /// Friendly error for any other QR code.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a Kernel sack label. Point the camera at a label printed from Kernel.'**
  String get qrNotKernel;

  /// Valid label, unknown item.
  ///
  /// In en, this message translates to:
  /// **'This label belongs to a sack that is not on this phone.'**
  String get qrUnknownItem;

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Could not open the sack: {detail}'**
  String qrLookupFailed(String detail);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Scan another label'**
  String get qrScanAnother;

  /// Camera permission rationale title.
  ///
  /// In en, this message translates to:
  /// **'Use the camera to read sack labels'**
  String get qrRationaleTitle;

  /// Camera permission rationale.
  ///
  /// In en, this message translates to:
  /// **'Kernel uses the camera only to read QR sack labels and to take inspection photos. Labels are read on this phone; camera images are not saved or uploaded.'**
  String get qrRationaleBody;

  /// Requests the camera permission.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get qrAllowCamera;

  /// Camera denied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was not allowed. You can still open sacks from your inventory.'**
  String get qrCameraDenied;

  /// Camera permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is blocked for Kernel. Open the phone settings, choose Permissions, then allow Camera.'**
  String get qrCameraBlocked;

  /// QR privacy note.
  ///
  /// In en, this message translates to:
  /// **'The label is read on this phone. Nothing is uploaded.'**
  String get qrPrivacyNote;

  /// Label form title.
  ///
  /// In en, this message translates to:
  /// **'Label research recording'**
  String get labelSampleTitle;

  /// Research label rule.
  ///
  /// In en, this message translates to:
  /// **'Only label Clean or Infested when a physical inspection of this sack confirmed it. Otherwise choose Unknown.'**
  String get labelRuleNote;

  /// Label option help.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by an inspection that found no pests'**
  String get labelCleanHelp;

  /// Why Clean is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Needs an inspection of this sack that found no pests'**
  String get labelCleanNeedsInspection;

  /// Label option help.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by an inspection that found pests'**
  String get labelInfestedHelp;

  /// Why Infested is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Needs an inspection of this sack that found pests'**
  String get labelInfestedNeedsInspection;

  /// Label option help.
  ///
  /// In en, this message translates to:
  /// **'No inspection confirms the state of this sack'**
  String get labelUnknownHelp;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Clean and Infested need an inspection of this sack that agrees. Choose Unknown or record an inspection first.'**
  String get labelNeedsEvidence;

  /// Evidence picker title.
  ///
  /// In en, this message translates to:
  /// **'Confirming inspection'**
  String get evidenceTitle;

  /// Evidence picker body.
  ///
  /// In en, this message translates to:
  /// **'Choose the inspection done for this recording.'**
  String get evidenceBody;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Sack or container material'**
  String get sackMaterialField;

  /// Empty picker option.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get notRecorded;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentField;

  /// Form helper.
  ///
  /// In en, this message translates to:
  /// **'Where it was recorded, for example a quiet room or a warehouse with fans'**
  String get environmentHelper;

  /// Environment preset.
  ///
  /// In en, this message translates to:
  /// **'Quiet room'**
  String get envQuietRoom;

  /// Environment preset.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get envWarehouse;

  /// Environment preset.
  ///
  /// In en, this message translates to:
  /// **'Fans or machines on'**
  String get envFansOn;

  /// Environment preset.
  ///
  /// In en, this message translates to:
  /// **'Outdoors'**
  String get envOutdoors;

  /// Sack material.
  ///
  /// In en, this message translates to:
  /// **'Jute'**
  String get materialJute;

  /// Sack material.
  ///
  /// In en, this message translates to:
  /// **'Woven polypropylene'**
  String get materialWovenPp;

  /// Sack material.
  ///
  /// In en, this message translates to:
  /// **'Cotton'**
  String get materialCotton;

  /// Container material.
  ///
  /// In en, this message translates to:
  /// **'Plastic container'**
  String get materialPlastic;

  /// Container material.
  ///
  /// In en, this message translates to:
  /// **'Metal container'**
  String get materialMetal;

  /// Material.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get materialOther;

  /// Form button.
  ///
  /// In en, this message translates to:
  /// **'Save labelled sample'**
  String get sampleSave;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Labelled sample saved on this phone'**
  String get sampleSaved;

  /// Repository rejected the label.
  ///
  /// In en, this message translates to:
  /// **'The label was not saved: {detail}'**
  String sampleRejected(String detail);

  /// RETRY recordings are never labelled.
  ///
  /// In en, this message translates to:
  /// **'This recording was not usable, so it cannot be labelled. Record it again in a quiet place.'**
  String get sampleUnusableRetry;

  /// No retained audio.
  ///
  /// In en, this message translates to:
  /// **'The audio for this recording was not kept, so it cannot be labelled.'**
  String get sampleUnusableNotKept;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get sampleRecordAgain;

  /// Samples screen title.
  ///
  /// In en, this message translates to:
  /// **'Research samples'**
  String get samplesTitle;

  /// Sample count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No labelled recordings yet} =1{1 labelled recording on this phone} other{{count} labelled recordings on this phone}}'**
  String samplesSubtitle(int count);

  /// Research mode off note.
  ///
  /// In en, this message translates to:
  /// **'Research recording mode is off. Turn it on in Settings to record new samples.'**
  String get samplesResearchOff;

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'No labelled samples yet'**
  String get samplesEmpty;

  /// Empty state detail.
  ///
  /// In en, this message translates to:
  /// **'With research mode on, open a sack and choose \"Record labelled sample\".'**
  String get samplesEmptyDetail;

  /// Dataset export card.
  ///
  /// In en, this message translates to:
  /// **'Training dataset'**
  String get datasetTitle;

  /// Dataset export explanation.
  ///
  /// In en, this message translates to:
  /// **'A ZIP of the kept recordings and a CSV of their labels, written on this phone. You choose where to share it; Kernel never uploads it.'**
  String get datasetBody;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Export dataset'**
  String get datasetExport;

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'The dataset could not be created or shared. {detail}'**
  String datasetExportFailed(String detail);

  /// Sample label chip.
  ///
  /// In en, this message translates to:
  /// **'Label: {label}'**
  String sampleLabelChip(String label);

  /// Sample linked to an agreeing inspection.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by inspection'**
  String get sampleConfirmed;

  /// Inspection form title.
  ///
  /// In en, this message translates to:
  /// **'Physical inspection'**
  String get inspectionTitle;

  /// Form button.
  ///
  /// In en, this message translates to:
  /// **'Save inspection'**
  String get saveInspection;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Inspection saved'**
  String get inspectionSaved;

  /// Read-only AI panel, kept apart from the human finding.
  ///
  /// In en, this message translates to:
  /// **'AI prediction (not verified)'**
  String get aiPanelTitle;

  /// AI panel loading.
  ///
  /// In en, this message translates to:
  /// **'Loading the linked scan…'**
  String get aiPanelLoading;

  /// AI panel without a scan.
  ///
  /// In en, this message translates to:
  /// **'No scan linked. This inspection stands on its own.'**
  String get aiPanelNoScan;

  /// When the linked scan was taken.
  ///
  /// In en, this message translates to:
  /// **'Scanned {when}'**
  String scannedAt(String when);

  /// The prediction never pre-fills the finding.
  ///
  /// In en, this message translates to:
  /// **'Not used to fill in your finding'**
  String get aiPanelNotUsed;

  /// Human finding panel.
  ///
  /// In en, this message translates to:
  /// **'Your verified finding'**
  String get findingPanelTitle;

  /// Human finding explanation.
  ///
  /// In en, this message translates to:
  /// **'What you saw yourself when you checked the grain. This is stored separately from the AI prediction.'**
  String get findingPanelBody;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Choose what you found'**
  String get findingMissing;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Inspector name'**
  String get inspectorField;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Enter who inspected'**
  String get validationInspector;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Inspection date'**
  String get inspectionDateField;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Observations'**
  String get observationsField;

  /// Form helper.
  ///
  /// In en, this message translates to:
  /// **'What you saw, where, and how much'**
  String get observationsHelper;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Assign follow-up to (optional)'**
  String get assigneeFieldOptional;

  /// Form section.
  ///
  /// In en, this message translates to:
  /// **'Follow-up status'**
  String get followUpStatusTitle;

  /// Form section.
  ///
  /// In en, this message translates to:
  /// **'Evidence photos (optional)'**
  String get photosTitle;

  /// Photo privacy note.
  ///
  /// In en, this message translates to:
  /// **'Photos stay privately on this phone with this inspection. They are evidence of what you saw, not acoustic results, and are never uploaded.'**
  String get photosBody;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get photoTake;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoPick;

  /// Snackbar when the camera is denied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Allow it in the phone settings to take evidence photos.'**
  String get cameraDeniedPhoto;

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Could not add the photo: {detail}'**
  String photoFailed(String detail);

  /// Filter chip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Empty filtered list.
  ///
  /// In en, this message translates to:
  /// **'No open inspections match this filter.'**
  String get filterNoMatch;

  /// Batch setup title.
  ///
  /// In en, this message translates to:
  /// **'Choose a room or stack'**
  String get batchSetupTitle;

  /// Batch setup subtitle.
  ///
  /// In en, this message translates to:
  /// **'Kernel walks you through its sacks one at a time.'**
  String get batchSetupSubtitle;

  /// Sequential scanning note (never multi-sack).
  ///
  /// In en, this message translates to:
  /// **'One recording per sack. Kernel never scans several sacks at once.'**
  String get batchSequentialNote;

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'No rooms or stacks yet'**
  String get batchNoPlaces;

  /// Empty state detail.
  ///
  /// In en, this message translates to:
  /// **'Add a warehouse with its rooms and stacks, then register sacks in them.'**
  String get batchNoPlacesDetail;

  /// Batch place row.
  ///
  /// In en, this message translates to:
  /// **'{type} · {total, plural, =1{1 sack} other{{total} sacks}} · {needScan} need a scan'**
  String batchPlaceSubtitle(String type, int total, int needScan);

  /// Batch intro subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sacks to walk} =1{1 sack to walk, one at a time} other{{count} sacks to walk, one at a time}}'**
  String batchIntroSubtitle(int count);

  /// Toggle.
  ///
  /// In en, this message translates to:
  /// **'Skip sacks scanned today'**
  String get batchSkipToday;

  /// Toggle explanation.
  ///
  /// In en, this message translates to:
  /// **'Leave out sacks that already have a recording from today.'**
  String get batchSkipTodayBody;

  /// A sack in the walk list.
  ///
  /// In en, this message translates to:
  /// **'{position}. {label} · {grain}'**
  String batchWalkLine(int position, String label, String grain);

  /// Starts the session.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Start with 1 sack} other{Start with {count} sacks}}'**
  String batchStart(int count);

  /// Nothing to walk.
  ///
  /// In en, this message translates to:
  /// **'Every sack here already has a usable scan or was scanned today.'**
  String get batchNothingToWalk;

  /// Session progress.
  ///
  /// In en, this message translates to:
  /// **'Sack {position} of {total}'**
  String batchProgress(int position, int total);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Skip this sack'**
  String get batchSkipSack;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Stop session'**
  String get batchStop;

  /// Auto-advance countdown.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Next sack in 1 second} other{Next sack in {seconds} seconds}}'**
  String batchNextIn(int seconds);

  /// Countdown on the last sack.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Summary in 1 second} other{Summary in {seconds} seconds}}'**
  String batchSummaryIn(int seconds);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Next sack'**
  String get batchNextSack;

  /// Button on the last sack.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get batchFinish;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Record this sack again'**
  String get batchRetrySack;

  /// Batch summary title.
  ///
  /// In en, this message translates to:
  /// **'Session summary'**
  String get batchSummaryTitle;

  /// Batch summary subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sack in this session} other{{count} sacks in this session}}'**
  String batchSummarySubtitle(int count);

  /// Stat label.
  ///
  /// In en, this message translates to:
  /// **'recorded'**
  String get batchStatRecorded;

  /// Stat label.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get batchStatSkipped;

  /// Stat label.
  ///
  /// In en, this message translates to:
  /// **'need a retry'**
  String get batchStatRetry;

  /// Queue section.
  ///
  /// In en, this message translates to:
  /// **'Ranked'**
  String get rankedTitle;

  /// Rank chip.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String rankLabel(int rank);

  /// Queue honesty note.
  ///
  /// In en, this message translates to:
  /// **'The order is a suggestion of what to check first. Inspect physically before any decision.'**
  String get queueSuggestionNote;

  /// Empty ranking.
  ///
  /// In en, this message translates to:
  /// **'No item has a usable model result yet, so nothing is ranked. Items without one are listed under \"Needs scan\".'**
  String get queueNothingRanked;

  /// Queue subtitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing ranked yet'**
  String get queueNothingRankedShort;

  /// Needs-scan group.
  ///
  /// In en, this message translates to:
  /// **'Needs scan ({count})'**
  String needsScanTitle(int count);

  /// Item without a valid, comparable scan.
  ///
  /// In en, this message translates to:
  /// **'Needs scan'**
  String get needsScanChip;

  /// Empty needs-scan group.
  ///
  /// In en, this message translates to:
  /// **'Every item has a usable scan.'**
  String get needsScanEmpty;

  /// Form button.
  ///
  /// In en, this message translates to:
  /// **'Save harvest'**
  String get saveHarvest;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Harvest name'**
  String get harvestNameField;

  /// Form helper.
  ///
  /// In en, this message translates to:
  /// **'For example \"Rabi wheat 2026\"'**
  String get harvestNameHelper;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Harvested on'**
  String get harvestedOnField;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesFieldOptional;

  /// App bar title.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get harvestAppBar;

  /// Unknown harvest id.
  ///
  /// In en, this message translates to:
  /// **'This harvest was not found on this phone.'**
  String get harvestNotFound;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Register sack in this harvest'**
  String get harvestAddSack;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Sacks from this harvest'**
  String get harvestSacksTitle;

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'No sacks in this harvest yet'**
  String get harvestSacksEmpty;

  /// Empty state detail.
  ///
  /// In en, this message translates to:
  /// **'Register the sacks you filled from this harvest, then scan them before sale.'**
  String get harvestSacksEmptyDetail;

  /// Pre-sale report explanation.
  ///
  /// In en, this message translates to:
  /// **'A summary of this harvest\'s sacks for a buyer. Scans show their model version and experimental status, and verified inspection findings are listed separately. It is not a quality certificate.'**
  String get preSaleBody;

  /// Item with no scans.
  ///
  /// In en, this message translates to:
  /// **'Not scanned yet'**
  String get notScannedYet;

  /// App bar title.
  ///
  /// In en, this message translates to:
  /// **'Lot'**
  String get lotAppBar;

  /// Unknown lot id.
  ///
  /// In en, this message translates to:
  /// **'This lot was not found on this phone.'**
  String get lotNotFound;

  /// Lot without supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier not recorded'**
  String get supplierNotRecorded;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Declared quantity'**
  String get fieldDeclaredQuantity;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get fieldReceived;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Screened'**
  String get fieldScreened;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Screening status'**
  String get screeningStatusTitle;

  /// Human-set status explanation. Keep the only mention of accepting.
  ///
  /// In en, this message translates to:
  /// **'You set this after reviewing scans and physical checks. Scans never change it, and Kernel never accepts or rejects a lot.'**
  String get screeningStatusBody;

  /// Current screening status chip.
  ///
  /// In en, this message translates to:
  /// **'Current: {status}'**
  String currentStatus(String status);

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Sacks in this lot'**
  String get lotSacksTitle;

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'No sacks in this lot yet'**
  String get lotSacksEmpty;

  /// Empty state action.
  ///
  /// In en, this message translates to:
  /// **'Register a sack in this lot'**
  String get lotSacksEmptyAction;

  /// Buyer sample scans section.
  ///
  /// In en, this message translates to:
  /// **'Sample scans'**
  String get sampleScansTitle;

  /// Sample scans explanation.
  ///
  /// In en, this message translates to:
  /// **'Scan sacks from this delivery one at a time. Each result is an unverified model output and does not change the lot\'s status.'**
  String get sampleScansBody;

  /// Starts a sequential session for this lot.
  ///
  /// In en, this message translates to:
  /// **'Start sample scans'**
  String get sampleScansStart;

  /// Buyer physical checks section.
  ///
  /// In en, this message translates to:
  /// **'Physical checks'**
  String get physicalChecksTitle;

  /// Physical checks explanation.
  ///
  /// In en, this message translates to:
  /// **'Open and look inside each sack, then record what you found. Your findings are kept apart from the scans.'**
  String get physicalChecksBody;

  /// Tooltip/button.
  ///
  /// In en, this message translates to:
  /// **'Record physical check'**
  String get recordPhysicalCheck;

  /// Sack without an inspection.
  ///
  /// In en, this message translates to:
  /// **'No physical check yet'**
  String get noPhysicalCheckYet;

  /// Lot summary export title.
  ///
  /// In en, this message translates to:
  /// **'Lot {code} summary report'**
  String lotSummaryTitle(String code);

  /// Lot summary explanation.
  ///
  /// In en, this message translates to:
  /// **'Sample scans with model provenance, and physical check findings listed separately, from records on this phone. Use it to support your own decision.'**
  String get lotSummaryBody;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved lot {code}'**
  String savedLot(String code);

  /// Form button.
  ///
  /// In en, this message translates to:
  /// **'Save lot'**
  String get saveLot;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Lot code'**
  String get lotCodeField;

  /// Form helper.
  ///
  /// In en, this message translates to:
  /// **'The reference on the delivery note'**
  String get lotCodeHelper;

  /// Form validation.
  ///
  /// In en, this message translates to:
  /// **'Enter the lot code'**
  String get validationLotCode;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Supplier name (optional)'**
  String get supplierFieldOptional;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Declared quantity'**
  String get declaredQuantityField;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Received on'**
  String get receivedOnField;

  /// Share sheet subject for an exported file.
  ///
  /// In en, this message translates to:
  /// **'Kernel {title}'**
  String shareSubject(String title);

  /// Export error.
  ///
  /// In en, this message translates to:
  /// **'The report could not be created or shared. {detail}'**
  String exportFailed(String detail);

  /// Export panel explanation.
  ///
  /// In en, this message translates to:
  /// **'Built only from records stored on this phone. Every scan shows its model version and experimental status. AI predictions and verified inspection findings are listed separately.'**
  String get exportPanelBody;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// Sack labels export button.
  ///
  /// In en, this message translates to:
  /// **'Create labels PDF'**
  String get exportLabelsPdf;

  /// Where the exported file was written.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone: {path}'**
  String exportSavedAt(String path);

  /// Sack label export card.
  ///
  /// In en, this message translates to:
  /// **'Print sack labels'**
  String get sackLabelsTitle;

  /// Sack label export explanation.
  ///
  /// In en, this message translates to:
  /// **'A PDF of QR labels for these sacks. Print it and stick each label on its sack; scanning a label opens that sack in Kernel.'**
  String get sackLabelsBody;

  /// Reports tab title.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// Where to find the harvest pre-sale report.
  ///
  /// In en, this message translates to:
  /// **'The pre-sale summary for one harvest is on that harvest\'s page.'**
  String get reportsFarmerHint;

  /// Where to find the lot summary report.
  ///
  /// In en, this message translates to:
  /// **'The lot summary report is on each lot\'s page.'**
  String get reportsBuyerHint;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Recent scans'**
  String get recentScans;

  /// Empty list.
  ///
  /// In en, this message translates to:
  /// **'No scans yet. Scans you record appear here.'**
  String get recentScansEmpty;

  /// Inventory subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your harvests and registered sacks'**
  String get inventorySubtitleFarmer;

  /// Inventory subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your grain containers and where they are kept'**
  String get inventorySubtitleHousehold;

  /// Inventory subtitle.
  ///
  /// In en, this message translates to:
  /// **'Warehouses, rooms, stacks and sacks'**
  String get inventorySubtitleFpo;

  /// Inventory subtitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming lots and their sacks'**
  String get inventorySubtitleBuyer;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'New harvest'**
  String get newHarvestAction;

  /// Register an item.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Add container} other{Register sack}}'**
  String registerItemAction(String kind);

  /// Household: add a place.
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get addPlace;

  /// Add a warehouse, room or stack.
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get addLocation;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Containers} other{Sacks}}'**
  String itemsSectionTitle(String kind);

  /// Empty section.
  ///
  /// In en, this message translates to:
  /// **'No lots yet. Register a delivery to add one.'**
  String get lotsSectionEmpty;

  /// Household places section.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get placesTitle;

  /// FPO locations section.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locationsTitle;

  /// Empty section.
  ///
  /// In en, this message translates to:
  /// **'No places yet. Add one to say where containers are kept.'**
  String get placesEmpty;

  /// Empty section.
  ///
  /// In en, this message translates to:
  /// **'No warehouse yet. Add one, then its rooms and stacks.'**
  String get locationsEmpty;

  /// Empty section.
  ///
  /// In en, this message translates to:
  /// **'No harvests yet. Create one to group its sacks and build a pre-sale summary.'**
  String get harvestsSectionEmpty;

  /// Harvest card subtitle.
  ///
  /// In en, this message translates to:
  /// **'{grain} · harvested {date}'**
  String harvestCardSubtitle(String grain, String date);

  /// Sack count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sacks yet} =1{1 sack} other{{count} sacks}}'**
  String sackCount(int count);

  /// App bar title.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get itemDetailAppBar;

  /// Unknown item id.
  ///
  /// In en, this message translates to:
  /// **'This item was not found on this phone.'**
  String get itemNotFound;

  /// Menu item.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Archive container} other{Archive sack}}'**
  String archiveItemMenu(String kind);

  /// Snackbar after archiving.
  ///
  /// In en, this message translates to:
  /// **'Archived. Its history is kept on this phone.'**
  String get archivedSnack;

  /// Banner on an archived item.
  ///
  /// In en, this message translates to:
  /// **'Hidden from lists, queues and new reports. Its scan history and inspections are kept.'**
  String get archivedItemNotice;

  /// Unarchive button.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Scan this container} other{Scan this sack}}'**
  String scanThisItem(String kind);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Set re-check reminder'**
  String get setReminderAction;

  /// Research mode entry on an item.
  ///
  /// In en, this message translates to:
  /// **'Record labelled sample'**
  String get researchRecordTitle;

  /// Research mode entry subtitle.
  ///
  /// In en, this message translates to:
  /// **'Research mode: keep a 2-second recording and label it for training data'**
  String get researchRecordSubtitle;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fieldQuantity;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Stored since'**
  String get fieldStoredSince;

  /// Storage date and days.
  ///
  /// In en, this message translates to:
  /// **'{date} ({days, plural, =1{1 day} other{{days} days}})'**
  String storedSinceValue(String date, int days);

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get fieldLocation;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Lot'**
  String get fieldLot;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get fieldHarvest;

  /// A name with its type.
  ///
  /// In en, this message translates to:
  /// **'{name} ({type})'**
  String nameWithType(String name, String type);

  /// Which role registered the item.
  ///
  /// In en, this message translates to:
  /// **'Registered as {role}'**
  String registeredAs(String role);

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Scan history'**
  String get scanHistoryTitle;

  /// Append-only explanation.
  ///
  /// In en, this message translates to:
  /// **'Every scan is kept as recorded. A new scan never changes an earlier one.'**
  String get scanHistoryAppendOnly;

  /// Empty history.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{No scans yet. Use \"Scan this container\" to record one.} other{No scans yet. Use \"Scan this sack\" to record one.}}'**
  String scanHistoryEmpty(String kind);

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Inspections'**
  String get inspectionsTitle;

  /// Empty list.
  ///
  /// In en, this message translates to:
  /// **'No inspections recorded yet.'**
  String get inspectionsEmpty;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// Empty list.
  ///
  /// In en, this message translates to:
  /// **'No reminders set.'**
  String get remindersEmpty;

  /// Reminder row.
  ///
  /// In en, this message translates to:
  /// **'Re-check on {when}'**
  String recheckOn(String when);

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get reminderMarkDone;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel reminder'**
  String get reminderCancel;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Assign inspection'**
  String get assignDialogTitle;

  /// Text field label.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignDialogLabel;

  /// Text field helper.
  ///
  /// In en, this message translates to:
  /// **'Who will do the follow-up check'**
  String get assignDialogHelper;

  /// Clears the assignee.
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get assignClear;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String savedNamed(String name);

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {detail}'**
  String saveFailed(String detail);

  /// Form button.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Save container} other{Save sack}}'**
  String saveItem(String kind);

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Container label} other{Sack label}}'**
  String itemLabelField(String kind);

  /// Form helper.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{The name written on the container} other{The name written on the sack}}'**
  String itemLabelHelper(String kind);

  /// Form validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a label'**
  String get validationLabel;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Grain type'**
  String get grainTypeField;

  /// Form validation.
  ///
  /// In en, this message translates to:
  /// **'Enter the grain type'**
  String get validationGrain;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityField;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitField;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Storage date'**
  String get storageDateField;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Harvest (optional)'**
  String get harvestFieldOptional;

  /// Form helper.
  ///
  /// In en, this message translates to:
  /// **'No harvests yet. Create one from My Grain.'**
  String get harvestFieldNone;

  /// Empty picker option.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get locationFieldOptional;

  /// Form helper.
  ///
  /// In en, this message translates to:
  /// **'No places yet. You can add them from {where}.'**
  String locationFieldNone(String where);

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Lot (optional)'**
  String get lotFieldOptional;

  /// Form helper.
  ///
  /// In en, this message translates to:
  /// **'No lots registered yet.'**
  String get lotFieldNone;

  /// App bar title.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationAppBar;

  /// Unknown location id.
  ///
  /// In en, this message translates to:
  /// **'This location was not found on this phone.'**
  String get locationNotFound;

  /// Archived location note.
  ///
  /// In en, this message translates to:
  /// **'This place is archived. Its sacks and their history are kept.'**
  String get archivedLocationNotice;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Add container here} other{Register sack here}}'**
  String registerHere(String kind);

  /// Add a child location.
  ///
  /// In en, this message translates to:
  /// **'Add inside'**
  String get addInside;

  /// Start a batch session for this place.
  ///
  /// In en, this message translates to:
  /// **'Batch scan here'**
  String get batchHere;

  /// Child locations section.
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get insideTitle;

  /// Empty section.
  ///
  /// In en, this message translates to:
  /// **'Nothing inside this location yet.'**
  String get insideEmpty;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Containers here} other{Sacks here}}'**
  String itemsHereTitle(String kind);

  /// Empty section.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{No containers stored here yet.} other{No sacks stored here yet.}}'**
  String itemsHereEmpty(String kind);

  /// Form button.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get saveLocation;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeField;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameField;

  /// Form validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get validationName;

  /// Form field.
  ///
  /// In en, this message translates to:
  /// **'Inside (optional)'**
  String get parentFieldOptional;

  /// Form helper.
  ///
  /// In en, this message translates to:
  /// **'For example a room inside a warehouse'**
  String get parentFieldHelper;

  /// Top-level option.
  ///
  /// In en, this message translates to:
  /// **'Nothing (top level)'**
  String get parentTopLevel;

  /// Role selection title (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get roleSelectTitle;

  /// Role selection subtitle (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'One app. Four workflows.'**
  String get roleSelectSubtitle;

  /// Marks the active role.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get roleCurrent;

  /// Reassurance on role switch.
  ///
  /// In en, this message translates to:
  /// **'Switching role keeps every record on this phone. You can switch back at any time.'**
  String get roleSwitchKeepsRecords;

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Could not save your role: {detail}'**
  String roleSaveFailed(String detail);

  /// Start screen error.
  ///
  /// In en, this message translates to:
  /// **'Kernel could not open its local data on this phone. Please restart the app.\n\nDetails: {detail}'**
  String startDataError(String detail);

  /// Skip to the role page.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Previous onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// Next onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Onboarding progress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStep(int step, int total);

  /// Onboarding page 1 title.
  ///
  /// In en, this message translates to:
  /// **'Audio stays on your phone'**
  String get onboardingPrivacyTitle;

  /// Onboarding privacy point.
  ///
  /// In en, this message translates to:
  /// **'Kernel listens to grain for 2 seconds and checks the sound right here on this phone.'**
  String get onboardingPrivacy1;

  /// Onboarding privacy point.
  ///
  /// In en, this message translates to:
  /// **'Nothing is uploaded. There is no account and no cloud, and everything works offline.'**
  String get onboardingPrivacy2;

  /// Onboarding privacy point.
  ///
  /// In en, this message translates to:
  /// **'Recordings are deleted after the check unless you choose to keep them in Settings.'**
  String get onboardingPrivacy3;

  /// Onboarding page 2 title.
  ///
  /// In en, this message translates to:
  /// **'How to scan'**
  String get onboardingHowTitle;

  /// Scan positioning step.
  ///
  /// In en, this message translates to:
  /// **'Lay the phone flat against the sack or container, microphone touching it.'**
  String get onboardingHow1;

  /// Scan environment step.
  ///
  /// In en, this message translates to:
  /// **'Choose a quiet room. Stop talking and switch off fans if you can.'**
  String get onboardingHow2;

  /// Scan duration step.
  ///
  /// In en, this message translates to:
  /// **'Hold still for 2 seconds while Kernel listens.'**
  String get onboardingHow3;

  /// Honesty note in onboarding.
  ///
  /// In en, this message translates to:
  /// **'Results are experimental. Always inspect the grain yourself before deciding.'**
  String get onboardingHow4;

  /// Onboarding page 3 title.
  ///
  /// In en, this message translates to:
  /// **'Pick your role'**
  String get onboardingRoleTitle;

  /// Small overline on the scan hero card.
  ///
  /// In en, this message translates to:
  /// **'Listen to your grain'**
  String get heroEyebrowListen;

  /// Hero card action.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get heroStartScan;

  /// FPO hero card action.
  ///
  /// In en, this message translates to:
  /// **'Start batch'**
  String get heroStartBatch;

  /// Placeholder while data loads.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// Farmer home title (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Farmer dashboard'**
  String get farmerHomeTitle;

  /// Farmer home subtitle with the latest harvest.
  ///
  /// In en, this message translates to:
  /// **'Harvest: {name}'**
  String farmerHomeHarvestSubtitle(String name);

  /// Farmer hero card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Scan grain'**
  String get farmerHeroTitle;

  /// Farmer hero card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Start a guided 2-second recording'**
  String get farmerHeroSubtitle;

  /// Farmer empty state detail.
  ///
  /// In en, this message translates to:
  /// **'Register a sack to start scanning and tracking it.'**
  String get farmerEmptyDetail;

  /// Count of registered sacks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 registered sack} other{{count} registered sacks}}'**
  String registeredSacks(int count);

  /// Farmer summary when nothing is open.
  ///
  /// In en, this message translates to:
  /// **'No follow-up inspections open'**
  String get noFollowUps;

  /// Open inspection count (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sack requires follow-up inspection} other{{count} sacks require follow-up inspection}}'**
  String sacksRequireFollowUp(int count);

  /// Farmer harvests card/section.
  ///
  /// In en, this message translates to:
  /// **'Harvests'**
  String get harvestsTitle;

  /// Harvests card with no harvests.
  ///
  /// In en, this message translates to:
  /// **'Create a harvest to group its sacks for the pre-sale report'**
  String get harvestsEmptyCard;

  /// Harvest count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 harvest · open the latest} other{{count} harvests · open the latest}}'**
  String harvestsCount(int count);

  /// Ranked inspection queue.
  ///
  /// In en, this message translates to:
  /// **'Inspection queue'**
  String get queueTitle;

  /// Queue card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Which sacks to check first'**
  String get queueCardSubtitle;

  /// Pre-sale report card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Export a summary built from your stored records'**
  String get preSaleCardSubtitle;

  /// Pre-sale report card subtitle with a harvest.
  ///
  /// In en, this message translates to:
  /// **'Pre-sale summary for {name}'**
  String preSaleCardHarvest(String name);

  /// Household home title (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Household storage'**
  String get householdHomeTitle;

  /// Household home subtitle (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Home grain tracker'**
  String get householdHomeSubtitle;

  /// Household hero card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Scan a container'**
  String get householdHeroTitle;

  /// Household hero card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Record grain condition'**
  String get householdHeroSubtitle;

  /// Household empty state detail.
  ///
  /// In en, this message translates to:
  /// **'Add a grain container to track its storage time.'**
  String get householdEmptyDetail;

  /// Household reminders card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Inspection reminders'**
  String get remindersCardTitle;

  /// Reminders card with nothing scheduled.
  ///
  /// In en, this message translates to:
  /// **'No reminders scheduled. Open a container to set one.'**
  String get remindersCardEmpty;

  /// Reminder count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reminder scheduled} other{{count} reminders scheduled}}'**
  String remindersScheduled(int count);

  /// Container card title (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'{grain} / {place}'**
  String containerTitle(String grain, String place);

  /// Days since the storage date.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Stored 1 day} other{Stored {days} days}}'**
  String storedDays(int days);

  /// Review status for a container never scanned.
  ///
  /// In en, this message translates to:
  /// **'Not scanned yet — review due'**
  String get reviewNeverScanned;

  /// Review status when the last usable scan is old.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Review due — last scanned 1 day ago} other{Review due — last scanned {days} days ago}}'**
  String reviewDueSince(int days);

  /// Review status when recently scanned.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Next review in 1 day} other{Next review in {days} days}}'**
  String reviewNextIn(int days);

  /// A reminder is due now.
  ///
  /// In en, this message translates to:
  /// **'Review due'**
  String get reviewDue;

  /// Next reminder chip.
  ///
  /// In en, this message translates to:
  /// **'Reminder {date}'**
  String reminderOn(String date);

  /// Shortcut to scan a container again.
  ///
  /// In en, this message translates to:
  /// **'Recheck'**
  String get recheckAction;

  /// Opens the reminder sheet.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMeAction;

  /// Reminder sheet title.
  ///
  /// In en, this message translates to:
  /// **'Set a re-check reminder'**
  String get reminderSheetTitle;

  /// Reminder sheet subtitle.
  ///
  /// In en, this message translates to:
  /// **'For {label}. Kernel reminds you on this phone.'**
  String reminderSheetSubtitle(String label);

  /// Reminder preset chip.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{In 1 day} other{In {days} days}}'**
  String reminderInDays(int days);

  /// Reminder date field.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reminderDateLabel;

  /// Reminder time field.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reminderTimeLabel;

  /// Reminder sheet note.
  ///
  /// In en, this message translates to:
  /// **'The reminder is scheduled on this phone and works offline.'**
  String get reminderOnDeviceNote;

  /// Reminder sheet button.
  ///
  /// In en, this message translates to:
  /// **'Save reminder'**
  String get reminderSave;

  /// Reminder validation.
  ///
  /// In en, this message translates to:
  /// **'Choose a time in the future.'**
  String get reminderPastError;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get reminderSet;

  /// Snackbar when notifications are not allowed.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved. Notifications are off, so it will only show inside the app.'**
  String get reminderSetNotificationsOff;

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Could not set reminder: {detail}'**
  String reminderFailed(String detail);

  /// FPO home title (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Warehouse overview'**
  String get fpoHomeTitle;

  /// FPO home subtitle with no places yet.
  ///
  /// In en, this message translates to:
  /// **'Warehouses, rooms and stacks'**
  String get fpoHomeSubtitle;

  /// FPO empty state detail.
  ///
  /// In en, this message translates to:
  /// **'Register sacks, then scan them one at a time to build an inspection queue.'**
  String get fpoEmptyDetail;

  /// Distinct sacks scanned since midnight.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sack scanned today} other{{count} sacks scanned today}}'**
  String sacksScannedToday(int count);

  /// Queue card subtitle.
  ///
  /// In en, this message translates to:
  /// **'{flagged} flagged · {needScan, plural, =1{1 sack needs a scan} other{{needScan} sacks need a scan}}'**
  String queueSummary(int flagged, int needScan);

  /// FPO assigned inspections (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Assigned inspections'**
  String get assignedTitle;

  /// Assigned card with nothing open.
  ///
  /// In en, this message translates to:
  /// **'No open inspections'**
  String get assignedNone;

  /// Open inspection count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 inspection open} other{{count} inspections open}}'**
  String inspectionsOpen(int count);

  /// FPO card.
  ///
  /// In en, this message translates to:
  /// **'Add warehouse, room or stack'**
  String get fpoAddLocationTitle;

  /// FPO card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Organise sacks by where they are stored'**
  String get fpoAddLocationSubtitle;

  /// Buyer home title (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Incoming lots'**
  String get buyerHomeTitle;

  /// Buyer home subtitle (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Procurement screening'**
  String get buyerHomeSubtitle;

  /// Buyer hero overline.
  ///
  /// In en, this message translates to:
  /// **'New delivery'**
  String get heroEyebrowDelivery;

  /// Buyer hero card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Register delivery'**
  String get buyerHeroTitle;

  /// Buyer hero card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Supplier, lot, grain, quantity'**
  String get buyerHeroSubtitle;

  /// Buyer hero action.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get buyerHeroAction;

  /// Buyer empty state.
  ///
  /// In en, this message translates to:
  /// **'No lots yet'**
  String get lotsEmptyMessage;

  /// Buyer empty state detail.
  ///
  /// In en, this message translates to:
  /// **'Register a delivery to screen its sacks.'**
  String get lotsEmptyDetail;

  /// Buyer empty state action.
  ///
  /// In en, this message translates to:
  /// **'Register your first delivery'**
  String get lotsEmptyAction;

  /// Buyer report card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Inspection report'**
  String get buyerReportCardTitle;

  /// Buyer report card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Export lot screening from your stored records'**
  String get buyerReportCardSubtitle;

  /// Lot card title (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'{code} / {grain}'**
  String lotTitle(String code, String grain);

  /// Lot card subtitle with no sacks.
  ///
  /// In en, this message translates to:
  /// **'No sacks registered in this lot yet'**
  String get lotNoSacks;

  /// Sacks with a valid, comparable scan (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'{screened} of {total, plural, =1{1 sack} other{{total} sacks}} screened'**
  String lotScreenedCount(int screened, int total);

  /// Supplier chip.
  ///
  /// In en, this message translates to:
  /// **'Supplier: {name}'**
  String supplierChip(String name);

  /// App bar title on the guided scan screen.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanAppBarTitle;

  /// Guided scan screen title (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Guided acoustic scan'**
  String get guidedScanTitle;

  /// Title of the research recording screen.
  ///
  /// In en, this message translates to:
  /// **'Record labelled sample'**
  String get researchScanTitle;

  /// Grain type and item label.
  ///
  /// In en, this message translates to:
  /// **'{grain} • {label}'**
  String grainAndLabel(String grain, String label);

  /// Banner title.
  ///
  /// In en, this message translates to:
  /// **'Research recording'**
  String get researchScanNoticeTitle;

  /// Explains research recording mode.
  ///
  /// In en, this message translates to:
  /// **'This 2-second recording is kept privately on this phone so you can label it for training data. It is not shown as a pest result and is never uploaded.'**
  String get researchScanNotice;

  /// Positioning tip shown before every scan.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Press phone against the container, keep still and quiet} other{Press phone against sack, keep still and quiet}}'**
  String positioningTip(String kind);

  /// Detail of the positioning tip.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Lay the phone flat on the container with the microphone touching it, in a quiet room. Stop talking and do not move it for 2 seconds.} other{Lay the phone flat on the sack with the microphone touching it, in a quiet place. Stop talking and do not move the sack for 2 seconds.}}'**
  String positioningTipDetail(String kind);

  /// Info card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Recording quality'**
  String get infoQualityTitle;

  /// Info card body.
  ///
  /// In en, this message translates to:
  /// **'Checked for background noise, clipping and silence before any result is shown.'**
  String get infoQualityBody;

  /// Info card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Capture duration'**
  String get infoDurationTitle;

  /// Capture duration before the engine reports its rate.
  ///
  /// In en, this message translates to:
  /// **'2 s'**
  String get infoDurationShort;

  /// Capture duration and target sample rate.
  ///
  /// In en, this message translates to:
  /// **'2 s at {khz} kHz'**
  String infoDurationRate(String khz);

  /// Info card (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'On-device inference'**
  String get infoOnDeviceTitle;

  /// Info card body (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'No upload required'**
  String get infoOnDeviceBody;

  /// Info card body with model provenance.
  ///
  /// In en, this message translates to:
  /// **'No upload required. {provenance}'**
  String infoOnDeviceWithModel(String provenance);

  /// Mic permission denied screen title.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off'**
  String get micDeniedTitle;

  /// Mic permission denied subtitle.
  ///
  /// In en, this message translates to:
  /// **'Kernel needs the microphone to listen to grain.'**
  String get micDeniedSubtitle;

  /// Privacy explanation on the mic-denied screen.
  ///
  /// In en, this message translates to:
  /// **'A scan records 2 seconds of sound and checks it on this phone. The sound is never uploaded, and it is deleted after the check unless you choose to keep recordings in Settings.'**
  String get micDeniedPrivacy;

  /// Shown when the permission is permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is blocked for Kernel. Open the phone settings, choose Permissions, then allow Microphone.'**
  String get micDeniedBlocked;

  /// Shown when the permission can be asked again.
  ///
  /// In en, this message translates to:
  /// **'You can allow it the next time Kernel asks, or in the phone settings.'**
  String get micDeniedAskAgain;

  /// The rest of the app keeps working.
  ///
  /// In en, this message translates to:
  /// **'Without the microphone you can still register items, browse your inventory, record physical inspections and export reports.'**
  String get micDeniedStillUsable;

  /// Opens the system app settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get actionOpenSettings;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Browse inventory'**
  String get actionBrowseInventory;

  /// App bar title on the result screen.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultAppBarTitle;

  /// Result screen title (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Screening result'**
  String get resultTitle;

  /// Shown for an unknown scan id.
  ///
  /// In en, this message translates to:
  /// **'This scan was not found on this phone.'**
  String get scanNotFound;

  /// RETRY results never store a class.
  ///
  /// In en, this message translates to:
  /// **'Nothing about pests was saved for this recording.'**
  String get retryNothingSaved;

  /// The AI prediction, always marked unverified.
  ///
  /// In en, this message translates to:
  /// **'Model prediction (unverified): {label}'**
  String predictedClassLine(String label);

  /// Raw model score. Never presented as accuracy.
  ///
  /// In en, this message translates to:
  /// **'Model score: {score} (experimental, not an accuracy figure)'**
  String modelScoreLine(String score);

  /// Title above the model's provenance note.
  ///
  /// In en, this message translates to:
  /// **'Experimental model — not validated'**
  String get modelNoteTitleExperimental;

  /// Title above the model's provenance note.
  ///
  /// In en, this message translates to:
  /// **'About this model'**
  String get modelNoteTitle;

  /// When the scan's model differs from the installed one.
  ///
  /// In en, this message translates to:
  /// **'This scan used model {version}, which is no longer installed. Its provenance note is not stored with the scan, so treat the result as experimental.'**
  String modelNoteOtherVersion(String version);

  /// Shown with every result.
  ///
  /// In en, this message translates to:
  /// **'Acoustic screening is experimental. A physical inspection is required before any storage or sale decision.'**
  String get physicalInspectionNote;

  /// Rescan after an unusable recording.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Opens the physical inspection form.
  ///
  /// In en, this message translates to:
  /// **'Record inspection'**
  String get actionRecordInspection;

  /// Back to the scan picker.
  ///
  /// In en, this message translates to:
  /// **'Scan another'**
  String get actionScanAnother;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Recording details'**
  String get recordingDetails;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get fieldCaptured;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get fieldDuration;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Sample rate'**
  String get fieldSampleRate;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Analysis time'**
  String get fieldAnalysisTime;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get fieldDevice;

  /// Milliseconds.
  ///
  /// In en, this message translates to:
  /// **'{value} ms'**
  String unitMs(int value);

  /// Hertz.
  ///
  /// In en, this message translates to:
  /// **'{value} Hz'**
  String unitHz(int value);

  /// Device model and OS version.
  ///
  /// In en, this message translates to:
  /// **'{device} ({os})'**
  String deviceAndOs(String device, String os);

  /// Scan tab subtitle.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Choose the container to listen to} other{Choose the sack to listen to}}'**
  String scanTabSubtitle(String kind);

  /// FPO batch scan entry (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Batch scan'**
  String get batchScanTitle;

  /// FPO batch scan entry subtitle (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Scan sacks one at a time'**
  String get batchScanSubtitle;

  /// Card that opens the QR scanner.
  ///
  /// In en, this message translates to:
  /// **'Open from a QR label'**
  String get qrCardTitle;

  /// QR card subtitle.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Point the camera at a Kernel label to open that container} other{Point the camera at a Kernel sack label to open that sack}}'**
  String qrCardSubtitle(String kind);

  /// Explains single-item scanning.
  ///
  /// In en, this message translates to:
  /// **'One at a time'**
  String get oneAtATimeTitle;

  /// Explains single-item scanning (never multi-sack).
  ///
  /// In en, this message translates to:
  /// **'Each recording belongs to one item. Scan items one after another; a scan never covers several at once.'**
  String get oneAtATimeBody;

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{No containers yet} other{No sacks yet}}'**
  String emptyItemsMessage(String kind);

  /// Empty state's single next action.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Add your first container} other{Register your first sack}}'**
  String emptyItemsAction(String kind);

  /// Empty state detail on the Scan tab.
  ///
  /// In en, this message translates to:
  /// **'Register one first, then come back to scan it.'**
  String get scanTabEmptyDetail;

  /// Screen listing today's scans.
  ///
  /// In en, this message translates to:
  /// **'Scanned today'**
  String get scansTodayTitle;

  /// Counts from ScanRepository.watchSince.
  ///
  /// In en, this message translates to:
  /// **'{scans, plural, =1{1 scan} other{{scans} scans}} of {items, plural, =1{1 item} other{{items} items}} since midnight'**
  String scansTodaySummary(int scans, int items);

  /// Empty list.
  ///
  /// In en, this message translates to:
  /// **'No scans yet today. Scans you record appear here straight away.'**
  String get scansTodayEmpty;

  /// Badge next to every model-derived value.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get experimentalBadge;

  /// Prefix for a data loading error.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get errorCouldNotLoad;

  /// An error message with technical details.
  ///
  /// In en, this message translates to:
  /// **'{prefix}: {detail}'**
  String errorWithDetail(String prefix, String detail);

  /// Label of a label/value row.
  ///
  /// In en, this message translates to:
  /// **'{label}:'**
  String fieldLabel(String label);

  /// Form validation.
  ///
  /// In en, this message translates to:
  /// **'Enter the quantity'**
  String get validationQuantityEmpty;

  /// Form validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a number above 0'**
  String get validationQuantityPositive;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Connectivity indicator. Informational only.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineLabel;

  /// Connectivity indicator. Informational only.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineLabel;

  /// Screen reader text for the indicator.
  ///
  /// In en, this message translates to:
  /// **'Offline. Everything keeps working on this phone.'**
  String get offlineSemantics;

  /// Screen reader text for the indicator.
  ///
  /// In en, this message translates to:
  /// **'Online. Kernel does not need the network.'**
  String get onlineSemantics;

  /// App bar QR button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Open a sack from its QR label'**
  String get qrTooltip;

  /// App bar overflow menu tooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// Menu item.
  ///
  /// In en, this message translates to:
  /// **'Switch role'**
  String get menuSwitchRole;

  /// Menu item.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// Second line of a sack/container tile.
  ///
  /// In en, this message translates to:
  /// **'{grain} · {quantity} · stored {date}'**
  String itemTileSubtitle(String grain, String quantity, String date);

  /// Badge on an archived record (history kept).
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedBadge;

  /// Scan chip when the recording was unusable.
  ///
  /// In en, this message translates to:
  /// **'Retry needed'**
  String get chipRetryNeeded;

  /// Scan chip for a model prediction. Always marked unverified.
  ///
  /// In en, this message translates to:
  /// **'AI: {label} (unverified)'**
  String chipAiUnverified(String label);

  /// Scan history row title.
  ///
  /// In en, this message translates to:
  /// **'{item} · {when}'**
  String scanTileTitle(String item, String when);

  /// Recording quality chip.
  ///
  /// In en, this message translates to:
  /// **'Quality: {quality}'**
  String qualityChip(String quality);

  /// The recording for this scan was retained (opt-in).
  ///
  /// In en, this message translates to:
  /// **'Audio kept on phone'**
  String get chipAudioKept;

  /// Screen reader label for an inspection photo thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Evidence photo {number}. Opens full size.'**
  String photoSemantics(int number);

  /// Shown when a photo file is missing.
  ///
  /// In en, this message translates to:
  /// **'This photo is no longer on this phone.'**
  String get photoMissing;

  /// Tooltip on an unsaved photo.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemove;

  /// Human inspection result line.
  ///
  /// In en, this message translates to:
  /// **'Verified finding: {finding}'**
  String verifiedFindingLine(String finding);

  /// Who inspected and when.
  ///
  /// In en, this message translates to:
  /// **'{inspector} · {when}'**
  String inspectorLine(String inspector, String when);

  /// Follow-up status chip.
  ///
  /// In en, this message translates to:
  /// **'Follow-up: {status}'**
  String followUpChip(String status);

  /// Inspection has no assignee.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// Inspection assignee chip.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String assignedToChip(String name);

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Change follow-up status'**
  String get followUpChangeTooltip;

  /// Button to change an inspection's follow-up status.
  ///
  /// In en, this message translates to:
  /// **'Update status'**
  String get followUpUpdate;

  /// Button to assign an inspection to a person.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignAction;

  /// Archive (soft delete) button.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveAction;

  /// Archive confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String archiveConfirmTitle(String name);

  /// Archive confirm for a sack or container.
  ///
  /// In en, this message translates to:
  /// **'It will be hidden from lists, queues and new reports. Its scan history and inspections are kept on this phone and are not deleted.'**
  String get archiveConfirmItemBody;

  /// Archive confirm for a lot.
  ///
  /// In en, this message translates to:
  /// **'The lot will be hidden from your lists and new reports. Its sacks, their scan history and inspections are kept on this phone.'**
  String get archiveConfirmLotBody;

  /// Archive confirm for a location.
  ///
  /// In en, this message translates to:
  /// **'The place will be hidden from lists and pickers. Sacks stored there, their scan history and inspections are kept on this phone.'**
  String get archiveConfirmLocationBody;

  /// Archive confirm for a harvest.
  ///
  /// In en, this message translates to:
  /// **'The harvest will be hidden from your lists and new reports. Its sacks, their scan history and inspections are kept on this phone.'**
  String get archiveConfirmHarvestBody;

  /// Screen reader label for the live level meter.
  ///
  /// In en, this message translates to:
  /// **'Microphone level'**
  String get levelMeterLabel;

  /// Level meter value before levels arrive.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sound'**
  String get levelMeterWaiting;

  /// Current input level in decibels relative to full scale.
  ///
  /// In en, this message translates to:
  /// **'{dbfs} dBFS'**
  String levelMeterValue(int dbfs);

  /// Spoken prompt before recording (voice prompts setting).
  ///
  /// In en, this message translates to:
  /// **'Place phone on the sack'**
  String get voicePlacePhone;

  /// Spoken prompt when recording starts.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get voiceListening;

  /// Spoken prompt when recording ends.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get voiceDone;

  /// Error when the scan engine failed.
  ///
  /// In en, this message translates to:
  /// **'The scan could not run: {detail}'**
  String scanCouldNotRun(String detail);

  /// Error when the repository refused the outcome.
  ///
  /// In en, this message translates to:
  /// **'The scan result could not be saved, so nothing was stored. Details: {detail}'**
  String scanCouldNotSave(String detail);

  /// Capture card title before recording (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Ready to listen'**
  String get captureReady;

  /// Capture card title while recording.
  ///
  /// In en, this message translates to:
  /// **'Listening — keep still'**
  String get captureListening;

  /// Capture card title while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving on this phone'**
  String get captureSaving;

  /// Capture card title while asking for the mic.
  ///
  /// In en, this message translates to:
  /// **'Checking microphone access'**
  String get captureCheckingMic;

  /// Capture card title while voice prompts play.
  ///
  /// In en, this message translates to:
  /// **'Get ready — place the phone'**
  String get captureGetReady;

  /// Capture card subtitle (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Press phone against the container} other{Press phone against sack}}'**
  String captureSubtitle(String kind);

  /// Capture subtitle in research recording mode.
  ///
  /// In en, this message translates to:
  /// **'Research recording: the 2 seconds are kept privately on this phone for labelling'**
  String get captureResearchSubtitle;

  /// Start capture button.
  ///
  /// In en, this message translates to:
  /// **'Start 2-second recording'**
  String get captureStart;

  /// Start capture button after a failure.
  ///
  /// In en, this message translates to:
  /// **'Try the 2-second recording again'**
  String get captureStartAgain;

  /// Start button in research recording mode.
  ///
  /// In en, this message translates to:
  /// **'Record labelled sample (2 s)'**
  String get captureStartResearch;

  /// Screen reader label for the capture progress bar.
  ///
  /// In en, this message translates to:
  /// **'Recording progress'**
  String get captureProgressLabel;

  /// Screen reader value for progress.
  ///
  /// In en, this message translates to:
  /// **'{percent} percent'**
  String percentValue(int percent);

  /// Elapsed recording time from the engine's live levels.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} s of {target} s'**
  String captureElapsed(String elapsed, String target);

  /// Shown after recording while the quality gate runs.
  ///
  /// In en, this message translates to:
  /// **'Checking the recording on this phone…'**
  String get captureChecking;

  /// Live hint before the first level arrives.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get hintWaiting;

  /// Live hint: input RMS below about -65 dBFS.
  ///
  /// In en, this message translates to:
  /// **'Too quiet — press closer'**
  String get hintTooQuiet;

  /// Live hint: input peak above about -1 dBFS.
  ///
  /// In en, this message translates to:
  /// **'Too loud / rubbing'**
  String get hintTooLoud;

  /// Live hint while the level is usable.
  ///
  /// In en, this message translates to:
  /// **'Hold still'**
  String get hintHoldStill;

  /// App name shown in the task switcher and app bar.
  ///
  /// In en, this message translates to:
  /// **'Kernel'**
  String get appTitle;

  /// Role name.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleFarmer;

  /// Role name.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get roleHousehold;

  /// Role name: warehouse operator or farmer producer organisation.
  ///
  /// In en, this message translates to:
  /// **'Storage/FPO'**
  String get roleStorageFpo;

  /// Role name.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get roleBuyer;

  /// Role card subtitle (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Harvest and pre-sale checks'**
  String get roleFarmerTagline;

  /// Role card subtitle (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Containers and reminders'**
  String get roleHouseholdTagline;

  /// Role card subtitle (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Warehouse and batch inspections'**
  String get roleStorageFpoTagline;

  /// Role card subtitle (PRD wireframe).
  ///
  /// In en, this message translates to:
  /// **'Supplier and lot screening'**
  String get roleBuyerTagline;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// Bottom navigation tab before a role is known.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// Inventory tab label for the farmer role.
  ///
  /// In en, this message translates to:
  /// **'My Grain'**
  String get navInventoryFarmer;

  /// Inventory tab label for the household role.
  ///
  /// In en, this message translates to:
  /// **'My Containers'**
  String get navInventoryHousehold;

  /// Inventory tab label for the storage/FPO role.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get navInventoryFpo;

  /// Inventory tab label for the buyer role.
  ///
  /// In en, this message translates to:
  /// **'Lots'**
  String get navInventoryBuyer;

  /// Report name for the farmer role.
  ///
  /// In en, this message translates to:
  /// **'Pre-sale report'**
  String get reportTitleFarmer;

  /// Report name for the household role.
  ///
  /// In en, this message translates to:
  /// **'Storage report'**
  String get reportTitleHousehold;

  /// Report name for the storage/FPO role.
  ///
  /// In en, this message translates to:
  /// **'Warehouse report'**
  String get reportTitleFpo;

  /// Report name for the buyer role.
  ///
  /// In en, this message translates to:
  /// **'Lot screening report'**
  String get reportTitleBuyer;

  /// Location type.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get locationTypeHome;

  /// Location type.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get locationTypeContainer;

  /// Location type.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get locationTypeWarehouse;

  /// Location type.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get locationTypeRoom;

  /// Location type: a stack of sacks inside a room.
  ///
  /// In en, this message translates to:
  /// **'Stack'**
  String get locationTypeStack;

  /// Lot screening status, set by a person.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get screeningPending;

  /// Lot screening status, set by a person.
  ///
  /// In en, this message translates to:
  /// **'Screening'**
  String get screeningScreening;

  /// Lot screening status, set by a person.
  ///
  /// In en, this message translates to:
  /// **'Pending physical check'**
  String get screeningNeedsPhysicalCheck;

  /// Lot screening status, set by a person.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get screeningReviewed;

  /// Verified inspection finding (human).
  ///
  /// In en, this message translates to:
  /// **'None found'**
  String get findingNoneFound;

  /// Verified inspection finding (human).
  ///
  /// In en, this message translates to:
  /// **'Pests found'**
  String get findingPestsFound;

  /// Verified inspection finding (human).
  ///
  /// In en, this message translates to:
  /// **'Inconclusive'**
  String get findingInconclusive;

  /// Explains the 'None found' option.
  ///
  /// In en, this message translates to:
  /// **'I checked and saw no insects or damage'**
  String get findingNoneFoundHelp;

  /// Explains the 'Pests found' option.
  ///
  /// In en, this message translates to:
  /// **'I saw insects, larvae, webbing or damage'**
  String get findingPestsFoundHelp;

  /// Explains the 'Inconclusive' option.
  ///
  /// In en, this message translates to:
  /// **'I could not tell from the check'**
  String get findingInconclusiveHelp;

  /// Inspection follow-up status.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get followUpOpen;

  /// Inspection follow-up status.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get followUpInProgress;

  /// Inspection follow-up status.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get followUpDone;

  /// Reminder status.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get reminderScheduled;

  /// Reminder status after its notification fired.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get reminderFired;

  /// Reminder status.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reminderDone;

  /// Reminder status.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get reminderCancelled;

  /// Why a recording was rejected, plus what to do.
  ///
  /// In en, this message translates to:
  /// **'Too quiet: almost no sound reached the microphone. Press the phone firmly against the grain.'**
  String get reasonSilence;

  /// Why a recording was rejected, plus what to do.
  ///
  /// In en, this message translates to:
  /// **'Too loud: the sound was distorted. Do not tap, rub or knock while recording.'**
  String get reasonClipping;

  /// Why a recording was rejected, plus what to do.
  ///
  /// In en, this message translates to:
  /// **'Too much background noise. Move somewhere quieter and keep still.'**
  String get reasonHighNoise;

  /// Why a recording was rejected, plus what to do.
  ///
  /// In en, this message translates to:
  /// **'The recording was too short. Keep the phone still for the full 2 seconds.'**
  String get reasonTooShort;

  /// Why a recording was rejected, plus what to do.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Allow it in the phone settings to scan.'**
  String get reasonPermissionDenied;

  /// Why a recording was rejected, plus what to do.
  ///
  /// In en, this message translates to:
  /// **'The microphone could not record. Close other apps that use the microphone and try again.'**
  String get reasonCaptureError;

  /// Recording quality: usable.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get qualityPass;

  /// Recording quality: not usable.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get qualityRetry;

  /// Unverified model prediction label. Never a guarantee.
  ///
  /// In en, this message translates to:
  /// **'No signal detected'**
  String get predictionClean;

  /// Unverified model prediction label.
  ///
  /// In en, this message translates to:
  /// **'Uncertain'**
  String get predictionUncertain;

  /// Unverified model prediction label.
  ///
  /// In en, this message translates to:
  /// **'Possible infestation'**
  String get predictionInfested;

  /// No model result for this recording.
  ///
  /// In en, this message translates to:
  /// **'Not evaluated'**
  String get predictionNotEvaluated;

  /// Research label, needs a confirming inspection.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get sampleLabelClean;

  /// Research label, needs a confirming inspection.
  ///
  /// In en, this message translates to:
  /// **'Infested'**
  String get sampleLabelInfested;

  /// Research label when no inspection confirms the state.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get sampleLabelUnknown;

  /// Result headline for RETRY (design-tokens.md, exact).
  ///
  /// In en, this message translates to:
  /// **'Recording not usable — try again'**
  String get headlineRetry;

  /// Result headline for NOT_EVALUATED with no model (design-tokens.md, exact).
  ///
  /// In en, this message translates to:
  /// **'Not evaluated — no model installed. Inspect physically.'**
  String get headlineNotEvaluated;

  /// Result headline when a model is installed but produced no result.
  ///
  /// In en, this message translates to:
  /// **'Not evaluated — the model could not process this recording. Inspect physically.'**
  String get headlineNotEvaluatedWithModel;

  /// Result headline for INFESTED or UNCERTAIN (design-tokens.md, exact).
  ///
  /// In en, this message translates to:
  /// **'Inspection needed — model result is not verified'**
  String get headlineInspectionNeeded;

  /// Result headline for CLEAN (design-tokens.md, exact).
  ///
  /// In en, this message translates to:
  /// **'No signal detected — not a guarantee; inspect before sale/storage decisions'**
  String get headlineClean;

  /// Model provenance when no model is bundled (design-tokens.md, exact).
  ///
  /// In en, this message translates to:
  /// **'Model: none — Not evaluated'**
  String get provenanceNone;

  /// Model provenance for an experimental model.
  ///
  /// In en, this message translates to:
  /// **'Model {version} — Experimental'**
  String provenanceExperimental(String version);

  /// Model provenance for a model validated on field data.
  ///
  /// In en, this message translates to:
  /// **'Model {version} — Validated'**
  String provenanceValidated(String version);

  /// Joins a formatted date and time.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String dateTimeJoin(String date, String time);

  /// Overline on the home hero when it shows the most urgent next action.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStepEyebrow;

  /// Home note when AnalyticsService has no next actions.
  ///
  /// In en, this message translates to:
  /// **'Nothing urgent right now. Scan regularly to keep track.'**
  String get nextNothingPending;

  /// Compact scan shortcut next to a non-scan next step; also the insights empty-state action.
  ///
  /// In en, this message translates to:
  /// **'Scan now'**
  String get quickScanAction;

  /// Scans recorded since local midnight (AnalyticsService.watchScanActivity).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No scans today} =1{1 scan today} other{{count} scans today}}'**
  String scansTodayCount(int count);

  /// Household home activity line.
  ///
  /// In en, this message translates to:
  /// **'Scans: {today} today · {week} in the last 7 days'**
  String scanActivityLine(int today, int week);

  /// Next step: nothing registered yet.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{Register your first container} other{Register your first sack}}'**
  String nextRegisterFirst(String kind);

  /// Next step detail for registering the first item.
  ///
  /// In en, this message translates to:
  /// **'Add a name, grain and quantity. It takes a minute.'**
  String get nextRegisterFirstBody;

  /// Buyer next step: no lots yet.
  ///
  /// In en, this message translates to:
  /// **'Register your first delivery'**
  String get nextRegisterFirstLot;

  /// Buyer next step detail for registering a lot.
  ///
  /// In en, this message translates to:
  /// **'Supplier, lot, grain and quantity.'**
  String get nextRegisterFirstLotBody;

  /// Next step: one named item needs a scan.
  ///
  /// In en, this message translates to:
  /// **'Scan {label}'**
  String nextScanOne(String label);

  /// Next step: sacks that need a scan.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sack needs a scan} other{{count} sacks need a scan}}'**
  String nextScanSacks(int count);

  /// Household next step: containers that need a scan.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 container needs a scan} other{{count} containers need a scan}}'**
  String nextScanContainers(int count);

  /// Next step detail for scanning.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, container{A 2-second listening check with the phone pressed on the container.} other{A 2-second listening check, one sack at a time.}}'**
  String nextScanBody(String kind);

  /// Next step: one flagged item needs a human inspection.
  ///
  /// In en, this message translates to:
  /// **'Inspect {label}'**
  String nextInspectOne(String label);

  /// Next step: flagged sacks to inspect.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 flagged sack to inspect} other{{count} flagged sacks to inspect}}'**
  String nextInspectSacks(int count);

  /// Household next step: flagged containers to inspect.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 flagged container to inspect} other{{count} flagged containers to inspect}}'**
  String nextInspectContainers(int count);

  /// Next step detail for inspecting flagged items. Must keep 'not verified'.
  ///
  /// In en, this message translates to:
  /// **'The model result is not verified. Check the grain by hand.'**
  String get nextInspectBody;

  /// Next step: one item is due for a re-check.
  ///
  /// In en, this message translates to:
  /// **'{label}: review due'**
  String nextReviewOne(String label);

  /// Next step: sacks due for review.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sack due for review} other{{count} sacks due for review}}'**
  String nextReviewSacks(int count);

  /// Household next step: containers due for review.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 container due for review} other{{count} containers due for review}}'**
  String nextReviewContainers(int count);

  /// Next step detail for a review that is due.
  ///
  /// In en, this message translates to:
  /// **'It has been a while since the last check. Listen again or inspect.'**
  String get nextReviewBody;

  /// Next step: a scheduled reminder for one item is due.
  ///
  /// In en, this message translates to:
  /// **'{label}: reminder due'**
  String nextReminderOne(String label);

  /// Next step: reminders due.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reminder due} other{{count} reminders due}}'**
  String nextReminderMany(int count);

  /// Next step detail for a due reminder.
  ///
  /// In en, this message translates to:
  /// **'A re-check you scheduled is due. Check this grain.'**
  String get nextReminderBody;

  /// Buyer next step: one lot waits for a physical check.
  ///
  /// In en, this message translates to:
  /// **'Lot {label}: physical check pending'**
  String nextPhysicalOne(String label);

  /// Buyer next step: lots waiting for a physical check.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lot needs a physical check} other{{count} lots need a physical check}}'**
  String nextPhysicalMany(int count);

  /// Buyer next step detail. Must not imply an automatic decision.
  ///
  /// In en, this message translates to:
  /// **'Open the lot and record what a person found. Kernel never accepts or rejects a lot.'**
  String get nextPhysicalBody;

  /// Next step: a batch scan is incomplete.
  ///
  /// In en, this message translates to:
  /// **'Finish the batch scan'**
  String get nextFinishBatch;

  /// Next step: the batch for a named place or lot is incomplete.
  ///
  /// In en, this message translates to:
  /// **'Finish the batch: {label}'**
  String nextFinishBatchOne(String label);

  /// Next step detail: sacks left in the batch.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Every sack in this batch has a scan} =1{1 sack left to scan, one at a time} other{{count} sacks left to scan, one at a time}}'**
  String nextFinishBatchBody(int count);

  /// Farmer next step: export a pre-sale report.
  ///
  /// In en, this message translates to:
  /// **'Share a pre-sale report'**
  String get nextPreSale;

  /// Farmer next step for a named harvest.
  ///
  /// In en, this message translates to:
  /// **'Share the pre-sale report for {label}'**
  String nextPreSaleOne(String label);

  /// Buyer next step: export a lot summary.
  ///
  /// In en, this message translates to:
  /// **'Share a lot summary'**
  String get nextLotSummary;

  /// Buyer next step for a named lot.
  ///
  /// In en, this message translates to:
  /// **'Share the lot summary for {label}'**
  String nextLotSummaryOne(String label);

  /// Next step detail for exporting a report.
  ///
  /// In en, this message translates to:
  /// **'Made on this phone from your records. You choose who to share it with.'**
  String get nextExportBody;

  /// Next step button: open the registration form.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get nextActionRegister;

  /// Next step button: start a scan.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get nextActionScan;

  /// Next step button: start a batch scan of a place or lot.
  ///
  /// In en, this message translates to:
  /// **'Start batch scan'**
  String get nextActionBatch;

  /// Next step button: open the item.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get nextActionOpen;

  /// Next step button: open the inspection queue.
  ///
  /// In en, this message translates to:
  /// **'Open the queue'**
  String get nextActionQueue;

  /// Next step button: open the lot.
  ///
  /// In en, this message translates to:
  /// **'Open lot'**
  String get nextActionOpenLot;

  /// Next step button: continue a batch scan.
  ///
  /// In en, this message translates to:
  /// **'Continue batch'**
  String get nextActionContinueBatch;

  /// Next step button: open Reports with the report preset.
  ///
  /// In en, this message translates to:
  /// **'Open report'**
  String get nextActionReport;

  /// Local analytics screen title.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// Insights screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Worked out on this phone from your own records'**
  String get insightsSubtitle;

  /// Home and Reports card that opens Insights.
  ///
  /// In en, this message translates to:
  /// **'Results, recording problems and what needs a check'**
  String get insightsCardSubtitle;

  /// Accessibility label for the period selector.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get insightsWindowLabel;

  /// Period chip: last 7 days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get insightsWindow7;

  /// Period chip: last 30 days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get insightsWindow30;

  /// Period chip: all records.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get insightsWindowAll;

  /// Insights section.
  ///
  /// In en, this message translates to:
  /// **'Scanning activity'**
  String get insightsActivityTitle;

  /// Stat tile label under a count.
  ///
  /// In en, this message translates to:
  /// **'Scans today'**
  String get insightsScansToday;

  /// Stat tile label under a count.
  ///
  /// In en, this message translates to:
  /// **'Scans in the last 7 days'**
  String get insightsScans7;

  /// Insights section: result counts.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get insightsRatesTitle;

  /// Insights empty state.
  ///
  /// In en, this message translates to:
  /// **'No scans in this period'**
  String get insightsRatesEmpty;

  /// Insights empty state detail.
  ///
  /// In en, this message translates to:
  /// **'Scan a sack or container to see results here.'**
  String get insightsRatesEmptyDetail;

  /// Shown with every result chart. Must keep 'experimental', 'not verified', 'inspect physically'.
  ///
  /// In en, this message translates to:
  /// **'Experimental model: these results are not verified and may be wrong. Inspect physically before any storage or sale decision.'**
  String get insightsExperimentalNote;

  /// Shown when every usable scan is NOT_EVALUATED.
  ///
  /// In en, this message translates to:
  /// **'No model results yet: no usable recording was evaluated by a model.'**
  String get insightsNoModelResults;

  /// Bar label for RETRY scans.
  ///
  /// In en, this message translates to:
  /// **'Recording not usable (retry)'**
  String get insightsRetryLabel;

  /// Value printed on a bar: count and share.
  ///
  /// In en, this message translates to:
  /// **'{count} · {percent}%'**
  String insightsBarValue(int count, int percent);

  /// Total under the result chart.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scan in this period} other{{count} scans in this period}}'**
  String insightsTotalScans(int count);

  /// Insights section: why recordings needed a retry.
  ///
  /// In en, this message translates to:
  /// **'Recording problems'**
  String get insightsQualityTitle;

  /// Quality section empty note.
  ///
  /// In en, this message translates to:
  /// **'No unusable recordings in this period'**
  String get insightsQualityEmpty;

  /// Tip under the recording-problems chart.
  ///
  /// In en, this message translates to:
  /// **'Most problems go away when the phone is pressed firmly on the sack in a quiet place.'**
  String get insightsQualityHint;

  /// Insights section: human inspections.
  ///
  /// In en, this message translates to:
  /// **'Inspections'**
  String get insightsInspectionsTitle;

  /// Inspections section empty note.
  ///
  /// In en, this message translates to:
  /// **'No inspections recorded yet'**
  String get insightsInspectionsEmpty;

  /// Inspection closure rate.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of inspections are done'**
  String insightsClosureRate(int percent);

  /// Insights section: most stale items.
  ///
  /// In en, this message translates to:
  /// **'Longest since last check'**
  String get insightsStaleTitle;

  /// Stale item chip.
  ///
  /// In en, this message translates to:
  /// **'Never scanned'**
  String get staleNeverScanned;

  /// Short bar label for the silence quality reason.
  ///
  /// In en, this message translates to:
  /// **'Too quiet'**
  String get qualityShortSilence;

  /// Short bar label for the clipping quality reason.
  ///
  /// In en, this message translates to:
  /// **'Too loud (clipping)'**
  String get qualityShortClipping;

  /// Short bar label for the high-noise quality reason.
  ///
  /// In en, this message translates to:
  /// **'Too noisy'**
  String get qualityShortHighNoise;

  /// Short bar label for the too-short quality reason.
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get qualityShortTooShort;

  /// Short bar label for the permission-denied quality reason.
  ///
  /// In en, this message translates to:
  /// **'Microphone blocked'**
  String get qualityShortPermissionDenied;

  /// Short bar label for the capture-error quality reason.
  ///
  /// In en, this message translates to:
  /// **'Recording error'**
  String get qualityShortCaptureError;

  /// Queue filter row label.
  ///
  /// In en, this message translates to:
  /// **'Model result'**
  String get queueFilterResult;

  /// Queue filter chip: no result filter.
  ///
  /// In en, this message translates to:
  /// **'All results'**
  String get queueFilterAllResults;

  /// Queue filter row label.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get queueFilterPlace;

  /// Queue filter chip: no place filter.
  ///
  /// In en, this message translates to:
  /// **'All places'**
  String get queueFilterAllPlaces;

  /// Queue filter row label (scan age).
  ///
  /// In en, this message translates to:
  /// **'Last usable scan'**
  String get queueFilterAge;

  /// Queue filter chip: no age filter.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get queueFilterAnyAge;

  /// Queue filter chip: last usable scan within N days.
  ///
  /// In en, this message translates to:
  /// **'Within {days} days'**
  String queueFilterWithinDays(int days);

  /// Explains the age filter.
  ///
  /// In en, this message translates to:
  /// **'Items whose last usable scan is older than {days} days move to Needs scan.'**
  String queueFilterAgeNote(int days);

  /// Queue empty note when filters are active.
  ///
  /// In en, this message translates to:
  /// **'No ranked items match these filters.'**
  String get queueNoMatch;

  /// Queue rank reason chip. Must keep 'not verified'.
  ///
  /// In en, this message translates to:
  /// **'Why here: possible infestation (not verified)'**
  String get rankReasonInfested;

  /// Queue rank reason chip.
  ///
  /// In en, this message translates to:
  /// **'Why here: the model was unsure'**
  String get rankReasonUncertain;

  /// Queue rank reason chip. Must keep 'not a guarantee'.
  ///
  /// In en, this message translates to:
  /// **'Why lower: no signal detected (not a guarantee)'**
  String get rankReasonClean;

  /// Age of the latest usable (PASS) scan: on queue entries and stale items.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Scanned today} =1{Scanned 1 day ago} other{Scanned {days} days ago}}'**
  String scannedDaysAgo(int days);

  /// Under the reminder date when it is the rule-based suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggested — you choose'**
  String get reminderSuggestedLabel;

  /// Under the reminder date after the user picked another date.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {date} — you choose'**
  String reminderSuggestedOther(String date);

  /// Optional on-phone AI wording in the reminder sheet.
  ///
  /// In en, this message translates to:
  /// **'Suggested wording'**
  String get reminderWordingTitle;

  /// Settings section for the local LLM.
  ///
  /// In en, this message translates to:
  /// **'On-phone AI assistant (experimental)'**
  String get settingsAdviceSection;

  /// Local LLM opt-in toggle.
  ///
  /// In en, this message translates to:
  /// **'Use the on-phone AI assistant'**
  String get adviceToggle;

  /// Local LLM opt-in explanation (guardrails §8).
  ///
  /// In en, this message translates to:
  /// **'Off by default. It runs only on this phone and never hears your recordings; it only sees results and dates. It may be wrong. You can turn it off at any time.'**
  String get adviceToggleBody;

  /// Card title for the assistant status.
  ///
  /// In en, this message translates to:
  /// **'Assistant status'**
  String get adviceStatusTitle;

  /// Assistant status: opted out.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get adviceStatusOff;

  /// Assistant status: enabled without a model file.
  ///
  /// In en, this message translates to:
  /// **'On — no model imported yet'**
  String get adviceStatusNoModel;

  /// Assistant status: loading.
  ///
  /// In en, this message translates to:
  /// **'Loading the model…'**
  String get adviceStatusLoading;

  /// Assistant status: ready.
  ///
  /// In en, this message translates to:
  /// **'Ready on this phone'**
  String get adviceStatusReady;

  /// Assistant status: generating.
  ///
  /// In en, this message translates to:
  /// **'Busy writing'**
  String get adviceStatusBusy;

  /// Assistant status: failed to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load the model — Kernel uses its standard text'**
  String get adviceStatusFailed;

  /// Model file card title.
  ///
  /// In en, this message translates to:
  /// **'Assistant model'**
  String get adviceModelTitle;

  /// Model card when no file is installed.
  ///
  /// In en, this message translates to:
  /// **'No model imported yet'**
  String get adviceModelNone;

  /// Field label: model id.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get adviceModelId;

  /// Field label: model version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get adviceModelVersion;

  /// Field label: model file size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get adviceModelSize;

  /// Field label: inference backend.
  ///
  /// In en, this message translates to:
  /// **'Runs on'**
  String get adviceModelBackend;

  /// Backend value: GPU.
  ///
  /// In en, this message translates to:
  /// **'Phone graphics chip (GPU)'**
  String get adviceBackendGpu;

  /// Backend value: CPU.
  ///
  /// In en, this message translates to:
  /// **'Phone processor (CPU)'**
  String get adviceBackendCpu;

  /// Backend value before the first load.
  ///
  /// In en, this message translates to:
  /// **'Not loaded yet'**
  String get adviceBackendNone;

  /// Opens the file picker for a .litertlm file.
  ///
  /// In en, this message translates to:
  /// **'Import model'**
  String get adviceImportAction;

  /// Accessibility label of the import progress bar.
  ///
  /// In en, this message translates to:
  /// **'Importing the model'**
  String get adviceImporting;

  /// Import progress.
  ///
  /// In en, this message translates to:
  /// **'Copying {copied} of {total}'**
  String adviceImportCopying(String copied, String total);

  /// Import progress when the size is unknown.
  ///
  /// In en, this message translates to:
  /// **'Copied {copied}'**
  String adviceImportCopied(String copied);

  /// Import phase: verifying.
  ///
  /// In en, this message translates to:
  /// **'Checking the model file…'**
  String get adviceImportVerifying;

  /// Import finished.
  ///
  /// In en, this message translates to:
  /// **'Model imported. It stays on this phone.'**
  String get adviceImportDone;

  /// Import failed.
  ///
  /// In en, this message translates to:
  /// **'The model could not be imported: {detail}'**
  String adviceImportFailed(String detail);

  /// Free-space check failed.
  ///
  /// In en, this message translates to:
  /// **'Not enough space: the model needs {needed} but only {free} is free on this phone.'**
  String adviceImportNoSpace(String needed, String free);

  /// Deletes the model file.
  ///
  /// In en, this message translates to:
  /// **'Delete model'**
  String get adviceDeleteAction;

  /// Delete confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete the assistant model?'**
  String get adviceDeleteConfirmTitle;

  /// Delete confirmation body.
  ///
  /// In en, this message translates to:
  /// **'This removes the model file from this phone. Your records are not affected. You can import it again later.'**
  String get adviceDeleteConfirmBody;

  /// Delete failed.
  ///
  /// In en, this message translates to:
  /// **'The model could not be deleted: {detail}'**
  String adviceDeleteFailed(String detail);

  /// Where to get a model file. Keep product names and the repository path in Latin script.
  ///
  /// In en, this message translates to:
  /// **'Get a .litertlm model with Google AI Edge Gallery or from Hugging Face litert-community/gemma-4-E2B-it-litert-lm (Gemma terms apply), then import it here.'**
  String get adviceHelp;

  /// Label on every piece of generated text (guardrails §8).
  ///
  /// In en, this message translates to:
  /// **'Generated on this phone — experimental · {modelVersion}'**
  String adviceProvenance(String modelVersion);

  /// Footnote on generated text. Must keep 'inspect physically'.
  ///
  /// In en, this message translates to:
  /// **'Not a decision — inspect physically'**
  String get adviceNotDecision;

  /// While the local model generates.
  ///
  /// In en, this message translates to:
  /// **'Writing on this phone…'**
  String get adviceGenerating;

  /// Result screen button (only when the assistant is ready).
  ///
  /// In en, this message translates to:
  /// **'Explain this result'**
  String get adviceExplainAction;

  /// Title of the explanation card.
  ///
  /// In en, this message translates to:
  /// **'What this result means'**
  String get adviceExplainTitle;

  /// Static explanation for RETRY when the assistant is unavailable.
  ///
  /// In en, this message translates to:
  /// **'The recording could not be used, so no result was saved. Press the phone firmly against the sack or container, keep still and quiet, and record again.'**
  String get adviceStaticRetry;

  /// Static explanation for NOT_EVALUATED.
  ///
  /// In en, this message translates to:
  /// **'No result was produced for this recording, so it says nothing about pests. Inspect the grain physically.'**
  String get adviceStaticNotEvaluated;

  /// Static explanation for INFESTED/UNCERTAIN.
  ///
  /// In en, this message translates to:
  /// **'The experimental model picked up something that may need attention. This is not verified. Inspect the grain physically before any decision.'**
  String get adviceStaticInspection;

  /// Static explanation for CLEAN.
  ///
  /// In en, this message translates to:
  /// **'The experimental model did not pick up a signal. This is not a guarantee. Inspect the grain physically before storage or sale decisions.'**
  String get adviceStaticClean;

  /// Export panel switch (only when the assistant is ready).
  ///
  /// In en, this message translates to:
  /// **'Add AI-drafted summary'**
  String get reportAiSummaryToggle;

  /// Explains the AI summary switch.
  ///
  /// In en, this message translates to:
  /// **'Drafted on this phone from the report\'s figures. You see it first and choose whether to include it. Experimental.'**
  String get reportAiSummaryBody;

  /// Narrative preview dialog title.
  ///
  /// In en, this message translates to:
  /// **'AI-drafted summary'**
  String get reportAiPreviewTitle;

  /// Narrative preview explanation.
  ///
  /// In en, this message translates to:
  /// **'If you include it, it appears in its own labelled section, separate from your records and inspection findings. It cannot be edited.'**
  String get reportAiPreviewBody;

  /// Card title inside the preview.
  ///
  /// In en, this message translates to:
  /// **'Draft summary'**
  String get reportAiSummaryTitle;

  /// Include the narrative in the report.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get reportAiInclude;

  /// Export without the narrative.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get reportAiSkip;

  /// File size in gigabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} GB'**
  String unitGb(String value);

  /// File size in megabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String unitMb(String value);

  /// Pest & Animal ID mode title.
  ///
  /// In en, this message translates to:
  /// **'Pest & animal ID'**
  String get pestIdTitle;

  /// Pest ID hub subtitle.
  ///
  /// In en, this message translates to:
  /// **'Look with the camera or listen. The phone finds possible signs; you confirm what is real.'**
  String get pestIdSubtitle;

  /// Home entry card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Check for insects, rats, spiders, lizards and other animals with the camera or by sound'**
  String get pestHomeActionBody;

  /// Action that opens Pest ID.
  ///
  /// In en, this message translates to:
  /// **'Look or listen'**
  String get pestHeroAction;

  /// Scan tab segment: acoustic grain scan.
  ///
  /// In en, this message translates to:
  /// **'Grain sack'**
  String get pestSegmentGrain;

  /// Scan tab segment: Pest & Animal ID.
  ///
  /// In en, this message translates to:
  /// **'Pest & animal'**
  String get pestSegmentPest;

  /// Hub card: camera mode.
  ///
  /// In en, this message translates to:
  /// **'Look with the camera'**
  String get pestCameraCardTitle;

  /// Hub card body: camera mode.
  ///
  /// In en, this message translates to:
  /// **'Finds movement, dark specks and eye shine. You confirm what is real.'**
  String get pestCameraCardBody;

  /// Hub card: listen mode.
  ///
  /// In en, this message translates to:
  /// **'Listen for sounds'**
  String get pestListenCardTitle;

  /// Hub card body: listen mode.
  ///
  /// In en, this message translates to:
  /// **'Picks up buzzing, scratching and squeaks. You confirm what you heard.'**
  String get pestListenCardBody;

  /// Hub card: saved sightings.
  ///
  /// In en, this message translates to:
  /// **'My sightings'**
  String get pestSightingsCardTitle;

  /// Saved sightings count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sightings saved yet} =1{1 sighting saved} other{{count} sightings saved}}'**
  String pestSightingsCount(int count);

  /// Privacy note.
  ///
  /// In en, this message translates to:
  /// **'Everything is checked on this phone. Pictures and sounds are never uploaded.'**
  String get pestOnPhoneNote;

  /// Honesty note.
  ///
  /// In en, this message translates to:
  /// **'AI results are estimates and may be wrong. A missed sign is not proof that nothing is there.'**
  String get pestNotCertainNote;

  /// Camera screen title.
  ///
  /// In en, this message translates to:
  /// **'Look for signs'**
  String get pestCameraTitle;

  /// Camera positioning tip.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone still near corners, gaps and grain. Tap a box to confirm it, or capture to see close-ups.'**
  String get pestCameraTip;

  /// Camera permission denied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Allow it in settings to look for signs. Your saved sightings stay available.'**
  String get pestCameraDenied;

  /// Signal kind: motion.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get pestKindMotion;

  /// Signal kind: dark specks (droppings, insects).
  ///
  /// In en, this message translates to:
  /// **'Dark specks'**
  String get pestKindSpecks;

  /// Signal kind: eyes reflecting light.
  ///
  /// In en, this message translates to:
  /// **'Eye shine'**
  String get pestKindEyeshine;

  /// Signal kind: looks like a known card.
  ///
  /// In en, this message translates to:
  /// **'Looks similar'**
  String get pestKindEmbedding;

  /// Signal kind: region proposed by a model.
  ///
  /// In en, this message translates to:
  /// **'AI box'**
  String get pestKindModelBox;

  /// Signal kind: sound event.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get pestKindSound;

  /// Screen-reader label of a candidate box.
  ///
  /// In en, this message translates to:
  /// **'Confirm {kind}'**
  String pestConfirmBox(String kind);

  /// Torch slider label.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get pestTorch;

  /// Torch brightness.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String pestTorchValue(int percent);

  /// Take a still with close-ups.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get pestCapture;

  /// While capturing.
  ///
  /// In en, this message translates to:
  /// **'Capturing…'**
  String get pestCapturing;

  /// Dismiss: nothing to analyse.
  ///
  /// In en, this message translates to:
  /// **'Not a pest / nothing here'**
  String get pestNothingHere;

  /// Snackbar after dismissing.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved. The pictures were discarded.'**
  String get pestNothingHereDone;

  /// No live candidates.
  ///
  /// In en, this message translates to:
  /// **'No possible signs yet. Move slowly or turn on the torch.'**
  String get pestCandidatesNone;

  /// Live candidate count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 possible sign} other{{count} possible signs}}'**
  String pestCandidatesCount(int count);

  /// Capture failed.
  ///
  /// In en, this message translates to:
  /// **'Could not take a picture. Try again.'**
  String get pestCaptureFailed;

  /// Tiles title.
  ///
  /// In en, this message translates to:
  /// **'Close-ups: tap the one that is real'**
  String get pestTilesTitle;

  /// No tiles.
  ///
  /// In en, this message translates to:
  /// **'No close-ups in this picture. Try again closer, or with the torch.'**
  String get pestTilesEmpty;

  /// Embedding hint on a tile.
  ///
  /// In en, this message translates to:
  /// **'AI hint: {name} (not verified)'**
  String pestTileHint(String name);

  /// Tile action.
  ///
  /// In en, this message translates to:
  /// **'Tap to confirm'**
  String get pestTileConfirm;

  /// Back to the live preview.
  ///
  /// In en, this message translates to:
  /// **'Capture again'**
  String get pestRetake;

  /// Analysis screen title.
  ///
  /// In en, this message translates to:
  /// **'AI analysis'**
  String get pestAnalysisTitle;

  /// While the on-device model runs.
  ///
  /// In en, this message translates to:
  /// **'Analysing on this phone…'**
  String get pestAnalysing;

  /// Label above the AI's common name.
  ///
  /// In en, this message translates to:
  /// **'AI label'**
  String get pestAiLabel;

  /// Chip on AI-derived values.
  ///
  /// In en, this message translates to:
  /// **'AI-estimated'**
  String get pestAiEstimated;

  /// Confidence bar label.
  ///
  /// In en, this message translates to:
  /// **'AI-estimated confidence — not calibrated'**
  String get pestConfidenceLabel;

  /// Confidence value.
  ///
  /// In en, this message translates to:
  /// **'{percent}% (the AI\'s own estimate)'**
  String pestConfidenceValue(int percent);

  /// Self-consistency agreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement {agree} of {runs} runs'**
  String pestAgreement(int agree, int runs);

  /// Analysis section.
  ///
  /// In en, this message translates to:
  /// **'Key features'**
  String get pestKeyFeatures;

  /// Analysis section.
  ///
  /// In en, this message translates to:
  /// **'Anomalies'**
  String get pestAnomalies;

  /// Analysis section.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get pestInsights;

  /// Analysis returned no card.
  ///
  /// In en, this message translates to:
  /// **'No matching card. This is not proof that nothing is there. Inspect physically.'**
  String get pestNoMatch;

  /// Analysis says not a pest.
  ///
  /// In en, this message translates to:
  /// **'The AI thinks this is not a pest. This is not proof. Inspect physically if unsure.'**
  String get pestNotAPest;

  /// Model provenance.
  ///
  /// In en, this message translates to:
  /// **'Model {version} · prompt {prompt} — Experimental'**
  String pestModelLine(String version, String prompt);

  /// Analysis returned null.
  ///
  /// In en, this message translates to:
  /// **'AI analysis unavailable'**
  String get pestAnalysisUnavailable;

  /// Fallback explanation.
  ///
  /// In en, this message translates to:
  /// **'The on-phone AI could not analyse this. Showing the closest knowledge card instead.'**
  String get pestAnalysisUnavailableBody;

  /// No card at all.
  ///
  /// In en, this message translates to:
  /// **'No matching knowledge card. Inspect physically and ask a professional if unsure.'**
  String get pestNoCardFound;

  /// Safety banner: venomous.
  ///
  /// In en, this message translates to:
  /// **'Venomous — keep your distance'**
  String get pestSafetyVenomousTitle;

  /// Safety banner: medical risk.
  ///
  /// In en, this message translates to:
  /// **'Health risk — keep your distance'**
  String get pestSafetyMedicalTitle;

  /// Safety banner body: venomous/medical.
  ///
  /// In en, this message translates to:
  /// **'Do not touch or handle it. Get medical care for any bite or sting. Do not use home remedies.'**
  String get pestSafetyDistanceBody;

  /// Safety banner: protected species.
  ///
  /// In en, this message translates to:
  /// **'Protected wildlife — do not harm it'**
  String get pestSafetyProtectedTitle;

  /// Safety banner body: protected species.
  ///
  /// In en, this message translates to:
  /// **'Do not harm, capture or kill it. Call the State Forest Department or a licensed wildlife rescuer.'**
  String get pestSafetyProtectedBody;

  /// Safety banner: caution.
  ///
  /// In en, this message translates to:
  /// **'Take care'**
  String get pestSafetyCautionTitle;

  /// Safety banner body: caution.
  ///
  /// In en, this message translates to:
  /// **'Do not touch it with bare hands. Follow the safe steps on the card.'**
  String get pestSafetyCautionBody;

  /// Curated card heading.
  ///
  /// In en, this message translates to:
  /// **'Knowledge card'**
  String get pestCardTitle;

  /// Chip: the user chose this card.
  ///
  /// In en, this message translates to:
  /// **'Your pick'**
  String get pestCardYourPick;

  /// Card review status.
  ///
  /// In en, this message translates to:
  /// **'Needs expert review'**
  String get pestCardNeedsReview;

  /// Other names.
  ///
  /// In en, this message translates to:
  /// **'Also called: {names}'**
  String pestCardOtherNames(String names);

  /// Card section.
  ///
  /// In en, this message translates to:
  /// **'Signs to look for'**
  String get pestCardSigns;

  /// Card section.
  ///
  /// In en, this message translates to:
  /// **'Health risks'**
  String get pestCardHealthRisks;

  /// Card section.
  ///
  /// In en, this message translates to:
  /// **'Safe steps'**
  String get pestCardSafeSteps;

  /// Card section.
  ///
  /// In en, this message translates to:
  /// **'Call a professional when'**
  String get pestCardCallPro;

  /// Card section (pointers to medical care only).
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get pestCardFirstAid;

  /// Card section.
  ///
  /// In en, this message translates to:
  /// **'Look-alikes'**
  String get pestCardLookAlikes;

  /// Card section.
  ///
  /// In en, this message translates to:
  /// **'Legal status'**
  String get pestCardLegal;

  /// Card section.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get pestCardSources;

  /// Stream an explanation grounded in the card.
  ///
  /// In en, this message translates to:
  /// **'Explain'**
  String get pestExplain;

  /// Explanation card title.
  ///
  /// In en, this message translates to:
  /// **'Explanation from the card'**
  String get pestExplainTitle;

  /// Explanation unavailable.
  ///
  /// In en, this message translates to:
  /// **'No explanation right now. The card above is the guidance.'**
  String get pestExplainFallback;

  /// Correct the AI label.
  ///
  /// In en, this message translates to:
  /// **'Pick a different card'**
  String get pestPickCard;

  /// Card picker title.
  ///
  /// In en, this message translates to:
  /// **'Which one is it?'**
  String get pestPickCardTitle;

  /// Card picker explanation.
  ///
  /// In en, this message translates to:
  /// **'Your pick is saved as your correction. The AI analysis is kept as it was.'**
  String get pestPickCardBody;

  /// Remove the user's pick.
  ///
  /// In en, this message translates to:
  /// **'Use the AI label'**
  String get pestPickCardClear;

  /// Measure the distance to the animal.
  ///
  /// In en, this message translates to:
  /// **'Measure distance'**
  String get pestMeasure;

  /// While measuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring…'**
  String get pestMeasuring;

  /// Distance result.
  ///
  /// In en, this message translates to:
  /// **'About {meters} m away ({low}–{high} m), by {method}'**
  String pestDistanceValue(
    String meters,
    String low,
    String high,
    String method,
  );

  /// Distance method.
  ///
  /// In en, this message translates to:
  /// **'depth sensing'**
  String get pestDistanceMethodDepth;

  /// Distance method.
  ///
  /// In en, this message translates to:
  /// **'camera focus'**
  String get pestDistanceMethodFocus;

  /// Distance gate failed.
  ///
  /// In en, this message translates to:
  /// **'Distance not available'**
  String get pestDistanceUnavailable;

  /// Why no distance.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String pestDistanceReason(String reason);

  /// No distance, no reason given.
  ///
  /// In en, this message translates to:
  /// **'The phone could not measure it reliably.'**
  String get pestDistanceNoReason;

  /// Save action.
  ///
  /// In en, this message translates to:
  /// **'Save sighting'**
  String get pestSave;

  /// Drop this signal and its media.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get pestDiscard;

  /// Back to the Pest ID start.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get pestStartAgain;

  /// No confirmed signal.
  ///
  /// In en, this message translates to:
  /// **'Nothing to analyse. Start again with the camera or listen mode.'**
  String get pestNoSignal;

  /// Animal group.
  ///
  /// In en, this message translates to:
  /// **'Insect'**
  String get pestGroupInsect;

  /// Animal group.
  ///
  /// In en, this message translates to:
  /// **'Spider or scorpion'**
  String get pestGroupArachnid;

  /// Animal group.
  ///
  /// In en, this message translates to:
  /// **'Rat or mouse'**
  String get pestGroupRodent;

  /// Animal group.
  ///
  /// In en, this message translates to:
  /// **'Reptile'**
  String get pestGroupReptile;

  /// Animal group.
  ///
  /// In en, this message translates to:
  /// **'Other animal'**
  String get pestGroupOther;

  /// Animal group.
  ///
  /// In en, this message translates to:
  /// **'Not a pest'**
  String get pestGroupNotAPest;

  /// Animal group.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get pestGroupUnknown;

  /// Sound group hint.
  ///
  /// In en, this message translates to:
  /// **'Likely group: {group} (AI hint)'**
  String pestGroupHint(String group);

  /// Signal source.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get pestSourceCamera;

  /// Signal source.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get pestSourceMic;

  /// Signal source.
  ///
  /// In en, this message translates to:
  /// **'Sensor'**
  String get pestSourceSensor;

  /// Listen screen title.
  ///
  /// In en, this message translates to:
  /// **'Listen for sounds'**
  String get pestListenTitle;

  /// Listen mode.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get pestListenModeGeneral;

  /// Listen mode.
  ///
  /// In en, this message translates to:
  /// **'Mosquito close-up'**
  String get pestListenModeMosquito;

  /// Listen mode.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get pestListenModeNight;

  /// Mode help.
  ///
  /// In en, this message translates to:
  /// **'Keep the phone still near where you hear the sound.'**
  String get pestListenModeGeneralBody;

  /// Mode help.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone within a hand\'s width of the buzzing.'**
  String get pestListenModeMosquitoBody;

  /// Mode help.
  ///
  /// In en, this message translates to:
  /// **'Leave the phone still in the room. A notification shows while it listens, so you can stop it at any time.'**
  String get pestListenModeNightBody;

  /// Start listen mode.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get pestListenStart;

  /// Stop listening.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get pestListenStop;

  /// While listening.
  ///
  /// In en, this message translates to:
  /// **'Listening on this phone…'**
  String get pestListening;

  /// No sound events yet.
  ///
  /// In en, this message translates to:
  /// **'No sounds picked up yet.'**
  String get pestListenNone;

  /// Sound list hint.
  ///
  /// In en, this message translates to:
  /// **'Tap a sound you also heard to confirm it'**
  String get pestListenTapToConfirm;

  /// Mic permission denied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Allow it in settings to listen. Your saved sightings stay available.'**
  String get pestListenMicDenied;

  /// Notification permission denied for night mode.
  ///
  /// In en, this message translates to:
  /// **'Night mode needs notifications so you can see and stop listening. Allow notifications and try again.'**
  String get pestListenNightNeedsNotice;

  /// Start a new listen.
  ///
  /// In en, this message translates to:
  /// **'Listen again'**
  String get pestListenAgain;

  /// Sound event title.
  ///
  /// In en, this message translates to:
  /// **'Sound at {time}'**
  String pestSoundAt(String time);

  /// Sound event action.
  ///
  /// In en, this message translates to:
  /// **'Tap to confirm'**
  String get pestSoundConfirm;

  /// Sound-classifier label and raw score.
  ///
  /// In en, this message translates to:
  /// **'{label} · {percent}%'**
  String pestSoundScore(String label, int percent);

  /// Classifier returned nothing.
  ///
  /// In en, this message translates to:
  /// **'No sound labels.'**
  String get pestSoundNoLabels;

  /// Under the labels.
  ///
  /// In en, this message translates to:
  /// **'Raw sound-classifier scores, not calibrated'**
  String get pestSoundRawNote;

  /// While describeSound runs.
  ///
  /// In en, this message translates to:
  /// **'Describing the sound on this phone…'**
  String get pestSoundDescribing;

  /// Experimental LLM description heading.
  ///
  /// In en, this message translates to:
  /// **'AI description (experimental)'**
  String get pestSoundDescription;

  /// No description.
  ///
  /// In en, this message translates to:
  /// **'No AI description available.'**
  String get pestSoundNoDescription;

  /// Sound model provenance.
  ///
  /// In en, this message translates to:
  /// **'Sound model {version} — Experimental'**
  String pestSoundModel(String version);

  /// Cards for the sound.
  ///
  /// In en, this message translates to:
  /// **'Matching cards'**
  String get pestSoundCards;

  /// No cards for the sound.
  ///
  /// In en, this message translates to:
  /// **'No matching card. Inspect physically.'**
  String get pestSoundNoCards;

  /// Clip discarded or missing.
  ///
  /// In en, this message translates to:
  /// **'That sound clip is no longer available. Listen again.'**
  String get pestClipGone;

  /// Save screen title.
  ///
  /// In en, this message translates to:
  /// **'Save sighting'**
  String get pestSaveTitle;

  /// Save screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved only on this phone'**
  String get pestSaveSubtitle;

  /// Location picker label.
  ///
  /// In en, this message translates to:
  /// **'Room or place'**
  String get pestSaveRoom;

  /// No location chosen.
  ///
  /// In en, this message translates to:
  /// **'No room'**
  String get pestSaveNoRoom;

  /// No locations exist.
  ///
  /// In en, this message translates to:
  /// **'No rooms or places yet. You can add them in Inventory.'**
  String get pestSaveNoRooms;

  /// Take a one-time location fix.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get pestSaveLocation;

  /// Location explanation.
  ///
  /// In en, this message translates to:
  /// **'Optional. Location is asked only now. Indoors, the room is usually more useful.'**
  String get pestSaveLocationBody;

  /// While locating.
  ///
  /// In en, this message translates to:
  /// **'Getting location…'**
  String get pestLocating;

  /// Location denied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied, saved room only'**
  String get pestLocationDenied;

  /// Accuracy worse than 25 m or approximate only.
  ///
  /// In en, this message translates to:
  /// **'Location too imprecise, saved room only'**
  String get pestLocationImprecise;

  /// Location service off.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on this phone, saved room only'**
  String get pestLocationOff;

  /// Location error.
  ///
  /// In en, this message translates to:
  /// **'Could not get a location, saved room only'**
  String get pestLocationFailed;

  /// Precise pin saved.
  ///
  /// In en, this message translates to:
  /// **'Pin saved (within {meters} m)'**
  String pestLocationPinned(int meters);

  /// Keep media toggle.
  ///
  /// In en, this message translates to:
  /// **'Keep the picture or clip'**
  String get pestKeepMedia;

  /// Keep media explanation.
  ///
  /// In en, this message translates to:
  /// **'Off by default. Kept privately on this phone with the sighting, never uploaded.'**
  String get pestKeepMediaBody;

  /// Notes field.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get pestNotes;

  /// Snackbar after saving.
  ///
  /// In en, this message translates to:
  /// **'Sighting saved'**
  String get pestSaved;

  /// Save failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Try again.'**
  String get pestSaveFailed;

  /// Sightings list title.
  ///
  /// In en, this message translates to:
  /// **'Sightings'**
  String get pestSightingsTitle;

  /// Sightings list subtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone, newest first'**
  String get pestSightingsSubtitle;

  /// Empty sightings list.
  ///
  /// In en, this message translates to:
  /// **'No sightings yet'**
  String get pestSightingsEmpty;

  /// Empty sightings detail.
  ///
  /// In en, this message translates to:
  /// **'Look or listen for signs and save what you confirm.'**
  String get pestSightingsEmptyDetail;

  /// Sighting with no label.
  ///
  /// In en, this message translates to:
  /// **'Unidentified sighting'**
  String get pestSightingUnnamed;

  /// No verified finding.
  ///
  /// In en, this message translates to:
  /// **'Not checked by a person yet'**
  String get pestNoFindingYet;

  /// Verified finding chip.
  ///
  /// In en, this message translates to:
  /// **'Checked: {finding}'**
  String pestFindingChip(String finding);

  /// Unknown sighting id.
  ///
  /// In en, this message translates to:
  /// **'This sighting is not on this phone.'**
  String get pestNotFound;

  /// Detail title.
  ///
  /// In en, this message translates to:
  /// **'Sighting'**
  String get pestDetailTitle;

  /// Detail section.
  ///
  /// In en, this message translates to:
  /// **'AI analysis'**
  String get pestDetailAiSection;

  /// AI section note.
  ///
  /// In en, this message translates to:
  /// **'AI-estimated — not calibrated. Saved as it was and never edited.'**
  String get pestDetailAiNote;

  /// Detail section.
  ///
  /// In en, this message translates to:
  /// **'Your confirmation'**
  String get pestDetailValidation;

  /// userValidated true.
  ///
  /// In en, this message translates to:
  /// **'You confirmed the signal was real'**
  String get pestDetailConfirmed;

  /// userValidated false.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get pestDetailNotConfirmed;

  /// User's card choice.
  ///
  /// In en, this message translates to:
  /// **'Your pick: {name}'**
  String pestDetailYourPick(String name);

  /// Detail section.
  ///
  /// In en, this message translates to:
  /// **'Verified finding'**
  String get pestDetailVerified;

  /// Verified finding explanation.
  ///
  /// In en, this message translates to:
  /// **'What a person found by checking. Separate from the AI analysis. It can be set once.'**
  String get pestDetailVerifiedBody;

  /// Save the verified finding.
  ///
  /// In en, this message translates to:
  /// **'Record finding'**
  String get pestDetailRecordFinding;

  /// Confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Save \"{finding}\" as the verified finding? It cannot be changed later.'**
  String pestDetailConfirmFinding(String finding);

  /// Detail section.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get pestDetailPlace;

  /// GPS pin row label.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pestDetailPinLabel;

  /// GPS pin value.
  ///
  /// In en, this message translates to:
  /// **'{lat}, {lng} (within {meters} m)'**
  String pestDetailPin(String lat, String lng, int meters);

  /// No location.
  ///
  /// In en, this message translates to:
  /// **'No room or pin saved.'**
  String get pestDetailNoPlace;

  /// Open the sightings map.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get pestDetailShowMap;

  /// Media kept.
  ///
  /// In en, this message translates to:
  /// **'Picture or clip kept on this phone'**
  String get pestDetailMediaKept;

  /// Next step: repeated sightings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A pest was seen again} other{Pests seen {count} times}}'**
  String pestNextRepeated(int count);

  /// Next step: repeated sightings in one place.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{label}: seen again} other{{label}: seen {count} times}}'**
  String pestNextRepeatedOne(String label, int count);

  /// Next step body.
  ///
  /// In en, this message translates to:
  /// **'Check the place and follow the safe steps on the card.'**
  String get pestNextRepeatedBody;

  /// Next step: dangerous or protected animal.
  ///
  /// In en, this message translates to:
  /// **'A sighting needs care'**
  String get pestNextSafety;

  /// Next step body.
  ///
  /// In en, this message translates to:
  /// **'Read the safety steps on the card before going near it.'**
  String get pestNextSafetyBody;

  /// Next step action.
  ///
  /// In en, this message translates to:
  /// **'View sightings'**
  String get pestNextAction;

  /// Map screen title.
  ///
  /// In en, this message translates to:
  /// **'Sightings map'**
  String get mapTitle;

  /// Hub card body.
  ///
  /// In en, this message translates to:
  /// **'Pins for sightings saved with a precise location'**
  String get mapCardBody;

  /// Consent sheet title.
  ///
  /// In en, this message translates to:
  /// **'Use Google Maps?'**
  String get mapConsentTitle;

  /// Consent explanation.
  ///
  /// In en, this message translates to:
  /// **'The map and the walking route come from Google. Google receives the map area you look at and the start and end points of a route.'**
  String get mapConsentBody;

  /// Consent: what is never sent.
  ///
  /// In en, this message translates to:
  /// **'Google never receives the animal, your notes, pictures or sounds.'**
  String get mapConsentNever;

  /// Give maps consent.
  ///
  /// In en, this message translates to:
  /// **'Allow maps'**
  String get mapConsentAllow;

  /// Decline maps consent.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get mapConsentDecline;

  /// Consent not given.
  ///
  /// In en, this message translates to:
  /// **'Maps are off. Nothing is sent until you allow them.'**
  String get mapConsentNeeded;

  /// No maps key in this build.
  ///
  /// In en, this message translates to:
  /// **'Maps not configured'**
  String get mapNotConfigured;

  /// No key explanation.
  ///
  /// In en, this message translates to:
  /// **'This build has no map key. You can still open a pin in the Google Maps app.'**
  String get mapNotConfiguredBody;

  /// geo: fallback.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get mapOpenInGoogleMaps;

  /// No pins.
  ///
  /// In en, this message translates to:
  /// **'No sightings with a precise location yet'**
  String get mapNoPins;

  /// No pins detail.
  ///
  /// In en, this message translates to:
  /// **'Pins appear for sightings saved with a location within 25 m.'**
  String get mapNoPinsDetail;

  /// No pins action.
  ///
  /// In en, this message translates to:
  /// **'View sightings'**
  String get mapNoPinsAction;

  /// Pin info window (date only).
  ///
  /// In en, this message translates to:
  /// **'Sighting {date}'**
  String mapPinLabel(String date);

  /// Compute a route.
  ///
  /// In en, this message translates to:
  /// **'Route from here'**
  String get mapRoute;

  /// While routing.
  ///
  /// In en, this message translates to:
  /// **'Finding a route…'**
  String get mapRouting;

  /// Route distance and ETA.
  ///
  /// In en, this message translates to:
  /// **'{distance} · about {minutes} min'**
  String mapRouteSummary(String distance, int minutes);

  /// Route failed.
  ///
  /// In en, this message translates to:
  /// **'Could not get a route. Check the internet connection and try again.'**
  String get mapRouteFailed;

  /// No origin.
  ///
  /// In en, this message translates to:
  /// **'Your location is needed for a route. Allow location and try again.'**
  String get mapRouteNeedsLocation;

  /// Hand off to Google Maps.
  ///
  /// In en, this message translates to:
  /// **'Start navigation'**
  String get mapStartNavigation;

  /// Hand-off failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps on this phone.'**
  String get mapNavigationFailed;

  /// Distance in km.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String mapDistanceKm(String km);

  /// Distance in metres.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String mapDistanceM(int meters);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'gu',
    'hi',
    'kn',
    'ml',
    'mr',
    'or',
    'pa',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

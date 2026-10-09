import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

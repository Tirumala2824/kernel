// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get languageTitle => 'ভাষা';

  @override
  String get languageFollowDevice => 'ফোনের ভাষা মেনে চলুন';

  @override
  String get languageSheetBody => 'Kernel-এর লেখা সঙ্গে সঙ্গে বদলে যায়।';

  @override
  String get settingsSubtitle =>
      'ভাষা, শব্দ-পরীক্ষা, গোপনীয়তা আর ফোনের ভেতরের তথ্য';

  @override
  String get settingsScanning => 'শব্দ-পরীক্ষা';

  @override
  String get settingsHaptics => 'শুরু আর শেষে কাঁপুনি';

  @override
  String get settingsHapticsBody =>
      'রেকর্ডিং শুরু আর শেষ হলে ফোন একটু কাঁপে, যাতে আপনি ফোনটা বস্তায় চেপে ধরে রাখতে পারেন।';

  @override
  String get settingsVoice => 'মুখে বলা নির্দেশ';

  @override
  String get settingsVoiceBody =>
      'শুরুতে বন্ধ থাকে। এই ফোনে থাকা কণ্ঠে “ফোন বস্তার উপর রাখুন”, “শুনছি” আর “হয়ে গেছে” বলে। ইন্টারনেট থেকে কিছু আনা হয় না।';

  @override
  String get settingsRetain => 'রেকর্ডিং এই ফোনে রাখুন';

  @override
  String get settingsRetainBody =>
      'শুরুতে বন্ধ থাকে: প্রতিটি 2 সেকেন্ডের রেকর্ডিং পরীক্ষার পরেই মুছে ফেলা হয়। চালু করলে রেকর্ডিং অ্যাপের ভেতরে গোপনে রাখা হয়, যাতে আবার পরীক্ষা করা যায়। এগুলো কখনও আপলোড হয় না। “সব ইতিহাস মুছুন” এগুলো সরিয়ে দেয়।';

  @override
  String get settingsResearchSection => 'গবেষণা';

  @override
  String get settingsResearch => 'গবেষণার রেকর্ডিং মোড';

  @override
  String get settingsResearchBody =>
      'শস্যের পোকা চেনার মডেল বানাতে সাহায্য করতে লেবেল দেওয়া নমুনা রেকর্ড করুন। এটা রেকর্ডিং রাখার সেটিং থেকে আলাদা; শুরুতে বন্ধ থাকে।';

  @override
  String get researchConsentTitle => 'গবেষণার রেকর্ডিং চালু করবেন?';

  @override
  String get researchConsentBody =>
      'আপনি “লেবেল দেওয়া নমুনা রেকর্ড করুন” বাছলে সেই 2 সেকেন্ডের রেকর্ডিং আপনার দেওয়া লেবেলসহ এই ফোনে গোপনে রাখা হয়। “কোনো চিহ্ন নেই” বা “পোকা লেগেছে” লেবেলের জন্য নিজে দেখে করা পরীক্ষায় তার প্রমাণ লাগবে। কিছুই আপলোড হয় না: আপনি একটা ডেটাসেট ফাইল বানিয়ে নিজেই ঠিক করতে পারেন সেটা কাকে দেবেন। যেকোনো সময় এটা বন্ধ করুন; “সব ইতিহাস মুছুন” সব রেকর্ডিং আর লেবেল মুছে দেয়।';

  @override
  String get researchConsentAgree => 'আমি রাজি, চালু করুন';

  @override
  String get settingsSamplesCard => 'প্রতিটি লেবেলের সংখ্যা আর ডেটাসেট ফাইল';

  @override
  String get settingsPrivacy => 'গোপনীয়তা';

  @override
  String get deleteHistoryTitle => 'সব ইতিহাস মুছুন';

  @override
  String get deleteHistoryBody =>
      'শব্দ-পরীক্ষা, দেখে পরীক্ষা ও তার ছবি, রিমাইন্ডার, লেবেল দেওয়া নমুনা আর রাখা রেকর্ডিং মুছে দেয়।';

  @override
  String get deleteHistoryConfirmTitle => 'সব ইতিহাস মুছবেন?';

  @override
  String get deleteHistoryConfirmBody =>
      'এতে এই ফোনের প্রতিটি শব্দ-পরীক্ষা, দেখে পরীক্ষা (ছবিসহ), রিমাইন্ডার, লেবেল দেওয়া নমুনা আর রাখা রেকর্ডিং মুছে যাবে। আপনার নথিভুক্ত জিনিস, জায়গা, ফসল আর লট থেকে যাবে। এটা আর ফেরানো যাবে না।';

  @override
  String get deleteHistoryConfirmAction => 'ইতিহাস মুছুন';

  @override
  String get deleteHistoryDone => 'সব ইতিহাস মুছে গেছে';

  @override
  String deleteHistoryFailed(String detail) {
    return 'ইতিহাস মোছা গেল না: $detail';
  }

  @override
  String get settingsOnDevice => 'ফোনেই শব্দ-পরীক্ষা';

  @override
  String get engineUnavailable => 'শব্দ-পরীক্ষা ইঞ্জিনের তথ্য পাওয়া যাচ্ছে না';

  @override
  String get engineModelPresent => 'ফলাফল পরীক্ষামূলক, যাচাই করা নয়।';

  @override
  String get engineNoModel =>
      'কোনো মডেল বসানো নেই, তাই শব্দ-পরীক্ষা শুধু রেকর্ডিংয়ের মান দেখে আর ফলাফলে “ফল তৈরি হয়নি” দেখায়।';

  @override
  String get settingsFooter =>
      'সব শব্দ-পরীক্ষা এই ফোনেই হয়। Kernel ইন্টারনেট ছাড়াই চলে আর কখনও শব্দ আপলোড করে না।';

  @override
  String get diagnosticsTitle => 'যান্ত্রিক তথ্য';

  @override
  String get diagnosticsCard =>
      'পরীক্ষার জন্য মডেল, প্রসেসর, স্যাম্পল রেট আর ফোনের তথ্য';

  @override
  String get diagnosticsSubtitle => 'এই ফোনে শব্দ-পরীক্ষা ইঞ্জিন কী জানাচ্ছে';

  @override
  String get notMeasured => 'এখনও মাপা হয়নি';

  @override
  String get yes => 'হ্যাঁ';

  @override
  String get no => 'না';

  @override
  String get diagModelInstalled => 'মডেল বসানো আছে';

  @override
  String get diagModelNote => 'মডেলের তথ্য';

  @override
  String get diagDelegate => 'প্রসেসর';

  @override
  String get diagAudioTitle => 'শব্দ ইনপুট';

  @override
  String get diagTargetRate => 'লক্ষ্য স্যাম্পল রেট';

  @override
  String get diagEffectiveRate => 'আসল স্যাম্পল রেট';

  @override
  String get diagDeviceRate => 'ফোনের ইনপুট রেট';

  @override
  String get diagAudioSource => 'শব্দের উৎস';

  @override
  String get diagDeviceTitle => 'ফোন';

  @override
  String get diagOs => 'অ্যান্ড্রয়েড';

  @override
  String get diagAppVersion => 'অ্যাপ ভার্সন';

  @override
  String get diagLogRowTitle => 'ডিভাইস-লগের সারি';

  @override
  String get diagLogRowBody =>
      'এই সারিটা docs/device-validation.md-এর ডিভাইস লগে বসান আর নিজের নাম লিখুন।';

  @override
  String get diagCopyRow => 'ডিভাইস-লগের সারি কপি করুন';

  @override
  String get diagCopied => 'সারি কপি হয়েছে';

  @override
  String get qrTitle => 'QR লেবেল থেকে খুলুন';

  @override
  String get qrInstructions =>
      'লেবেলটা ফ্রেমের ভেতরে ধরুন। পড়া হলেই খুলে যাবে।';

  @override
  String get qrNotKernel =>
      'এই QR কোড Kernel-এর বস্তার লেবেল নয়। Kernel থেকে ছাপা লেবেলের দিকে ক্যামেরা ধরুন।';

  @override
  String get qrUnknownItem => 'এই লেবেল এমন বস্তার, যা এই ফোনে নেই।';

  @override
  String qrLookupFailed(String detail) {
    return 'বস্তা খোলা গেল না: $detail';
  }

  @override
  String get qrScanAnother => 'আরেকটা লেবেল পড়ুন';

  @override
  String get qrRationaleTitle => 'বস্তার লেবেল পড়তে ক্যামেরা ব্যবহার করুন';

  @override
  String get qrRationaleBody =>
      'Kernel ক্যামেরা শুধু বস্তার QR লেবেল পড়তে আর পরীক্ষার ছবি তুলতে ব্যবহার করে। লেবেল এই ফোনেই পড়া হয়; ক্যামেরার ছবি সেভ বা আপলোড হয় না।';

  @override
  String get qrAllowCamera => 'ক্যামেরার অনুমতি দিন';

  @override
  String get qrCameraDenied =>
      'ক্যামেরার অনুমতি দেওয়া হয়নি। তবু আপনি আপনার মজুত থেকে বস্তা খুলতে পারেন।';

  @override
  String get qrCameraBlocked =>
      'Kernel-এর জন্য ক্যামেরা বন্ধ করা আছে। ফোনের সেটিংস খুলুন, অনুমতি বাছুন, তারপর ক্যামেরার অনুমতি দিন।';

  @override
  String get qrPrivacyNote => 'লেবেল এই ফোনেই পড়া হয়। কিছুই আপলোড হয় না।';

  @override
  String get labelSampleTitle => 'গবেষণার রেকর্ডিংয়ে লেবেল দিন';

  @override
  String get labelRuleNote =>
      '“কোনো চিহ্ন নেই” বা “পোকা লেগেছে” তখনই বাছুন, যখন এই বস্তার নিজে দেখে করা পরীক্ষা তা নিশ্চিত করেছে। নইলে “জানা নেই” বাছুন।';

  @override
  String get labelCleanHelp =>
      'দেখে পরীক্ষায় কোনো পোকা পাওয়া যায়নি, তা নিশ্চিত';

  @override
  String get labelCleanNeedsInspection =>
      'এই বস্তার এমন একটা দেখে পরীক্ষা চাই, যাতে পোকা পাওয়া যায়নি';

  @override
  String get labelInfestedHelp => 'দেখে পরীক্ষায় পোকা পাওয়া গেছে, তা নিশ্চিত';

  @override
  String get labelInfestedNeedsInspection =>
      'এই বস্তার এমন একটা দেখে পরীক্ষা চাই, যাতে পোকা পাওয়া গেছে';

  @override
  String get labelUnknownHelp =>
      'কোনো পরীক্ষায় এই বস্তার অবস্থা নিশ্চিত হয়নি';

  @override
  String get labelNeedsEvidence =>
      '“কোনো চিহ্ন নেই” আর “পোকা লেগেছে”-র জন্য এই বস্তার মিলে যাওয়া দেখে পরীক্ষা চাই। “জানা নেই” বাছুন বা আগে একটা দেখে পরীক্ষা লিখে রাখুন।';

  @override
  String get evidenceTitle => 'নিশ্চিত করার পরীক্ষা';

  @override
  String get evidenceBody => 'এই রেকর্ডিংয়ের জন্য করা দেখে পরীক্ষাটা বাছুন।';

  @override
  String get sackMaterialField => 'বস্তা বা পাত্রের উপাদান';

  @override
  String get notRecorded => 'লেখা নেই';

  @override
  String get environmentField => 'পরিবেশ';

  @override
  String get environmentHelper =>
      'কোথায় রেকর্ড করা হয়েছে, যেমন শান্ত ঘর বা পাখা চলা গুদাম';

  @override
  String get envQuietRoom => 'শান্ত ঘর';

  @override
  String get envWarehouse => 'গুদাম';

  @override
  String get envFansOn => 'পাখা বা যন্ত্র চলছে';

  @override
  String get envOutdoors => 'বাইরে খোলা জায়গায়';

  @override
  String get materialJute => 'পাট';

  @override
  String get materialWovenPp => 'প্লাস্টিকের বোনা বস্তা (PP)';

  @override
  String get materialCotton => 'সুতি';

  @override
  String get materialPlastic => 'প্লাস্টিকের পাত্র';

  @override
  String get materialMetal => 'ধাতুর পাত্র';

  @override
  String get materialOther => 'অন্য';

  @override
  String get sampleSave => 'লেবেল দেওয়া নমুনা সেভ করুন';

  @override
  String get sampleSaved => 'লেবেল দেওয়া নমুনা এই ফোনে সেভ হয়েছে';

  @override
  String sampleRejected(String detail) {
    return 'লেবেল সেভ হয়নি: $detail';
  }

  @override
  String get sampleUnusableRetry =>
      'এই রেকর্ডিং কাজে লাগার মতো ছিল না, তাই এতে লেবেল দেওয়া যাবে না। কোনো শান্ত জায়গায় আবার রেকর্ড করুন।';

  @override
  String get sampleUnusableNotKept =>
      'এই রেকর্ডিংয়ের শব্দ রাখা হয়নি, তাই এতে লেবেল দেওয়া যাবে না।';

  @override
  String get sampleRecordAgain => 'আবার রেকর্ড করুন';

  @override
  String get samplesTitle => 'গবেষণার নমুনা';

  @override
  String samplesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'এই ফোনে $countটি লেবেল দেওয়া রেকর্ডিং',
      one: 'এই ফোনে 1টি লেবেল দেওয়া রেকর্ডিং',
      zero: 'এখনও কোনো লেবেল দেওয়া রেকর্ডিং নেই',
    );
    return '$_temp0';
  }

  @override
  String get samplesResearchOff =>
      'গবেষণার রেকর্ডিং মোড বন্ধ। নতুন নমুনা রেকর্ড করতে সেটিংসে এটা চালু করুন।';

  @override
  String get samplesEmpty => 'এখনও কোনো লেবেল দেওয়া নমুনা নেই';

  @override
  String get samplesEmptyDetail =>
      'গবেষণা মোড চালু রেখে একটা বস্তা খুলুন আর “লেবেল দেওয়া নমুনা রেকর্ড করুন” বাছুন।';

  @override
  String get datasetTitle => 'প্রশিক্ষণের ডেটাসেট';

  @override
  String get datasetBody =>
      'রাখা রেকর্ডিংয়ের একটা ZIP আর তাদের লেবেলের একটা CSV, এই ফোনেই তৈরি হয়। কোথায় পাঠাবেন আপনি ঠিক করবেন; Kernel কখনও এটা আপলোড করে না।';

  @override
  String get datasetExport => 'ডেটাসেট ফাইল বানান';

  @override
  String datasetExportFailed(String detail) {
    return 'ডেটাসেট তৈরি বা পাঠানো গেল না। $detail';
  }

  @override
  String sampleLabelChip(String label) {
    return 'লেবেল: $label';
  }

  @override
  String get sampleConfirmed => 'দেখে পরীক্ষায় নিশ্চিত';

  @override
  String get inspectionTitle => 'নিজে দেখে পরীক্ষা';

  @override
  String get saveInspection => 'পরীক্ষা সেভ করুন';

  @override
  String get inspectionSaved => 'পরীক্ষা সেভ হয়েছে';

  @override
  String get aiPanelTitle => 'AI-এর অনুমান (যাচাই হয়নি)';

  @override
  String get aiPanelLoading => 'যুক্ত শব্দ-পরীক্ষা খোলা হচ্ছে…';

  @override
  String get aiPanelNoScan =>
      'কোনো শব্দ-পরীক্ষা যুক্ত নেই। এই দেখে পরীক্ষা নিজেই সম্পূর্ণ।';

  @override
  String scannedAt(String when) {
    return 'শব্দ-পরীক্ষা $when';
  }

  @override
  String get aiPanelNotUsed => 'আপনার ফল লিখতে এটা ব্যবহার হয়নি';

  @override
  String get findingPanelTitle => 'আপনার যাচাই করা ফল';

  @override
  String get findingPanelBody =>
      'শস্য পরীক্ষার সময় আপনি নিজে যা দেখেছেন। এটা AI-এর অনুমান থেকে আলাদা রাখা হয়।';

  @override
  String get findingMissing => 'কী পেলেন বাছুন';

  @override
  String get inspectorField => 'পরীক্ষকের নাম';

  @override
  String get validationInspector => 'কে পরীক্ষা করেছেন লিখুন';

  @override
  String get inspectionDateField => 'পরীক্ষার তারিখ';

  @override
  String get observationsField => 'যা দেখা গেছে';

  @override
  String get observationsHelper => 'কী দেখেছেন, কোথায় আর কতটা';

  @override
  String get assigneeFieldOptional => 'পরের পরীক্ষার দায়িত্ব কাকে (ঐচ্ছিক)';

  @override
  String get followUpStatusTitle => 'পরের পরীক্ষার অবস্থা';

  @override
  String get photosTitle => 'প্রমাণের ছবি (ঐচ্ছিক)';

  @override
  String get photosBody =>
      'ছবিগুলো এই পরীক্ষার সঙ্গে এই ফোনেই গোপনে থাকে। এগুলো আপনার দেখা জিনিসের প্রমাণ, শব্দ-পরীক্ষার ফল নয়, আর কখনও আপলোড হয় না।';

  @override
  String get photoTake => 'ছবি তুলুন';

  @override
  String get photoPick => 'গ্যালারি থেকে বাছুন';

  @override
  String get cameraDeniedPhoto =>
      'ক্যামেরা বন্ধ। প্রমাণের ছবি তুলতে ফোনের সেটিংসে অনুমতি দিন।';

  @override
  String photoFailed(String detail) {
    return 'ছবি যোগ করা গেল না: $detail';
  }

  @override
  String get filterAll => 'সব';

  @override
  String get filterNoMatch => 'এই ফিল্টারে কোনো খোলা পরীক্ষা নেই।';

  @override
  String get batchSetupTitle => 'একটা ঘর বা গাদা বাছুন';

  @override
  String get batchSetupSubtitle =>
      'Kernel আপনাকে এর বস্তাগুলোয় একে একে নিয়ে যাবে।';

  @override
  String get batchSequentialNote =>
      'প্রতি বস্তায় একটা রেকর্ডিং। Kernel কখনও একসঙ্গে অনেক বস্তার শব্দ-পরীক্ষা করে না।';

  @override
  String get batchNoPlaces => 'এখনও কোনো ঘর বা গাদা নেই';

  @override
  String get batchNoPlacesDetail =>
      'একটা গুদাম তার ঘর আর গাদাসহ যোগ করুন, তারপর সেখানে বস্তা নথিভুক্ত করুন।';

  @override
  String batchPlaceSubtitle(String type, int total, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalটি বস্তা',
      one: '1টি বস্তা',
    );
    return '$type · $_temp0 · $needScanটির শব্দ-পরীক্ষা বাকি';
  }

  @override
  String batchIntroSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি বস্তা, একে একে দেখা হবে',
      one: '1টি বস্তা, একে একে দেখা হবে',
      zero: 'দেখার মতো কোনো বস্তা নেই',
    );
    return '$_temp0';
  }

  @override
  String get batchSkipToday => 'আজ পরীক্ষা হওয়া বস্তা বাদ দিন';

  @override
  String get batchSkipTodayBody =>
      'যেসব বস্তার আজকের রেকর্ডিং আগেই আছে, সেগুলো বাদ দিন।';

  @override
  String batchWalkLine(int position, String label, String grain) {
    return '$position. $label · $grain';
  }

  @override
  String batchStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি বস্তা দিয়ে শুরু করুন',
      one: '1টি বস্তা দিয়ে শুরু করুন',
    );
    return '$_temp0';
  }

  @override
  String get batchNothingToWalk =>
      'এখানকার প্রতিটি বস্তার কাজে লাগার মতো শব্দ-পরীক্ষা আছে বা আজ পরীক্ষা হয়ে গেছে।';

  @override
  String batchProgress(int position, int total) {
    return '$totalটির মধ্যে বস্তা $position';
  }

  @override
  String get batchSkipSack => 'এই বস্তা বাদ দিন';

  @override
  String get batchStop => 'দফা থামান';

  @override
  String batchNextIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds সেকেন্ডে পরের বস্তা',
      one: '1 সেকেন্ডে পরের বস্তা',
    );
    return '$_temp0';
  }

  @override
  String batchSummaryIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds সেকেন্ডে সারাংশ',
      one: '1 সেকেন্ডে সারাংশ',
    );
    return '$_temp0';
  }

  @override
  String get batchNextSack => 'পরের বস্তা';

  @override
  String get batchFinish => 'শেষ করুন';

  @override
  String get batchRetrySack => 'এই বস্তা আবার রেকর্ড করুন';

  @override
  String get batchSummaryTitle => 'দফার সারাংশ';

  @override
  String batchSummarySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'এই দফায় $countটি বস্তা',
      one: 'এই দফায় 1টি বস্তা',
    );
    return '$_temp0';
  }

  @override
  String get batchStatRecorded => 'রেকর্ড হয়েছে';

  @override
  String get batchStatSkipped => 'বাদ গেছে';

  @override
  String get batchStatRetry => 'আবার করতে হবে';

  @override
  String get rankedTitle => 'ক্রম অনুযায়ী';

  @override
  String rankLabel(int rank) {
    return '#$rank';
  }

  @override
  String get queueSuggestionNote =>
      'এই ক্রম শুধু পরামর্শ, কোনটা আগে দেখবেন। যেকোনো সিদ্ধান্তের আগে নিজে দেখে পরীক্ষা করুন।';

  @override
  String get queueNothingRanked =>
      'এখনও কোনো জিনিসের কাজে লাগার মতো মডেল ফল নেই, তাই কিছুই ক্রমে নেই। যাদের ফল নেই, সেগুলো “শব্দ-পরীক্ষা বাকি”-তে আছে।';

  @override
  String get queueNothingRankedShort => 'এখনও কিছু ক্রমে নেই';

  @override
  String needsScanTitle(int count) {
    return 'শব্দ-পরীক্ষা বাকি ($count)';
  }

  @override
  String get needsScanChip => 'শব্দ-পরীক্ষা বাকি';

  @override
  String get needsScanEmpty =>
      'প্রতিটি জিনিসের কাজে লাগার মতো শব্দ-পরীক্ষা আছে।';

  @override
  String get saveHarvest => 'ফসল সেভ করুন';

  @override
  String get harvestNameField => 'ফসলের নাম';

  @override
  String get harvestNameHelper => 'যেমন “রবি গম 2026”';

  @override
  String get harvestedOnField => 'কাটার তারিখ';

  @override
  String get notesFieldOptional => 'নোট (ঐচ্ছিক)';

  @override
  String get harvestAppBar => 'ফসল';

  @override
  String get harvestNotFound => 'এই ফসল এই ফোনে পাওয়া যায়নি।';

  @override
  String get harvestAddSack => 'এই ফসলে বস্তা নথিভুক্ত করুন';

  @override
  String get harvestSacksTitle => 'এই ফসলের বস্তা';

  @override
  String get harvestSacksEmpty => 'এই ফসলে এখনও কোনো বস্তা নেই';

  @override
  String get harvestSacksEmptyDetail =>
      'এই ফসল থেকে ভরা বস্তাগুলো নথিভুক্ত করুন, তারপর বিক্রির আগে সেগুলোর শব্দ-পরীক্ষা করুন।';

  @override
  String get preSaleBody =>
      'ক্রেতার জন্য এই ফসলের বস্তার সারাংশ। প্রতিটি শব্দ-পরীক্ষার সঙ্গে মডেলের ভার্সন আর পরীক্ষামূলক অবস্থা দেখানো হয়, আর দেখে পরীক্ষার যাচাই করা ফল আলাদা লেখা থাকে। এটা মানের সার্টিফিকেট নয়।';

  @override
  String get notScannedYet => 'এখনও শব্দ-পরীক্ষা হয়নি';

  @override
  String get lotAppBar => 'লট';

  @override
  String get lotNotFound => 'এই লট এই ফোনে পাওয়া যায়নি।';

  @override
  String get supplierNotRecorded => 'সরবরাহকারী লেখা নেই';

  @override
  String get fieldDeclaredQuantity => 'জানানো পরিমাণ';

  @override
  String get fieldReceived => 'পাওয়ার তারিখ';

  @override
  String get fieldScreened => 'পরীক্ষা হয়েছে';

  @override
  String get screeningStatusTitle => 'পরীক্ষার অবস্থা';

  @override
  String get screeningStatusBody =>
      'শব্দ-পরীক্ষা আর খুলে পরীক্ষা দেখে এটা আপনি ঠিক করেন। শব্দ-পরীক্ষা কখনও এটা বদলায় না, আর Kernel কখনও কোনো লট মেনে নেয় বা বাতিল করে না।';

  @override
  String currentStatus(String status) {
    return 'এখন: $status';
  }

  @override
  String get lotSacksTitle => 'এই লটের বস্তা';

  @override
  String get lotSacksEmpty => 'এই লটে এখনও কোনো বস্তা নেই';

  @override
  String get lotSacksEmptyAction => 'এই লটে একটা বস্তা নথিভুক্ত করুন';

  @override
  String get sampleScansTitle => 'নমুনা শব্দ-পরীক্ষা';

  @override
  String get sampleScansBody =>
      'এই চালানের বস্তাগুলোর একে একে শব্দ-পরীক্ষা করুন। প্রতিটি ফল মডেলের যাচাই না হওয়া অনুমান, আর এতে লটের অবস্থা বদলায় না।';

  @override
  String get sampleScansStart => 'নমুনা শব্দ-পরীক্ষা শুরু করুন';

  @override
  String get physicalChecksTitle => 'খুলে পরীক্ষা';

  @override
  String get physicalChecksBody =>
      'প্রতিটি বস্তা খুলে ভেতরে দেখুন, তারপর যা পেলেন লিখে রাখুন। আপনার ফল শব্দ-পরীক্ষা থেকে আলাদা রাখা হয়।';

  @override
  String get recordPhysicalCheck => 'খুলে পরীক্ষা লিখে রাখুন';

  @override
  String get noPhysicalCheckYet => 'এখনও খুলে পরীক্ষা হয়নি';

  @override
  String lotSummaryTitle(String code) {
    return 'লট $code-এর সারাংশ রিপোর্ট';
  }

  @override
  String get lotSummaryBody =>
      'এই ফোনের রেকর্ড থেকে তৈরি: মডেলের তথ্যসহ নমুনা শব্দ-পরীক্ষা, আর খুলে পরীক্ষার ফল আলাদা করে। নিজের সিদ্ধান্তে সাহায্যের জন্য এটা ব্যবহার করুন।';

  @override
  String savedLot(String code) {
    return 'লট $code সেভ হয়েছে';
  }

  @override
  String get saveLot => 'লট সেভ করুন';

  @override
  String get lotCodeField => 'লট কোড';

  @override
  String get lotCodeHelper => 'চালানের কাগজে লেখা নম্বর';

  @override
  String get validationLotCode => 'লট কোড লিখুন';

  @override
  String get supplierFieldOptional => 'সরবরাহকারীর নাম (ঐচ্ছিক)';

  @override
  String get declaredQuantityField => 'জানানো পরিমাণ';

  @override
  String get receivedOnField => 'পাওয়ার তারিখ';

  @override
  String shareSubject(String title) {
    return 'Kernel $title';
  }

  @override
  String exportFailed(String detail) {
    return 'রিপোর্ট তৈরি বা পাঠানো গেল না। $detail';
  }

  @override
  String get exportPanelBody =>
      'শুধু এই ফোনে রাখা রেকর্ড থেকে তৈরি। প্রতিটি শব্দ-পরীক্ষার সঙ্গে মডেলের ভার্সন আর পরীক্ষামূলক অবস্থা দেখানো হয়। AI-এর অনুমান আর দেখে পরীক্ষার যাচাই করা ফল আলাদা আলাদা লেখা থাকে।';

  @override
  String get exportCsv => 'CSV বানান';

  @override
  String get exportPdf => 'PDF বানান';

  @override
  String get exportLabelsPdf => 'লেবেলের PDF বানান';

  @override
  String exportSavedAt(String path) {
    return 'এই ফোনে সেভ হয়েছে: $path';
  }

  @override
  String get sackLabelsTitle => 'বস্তার লেবেল ছাপুন';

  @override
  String get sackLabelsBody =>
      'এই বস্তাগুলোর QR লেবেলের একটা PDF। ছেপে প্রতিটি লেবেল তার বস্তায় সেঁটে দিন; লেবেল পড়লে Kernel-এ সেই বস্তা খুলে যায়।';

  @override
  String get reportsTitle => 'রিপোর্ট';

  @override
  String get reportsFarmerHint =>
      'কোনো ফসলের বিক্রির আগের সারাংশ সেই ফসলের পাতায় আছে।';

  @override
  String get reportsBuyerHint => 'লটের সারাংশ রিপোর্ট প্রতিটি লটের পাতায় আছে।';

  @override
  String get recentScans => 'সাম্প্রতিক শব্দ-পরীক্ষা';

  @override
  String get recentScansEmpty =>
      'এখনও কোনো শব্দ-পরীক্ষা নেই। আপনার রেকর্ড করা শব্দ-পরীক্ষা এখানে দেখা যাবে।';

  @override
  String get inventorySubtitleFarmer => 'আপনার ফসল আর নথিভুক্ত বস্তা';

  @override
  String get inventorySubtitleHousehold =>
      'আপনার শস্যের পাত্র আর সেগুলো কোথায় রাখা';

  @override
  String get inventorySubtitleFpo => 'গুদাম, ঘর, গাদা আর বস্তা';

  @override
  String get inventorySubtitleBuyer => 'আসা লট আর তাদের বস্তা';

  @override
  String get newHarvestAction => 'নতুন ফসল';

  @override
  String registerItemAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'পাত্র যোগ করুন',
      'other': 'বস্তা নথিভুক্ত করুন',
    });
    return '$_temp0';
  }

  @override
  String get addPlace => 'জায়গা যোগ করুন';

  @override
  String get addLocation => 'জায়গা যোগ করুন';

  @override
  String itemsSectionTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'পাত্র',
      'other': 'বস্তা',
    });
    return '$_temp0';
  }

  @override
  String get lotsSectionEmpty =>
      'এখনও কোনো লট নেই। যোগ করতে একটা চালান নথিভুক্ত করুন।';

  @override
  String get placesTitle => 'জায়গা';

  @override
  String get locationsTitle => 'জায়গা';

  @override
  String get placesEmpty =>
      'এখনও কোনো জায়গা নেই। পাত্র কোথায় রাখা, জানাতে একটা যোগ করুন।';

  @override
  String get locationsEmpty =>
      'এখনও কোনো গুদাম নেই। একটা যোগ করুন, তারপর তার ঘর আর গাদা।';

  @override
  String get harvestsSectionEmpty =>
      'এখনও কোনো ফসল নেই। তার বস্তাগুলো একসঙ্গে রাখতে আর বিক্রির আগের সারাংশ বানাতে একটা ফসল তৈরি করুন।';

  @override
  String harvestCardSubtitle(String grain, String date) {
    return '$grain · কাটা হয়েছে $date';
  }

  @override
  String sackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি বস্তা',
      one: '1টি বস্তা',
      zero: 'এখনও কোনো বস্তা নেই',
    );
    return '$_temp0';
  }

  @override
  String get itemDetailAppBar => 'বিস্তারিত';

  @override
  String get itemNotFound => 'এই জিনিস এই ফোনে পাওয়া যায়নি।';

  @override
  String archiveItemMenu(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'পাত্র সরিয়ে রাখুন',
      'other': 'বস্তা সরিয়ে রাখুন',
    });
    return '$_temp0';
  }

  @override
  String get archivedSnack =>
      'সরিয়ে রাখা হয়েছে। এর ইতিহাস এই ফোনে থেকে যাবে।';

  @override
  String get archivedItemNotice =>
      'তালিকা, সারি আর নতুন রিপোর্টে দেখা যাবে না। এর শব্দ-পরীক্ষার ইতিহাস আর দেখে পরীক্ষা থেকে যায়।';

  @override
  String get restoreAction => 'ফিরিয়ে আনুন';

  @override
  String scanThisItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'এই পাত্রের শব্দ-পরীক্ষা করুন',
      'other': 'এই বস্তার শব্দ-পরীক্ষা করুন',
    });
    return '$_temp0';
  }

  @override
  String get setReminderAction => 'আবার পরীক্ষার রিমাইন্ডার দিন';

  @override
  String get researchRecordTitle => 'লেবেল দেওয়া নমুনা রেকর্ড করুন';

  @override
  String get researchRecordSubtitle =>
      'গবেষণা মোড: 2 সেকেন্ডের রেকর্ডিং রেখে প্রশিক্ষণের ডেটার জন্য লেবেল দিন';

  @override
  String get fieldQuantity => 'পরিমাণ';

  @override
  String get fieldStoredSince => 'কবে থেকে রাখা';

  @override
  String storedSinceValue(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days দিন',
      one: '1 দিন',
    );
    return '$date ($_temp0)';
  }

  @override
  String get fieldLocation => 'জায়গা';

  @override
  String get fieldLot => 'লট';

  @override
  String get fieldHarvest => 'ফসল';

  @override
  String nameWithType(String name, String type) {
    return '$name ($type)';
  }

  @override
  String registeredAs(String role) {
    return '$role হিসেবে নথিভুক্ত';
  }

  @override
  String get scanHistoryTitle => 'শব্দ-পরীক্ষার ইতিহাস';

  @override
  String get scanHistoryAppendOnly =>
      'প্রতিটি শব্দ-পরীক্ষা যেমন রেকর্ড হয়েছে তেমনই রাখা হয়। নতুন শব্দ-পরীক্ষা কখনও পুরনোটা বদলায় না।';

  @override
  String scanHistoryEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'এখনও কোনো শব্দ-পরীক্ষা নেই। একটা রেকর্ড করতে “এই পাত্রের শব্দ-পরীক্ষা করুন” চাপুন।',
      'other': 'এখনও কোনো শব্দ-পরীক্ষা নেই। একটা রেকর্ড করতে “এই বস্তার শব্দ-পরীক্ষা করুন” চাপুন।',
    });
    return '$_temp0';
  }

  @override
  String get inspectionsTitle => 'দেখে পরীক্ষা';

  @override
  String get inspectionsEmpty => 'এখনও কোনো দেখে পরীক্ষা লেখা হয়নি।';

  @override
  String get remindersTitle => 'রিমাইন্ডার';

  @override
  String get remindersEmpty => 'কোনো রিমাইন্ডার দেওয়া নেই।';

  @override
  String recheckOn(String when) {
    return '$when আবার পরীক্ষা';
  }

  @override
  String get reminderMarkDone => 'হয়ে গেছে চিহ্ন দিন';

  @override
  String get reminderCancel => 'রিমাইন্ডার বাতিল করুন';

  @override
  String get assignDialogTitle => 'পরীক্ষার দায়িত্ব দিন';

  @override
  String get assignDialogLabel => 'দায়িত্বে আছেন';

  @override
  String get assignDialogHelper => 'পরের পরীক্ষা কে করবেন';

  @override
  String get assignClear => 'দায়িত্ব সরান';

  @override
  String savedNamed(String name) {
    return '$name সেভ হয়েছে';
  }

  @override
  String saveFailed(String detail) {
    return 'সেভ করা গেল না: $detail';
  }

  @override
  String saveItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'পাত্র সেভ করুন',
      'other': 'বস্তা সেভ করুন',
    });
    return '$_temp0';
  }

  @override
  String itemLabelField(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'পাত্রের লেবেল',
      'other': 'বস্তার লেবেল',
    });
    return '$_temp0';
  }

  @override
  String itemLabelHelper(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'পাত্রের গায়ে লেখা নাম',
      'other': 'বস্তার গায়ে লেখা নাম',
    });
    return '$_temp0';
  }

  @override
  String get validationLabel => 'একটা লেবেল লিখুন';

  @override
  String get grainTypeField => 'শস্যের ধরন';

  @override
  String get validationGrain => 'শস্যের ধরন লিখুন';

  @override
  String get quantityField => 'পরিমাণ';

  @override
  String get unitField => 'একক';

  @override
  String get storageDateField => 'রাখার তারিখ';

  @override
  String get harvestFieldOptional => 'ফসল (ঐচ্ছিক)';

  @override
  String get harvestFieldNone =>
      'এখনও কোনো ফসল নেই। “আমার শস্য” থেকে একটা তৈরি করুন।';

  @override
  String get none => 'কোনোটাই না';

  @override
  String get locationFieldOptional => 'জায়গা (ঐচ্ছিক)';

  @override
  String locationFieldNone(String where) {
    return 'এখনও কোনো জায়গা নেই। আপনি $where থেকে যোগ করতে পারেন।';
  }

  @override
  String get lotFieldOptional => 'লট (ঐচ্ছিক)';

  @override
  String get lotFieldNone => 'এখনও কোনো লট নথিভুক্ত হয়নি।';

  @override
  String get locationAppBar => 'জায়গা';

  @override
  String get locationNotFound => 'এই জায়গা এই ফোনে পাওয়া যায়নি।';

  @override
  String get archivedLocationNotice =>
      'এই জায়গা সরিয়ে রাখা হয়েছে। এর বস্তা আর তাদের ইতিহাস থেকে যায়।';

  @override
  String registerHere(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'এখানে পাত্র যোগ করুন',
      'other': 'এখানে বস্তা নথিভুক্ত করুন',
    });
    return '$_temp0';
  }

  @override
  String get addInside => 'ভেতরে যোগ করুন';

  @override
  String get batchHere => 'এখানে একে একে পরীক্ষা';

  @override
  String get insideTitle => 'ভেতরে';

  @override
  String get insideEmpty => 'এই জায়গার ভেতরে এখনও কিছু নেই।';

  @override
  String itemsHereTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'এখানকার পাত্র',
      'other': 'এখানকার বস্তা',
    });
    return '$_temp0';
  }

  @override
  String itemsHereEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'এখানে এখনও কোনো পাত্র রাখা নেই।',
      'other': 'এখানে এখনও কোনো বস্তা রাখা নেই।',
    });
    return '$_temp0';
  }

  @override
  String get saveLocation => 'জায়গা সেভ করুন';

  @override
  String get typeField => 'ধরন';

  @override
  String get nameField => 'নাম';

  @override
  String get validationName => 'একটা নাম লিখুন';

  @override
  String get parentFieldOptional => 'কার ভেতরে (ঐচ্ছিক)';

  @override
  String get parentFieldHelper => 'যেমন গুদামের ভেতরের একটা ঘর';

  @override
  String get parentTopLevel => 'কোনোটার ভেতরে নয় (সবার উপরে)';

  @override
  String get roleSelectTitle => 'আপনার ভূমিকা বাছুন';

  @override
  String get roleSelectSubtitle => 'একটা অ্যাপ। চার রকম কাজ।';

  @override
  String get roleCurrent => 'এখনকার';

  @override
  String get roleSwitchKeepsRecords =>
      'ভূমিকা বদলালেও এই ফোনের সব রেকর্ড থেকে যায়। যেকোনো সময় আবার ফিরে আসতে পারেন।';

  @override
  String roleSaveFailed(String detail) {
    return 'আপনার ভূমিকা সেভ করা গেল না: $detail';
  }

  @override
  String startDataError(String detail) {
    return 'Kernel এই ফোনে নিজের তথ্য খুলতে পারেনি। অ্যাপটা আবার চালু করুন।\n\nবিস্তারিত: $detail';
  }

  @override
  String get onboardingSkip => 'বাদ দিন';

  @override
  String get onboardingBack => 'পিছনে';

  @override
  String get onboardingNext => 'পরে';

  @override
  String onboardingStep(int step, int total) {
    return '$totalটির মধ্যে ধাপ $step';
  }

  @override
  String get onboardingPrivacyTitle => 'শব্দ আপনার ফোনেই থাকে';

  @override
  String get onboardingPrivacy1 =>
      'Kernel শস্যের শব্দ 2 সেকেন্ড শোনে আর এই ফোনেই তা পরীক্ষা করে।';

  @override
  String get onboardingPrivacy2 =>
      'কিছুই আপলোড হয় না। কোনো অ্যাকাউন্ট নেই, কোনো ক্লাউড নেই, আর সবকিছু ইন্টারনেট ছাড়াই চলে।';

  @override
  String get onboardingPrivacy3 =>
      'পরীক্ষার পর রেকর্ডিং মুছে ফেলা হয়, যদি না আপনি সেটিংসে সেগুলো রাখা বাছেন।';

  @override
  String get onboardingHowTitle => 'কীভাবে শব্দ-পরীক্ষা করবেন';

  @override
  String get onboardingHow1 =>
      'ফোনটা বস্তা বা পাত্রের গায়ে চ্যাপ্টা করে রাখুন, মাইক যেন ছুঁয়ে থাকে।';

  @override
  String get onboardingHow2 =>
      'একটা শান্ত ঘর বাছুন। কথা বলা বন্ধ করুন আর পারলে পাখা বন্ধ করুন।';

  @override
  String get onboardingHow3 => 'Kernel যখন শোনে, 2 সেকেন্ড একদম নড়বেন না।';

  @override
  String get onboardingHow4 =>
      'ফলাফল পরীক্ষামূলক। সিদ্ধান্তের আগে সবসময় নিজে শস্য দেখে পরীক্ষা করুন।';

  @override
  String get onboardingRoleTitle => 'আপনার ভূমিকা বাছুন';

  @override
  String get heroEyebrowListen => 'আপনার শস্যের শব্দ শুনুন';

  @override
  String get heroStartScan => 'শব্দ-পরীক্ষা শুরু করুন';

  @override
  String get heroStartBatch => 'একে একে পরীক্ষা শুরু';

  @override
  String get loading => 'খুলছে…';

  @override
  String get farmerHomeTitle => 'কৃষকের পাতা';

  @override
  String farmerHomeHarvestSubtitle(String name) {
    return 'ফসল: $name';
  }

  @override
  String get farmerHeroTitle => 'শস্যের শব্দ-পরীক্ষা';

  @override
  String get farmerHeroSubtitle =>
      'দেখানো নিয়মে 2 সেকেন্ডের রেকর্ডিং শুরু করুন';

  @override
  String get farmerEmptyDetail =>
      'শব্দ-পরীক্ষা আর হিসাব রাখা শুরু করতে একটা বস্তা নথিভুক্ত করুন।';

  @override
  String registeredSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি নথিভুক্ত বস্তা',
      one: '1টি নথিভুক্ত বস্তা',
    );
    return '$_temp0';
  }

  @override
  String get noFollowUps => 'পরের কোনো দেখে পরীক্ষা বাকি নেই';

  @override
  String sacksRequireFollowUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি বস্তার পরে দেখে পরীক্ষা দরকার',
      one: '1টি বস্তার পরে দেখে পরীক্ষা দরকার',
    );
    return '$_temp0';
  }

  @override
  String get harvestsTitle => 'ফসল';

  @override
  String get harvestsEmptyCard =>
      'ফসল তৈরি করুন, যাতে বিক্রির আগের রিপোর্টের জন্য তার বস্তাগুলো একসঙ্গে থাকে';

  @override
  String harvestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ফসল · সবচেয়ে নতুনটা খুলুন',
      one: '1টি ফসল · সবচেয়ে নতুনটা খুলুন',
    );
    return '$_temp0';
  }

  @override
  String get queueTitle => 'পরীক্ষার সারি';

  @override
  String get queueCardSubtitle => 'কোন বস্তাগুলো আগে দেখবেন';

  @override
  String get preSaleCardSubtitle => 'আপনার রাখা রেকর্ড থেকে সারাংশ বানান';

  @override
  String preSaleCardHarvest(String name) {
    return '$name-এর বিক্রির আগের সারাংশ';
  }

  @override
  String get householdHomeTitle => 'বাড়ির মজুত';

  @override
  String get householdHomeSubtitle => 'বাড়ির শস্যের হিসাব';

  @override
  String get householdHeroTitle => 'পাত্রের শব্দ-পরীক্ষা করুন';

  @override
  String get householdHeroSubtitle => 'শস্যের অবস্থা লিখে রাখুন';

  @override
  String get householdEmptyDetail =>
      'কতদিন রাখা আছে দেখতে একটা শস্যের পাত্র যোগ করুন।';

  @override
  String get remindersCardTitle => 'পরীক্ষার রিমাইন্ডার';

  @override
  String get remindersCardEmpty =>
      'কোনো রিমাইন্ডার ঠিক করা নেই। দিতে একটা পাত্র খুলুন।';

  @override
  String remindersScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি রিমাইন্ডার ঠিক করা',
      one: '1টি রিমাইন্ডার ঠিক করা',
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
      other: '$days দিন ধরে রাখা',
      one: '1 দিন ধরে রাখা',
    );
    return '$_temp0';
  }

  @override
  String get reviewNeverScanned =>
      'এখনও শব্দ-পরীক্ষা হয়নি — দেখার সময় হয়েছে';

  @override
  String reviewDueSince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'দেখার সময় হয়েছে — শেষ শব্দ-পরীক্ষা $days দিন আগে',
      one: 'দেখার সময় হয়েছে — শেষ শব্দ-পরীক্ষা 1 দিন আগে',
    );
    return '$_temp0';
  }

  @override
  String reviewNextIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'পরের দেখা $days দিন পরে',
      one: 'পরের দেখা 1 দিন পরে',
    );
    return '$_temp0';
  }

  @override
  String get reviewDue => 'দেখার সময় হয়েছে';

  @override
  String reminderOn(String date) {
    return 'রিমাইন্ডার $date';
  }

  @override
  String get recheckAction => 'আবার দেখুন';

  @override
  String get remindMeAction => 'মনে করিয়ে দিন';

  @override
  String get reminderSheetTitle => 'আবার পরীক্ষার রিমাইন্ডার দিন';

  @override
  String reminderSheetSubtitle(String label) {
    return '$label-এর জন্য। Kernel এই ফোনেই আপনাকে মনে করিয়ে দেবে।';
  }

  @override
  String reminderInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days দিন পরে',
      one: '1 দিন পরে',
    );
    return '$_temp0';
  }

  @override
  String get reminderDateLabel => 'তারিখ';

  @override
  String get reminderTimeLabel => 'সময়';

  @override
  String get reminderOnDeviceNote =>
      'রিমাইন্ডার এই ফোনেই ঠিক করা হয় আর ইন্টারনেট ছাড়াই কাজ করে।';

  @override
  String get reminderSave => 'রিমাইন্ডার সেভ করুন';

  @override
  String get reminderPastError => 'সামনের কোনো সময় বাছুন।';

  @override
  String get reminderSet => 'রিমাইন্ডার দেওয়া হয়েছে';

  @override
  String get reminderSetNotificationsOff =>
      'রিমাইন্ডার সেভ হয়েছে। নোটিফিকেশন বন্ধ, তাই এটা শুধু অ্যাপের ভেতরে দেখা যাবে।';

  @override
  String reminderFailed(String detail) {
    return 'রিমাইন্ডার দেওয়া গেল না: $detail';
  }

  @override
  String get fpoHomeTitle => 'গুদামের এক নজরে';

  @override
  String get fpoHomeSubtitle => 'গুদাম, ঘর আর গাদা';

  @override
  String get fpoEmptyDetail =>
      'বস্তা নথিভুক্ত করুন, তারপর একে একে তাদের শব্দ-পরীক্ষা করে পরীক্ষার সারি বানান।';

  @override
  String sacksScannedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'আজ $countটি বস্তার শব্দ-পরীক্ষা হয়েছে',
      one: 'আজ 1টি বস্তার শব্দ-পরীক্ষা হয়েছে',
    );
    return '$_temp0';
  }

  @override
  String queueSummary(int flagged, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      needScan,
      locale: localeName,
      other: '$needScanটি বস্তার শব্দ-পরীক্ষা বাকি',
      one: '1টি বস্তার শব্দ-পরীক্ষা বাকি',
    );
    return '$flaggedটিতে নজর দিন · $_temp0';
  }

  @override
  String get assignedTitle => 'দায়িত্ব দেওয়া পরীক্ষা';

  @override
  String get assignedNone => 'কোনো খোলা পরীক্ষা নেই';

  @override
  String inspectionsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পরীক্ষা খোলা',
      one: '1টি পরীক্ষা খোলা',
    );
    return '$_temp0';
  }

  @override
  String get fpoAddLocationTitle => 'গুদাম, ঘর বা গাদা যোগ করুন';

  @override
  String get fpoAddLocationSubtitle => 'বস্তা কোথায় রাখা, সেই অনুযায়ী সাজান';

  @override
  String get buyerHomeTitle => 'আসা লট';

  @override
  String get buyerHomeSubtitle => 'কেনার আগে পরীক্ষা';

  @override
  String get heroEyebrowDelivery => 'নতুন চালান';

  @override
  String get buyerHeroTitle => 'চালান নথিভুক্ত করুন';

  @override
  String get buyerHeroSubtitle => 'সরবরাহকারী, লট, শস্য, পরিমাণ';

  @override
  String get buyerHeroAction => 'নথিভুক্ত করুন';

  @override
  String get lotsEmptyMessage => 'এখনও কোনো লট নেই';

  @override
  String get lotsEmptyDetail =>
      'বস্তাগুলো পরীক্ষা করতে একটা চালান নথিভুক্ত করুন।';

  @override
  String get lotsEmptyAction => 'আপনার প্রথম চালান নথিভুক্ত করুন';

  @override
  String get buyerReportCardTitle => 'পরীক্ষার রিপোর্ট';

  @override
  String get buyerReportCardSubtitle =>
      'আপনার রাখা রেকর্ড থেকে লট পরীক্ষার রিপোর্ট বানান';

  @override
  String lotTitle(String code, String grain) {
    return '$code / $grain';
  }

  @override
  String get lotNoSacks => 'এই লটে এখনও কোনো বস্তা নথিভুক্ত হয়নি';

  @override
  String lotScreenedCount(int screened, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalটি বস্তার',
      one: '1টি বস্তার',
    );
    return '$_temp0 মধ্যে $screenedটির পরীক্ষা হয়েছে';
  }

  @override
  String supplierChip(String name) {
    return 'সরবরাহকারী: $name';
  }

  @override
  String get scanAppBarTitle => 'শব্দ-পরীক্ষা';

  @override
  String get guidedScanTitle => 'দেখানো নিয়মে শব্দ-পরীক্ষা';

  @override
  String get researchScanTitle => 'লেবেল দেওয়া নমুনা রেকর্ড করুন';

  @override
  String grainAndLabel(String grain, String label) {
    return '$grain • $label';
  }

  @override
  String get researchScanNoticeTitle => 'গবেষণার রেকর্ডিং';

  @override
  String get researchScanNotice =>
      'এই 2 সেকেন্ডের রেকর্ডিং এই ফোনেই গোপনে রাখা হয়, যাতে আপনি প্রশিক্ষণের ডেটার জন্য লেবেল দিতে পারেন। এটা পোকার ফল হিসেবে দেখানো হয় না আর কখনও আপলোড হয় না।';

  @override
  String positioningTip(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ফোন পাত্রের গায়ে চেপে ধরুন, স্থির আর চুপ থাকুন',
      'other': 'ফোন বস্তার গায়ে চেপে ধরুন, স্থির আর চুপ থাকুন',
    });
    return '$_temp0';
  }

  @override
  String positioningTipDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'শান্ত ঘরে ফোনটা পাত্রের উপর চ্যাপ্টা করে রাখুন, মাইক যেন ছুঁয়ে থাকে। 2 সেকেন্ড কথা বলবেন না আর নাড়াবেন না।',
      'other': 'শান্ত জায়গায় ফোনটা বস্তার উপর চ্যাপ্টা করে রাখুন, মাইক যেন ছুঁয়ে থাকে। 2 সেকেন্ড কথা বলবেন না আর বস্তা নাড়াবেন না।',
    });
    return '$_temp0';
  }

  @override
  String get infoQualityTitle => 'রেকর্ডিংয়ের মান';

  @override
  String get infoQualityBody =>
      'কোনো ফল দেখানোর আগে পেছনের আওয়াজ, ফেটে যাওয়া শব্দ আর নিস্তব্ধতা পরীক্ষা করা হয়।';

  @override
  String get infoDurationTitle => 'রেকর্ডিংয়ের সময়';

  @override
  String get infoDurationShort => '2 সেকেন্ড';

  @override
  String infoDurationRate(String khz) {
    return '$khz kHz-এ 2 সেকেন্ড';
  }

  @override
  String get infoOnDeviceTitle => 'ফোনেই বিশ্লেষণ';

  @override
  String get infoOnDeviceBody => 'আপলোডের দরকার নেই';

  @override
  String infoOnDeviceWithModel(String provenance) {
    return 'আপলোডের দরকার নেই। $provenance';
  }

  @override
  String get micDeniedTitle => 'মাইকের অনুমতি বন্ধ';

  @override
  String get micDeniedSubtitle => 'শস্যের শব্দ শুনতে Kernel-এর মাইক দরকার।';

  @override
  String get micDeniedPrivacy =>
      'শব্দ-পরীক্ষা 2 সেকেন্ডের শব্দ রেকর্ড করে এই ফোনেই পরীক্ষা করে। শব্দ কখনও আপলোড হয় না, আর পরীক্ষার পর মুছে ফেলা হয়, যদি না আপনি সেটিংসে রেকর্ডিং রাখা বাছেন।';

  @override
  String get micDeniedBlocked =>
      'Kernel-এর জন্য মাইক বন্ধ করা আছে। ফোনের সেটিংস খুলুন, অনুমতি বাছুন, তারপর মাইকের অনুমতি দিন।';

  @override
  String get micDeniedAskAgain =>
      'পরের বার Kernel জিজ্ঞেস করলে, বা ফোনের সেটিংসে, অনুমতি দিতে পারেন।';

  @override
  String get micDeniedStillUsable =>
      'মাইক ছাড়াও আপনি জিনিস নথিভুক্ত করতে, মজুত দেখতে, খুলে পরীক্ষা লিখতে আর রিপোর্ট বানাতে পারেন।';

  @override
  String get actionOpenSettings => 'সেটিংস খুলুন';

  @override
  String get actionTryAgain => 'আবার চেষ্টা করুন';

  @override
  String get actionBrowseInventory => 'মজুত দেখুন';

  @override
  String get resultAppBarTitle => 'ফলাফল';

  @override
  String get resultTitle => 'পরীক্ষার ফলাফল';

  @override
  String get scanNotFound => 'এই শব্দ-পরীক্ষা এই ফোনে পাওয়া যায়নি।';

  @override
  String get retryNothingSaved =>
      'এই রেকর্ডিংয়ের জন্য পোকা নিয়ে কিছুই সেভ হয়নি।';

  @override
  String predictedClassLine(String label) {
    return 'মডেলের অনুমান (যাচাই হয়নি): $label';
  }

  @override
  String modelScoreLine(String score) {
    return 'মডেলের স্কোর: $score (পরীক্ষামূলক, এটা নির্ভুলতার হিসাব নয়)';
  }

  @override
  String get modelNoteTitleExperimental => 'পরীক্ষামূলক মডেল — প্রমাণিত নয়';

  @override
  String get modelNoteTitle => 'এই মডেল সম্পর্কে';

  @override
  String modelNoteOtherVersion(String version) {
    return 'এই শব্দ-পরীক্ষায় মডেল $version ব্যবহার হয়েছিল, যা এখন আর ফোনে নেই। এর তথ্য শব্দ-পরীক্ষার সঙ্গে রাখা হয়নি, তাই ফলটাকে পরীক্ষামূলক বলেই ধরুন।';
  }

  @override
  String get physicalInspectionNote =>
      'শব্দ দিয়ে পরীক্ষা পরীক্ষামূলক। মজুত বা বিক্রির যেকোনো সিদ্ধান্তের আগে নিজে দেখে পরীক্ষা করা জরুরি।';

  @override
  String get actionRetry => 'আবার করুন';

  @override
  String get actionRecordInspection => 'দেখে পরীক্ষা লিখে রাখুন';

  @override
  String get actionScanAnother => 'আরেকটা শব্দ-পরীক্ষা';

  @override
  String get recordingDetails => 'রেকর্ডিংয়ের বিস্তারিত';

  @override
  String get fieldCaptured => 'রেকর্ড হয়েছে';

  @override
  String get fieldDuration => 'সময়';

  @override
  String get fieldSampleRate => 'স্যাম্পল রেট';

  @override
  String get fieldAnalysisTime => 'বিশ্লেষণের সময়';

  @override
  String get fieldDevice => 'ফোন';

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
      'container': 'কোন পাত্রের শব্দ শুনবেন বাছুন',
      'other': 'কোন বস্তার শব্দ শুনবেন বাছুন',
    });
    return '$_temp0';
  }

  @override
  String get batchScanTitle => 'একে একে শব্দ-পরীক্ষা';

  @override
  String get batchScanSubtitle => 'বস্তাগুলোর একে একে শব্দ-পরীক্ষা করুন';

  @override
  String get qrCardTitle => 'QR লেবেল থেকে খুলুন';

  @override
  String qrCardSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'সেই পাত্র খুলতে Kernel লেবেলের দিকে ক্যামেরা ধরুন',
      'other': 'সেই বস্তা খুলতে Kernel বস্তার লেবেলের দিকে ক্যামেরা ধরুন',
    });
    return '$_temp0';
  }

  @override
  String get oneAtATimeTitle => 'একবারে একটা';

  @override
  String get oneAtATimeBody =>
      'প্রতিটি রেকর্ডিং একটাই জিনিসের। জিনিসগুলোর একটার পর একটা শব্দ-পরীক্ষা করুন; একটা শব্দ-পরীক্ষা কখনও একসঙ্গে অনেক জিনিস দেখে না।';

  @override
  String emptyItemsMessage(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'এখনও কোনো পাত্র নেই',
      'other': 'এখনও কোনো বস্তা নেই',
    });
    return '$_temp0';
  }

  @override
  String emptyItemsAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'আপনার প্রথম পাত্র যোগ করুন',
      'other': 'আপনার প্রথম বস্তা নথিভুক্ত করুন',
    });
    return '$_temp0';
  }

  @override
  String get scanTabEmptyDetail =>
      'আগে একটা নথিভুক্ত করুন, তারপর শব্দ-পরীক্ষা করতে ফিরে আসুন।';

  @override
  String get scansTodayTitle => 'আজকের শব্দ-পরীক্ষা';

  @override
  String scansTodaySummary(int scans, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$itemsটি জিনিসের',
      one: '1টি জিনিসের',
    );
    String _temp1 = intl.Intl.pluralLogic(
      scans,
      locale: localeName,
      other: '$scansটি শব্দ-পরীক্ষা',
      one: '1টি শব্দ-পরীক্ষা',
    );
    return 'মাঝরাত থেকে $_temp0 $_temp1';
  }

  @override
  String get scansTodayEmpty =>
      'আজ এখনও কোনো শব্দ-পরীক্ষা হয়নি। আপনার রেকর্ড করা শব্দ-পরীক্ষা সঙ্গে সঙ্গে এখানে দেখা যাবে।';

  @override
  String get experimentalBadge => 'পরীক্ষামূলক';

  @override
  String get errorCouldNotLoad => 'খোলা গেল না';

  @override
  String errorWithDetail(String prefix, String detail) {
    return '$prefix: $detail';
  }

  @override
  String fieldLabel(String label) {
    return '$label:';
  }

  @override
  String get validationQuantityEmpty => 'পরিমাণ লিখুন';

  @override
  String get validationQuantityPositive => '0-এর বেশি একটা সংখ্যা লিখুন';

  @override
  String get actionCancel => 'বাতিল';

  @override
  String get actionSave => 'সেভ করুন';

  @override
  String get offlineLabel => 'অফলাইন';

  @override
  String get onlineLabel => 'অনলাইন';

  @override
  String get offlineSemantics => 'অফলাইন। এই ফোনে সবকিছু চলতে থাকে।';

  @override
  String get onlineSemantics => 'অনলাইন। Kernel-এর ইন্টারনেট লাগে না।';

  @override
  String get qrTooltip => 'QR লেবেল থেকে বস্তা খুলুন';

  @override
  String get menuTooltip => 'মেনু';

  @override
  String get menuSwitchRole => 'ভূমিকা বদলান';

  @override
  String get menuSettings => 'সেটিংস';

  @override
  String itemTileSubtitle(String grain, String quantity, String date) {
    return '$grain · $quantity · রাখা $date';
  }

  @override
  String get archivedBadge => 'সরিয়ে রাখা';

  @override
  String get chipRetryNeeded => 'আবার করতে হবে';

  @override
  String chipAiUnverified(String label) {
    return 'AI: $label (যাচাই হয়নি)';
  }

  @override
  String scanTileTitle(String item, String when) {
    return '$item · $when';
  }

  @override
  String qualityChip(String quality) {
    return 'মান: $quality';
  }

  @override
  String get chipAudioKept => 'শব্দ ফোনে রাখা আছে';

  @override
  String photoSemantics(int number) {
    return 'প্রমাণের ছবি $number। পুরো বড় করে খোলে।';
  }

  @override
  String get photoMissing => 'এই ছবি আর এই ফোনে নেই।';

  @override
  String get photoRemove => 'ছবি সরান';

  @override
  String verifiedFindingLine(String finding) {
    return 'যাচাই করা ফল: $finding';
  }

  @override
  String inspectorLine(String inspector, String when) {
    return '$inspector · $when';
  }

  @override
  String followUpChip(String status) {
    return 'পরের পরীক্ষা: $status';
  }

  @override
  String get unassigned => 'কাউকে দায়িত্ব দেওয়া হয়নি';

  @override
  String assignedToChip(String name) {
    return 'দায়িত্বে $name';
  }

  @override
  String get followUpChangeTooltip => 'পরের পরীক্ষার অবস্থা বদলান';

  @override
  String get followUpUpdate => 'অবস্থা বদলান';

  @override
  String get assignAction => 'দায়িত্ব দিন';

  @override
  String get archiveAction => 'সরিয়ে রাখুন';

  @override
  String archiveConfirmTitle(String name) {
    return '$name সরিয়ে রাখবেন?';
  }

  @override
  String get archiveConfirmItemBody =>
      'এটা তালিকা, সারি আর নতুন রিপোর্টে দেখা যাবে না। এর শব্দ-পরীক্ষার ইতিহাস আর দেখে পরীক্ষা এই ফোনে থেকে যাবে, মোছা হবে না।';

  @override
  String get archiveConfirmLotBody =>
      'লটটা আপনার তালিকা আর নতুন রিপোর্টে দেখা যাবে না। এর বস্তা, তাদের শব্দ-পরীক্ষার ইতিহাস আর দেখে পরীক্ষা এই ফোনে থেকে যাবে।';

  @override
  String get archiveConfirmLocationBody =>
      'জায়গাটা তালিকা আর বাছাইয়ের ঘরে দেখা যাবে না। সেখানে রাখা বস্তা, তাদের শব্দ-পরীক্ষার ইতিহাস আর দেখে পরীক্ষা এই ফোনে থেকে যাবে।';

  @override
  String get archiveConfirmHarvestBody =>
      'ফসলটা আপনার তালিকা আর নতুন রিপোর্টে দেখা যাবে না। এর বস্তা, তাদের শব্দ-পরীক্ষার ইতিহাস আর দেখে পরীক্ষা এই ফোনে থেকে যাবে।';

  @override
  String get levelMeterLabel => 'মাইকের শব্দের মাত্রা';

  @override
  String get levelMeterWaiting => 'শব্দের অপেক্ষায়';

  @override
  String levelMeterValue(int dbfs) {
    return '$dbfs dBFS';
  }

  @override
  String get voicePlacePhone => 'ফোন বস্তার উপর রাখুন';

  @override
  String get voiceListening => 'শুনছি';

  @override
  String get voiceDone => 'হয়ে গেছে';

  @override
  String scanCouldNotRun(String detail) {
    return 'শব্দ-পরীক্ষা চালানো গেল না: $detail';
  }

  @override
  String scanCouldNotSave(String detail) {
    return 'শব্দ-পরীক্ষার ফল সেভ করা গেল না, তাই কিছুই রাখা হয়নি। বিস্তারিত: $detail';
  }

  @override
  String get captureReady => 'শোনার জন্য তৈরি';

  @override
  String get captureListening => 'শুনছি — স্থির থাকুন';

  @override
  String get captureSaving => 'এই ফোনে সেভ হচ্ছে';

  @override
  String get captureCheckingMic => 'মাইকের অনুমতি দেখা হচ্ছে';

  @override
  String get captureGetReady => 'তৈরি হন — ফোন রাখুন';

  @override
  String captureSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ফোন পাত্রের গায়ে চেপে ধরুন',
      'other': 'ফোন বস্তার গায়ে চেপে ধরুন',
    });
    return '$_temp0';
  }

  @override
  String get captureResearchSubtitle =>
      'গবেষণার রেকর্ডিং: এই 2 সেকেন্ড লেবেল দেওয়ার জন্য এই ফোনেই গোপনে রাখা হয়';

  @override
  String get captureStart => '2 সেকেন্ডের রেকর্ডিং শুরু করুন';

  @override
  String get captureStartAgain => '2 সেকেন্ডের রেকর্ডিং আবার করুন';

  @override
  String get captureStartResearch =>
      'লেবেল দেওয়া নমুনা রেকর্ড করুন (2 সেকেন্ড)';

  @override
  String get captureProgressLabel => 'রেকর্ডিং কতটা হল';

  @override
  String percentValue(int percent) {
    return '$percent শতাংশ';
  }

  @override
  String captureElapsed(String elapsed, String target) {
    return '$target সেকেন্ডের মধ্যে $elapsed সেকেন্ড';
  }

  @override
  String get captureChecking => 'এই ফোনে রেকর্ডিং পরীক্ষা হচ্ছে…';

  @override
  String get hintWaiting => 'শুনছি…';

  @override
  String get hintTooQuiet => 'খুব আস্তে — আরও চেপে ধরুন';

  @override
  String get hintTooLoud => 'খুব জোরে / ঘষার শব্দ';

  @override
  String get hintHoldStill => 'স্থির থাকুন';

  @override
  String get appTitle => 'Kernel';

  @override
  String get roleFarmer => 'কৃষক';

  @override
  String get roleHousehold => 'বাড়ি';

  @override
  String get roleStorageFpo => 'মজুত/FPO';

  @override
  String get roleBuyer => 'ক্রেতা';

  @override
  String get roleFarmerTagline => 'ফসল আর বিক্রির আগের পরীক্ষা';

  @override
  String get roleHouseholdTagline => 'পাত্র আর রিমাইন্ডার';

  @override
  String get roleStorageFpoTagline => 'গুদাম আর একে একে পরীক্ষা';

  @override
  String get roleBuyerTagline => 'সরবরাহকারী আর লটের পরীক্ষা';

  @override
  String get navHome => 'হোম';

  @override
  String get navScan => 'শব্দ-পরীক্ষা';

  @override
  String get navInventory => 'মজুত';

  @override
  String get navReports => 'রিপোর্ট';

  @override
  String get navInventoryFarmer => 'আমার শস্য';

  @override
  String get navInventoryHousehold => 'আমার পাত্র';

  @override
  String get navInventoryFpo => 'গুদাম';

  @override
  String get navInventoryBuyer => 'লট';

  @override
  String get reportTitleFarmer => 'বিক্রির আগের রিপোর্ট';

  @override
  String get reportTitleHousehold => 'মজুতের রিপোর্ট';

  @override
  String get reportTitleFpo => 'গুদামের রিপোর্ট';

  @override
  String get reportTitleBuyer => 'লট পরীক্ষার রিপোর্ট';

  @override
  String get locationTypeHome => 'বাড়ি';

  @override
  String get locationTypeContainer => 'পাত্র';

  @override
  String get locationTypeWarehouse => 'গুদাম';

  @override
  String get locationTypeRoom => 'ঘর';

  @override
  String get locationTypeStack => 'গাদা';

  @override
  String get screeningPending => 'বাকি';

  @override
  String get screeningScreening => 'পরীক্ষা চলছে';

  @override
  String get screeningNeedsPhysicalCheck => 'খুলে পরীক্ষা বাকি';

  @override
  String get screeningReviewed => 'দেখা হয়েছে';

  @override
  String get findingNoneFound => 'কিছু পাওয়া যায়নি';

  @override
  String get findingPestsFound => 'পোকা পাওয়া গেছে';

  @override
  String get findingInconclusive => 'বোঝা যায়নি';

  @override
  String get findingNoneFoundHelp =>
      'আমি দেখেছি, কোনো পোকা বা ক্ষতি চোখে পড়েনি';

  @override
  String get findingPestsFoundHelp => 'আমি পোকা, লার্ভা, জাল বা ক্ষতি দেখেছি';

  @override
  String get findingInconclusiveHelp => 'দেখে আমি বুঝতে পারিনি';

  @override
  String get followUpOpen => 'খোলা';

  @override
  String get followUpInProgress => 'চলছে';

  @override
  String get followUpDone => 'হয়ে গেছে';

  @override
  String get reminderScheduled => 'ঠিক করা আছে';

  @override
  String get reminderFired => 'এখনই সময়';

  @override
  String get reminderDone => 'হয়ে গেছে';

  @override
  String get reminderCancelled => 'বাতিল';

  @override
  String get reasonSilence =>
      'খুব আস্তে: মাইকে প্রায় কোনো শব্দই পৌঁছায়নি। ফোনটা শস্যের গায়ে জোরে চেপে ধরুন।';

  @override
  String get reasonClipping =>
      'খুব জোরে: শব্দ ফেটে গেছে। রেকর্ডিংয়ের সময় টোকা, ঘষা বা ঠোকা দেবেন না।';

  @override
  String get reasonHighNoise =>
      'পেছনে খুব আওয়াজ। কোনো শান্ত জায়গায় যান আর স্থির থাকুন।';

  @override
  String get reasonTooShort =>
      'রেকর্ডিং খুব ছোট হয়েছে। পুরো 2 সেকেন্ড ফোন স্থির রাখুন।';

  @override
  String get reasonPermissionDenied =>
      'মাইকের অনুমতি বন্ধ। শব্দ-পরীক্ষা করতে ফোনের সেটিংসে অনুমতি দিন।';

  @override
  String get reasonCaptureError =>
      'মাইক রেকর্ড করতে পারেনি। মাইক ব্যবহার করা অন্য অ্যাপ বন্ধ করে আবার চেষ্টা করুন।';

  @override
  String get qualityPass => 'কাজের';

  @override
  String get qualityRetry => 'আবার করুন';

  @override
  String get predictionClean => 'কোনো সংকেত পাওয়া যায়নি';

  @override
  String get predictionUncertain => 'নিশ্চিত নয়';

  @override
  String get predictionInfested => 'পোকা লাগার সম্ভাবনা';

  @override
  String get predictionNotEvaluated => 'ফল তৈরি হয়নি';

  @override
  String get sampleLabelClean => 'কোনো চিহ্ন নেই';

  @override
  String get sampleLabelInfested => 'পোকা লেগেছে';

  @override
  String get sampleLabelUnknown => 'জানা নেই';

  @override
  String get headlineRetry => 'রেকর্ডিং কাজে লাগার মতো নয় — আবার চেষ্টা করুন';

  @override
  String get headlineNotEvaluated =>
      'ফল তৈরি হয়নি — কোনো মডেল বসানো নেই। নিজে দেখে পরীক্ষা করুন।';

  @override
  String get headlineNotEvaluatedWithModel =>
      'ফল তৈরি হয়নি — মডেল এই রেকর্ডিং বিশ্লেষণ করতে পারেনি। নিজে দেখে পরীক্ষা করুন।';

  @override
  String get headlineInspectionNeeded =>
      'দেখে পরীক্ষা দরকার — মডেলের ফল যাচাই করা নয়';

  @override
  String get headlineClean =>
      'কোনো সংকেত পাওয়া যায়নি — এটা কোনো গ্যারান্টি নয়; বিক্রি/মজুতের সিদ্ধান্তের আগে নিজে দেখে পরীক্ষা করুন';

  @override
  String get provenanceNone => 'মডেল: নেই — ফল তৈরি হয়নি';

  @override
  String provenanceExperimental(String version) {
    return 'মডেল $version — পরীক্ষামূলক';
  }

  @override
  String provenanceValidated(String version) {
    return 'মডেল $version — প্রমাণিত';
  }

  @override
  String dateTimeJoin(String date, String time) {
    return '$date, $time';
  }

  @override
  String get nextStepEyebrow => 'পরের ধাপ';

  @override
  String get nextNothingPending =>
      'এখন জরুরি কিছু নেই। খোঁজ রাখতে নিয়মিত শব্দ-পরীক্ষা করুন।';

  @override
  String get quickScanAction => 'এখনই শব্দ-পরীক্ষা';

  @override
  String scansTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'আজ $countটি শব্দ-পরীক্ষা',
      one: 'আজ 1টি শব্দ-পরীক্ষা',
      zero: 'আজ কোনো শব্দ-পরীক্ষা হয়নি',
    );
    return '$_temp0';
  }

  @override
  String scanActivityLine(int today, int week) {
    return 'শব্দ-পরীক্ষা: আজ $today · গত 7 দিনে $week';
  }

  @override
  String nextRegisterFirst(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'আপনার প্রথম পাত্র নথিভুক্ত করুন',
      'other': 'আপনার প্রথম বস্তা নথিভুক্ত করুন',
    });
    return '$_temp0';
  }

  @override
  String get nextRegisterFirstBody =>
      'নাম, শস্য আর পরিমাণ লিখুন। এক মিনিট লাগে।';

  @override
  String get nextRegisterFirstLot => 'আপনার প্রথম চালান নথিভুক্ত করুন';

  @override
  String get nextRegisterFirstLotBody => 'সরবরাহকারী, লট, শস্য আর পরিমাণ।';

  @override
  String nextScanOne(String label) {
    return '$label-এর শব্দ-পরীক্ষা করুন';
  }

  @override
  String nextScanSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি বস্তার শব্দ-পরীক্ষা বাকি',
      one: '1টি বস্তার শব্দ-পরীক্ষা বাকি',
    );
    return '$_temp0';
  }

  @override
  String nextScanContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পাত্রের শব্দ-পরীক্ষা বাকি',
      one: '1টি পাত্রের শব্দ-পরীক্ষা বাকি',
    );
    return '$_temp0';
  }

  @override
  String nextScanBody(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ফোনটা পাত্রের গায়ে চেপে 2 সেকেন্ডের শোনার পরীক্ষা।',
      'other': '2 সেকেন্ডের শোনার পরীক্ষা, একবারে একটি বস্তা।',
    });
    return '$_temp0';
  }

  @override
  String nextInspectOne(String label) {
    return '$label দেখে পরীক্ষা করুন';
  }

  @override
  String nextInspectSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'চিহ্নিত $countটি বস্তা দেখে পরীক্ষা করুন',
      one: 'চিহ্নিত 1টি বস্তা দেখে পরীক্ষা করুন',
    );
    return '$_temp0';
  }

  @override
  String nextInspectContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'চিহ্নিত $countটি পাত্র দেখে পরীক্ষা করুন',
      one: 'চিহ্নিত 1টি পাত্র দেখে পরীক্ষা করুন',
    );
    return '$_temp0';
  }

  @override
  String get nextInspectBody =>
      'মডেলের ফল যাচাই করা নয়। শস্য হাতে নিয়ে পরীক্ষা করুন।';

  @override
  String nextReviewOne(String label) {
    return '$label: আবার দেখার সময়';
  }

  @override
  String nextReviewSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি বস্তা আবার দেখার সময়',
      one: '1টি বস্তা আবার দেখার সময়',
    );
    return '$_temp0';
  }

  @override
  String nextReviewContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পাত্র আবার দেখার সময়',
      one: '1টি পাত্র আবার দেখার সময়',
    );
    return '$_temp0';
  }

  @override
  String get nextReviewBody =>
      'শেষ পরীক্ষার পর অনেকদিন হয়ে গেছে। আবার শুনুন বা দেখে পরীক্ষা করুন।';

  @override
  String nextReminderOne(String label) {
    return '$label: রিমাইন্ডারের সময়';
  }

  @override
  String nextReminderMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি রিমাইন্ডারের সময়',
      one: '1টি রিমাইন্ডারের সময়',
    );
    return '$_temp0';
  }

  @override
  String get nextReminderBody =>
      'আপনার ঠিক করা আবার-পরীক্ষার সময় হয়েছে। এই শস্যটা দেখুন।';

  @override
  String nextPhysicalOne(String label) {
    return 'লট $label: দেখে পরীক্ষা বাকি';
  }

  @override
  String nextPhysicalMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি লটের দেখে পরীক্ষা বাকি',
      one: '1টি লটের দেখে পরীক্ষা বাকি',
    );
    return '$_temp0';
  }

  @override
  String get nextPhysicalBody =>
      'লটটা খুলে মানুষ যা দেখেছেন তা লিখে রাখুন। Kernel কখনও কোনো লট গ্রহণ বা বাতিল করে না।';

  @override
  String get nextFinishBatch => 'একে একে পরীক্ষা শেষ করুন';

  @override
  String nextFinishBatchOne(String label) {
    return 'একে একে পরীক্ষা শেষ করুন: $label';
  }

  @override
  String nextFinishBatchBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি বস্তা বাকি, একবারে একটি',
      one: '1টি বস্তা বাকি, একবারে একটি',
      zero: 'এই দলের সব বস্তার শব্দ-পরীক্ষা হয়ে গেছে',
    );
    return '$_temp0';
  }

  @override
  String get nextPreSale => 'বিক্রির আগের রিপোর্ট পাঠান';

  @override
  String nextPreSaleOne(String label) {
    return '$label-এর বিক্রির আগের রিপোর্ট পাঠান';
  }

  @override
  String get nextLotSummary => 'লটের সারসংক্ষেপ পাঠান';

  @override
  String nextLotSummaryOne(String label) {
    return '$label-এর লট সারসংক্ষেপ পাঠান';
  }

  @override
  String get nextExportBody =>
      'আপনার রেকর্ড থেকে এই ফোনেই তৈরি। কাকে পাঠাবেন, আপনি ঠিক করুন।';

  @override
  String get nextActionRegister => 'নথিভুক্ত করুন';

  @override
  String get nextActionScan => 'শব্দ-পরীক্ষা শুরু';

  @override
  String get nextActionBatch => 'একে একে পরীক্ষা শুরু';

  @override
  String get nextActionOpen => 'খুলুন';

  @override
  String get nextActionQueue => 'পরীক্ষার সারি খুলুন';

  @override
  String get nextActionOpenLot => 'লট খুলুন';

  @override
  String get nextActionContinueBatch => 'একে একে পরীক্ষা চালিয়ে যান';

  @override
  String get nextActionReport => 'রিপোর্ট খুলুন';

  @override
  String get insightsTitle => 'তথ্য';

  @override
  String get insightsSubtitle => 'আপনার নিজের রেকর্ড থেকে এই ফোনেই হিসাব করা';

  @override
  String get insightsCardSubtitle =>
      'ফল, রেকর্ডিংয়ের সমস্যা আর কী পরীক্ষা দরকার';

  @override
  String get insightsWindowLabel => 'সময়কাল';

  @override
  String get insightsWindow7 => '7 দিন';

  @override
  String get insightsWindow30 => '30 দিন';

  @override
  String get insightsWindowAll => 'সব সময়';

  @override
  String get insightsActivityTitle => 'শব্দ-পরীক্ষার কাজ';

  @override
  String get insightsScansToday => 'আজকের শব্দ-পরীক্ষা';

  @override
  String get insightsScans7 => 'গত 7 দিনের শব্দ-পরীক্ষা';

  @override
  String get insightsRatesTitle => 'ফল';

  @override
  String get insightsRatesEmpty => 'এই সময়ে কোনো শব্দ-পরীক্ষা নেই';

  @override
  String get insightsRatesEmptyDetail =>
      'এখানে ফল দেখতে কোনো বস্তা বা পাত্রের শব্দ-পরীক্ষা করুন।';

  @override
  String get insightsExperimentalNote =>
      'পরীক্ষামূলক মডেল: এই ফলগুলো যাচাই করা নয় এবং ভুল হতে পারে। মজুত বা বিক্রির যেকোনো সিদ্ধান্তের আগে নিজে দেখে পরীক্ষা করুন।';

  @override
  String get insightsNoModelResults =>
      'এখনও মডেলের কোনো ফল নেই: কোনো কাজের রেকর্ডিং মডেল দিয়ে যাচাই হয়নি।';

  @override
  String get insightsRetryLabel => 'রেকর্ডিং কাজের নয় (আবার করুন)';

  @override
  String insightsBarValue(int count, int percent) {
    return '$count · $percent%';
  }

  @override
  String insightsTotalScans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'এই সময়ে $countটি শব্দ-পরীক্ষা',
      one: 'এই সময়ে 1টি শব্দ-পরীক্ষা',
    );
    return '$_temp0';
  }

  @override
  String get insightsQualityTitle => 'রেকর্ডিংয়ের সমস্যা';

  @override
  String get insightsQualityEmpty => 'এই সময়ে কোনো অকেজো রেকর্ডিং নেই';

  @override
  String get insightsQualityHint =>
      'শান্ত জায়গায় ফোনটা বস্তার গায়ে জোরে চেপে ধরলে বেশিরভাগ সমস্যা মিটে যায়।';

  @override
  String get insightsInspectionsTitle => 'দেখে পরীক্ষা';

  @override
  String get insightsInspectionsEmpty => 'এখনও কোনো পরীক্ষা লেখা হয়নি';

  @override
  String insightsClosureRate(int percent) {
    return '$percent% পরীক্ষা শেষ হয়েছে';
  }

  @override
  String get insightsStaleTitle => 'সবচেয়ে বেশিদিন পরীক্ষা হয়নি';

  @override
  String get staleNeverScanned => 'কখনও শব্দ-পরীক্ষা হয়নি';

  @override
  String get qualityShortSilence => 'খুব আস্তে';

  @override
  String get qualityShortClipping => 'খুব জোরে (শব্দ ফেটে গেছে)';

  @override
  String get qualityShortHighNoise => 'খুব গোলমাল';

  @override
  String get qualityShortTooShort => 'খুব ছোট';

  @override
  String get qualityShortPermissionDenied => 'মাইক বন্ধ';

  @override
  String get qualityShortCaptureError => 'রেকর্ডিংয়ে গোলমাল';

  @override
  String get queueFilterResult => 'মডেলের ফল';

  @override
  String get queueFilterAllResults => 'সব ফল';

  @override
  String get queueFilterPlace => 'জায়গা';

  @override
  String get queueFilterAllPlaces => 'সব জায়গা';

  @override
  String get queueFilterAge => 'শেষ কাজের শব্দ-পরীক্ষা';

  @override
  String get queueFilterAnyAge => 'যেকোনো সময়';

  @override
  String queueFilterWithinDays(int days) {
    return '$days দিনের মধ্যে';
  }

  @override
  String queueFilterAgeNote(int days) {
    return 'যেগুলোর শেষ কাজের শব্দ-পরীক্ষা $days দিনের বেশি পুরনো, সেগুলো \"শব্দ-পরীক্ষা বাকি\"-তে চলে যায়।';
  }

  @override
  String get queueNoMatch => 'এই ছাঁকনিতে কিছু মেলেনি।';

  @override
  String get rankReasonInfested =>
      'কেন এখানে: পোকা লাগার সম্ভাবনা (যাচাই করা নয়)';

  @override
  String get rankReasonUncertain => 'কেন এখানে: মডেল নিশ্চিত ছিল না';

  @override
  String get rankReasonClean =>
      'কেন নিচে: কোনো সংকেত পাওয়া যায়নি (গ্যারান্টি নয়)';

  @override
  String scannedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days দিন আগে শব্দ-পরীক্ষা হয়েছে',
      one: '1 দিন আগে শব্দ-পরীক্ষা হয়েছে',
      zero: 'আজ শব্দ-পরীক্ষা হয়েছে',
    );
    return '$_temp0';
  }

  @override
  String get reminderSuggestedLabel => 'পরামর্শ — বেছে নেবেন আপনি';

  @override
  String reminderSuggestedOther(String date) {
    return 'পরামর্শ: $date — বেছে নেবেন আপনি';
  }

  @override
  String get reminderWordingTitle => 'পরামর্শ দেওয়া কথা';

  @override
  String get settingsAdviceSection => 'ফোনেই AI সহায়ক (পরীক্ষামূলক)';

  @override
  String get adviceToggle => 'ফোনের AI সহায়ক ব্যবহার করুন';

  @override
  String get adviceToggleBody =>
      'শুরুতে বন্ধ থাকে। এটি শুধু এই ফোনেই চলে এবং আপনার রেকর্ডিং কখনও শোনে না; শুধু ফল আর তারিখ দেখে। এটি ভুল হতে পারে। যেকোনো সময় বন্ধ করতে পারেন।';

  @override
  String get adviceStatusTitle => 'সহায়কের অবস্থা';

  @override
  String get adviceStatusOff => 'বন্ধ';

  @override
  String get adviceStatusNoModel => 'চালু — এখনও কোনো মডেল আনা হয়নি';

  @override
  String get adviceStatusLoading => 'মডেল খুলছে…';

  @override
  String get adviceStatusReady => 'এই ফোনে তৈরি';

  @override
  String get adviceStatusBusy => 'লিখছে';

  @override
  String get adviceStatusFailed =>
      'মডেল খোলা গেল না — Kernel তার সাধারণ লেখা দেখায়';

  @override
  String get adviceModelTitle => 'সহায়কের মডেল';

  @override
  String get adviceModelNone => 'এখনও কোনো মডেল আনা হয়নি';

  @override
  String get adviceModelId => 'মডেল';

  @override
  String get adviceModelVersion => 'সংস্করণ';

  @override
  String get adviceModelSize => 'আকার';

  @override
  String get adviceModelBackend => 'কীসে চলে';

  @override
  String get adviceBackendGpu => 'ফোনের গ্রাফিক্স চিপ (GPU)';

  @override
  String get adviceBackendCpu => 'ফোনের প্রসেসর (CPU)';

  @override
  String get adviceBackendNone => 'এখনও খোলা হয়নি';

  @override
  String get adviceImportAction => 'মডেল আনুন';

  @override
  String get adviceImporting => 'মডেল আনা হচ্ছে';

  @override
  String adviceImportCopying(String copied, String total) {
    return '$total-এর মধ্যে $copied কপি হয়েছে';
  }

  @override
  String adviceImportCopied(String copied) {
    return '$copied কপি হয়েছে';
  }

  @override
  String get adviceImportVerifying => 'মডেল ফাইল যাচাই হচ্ছে…';

  @override
  String get adviceImportDone => 'মডেল এসে গেছে। এটি এই ফোনেই থাকে।';

  @override
  String adviceImportFailed(String detail) {
    return 'মডেল আনা গেল না: $detail';
  }

  @override
  String adviceImportNoSpace(String needed, String free) {
    return 'জায়গা কম: মডেলের $needed দরকার, কিন্তু এই ফোনে মাত্র $free খালি আছে।';
  }

  @override
  String get adviceDeleteAction => 'মডেল মুছুন';

  @override
  String get adviceDeleteConfirmTitle => 'সহায়কের মডেল মুছবেন?';

  @override
  String get adviceDeleteConfirmBody =>
      'এতে মডেল ফাইলটা এই ফোন থেকে মুছে যাবে। আপনার রেকর্ডে কোনো প্রভাব পড়বে না। পরে আবার আনতে পারবেন।';

  @override
  String adviceDeleteFailed(String detail) {
    return 'মডেল মোছা গেল না: $detail';
  }

  @override
  String get adviceHelp =>
      'Google AI Edge Gallery দিয়ে বা Hugging Face litert-community/gemma-4-E2B-it-litert-lm থেকে একটি .litertlm মডেল নিন (Gemma-র শর্ত প্রযোজ্য), তারপর এখানে আনুন।';

  @override
  String adviceProvenance(String modelVersion) {
    return 'এই ফোনেই তৈরি — পরীক্ষামূলক · $modelVersion';
  }

  @override
  String get adviceNotDecision =>
      'এটি কোনো সিদ্ধান্ত নয় — নিজে দেখে পরীক্ষা করুন';

  @override
  String get adviceGenerating => 'এই ফোনেই লেখা হচ্ছে…';

  @override
  String get adviceExplainAction => 'এই ফলটা বুঝিয়ে দিন';

  @override
  String get adviceExplainTitle => 'এই ফলের মানে';

  @override
  String get adviceStaticRetry =>
      'রেকর্ডিং কাজে লাগেনি, তাই কোনো ফল রাখা হয়নি। ফোনটা বস্তা বা পাত্রের গায়ে জোরে চেপে ধরুন, নড়বেন না, চুপ থাকুন, তারপর আবার রেকর্ড করুন।';

  @override
  String get adviceStaticNotEvaluated =>
      'এই রেকর্ডিং থেকে কোনো ফল তৈরি হয়নি, তাই এটি পোকা নিয়ে কিছুই বলে না। শস্য নিজে দেখে পরীক্ষা করুন।';

  @override
  String get adviceStaticInspection =>
      'পরীক্ষামূলক মডেল এমন কিছু শুনেছে যাতে নজর দেওয়া দরকার হতে পারে। এটি যাচাই করা নয়। যেকোনো সিদ্ধান্তের আগে শস্য নিজে দেখে পরীক্ষা করুন।';

  @override
  String get adviceStaticClean =>
      'পরীক্ষামূলক মডেল কোনো সংকেত পায়নি। এটি গ্যারান্টি নয়। মজুত বা বিক্রির সিদ্ধান্তের আগে শস্য নিজে দেখে পরীক্ষা করুন।';

  @override
  String get reportAiSummaryToggle => 'AI-এর লেখা সারসংক্ষেপ যোগ করুন';

  @override
  String get reportAiSummaryBody =>
      'রিপোর্টের সংখ্যা থেকে এই ফোনেই লেখা। আগে আপনি দেখবেন, তারপর যোগ করবেন কিনা ঠিক করবেন। পরীক্ষামূলক।';

  @override
  String get reportAiPreviewTitle => 'AI-এর লেখা সারসংক্ষেপ';

  @override
  String get reportAiPreviewBody =>
      'যোগ করলে এটি রিপোর্টে আলাদা, নাম দেওয়া অংশে থাকবে — আপনার রেকর্ড আর পরীক্ষার ফল থেকে আলাদা। এটি বদলানো যায় না।';

  @override
  String get reportAiSummaryTitle => 'সারসংক্ষেপের খসড়া';

  @override
  String get reportAiInclude => 'যোগ করুন';

  @override
  String get reportAiSkip => 'বাদ দিন';

  @override
  String unitGb(String value) {
    return '$value GB';
  }

  @override
  String unitMb(String value) {
    return '$value MB';
  }

  @override
  String get hubTitle => 'মডেল হাব';

  @override
  String get hubSubtitle =>
      'পোকা চেনার জন্য ফোনে চলা মডেল। এগুলো শুধু এই ফোনেই চলে।';

  @override
  String get hubNeedsTitle => 'পোকা চেনার জন্য দরকার';

  @override
  String get hubNeedImage => 'ছবি বোঝা';

  @override
  String get hubNeedEmbeddings => 'এমবেডিং (খোঁজার জন্য)';

  @override
  String get hubNeedSound => 'শব্দ চেনার মডেল';

  @override
  String get hubInstalledChip => 'বসানো আছে';

  @override
  String get hubMissingChip => 'নেই';

  @override
  String get hubAllInstalled => 'পোকা চেনার জন্য যা যা দরকার সব এই ফোনে আছে।';

  @override
  String get hubNothingToDownload =>
      'যে অংশগুলো নেই, সেগুলোর জন্য এখনও কোনো ডাউনলোড পাওয়া যাচ্ছে না।';

  @override
  String hubDownloadSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি মডেল ডাউনলোড করতে হবে, প্রায় $size',
      one: '1টি মডেল ডাউনলোড করতে হবে, প্রায় $size',
    );
    return '$_temp0';
  }

  @override
  String get hubDownloadAction => 'মডেল ডাউনলোড করুন';

  @override
  String hubDownloadFailed(String error) {
    return 'ডাউনলোড শুরু করা গেল না: $error';
  }

  @override
  String get hubCatalogUnavailable => 'মডেলের তালিকা পড়া গেল না';

  @override
  String get hubInstalledUnavailable => 'বসানো মডেল পড়া গেল না';

  @override
  String get hubGalleryNote =>
      'AI Edge Gallery আগে যে ফাইল ডাউনলোড করেছে, Kernel সেগুলো ব্যবহার করতে পারে না (Android প্রতিটি অ্যাপের ফাইল আলাদা ও গোপন রাখে), তাই একই মডেল একবার ডাউনলোড করে।';

  @override
  String get hubConsentTitle => 'পোকা চেনার মডেল ডাউনলোড করবেন?';

  @override
  String get hubConsentBody =>
      'এই মডেলগুলো একবার ডাউনলোড হয়, তারপর শুধু এই ফোনেই চলে। আপনি যা রেকর্ড করেন, তা কখনও আপলোড হয় না।';

  @override
  String hubConsentSize(String size) {
    return 'আকার: $size';
  }

  @override
  String hubConsentLicense(String license) {
    return 'লাইসেন্স: $license';
  }

  @override
  String hubConsentModelCard(String url) {
    return 'মডেল কার্ড: $url';
  }

  @override
  String get hubSourceHf => 'Hugging Face থেকে ডাউনলোড';

  @override
  String get hubSourceGoogle => 'Google AI Edge থেকে ডাউনলোড';

  @override
  String hubSourceOther(String host) {
    return '$host থেকে ডাউনলোড';
  }

  @override
  String get hubWifiOnly => 'শুধু Wi-Fi-তে';

  @override
  String get hubWifiOnlyBody =>
      'ডাউনলোডের আগে Wi-Fi-র জন্য অপেক্ষা করুন। ফাইলগুলো বড়।';

  @override
  String hubConsentTotal(String size) {
    return 'মোট: প্রায় $size';
  }

  @override
  String get hubConsentAgree => 'রাজি, ডাউনলোড করুন';

  @override
  String get hubConsentNotNow => 'এখন নয়';

  @override
  String get hubConsentGrantedTitle => 'মডেল ডাউনলোডের অনুমতি দেওয়া হয়েছে';

  @override
  String get hubDownloadsTitle => 'ডাউনলোড';

  @override
  String get hubPhaseQueued => 'শুরুর অপেক্ষায়';

  @override
  String get hubPhaseWifi => 'Wi-Fi-র অপেক্ষায়';

  @override
  String hubPhaseSpace(String size) {
    return 'খালি জায়গার অপেক্ষায়: $size দরকার';
  }

  @override
  String hubFreeSpace(String free) {
    return 'এই ফোনে $free খালি';
  }

  @override
  String hubPhaseDownloading(String done, String total) {
    return 'ডাউনলোড হচ্ছে: $total-এর মধ্যে $done';
  }

  @override
  String get hubPhaseVerifying => 'ফাইল যাচাই হচ্ছে';

  @override
  String get hubPhasePaused => 'থেমে আছে';

  @override
  String hubPhaseFailed(String reason) {
    return 'হয়নি: $reason';
  }

  @override
  String get hubCancel => 'বাতিল';

  @override
  String get hubInstalledTitle => 'বসানো মডেল';

  @override
  String get hubInstalledEmpty => 'এখনও কোনো মডেল বসানো হয়নি';

  @override
  String get hubInstalledEmptyDetail =>
      'মডেলগুলো একবার ডাউনলোড হলে পোকা চেনা কাজ করে।';

  @override
  String get hubFieldPath => 'ফাইল';

  @override
  String get hubFieldSize => 'আকার';

  @override
  String get hubFieldVersion => 'সংস্করণ';

  @override
  String get hubFieldCapabilities => 'যা পারে';

  @override
  String get hubFieldBackends => 'যাতে চলে';

  @override
  String get hubMatchesGallery => 'AI Edge Gallery-র ফাইলের সঙ্গে মেলে';

  @override
  String get hubRemove => 'সরান';

  @override
  String get hubRemoveConfirmTitle => 'এই মডেল সরাবেন?';

  @override
  String get hubRemoveConfirmBody =>
      'ফাইলটি এই ফোন থেকে মুছে যাবে। যে অংশগুলোর এটা দরকার, আবার ডাউনলোড না হওয়া পর্যন্ত সেগুলো বন্ধ থাকবে।';

  @override
  String hubRemoveFailed(String error) {
    return 'সরানো গেল না: $error';
  }

  @override
  String get hubCapTextGen => 'লেখা';

  @override
  String get hubCapImageIn => 'ছবি বোঝা';

  @override
  String get hubCapAudioIn => 'শব্দ বোঝা';

  @override
  String get hubCapEmbedText => 'লেখার এমবেডিং';

  @override
  String get hubCapEmbedImage => 'ছবির এমবেডিং';

  @override
  String get hubCapEmbedAudio => 'শব্দের এমবেডিং';

  @override
  String get hubCapAudioClassify => 'শব্দ চেনা';

  @override
  String get hubCapImageClassify => 'ছবি চেনা';

  @override
  String get hubCapObjectDetect => 'জিনিস খোঁজা';

  @override
  String get hubCapSegment => 'আকারের রেখা খোঁজা';

  @override
  String get hubCapSensorClassify => 'সেন্সরের সংকেত চেনা';

  @override
  String get hubSearchHint => 'মডেল ও পোকার তথ্য খুঁজুন';

  @override
  String get hubSearchAction => 'খুঁজুন';

  @override
  String get hubSearchModels => 'মডেল';

  @override
  String get hubSearchPestInfo => 'পোকার তথ্য';

  @override
  String hubSearchScore(String score) {
    return 'মিল $score';
  }

  @override
  String get hubSearchNoResults => 'কিছু মেলেনি। অন্য শব্দ দিয়ে চেষ্টা করুন।';

  @override
  String hubSearchFailed(String error) {
    return 'খোঁজা এখন যাচ্ছে না: $error';
  }

  @override
  String get hubSearchNote =>
      'খোঁজা এই ফোনেই চলে। মিলের অঙ্ক নিশ্চয়তার অঙ্ক নয়।';

  @override
  String get hubNeedsReview => 'বিশেষজ্ঞের যাচাই বাকি';

  @override
  String get hubSettingsSection => 'পোকা চেনা, মানচিত্র ও সেন্সর';

  @override
  String get hubSettingsCard =>
      'পোকা চেনার জন্য ফোনে চলা মডেল ডাউনলোড ও সামলান।';

  @override
  String get hubMapsToggle => 'Google Maps ব্যবহার করুন';

  @override
  String get hubMapsToggleBody =>
      'Google-কে শুধু মানচিত্রের অংশ আর পথের শুরু ও শেষ পাঠানো হয়। পোকার নাম, নোট, ছবি বা শব্দ কখনও নয়।';

  @override
  String get hubMapsConfirmTitle => 'Google Maps-এর অনুমতি দেবেন?';

  @override
  String get hubMapsConfirmBody =>
      'মানচিত্রের জন্য ইন্টারনেট লাগে। Google শুধু আপনি মানচিত্রের যে অংশ দেখেন আর পথের শুরু ও শেষ পায়। Kernel কখনও পোকার নাম, নোট, ছবি, শব্দ বা সেন্সরের তথ্য পাঠায় না। যেকোনো সময় এটা বন্ধ করতে পারেন।';

  @override
  String get hubMapsConfirmAgree => 'মানচিত্র চালু করুন';

  @override
  String get hubKeepMediaToggle => 'দেখা পোকার সঙ্গে ছবি ও ক্লিপ রাখুন';

  @override
  String get hubKeepMediaToggleBody =>
      'বন্ধ থাকলে বিশ্লেষণের পরে ছবি বা শব্দের ক্লিপ মুছে ফেলা হয়। রাখা ফাইল এই ফোনেই থাকে।';

  @override
  String get sensorTitle => 'সেন্সর';

  @override
  String get sensorSubtitle =>
      'যুক্ত করা শোনার যন্ত্র। এগুলো সংকেত পাঠায়, রোগনির্ণয় নয়।';

  @override
  String get sensorEmpty => 'এখনও কোনো সেন্সর যুক্ত হয়নি';

  @override
  String get sensorEmptyDetail =>
      'Kernel সেন্সরের গায়ে লাগানো QR লেবেল স্ক্যান করে সেটি যুক্ত করুন।';

  @override
  String get sensorPairAction => 'সেন্সর যুক্ত করুন';

  @override
  String get sensorPrivacyNote =>
      'সেন্সর শুধু শব্দের বৈশিষ্ট্য পাঠায়, শব্দ কখনও নয়। সবকিছু এই ফোনেই থাকে।';

  @override
  String get sensorSettingsCard => 'ব্লুটুথ সেন্সর যুক্ত করুন ও দেখুন।';

  @override
  String get sensorTypeUsAir => 'আল্ট্রাসোনিক (বাতাস)';

  @override
  String get sensorTypeContactPiezo => 'ছুঁয়ে (পিজো)';

  @override
  String get sensorTypeContactAccel => 'ছুঁয়ে (কম্পন)';

  @override
  String get sensorTypeAudioAir => 'শব্দ (বাতাস)';

  @override
  String get sensorLinkUnpaired => 'যুক্ত নয়';

  @override
  String get sensorLinkPairing => 'যুক্ত হচ্ছে';

  @override
  String get sensorLinkConnecting => 'সংযোগ হচ্ছে';

  @override
  String get sensorLinkConnected => 'সংযুক্ত';

  @override
  String get sensorLinkAuthenticated => 'নিরাপদে সংযুক্ত';

  @override
  String get sensorLinkDisconnected => 'সংযুক্ত নয়';

  @override
  String get sensorLinkError => 'সংযোগে সমস্যা';

  @override
  String get sensorStatusUnknown => 'অবস্থা জানা নেই';

  @override
  String sensorBattery(int percent) {
    return 'ব্যাটারি $percent%';
  }

  @override
  String get sensorBatteryUnknown => 'ব্যাটারি জানা নেই';

  @override
  String get sensorHealthOk => 'সেন্সর কাজ করছে';

  @override
  String get sensorHealthJammed =>
      'জ্যাম — কাছে আল্ট্রাসোনিক উৎস আছে (যেমন পোকা তাড়ানোর যন্ত্র); ফল যাচাই হয়নি';

  @override
  String get sensorHealthClipped => 'শব্দ খুব জোরে (ক্লিপ)';

  @override
  String get sensorHealthLowBattery => 'ব্যাটারি কম';

  @override
  String get sensorHealthSurveyNeeded => 'সার্ভে দরকার';

  @override
  String get sensorHealthAuthFailed =>
      'নিরাপত্তা যাচাই হয়নি — আবার যুক্ত করুন';

  @override
  String get sensorHealthSensorFault => 'সেন্সরে ত্রুটি — যাচাই হয়নি';

  @override
  String get sensorHealthEventsOverwritten =>
      'কিছু ঘটনা হারিয়ে গেছে — এই সময়ের যাচাই হয়নি';

  @override
  String get sensorNotEvaluatedTitle => 'যাচাই হয়নি';

  @override
  String get sensorNotEvaluatedBody =>
      'এই সেন্সর এখন যাচাই করতে পারছে না। এর মানে এই নয় যে সেখানে কিছু নেই। নিজে দেখে পরীক্ষা করুন।';

  @override
  String get sensorPairTitle => 'সেন্সর যুক্ত করুন';

  @override
  String get sensorPairInstructions =>
      'ক্যামেরা সেন্সরের QR লেবেলের দিকে ধরুন।';

  @override
  String get sensorPairPrivacy =>
      'লেবেলে সেন্সরের নিরাপত্তা চাবি আছে। এটা এই ফোনে সুরক্ষিত জায়গায় রাখা হয় এবং কখনও দেখানো বা পাঠানো হয় না।';

  @override
  String get sensorPairNotSensor => 'এটা Kernel সেন্সরের লেবেল নয়।';

  @override
  String get sensorPairing =>
      'যুক্ত হচ্ছে। Android-এর যুক্ত করার অনুরোধ মেনে নিন।';

  @override
  String get sensorPairCancelled => 'যুক্ত করা বাতিল হয়েছে।';

  @override
  String sensorPairFailed(String error) {
    return 'যুক্ত করা গেল না: $error';
  }

  @override
  String get sensorPairTryAgain => 'আবার স্ক্যান করুন';

  @override
  String sensorPairedSnack(String name) {
    return '$name যুক্ত হয়েছে';
  }

  @override
  String get sensorCameraTitle => 'লেবেল পড়তে ক্যামেরার অনুমতি দিন';

  @override
  String get sensorCameraBody =>
      'Kernel ক্যামেরা শুধু সেন্সরের QR লেবেল পড়তে ব্যবহার করে। কিছু রেকর্ড বা পাঠানো হয় না।';

  @override
  String get sensorPlaceTitle => 'এই সেন্সর কোথায়?';

  @override
  String get sensorPlaceSubtitle =>
      'জায়গা বেছে নিন, আর এটা কোনো বস্তা বা পাত্রের ওপর থাকলে সেটাও।';

  @override
  String get sensorPlaceLocation => 'জায়গা';

  @override
  String get sensorPlaceItem => 'বস্তা বা পাত্র';

  @override
  String get sensorPlaceNone => 'ঠিক করা নেই';

  @override
  String get sensorPlaceNote =>
      'তারপর সেন্সরের প্রমাণ সেই বস্তা বা পাত্রে দেখা যাবে, স্ক্যান ও পরিদর্শন থেকে আলাদা।';

  @override
  String get sensorPlaceSave => 'জায়গা সংরক্ষণ করুন';

  @override
  String get sensorPlaceSkip => 'পরে';

  @override
  String get sensorPlaceSaved => 'জায়গা সংরক্ষিত';

  @override
  String sensorPlaceFailed(String error) {
    return 'জায়গা সংরক্ষণ করা গেল না: $error';
  }

  @override
  String get sensorPlaceNoLocations =>
      'এখনও কোনো জায়গা নেই — আগে ঘর বা গুদাম যোগ করুন';

  @override
  String get sensorPlaceChange => 'জায়গা বদলান';

  @override
  String get sensorNotFound => 'এই সেন্সর এই ফোনে নেই।';

  @override
  String get sensorDetailsTitle => 'সেন্সরের তথ্য';

  @override
  String get sensorFieldType => 'ধরন';

  @override
  String get sensorFieldPlace => 'জায়গা';

  @override
  String get sensorFieldItem => 'যার ওপর রাখা';

  @override
  String get sensorFieldFirmware => 'ফার্মওয়্যার';

  @override
  String get sensorFieldKey => 'চাবির পরিচয়';

  @override
  String get sensorFieldLastSeen => 'শেষ দেখা';

  @override
  String get sensorLiveTitle => 'লাইভ ব্যান্ড';

  @override
  String get sensorLiveNote =>
      'শুধু প্রতিটি কম্পাঙ্ক ব্যান্ডের শক্তি। সেন্সর কোনো শব্দ পাঠায় না।';

  @override
  String get sensorLiveWaiting => 'সেন্সরের অপেক্ষায়';

  @override
  String sensorBandRange(String low, String high) {
    return '$low–$high kHz';
  }

  @override
  String sensorBandLevel(String db) {
    return 'পটভূমির চেয়ে $db dB বেশি';
  }

  @override
  String sensorLivePeak(String khz) {
    return 'সবচেয়ে জোরালো $khz kHz-এ';
  }

  @override
  String get sensorSurveyTitle => 'সার্ভে';

  @override
  String sensorSurveyBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'জায়গাটি $minutes মিনিট চুপচাপ রাখুন, যাতে সেন্সর স্বাভাবিক পটভূমি শিখে নেয়।',
      one: 'জায়গাটি 1 মিনিট চুপচাপ রাখুন, যাতে সেন্সর স্বাভাবিক পটভূমি শিখে নেয়।',
    );
    return '$_temp0';
  }

  @override
  String sensorSurveyStart(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'সার্ভে শুরু করুন ($minutes মিনিট)',
      one: 'সার্ভে শুরু করুন (1 মিনিট)',
    );
    return '$_temp0';
  }

  @override
  String sensorSurveyRunning(int done, int total) {
    return 'সার্ভে চলছে: $total মিনিটের মধ্যে $done';
  }

  @override
  String get sensorSurveyDone => 'সার্ভে শেষ';

  @override
  String sensorSurveyFailed(String error) {
    return 'সার্ভে হয়নি: $error';
  }

  @override
  String get sensorSessionTitle => 'সারা রাত নজরদারি';

  @override
  String get sensorSessionBody =>
      'Kernel পেছনে এই সেন্সর শুনতে থাকে। চলার সময় Android একটা বিজ্ঞপ্তি দেখায়। সারা রাত চালু রাখতে অ্যাপ সেটিংস খুলে ব্যাটারি ব্যবহার \'বাধাহীন\' (ব্যাটারি অপ্টিমাইজেশন বন্ধ) করুন।';

  @override
  String get sensorSessionStart => 'সারা রাতের নজরদারি শুরু করুন';

  @override
  String get sensorSessionStop => 'নজরদারি থামান';

  @override
  String get sensorSessionRunning => 'নজরদারি চলছে';

  @override
  String sensorSessionFailed(String error) {
    return 'নজরদারি বদলানো গেল না: $error';
  }

  @override
  String get sensorBatterySettings => 'অ্যাপ সেটিংস খুলুন';

  @override
  String get sensorSyncAction => 'ঘটনা আনুন';

  @override
  String sensorSynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি নতুন ঘটনা',
      one: '1টি নতুন ঘটনা',
      zero: 'কোনো নতুন ঘটনা নেই',
    );
    return '$_temp0';
  }

  @override
  String sensorSyncFailed(String error) {
    return 'আনা গেল না: $error';
  }

  @override
  String get sensorTimelineTitle => 'ঘটনার তালিকা';

  @override
  String get sensorTimelineEmpty => 'এখনও কোনো ঘটনা লেখা হয়নি';

  @override
  String get sensorTimelineEmptyDetail =>
      'এটা প্রমাণ নয় যে সেখানে কিছু নেই। সেন্সরে জমা ঘটনা আনতে \'ঘটনা আনুন\' চাপুন।';

  @override
  String get sensorSummaryTitle => 'সংকেত';

  @override
  String sensorEventsSummary(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes মিনিটে',
      one: '1 মিনিটে',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ঘটনা',
      one: '1টি ঘটনা',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get sensorSignalNotDiagnosis =>
      'এগুলো সংকেত, রোগনির্ণয় নয়। নিজে দেখে পরীক্ষা করুন।';

  @override
  String get sensorUnmatched => 'না-মেলা সংকেত';

  @override
  String get sensorSigMouseUsv => 'ইঁদুরের মতো আল্ট্রাসোনিক ডাক';

  @override
  String get sensorSigRat22k => 'ধেড়ে ইঁদুরের মতো 22 kHz ডাক';

  @override
  String get sensorSigGrainLarva => 'শস্যের লার্ভার মতো কুটকুট শব্দ';

  @override
  String get sensorSigTermiteDrum => 'উইপোকার মতো ঠকঠক';

  @override
  String sensorSigOther(String id) {
    return 'চিহ্ন: $id';
  }

  @override
  String sensorPack(String version) {
    return 'সংকেত প্যাক $version';
  }

  @override
  String sensorScore(String score) {
    return 'নিয়ম অঙ্ক $score (সম্ভাবনা নয়)';
  }

  @override
  String sensorEventLine(String time, String kind, String khz, int ms) {
    return '$time · $kind · $khz kHz · $ms ms';
  }

  @override
  String get sensorClassTonal => 'সুর';

  @override
  String get sensorClassFmSweep => 'ওঠানামা করা শব্দ';

  @override
  String get sensorClassFlatTone => 'একটানা সুর';

  @override
  String get sensorClassImpulse => 'টিকটিক';

  @override
  String get sensorClassHarmonic => 'গুঞ্জন সুর';

  @override
  String get sensorClassChirp => 'থেমে থেমে কিচকিচ';

  @override
  String get sensorClassEmitter => 'একটানা চলা যন্ত্র';

  @override
  String get sensorEvidenceTitle => 'সেন্সরের প্রমাণ';

  @override
  String get sensorEvidenceBody =>
      'এখানে রাখা সেন্সরের সংকেত। পরীক্ষামূলক, এবং স্ক্যান ও পরিদর্শন থেকে আলাদা রাখা।';

  @override
  String get sensorEvidenceOpen => 'সেন্সর খুলুন';

  @override
  String sensorEvidenceEmpty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'গত $days দিনে কোনো সেন্সর ঘটনা নেই। এটা প্রমাণ নয় যে সেখানে কিছু নেই।',
      one: 'গত 1 দিনে কোনো সেন্সর ঘটনা নেই। এটা প্রমাণ নয় যে সেখানে কিছু নেই।',
    );
    return '$_temp0';
  }

  @override
  String sensorEvidenceWindow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'গত $days দিন',
      one: 'গত 1 দিন',
    );
    return '$_temp0';
  }

  @override
  String sensorNextActivityOne(String name) {
    return '$name-এ সেন্সর সংকেত';
  }

  @override
  String sensorNextActivityMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি জায়গায় সেন্সর সংকেত',
      one: '1টি জায়গায় সেন্সর সংকেত',
    );
    return '$_temp0';
  }

  @override
  String get sensorNextActivityBody =>
      'এগুলো সংকেত, রোগনির্ণয় নয়। নিজে দেখে পরীক্ষা করুন।';

  @override
  String sensorNextAttentionOne(String name) {
    return 'সেন্সর $name দেখুন';
  }

  @override
  String sensorNextAttentionMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি সেন্সরে নজর দরকার',
      one: '1টি সেন্সরে নজর দরকার',
    );
    return '$_temp0';
  }

  @override
  String get sensorNextAttentionBody =>
      'জ্যাম, শব্দ খুব জোরে, ব্যাটারি কম বা সার্ভে দরকার। এর ফল যাচাই হয়নি।';

  @override
  String get sensorNextOpen => 'সেন্সর খুলুন';

  @override
  String get pestIdTitle => 'পোকা ও প্রাণী শনাক্ত';

  @override
  String get pestIdSubtitle =>
      'ক্যামেরা দিয়ে দেখুন বা শব্দ শুনুন। ফোন সম্ভাব্য চিহ্ন খোঁজে; কোনটা আসল, আপনি ঠিক করেন।';

  @override
  String get pestHomeActionBody =>
      'ক্যামেরা বা শব্দ দিয়ে পোকা, ইঁদুর, মাকড়সা, টিকটিকি ও অন্য প্রাণী দেখুন';

  @override
  String get pestHeroAction => 'দেখুন বা শুনুন';

  @override
  String get pestSegmentGrain => 'শস্যের বস্তা';

  @override
  String get pestSegmentPest => 'পোকা ও প্রাণী';

  @override
  String get pestCameraCardTitle => 'ক্যামেরা দিয়ে দেখুন';

  @override
  String get pestCameraCardBody =>
      'নড়াচড়া, কালো দাগ আর চোখের ঝলক খোঁজে। কোনটা আসল, আপনি নিশ্চিত করেন।';

  @override
  String get pestListenCardTitle => 'শব্দ শুনুন';

  @override
  String get pestListenCardBody =>
      'ভনভন, আঁচড়ানো আর কিচকিচ শব্দ ধরে। আপনি যা শুনেছেন, আপনি নিশ্চিত করেন।';

  @override
  String get pestSightingsCardTitle => 'আমার দেখা প্রাণী';

  @override
  String pestSightingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি দেখা সংরক্ষিত',
      one: '1টি দেখা সংরক্ষিত',
      zero: 'এখনও কিছু সংরক্ষিত নেই',
    );
    return '$_temp0';
  }

  @override
  String get pestOnPhoneNote =>
      'সবকিছু এই ফোনেই পরীক্ষা হয়। ছবি ও শব্দ কখনও আপলোড হয় না।';

  @override
  String get pestNotCertainNote =>
      'AI-এর ফল অনুমান মাত্র, ভুল হতে পারে। কোনো চিহ্ন না পাওয়া মানে এই প্রমাণ নয় যে সেখানে কিছু নেই।';

  @override
  String get pestCameraTitle => 'চিহ্ন খুঁজুন';

  @override
  String get pestCameraTip =>
      'কোণ, ফাটল আর শস্যের কাছে ফোন স্থির রাখুন। কোনো বাক্স নিশ্চিত করতে ছুঁয়ে দিন, বা কাছ থেকে দেখতে ছবি তুলুন।';

  @override
  String get pestCameraDenied =>
      'ক্যামেরার অনুমতি বন্ধ। চিহ্ন খুঁজতে সেটিংসে এটি চালু করুন। আপনার সংরক্ষিত রেকর্ড দেখা যাবে।';

  @override
  String get pestKindMotion => 'নড়াচড়া';

  @override
  String get pestKindSpecks => 'কালো দাগ';

  @override
  String get pestKindEyeshine => 'চোখের ঝলক';

  @override
  String get pestKindEmbedding => 'দেখতে একই রকম';

  @override
  String get pestKindModelBox => 'AI বাক্স';

  @override
  String get pestKindSound => 'শব্দ';

  @override
  String pestConfirmBox(String kind) {
    return '$kind নিশ্চিত করুন';
  }

  @override
  String get pestTorch => 'টর্চ';

  @override
  String pestTorchValue(int percent) {
    return '$percent%';
  }

  @override
  String get pestCapture => 'ছবি তুলুন';

  @override
  String get pestCapturing => 'ছবি তোলা হচ্ছে…';

  @override
  String get pestNothingHere => 'পোকা নয় / এখানে কিছু নেই';

  @override
  String get pestNothingHereDone =>
      'কিছু সংরক্ষিত হয়নি। ছবিগুলি মুছে ফেলা হয়েছে।';

  @override
  String get pestCandidatesNone =>
      'এখনও কোনো সম্ভাব্য চিহ্ন নেই। ধীরে নাড়ান বা টর্চ চালু করুন।';

  @override
  String pestCandidatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি সম্ভাব্য চিহ্ন',
      one: '1টি সম্ভাব্য চিহ্ন',
    );
    return '$_temp0';
  }

  @override
  String get pestCaptureFailed => 'ছবি তোলা গেল না। আবার চেষ্টা করুন।';

  @override
  String get pestTilesTitle => 'কাছ থেকে: যেটি আসল সেটি ছুঁয়ে দিন';

  @override
  String get pestTilesEmpty =>
      'এই ছবিতে কাছের কোনো অংশ নেই। আরও কাছে বা টর্চ দিয়ে আবার চেষ্টা করুন।';

  @override
  String pestTileHint(String name) {
    return 'AI ইঙ্গিত: $name (যাচাই করা নয়)';
  }

  @override
  String get pestTileConfirm => 'নিশ্চিত করতে ছুঁয়ে দিন';

  @override
  String get pestRetake => 'আবার ছবি তুলুন';

  @override
  String get pestAnalysisTitle => 'AI বিশ্লেষণ';

  @override
  String get pestAnalysing => 'এই ফোনেই বিশ্লেষণ হচ্ছে…';

  @override
  String get pestAiLabel => 'AI-এর দেওয়া নাম';

  @override
  String get pestAiEstimated => 'AI-এর অনুমান';

  @override
  String get pestConfidenceLabel => 'AI-এর আনুমানিক ভরসা — যাচাই করে মাপা নয়';

  @override
  String pestConfidenceValue(int percent) {
    return '$percent% (AI-এর নিজের অনুমান)';
  }

  @override
  String pestAgreement(int agree, int runs) {
    return '$runs বারের মধ্যে $agree বার একই উত্তর';
  }

  @override
  String get pestKeyFeatures => 'মূল বৈশিষ্ট্য';

  @override
  String get pestAnomalies => 'অস্বাভাবিক বিষয়';

  @override
  String get pestInsights => 'তথ্য';

  @override
  String get pestNoMatch =>
      'কোনো মিলে যাওয়া কার্ড নেই। এর মানে এই নয় যে সেখানে কিছু নেই। নিজে দেখে পরীক্ষা করুন।';

  @override
  String get pestNotAPest =>
      'AI মনে করে এটি পোকা নয়। এটি প্রমাণ নয়। সন্দেহ হলে নিজে দেখে পরীক্ষা করুন।';

  @override
  String pestModelLine(String version, String prompt) {
    return 'মডেল $version · প্রম্পট $prompt — পরীক্ষামূলক';
  }

  @override
  String get pestAnalysisUnavailable => 'AI বিশ্লেষণ পাওয়া যাচ্ছে না';

  @override
  String get pestAnalysisUnavailableBody =>
      'ফোনের AI এটি বিশ্লেষণ করতে পারেনি। তার বদলে সবচেয়ে কাছের তথ্য কার্ড দেখানো হচ্ছে।';

  @override
  String get pestNoCardFound =>
      'কোনো মিলে যাওয়া তথ্য কার্ড নেই। নিজে দেখে পরীক্ষা করুন এবং সন্দেহ হলে বিশেষজ্ঞকে জিজ্ঞাসা করুন।';

  @override
  String get pestSafetyVenomousTitle => 'বিষাক্ত — দূরে থাকুন';

  @override
  String get pestSafetyMedicalTitle => 'স্বাস্থ্যের ঝুঁকি — দূরে থাকুন';

  @override
  String get pestSafetyDistanceBody =>
      'এটি ছোঁবেন না বা ধরবেন না। কামড় বা হুল ফোটালে চিকিৎসা নিন। ঘরোয়া টোটকা ব্যবহার করবেন না।';

  @override
  String get pestSafetyProtectedTitle => 'সংরক্ষিত বন্যপ্রাণী — ক্ষতি করবেন না';

  @override
  String get pestSafetyProtectedBody =>
      'এর ক্ষতি করবেন না, ধরবেন না বা মারবেন না। রাজ্য বন বিভাগ বা লাইসেন্সপ্রাপ্ত বন্যপ্রাণী উদ্ধারকারীকে ডাকুন।';

  @override
  String get pestSafetyCautionTitle => 'সাবধান থাকুন';

  @override
  String get pestSafetyCautionBody =>
      'খালি হাতে এটি ছোঁবেন না। কার্ডে দেওয়া নিরাপদ পদক্ষেপ মেনে চলুন।';

  @override
  String get pestCardTitle => 'তথ্য কার্ড';

  @override
  String get pestCardYourPick => 'আপনার বাছাই';

  @override
  String get pestCardNeedsReview => 'বিশেষজ্ঞের যাচাই বাকি';

  @override
  String pestCardOtherNames(String names) {
    return 'অন্য নাম: $names';
  }

  @override
  String get pestCardSigns => 'কোন চিহ্ন দেখবেন';

  @override
  String get pestCardHealthRisks => 'স্বাস্থ্যের ঝুঁকি';

  @override
  String get pestCardSafeSteps => 'নিরাপদ পদক্ষেপ';

  @override
  String get pestCardCallPro => 'কখন বিশেষজ্ঞকে ডাকবেন';

  @override
  String get pestCardFirstAid => 'প্রাথমিক চিকিৎসা';

  @override
  String get pestCardLookAlikes => 'দেখতে একই রকম প্রাণী';

  @override
  String get pestCardLegal => 'আইনি অবস্থা';

  @override
  String get pestCardSources => 'সূত্র';

  @override
  String get pestExplain => 'বুঝিয়ে বলুন';

  @override
  String get pestExplainTitle => 'কার্ড অনুযায়ী ব্যাখ্যা';

  @override
  String get pestExplainFallback =>
      'এখন কোনো ব্যাখ্যা নেই। উপরের কার্ডটিই নির্দেশনা।';

  @override
  String get pestPickCard => 'অন্য কার্ড বাছুন';

  @override
  String get pestPickCardTitle => 'এটি কোনটি?';

  @override
  String get pestPickCardBody =>
      'আপনার বাছাই আপনার সংশোধন হিসেবে সংরক্ষিত হয়। AI বিশ্লেষণ যেমন ছিল তেমনই থাকে।';

  @override
  String get pestPickCardClear => 'AI-এর নাম ব্যবহার করুন';

  @override
  String get pestMeasure => 'দূরত্ব মাপুন';

  @override
  String get pestMeasuring => 'মাপা হচ্ছে…';

  @override
  String pestDistanceValue(
    String meters,
    String low,
    String high,
    String method,
  ) {
    return 'প্রায় $meters মি. দূরে ($low–$high মি.), $method দিয়ে';
  }

  @override
  String get pestDistanceMethodDepth => 'গভীরতা সেন্সর';

  @override
  String get pestDistanceMethodFocus => 'ক্যামেরা ফোকাস';

  @override
  String get pestDistanceUnavailable => 'দূরত্ব পাওয়া যাচ্ছে না';

  @override
  String pestDistanceReason(String reason) {
    return 'কারণ: $reason';
  }

  @override
  String get pestDistanceNoReason => 'ফোন এটি ভরসাযোগ্যভাবে মাপতে পারেনি।';

  @override
  String get pestSave => 'রেকর্ড সংরক্ষণ করুন';

  @override
  String get pestDiscard => 'বাদ দিন';

  @override
  String get pestStartAgain => 'আবার শুরু করুন';

  @override
  String get pestNoSignal =>
      'বিশ্লেষণের মতো কিছু নেই। ক্যামেরা বা শোনা দিয়ে আবার শুরু করুন।';

  @override
  String get pestGroupInsect => 'পোকা';

  @override
  String get pestGroupArachnid => 'মাকড়সা বা বিছে';

  @override
  String get pestGroupRodent => 'ইঁদুর';

  @override
  String get pestGroupReptile => 'সরীসৃপ (টিকটিকি, সাপ ইত্যাদি)';

  @override
  String get pestGroupOther => 'অন্য প্রাণী';

  @override
  String get pestGroupNotAPest => 'পোকা নয়';

  @override
  String get pestGroupUnknown => 'অজানা';

  @override
  String pestGroupHint(String group) {
    return 'সম্ভাব্য দল: $group (AI ইঙ্গিত)';
  }

  @override
  String get pestSourceCamera => 'ক্যামেরা';

  @override
  String get pestSourceMic => 'শব্দ';

  @override
  String get pestSourceSensor => 'সেন্সর';

  @override
  String get pestListenTitle => 'শব্দ শুনুন';

  @override
  String get pestListenModeGeneral => 'সাধারণ';

  @override
  String get pestListenModeMosquito => 'মশা কাছ থেকে';

  @override
  String get pestListenModeNight => 'রাত';

  @override
  String get pestListenModeGeneralBody =>
      'যেখানে শব্দ হচ্ছে তার কাছে ফোন স্থির রাখুন।';

  @override
  String get pestListenModeMosquitoBody =>
      'ভনভনানি থেকে এক হাতের তালুর দূরত্বে ফোন ধরুন।';

  @override
  String get pestListenModeNightBody =>
      'ফোনটি ঘরে স্থির রেখে দিন। শোনার সময় একটি বিজ্ঞপ্তি দেখা যায়, যাতে আপনি যেকোনো সময় থামাতে পারেন।';

  @override
  String get pestListenStart => 'শোনা শুরু করুন';

  @override
  String get pestListenStop => 'থামান';

  @override
  String get pestListening => 'এই ফোনেই শোনা হচ্ছে…';

  @override
  String get pestListenNone => 'এখনও কোনো শব্দ ধরা পড়েনি।';

  @override
  String get pestListenTapToConfirm =>
      'যে শব্দ আপনিও শুনেছেন, ছুঁয়ে নিশ্চিত করুন';

  @override
  String get pestListenMicDenied =>
      'মাইক্রোফোনের অনুমতি বন্ধ। শুনতে সেটিংসে এটি চালু করুন। আপনার সংরক্ষিত রেকর্ড দেখা যাবে।';

  @override
  String get pestListenNightNeedsNotice =>
      'রাতের মোডে বিজ্ঞপ্তি দরকার, যাতে আপনি শোনা দেখতে ও থামাতে পারেন। বিজ্ঞপ্তি চালু করে আবার চেষ্টা করুন।';

  @override
  String get pestListenAgain => 'আবার শুনুন';

  @override
  String pestSoundAt(String time) {
    return '$time-এ শব্দ';
  }

  @override
  String get pestSoundConfirm => 'নিশ্চিত করতে ছুঁয়ে দিন';

  @override
  String pestSoundScore(String label, int percent) {
    return '$label · $percent%';
  }

  @override
  String get pestSoundNoLabels => 'শব্দের কোনো নাম পাওয়া যায়নি।';

  @override
  String get pestSoundRawNote =>
      'শব্দ চেনার মডেলের কাঁচা নম্বর, যাচাই করে মাপা নয়';

  @override
  String get pestSoundDescribing => 'এই ফোনেই শব্দের বর্ণনা তৈরি হচ্ছে…';

  @override
  String get pestSoundDescription => 'AI বর্ণনা (পরীক্ষামূলক)';

  @override
  String get pestSoundNoDescription => 'কোনো AI বর্ণনা পাওয়া যায়নি।';

  @override
  String pestSoundModel(String version) {
    return 'শব্দ মডেল $version — পরীক্ষামূলক';
  }

  @override
  String get pestSoundCards => 'মিলে যাওয়া কার্ড';

  @override
  String get pestSoundNoCards =>
      'কোনো মিলে যাওয়া কার্ড নেই। নিজে দেখে পরীক্ষা করুন।';

  @override
  String get pestClipGone => 'সেই শব্দটি আর পাওয়া যাচ্ছে না। আবার শুনুন।';

  @override
  String get pestSaveTitle => 'রেকর্ড সংরক্ষণ করুন';

  @override
  String get pestSaveSubtitle => 'শুধু এই ফোনেই সংরক্ষিত হয়';

  @override
  String get pestSaveRoom => 'ঘর বা জায়গা';

  @override
  String get pestSaveNoRoom => 'কোনো ঘর নয়';

  @override
  String get pestSaveNoRooms =>
      'এখনও কোনো ঘর বা জায়গা নেই। মজুত থেকে যোগ করতে পারেন।';

  @override
  String get pestSaveLocation => 'অবস্থান সংরক্ষণ করুন';

  @override
  String get pestSaveLocationBody =>
      'ঐচ্ছিক। অবস্থান শুধু এখনই চাওয়া হয়। ঘরের ভিতরে ঘরের নামই বেশি কাজে লাগে।';

  @override
  String get pestLocating => 'অবস্থান নেওয়া হচ্ছে…';

  @override
  String get pestLocationDenied =>
      'অবস্থানের অনুমতি পাওয়া যায়নি, শুধু ঘর সংরক্ষিত';

  @override
  String get pestLocationImprecise => 'অবস্থান খুব আন্দাজি, শুধু ঘর সংরক্ষিত';

  @override
  String get pestLocationOff => 'এই ফোনে অবস্থান বন্ধ, শুধু ঘর সংরক্ষিত';

  @override
  String get pestLocationFailed => 'অবস্থান পাওয়া যায়নি, শুধু ঘর সংরক্ষিত';

  @override
  String pestLocationPinned(int meters) {
    return 'পিন সংরক্ষিত ($meters মি.-এর মধ্যে)';
  }

  @override
  String get pestKeepMedia => 'ছবি বা শব্দ রেখে দিন';

  @override
  String get pestKeepMediaBody =>
      'শুরুতে বন্ধ। রেকর্ডের সঙ্গে এই ফোনেই গোপনে রাখা হয়, কখনও আপলোড হয় না।';

  @override
  String get pestNotes => 'নোট';

  @override
  String get pestSaved => 'রেকর্ড সংরক্ষিত';

  @override
  String get pestSaveFailed => 'সংরক্ষণ করা গেল না। আবার চেষ্টা করুন।';

  @override
  String get pestSightingsTitle => 'দেখা প্রাণী';

  @override
  String get pestSightingsSubtitle => 'এই ফোনে সংরক্ষিত, নতুনগুলি আগে';

  @override
  String get pestSightingsEmpty => 'এখনও কোনো রেকর্ড নেই';

  @override
  String get pestSightingsEmptyDetail =>
      'চিহ্ন দেখুন বা শুনুন, আর যা নিশ্চিত করবেন তা সংরক্ষণ করুন।';

  @override
  String get pestSightingUnnamed => 'অচেনা রেকর্ড';

  @override
  String get pestNoFindingYet => 'এখনও কেউ পরীক্ষা করেননি';

  @override
  String pestFindingChip(String finding) {
    return 'পরীক্ষিত: $finding';
  }

  @override
  String get pestNotFound => 'এই রেকর্ডটি এই ফোনে নেই।';

  @override
  String get pestDetailTitle => 'দেখা প্রাণী';

  @override
  String get pestDetailAiSection => 'AI বিশ্লেষণ';

  @override
  String get pestDetailAiNote =>
      'AI-এর অনুমান — যাচাই করে মাপা নয়। যেমন ছিল তেমন সংরক্ষিত, কখনও বদলানো হয় না।';

  @override
  String get pestDetailValidation => 'আপনার নিশ্চিতকরণ';

  @override
  String get pestDetailConfirmed => 'আপনি নিশ্চিত করেছেন চিহ্নটি আসল ছিল';

  @override
  String get pestDetailNotConfirmed => 'নিশ্চিত করা হয়নি';

  @override
  String pestDetailYourPick(String name) {
    return 'আপনার বাছাই: $name';
  }

  @override
  String get pestDetailVerified => 'যাচাই করা ফলাফল';

  @override
  String get pestDetailVerifiedBody =>
      'কেউ পরীক্ষা করে যা পেয়েছেন। AI বিশ্লেষণ থেকে আলাদা। এটি একবারই লেখা যায়।';

  @override
  String get pestDetailRecordFinding => 'ফলাফল লিখুন';

  @override
  String pestDetailConfirmFinding(String finding) {
    return '\"$finding\" যাচাই করা ফলাফল হিসেবে সংরক্ষণ করবেন? পরে এটি বদলানো যাবে না।';
  }

  @override
  String get pestDetailPlace => 'জায়গা';

  @override
  String get pestDetailPinLabel => 'পিন';

  @override
  String pestDetailPin(String lat, String lng, int meters) {
    return '$lat, $lng ($meters মি.-এর মধ্যে)';
  }

  @override
  String get pestDetailNoPlace => 'কোনো ঘর বা পিন সংরক্ষিত নেই।';

  @override
  String get pestDetailShowMap => 'মানচিত্রে দেখান';

  @override
  String get pestDetailMediaKept => 'ছবি বা শব্দ এই ফোনে রাখা আছে';

  @override
  String pestNextRepeated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'পোকা $count বার দেখা গেছে',
      one: 'একটি পোকা আবার দেখা গেছে',
    );
    return '$_temp0';
  }

  @override
  String pestNextRepeatedOne(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$label: $count বার দেখা গেছে',
      one: '$label: আবার দেখা গেছে',
    );
    return '$_temp0';
  }

  @override
  String get pestNextRepeatedBody =>
      'জায়গাটি দেখুন এবং কার্ডের নিরাপদ পদক্ষেপ মেনে চলুন।';

  @override
  String get pestNextSafety => 'একটি রেকর্ডে সতর্কতা দরকার';

  @override
  String get pestNextSafetyBody =>
      'কাছে যাওয়ার আগে কার্ডের নিরাপত্তা পদক্ষেপ পড়ুন।';

  @override
  String get pestNextAction => 'রেকর্ড দেখুন';

  @override
  String get mapTitle => 'দেখা প্রাণীর মানচিত্র';

  @override
  String get mapCardBody => 'সঠিক অবস্থানসহ সংরক্ষিত রেকর্ডের পিন';

  @override
  String get mapConsentTitle => 'Google Maps ব্যবহার করবেন?';

  @override
  String get mapConsentBody =>
      'মানচিত্র ও হাঁটার পথ Google থেকে আসে। আপনি মানচিত্রের যে অংশ দেখেন এবং পথের শুরু ও শেষের জায়গা Google পায়।';

  @override
  String get mapConsentNever =>
      'Google কখনও প্রাণীর নাম, আপনার নোট, ছবি বা শব্দ পায় না।';

  @override
  String get mapConsentAllow => 'মানচিত্রের অনুমতি দিন';

  @override
  String get mapConsentDecline => 'এখন নয়';

  @override
  String get mapConsentNeeded =>
      'মানচিত্র বন্ধ। আপনি অনুমতি না দেওয়া পর্যন্ত কিছু পাঠানো হয় না।';

  @override
  String get mapNotConfigured => 'মানচিত্র সেট করা নেই';

  @override
  String get mapNotConfiguredBody =>
      'এই অ্যাপে মানচিত্রের চাবি নেই। তবু কোনো পিন Google Maps অ্যাপে খুলতে পারেন।';

  @override
  String get mapOpenInGoogleMaps => 'Google Maps-এ খুলুন';

  @override
  String get mapNoPins => 'এখনও সঠিক অবস্থানসহ কোনো রেকর্ড নেই';

  @override
  String get mapNoPinsDetail =>
      '25 মি.-এর মধ্যে অবস্থানসহ সংরক্ষিত রেকর্ডের পিন দেখা যায়।';

  @override
  String get mapNoPinsAction => 'রেকর্ড দেখুন';

  @override
  String mapPinLabel(String date) {
    return 'রেকর্ড $date';
  }

  @override
  String get mapRoute => 'এখান থেকে পথ';

  @override
  String get mapRouting => 'পথ খোঁজা হচ্ছে…';

  @override
  String mapRouteSummary(String distance, int minutes) {
    return '$distance · প্রায় $minutes মিনিট';
  }

  @override
  String get mapRouteFailed =>
      'পথ পাওয়া গেল না। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।';

  @override
  String get mapRouteNeedsLocation =>
      'পথের জন্য আপনার অবস্থান দরকার। অবস্থানের অনুমতি দিয়ে আবার চেষ্টা করুন।';

  @override
  String get mapStartNavigation => 'পথ দেখানো শুরু করুন';

  @override
  String get mapNavigationFailed => 'এই ফোনে Google Maps খোলা গেল না।';

  @override
  String mapDistanceKm(String km) {
    return '$km কিমি';
  }

  @override
  String mapDistanceM(int meters) {
    return '$meters মি.';
  }
}

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
  String get languageSheetBody =>
      'Kernel-এর লেখা সঙ্গে সঙ্গে বদলে যায়। আরও ভারতীয় ভাষা আসছে।';

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

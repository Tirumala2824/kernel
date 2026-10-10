// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageFollowDevice => 'फोनची भाषा वापरा';

  @override
  String get languageSheetBody => 'Kernel मधले शब्द लगेच बदलतात.';

  @override
  String get settingsSubtitle =>
      'भाषा, आवाज-तपासणी, गोपनीयता आणि फोनवरच चालणाऱ्या गोष्टींची माहिती';

  @override
  String get settingsScanning => 'आवाज-तपासणी';

  @override
  String get settingsHaptics => 'सुरुवातीला आणि शेवटी कंपन';

  @override
  String get settingsHapticsBody =>
      'रेकॉर्डिंग सुरू आणि बंद होताना फोन थोडा थरथरतो, म्हणजे तुम्ही फोन पोत्यावर दाबून ठेवू शकता.';

  @override
  String get settingsVoice => 'बोलून सूचना';

  @override
  String get settingsVoiceBody =>
      'सुरुवातीला बंद असते. या फोनमधल्या आवाजात “फोन पोत्यावर ठेवा”, “ऐकत आहे” आणि “झाले” असे सांगते. इंटरनेटवरून काहीही घेतले जात नाही.';

  @override
  String get settingsRetain => 'रेकॉर्डिंग या फोनवर ठेवा';

  @override
  String get settingsRetainBody =>
      'सुरुवातीला बंद असते: प्रत्येक 2 सेकंदांचे रेकॉर्डिंग तपासल्यावर लगेच हटवले जाते. चालू केल्यास रेकॉर्डिंग अॅपच्या आत खाजगीरित्या ठेवली जातात, म्हणजे ती पुन्हा तपासता येतात. ती कधीही अपलोड होत नाहीत. “सगळा इतिहास हटवा” ती काढून टाकते.';

  @override
  String get settingsResearchSection => 'संशोधन';

  @override
  String get settingsResearch => 'संशोधन रेकॉर्डिंग मोड';

  @override
  String get settingsResearchBody =>
      'धान्यातील किडीचे मॉडेल बनवायला मदत म्हणून लेबल लावलेले नमुने रेकॉर्ड करा. हे रेकॉर्डिंग ठेवण्याच्या सेटिंगपेक्षा वेगळे आहे; सुरुवातीला बंद असते.';

  @override
  String get researchConsentTitle => 'संशोधन रेकॉर्डिंग चालू करायचे?';

  @override
  String get researchConsentBody =>
      'तुम्ही “लेबल लावलेला नमुना रेकॉर्ड करा” निवडल्यावर ते 2 सेकंदांचे रेकॉर्डिंग तुम्ही दिलेल्या लेबलसह या फोनवर खाजगीरित्या ठेवले जाते. “कोणतीही खूण नाही” किंवा “कीड लागली” या लेबलसाठी स्वतः केलेल्या पाहणीने त्याची खात्री व्हायला हवी. काहीही अपलोड होत नाही: तुम्ही डेटासेट फाइल तयार करून ती कोणाला द्यायची ते स्वतः ठरवू शकता. हे कधीही बंद करा; “सगळा इतिहास हटवा” प्रत्येक रेकॉर्डिंग आणि लेबल काढून टाकते.';

  @override
  String get researchConsentAgree => 'मला मान्य आहे, चालू करा';

  @override
  String get settingsSamplesCard => 'प्रत्येक लेबलची संख्या आणि डेटासेट फाइल';

  @override
  String get settingsPrivacy => 'गोपनीयता';

  @override
  String get deleteHistoryTitle => 'सगळा इतिहास हटवा';

  @override
  String get deleteHistoryBody =>
      'आवाज-तपासण्या, पाहण्या आणि त्यांचे फोटो, आठवणी, लेबल लावलेले नमुने आणि ठेवलेली रेकॉर्डिंग काढून टाकते.';

  @override
  String get deleteHistoryConfirmTitle => 'सगळा इतिहास हटवायचा?';

  @override
  String get deleteHistoryConfirmBody =>
      'यामुळे या फोनवरची प्रत्येक आवाज-तपासणी, पाहणी (फोटोसह), आठवण, लेबल लावलेला नमुना आणि ठेवलेले रेकॉर्डिंग हटवले जाईल. तुमच्या नोंदवलेल्या वस्तू, जागा, पिके आणि लॉट तसेच राहतील. हे परत आणता येणार नाही.';

  @override
  String get deleteHistoryConfirmAction => 'इतिहास हटवा';

  @override
  String get deleteHistoryDone => 'सगळा इतिहास हटवला';

  @override
  String deleteHistoryFailed(String detail) {
    return 'इतिहास हटवता आला नाही: $detail';
  }

  @override
  String get settingsOnDevice => 'फोनवरच आवाज-तपासणी';

  @override
  String get engineUnavailable => 'आवाज-तपासणी इंजिनची माहिती मिळत नाही';

  @override
  String get engineModelPresent =>
      'निकाल प्रायोगिक आहेत आणि त्यांची खात्री झालेली नाही.';

  @override
  String get engineNoModel =>
      'कोणतेही मॉडेल बसवलेले नाही, त्यामुळे आवाज-तपासणी फक्त रेकॉर्डिंगचा दर्जा पाहते आणि निकालात “निकाल आला नाही” दिसते.';

  @override
  String get settingsFooter =>
      'सगळी आवाज-तपासणी याच फोनवर होते. Kernel इंटरनेटशिवाय चालते आणि कधीही आवाज अपलोड करत नाही.';

  @override
  String get diagnosticsTitle => 'तांत्रिक माहिती';

  @override
  String get diagnosticsCard =>
      'चाचणीसाठी मॉडेल, प्रोसेसर, सॅम्पल रेट आणि फोनची माहिती';

  @override
  String get diagnosticsSubtitle => 'या फोनवर आवाज-तपासणी इंजिन काय सांगते';

  @override
  String get notMeasured => 'अजून मोजलेले नाही';

  @override
  String get yes => 'हो';

  @override
  String get no => 'नाही';

  @override
  String get diagModelInstalled => 'मॉडेल बसवले आहे';

  @override
  String get diagModelNote => 'मॉडेलबद्दल टीप';

  @override
  String get diagDelegate => 'प्रोसेसर';

  @override
  String get diagAudioTitle => 'आवाज इनपुट';

  @override
  String get diagTargetRate => 'अपेक्षित सॅम्पल रेट';

  @override
  String get diagEffectiveRate => 'प्रत्यक्ष सॅम्पल रेट';

  @override
  String get diagDeviceRate => 'फोनचा इनपुट रेट';

  @override
  String get diagAudioSource => 'आवाजाचा स्रोत';

  @override
  String get diagDeviceTitle => 'फोन';

  @override
  String get diagOs => 'अँड्रॉइड';

  @override
  String get diagAppVersion => 'अॅप आवृत्ती';

  @override
  String get diagLogRowTitle => 'डिव्हाइस-लॉगची ओळ';

  @override
  String get diagLogRowBody =>
      'ही ओळ docs/device-validation.md मधल्या डिव्हाइस लॉगमध्ये चिकटवा आणि तुमचे नाव लिहा.';

  @override
  String get diagCopyRow => 'डिव्हाइस-लॉगची ओळ कॉपी करा';

  @override
  String get diagCopied => 'ओळ कॉपी झाली';

  @override
  String get qrTitle => 'QR लेबलवरून उघडा';

  @override
  String get qrInstructions => 'लेबल चौकटीच्या आत धरा. वाचताच ते उघडेल.';

  @override
  String get qrNotKernel =>
      'हा QR कोड Kernel चे पोत्याचे लेबल नाही. Kernel मधून छापलेल्या लेबलकडे कॅमेरा धरा.';

  @override
  String get qrUnknownItem => 'हे लेबल अशा पोत्याचे आहे जे या फोनवर नाही.';

  @override
  String qrLookupFailed(String detail) {
    return 'पोते उघडता आले नाही: $detail';
  }

  @override
  String get qrScanAnother => 'दुसरे लेबल वाचा';

  @override
  String get qrRationaleTitle => 'पोत्याची लेबले वाचायला कॅमेरा वापरा';

  @override
  String get qrRationaleBody =>
      'Kernel कॅमेरा फक्त पोत्यांची QR लेबले वाचायला आणि पाहणीचे फोटो काढायला वापरते. लेबले याच फोनवर वाचली जातात; कॅमेऱ्याची चित्रे सेव्ह किंवा अपलोड होत नाहीत.';

  @override
  String get qrAllowCamera => 'कॅमेऱ्याला परवानगी द्या';

  @override
  String get qrCameraDenied =>
      'कॅमेऱ्याला परवानगी दिली नाही. तरीही तुम्ही तुमच्या साठ्यातून पोती उघडू शकता.';

  @override
  String get qrCameraBlocked =>
      'Kernel साठी कॅमेरा बंद केला आहे. फोनची सेटिंग्ज उघडा, परवानग्या निवडा, मग कॅमेऱ्याला परवानगी द्या.';

  @override
  String get qrPrivacyNote =>
      'लेबल याच फोनवर वाचले जाते. काहीही अपलोड होत नाही.';

  @override
  String get labelSampleTitle => 'संशोधन रेकॉर्डिंगला लेबल लावा';

  @override
  String get labelRuleNote =>
      'या पोत्याच्या स्वतः केलेल्या पाहणीने खात्री झाली असेल तेव्हाच “कोणतीही खूण नाही” किंवा “कीड लागली” निवडा. नाहीतर “माहीत नाही” निवडा.';

  @override
  String get labelCleanHelp => 'पाहणीत कीड आढळली नाही, याची खात्री झाली';

  @override
  String get labelCleanNeedsInspection => 'कीड न आढळलेली या पोत्याची पाहणी हवी';

  @override
  String get labelInfestedHelp => 'पाहणीत कीड आढळली, याची खात्री झाली';

  @override
  String get labelInfestedNeedsInspection =>
      'कीड आढळलेली या पोत्याची पाहणी हवी';

  @override
  String get labelUnknownHelp =>
      'कोणत्याही पाहणीने या पोत्याच्या स्थितीची खात्री होत नाही';

  @override
  String get labelNeedsEvidence =>
      '“कोणतीही खूण नाही” आणि “कीड लागली” साठी त्याच्याशी जुळणारी या पोत्याची पाहणी हवी. “माहीत नाही” निवडा किंवा आधी पाहणीची नोंद करा.';

  @override
  String get evidenceTitle => 'खात्री देणारी पाहणी';

  @override
  String get evidenceBody => 'या रेकॉर्डिंगसाठी केलेली पाहणी निवडा.';

  @override
  String get sackMaterialField => 'पोते किंवा डबा कशाचा आहे';

  @override
  String get notRecorded => 'नोंद नाही';

  @override
  String get environmentField => 'आजूबाजूची परिस्थिती';

  @override
  String get environmentHelper =>
      'कुठे रेकॉर्ड केले, उदा. शांत खोली किंवा पंखे चालू असलेले गोदाम';

  @override
  String get envQuietRoom => 'शांत खोली';

  @override
  String get envWarehouse => 'गोदाम';

  @override
  String get envFansOn => 'पंखे किंवा यंत्रे चालू';

  @override
  String get envOutdoors => 'बाहेर मोकळ्यावर';

  @override
  String get materialJute => 'ज्यूट (ताग)';

  @override
  String get materialWovenPp => 'प्लास्टिकचे विणलेले पोते (PP)';

  @override
  String get materialCotton => 'सुती';

  @override
  String get materialPlastic => 'प्लास्टिकचा डबा';

  @override
  String get materialMetal => 'धातूचा डबा';

  @override
  String get materialOther => 'इतर';

  @override
  String get sampleSave => 'लेबल लावलेला नमुना सेव्ह करा';

  @override
  String get sampleSaved => 'लेबल लावलेला नमुना या फोनवर सेव्ह झाला';

  @override
  String sampleRejected(String detail) {
    return 'लेबल सेव्ह झाले नाही: $detail';
  }

  @override
  String get sampleUnusableRetry =>
      'हे रेकॉर्डिंग वापरण्याजोगे नव्हते, म्हणून त्याला लेबल लावता येणार नाही. शांत जागी पुन्हा रेकॉर्ड करा.';

  @override
  String get sampleUnusableNotKept =>
      'या रेकॉर्डिंगचा आवाज ठेवला गेला नाही, म्हणून त्याला लेबल लावता येणार नाही.';

  @override
  String get sampleRecordAgain => 'पुन्हा रेकॉर्ड करा';

  @override
  String get samplesTitle => 'संशोधन नमुने';

  @override
  String samplesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'या फोनवर $count लेबल लावलेली रेकॉर्डिंग',
      one: 'या फोनवर 1 लेबल लावलेले रेकॉर्डिंग',
      zero: 'अजून लेबल लावलेले रेकॉर्डिंग नाही',
    );
    return '$_temp0';
  }

  @override
  String get samplesResearchOff =>
      'संशोधन रेकॉर्डिंग मोड बंद आहे. नवीन नमुने रेकॉर्ड करायला सेटिंग्जमध्ये ते चालू करा.';

  @override
  String get samplesEmpty => 'अजून लेबल लावलेले नमुने नाहीत';

  @override
  String get samplesEmptyDetail =>
      'संशोधन मोड चालू ठेवून एखादे पोते उघडा आणि “लेबल लावलेला नमुना रेकॉर्ड करा” निवडा.';

  @override
  String get datasetTitle => 'प्रशिक्षण डेटासेट';

  @override
  String get datasetBody =>
      'ठेवलेल्या रेकॉर्डिंगची एक ZIP आणि त्यांच्या लेबलची एक CSV, याच फोनवर तयार होते. ती कुठे पाठवायची ते तुम्ही ठरवता; Kernel ती कधीही अपलोड करत नाही.';

  @override
  String get datasetExport => 'डेटासेट फाइल तयार करा';

  @override
  String datasetExportFailed(String detail) {
    return 'डेटासेट तयार करता किंवा पाठवता आला नाही. $detail';
  }

  @override
  String sampleLabelChip(String label) {
    return 'लेबल: $label';
  }

  @override
  String get sampleConfirmed => 'पाहणीने खात्री झाली';

  @override
  String get inspectionTitle => 'स्वतः केलेली पाहणी';

  @override
  String get saveInspection => 'पाहणी सेव्ह करा';

  @override
  String get inspectionSaved => 'पाहणी सेव्ह झाली';

  @override
  String get aiPanelTitle => 'AI चा अंदाज (खात्री नाही)';

  @override
  String get aiPanelLoading => 'जोडलेली आवाज-तपासणी उघडत आहे…';

  @override
  String get aiPanelNoScan =>
      'कोणतीही आवाज-तपासणी जोडलेली नाही. ही पाहणी स्वतंत्र आहे.';

  @override
  String scannedAt(String when) {
    return 'आवाज-तपासणी $when';
  }

  @override
  String get aiPanelNotUsed => 'तुमचा निकाल भरायला हे वापरले नाही';

  @override
  String get findingPanelTitle => 'तुमचा खात्रीचा निकाल';

  @override
  String get findingPanelBody =>
      'धान्य तपासताना तुम्ही स्वतः जे पाहिले ते. हे AI च्या अंदाजापासून वेगळे ठेवले जाते.';

  @override
  String get findingMissing => 'तुम्हाला काय आढळले ते निवडा';

  @override
  String get inspectorField => 'पाहणी करणाऱ्याचे नाव';

  @override
  String get validationInspector => 'पाहणी कोणी केली ते लिहा';

  @override
  String get inspectionDateField => 'पाहणीची तारीख';

  @override
  String get observationsField => 'काय दिसले';

  @override
  String get observationsHelper => 'तुम्ही काय पाहिले, कुठे आणि किती';

  @override
  String get assigneeFieldOptional => 'पुढची पाहणी कोणाकडे सोपवायची (ऐच्छिक)';

  @override
  String get followUpStatusTitle => 'पुढच्या पाहणीची स्थिती';

  @override
  String get photosTitle => 'पुराव्याचे फोटो (ऐच्छिक)';

  @override
  String get photosBody =>
      'फोटो या पाहणीसोबत याच फोनवर खाजगीरित्या राहतात. ते तुम्ही जे पाहिले त्याचा पुरावा आहेत, आवाज-तपासणीचे निकाल नाहीत, आणि कधीही अपलोड होत नाहीत.';

  @override
  String get photoTake => 'फोटो काढा';

  @override
  String get photoPick => 'गॅलरीतून निवडा';

  @override
  String get cameraDeniedPhoto =>
      'कॅमेरा बंद आहे. पुराव्याचे फोटो काढायला फोनच्या सेटिंग्जमध्ये परवानगी द्या.';

  @override
  String photoFailed(String detail) {
    return 'फोटो जोडता आला नाही: $detail';
  }

  @override
  String get filterAll => 'सर्व';

  @override
  String get filterNoMatch => 'या फिल्टरनुसार कोणतीही उघडी पाहणी नाही.';

  @override
  String get batchSetupTitle => 'खोली किंवा थप्पी निवडा';

  @override
  String get batchSetupSubtitle =>
      'Kernel तुम्हाला तिथल्या पोत्यांकडे एकेक करून नेते.';

  @override
  String get batchSequentialNote =>
      'प्रत्येक पोत्याचे एक रेकॉर्डिंग. Kernel कधीही अनेक पोत्यांची एकाच वेळी आवाज-तपासणी करत नाही.';

  @override
  String get batchNoPlaces => 'अजून खोल्या किंवा थप्प्या नाहीत';

  @override
  String get batchNoPlacesDetail =>
      'एक गोदाम त्याच्या खोल्या आणि थप्प्यांसह जोडा, मग त्यात पोत्यांची नोंद करा.';

  @override
  String batchPlaceSubtitle(String type, int total, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total पोती',
      one: '1 पोते',
    );
    return '$type · $_temp0 · $needScan ची आवाज-तपासणी बाकी';
  }

  @override
  String batchIntroSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पोती, एकेक करून',
      one: '1 पोते, एकेक करून',
      zero: 'तपासायला पोते नाही',
    );
    return '$_temp0';
  }

  @override
  String get batchSkipToday => 'आज तपासलेली पोती वगळा';

  @override
  String get batchSkipTodayBody =>
      'ज्या पोत्यांचे आजचे रेकॉर्डिंग आधीच आहे ती वगळा.';

  @override
  String batchWalkLine(int position, String label, String grain) {
    return '$position. $label · $grain';
  }

  @override
  String batchStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पोत्यांनी सुरू करा',
      one: '1 पोत्याने सुरू करा',
    );
    return '$_temp0';
  }

  @override
  String get batchNothingToWalk =>
      'इथल्या प्रत्येक पोत्याची वापरण्याजोगी आवाज-तपासणी आधीच आहे किंवा आज तपासणी झाली आहे.';

  @override
  String batchProgress(int position, int total) {
    return '$total पैकी पोते $position';
  }

  @override
  String get batchSkipSack => 'हे पोते वगळा';

  @override
  String get batchStop => 'फेरी थांबवा';

  @override
  String batchNextIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds सेकंदांत पुढचे पोते',
      one: '1 सेकंदात पुढचे पोते',
    );
    return '$_temp0';
  }

  @override
  String batchSummaryIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds सेकंदांत सारांश',
      one: '1 सेकंदात सारांश',
    );
    return '$_temp0';
  }

  @override
  String get batchNextSack => 'पुढचे पोते';

  @override
  String get batchFinish => 'संपवा';

  @override
  String get batchRetrySack => 'हे पोते पुन्हा रेकॉर्ड करा';

  @override
  String get batchSummaryTitle => 'फेरीचा सारांश';

  @override
  String batchSummarySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'या फेरीत $count पोती',
      one: 'या फेरीत 1 पोते',
    );
    return '$_temp0';
  }

  @override
  String get batchStatRecorded => 'रेकॉर्ड झाली';

  @override
  String get batchStatSkipped => 'वगळली';

  @override
  String get batchStatRetry => 'पुन्हा करायची';

  @override
  String get rankedTitle => 'क्रमाने';

  @override
  String rankLabel(int rank) {
    return '#$rank';
  }

  @override
  String get queueSuggestionNote =>
      'हा क्रम फक्त आधी काय तपासावे याची सूचना आहे. कोणताही निर्णय घेण्यापूर्वी स्वतः उघडून पाहणी करा.';

  @override
  String get queueNothingRanked =>
      'अजून कोणत्याही वस्तूचा वापरण्याजोगा मॉडेल निकाल नाही, त्यामुळे काहीच क्रमात नाही. निकाल नसलेल्या वस्तू “आवाज-तपासणी बाकी” मध्ये आहेत.';

  @override
  String get queueNothingRankedShort => 'अजून काहीच क्रमात नाही';

  @override
  String needsScanTitle(int count) {
    return 'आवाज-तपासणी बाकी ($count)';
  }

  @override
  String get needsScanChip => 'आवाज-तपासणी बाकी';

  @override
  String get needsScanEmpty => 'प्रत्येक वस्तूची वापरण्याजोगी आवाज-तपासणी आहे.';

  @override
  String get saveHarvest => 'पीक सेव्ह करा';

  @override
  String get harvestNameField => 'पिकाचे नाव';

  @override
  String get harvestNameHelper => 'उदा. “रब्बी गहू 2026”';

  @override
  String get harvestedOnField => 'काढणीची तारीख';

  @override
  String get notesFieldOptional => 'टीप (ऐच्छिक)';

  @override
  String get harvestAppBar => 'पीक';

  @override
  String get harvestNotFound => 'हे पीक या फोनवर सापडले नाही.';

  @override
  String get harvestAddSack => 'या पिकात पोत्याची नोंद करा';

  @override
  String get harvestSacksTitle => 'या पिकाची पोती';

  @override
  String get harvestSacksEmpty => 'या पिकात अजून पोती नाहीत';

  @override
  String get harvestSacksEmptyDetail =>
      'या पिकातून भरलेल्या पोत्यांची नोंद करा, मग विकण्यापूर्वी त्यांची आवाज-तपासणी करा.';

  @override
  String get preSaleBody =>
      'खरेदीदारासाठी या पिकाच्या पोत्यांचा सारांश. प्रत्येक आवाज-तपासणीसोबत तिची मॉडेल आवृत्ती आणि प्रायोगिक स्थिती दिसते, आणि पाहणीतील खात्रीचे निकाल वेगळे लिहिलेले असतात. हे दर्जाचे प्रमाणपत्र नाही.';

  @override
  String get notScannedYet => 'अजून आवाज-तपासणी झाली नाही';

  @override
  String get lotAppBar => 'लॉट';

  @override
  String get lotNotFound => 'हा लॉट या फोनवर सापडला नाही.';

  @override
  String get supplierNotRecorded => 'पुरवठादाराची नोंद नाही';

  @override
  String get fieldDeclaredQuantity => 'सांगितलेले प्रमाण';

  @override
  String get fieldReceived => 'मिळाल्याची तारीख';

  @override
  String get fieldScreened => 'तपासली';

  @override
  String get screeningStatusTitle => 'तपासणीची स्थिती';

  @override
  String get screeningStatusBody =>
      'आवाज-तपासण्या आणि उघडून केलेली पाहणी बघून हे तुम्ही ठरवता. आवाज-तपासणी हे कधीही बदलत नाही, आणि Kernel कधीही कोणताही लॉट स्वीकारत किंवा नाकारत नाही.';

  @override
  String currentStatus(String status) {
    return 'सध्या: $status';
  }

  @override
  String get lotSacksTitle => 'या लॉटमधली पोती';

  @override
  String get lotSacksEmpty => 'या लॉटमध्ये अजून पोती नाहीत';

  @override
  String get lotSacksEmptyAction => 'या लॉटमध्ये पोत्याची नोंद करा';

  @override
  String get sampleScansTitle => 'नमुना आवाज-तपासण्या';

  @override
  String get sampleScansBody =>
      'या मालातील पोत्यांची एकेक करून आवाज-तपासणी करा. प्रत्येक निकाल हा खात्री न झालेला मॉडेलचा अंदाज आहे आणि त्याने लॉटची स्थिती बदलत नाही.';

  @override
  String get sampleScansStart => 'नमुना आवाज-तपासण्या सुरू करा';

  @override
  String get physicalChecksTitle => 'उघडून पाहणी';

  @override
  String get physicalChecksBody =>
      'प्रत्येक पोते उघडून आत पाहा, मग जे आढळले त्याची नोंद करा. तुमचे निकाल आवाज-तपासणीपासून वेगळे ठेवले जातात.';

  @override
  String get recordPhysicalCheck => 'उघडून पाहणीची नोंद करा';

  @override
  String get noPhysicalCheckYet => 'अजून उघडून पाहणी झाली नाही';

  @override
  String lotSummaryTitle(String code) {
    return 'लॉट $code चा सारांश अहवाल';
  }

  @override
  String get lotSummaryBody =>
      'या फोनवरील नोंदींमधून: मॉडेलच्या माहितीसह नमुना आवाज-तपासण्या, आणि उघडून पाहणीचे निकाल वेगळे. तुमच्या स्वतःच्या निर्णयाला मदत म्हणून हे वापरा.';

  @override
  String savedLot(String code) {
    return 'लॉट $code सेव्ह झाला';
  }

  @override
  String get saveLot => 'लॉट सेव्ह करा';

  @override
  String get lotCodeField => 'लॉट कोड';

  @override
  String get lotCodeHelper => 'मालाच्या पावतीवरचा क्रमांक';

  @override
  String get validationLotCode => 'लॉट कोड लिहा';

  @override
  String get supplierFieldOptional => 'पुरवठादाराचे नाव (ऐच्छिक)';

  @override
  String get declaredQuantityField => 'सांगितलेले प्रमाण';

  @override
  String get receivedOnField => 'मिळाल्याची तारीख';

  @override
  String shareSubject(String title) {
    return 'Kernel $title';
  }

  @override
  String exportFailed(String detail) {
    return 'अहवाल तयार करता किंवा पाठवता आला नाही. $detail';
  }

  @override
  String get exportPanelBody =>
      'फक्त या फोनवर ठेवलेल्या नोंदींमधून तयार होतो. प्रत्येक आवाज-तपासणीसोबत तिची मॉडेल आवृत्ती आणि प्रायोगिक स्थिती दिसते. AI चे अंदाज आणि पाहणीतील खात्रीचे निकाल वेगवेगळे लिहिले जातात.';

  @override
  String get exportCsv => 'CSV तयार करा';

  @override
  String get exportPdf => 'PDF तयार करा';

  @override
  String get exportLabelsPdf => 'लेबलची PDF तयार करा';

  @override
  String exportSavedAt(String path) {
    return 'या फोनवर सेव्ह झाले: $path';
  }

  @override
  String get sackLabelsTitle => 'पोत्यांची लेबले छापा';

  @override
  String get sackLabelsBody =>
      'या पोत्यांच्या QR लेबलची एक PDF. ती छापा आणि प्रत्येक लेबल त्याच्या पोत्यावर चिकटवा; लेबल वाचल्यावर Kernel मध्ये ते पोते उघडते.';

  @override
  String get reportsTitle => 'अहवाल';

  @override
  String get reportsFarmerHint =>
      'एखाद्या पिकाचा विक्रीआधीचा सारांश त्या पिकाच्या पानावर आहे.';

  @override
  String get reportsBuyerHint =>
      'लॉटचा सारांश अहवाल प्रत्येक लॉटच्या पानावर आहे.';

  @override
  String get recentScans => 'अलीकडच्या आवाज-तपासण्या';

  @override
  String get recentScansEmpty =>
      'अजून आवाज-तपासणी नाही. तुम्ही रेकॉर्ड केलेल्या तपासण्या इथे दिसतील.';

  @override
  String get inventorySubtitleFarmer => 'तुमची पिके आणि नोंदवलेली पोती';

  @override
  String get inventorySubtitleHousehold =>
      'तुमचे धान्याचे डबे आणि ते कुठे ठेवले आहेत';

  @override
  String get inventorySubtitleFpo => 'गोदामे, खोल्या, थप्प्या आणि पोती';

  @override
  String get inventorySubtitleBuyer => 'येणारे लॉट आणि त्यांची पोती';

  @override
  String get newHarvestAction => 'नवीन पीक';

  @override
  String registerItemAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डबा जोडा',
      'other': 'पोत्याची नोंद करा',
    });
    return '$_temp0';
  }

  @override
  String get addPlace => 'जागा जोडा';

  @override
  String get addLocation => 'जागा जोडा';

  @override
  String itemsSectionTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डबे',
      'other': 'पोती',
    });
    return '$_temp0';
  }

  @override
  String get lotsSectionEmpty =>
      'अजून लॉट नाहीत. एक जोडायला आलेल्या मालाची नोंद करा.';

  @override
  String get placesTitle => 'जागा';

  @override
  String get locationsTitle => 'जागा';

  @override
  String get placesEmpty =>
      'अजून जागा नाहीत. डबे कुठे ठेवले आहेत ते सांगायला एक जोडा.';

  @override
  String get locationsEmpty =>
      'अजून गोदाम नाही. एक जोडा, मग त्याच्या खोल्या आणि थप्प्या.';

  @override
  String get harvestsSectionEmpty =>
      'अजून पिके नाहीत. त्याची पोती एकत्र ठेवायला आणि विक्रीआधीचा सारांश बनवायला एक पीक तयार करा.';

  @override
  String harvestCardSubtitle(String grain, String date) {
    return '$grain · काढणी $date';
  }

  @override
  String sackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पोती',
      one: '1 पोते',
      zero: 'अजून पोती नाहीत',
    );
    return '$_temp0';
  }

  @override
  String get itemDetailAppBar => 'तपशील';

  @override
  String get itemNotFound => 'ही वस्तू या फोनवर सापडली नाही.';

  @override
  String archiveItemMenu(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डबा बाजूला ठेवा',
      'other': 'पोते बाजूला ठेवा',
    });
    return '$_temp0';
  }

  @override
  String get archivedSnack => 'बाजूला ठेवले. त्याचा इतिहास या फोनवर राहील.';

  @override
  String get archivedItemNotice =>
      'याद्या, रांगा आणि नवीन अहवालांत दिसणार नाही. त्याचा आवाज-तपासणी इतिहास आणि पाहण्या तशाच राहतात.';

  @override
  String get restoreAction => 'परत आणा';

  @override
  String scanThisItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'या डब्याची आवाज-तपासणी करा',
      'other': 'या पोत्याची आवाज-तपासणी करा',
    });
    return '$_temp0';
  }

  @override
  String get setReminderAction => 'पुन्हा तपासणीची आठवण लावा';

  @override
  String get researchRecordTitle => 'लेबल लावलेला नमुना रेकॉर्ड करा';

  @override
  String get researchRecordSubtitle =>
      'संशोधन मोड: 2 सेकंदांचे रेकॉर्डिंग ठेवा आणि प्रशिक्षण डेटासाठी त्याला लेबल लावा';

  @override
  String get fieldQuantity => 'प्रमाण';

  @override
  String get fieldStoredSince => 'कधीपासून साठवले';

  @override
  String storedSinceValue(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिवस',
      one: '1 दिवस',
    );
    return '$date ($_temp0)';
  }

  @override
  String get fieldLocation => 'जागा';

  @override
  String get fieldLot => 'लॉट';

  @override
  String get fieldHarvest => 'पीक';

  @override
  String nameWithType(String name, String type) {
    return '$name ($type)';
  }

  @override
  String registeredAs(String role) {
    return '$role म्हणून नोंद';
  }

  @override
  String get scanHistoryTitle => 'आवाज-तपासणीचा इतिहास';

  @override
  String get scanHistoryAppendOnly =>
      'प्रत्येक आवाज-तपासणी जशी रेकॉर्ड झाली तशीच ठेवली जाते. नवीन तपासणी जुनी कधीही बदलत नाही.';

  @override
  String scanHistoryEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'अजून आवाज-तपासणी नाही. एक रेकॉर्ड करायला “या डब्याची आवाज-तपासणी करा” दाबा.',
      'other': 'अजून आवाज-तपासणी नाही. एक रेकॉर्ड करायला “या पोत्याची आवाज-तपासणी करा” दाबा.',
    });
    return '$_temp0';
  }

  @override
  String get inspectionsTitle => 'पाहण्या';

  @override
  String get inspectionsEmpty => 'अजून पाहणीची नोंद नाही.';

  @override
  String get remindersTitle => 'आठवणी';

  @override
  String get remindersEmpty => 'कोणतीही आठवण लावलेली नाही.';

  @override
  String recheckOn(String when) {
    return '$when ला पुन्हा तपासणी';
  }

  @override
  String get reminderMarkDone => 'झाले म्हणून खूण करा';

  @override
  String get reminderCancel => 'आठवण रद्द करा';

  @override
  String get assignDialogTitle => 'पाहणी सोपवा';

  @override
  String get assignDialogLabel => 'कोणाकडे सोपवली';

  @override
  String get assignDialogHelper => 'पुढची पाहणी कोण करेल';

  @override
  String get assignClear => 'सोपवणे काढा';

  @override
  String savedNamed(String name) {
    return '$name सेव्ह झाले';
  }

  @override
  String saveFailed(String detail) {
    return 'सेव्ह करता आले नाही: $detail';
  }

  @override
  String saveItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डबा सेव्ह करा',
      'other': 'पोते सेव्ह करा',
    });
    return '$_temp0';
  }

  @override
  String itemLabelField(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डब्याचे लेबल',
      'other': 'पोत्याचे लेबल',
    });
    return '$_temp0';
  }

  @override
  String itemLabelHelper(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डब्यावर लिहिलेले नाव',
      'other': 'पोत्यावर लिहिलेले नाव',
    });
    return '$_temp0';
  }

  @override
  String get validationLabel => 'लेबल लिहा';

  @override
  String get grainTypeField => 'धान्याचा प्रकार';

  @override
  String get validationGrain => 'धान्याचा प्रकार लिहा';

  @override
  String get quantityField => 'प्रमाण';

  @override
  String get unitField => 'एकक';

  @override
  String get storageDateField => 'साठवणीची तारीख';

  @override
  String get harvestFieldOptional => 'पीक (ऐच्छिक)';

  @override
  String get harvestFieldNone =>
      'अजून पिके नाहीत. “माझे धान्य” मधून एक तयार करा.';

  @override
  String get none => 'काहीही नाही';

  @override
  String get locationFieldOptional => 'जागा (ऐच्छिक)';

  @override
  String locationFieldNone(String where) {
    return 'अजून जागा नाहीत. तुम्ही त्या $where मधून जोडू शकता.';
  }

  @override
  String get lotFieldOptional => 'लॉट (ऐच्छिक)';

  @override
  String get lotFieldNone => 'अजून लॉटची नोंद नाही.';

  @override
  String get locationAppBar => 'जागा';

  @override
  String get locationNotFound => 'ही जागा या फोनवर सापडली नाही.';

  @override
  String get archivedLocationNotice =>
      'ही जागा बाजूला ठेवली आहे. तिथली पोती आणि त्यांचा इतिहास तसाच राहतो.';

  @override
  String registerHere(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'इथे डबा जोडा',
      'other': 'इथे पोत्याची नोंद करा',
    });
    return '$_temp0';
  }

  @override
  String get addInside => 'आत जोडा';

  @override
  String get batchHere => 'इथे एकेक करून तपासणी';

  @override
  String get insideTitle => 'आत';

  @override
  String get insideEmpty => 'या जागेच्या आत अजून काही नाही.';

  @override
  String itemsHereTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'इथले डबे',
      'other': 'इथली पोती',
    });
    return '$_temp0';
  }

  @override
  String itemsHereEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'इथे अजून डबे ठेवलेले नाहीत.',
      'other': 'इथे अजून पोती ठेवलेली नाहीत.',
    });
    return '$_temp0';
  }

  @override
  String get saveLocation => 'जागा सेव्ह करा';

  @override
  String get typeField => 'प्रकार';

  @override
  String get nameField => 'नाव';

  @override
  String get validationName => 'नाव लिहा';

  @override
  String get parentFieldOptional => 'कशाच्या आत (ऐच्छिक)';

  @override
  String get parentFieldHelper => 'उदा. गोदामाच्या आतली खोली';

  @override
  String get parentTopLevel => 'कशाच्याही आत नाही (सर्वात वर)';

  @override
  String get roleSelectTitle => 'तुमची भूमिका निवडा';

  @override
  String get roleSelectSubtitle => 'एक अॅप. चार प्रकारची कामे.';

  @override
  String get roleCurrent => 'सध्याची';

  @override
  String get roleSwitchKeepsRecords =>
      'भूमिका बदलली तरी या फोनवरची प्रत्येक नोंद राहते. तुम्ही कधीही परत बदलू शकता.';

  @override
  String roleSaveFailed(String detail) {
    return 'तुमची भूमिका सेव्ह करता आली नाही: $detail';
  }

  @override
  String startDataError(String detail) {
    return 'Kernel ला या फोनवरचा स्वतःचा डेटा उघडता आला नाही. कृपया अॅप पुन्हा सुरू करा.\n\nतपशील: $detail';
  }

  @override
  String get onboardingSkip => 'वगळा';

  @override
  String get onboardingBack => 'मागे';

  @override
  String get onboardingNext => 'पुढे';

  @override
  String onboardingStep(int step, int total) {
    return '$total पैकी पायरी $step';
  }

  @override
  String get onboardingPrivacyTitle => 'आवाज तुमच्या फोनवरच राहतो';

  @override
  String get onboardingPrivacy1 =>
      'Kernel धान्याचा आवाज 2 सेकंद ऐकते आणि तो इथेच या फोनवर तपासते.';

  @override
  String get onboardingPrivacy2 =>
      'काहीही अपलोड होत नाही. खाते नाही, क्लाउड नाही, आणि सगळे इंटरनेटशिवाय चालते.';

  @override
  String get onboardingPrivacy3 =>
      'तुम्ही सेटिंग्जमध्ये ठेवायचे निवडले नाही तर तपासणीनंतर रेकॉर्डिंग हटवली जातात.';

  @override
  String get onboardingHowTitle => 'आवाज-तपासणी कशी करायची';

  @override
  String get onboardingHow1 =>
      'फोन पोत्यावर किंवा डब्यावर सपाट टेकवा, माइक त्याला टेकलेला असू द्या.';

  @override
  String get onboardingHow2 =>
      'शांत खोली निवडा. बोलणे थांबवा आणि जमल्यास पंखे बंद करा.';

  @override
  String get onboardingHow3 => 'Kernel ऐकत असताना 2 सेकंद अजिबात हलू नका.';

  @override
  String get onboardingHow4 =>
      'निकाल प्रायोगिक आहेत. निर्णय घेण्यापूर्वी नेहमी धान्याची स्वतः पाहणी करा.';

  @override
  String get onboardingRoleTitle => 'तुमची भूमिका निवडा';

  @override
  String get heroEyebrowListen => 'तुमच्या धान्याचा आवाज ऐका';

  @override
  String get heroStartScan => 'आवाज-तपासणी सुरू करा';

  @override
  String get heroStartBatch => 'एकेक करून तपासणी सुरू';

  @override
  String get loading => 'उघडत आहे…';

  @override
  String get farmerHomeTitle => 'शेतकऱ्याचे पान';

  @override
  String farmerHomeHarvestSubtitle(String name) {
    return 'पीक: $name';
  }

  @override
  String get farmerHeroTitle => 'धान्याची आवाज-तपासणी';

  @override
  String get farmerHeroSubtitle =>
      'सांगितल्याप्रमाणे 2 सेकंदांचे रेकॉर्डिंग सुरू करा';

  @override
  String get farmerEmptyDetail =>
      'आवाज-तपासणी आणि हिशोब सुरू करायला एका पोत्याची नोंद करा.';

  @override
  String registeredSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नोंदवलेली पोती',
      one: '1 नोंदवलेले पोते',
    );
    return '$_temp0';
  }

  @override
  String get noFollowUps => 'पुढची कोणतीही पाहणी बाकी नाही';

  @override
  String sacksRequireFollowUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पोत्यांची पुढची पाहणी करायला हवी',
      one: '1 पोत्याची पुढची पाहणी करायला हवी',
    );
    return '$_temp0';
  }

  @override
  String get harvestsTitle => 'पिके';

  @override
  String get harvestsEmptyCard =>
      'विक्रीआधीच्या अहवालासाठी पोती एकत्र ठेवायला पीक तयार करा';

  @override
  String harvestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पिके · सर्वात नवीन उघडा',
      one: '1 पीक · सर्वात नवीन उघडा',
    );
    return '$_temp0';
  }

  @override
  String get queueTitle => 'पाहणीची रांग';

  @override
  String get queueCardSubtitle => 'कोणती पोती आधी तपासायची';

  @override
  String get preSaleCardSubtitle => 'तुमच्या नोंदींमधून सारांश तयार करा';

  @override
  String preSaleCardHarvest(String name) {
    return '$name चा विक्रीआधीचा सारांश';
  }

  @override
  String get householdHomeTitle => 'घरचा साठा';

  @override
  String get householdHomeSubtitle => 'घरच्या धान्याचा हिशोब';

  @override
  String get householdHeroTitle => 'डब्याची आवाज-तपासणी करा';

  @override
  String get householdHeroSubtitle => 'धान्याची स्थिती नोंदवा';

  @override
  String get householdEmptyDetail =>
      'किती दिवस साठवले आहे ते पाहायला धान्याचा डबा जोडा.';

  @override
  String get remindersCardTitle => 'पाहणीच्या आठवणी';

  @override
  String get remindersCardEmpty =>
      'कोणतीही आठवण ठरवलेली नाही. लावायला एखादा डबा उघडा.';

  @override
  String remindersScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आठवणी ठरवल्या',
      one: '1 आठवण ठरवली',
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
      other: '$days दिवस साठवले',
      one: '1 दिवस साठवले',
    );
    return '$_temp0';
  }

  @override
  String get reviewNeverScanned => 'अजून आवाज-तपासणी झाली नाही — पाहण्याची वेळ';

  @override
  String reviewDueSince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'पाहण्याची वेळ — शेवटची आवाज-तपासणी $days दिवसांपूर्वी',
      one: 'पाहण्याची वेळ — शेवटची आवाज-तपासणी 1 दिवसापूर्वी',
    );
    return '$_temp0';
  }

  @override
  String reviewNextIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'पुढची पाहणी $days दिवसांत',
      one: 'पुढची पाहणी 1 दिवसात',
    );
    return '$_temp0';
  }

  @override
  String get reviewDue => 'पाहण्याची वेळ';

  @override
  String reminderOn(String date) {
    return 'आठवण $date';
  }

  @override
  String get recheckAction => 'पुन्हा तपासा';

  @override
  String get remindMeAction => 'आठवण करून द्या';

  @override
  String get reminderSheetTitle => 'पुन्हा तपासणीची आठवण लावा';

  @override
  String reminderSheetSubtitle(String label) {
    return '$label साठी. Kernel तुम्हाला याच फोनवर आठवण करून देईल.';
  }

  @override
  String reminderInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिवसांत',
      one: '1 दिवसात',
    );
    return '$_temp0';
  }

  @override
  String get reminderDateLabel => 'तारीख';

  @override
  String get reminderTimeLabel => 'वेळ';

  @override
  String get reminderOnDeviceNote =>
      'आठवण याच फोनवर ठरवली जाते आणि इंटरनेटशिवाय चालते.';

  @override
  String get reminderSave => 'आठवण सेव्ह करा';

  @override
  String get reminderPastError => 'पुढची एखादी वेळ निवडा.';

  @override
  String get reminderSet => 'आठवण लावली';

  @override
  String get reminderSetNotificationsOff =>
      'आठवण सेव्ह झाली. सूचना बंद आहेत, त्यामुळे ती फक्त अॅपमध्येच दिसेल.';

  @override
  String reminderFailed(String detail) {
    return 'आठवण लावता आली नाही: $detail';
  }

  @override
  String get fpoHomeTitle => 'गोदामाचा आढावा';

  @override
  String get fpoHomeSubtitle => 'गोदामे, खोल्या आणि थप्प्या';

  @override
  String get fpoEmptyDetail =>
      'पोत्यांची नोंद करा, मग एकेक करून त्यांची आवाज-तपासणी करा म्हणजे पाहणीची रांग तयार होईल.';

  @override
  String sacksScannedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आज $count पोत्यांची आवाज-तपासणी झाली',
      one: 'आज 1 पोत्याची आवाज-तपासणी झाली',
    );
    return '$_temp0';
  }

  @override
  String queueSummary(int flagged, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      needScan,
      locale: localeName,
      other: '$needScan पोत्यांची आवाज-तपासणी बाकी',
      one: '1 पोत्याची आवाज-तपासणी बाकी',
    );
    return '$flagged कडे लक्ष द्या · $_temp0';
  }

  @override
  String get assignedTitle => 'सोपवलेल्या पाहण्या';

  @override
  String get assignedNone => 'कोणतीही उघडी पाहणी नाही';

  @override
  String inspectionsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पाहण्या उघड्या',
      one: '1 पाहणी उघडी',
    );
    return '$_temp0';
  }

  @override
  String get fpoAddLocationTitle => 'गोदाम, खोली किंवा थप्पी जोडा';

  @override
  String get fpoAddLocationSubtitle => 'पोती कुठे साठवली आहेत त्यानुसार मांडा';

  @override
  String get buyerHomeTitle => 'येणारे लॉट';

  @override
  String get buyerHomeSubtitle => 'खरेदीआधी तपासणी';

  @override
  String get heroEyebrowDelivery => 'नवीन माल';

  @override
  String get buyerHeroTitle => 'आलेल्या मालाची नोंद';

  @override
  String get buyerHeroSubtitle => 'पुरवठादार, लॉट, धान्य, प्रमाण';

  @override
  String get buyerHeroAction => 'नोंद करा';

  @override
  String get lotsEmptyMessage => 'अजून लॉट नाहीत';

  @override
  String get lotsEmptyDetail => 'पोती तपासायला आलेल्या मालाची नोंद करा.';

  @override
  String get lotsEmptyAction => 'तुमच्या पहिल्या मालाची नोंद करा';

  @override
  String get buyerReportCardTitle => 'पाहणी अहवाल';

  @override
  String get buyerReportCardSubtitle =>
      'तुमच्या नोंदींमधून लॉट तपासणीचा अहवाल तयार करा';

  @override
  String lotTitle(String code, String grain) {
    return '$code / $grain';
  }

  @override
  String get lotNoSacks => 'या लॉटमध्ये अजून पोत्यांची नोंद नाही';

  @override
  String lotScreenedCount(int screened, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total पोत्यांपैकी',
      one: '1 पोत्यापैकी',
    );
    return '$_temp0 $screened तपासली';
  }

  @override
  String supplierChip(String name) {
    return 'पुरवठादार: $name';
  }

  @override
  String get scanAppBarTitle => 'आवाज-तपासणी';

  @override
  String get guidedScanTitle => 'सांगितल्याप्रमाणे आवाज-तपासणी';

  @override
  String get researchScanTitle => 'लेबल लावलेला नमुना रेकॉर्ड करा';

  @override
  String grainAndLabel(String grain, String label) {
    return '$grain • $label';
  }

  @override
  String get researchScanNoticeTitle => 'संशोधन रेकॉर्डिंग';

  @override
  String get researchScanNotice =>
      'हे 2 सेकंदांचे रेकॉर्डिंग याच फोनवर खाजगीरित्या ठेवले जाते, म्हणजे तुम्ही प्रशिक्षण डेटासाठी त्याला लेबल लावू शकता. हे किडीचा निकाल म्हणून दाखवले जात नाही आणि कधीही अपलोड होत नाही.';

  @override
  String positioningTip(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'फोन डब्यावर दाबून धरा, न हलता शांत राहा',
      'other': 'फोन पोत्यावर दाबून धरा, न हलता शांत राहा',
    });
    return '$_temp0';
  }

  @override
  String positioningTipDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'शांत खोलीत फोन डब्यावर सपाट ठेवा, माइक त्याला टेकलेला असू द्या. 2 सेकंद बोलू नका आणि तो हलवू नका.',
      'other': 'शांत जागी फोन पोत्यावर सपाट ठेवा, माइक त्याला टेकलेला असू द्या. 2 सेकंद बोलू नका आणि पोते हलवू नका.',
    });
    return '$_temp0';
  }

  @override
  String get infoQualityTitle => 'रेकॉर्डिंगचा दर्जा';

  @override
  String get infoQualityBody =>
      'कोणताही निकाल दाखवण्यापूर्वी मागचा गोंगाट, फाटलेला आवाज आणि शांतता तपासली जाते.';

  @override
  String get infoDurationTitle => 'रेकॉर्डिंगचा वेळ';

  @override
  String get infoDurationShort => '2 सेकंद';

  @override
  String infoDurationRate(String khz) {
    return '$khz kHz वर 2 सेकंद';
  }

  @override
  String get infoOnDeviceTitle => 'फोनवरच विश्लेषण';

  @override
  String get infoOnDeviceBody => 'अपलोडची गरज नाही';

  @override
  String infoOnDeviceWithModel(String provenance) {
    return 'अपलोडची गरज नाही. $provenance';
  }

  @override
  String get micDeniedTitle => 'माइकची परवानगी बंद आहे';

  @override
  String get micDeniedSubtitle => 'धान्याचा आवाज ऐकायला Kernel ला माइक हवा.';

  @override
  String get micDeniedPrivacy =>
      'आवाज-तपासणी 2 सेकंदांचा आवाज रेकॉर्ड करून याच फोनवर तपासते. आवाज कधीही अपलोड होत नाही, आणि तुम्ही सेटिंग्जमध्ये रेकॉर्डिंग ठेवायचे निवडले नाही तर तपासणीनंतर हटवला जातो.';

  @override
  String get micDeniedBlocked =>
      'Kernel साठी माइक बंद केला आहे. फोनची सेटिंग्ज उघडा, परवानग्या निवडा, मग माइकला परवानगी द्या.';

  @override
  String get micDeniedAskAgain =>
      'पुढच्या वेळी Kernel विचारेल तेव्हा, किंवा फोनच्या सेटिंग्जमध्ये, तुम्ही परवानगी देऊ शकता.';

  @override
  String get micDeniedStillUsable =>
      'माइकशिवायही तुम्ही वस्तूंची नोंद करू शकता, तुमचा साठा पाहू शकता, उघडून पाहणीची नोंद करू शकता आणि अहवाल तयार करू शकता.';

  @override
  String get actionOpenSettings => 'सेटिंग्ज उघडा';

  @override
  String get actionTryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get actionBrowseInventory => 'साठा पाहा';

  @override
  String get resultAppBarTitle => 'निकाल';

  @override
  String get resultTitle => 'तपासणीचा निकाल';

  @override
  String get scanNotFound => 'ही आवाज-तपासणी या फोनवर सापडली नाही.';

  @override
  String get retryNothingSaved =>
      'या रेकॉर्डिंगसाठी किडीबद्दल काहीही सेव्ह झाले नाही.';

  @override
  String predictedClassLine(String label) {
    return 'मॉडेलचा अंदाज (खात्री नाही): $label';
  }

  @override
  String modelScoreLine(String score) {
    return 'मॉडेल गुण: $score (प्रायोगिक, हा अचूकतेचा आकडा नाही)';
  }

  @override
  String get modelNoteTitleExperimental =>
      'प्रायोगिक मॉडेल — अजून सिद्ध झालेले नाही';

  @override
  String get modelNoteTitle => 'या मॉडेलबद्दल';

  @override
  String modelNoteOtherVersion(String version) {
    return 'या आवाज-तपासणीसाठी मॉडेल $version वापरले होते, जे आता फोनवर नाही. त्याची माहिती या तपासणीसोबत ठेवलेली नाही, म्हणून निकाल प्रायोगिकच समजा.';
  }

  @override
  String get physicalInspectionNote =>
      'आवाजावरून तपासणी प्रायोगिक आहे. साठवण किंवा विक्रीचा कोणताही निर्णय घेण्यापूर्वी स्वतः पाहणी करणे आवश्यक आहे.';

  @override
  String get actionRetry => 'पुन्हा करा';

  @override
  String get actionRecordInspection => 'पाहणीची नोंद करा';

  @override
  String get actionScanAnother => 'दुसरी आवाज-तपासणी';

  @override
  String get recordingDetails => 'रेकॉर्डिंगचा तपशील';

  @override
  String get fieldCaptured => 'रेकॉर्ड केले';

  @override
  String get fieldDuration => 'वेळ';

  @override
  String get fieldSampleRate => 'सॅम्पल रेट';

  @override
  String get fieldAnalysisTime => 'विश्लेषणाचा वेळ';

  @override
  String get fieldDevice => 'फोन';

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
      'container': 'ज्या डब्याचा आवाज ऐकायचा तो निवडा',
      'other': 'ज्या पोत्याचा आवाज ऐकायचा ते निवडा',
    });
    return '$_temp0';
  }

  @override
  String get batchScanTitle => 'एकेक करून आवाज-तपासणी';

  @override
  String get batchScanSubtitle => 'पोत्यांची एकेक करून आवाज-तपासणी करा';

  @override
  String get qrCardTitle => 'QR लेबलवरून उघडा';

  @override
  String qrCardSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'तो डबा उघडायला Kernel लेबलकडे कॅमेरा धरा',
      'other': 'ते पोते उघडायला Kernel पोत्याच्या लेबलकडे कॅमेरा धरा',
    });
    return '$_temp0';
  }

  @override
  String get oneAtATimeTitle => 'एका वेळी एक';

  @override
  String get oneAtATimeBody =>
      'प्रत्येक रेकॉर्डिंग एकाच वस्तूचे असते. वस्तूंची एकामागून एक आवाज-तपासणी करा; एक तपासणी कधीही अनेक वस्तू एकत्र पाहत नाही.';

  @override
  String emptyItemsMessage(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'अजून डबे नाहीत',
      'other': 'अजून पोती नाहीत',
    });
    return '$_temp0';
  }

  @override
  String emptyItemsAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'तुमचा पहिला डबा जोडा',
      'other': 'तुमच्या पहिल्या पोत्याची नोंद करा',
    });
    return '$_temp0';
  }

  @override
  String get scanTabEmptyDetail =>
      'आधी एकाची नोंद करा, मग आवाज-तपासणीसाठी परत या.';

  @override
  String get scansTodayTitle => 'आजच्या आवाज-तपासण्या';

  @override
  String scansTodaySummary(int scans, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items वस्तूंच्या',
      one: '1 वस्तूच्या',
    );
    String _temp1 = intl.Intl.pluralLogic(
      scans,
      locale: localeName,
      other: '$scans आवाज-तपासण्या',
      one: '1 आवाज-तपासणी',
    );
    return 'मध्यरात्रीपासून $_temp0 $_temp1';
  }

  @override
  String get scansTodayEmpty =>
      'आज अजून आवाज-तपासणी नाही. तुम्ही रेकॉर्ड केलेल्या तपासण्या लगेच इथे दिसतील.';

  @override
  String get experimentalBadge => 'प्रायोगिक';

  @override
  String get errorCouldNotLoad => 'उघडता आले नाही';

  @override
  String errorWithDetail(String prefix, String detail) {
    return '$prefix: $detail';
  }

  @override
  String fieldLabel(String label) {
    return '$label:';
  }

  @override
  String get validationQuantityEmpty => 'प्रमाण लिहा';

  @override
  String get validationQuantityPositive => '0 पेक्षा मोठी संख्या लिहा';

  @override
  String get actionCancel => 'रद्द करा';

  @override
  String get actionSave => 'सेव्ह करा';

  @override
  String get offlineLabel => 'ऑफलाइन';

  @override
  String get onlineLabel => 'ऑनलाइन';

  @override
  String get offlineSemantics => 'ऑफलाइन. या फोनवर सगळे चालू राहते.';

  @override
  String get onlineSemantics => 'ऑनलाइन. Kernel ला इंटरनेटची गरज नाही.';

  @override
  String get qrTooltip => 'QR लेबलवरून पोते उघडा';

  @override
  String get menuTooltip => 'मेनू';

  @override
  String get menuSwitchRole => 'भूमिका बदला';

  @override
  String get menuSettings => 'सेटिंग्ज';

  @override
  String itemTileSubtitle(String grain, String quantity, String date) {
    return '$grain · $quantity · साठवले $date';
  }

  @override
  String get archivedBadge => 'बाजूला ठेवले';

  @override
  String get chipRetryNeeded => 'पुन्हा करायला हवे';

  @override
  String chipAiUnverified(String label) {
    return 'AI: $label (खात्री नाही)';
  }

  @override
  String scanTileTitle(String item, String when) {
    return '$item · $when';
  }

  @override
  String qualityChip(String quality) {
    return 'दर्जा: $quality';
  }

  @override
  String get chipAudioKept => 'आवाज फोनवर ठेवला आहे';

  @override
  String photoSemantics(int number) {
    return 'पुराव्याचा फोटो $number. पूर्ण आकारात उघडतो.';
  }

  @override
  String get photoMissing => 'हा फोटो आता या फोनवर नाही.';

  @override
  String get photoRemove => 'फोटो काढा';

  @override
  String verifiedFindingLine(String finding) {
    return 'खात्रीचा निकाल: $finding';
  }

  @override
  String inspectorLine(String inspector, String when) {
    return '$inspector · $when';
  }

  @override
  String followUpChip(String status) {
    return 'पुढची पाहणी: $status';
  }

  @override
  String get unassigned => 'कोणाकडेही सोपवलेली नाही';

  @override
  String assignedToChip(String name) {
    return '$name कडे सोपवली';
  }

  @override
  String get followUpChangeTooltip => 'पुढच्या पाहणीची स्थिती बदला';

  @override
  String get followUpUpdate => 'स्थिती बदला';

  @override
  String get assignAction => 'सोपवा';

  @override
  String get archiveAction => 'बाजूला ठेवा';

  @override
  String archiveConfirmTitle(String name) {
    return '$name बाजूला ठेवायचे?';
  }

  @override
  String get archiveConfirmItemBody =>
      'ते याद्या, रांगा आणि नवीन अहवालांत दिसणार नाही. त्याचा आवाज-तपासणी इतिहास आणि पाहण्या या फोनवर राहतील आणि हटवल्या जाणार नाहीत.';

  @override
  String get archiveConfirmLotBody =>
      'हा लॉट तुमच्या याद्या आणि नवीन अहवालांत दिसणार नाही. त्याची पोती, त्यांचा आवाज-तपासणी इतिहास आणि पाहण्या या फोनवर राहतील.';

  @override
  String get archiveConfirmLocationBody =>
      'ही जागा याद्या आणि निवडीच्या यादीत दिसणार नाही. तिथे ठेवलेली पोती, त्यांचा आवाज-तपासणी इतिहास आणि पाहण्या या फोनवर राहतील.';

  @override
  String get archiveConfirmHarvestBody =>
      'हे पीक तुमच्या याद्या आणि नवीन अहवालांत दिसणार नाही. त्याची पोती, त्यांचा आवाज-तपासणी इतिहास आणि पाहण्या या फोनवर राहतील.';

  @override
  String get levelMeterLabel => 'माइकच्या आवाजाची पातळी';

  @override
  String get levelMeterWaiting => 'आवाजाची वाट पाहत आहे';

  @override
  String levelMeterValue(int dbfs) {
    return '$dbfs dBFS';
  }

  @override
  String get voicePlacePhone => 'फोन पोत्यावर ठेवा';

  @override
  String get voiceListening => 'ऐकत आहे';

  @override
  String get voiceDone => 'झाले';

  @override
  String scanCouldNotRun(String detail) {
    return 'आवाज-तपासणी चालू शकली नाही: $detail';
  }

  @override
  String scanCouldNotSave(String detail) {
    return 'आवाज-तपासणीचा निकाल सेव्ह झाला नाही, म्हणून काहीही ठेवले गेले नाही. तपशील: $detail';
  }

  @override
  String get captureReady => 'ऐकायला तयार';

  @override
  String get captureListening => 'ऐकत आहे — हलू नका';

  @override
  String get captureSaving => 'या फोनवर सेव्ह होत आहे';

  @override
  String get captureCheckingMic => 'माइकची परवानगी तपासत आहे';

  @override
  String get captureGetReady => 'तयार व्हा — फोन ठेवा';

  @override
  String captureSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'फोन डब्यावर दाबून धरा',
      'other': 'फोन पोत्यावर दाबून धरा',
    });
    return '$_temp0';
  }

  @override
  String get captureResearchSubtitle =>
      'संशोधन रेकॉर्डिंग: हे 2 सेकंद लेबल लावण्यासाठी याच फोनवर खाजगीरित्या ठेवले जातात';

  @override
  String get captureStart => '2 सेकंदांचे रेकॉर्डिंग सुरू करा';

  @override
  String get captureStartAgain => '2 सेकंदांचे रेकॉर्डिंग पुन्हा करा';

  @override
  String get captureStartResearch => 'लेबल लावलेला नमुना रेकॉर्ड करा (2 से.)';

  @override
  String get captureProgressLabel => 'रेकॉर्डिंग किती झाले';

  @override
  String percentValue(int percent) {
    return '$percent टक्के';
  }

  @override
  String captureElapsed(String elapsed, String target) {
    return '$target से. पैकी $elapsed से.';
  }

  @override
  String get captureChecking => 'या फोनवर रेकॉर्डिंग तपासत आहे…';

  @override
  String get hintWaiting => 'ऐकत आहे…';

  @override
  String get hintTooQuiet => 'खूप हळू — आणखी जवळ दाबा';

  @override
  String get hintTooLoud => 'खूप मोठा / घासल्याचा आवाज';

  @override
  String get hintHoldStill => 'हलू नका';

  @override
  String get appTitle => 'Kernel';

  @override
  String get roleFarmer => 'शेतकरी';

  @override
  String get roleHousehold => 'घर';

  @override
  String get roleStorageFpo => 'साठवण/FPO';

  @override
  String get roleBuyer => 'खरेदीदार';

  @override
  String get roleFarmerTagline => 'पीक आणि विक्रीआधी तपासणी';

  @override
  String get roleHouseholdTagline => 'डबे आणि आठवणी';

  @override
  String get roleStorageFpoTagline => 'गोदाम आणि एकेक करून पाहणी';

  @override
  String get roleBuyerTagline => 'पुरवठादार आणि लॉट तपासणी';

  @override
  String get navHome => 'होम';

  @override
  String get navScan => 'आवाज-तपासणी';

  @override
  String get navInventory => 'साठा';

  @override
  String get navReports => 'अहवाल';

  @override
  String get navInventoryFarmer => 'माझे धान्य';

  @override
  String get navInventoryHousehold => 'माझे डबे';

  @override
  String get navInventoryFpo => 'गोदाम';

  @override
  String get navInventoryBuyer => 'लॉट';

  @override
  String get reportTitleFarmer => 'विक्रीआधीचा अहवाल';

  @override
  String get reportTitleHousehold => 'साठवण अहवाल';

  @override
  String get reportTitleFpo => 'गोदाम अहवाल';

  @override
  String get reportTitleBuyer => 'लॉट तपासणी अहवाल';

  @override
  String get locationTypeHome => 'घर';

  @override
  String get locationTypeContainer => 'डबा';

  @override
  String get locationTypeWarehouse => 'गोदाम';

  @override
  String get locationTypeRoom => 'खोली';

  @override
  String get locationTypeStack => 'थप्पी';

  @override
  String get screeningPending => 'बाकी';

  @override
  String get screeningScreening => 'तपासणी चालू';

  @override
  String get screeningNeedsPhysicalCheck => 'उघडून पाहणी बाकी';

  @override
  String get screeningReviewed => 'पाहिले';

  @override
  String get findingNoneFound => 'काहीही आढळले नाही';

  @override
  String get findingPestsFound => 'कीड आढळली';

  @override
  String get findingInconclusive => 'ठरवता आले नाही';

  @override
  String get findingNoneFoundHelp =>
      'मी तपासले आणि कीड किंवा नुकसान दिसले नाही';

  @override
  String get findingPestsFoundHelp =>
      'मला किडे, अळ्या, जाळी किंवा नुकसान दिसले';

  @override
  String get findingInconclusiveHelp => 'तपासून मला ठरवता आले नाही';

  @override
  String get followUpOpen => 'उघडी';

  @override
  String get followUpInProgress => 'चालू आहे';

  @override
  String get followUpDone => 'झाली';

  @override
  String get reminderScheduled => 'ठरवली';

  @override
  String get reminderFired => 'आत्ताची वेळ';

  @override
  String get reminderDone => 'झाली';

  @override
  String get reminderCancelled => 'रद्द';

  @override
  String get reasonSilence =>
      'खूप हळू: माइकपर्यंत जवळजवळ आवाजच पोहोचला नाही. फोन धान्यावर घट्ट दाबा.';

  @override
  String get reasonClipping =>
      'खूप मोठा: आवाज फाटला. रेकॉर्डिंग चालू असताना ठोकू, घासू किंवा आपटू नका.';

  @override
  String get reasonHighNoise =>
      'मागे खूप गोंगाट आहे. शांत जागी जा आणि हलू नका.';

  @override
  String get reasonTooShort =>
      'रेकॉर्डिंग खूप छोटे झाले. पूर्ण 2 सेकंद फोन न हलवता धरा.';

  @override
  String get reasonPermissionDenied =>
      'माइकची परवानगी बंद आहे. आवाज-तपासणीसाठी फोनच्या सेटिंग्जमध्ये परवानगी द्या.';

  @override
  String get reasonCaptureError =>
      'माइक रेकॉर्ड करू शकला नाही. माइक वापरणारी इतर अॅप बंद करा आणि पुन्हा प्रयत्न करा.';

  @override
  String get qualityPass => 'वापरण्याजोगे';

  @override
  String get qualityRetry => 'पुन्हा करा';

  @override
  String get predictionClean => 'कोणताही संकेत आढळला नाही';

  @override
  String get predictionUncertain => 'नक्की नाही';

  @override
  String get predictionInfested => 'कीड लागल्याची शक्यता';

  @override
  String get predictionNotEvaluated => 'निकाल आला नाही';

  @override
  String get sampleLabelClean => 'कोणतीही खूण नाही';

  @override
  String get sampleLabelInfested => 'कीड लागली';

  @override
  String get sampleLabelUnknown => 'माहीत नाही';

  @override
  String get headlineRetry =>
      'रेकॉर्डिंग वापरण्याजोगे नाही — पुन्हा प्रयत्न करा';

  @override
  String get headlineNotEvaluated =>
      'निकाल आला नाही — कोणतेही मॉडेल बसवलेले नाही. स्वतः उघडून पाहणी करा.';

  @override
  String get headlineNotEvaluatedWithModel =>
      'निकाल आला नाही — मॉडेलला हे रेकॉर्डिंग तपासता आले नाही. स्वतः उघडून पाहणी करा.';

  @override
  String get headlineInspectionNeeded =>
      'पाहणी आवश्यक — मॉडेलच्या निकालाची खात्री झालेली नाही';

  @override
  String get headlineClean =>
      'कोणताही संकेत आढळला नाही — ही हमी नाही; विक्री/साठवणीच्या निर्णयापूर्वी स्वतः पाहणी करा';

  @override
  String get provenanceNone => 'मॉडेल: नाही — निकाल आला नाही';

  @override
  String provenanceExperimental(String version) {
    return 'मॉडेल $version — प्रायोगिक';
  }

  @override
  String provenanceValidated(String version) {
    return 'मॉडेल $version — सिद्ध झालेले';
  }

  @override
  String dateTimeJoin(String date, String time) {
    return '$date, $time';
  }

  @override
  String get nextStepEyebrow => 'पुढची पायरी';

  @override
  String get nextNothingPending =>
      'आत्ता काही तातडीचे नाही. लक्ष ठेवण्यासाठी नियमित आवाज-तपासणी करत राहा.';

  @override
  String get quickScanAction => 'आत्ता आवाज-तपासणी करा';

  @override
  String scansTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आज $count आवाज-तपासण्या',
      one: 'आज 1 आवाज-तपासणी',
      zero: 'आज एकही आवाज-तपासणी नाही',
    );
    return '$_temp0';
  }

  @override
  String scanActivityLine(int today, int week) {
    return 'आवाज-तपासण्या: आज $today · मागच्या 7 दिवसांत $week';
  }

  @override
  String nextRegisterFirst(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'तुमचा पहिला डबा नोंदवा',
      'other': 'तुमचे पहिले पोते नोंदवा',
    });
    return '$_temp0';
  }

  @override
  String get nextRegisterFirstBody =>
      'नाव, धान्य आणि प्रमाण लिहा. एक मिनिट लागतो.';

  @override
  String get nextRegisterFirstLot => 'तुमची पहिली खेप नोंदवा';

  @override
  String get nextRegisterFirstLotBody => 'पुरवठादार, लॉट, धान्य आणि प्रमाण.';

  @override
  String nextScanOne(String label) {
    return '$label ची आवाज-तपासणी करा';
  }

  @override
  String nextScanSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पोत्यांची आवाज-तपासणी बाकी',
      one: '1 पोत्याची आवाज-तपासणी बाकी',
    );
    return '$_temp0';
  }

  @override
  String nextScanContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डब्यांची आवाज-तपासणी बाकी',
      one: '1 डब्याची आवाज-तपासणी बाकी',
    );
    return '$_temp0';
  }

  @override
  String nextScanBody(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'फोन डब्यावर दाबून 2 सेकंदांची ऐकण्याची तपासणी.',
      'other': '2 सेकंदांची ऐकण्याची तपासणी, एका वेळी एक पोते.',
    });
    return '$_temp0';
  }

  @override
  String nextInspectOne(String label) {
    return '$label ची पाहणी करा';
  }

  @override
  String nextInspectSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'खूण केलेल्या $count पोत्यांची पाहणी करा',
      one: 'खूण केलेल्या 1 पोत्याची पाहणी करा',
    );
    return '$_temp0';
  }

  @override
  String nextInspectContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'खूण केलेल्या $count डब्यांची पाहणी करा',
      one: 'खूण केलेल्या 1 डब्याची पाहणी करा',
    );
    return '$_temp0';
  }

  @override
  String get nextInspectBody =>
      'मॉडेलच्या निकालाची खात्री झालेली नाही. धान्य हाताने तपासा.';

  @override
  String nextReviewOne(String label) {
    return '$label: पुन्हा पाहण्याची वेळ';
  }

  @override
  String nextReviewSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पोती पुन्हा पाहण्याची वेळ',
      one: '1 पोते पुन्हा पाहण्याची वेळ',
    );
    return '$_temp0';
  }

  @override
  String nextReviewContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डबे पुन्हा पाहण्याची वेळ',
      one: '1 डबा पुन्हा पाहण्याची वेळ',
    );
    return '$_temp0';
  }

  @override
  String get nextReviewBody =>
      'मागच्या तपासणीला बराच काळ झाला. पुन्हा ऐका किंवा पाहणी करा.';

  @override
  String nextReminderOne(String label) {
    return '$label: आठवणीची वेळ';
  }

  @override
  String nextReminderMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आठवणींची वेळ',
      one: '1 आठवणीची वेळ',
    );
    return '$_temp0';
  }

  @override
  String get nextReminderBody =>
      'तुम्ही ठरवलेल्या पुन्हा-तपासणीची वेळ झाली आहे. हे धान्य तपासा.';

  @override
  String nextPhysicalOne(String label) {
    return 'लॉट $label: प्रत्यक्ष पाहणी बाकी';
  }

  @override
  String nextPhysicalMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लॉटची प्रत्यक्ष पाहणी बाकी',
      one: '1 लॉटची प्रत्यक्ष पाहणी बाकी',
    );
    return '$_temp0';
  }

  @override
  String get nextPhysicalBody =>
      'लॉट उघडा आणि माणसाला जे दिसले ते नोंदवा. Kernel कधीही लॉट स्वीकारत किंवा नाकारत नाही.';

  @override
  String get nextFinishBatch => 'एकेक करून तपासणी पूर्ण करा';

  @override
  String nextFinishBatchOne(String label) {
    return 'एकेक करून तपासणी पूर्ण करा: $label';
  }

  @override
  String nextFinishBatchBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पोती बाकी, एका वेळी एक',
      one: '1 पोते बाकी, एका वेळी एक',
      zero: 'या गटातील सर्व पोत्यांची आवाज-तपासणी झाली',
    );
    return '$_temp0';
  }

  @override
  String get nextPreSale => 'विक्रीआधीचा अहवाल पाठवा';

  @override
  String nextPreSaleOne(String label) {
    return '$label चा विक्रीआधीचा अहवाल पाठवा';
  }

  @override
  String get nextLotSummary => 'लॉटचा सारांश पाठवा';

  @override
  String nextLotSummaryOne(String label) {
    return '$label चा लॉट सारांश पाठवा';
  }

  @override
  String get nextExportBody =>
      'तुमच्या नोंदींवरून याच फोनवर बनवलेला. कोणाला पाठवायचा ते तुम्ही ठरवा.';

  @override
  String get nextActionRegister => 'नोंद करा';

  @override
  String get nextActionScan => 'आवाज-तपासणी सुरू';

  @override
  String get nextActionBatch => 'एकेक करून तपासणी सुरू';

  @override
  String get nextActionOpen => 'उघडा';

  @override
  String get nextActionQueue => 'पाहणीची रांग उघडा';

  @override
  String get nextActionOpenLot => 'लॉट उघडा';

  @override
  String get nextActionContinueBatch => 'एकेक करून तपासणी चालू ठेवा';

  @override
  String get nextActionReport => 'अहवाल उघडा';

  @override
  String get insightsTitle => 'माहिती';

  @override
  String get insightsSubtitle => 'तुमच्याच नोंदींवरून याच फोनवर काढलेली';

  @override
  String get insightsCardSubtitle =>
      'निकाल, रेकॉर्डिंगच्या अडचणी आणि कशाची तपासणी हवी';

  @override
  String get insightsWindowLabel => 'कालावधी';

  @override
  String get insightsWindow7 => '7 दिवस';

  @override
  String get insightsWindow30 => '30 दिवस';

  @override
  String get insightsWindowAll => 'सर्व काळ';

  @override
  String get insightsActivityTitle => 'आवाज-तपासणीचे काम';

  @override
  String get insightsScansToday => 'आजच्या आवाज-तपासण्या';

  @override
  String get insightsScans7 => 'मागच्या 7 दिवसांतील आवाज-तपासण्या';

  @override
  String get insightsRatesTitle => 'निकाल';

  @override
  String get insightsRatesEmpty => 'या कालावधीत आवाज-तपासणी नाही';

  @override
  String get insightsRatesEmptyDetail =>
      'इथे निकाल पाहण्यासाठी एखाद्या पोत्याची किंवा डब्याची आवाज-तपासणी करा.';

  @override
  String get insightsExperimentalNote =>
      'प्रायोगिक मॉडेल: या निकालांची खात्री झालेली नाही आणि ते चुकीचे असू शकतात. साठवण किंवा विक्रीच्या कोणत्याही निर्णयापूर्वी स्वतः पाहणी करा.';

  @override
  String get insightsNoModelResults =>
      'अजून मॉडेलचे निकाल नाहीत: वापरण्याजोगे एकही रेकॉर्डिंग मॉडेलने तपासलेले नाही.';

  @override
  String get insightsRetryLabel => 'रेकॉर्डिंग वापरण्याजोगे नाही (पुन्हा करा)';

  @override
  String insightsBarValue(int count, int percent) {
    return '$count · $percent%';
  }

  @override
  String insightsTotalScans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'या कालावधीत $count आवाज-तपासण्या',
      one: 'या कालावधीत 1 आवाज-तपासणी',
    );
    return '$_temp0';
  }

  @override
  String get insightsQualityTitle => 'रेकॉर्डिंगच्या अडचणी';

  @override
  String get insightsQualityEmpty => 'या कालावधीत निरुपयोगी रेकॉर्डिंग नाही';

  @override
  String get insightsQualityHint =>
      'शांत जागी फोन पोत्यावर घट्ट दाबला की बहुतेक अडचणी दूर होतात.';

  @override
  String get insightsInspectionsTitle => 'पाहण्या';

  @override
  String get insightsInspectionsEmpty => 'अजून एकही पाहणी नोंदवलेली नाही';

  @override
  String insightsClosureRate(int percent) {
    return '$percent% पाहण्या पूर्ण झाल्या';
  }

  @override
  String get insightsStaleTitle => 'सर्वात जास्त काळ न तपासलेले';

  @override
  String get staleNeverScanned => 'कधीही आवाज-तपासणी झाली नाही';

  @override
  String get qualityShortSilence => 'खूप हळू';

  @override
  String get qualityShortClipping => 'खूप मोठा (आवाज फुटला)';

  @override
  String get qualityShortHighNoise => 'खूप गोंगाट';

  @override
  String get qualityShortTooShort => 'खूप लहान';

  @override
  String get qualityShortPermissionDenied => 'माइक बंद आहे';

  @override
  String get qualityShortCaptureError => 'रेकॉर्डिंगमध्ये बिघाड';

  @override
  String get queueFilterResult => 'मॉडेलचा निकाल';

  @override
  String get queueFilterAllResults => 'सर्व निकाल';

  @override
  String get queueFilterPlace => 'जागा';

  @override
  String get queueFilterAllPlaces => 'सर्व जागा';

  @override
  String get queueFilterAge => 'शेवटची वापरण्याजोगी आवाज-तपासणी';

  @override
  String get queueFilterAnyAge => 'कधीही';

  @override
  String queueFilterWithinDays(int days) {
    return '$days दिवसांच्या आत';
  }

  @override
  String queueFilterAgeNote(int days) {
    return 'ज्यांची शेवटची वापरण्याजोगी आवाज-तपासणी $days दिवसांपेक्षा जुनी आहे, ते \"आवाज-तपासणी बाकी\" मध्ये जातात.';
  }

  @override
  String get queueNoMatch => 'या फिल्टरशी काहीही जुळत नाही.';

  @override
  String get rankReasonInfested => 'इथे का: कीड लागल्याची शक्यता (खात्री नाही)';

  @override
  String get rankReasonUncertain => 'इथे का: मॉडेलला नक्की सांगता आले नाही';

  @override
  String get rankReasonClean => 'खाली का: कोणताही संकेत आढळला नाही (हमी नाही)';

  @override
  String scannedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिवसांपूर्वी आवाज-तपासणी झाली',
      one: '1 दिवसापूर्वी आवाज-तपासणी झाली',
      zero: 'आज आवाज-तपासणी झाली',
    );
    return '$_temp0';
  }

  @override
  String get reminderSuggestedLabel => 'सुचवलेले — निवड तुमची';

  @override
  String reminderSuggestedOther(String date) {
    return 'सुचवलेले: $date — निवड तुमची';
  }

  @override
  String get reminderWordingTitle => 'सुचवलेले शब्द';

  @override
  String get settingsAdviceSection => 'फोनवरचा AI मदतनीस (प्रायोगिक)';

  @override
  String get adviceToggle => 'फोनवरचा AI मदतनीस वापरा';

  @override
  String get adviceToggleBody =>
      'सुरुवातीला बंद असतो. तो फक्त याच फोनवर चालतो आणि तुमचे रेकॉर्डिंग कधीच ऐकत नाही; तो फक्त निकाल आणि तारखा पाहतो. तो चुकू शकतो. तुम्ही तो कधीही बंद करू शकता.';

  @override
  String get adviceStatusTitle => 'मदतनीसाची स्थिती';

  @override
  String get adviceStatusOff => 'बंद';

  @override
  String get adviceStatusNoModel => 'चालू — अजून मॉडेल आणलेले नाही';

  @override
  String get adviceStatusLoading => 'मॉडेल उघडत आहे…';

  @override
  String get adviceStatusReady => 'या फोनवर तयार';

  @override
  String get adviceStatusBusy => 'लिहीत आहे';

  @override
  String get adviceStatusFailed =>
      'मॉडेल उघडता आले नाही — Kernel त्याचा नेहमीचा मजकूर दाखवते';

  @override
  String get adviceModelTitle => 'मदतनीसाचे मॉडेल';

  @override
  String get adviceModelNone => 'अजून मॉडेल आणलेले नाही';

  @override
  String get adviceModelId => 'मॉडेल';

  @override
  String get adviceModelVersion => 'आवृत्ती';

  @override
  String get adviceModelSize => 'आकार';

  @override
  String get adviceModelBackend => 'कशावर चालते';

  @override
  String get adviceBackendGpu => 'फोनची ग्राफिक्स चिप (GPU)';

  @override
  String get adviceBackendCpu => 'फोनचा प्रोसेसर (CPU)';

  @override
  String get adviceBackendNone => 'अजून उघडलेले नाही';

  @override
  String get adviceImportAction => 'मॉडेल आणा';

  @override
  String get adviceImporting => 'मॉडेल आणले जात आहे';

  @override
  String adviceImportCopying(String copied, String total) {
    return '$total पैकी $copied कॉपी झाले';
  }

  @override
  String adviceImportCopied(String copied) {
    return '$copied कॉपी झाले';
  }

  @override
  String get adviceImportVerifying => 'मॉडेल फाईल तपासली जात आहे…';

  @override
  String get adviceImportDone => 'मॉडेल आले. ते याच फोनवर राहते.';

  @override
  String adviceImportFailed(String detail) {
    return 'मॉडेल आणता आले नाही: $detail';
  }

  @override
  String adviceImportNoSpace(String needed, String free) {
    return 'जागा कमी आहे: मॉडेलला $needed हवी, पण या फोनवर फक्त $free रिकामी आहे.';
  }

  @override
  String get adviceDeleteAction => 'मॉडेल काढून टाका';

  @override
  String get adviceDeleteConfirmTitle => 'मदतनीसाचे मॉडेल काढून टाकायचे?';

  @override
  String get adviceDeleteConfirmBody =>
      'यामुळे मॉडेल फाईल या फोनवरून काढली जाईल. तुमच्या नोंदींवर काहीही परिणाम होणार नाही. नंतर पुन्हा आणता येईल.';

  @override
  String adviceDeleteFailed(String detail) {
    return 'मॉडेल काढता आले नाही: $detail';
  }

  @override
  String get adviceHelp =>
      'Google AI Edge Gallery वापरून किंवा Hugging Face litert-community/gemma-4-E2B-it-litert-lm वरून .litertlm मॉडेल मिळवा (Gemma च्या अटी लागू), मग ते इथे आणा.';

  @override
  String adviceProvenance(String modelVersion) {
    return 'याच फोनवर तयार — प्रायोगिक · $modelVersion';
  }

  @override
  String get adviceNotDecision => 'हा निर्णय नाही — स्वतः पाहणी करा';

  @override
  String get adviceGenerating => 'याच फोनवर लिहिले जात आहे…';

  @override
  String get adviceExplainAction => 'हा निकाल समजावून सांगा';

  @override
  String get adviceExplainTitle => 'या निकालाचा अर्थ';

  @override
  String get adviceStaticRetry =>
      'रेकॉर्डिंग वापरण्याजोगे नव्हते, म्हणून कोणताही निकाल जतन झाला नाही. फोन पोत्यावर किंवा डब्यावर घट्ट दाबा, हलू नका, शांत राहा आणि पुन्हा रेकॉर्ड करा.';

  @override
  String get adviceStaticNotEvaluated =>
      'या रेकॉर्डिंगचा निकाल आला नाही, त्यामुळे यावरून किडीबद्दल काहीही कळत नाही. धान्याची स्वतः पाहणी करा.';

  @override
  String get adviceStaticInspection =>
      'प्रायोगिक मॉडेलला लक्ष द्यावे लागेल असे काहीतरी ऐकू आले. याची खात्री झालेली नाही. कोणताही निर्णय घेण्यापूर्वी धान्याची स्वतः पाहणी करा.';

  @override
  String get adviceStaticClean =>
      'प्रायोगिक मॉडेलला कोणताही संकेत मिळाला नाही. ही हमी नाही. साठवण किंवा विक्रीच्या निर्णयापूर्वी धान्याची स्वतः पाहणी करा.';

  @override
  String get reportAiSummaryToggle => 'AI ने लिहिलेला सारांश जोडा';

  @override
  String get reportAiSummaryBody =>
      'अहवालातील आकड्यांवरून याच फोनवर लिहिलेला. आधी तुम्ही तो पाहता आणि जोडायचा की नाही ते ठरवता. प्रायोगिक.';

  @override
  String get reportAiPreviewTitle => 'AI ने लिहिलेला सारांश';

  @override
  String get reportAiPreviewBody =>
      'जोडल्यास तो अहवालात स्वतंत्र, नाव दिलेल्या भागात दिसेल — तुमच्या नोंदी आणि पाहणीच्या निष्कर्षांपासून वेगळा. तो बदलता येत नाही.';

  @override
  String get reportAiSummaryTitle => 'सारांशाचा मसुदा';

  @override
  String get reportAiInclude => 'जोडा';

  @override
  String get reportAiSkip => 'वगळा';

  @override
  String unitGb(String value) {
    return '$value GB';
  }

  @override
  String unitMb(String value) {
    return '$value MB';
  }

  @override
  String get hubTitle => 'Model Hub';

  @override
  String get hubSubtitle =>
      'On-phone models for Pest ID. They run only on this phone.';

  @override
  String get hubNeedsTitle => 'Pest ID needs';

  @override
  String get hubNeedImage => 'Image understanding';

  @override
  String get hubNeedEmbeddings => 'Embeddings';

  @override
  String get hubNeedSound => 'Sound classifier';

  @override
  String get hubInstalledChip => 'Installed';

  @override
  String get hubMissingChip => 'Missing';

  @override
  String get hubAllInstalled => 'Everything Pest ID needs is on this phone.';

  @override
  String get hubNothingToDownload =>
      'No download is available for the missing parts yet.';

  @override
  String hubDownloadSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count models to download, about $size',
      one: '1 model to download, about $size',
    );
    return '$_temp0';
  }

  @override
  String get hubDownloadAction => 'Download models';

  @override
  String hubDownloadFailed(String error) {
    return 'Download could not start: $error';
  }

  @override
  String get hubCatalogUnavailable => 'Could not read the model list';

  @override
  String get hubInstalledUnavailable => 'Could not read installed models';

  @override
  String get hubGalleryNote =>
      'Kernel can\'t use files AI Edge Gallery already downloaded (Android keeps each app\'s files private), so it downloads the same models once.';

  @override
  String get hubConsentTitle => 'Download Pest ID models?';

  @override
  String get hubConsentBody =>
      'These models are downloaded once and then run only on this phone. Nothing you capture is ever uploaded.';

  @override
  String hubConsentSize(String size) {
    return 'Size: $size';
  }

  @override
  String hubConsentLicense(String license) {
    return 'Licence: $license';
  }

  @override
  String hubConsentModelCard(String url) {
    return 'Model card: $url';
  }

  @override
  String get hubSourceHf => 'Downloaded from Hugging Face';

  @override
  String get hubSourceGoogle => 'Downloaded from Google AI Edge';

  @override
  String hubSourceOther(String host) {
    return 'Downloaded from $host';
  }

  @override
  String get hubWifiOnly => 'Wi-Fi only';

  @override
  String get hubWifiOnlyBody =>
      'Wait for Wi-Fi before downloading. These files are large.';

  @override
  String hubConsentTotal(String size) {
    return 'Total: about $size';
  }

  @override
  String get hubConsentAgree => 'Agree and download';

  @override
  String get hubConsentNotNow => 'Not now';

  @override
  String get hubConsentGrantedTitle => 'Model downloads allowed';

  @override
  String get hubDownloadsTitle => 'Downloads';

  @override
  String get hubPhaseQueued => 'Waiting to start';

  @override
  String get hubPhaseWifi => 'Waiting for Wi-Fi';

  @override
  String hubPhaseSpace(String size) {
    return 'Waiting for free space: needs $size';
  }

  @override
  String hubFreeSpace(String free) {
    return '$free free on this phone';
  }

  @override
  String hubPhaseDownloading(String done, String total) {
    return 'Downloading: $done of $total';
  }

  @override
  String get hubPhaseVerifying => 'Checking the file';

  @override
  String get hubPhasePaused => 'Paused';

  @override
  String hubPhaseFailed(String reason) {
    return 'Failed: $reason';
  }

  @override
  String get hubCancel => 'Cancel';

  @override
  String get hubInstalledTitle => 'Installed models';

  @override
  String get hubInstalledEmpty => 'No models installed yet';

  @override
  String get hubInstalledEmptyDetail =>
      'Pest ID works after its models are downloaded once.';

  @override
  String get hubFieldPath => 'File';

  @override
  String get hubFieldSize => 'Size';

  @override
  String get hubFieldVersion => 'Version';

  @override
  String get hubFieldCapabilities => 'Can do';

  @override
  String get hubFieldBackends => 'Runs on';

  @override
  String get hubMatchesGallery => 'Matches AI Edge Gallery';

  @override
  String get hubRemove => 'Remove';

  @override
  String get hubRemoveConfirmTitle => 'Remove this model?';

  @override
  String get hubRemoveConfirmBody =>
      'The file is deleted from this phone. Pest ID parts that need it stop until it is downloaded again.';

  @override
  String hubRemoveFailed(String error) {
    return 'Could not remove: $error';
  }

  @override
  String get hubCapTextGen => 'Text writing';

  @override
  String get hubCapImageIn => 'Image understanding';

  @override
  String get hubCapAudioIn => 'Audio understanding';

  @override
  String get hubCapEmbedText => 'Text embeddings';

  @override
  String get hubCapEmbedImage => 'Image embeddings';

  @override
  String get hubCapEmbedAudio => 'Audio embeddings';

  @override
  String get hubCapAudioClassify => 'Sound classifier';

  @override
  String get hubCapImageClassify => 'Image classifier';

  @override
  String get hubCapObjectDetect => 'Object finder';

  @override
  String get hubCapSegment => 'Outline finder';

  @override
  String get hubCapSensorClassify => 'Sensor classifier';

  @override
  String get hubSearchHint => 'Search models & pest info';

  @override
  String get hubSearchAction => 'Search';

  @override
  String get hubSearchModels => 'Models';

  @override
  String get hubSearchPestInfo => 'Pest info';

  @override
  String hubSearchScore(String score) {
    return 'Similarity $score';
  }

  @override
  String get hubSearchNoResults => 'No matches. Try other words.';

  @override
  String hubSearchFailed(String error) {
    return 'Search is not available right now: $error';
  }

  @override
  String get hubSearchNote =>
      'Search runs on this phone. Similarity is not confidence.';

  @override
  String get hubNeedsReview => 'Needs expert review';

  @override
  String get hubSettingsSection => 'Pest ID, maps and sensors';

  @override
  String get hubSettingsCard =>
      'Download and manage the on-phone models Pest ID uses.';

  @override
  String get hubMapsToggle => 'Use Google Maps';

  @override
  String get hubMapsToggleBody =>
      'Only the map area and route start and end are sent to Google. Never species, notes, photos or audio.';

  @override
  String get hubMapsConfirmTitle => 'Allow Google Maps?';

  @override
  String get hubMapsConfirmBody =>
      'Maps need the internet. Google receives only the part of the map you look at and a route\'s start and end. Kernel never sends species, notes, photos, audio or sensor data. You can turn this off at any time.';

  @override
  String get hubMapsConfirmAgree => 'Allow maps';

  @override
  String get hubKeepMediaToggle => 'Keep photos and clips with sightings';

  @override
  String get hubKeepMediaToggleBody =>
      'When off, the photo or sound clip is deleted after analysis. Kept media stays on this phone.';

  @override
  String get sensorTitle => 'Sensors';

  @override
  String get sensorSubtitle =>
      'Paired listening nodes. They send signals, not diagnoses.';

  @override
  String get sensorEmpty => 'No sensors paired yet';

  @override
  String get sensorEmptyDetail =>
      'Pair a Kernel sensor node by scanning the QR label on it.';

  @override
  String get sensorPairAction => 'Pair a sensor';

  @override
  String get sensorPrivacyNote =>
      'Sensors send sound features only, never audio. Everything stays on this phone.';

  @override
  String get sensorSettingsCard => 'Pair and check Bluetooth sensor nodes.';

  @override
  String get sensorTypeUsAir => 'Ultrasonic (air)';

  @override
  String get sensorTypeContactPiezo => 'Contact (piezo)';

  @override
  String get sensorTypeContactAccel => 'Contact (vibration)';

  @override
  String get sensorTypeAudioAir => 'Sound (air)';

  @override
  String get sensorLinkUnpaired => 'Not paired';

  @override
  String get sensorLinkPairing => 'Pairing';

  @override
  String get sensorLinkConnecting => 'Connecting';

  @override
  String get sensorLinkConnected => 'Connected';

  @override
  String get sensorLinkAuthenticated => 'Connected securely';

  @override
  String get sensorLinkDisconnected => 'Not connected';

  @override
  String get sensorLinkError => 'Link problem';

  @override
  String get sensorStatusUnknown => 'Status unknown';

  @override
  String sensorBattery(int percent) {
    return 'Battery $percent%';
  }

  @override
  String get sensorBatteryUnknown => 'Battery unknown';

  @override
  String get sensorHealthOk => 'Sensor working';

  @override
  String get sensorHealthJammed =>
      'Jammed — ultrasonic source nearby (e.g. a repeller); results not evaluated';

  @override
  String get sensorHealthClipped => 'Clipped';

  @override
  String get sensorHealthLowBattery => 'Low battery';

  @override
  String get sensorHealthSurveyNeeded => 'Survey needed';

  @override
  String get sensorHealthAuthFailed => 'Security check failed — pair again';

  @override
  String get sensorNotEvaluatedTitle => 'Not evaluated';

  @override
  String get sensorNotEvaluatedBody =>
      'This sensor can\'t check right now. This does not mean nothing is there. Inspect physically.';

  @override
  String get sensorPairTitle => 'Pair a sensor';

  @override
  String get sensorPairInstructions =>
      'Point the camera at the QR label on the sensor node.';

  @override
  String get sensorPairPrivacy =>
      'The label holds the sensor\'s security key. It is kept in protected storage on this phone and is never shown or sent.';

  @override
  String get sensorPairNotSensor => 'This isn\'t a Kernel sensor label.';

  @override
  String get sensorPairing => 'Pairing. Accept the Android pairing request.';

  @override
  String get sensorPairCancelled => 'Pairing was cancelled.';

  @override
  String sensorPairFailed(String error) {
    return 'Could not pair: $error';
  }

  @override
  String get sensorPairTryAgain => 'Scan again';

  @override
  String sensorPairedSnack(String name) {
    return '$name paired';
  }

  @override
  String get sensorCameraTitle => 'Allow the camera to read the label';

  @override
  String get sensorCameraBody =>
      'Kernel uses the camera only to read the sensor\'s QR label. Nothing is recorded or sent.';

  @override
  String get sensorPlaceTitle => 'Where is this sensor?';

  @override
  String get sensorPlaceSubtitle =>
      'Choose the place, and the sack or container if it sits on one.';

  @override
  String get sensorPlaceLocation => 'Place';

  @override
  String get sensorPlaceItem => 'Sack or container';

  @override
  String get sensorPlaceNone => 'Not set';

  @override
  String get sensorPlaceNote =>
      'Sensor evidence then shows on that sack or container, separate from scans and inspections.';

  @override
  String get sensorPlaceSave => 'Save placement';

  @override
  String get sensorPlaceSkip => 'Later';

  @override
  String get sensorPlaceSaved => 'Placement saved';

  @override
  String sensorPlaceFailed(String error) {
    return 'Could not save the placement: $error';
  }

  @override
  String get sensorPlaceNoLocations =>
      'No places yet — add a room or store first';

  @override
  String get sensorPlaceChange => 'Change placement';

  @override
  String get sensorNotFound => 'This sensor is not on this phone.';

  @override
  String get sensorDetailsTitle => 'Sensor details';

  @override
  String get sensorFieldType => 'Type';

  @override
  String get sensorFieldPlace => 'Place';

  @override
  String get sensorFieldItem => 'Placed on';

  @override
  String get sensorFieldFirmware => 'Firmware';

  @override
  String get sensorFieldKey => 'Key fingerprint';

  @override
  String get sensorFieldLastSeen => 'Last seen';

  @override
  String get sensorLiveTitle => 'Live bands';

  @override
  String get sensorLiveNote =>
      'Energy per frequency band only. The sensor sends no audio.';

  @override
  String get sensorLiveWaiting => 'Waiting for the sensor';

  @override
  String sensorBandRange(String low, String high) {
    return '$low–$high kHz';
  }

  @override
  String sensorBandLevel(String db) {
    return '$db dB above background';
  }

  @override
  String sensorLivePeak(String khz) {
    return 'Strongest at $khz kHz';
  }

  @override
  String get sensorSurveyTitle => 'Survey';

  @override
  String sensorSurveyBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Keep the place quiet for $minutes minutes so the sensor learns its normal background.',
      one: 'Keep the place quiet for 1 minute so the sensor learns its normal background.',
    );
    return '$_temp0';
  }

  @override
  String sensorSurveyStart(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Start survey ($minutes min)',
      one: 'Start survey (1 min)',
    );
    return '$_temp0';
  }

  @override
  String sensorSurveyRunning(int done, int total) {
    return 'Surveying: $done of $total min';
  }

  @override
  String get sensorSurveyDone => 'Survey finished';

  @override
  String sensorSurveyFailed(String error) {
    return 'Survey failed: $error';
  }

  @override
  String get sensorSessionTitle => 'Overnight monitoring';

  @override
  String get sensorSessionBody =>
      'Kernel keeps listening to this sensor in the background. Android shows a notification while it runs. To keep it running all night, open app settings and set battery use to Unrestricted (no battery optimisation).';

  @override
  String get sensorSessionStart => 'Start overnight session';

  @override
  String get sensorSessionStop => 'Stop session';

  @override
  String get sensorSessionRunning => 'Session running';

  @override
  String sensorSessionFailed(String error) {
    return 'Could not change the session: $error';
  }

  @override
  String get sensorBatterySettings => 'Open app settings';

  @override
  String get sensorSyncAction => 'Sync events';

  @override
  String sensorSynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new events',
      one: '1 new event',
      zero: 'No new events',
    );
    return '$_temp0';
  }

  @override
  String sensorSyncFailed(String error) {
    return 'Could not sync: $error';
  }

  @override
  String get sensorTimelineTitle => 'Event timeline';

  @override
  String get sensorTimelineEmpty => 'No events recorded yet';

  @override
  String get sensorTimelineEmptyDetail =>
      'This is not proof that nothing is there. Sync to fetch events stored on the sensor.';

  @override
  String get sensorSummaryTitle => 'Signals';

  @override
  String sensorEventsSummary(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String get sensorSignalNotDiagnosis =>
      'Signals, not a diagnosis. Inspect physically.';

  @override
  String get sensorUnmatched => 'Unmatched signal';

  @override
  String get sensorSigMouseUsv => 'Mouse-like ultrasonic calls';

  @override
  String get sensorSigRat22k => 'Rat-like 22 kHz calls';

  @override
  String get sensorSigGrainLarva => 'Grain-larva-like feeding clicks';

  @override
  String get sensorSigTermiteDrum => 'Termite-like drumming';

  @override
  String sensorSigOther(String id) {
    return 'Signature: $id';
  }

  @override
  String sensorPack(String version) {
    return 'Signature pack $version';
  }

  @override
  String sensorScore(String score) {
    return 'Rule score $score (not a probability)';
  }

  @override
  String sensorEventLine(String time, String kind, String khz, int ms) {
    return '$time · $kind · $khz kHz · $ms ms';
  }

  @override
  String get sensorClassTonal => 'Tone';

  @override
  String get sensorClassFmSweep => 'Sweep';

  @override
  String get sensorClassFlatTone => 'Flat tone';

  @override
  String get sensorClassImpulse => 'Clicks';

  @override
  String get sensorClassHarmonic => 'Harmonic tone';

  @override
  String get sensorClassChirp => 'Pulsed chirps';

  @override
  String get sensorClassEmitter => 'Continuous emitter';

  @override
  String get sensorEvidenceTitle => 'Sensor evidence';

  @override
  String get sensorEvidenceBody =>
      'Signals from sensors placed here. Experimental, and kept separate from scans and inspections.';

  @override
  String get sensorEvidenceOpen => 'Open sensor';

  @override
  String sensorEvidenceEmpty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'No sensor events in the last $days days. This is not proof that nothing is there.',
      one: 'No sensor events in the last day. This is not proof that nothing is there.',
    );
    return '$_temp0';
  }

  @override
  String sensorEvidenceWindow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Last $days days',
      one: 'Last day',
    );
    return '$_temp0';
  }

  @override
  String sensorNextActivityOne(String name) {
    return 'Sensor signals at $name';
  }

  @override
  String sensorNextActivityMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sensor signals in $count places',
      one: 'Sensor signals in 1 place',
    );
    return '$_temp0';
  }

  @override
  String get sensorNextActivityBody =>
      'Signals, not a diagnosis. Inspect physically.';

  @override
  String sensorNextAttentionOne(String name) {
    return 'Check sensor $name';
  }

  @override
  String sensorNextAttentionMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sensors need attention',
      one: '1 sensor needs attention',
    );
    return '$_temp0';
  }

  @override
  String get sensorNextAttentionBody =>
      'Jammed, clipped, low battery or survey needed. Its results are not evaluated.';

  @override
  String get sensorNextOpen => 'Open sensors';
}

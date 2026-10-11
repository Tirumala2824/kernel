// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageFollowDevice => 'फ़ोन की भाषा अपनाएँ';

  @override
  String get languageSheetBody => 'Kernel के शब्द तुरंत बदल जाते हैं।';

  @override
  String get settingsSubtitle =>
      'भाषा, आवाज़-जाँच, निजता और फ़ोन पर चलने वाली जानकारी';

  @override
  String get settingsScanning => 'आवाज़-जाँच';

  @override
  String get settingsHaptics => 'शुरू और खत्म होने पर कंपन';

  @override
  String get settingsHapticsBody =>
      'रिकॉर्डिंग शुरू और बंद होने पर फ़ोन थोड़ा काँपता है, ताकि आप फ़ोन को बोरी पर दबाए रख सकें।';

  @override
  String get settingsVoice => 'बोलकर निर्देश';

  @override
  String get settingsVoiceBody =>
      'शुरू में बंद रहता है। इस फ़ोन में लगी आवाज़ से “फ़ोन बोरी पर रखें”, “सुन रहा है” और “हो गया” बोलता है। इंटरनेट से कुछ नहीं लिया जाता।';

  @override
  String get settingsRetain => 'रिकॉर्डिंग इस फ़ोन पर रखें';

  @override
  String get settingsRetainBody =>
      'शुरू में बंद रहता है: हर 2 सेकंड की रिकॉर्डिंग जाँच के तुरंत बाद मिटा दी जाती है। चालू करने पर रिकॉर्डिंग ऐप के अंदर निजी रूप से रखी जाती हैं ताकि उन्हें फिर से जाँचा जा सके। ये कभी अपलोड नहीं होतीं। “सारा इतिहास मिटाएँ” इन्हें हटा देता है।';

  @override
  String get settingsResearchSection => 'शोध';

  @override
  String get settingsResearch => 'शोध रिकॉर्डिंग मोड';

  @override
  String get settingsResearchBody =>
      'अनाज के कीड़ों का मॉडल बनाने में मदद के लिए लेबल वाले नमूने रिकॉर्ड करें। यह रिकॉर्डिंग रखने वाली सेटिंग से अलग है; शुरू में बंद रहता है।';

  @override
  String get researchConsentTitle => 'शोध रिकॉर्डिंग चालू करें?';

  @override
  String get researchConsentBody =>
      'जब आप “लेबल वाला नमूना रिकॉर्ड करें” चुनते हैं, तो वह 2 सेकंड की रिकॉर्डिंग आपके दिए लेबल के साथ इस फ़ोन पर निजी रूप से रखी जाती है। “कोई निशान नहीं” या “कीड़े लगे” लेबल के लिए खुद देखकर की गई जाँच से पुष्टि ज़रूरी है। कुछ भी अपलोड नहीं होता: आप डेटासेट फ़ाइल बना सकते हैं और खुद तय कर सकते हैं कि उसे किसे देना है। इसे कभी भी बंद करें; “सारा इतिहास मिटाएँ” हर रिकॉर्डिंग और लेबल हटा देता है।';

  @override
  String get researchConsentAgree => 'मैं सहमत हूँ, चालू करें';

  @override
  String get settingsSamplesCard => 'हर लेबल की गिनती और डेटासेट फ़ाइल';

  @override
  String get settingsPrivacy => 'निजता';

  @override
  String get deleteHistoryTitle => 'सारा इतिहास मिटाएँ';

  @override
  String get deleteHistoryBody =>
      'आवाज़-जाँच, देखकर जाँच और उनकी फ़ोटो, रिमाइंडर, लेबल वाले नमूने और रखी गई रिकॉर्डिंग हटाता है।';

  @override
  String get deleteHistoryConfirmTitle => 'सारा इतिहास मिटाएँ?';

  @override
  String get deleteHistoryConfirmBody =>
      'इससे इस फ़ोन पर हर आवाज़-जाँच, देखकर जाँच (फ़ोटो सहित), रिमाइंडर, लेबल वाला नमूना और रखी गई रिकॉर्डिंग मिट जाएगी। आपकी दर्ज चीज़ें, जगहें, फ़सलें और लॉट बने रहेंगे। इसे वापस नहीं किया जा सकता।';

  @override
  String get deleteHistoryConfirmAction => 'इतिहास मिटाएँ';

  @override
  String get deleteHistoryDone => 'सारा इतिहास मिट गया';

  @override
  String deleteHistoryFailed(String detail) {
    return 'इतिहास नहीं मिट सका: $detail';
  }

  @override
  String get settingsOnDevice => 'फ़ोन पर ही आवाज़-जाँच';

  @override
  String get engineUnavailable => 'आवाज़-जाँच इंजन की जानकारी नहीं मिली';

  @override
  String get engineModelPresent =>
      'नतीजे प्रायोगिक हैं और उनकी पुष्टि नहीं हुई है।';

  @override
  String get engineNoModel =>
      'कोई मॉडल नहीं लगा है, इसलिए आवाज़-जाँच सिर्फ़ रिकॉर्डिंग की गुणवत्ता देखती है और नतीजों में “नतीजा नहीं बना” दिखता है।';

  @override
  String get settingsFooter =>
      'Kernel ऑडियो इसी फ़ोन पर रखता है। फ़ोन पर सहेजे रिकॉर्ड और ऐप में शामिल जाँचें ऑफ़लाइन काम करती हैं; मॉडल डाउनलोड और ऑनलाइन नक्शों के लिए इंटरनेट चाहिए।';

  @override
  String get diagnosticsTitle => 'तकनीकी जानकारी';

  @override
  String get diagnosticsCard =>
      'टेस्टिंग के लिए मॉडल, प्रोसेसर, सैंपल रेट और फ़ोन की जानकारी';

  @override
  String get diagnosticsSubtitle => 'इस फ़ोन पर आवाज़-जाँच इंजन क्या बताता है';

  @override
  String get notMeasured => 'अभी नापा नहीं गया';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get diagModelInstalled => 'मॉडल लगा है';

  @override
  String get diagModelNote => 'मॉडल की जानकारी';

  @override
  String get diagDelegate => 'प्रोसेसर';

  @override
  String get diagAudioTitle => 'आवाज़ इनपुट';

  @override
  String get diagTargetRate => 'लक्ष्य सैंपल रेट';

  @override
  String get diagEffectiveRate => 'असल सैंपल रेट';

  @override
  String get diagDeviceRate => 'फ़ोन का इनपुट रेट';

  @override
  String get diagAudioSource => 'आवाज़ का स्रोत';

  @override
  String get diagDeviceTitle => 'फ़ोन';

  @override
  String get diagOs => 'एंड्रॉइड';

  @override
  String get diagAppVersion => 'ऐप वर्ज़न';

  @override
  String get diagLogRowTitle => 'डिवाइस-लॉग की पंक्ति';

  @override
  String get diagLogRowBody =>
      'यह पंक्ति docs/device-validation.md के डिवाइस लॉग में चिपकाएँ और अपना नाम जोड़ें।';

  @override
  String get diagCopyRow => 'डिवाइस-लॉग पंक्ति कॉपी करें';

  @override
  String get diagCopied => 'पंक्ति कॉपी हो गई';

  @override
  String get qrTitle => 'QR लेबल से खोलें';

  @override
  String get qrInstructions =>
      'लेबल को चौखटे के अंदर रखें। पढ़ते ही यह खुल जाएगा।';

  @override
  String get qrNotKernel =>
      'यह QR कोड Kernel का बोरी लेबल नहीं है। कैमरा Kernel से छपे लेबल की ओर करें।';

  @override
  String get qrUnknownItem =>
      'यह लेबल ऐसी बोरी का है जो इस फ़ोन पर दर्ज नहीं है।';

  @override
  String qrLookupFailed(String detail) {
    return 'बोरी नहीं खुल सकी: $detail';
  }

  @override
  String get qrScanAnother => 'दूसरा लेबल पढ़ें';

  @override
  String get qrRationaleTitle =>
      'बोरी के लेबल पढ़ने के लिए कैमरा इस्तेमाल करें';

  @override
  String get qrRationaleBody =>
      'Kernel कैमरे का इस्तेमाल सिर्फ़ बोरी के QR लेबल पढ़ने और जाँच की फ़ोटो लेने के लिए करता है। लेबल इसी फ़ोन पर पढ़े जाते हैं; कैमरे की तस्वीरें न सेव होती हैं, न अपलोड।';

  @override
  String get qrAllowCamera => 'कैमरे की अनुमति दें';

  @override
  String get qrCameraDenied =>
      'कैमरे की अनुमति नहीं मिली। आप फिर भी अपने भंडार से बोरियाँ खोल सकते हैं।';

  @override
  String get qrCameraBlocked =>
      'Kernel के लिए कैमरा बंद है। फ़ोन की सेटिंग खोलें, अनुमतियाँ चुनें, फिर कैमरे की अनुमति दें।';

  @override
  String get qrPrivacyNote =>
      'लेबल इसी फ़ोन पर पढ़ा जाता है। कुछ भी अपलोड नहीं होता।';

  @override
  String get labelSampleTitle => 'शोध रिकॉर्डिंग पर लेबल लगाएँ';

  @override
  String get labelRuleNote =>
      '“कोई निशान नहीं” या “कीड़े लगे” तभी चुनें जब इस बोरी की खुद देखकर जाँच ने इसकी पुष्टि की हो। नहीं तो “पता नहीं” चुनें।';

  @override
  String get labelCleanHelp =>
      'देखकर जाँच में कीड़े नहीं मिले, इसकी पुष्टि हुई';

  @override
  String get labelCleanNeedsInspection =>
      'इस बोरी की ऐसी देखकर जाँच चाहिए जिसमें कीड़े न मिले हों';

  @override
  String get labelInfestedHelp => 'देखकर जाँच में कीड़े मिले, इसकी पुष्टि हुई';

  @override
  String get labelInfestedNeedsInspection =>
      'इस बोरी की ऐसी देखकर जाँच चाहिए जिसमें कीड़े मिले हों';

  @override
  String get labelUnknownHelp =>
      'किसी जाँच से इस बोरी की हालत की पुष्टि नहीं होती';

  @override
  String get labelNeedsEvidence =>
      '“कोई निशान नहीं” और “कीड़े लगे” के लिए इस बोरी की मेल खाती देखकर जाँच चाहिए। “पता नहीं” चुनें या पहले देखकर जाँच दर्ज करें।';

  @override
  String get evidenceTitle => 'पुष्टि करने वाली जाँच';

  @override
  String get evidenceBody => 'इस रिकॉर्डिंग के लिए की गई देखकर जाँच चुनें।';

  @override
  String get sackMaterialField => 'बोरी या डिब्बे का सामान';

  @override
  String get notRecorded => 'दर्ज नहीं';

  @override
  String get environmentField => 'माहौल';

  @override
  String get environmentHelper =>
      'कहाँ रिकॉर्ड किया, जैसे शांत कमरा या पंखों वाला गोदाम';

  @override
  String get envQuietRoom => 'शांत कमरा';

  @override
  String get envWarehouse => 'गोदाम';

  @override
  String get envFansOn => 'पंखे या मशीनें चालू';

  @override
  String get envOutdoors => 'बाहर खुले में';

  @override
  String get materialJute => 'जूट';

  @override
  String get materialWovenPp => 'प्लास्टिक की बुनी बोरी (PP)';

  @override
  String get materialCotton => 'सूती';

  @override
  String get materialPlastic => 'प्लास्टिक का डिब्बा';

  @override
  String get materialMetal => 'धातु का डिब्बा';

  @override
  String get materialOther => 'अन्य';

  @override
  String get sampleSave => 'लेबल वाला नमूना सेव करें';

  @override
  String get sampleSaved => 'लेबल वाला नमूना इस फ़ोन पर सेव हुआ';

  @override
  String sampleRejected(String detail) {
    return 'लेबल सेव नहीं हुआ: $detail';
  }

  @override
  String get sampleUnusableRetry =>
      'यह रिकॉर्डिंग काम की नहीं थी, इसलिए इस पर लेबल नहीं लग सकता। किसी शांत जगह पर फिर से रिकॉर्ड करें।';

  @override
  String get sampleUnusableNotKept =>
      'इस रिकॉर्डिंग की आवाज़ रखी नहीं गई, इसलिए इस पर लेबल नहीं लग सकता।';

  @override
  String get sampleRecordAgain => 'फिर से रिकॉर्ड करें';

  @override
  String get samplesTitle => 'शोध नमूने';

  @override
  String samplesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'इस फ़ोन पर $count लेबल वाली रिकॉर्डिंग',
      one: 'इस फ़ोन पर 1 लेबल वाली रिकॉर्डिंग',
      zero: 'अभी कोई लेबल वाली रिकॉर्डिंग नहीं',
    );
    return '$_temp0';
  }

  @override
  String get samplesResearchOff =>
      'शोध रिकॉर्डिंग मोड बंद है। नए नमूने रिकॉर्ड करने के लिए इसे सेटिंग में चालू करें।';

  @override
  String get samplesEmpty => 'अभी कोई लेबल वाला नमूना नहीं';

  @override
  String get samplesEmptyDetail =>
      'शोध मोड चालू करके कोई बोरी खोलें और “लेबल वाला नमूना रिकॉर्ड करें” चुनें।';

  @override
  String get datasetTitle => 'ट्रेनिंग डेटासेट';

  @override
  String get datasetBody =>
      'रखी गई रिकॉर्डिंग की एक ZIP फ़ाइल और उनके लेबल की एक CSV फ़ाइल, जो इसी फ़ोन पर बनती है। इसे कहाँ भेजना है, आप तय करते हैं; Kernel इसे कभी अपलोड नहीं करता।';

  @override
  String get datasetExport => 'डेटासेट फ़ाइल बनाएँ';

  @override
  String datasetExportFailed(String detail) {
    return 'डेटासेट नहीं बन सका या भेजा नहीं जा सका। $detail';
  }

  @override
  String sampleLabelChip(String label) {
    return 'लेबल: $label';
  }

  @override
  String get sampleConfirmed => 'देखकर जाँच से पुष्टि हुई';

  @override
  String get inspectionTitle => 'खुद देखकर जाँच';

  @override
  String get saveInspection => 'जाँच सेव करें';

  @override
  String get inspectionSaved => 'जाँच सेव हुई';

  @override
  String get aiPanelTitle => 'AI का अनुमान (पुष्टि नहीं)';

  @override
  String get aiPanelLoading => 'जुड़ी हुई आवाज़-जाँच खुल रही है…';

  @override
  String get aiPanelNoScan =>
      'कोई आवाज़-जाँच नहीं जुड़ी। यह देखकर जाँच अपने आप में पूरी है।';

  @override
  String scannedAt(String when) {
    return 'आवाज़-जाँच $when';
  }

  @override
  String get aiPanelNotUsed => 'आपका नतीजा भरने में इसका इस्तेमाल नहीं हुआ';

  @override
  String get findingPanelTitle => 'आपका पक्का नतीजा';

  @override
  String get findingPanelBody =>
      'अनाज जाँचते समय आपने खुद जो देखा। इसे AI के अनुमान से अलग रखा जाता है।';

  @override
  String get findingMissing => 'चुनें कि आपको क्या मिला';

  @override
  String get inspectorField => 'जाँच करने वाले का नाम';

  @override
  String get validationInspector => 'लिखें कि जाँच किसने की';

  @override
  String get inspectionDateField => 'जाँच की तारीख';

  @override
  String get observationsField => 'क्या देखा';

  @override
  String get observationsHelper => 'आपने क्या देखा, कहाँ और कितना';

  @override
  String get assigneeFieldOptional => 'आगे की जाँच किसे सौंपें (ज़रूरी नहीं)';

  @override
  String get followUpStatusTitle => 'आगे की जाँच की स्थिति';

  @override
  String get photosTitle => 'सबूत की फ़ोटो (ज़रूरी नहीं)';

  @override
  String get photosBody =>
      'फ़ोटो इस जाँच के साथ इसी फ़ोन पर निजी रूप से रहती हैं। ये आपकी देखी बात का सबूत हैं, आवाज़-जाँच का नतीजा नहीं, और कभी अपलोड नहीं होतीं।';

  @override
  String get photoTake => 'फ़ोटो लें';

  @override
  String get photoPick => 'गैलरी से चुनें';

  @override
  String get cameraDeniedPhoto =>
      'कैमरा बंद है। सबूत की फ़ोटो लेने के लिए फ़ोन की सेटिंग में इसकी अनुमति दें।';

  @override
  String photoFailed(String detail) {
    return 'फ़ोटो नहीं जुड़ सकी: $detail';
  }

  @override
  String get filterAll => 'सभी';

  @override
  String get filterNoMatch => 'इस फ़िल्टर से कोई खुली जाँच नहीं मिली।';

  @override
  String get batchSetupTitle => 'कमरा या ढेर चुनें';

  @override
  String get batchSetupSubtitle =>
      'Kernel आपको इसकी बोरियों तक एक-एक करके ले जाता है।';

  @override
  String get batchSequentialNote =>
      'हर बोरी की एक रिकॉर्डिंग। Kernel कभी कई बोरियों की एक साथ आवाज़-जाँच नहीं करता।';

  @override
  String get batchNoPlaces => 'अभी कोई कमरा या ढेर नहीं';

  @override
  String get batchNoPlacesDetail =>
      'एक गोदाम उसके कमरों और ढेरों के साथ जोड़ें, फिर उनमें बोरियाँ दर्ज करें।';

  @override
  String batchPlaceSubtitle(String type, int total, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total बोरियाँ',
      one: '1 बोरी',
    );
    return '$type · $_temp0 · $needScan की आवाज़-जाँच बाकी';
  }

  @override
  String batchIntroSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बोरियाँ, एक-एक करके जाँचें',
      one: '1 बोरी, एक-एक करके जाँचें',
      zero: 'जाँचने को कोई बोरी नहीं',
    );
    return '$_temp0';
  }

  @override
  String get batchSkipToday => 'आज जाँची गई बोरियाँ छोड़ें';

  @override
  String get batchSkipTodayBody =>
      'जिन बोरियों की आज की रिकॉर्डिंग पहले से है, उन्हें छोड़ दें।';

  @override
  String batchWalkLine(int position, String label, String grain) {
    return '$position. $label · $grain';
  }

  @override
  String batchStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बोरियों से शुरू करें',
      one: '1 बोरी से शुरू करें',
    );
    return '$_temp0';
  }

  @override
  String get batchNothingToWalk =>
      'यहाँ हर बोरी की पहले से काम की आवाज़-जाँच है या आज जाँच हो चुकी है।';

  @override
  String batchProgress(int position, int total) {
    return '$total में से बोरी $position';
  }

  @override
  String get batchSkipSack => 'यह बोरी छोड़ें';

  @override
  String get batchStop => 'दौर रोकें';

  @override
  String batchNextIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds सेकंड में अगली बोरी',
      one: '1 सेकंड में अगली बोरी',
    );
    return '$_temp0';
  }

  @override
  String batchSummaryIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds सेकंड में सारांश',
      one: '1 सेकंड में सारांश',
    );
    return '$_temp0';
  }

  @override
  String get batchNextSack => 'अगली बोरी';

  @override
  String get batchFinish => 'पूरा करें';

  @override
  String get batchRetrySack => 'इस बोरी को फिर से रिकॉर्ड करें';

  @override
  String get batchSummaryTitle => 'दौर का सारांश';

  @override
  String batchSummarySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'इस दौर में $count बोरियाँ',
      one: 'इस दौर में 1 बोरी',
    );
    return '$_temp0';
  }

  @override
  String get batchStatRecorded => 'रिकॉर्ड हुईं';

  @override
  String get batchStatSkipped => 'छोड़ी गईं';

  @override
  String get batchStatRetry => 'फिर से करनी हैं';

  @override
  String get rankedTitle => 'क्रम में';

  @override
  String rankLabel(int rank) {
    return '#$rank';
  }

  @override
  String get queueSuggestionNote =>
      'यह क्रम सिर्फ़ सुझाव है कि पहले क्या जाँचें। कोई भी फ़ैसला लेने से पहले खुद देखकर जाँच करें।';

  @override
  String get queueNothingRanked =>
      'अभी किसी चीज़ का काम का मॉडल नतीजा नहीं है, इसलिए कुछ भी क्रम में नहीं है। जिनका नतीजा नहीं है, वे “आवाज़-जाँच बाकी” में दिखती हैं।';

  @override
  String get queueNothingRankedShort => 'अभी कुछ क्रम में नहीं';

  @override
  String needsScanTitle(int count) {
    return 'आवाज़-जाँच बाकी ($count)';
  }

  @override
  String get needsScanChip => 'आवाज़-जाँच बाकी';

  @override
  String get needsScanEmpty => 'हर चीज़ की काम की आवाज़-जाँच है।';

  @override
  String get saveHarvest => 'फ़सल सेव करें';

  @override
  String get harvestNameField => 'फ़सल का नाम';

  @override
  String get harvestNameHelper => 'जैसे “रबी गेहूँ 2026”';

  @override
  String get harvestedOnField => 'कटाई की तारीख';

  @override
  String get notesFieldOptional => 'नोट (ज़रूरी नहीं)';

  @override
  String get harvestAppBar => 'फ़सल';

  @override
  String get harvestNotFound => 'यह फ़सल इस फ़ोन पर नहीं मिली।';

  @override
  String get harvestAddSack => 'इस फ़सल में बोरी दर्ज करें';

  @override
  String get harvestSacksTitle => 'इस फ़सल की बोरियाँ';

  @override
  String get harvestSacksEmpty => 'इस फ़सल में अभी कोई बोरी नहीं';

  @override
  String get harvestSacksEmptyDetail =>
      'इस फ़सल से भरी बोरियाँ दर्ज करें, फिर बेचने से पहले उनकी आवाज़-जाँच करें।';

  @override
  String get preSaleBody =>
      'खरीदार के लिए इस फ़सल की बोरियों का सारांश। हर आवाज़-जाँच के साथ उसका मॉडल वर्ज़न और प्रायोगिक स्थिति दिखती है, और देखकर जाँच के पक्के नतीजे अलग लिखे जाते हैं। यह गुणवत्ता का प्रमाणपत्र नहीं है।';

  @override
  String get notScannedYet => 'अभी आवाज़-जाँच नहीं हुई';

  @override
  String get lotAppBar => 'लॉट';

  @override
  String get lotNotFound => 'यह लॉट इस फ़ोन पर नहीं मिला।';

  @override
  String get supplierNotRecorded => 'सप्लायर दर्ज नहीं';

  @override
  String get fieldDeclaredQuantity => 'बताई गई मात्रा';

  @override
  String get fieldReceived => 'मिलने की तारीख';

  @override
  String get fieldScreened => 'जाँची गईं';

  @override
  String get screeningStatusTitle => 'जाँच की स्थिति';

  @override
  String get screeningStatusBody =>
      'आवाज़-जाँच और खोलकर जाँच देखने के बाद इसे आप तय करते हैं। आवाज़-जाँच इसे कभी नहीं बदलती, और Kernel कभी किसी लॉट को मंज़ूर या नामंज़ूर नहीं करता।';

  @override
  String currentStatus(String status) {
    return 'अभी: $status';
  }

  @override
  String get lotSacksTitle => 'इस लॉट की बोरियाँ';

  @override
  String get lotSacksEmpty => 'इस लॉट में अभी कोई बोरी नहीं';

  @override
  String get lotSacksEmptyAction => 'इस लॉट में बोरी दर्ज करें';

  @override
  String get sampleScansTitle => 'नमूना आवाज़-जाँच';

  @override
  String get sampleScansBody =>
      'इस माल की बोरियों की एक-एक करके आवाज़-जाँच करें। हर नतीजा मॉडल का बिना पुष्टि वाला अनुमान है और इससे लॉट की स्थिति नहीं बदलती।';

  @override
  String get sampleScansStart => 'नमूना आवाज़-जाँच शुरू करें';

  @override
  String get physicalChecksTitle => 'खोलकर जाँच';

  @override
  String get physicalChecksBody =>
      'हर बोरी खोलकर अंदर देखें, फिर जो मिला वह दर्ज करें। आपके नतीजे आवाज़-जाँच से अलग रखे जाते हैं।';

  @override
  String get recordPhysicalCheck => 'खोलकर जाँच दर्ज करें';

  @override
  String get noPhysicalCheckYet => 'अभी खोलकर जाँच नहीं हुई';

  @override
  String lotSummaryTitle(String code) {
    return 'लॉट $code की सारांश रिपोर्ट';
  }

  @override
  String get lotSummaryBody =>
      'इस फ़ोन के रिकॉर्ड से बनी: मॉडल की जानकारी के साथ नमूना आवाज़-जाँच, और खोलकर जाँच के नतीजे अलग से। इसे अपने फ़ैसले में मदद के लिए इस्तेमाल करें।';

  @override
  String savedLot(String code) {
    return 'लॉट $code सेव हुआ';
  }

  @override
  String get saveLot => 'लॉट सेव करें';

  @override
  String get lotCodeField => 'लॉट कोड';

  @override
  String get lotCodeHelper => 'माल की पर्ची पर लिखा नंबर';

  @override
  String get validationLotCode => 'लॉट कोड लिखें';

  @override
  String get supplierFieldOptional => 'सप्लायर का नाम (ज़रूरी नहीं)';

  @override
  String get declaredQuantityField => 'बताई गई मात्रा';

  @override
  String get receivedOnField => 'मिलने की तारीख';

  @override
  String shareSubject(String title) {
    return 'Kernel $title';
  }

  @override
  String exportFailed(String detail) {
    return 'रिपोर्ट नहीं बन सकी या भेजी नहीं जा सकी। $detail';
  }

  @override
  String get exportPanelBody =>
      'सिर्फ़ इस फ़ोन में रखे रिकॉर्ड से बनी। हर आवाज़-जाँच के साथ उसका मॉडल वर्ज़न और प्रायोगिक स्थिति दिखती है। AI के अनुमान और देखकर जाँच के पक्के नतीजे अलग-अलग लिखे जाते हैं।';

  @override
  String get exportCsv => 'CSV बनाएँ';

  @override
  String get exportPdf => 'PDF बनाएँ';

  @override
  String get exportLabelsPdf => 'लेबल की PDF बनाएँ';

  @override
  String exportSavedAt(String path) {
    return 'इस फ़ोन पर सेव हुई: $path';
  }

  @override
  String get sackLabelsTitle => 'बोरी के लेबल छापें';

  @override
  String get sackLabelsBody =>
      'इन बोरियों के QR लेबल की एक PDF। इसे छापें और हर लेबल उसकी बोरी पर चिपकाएँ; लेबल पढ़ने पर Kernel में वह बोरी खुल जाती है।';

  @override
  String get reportsTitle => 'रिपोर्ट';

  @override
  String get reportsFarmerHint =>
      'किसी फ़सल का बिक्री से पहले का सारांश उसी फ़सल के पेज पर है।';

  @override
  String get reportsBuyerHint => 'लॉट की सारांश रिपोर्ट हर लॉट के पेज पर है।';

  @override
  String get recentScans => 'हाल की आवाज़-जाँच';

  @override
  String get recentScansEmpty =>
      'अभी कोई आवाज़-जाँच नहीं। आपकी रिकॉर्ड की गई आवाज़-जाँच यहाँ दिखेंगी।';

  @override
  String get inventorySubtitleFarmer => 'आपकी फ़सलें और दर्ज बोरियाँ';

  @override
  String get inventorySubtitleHousehold =>
      'आपके अनाज के डिब्बे और वे कहाँ रखे हैं';

  @override
  String get inventorySubtitleFpo => 'गोदाम, कमरे, ढेर और बोरियाँ';

  @override
  String get inventorySubtitleBuyer => 'आने वाले लॉट और उनकी बोरियाँ';

  @override
  String get newHarvestAction => 'नई फ़सल';

  @override
  String registerItemAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डिब्बा जोड़ें',
      'other': 'बोरी दर्ज करें',
    });
    return '$_temp0';
  }

  @override
  String get addPlace => 'जगह जोड़ें';

  @override
  String get addLocation => 'जगह जोड़ें';

  @override
  String itemsSectionTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डिब्बे',
      'other': 'बोरियाँ',
    });
    return '$_temp0';
  }

  @override
  String get lotsSectionEmpty =>
      'अभी कोई लॉट नहीं। जोड़ने के लिए आया माल दर्ज करें।';

  @override
  String get placesTitle => 'जगहें';

  @override
  String get locationsTitle => 'जगहें';

  @override
  String get placesEmpty =>
      'अभी कोई जगह नहीं। डिब्बे कहाँ रखे हैं, यह बताने के लिए एक जोड़ें।';

  @override
  String get locationsEmpty =>
      'अभी कोई गोदाम नहीं। एक जोड़ें, फिर उसके कमरे और ढेर।';

  @override
  String get harvestsSectionEmpty =>
      'अभी कोई फ़सल नहीं। उसकी बोरियों को एक साथ रखने और बिक्री से पहले का सारांश बनाने के लिए एक फ़सल बनाएँ।';

  @override
  String harvestCardSubtitle(String grain, String date) {
    return '$grain · कटाई $date';
  }

  @override
  String sackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बोरियाँ',
      one: '1 बोरी',
      zero: 'अभी कोई बोरी नहीं',
    );
    return '$_temp0';
  }

  @override
  String get itemDetailAppBar => 'जानकारी';

  @override
  String get itemNotFound => 'यह चीज़ इस फ़ोन पर नहीं मिली।';

  @override
  String archiveItemMenu(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डिब्बा अलग रखें',
      'other': 'बोरी अलग रखें',
    });
    return '$_temp0';
  }

  @override
  String get archivedSnack => 'अलग रखा गया। इसका इतिहास इस फ़ोन पर बना रहेगा।';

  @override
  String get archivedItemNotice =>
      'सूचियों, कतारों और नई रिपोर्टों में नहीं दिखेगा। इसकी आवाज़-जाँच का इतिहास और देखकर जाँच बनी रहती हैं।';

  @override
  String get restoreAction => 'वापस लाएँ';

  @override
  String scanThisItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'इस डिब्बे की आवाज़-जाँच करें',
      'other': 'इस बोरी की आवाज़-जाँच करें',
    });
    return '$_temp0';
  }

  @override
  String get setReminderAction => 'दोबारा जाँच का रिमाइंडर लगाएँ';

  @override
  String get researchRecordTitle => 'लेबल वाला नमूना रिकॉर्ड करें';

  @override
  String get researchRecordSubtitle =>
      'शोध मोड: 2 सेकंड की रिकॉर्डिंग रखें और ट्रेनिंग डेटा के लिए उस पर लेबल लगाएँ';

  @override
  String get fieldQuantity => 'मात्रा';

  @override
  String get fieldStoredSince => 'कब से रखा है';

  @override
  String storedSinceValue(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '1 दिन',
    );
    return '$date ($_temp0)';
  }

  @override
  String get fieldLocation => 'जगह';

  @override
  String get fieldLot => 'लॉट';

  @override
  String get fieldHarvest => 'फ़सल';

  @override
  String nameWithType(String name, String type) {
    return '$name ($type)';
  }

  @override
  String registeredAs(String role) {
    return '$role के रूप में दर्ज';
  }

  @override
  String get scanHistoryTitle => 'आवाज़-जाँच का इतिहास';

  @override
  String get scanHistoryAppendOnly =>
      'हर आवाज़-जाँच जैसी रिकॉर्ड हुई वैसी ही रखी जाती है। नई आवाज़-जाँच पुरानी को कभी नहीं बदलती।';

  @override
  String scanHistoryEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'अभी कोई आवाज़-जाँच नहीं। एक रिकॉर्ड करने के लिए “इस डिब्बे की आवाज़-जाँच करें” दबाएँ।',
      'other': 'अभी कोई आवाज़-जाँच नहीं। एक रिकॉर्ड करने के लिए “इस बोरी की आवाज़-जाँच करें” दबाएँ।',
    });
    return '$_temp0';
  }

  @override
  String get inspectionsTitle => 'देखकर जाँच';

  @override
  String get inspectionsEmpty => 'अभी कोई देखकर जाँच दर्ज नहीं।';

  @override
  String get remindersTitle => 'रिमाइंडर';

  @override
  String get remindersEmpty => 'कोई रिमाइंडर नहीं लगा।';

  @override
  String recheckOn(String when) {
    return '$when को दोबारा जाँच';
  }

  @override
  String get reminderMarkDone => 'हो गया मानें';

  @override
  String get reminderCancel => 'रिमाइंडर रद्द करें';

  @override
  String get assignDialogTitle => 'जाँच सौंपें';

  @override
  String get assignDialogLabel => 'किसे सौंपा';

  @override
  String get assignDialogHelper => 'आगे की जाँच कौन करेगा';

  @override
  String get assignClear => 'सौंपना हटाएँ';

  @override
  String savedNamed(String name) {
    return '$name सेव हुआ';
  }

  @override
  String saveFailed(String detail) {
    return 'सेव नहीं हो सका: $detail';
  }

  @override
  String saveItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डिब्बा सेव करें',
      'other': 'बोरी सेव करें',
    });
    return '$_temp0';
  }

  @override
  String itemLabelField(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डिब्बे का लेबल',
      'other': 'बोरी का लेबल',
    });
    return '$_temp0';
  }

  @override
  String itemLabelHelper(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'डिब्बे पर लिखा नाम',
      'other': 'बोरी पर लिखा नाम',
    });
    return '$_temp0';
  }

  @override
  String get validationLabel => 'लेबल लिखें';

  @override
  String get grainTypeField => 'अनाज का प्रकार';

  @override
  String get validationGrain => 'अनाज का प्रकार लिखें';

  @override
  String get quantityField => 'मात्रा';

  @override
  String get unitField => 'इकाई';

  @override
  String get storageDateField => 'रखने की तारीख';

  @override
  String get harvestFieldOptional => 'फ़सल (ज़रूरी नहीं)';

  @override
  String get harvestFieldNone => 'अभी कोई फ़सल नहीं। “मेरा अनाज” से एक बनाएँ।';

  @override
  String get none => 'कोई नहीं';

  @override
  String get locationFieldOptional => 'जगह (ज़रूरी नहीं)';

  @override
  String locationFieldNone(String where) {
    return 'अभी कोई जगह नहीं। आप इन्हें $where से जोड़ सकते हैं।';
  }

  @override
  String get lotFieldOptional => 'लॉट (ज़रूरी नहीं)';

  @override
  String get lotFieldNone => 'अभी कोई लॉट दर्ज नहीं।';

  @override
  String get locationAppBar => 'जगह';

  @override
  String get locationNotFound => 'यह जगह इस फ़ोन पर नहीं मिली।';

  @override
  String get archivedLocationNotice =>
      'यह जगह अलग रखी गई है। इसकी बोरियाँ और उनका इतिहास बना रहता है।';

  @override
  String registerHere(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'यहाँ डिब्बा जोड़ें',
      'other': 'यहाँ बोरी दर्ज करें',
    });
    return '$_temp0';
  }

  @override
  String get addInside => 'अंदर जोड़ें';

  @override
  String get batchHere => 'यहाँ बारी-बारी जाँच';

  @override
  String get insideTitle => 'अंदर';

  @override
  String get insideEmpty => 'इस जगह के अंदर अभी कुछ नहीं।';

  @override
  String itemsHereTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'यहाँ के डिब्बे',
      'other': 'यहाँ की बोरियाँ',
    });
    return '$_temp0';
  }

  @override
  String itemsHereEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'यहाँ अभी कोई डिब्बा नहीं रखा।',
      'other': 'यहाँ अभी कोई बोरी नहीं रखी।',
    });
    return '$_temp0';
  }

  @override
  String get saveLocation => 'जगह सेव करें';

  @override
  String get typeField => 'प्रकार';

  @override
  String get nameField => 'नाम';

  @override
  String get validationName => 'नाम लिखें';

  @override
  String get parentFieldOptional => 'किसके अंदर (ज़रूरी नहीं)';

  @override
  String get parentFieldHelper => 'जैसे गोदाम के अंदर कोई कमरा';

  @override
  String get parentTopLevel => 'किसी के अंदर नहीं (सबसे ऊपर)';

  @override
  String get roleSelectTitle => 'अपनी भूमिका चुनें';

  @override
  String get roleSelectSubtitle => 'एक ऐप। चार तरह के काम।';

  @override
  String get roleCurrent => 'अभी वाली';

  @override
  String get roleSwitchKeepsRecords =>
      'भूमिका बदलने पर इस फ़ोन का हर रिकॉर्ड बना रहता है। आप कभी भी वापस बदल सकते हैं।';

  @override
  String roleSaveFailed(String detail) {
    return 'आपकी भूमिका सेव नहीं हो सकी: $detail';
  }

  @override
  String startDataError(String detail) {
    return 'Kernel इस फ़ोन पर अपना डेटा नहीं खोल सका। कृपया ऐप फिर से शुरू करें।\n\nजानकारी: $detail';
  }

  @override
  String get onboardingSkip => 'छोड़ें';

  @override
  String get onboardingBack => 'पीछे';

  @override
  String get onboardingNext => 'आगे';

  @override
  String onboardingStep(int step, int total) {
    return '$total में से चरण $step';
  }

  @override
  String get onboardingPrivacyTitle => 'आवाज़ आपके फ़ोन पर ही रहती है';

  @override
  String get onboardingPrivacy1 =>
      'Kernel अनाज की आवाज़ 2 सेकंड सुनता है और उसे यहीं इसी फ़ोन पर जाँचता है।';

  @override
  String get onboardingPrivacy2 =>
      'ऑडियो इसी फ़ोन पर रहता है। फ़ोन पर सहेजे रिकॉर्ड और ऐप में शामिल जाँचें ऑफ़लाइन काम करती हैं; मॉडल डाउनलोड और ऑनलाइन नक्शों के लिए इंटरनेट चाहिए।';

  @override
  String get onboardingPrivacy3 =>
      'जाँच के बाद रिकॉर्डिंग मिटा दी जाती हैं, जब तक आप सेटिंग में उन्हें रखना न चुनें।';

  @override
  String get onboardingHowTitle => 'आवाज़-जाँच कैसे करें';

  @override
  String get onboardingHow1 =>
      'फ़ोन को बोरी या डिब्बे पर सपाट रखें, माइक उससे छूता रहे।';

  @override
  String get onboardingHow2 =>
      'शांत कमरा चुनें। बात करना बंद करें और हो सके तो पंखे बंद करें।';

  @override
  String get onboardingHow3 => 'Kernel के सुनते समय 2 सेकंड बिना हिले रहें।';

  @override
  String get onboardingHow4 =>
      'नतीजे प्रायोगिक हैं। फ़ैसला लेने से पहले हमेशा अनाज को खुद देखकर जाँचें।';

  @override
  String get onboardingRoleTitle => 'अपनी भूमिका चुनें';

  @override
  String get heroEyebrowListen => 'अपने अनाज की आवाज़ सुनें';

  @override
  String get heroStartScan => 'आवाज़-जाँच शुरू करें';

  @override
  String get heroStartBatch => 'बारी-बारी जाँच शुरू करें';

  @override
  String get loading => 'खुल रहा है…';

  @override
  String get farmerHomeTitle => 'किसान का पन्ना';

  @override
  String farmerHomeHarvestSubtitle(String name) {
    return 'फ़सल: $name';
  }

  @override
  String get farmerHeroTitle => 'अनाज की आवाज़-जाँच';

  @override
  String get farmerHeroSubtitle =>
      'बताए तरीके से 2 सेकंड की रिकॉर्डिंग शुरू करें';

  @override
  String get farmerEmptyDetail =>
      'आवाज़-जाँच और हिसाब रखना शुरू करने के लिए एक बोरी दर्ज करें।';

  @override
  String registeredSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दर्ज बोरियाँ',
      one: '1 दर्ज बोरी',
    );
    return '$_temp0';
  }

  @override
  String get noFollowUps => 'आगे की कोई देखकर जाँच बाकी नहीं';

  @override
  String sacksRequireFollowUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बोरियों की आगे देखकर जाँच ज़रूरी',
      one: '1 बोरी की आगे देखकर जाँच ज़रूरी',
    );
    return '$_temp0';
  }

  @override
  String get harvestsTitle => 'फ़सलें';

  @override
  String get harvestsEmptyCard =>
      'फ़सल बनाएँ, ताकि उसकी बोरियाँ बिक्री से पहले की रिपोर्ट के लिए एक साथ रहें';

  @override
  String harvestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़सलें · सबसे नई खोलें',
      one: '1 फ़सल · सबसे नई खोलें',
    );
    return '$_temp0';
  }

  @override
  String get queueTitle => 'जाँच की कतार';

  @override
  String get queueCardSubtitle => 'पहले कौन-सी बोरियाँ जाँचें';

  @override
  String get preSaleCardSubtitle => 'अपने रखे रिकॉर्ड से बना सारांश निकालें';

  @override
  String preSaleCardHarvest(String name) {
    return '$name का बिक्री से पहले का सारांश';
  }

  @override
  String get householdHomeTitle => 'घर का भंडार';

  @override
  String get householdHomeSubtitle => 'घर के अनाज का हिसाब';

  @override
  String get householdHeroTitle => 'डिब्बे की आवाज़-जाँच करें';

  @override
  String get householdHeroSubtitle => 'अनाज की हालत दर्ज करें';

  @override
  String get householdEmptyDetail =>
      'कितने दिन से रखा है, यह देखने के लिए अनाज का डिब्बा जोड़ें।';

  @override
  String get remindersCardTitle => 'जाँच के रिमाइंडर';

  @override
  String get remindersCardEmpty =>
      'कोई रिमाइंडर तय नहीं। लगाने के लिए कोई डिब्बा खोलें।';

  @override
  String remindersScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिमाइंडर तय',
      one: '1 रिमाइंडर तय',
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
      other: '$days दिन से रखा है',
      one: '1 दिन से रखा है',
    );
    return '$_temp0';
  }

  @override
  String get reviewNeverScanned => 'अभी आवाज़-जाँच नहीं हुई — जाँच का समय';

  @override
  String reviewDueSince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'जाँच का समय — आखिरी आवाज़-जाँच $days दिन पहले',
      one: 'जाँच का समय — आखिरी आवाज़-जाँच 1 दिन पहले',
    );
    return '$_temp0';
  }

  @override
  String reviewNextIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'अगली जाँच $days दिन में',
      one: 'अगली जाँच 1 दिन में',
    );
    return '$_temp0';
  }

  @override
  String get reviewDue => 'जाँच का समय';

  @override
  String reminderOn(String date) {
    return 'रिमाइंडर $date';
  }

  @override
  String get recheckAction => 'फिर जाँचें';

  @override
  String get remindMeAction => 'याद दिलाएँ';

  @override
  String get reminderSheetTitle => 'दोबारा जाँच का रिमाइंडर लगाएँ';

  @override
  String reminderSheetSubtitle(String label) {
    return '$label के लिए। Kernel आपको इसी फ़ोन पर याद दिलाएगा।';
  }

  @override
  String reminderInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन में',
      one: '1 दिन में',
    );
    return '$_temp0';
  }

  @override
  String get reminderDateLabel => 'तारीख';

  @override
  String get reminderTimeLabel => 'समय';

  @override
  String get reminderOnDeviceNote =>
      'रिमाइंडर इसी फ़ोन पर तय होता है और बिना इंटरनेट के चलता है।';

  @override
  String get reminderSave => 'रिमाइंडर सेव करें';

  @override
  String get reminderPastError => 'आगे का कोई समय चुनें।';

  @override
  String get reminderSet => 'रिमाइंडर लग गया';

  @override
  String get reminderSetNotificationsOff =>
      'रिमाइंडर सेव हुआ। सूचनाएँ बंद हैं, इसलिए यह सिर्फ़ ऐप के अंदर दिखेगा।';

  @override
  String reminderFailed(String detail) {
    return 'रिमाइंडर नहीं लग सका: $detail';
  }

  @override
  String get fpoHomeTitle => 'गोदाम की झलक';

  @override
  String get fpoHomeSubtitle => 'गोदाम, कमरे और ढेर';

  @override
  String get fpoEmptyDetail =>
      'बोरियाँ दर्ज करें, फिर एक-एक करके उनकी आवाज़-जाँच करें ताकि जाँच की कतार बने।';

  @override
  String sacksScannedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आज $count बोरियों की आवाज़-जाँच हुई',
      one: 'आज 1 बोरी की आवाज़-जाँच हुई',
    );
    return '$_temp0';
  }

  @override
  String queueSummary(int flagged, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      needScan,
      locale: localeName,
      other: '$needScan बोरियों की आवाज़-जाँच बाकी',
      one: '1 बोरी की आवाज़-जाँच बाकी',
    );
    return '$flagged पर ध्यान दें · $_temp0';
  }

  @override
  String get assignedTitle => 'सौंपी गई जाँच';

  @override
  String get assignedNone => 'कोई खुली जाँच नहीं';

  @override
  String inspectionsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count जाँच खुली हैं',
      one: '1 जाँच खुली है',
    );
    return '$_temp0';
  }

  @override
  String get fpoAddLocationTitle => 'गोदाम, कमरा या ढेर जोड़ें';

  @override
  String get fpoAddLocationSubtitle =>
      'बोरियाँ कहाँ रखी हैं, उसके हिसाब से सजाएँ';

  @override
  String get buyerHomeTitle => 'आने वाले लॉट';

  @override
  String get buyerHomeSubtitle => 'खरीद से पहले जाँच';

  @override
  String get heroEyebrowDelivery => 'नया माल';

  @override
  String get buyerHeroTitle => 'आया माल दर्ज करें';

  @override
  String get buyerHeroSubtitle => 'सप्लायर, लॉट, अनाज, मात्रा';

  @override
  String get buyerHeroAction => 'दर्ज करें';

  @override
  String get lotsEmptyMessage => 'अभी कोई लॉट नहीं';

  @override
  String get lotsEmptyDetail => 'बोरियों की जाँच के लिए आया माल दर्ज करें।';

  @override
  String get lotsEmptyAction => 'अपना पहला आया माल दर्ज करें';

  @override
  String get buyerReportCardTitle => 'जाँच रिपोर्ट';

  @override
  String get buyerReportCardSubtitle =>
      'अपने रखे रिकॉर्ड से लॉट की जाँच रिपोर्ट निकालें';

  @override
  String lotTitle(String code, String grain) {
    return '$code / $grain';
  }

  @override
  String get lotNoSacks => 'इस लॉट में अभी कोई बोरी दर्ज नहीं';

  @override
  String lotScreenedCount(int screened, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total बोरियों',
      one: '1 बोरी',
    );
    return '$_temp0 में से $screened की जाँच हुई';
  }

  @override
  String supplierChip(String name) {
    return 'सप्लायर: $name';
  }

  @override
  String get scanAppBarTitle => 'आवाज़-जाँच';

  @override
  String get guidedScanTitle => 'बताए तरीके से आवाज़-जाँच';

  @override
  String get researchScanTitle => 'लेबल वाला नमूना रिकॉर्ड करें';

  @override
  String grainAndLabel(String grain, String label) {
    return '$grain • $label';
  }

  @override
  String get researchScanNoticeTitle => 'शोध रिकॉर्डिंग';

  @override
  String get researchScanNotice =>
      'यह 2 सेकंड की रिकॉर्डिंग इसी फ़ोन पर निजी रूप से रखी जाती है ताकि आप ट्रेनिंग डेटा के लिए उस पर लेबल लगा सकें। इसे कीड़ों के नतीजे के रूप में नहीं दिखाया जाता और कभी अपलोड नहीं किया जाता।';

  @override
  String positioningTip(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'फ़ोन को डिब्बे पर दबाएँ, बिना हिले और चुप रहें',
      'other': 'फ़ोन को बोरी पर दबाएँ, बिना हिले और चुप रहें',
    });
    return '$_temp0';
  }

  @override
  String positioningTipDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'शांत कमरे में फ़ोन को डिब्बे पर सपाट रखें, माइक उससे छूता रहे। 2 सेकंड तक बात न करें और इसे न हिलाएँ।',
      'other': 'शांत जगह पर फ़ोन को बोरी पर सपाट रखें, माइक उससे छूता रहे। 2 सेकंड तक बात न करें और बोरी को न हिलाएँ।',
    });
    return '$_temp0';
  }

  @override
  String get infoQualityTitle => 'रिकॉर्डिंग की गुणवत्ता';

  @override
  String get infoQualityBody =>
      'कोई भी नतीजा दिखाने से पहले पीछे का शोर, फटी आवाज़ और चुप्पी जाँची जाती है।';

  @override
  String get infoDurationTitle => 'रिकॉर्डिंग का समय';

  @override
  String get infoDurationShort => '2 सेकंड';

  @override
  String infoDurationRate(String khz) {
    return '$khz kHz पर 2 सेकंड';
  }

  @override
  String get infoOnDeviceTitle => 'फ़ोन पर ही जाँच';

  @override
  String get infoOnDeviceBody => 'अपलोड की ज़रूरत नहीं';

  @override
  String infoOnDeviceWithModel(String provenance) {
    return 'अपलोड की ज़रूरत नहीं। $provenance';
  }

  @override
  String get micDeniedTitle => 'माइक की अनुमति बंद है';

  @override
  String get micDeniedSubtitle =>
      'अनाज की आवाज़ सुनने के लिए Kernel को माइक चाहिए।';

  @override
  String get micDeniedPrivacy =>
      'आवाज़-जाँच 2 सेकंड की आवाज़ रिकॉर्ड करती है और उसे इसी फ़ोन पर जाँचती है। आवाज़ कभी अपलोड नहीं होती, और जाँच के बाद मिटा दी जाती है, जब तक आप सेटिंग में रिकॉर्डिंग रखना न चुनें।';

  @override
  String get micDeniedBlocked =>
      'Kernel के लिए माइक बंद है। फ़ोन की सेटिंग खोलें, अनुमतियाँ चुनें, फिर माइक की अनुमति दें।';

  @override
  String get micDeniedAskAgain =>
      'अगली बार Kernel के पूछने पर, या फ़ोन की सेटिंग में, आप अनुमति दे सकते हैं।';

  @override
  String get micDeniedStillUsable =>
      'माइक के बिना भी आप चीज़ें दर्ज कर सकते हैं, अपना भंडार देख सकते हैं, खोलकर जाँच दर्ज कर सकते हैं और रिपोर्ट बना सकते हैं।';

  @override
  String get actionOpenSettings => 'सेटिंग खोलें';

  @override
  String get actionTryAgain => 'फिर कोशिश करें';

  @override
  String get actionBrowseInventory => 'भंडार देखें';

  @override
  String get resultAppBarTitle => 'नतीजा';

  @override
  String get resultTitle => 'जाँच का नतीजा';

  @override
  String get scanNotFound => 'यह आवाज़-जाँच इस फ़ोन पर नहीं मिली।';

  @override
  String get retryNothingSaved =>
      'इस रिकॉर्डिंग के लिए कीड़ों के बारे में कुछ भी सेव नहीं हुआ।';

  @override
  String predictedClassLine(String label) {
    return 'मॉडल का अनुमान (पुष्टि नहीं): $label';
  }

  @override
  String modelScoreLine(String score) {
    return 'मॉडल स्कोर: $score (प्रायोगिक, यह सटीकता का आँकड़ा नहीं है)';
  }

  @override
  String get modelNoteTitleExperimental => 'प्रायोगिक मॉडल — परखा नहीं गया';

  @override
  String get modelNoteTitle => 'इस मॉडल के बारे में';

  @override
  String modelNoteOtherVersion(String version) {
    return 'इस आवाज़-जाँच में मॉडल $version इस्तेमाल हुआ था, जो अब फ़ोन पर नहीं है। उसकी जानकारी इस आवाज़-जाँच के साथ नहीं रखी गई, इसलिए नतीजे को प्रायोगिक ही मानें।';
  }

  @override
  String get physicalInspectionNote =>
      'आवाज़ से जाँच प्रायोगिक है। भंडारण या बिक्री का कोई भी फ़ैसला लेने से पहले खुद देखकर जाँच ज़रूरी है।';

  @override
  String get actionRetry => 'फिर से करें';

  @override
  String get actionRecordInspection => 'देखकर जाँच दर्ज करें';

  @override
  String get actionScanAnother => 'दूसरी आवाज़-जाँच';

  @override
  String get recordingDetails => 'रिकॉर्डिंग की जानकारी';

  @override
  String get fieldCaptured => 'रिकॉर्ड हुई';

  @override
  String get fieldDuration => 'समय';

  @override
  String get fieldSampleRate => 'सैंपल रेट';

  @override
  String get fieldAnalysisTime => 'जाँच में लगा समय';

  @override
  String get fieldDevice => 'फ़ोन';

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
      'container': 'वह डिब्बा चुनें जिसकी आवाज़ सुननी है',
      'other': 'वह बोरी चुनें जिसकी आवाज़ सुननी है',
    });
    return '$_temp0';
  }

  @override
  String get batchScanTitle => 'बारी-बारी आवाज़-जाँच';

  @override
  String get batchScanSubtitle => 'बोरियों की एक-एक करके आवाज़-जाँच करें';

  @override
  String get qrCardTitle => 'QR लेबल से खोलें';

  @override
  String qrCardSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'वह डिब्बा खोलने के लिए कैमरा Kernel लेबल की ओर करें',
      'other': 'वह बोरी खोलने के लिए कैमरा Kernel बोरी लेबल की ओर करें',
    });
    return '$_temp0';
  }

  @override
  String get oneAtATimeTitle => 'एक बार में एक';

  @override
  String get oneAtATimeBody =>
      'हर रिकॉर्डिंग एक ही चीज़ की होती है। चीज़ों की एक के बाद एक आवाज़-जाँच करें; एक आवाज़-जाँच कभी कई चीज़ों को एक साथ नहीं जाँचती।';

  @override
  String emptyItemsMessage(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'अभी कोई डिब्बा नहीं',
      'other': 'अभी कोई बोरी नहीं',
    });
    return '$_temp0';
  }

  @override
  String emptyItemsAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'अपना पहला डिब्बा जोड़ें',
      'other': 'अपनी पहली बोरी दर्ज करें',
    });
    return '$_temp0';
  }

  @override
  String get scanTabEmptyDetail =>
      'पहले एक दर्ज करें, फिर उसकी आवाज़-जाँच के लिए वापस आएँ।';

  @override
  String get scansTodayTitle => 'आज की आवाज़-जाँच';

  @override
  String scansTodaySummary(int scans, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items चीज़ों',
      one: '1 चीज़',
    );
    String _temp1 = intl.Intl.pluralLogic(
      scans,
      locale: localeName,
      other: '$scans आवाज़-जाँच',
      one: '1 आवाज़-जाँच',
    );
    return 'आधी रात से $_temp0 की $_temp1';
  }

  @override
  String get scansTodayEmpty =>
      'आज अभी कोई आवाज़-जाँच नहीं। आपकी रिकॉर्ड की गई आवाज़-जाँच तुरंत यहाँ दिखेंगी।';

  @override
  String get experimentalBadge => 'प्रायोगिक';

  @override
  String get errorCouldNotLoad => 'खुल नहीं सका';

  @override
  String errorWithDetail(String prefix, String detail) {
    return '$prefix: $detail';
  }

  @override
  String fieldLabel(String label) {
    return '$label:';
  }

  @override
  String get validationQuantityEmpty => 'मात्रा लिखें';

  @override
  String get validationQuantityPositive => '0 से बड़ी संख्या लिखें';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionSave => 'सेव करें';

  @override
  String get offlineLabel => 'ऑफ़लाइन';

  @override
  String get onlineLabel => 'ऑनलाइन';

  @override
  String get offlineSemantics =>
      'ऑफ़लाइन। फ़ोन पर सहेजे रिकॉर्ड और ऐप में शामिल जाँचें ऑफ़लाइन काम करती हैं; मॉडल डाउनलोड और ऑनलाइन नक्शों के लिए इंटरनेट चाहिए।';

  @override
  String get onlineSemantics =>
      'ऑनलाइन। फ़ोन पर सहेजे रिकॉर्ड और ऐप में शामिल जाँचें ऑफ़लाइन काम करती हैं; मॉडल डाउनलोड और ऑनलाइन नक्शों के लिए इंटरनेट चाहिए।';

  @override
  String get qrTooltip => 'QR लेबल से बोरी खोलें';

  @override
  String get menuTooltip => 'मेनू';

  @override
  String get menuSwitchRole => 'भूमिका बदलें';

  @override
  String get menuSettings => 'सेटिंग';

  @override
  String itemTileSubtitle(String grain, String quantity, String date) {
    return '$grain · $quantity · रखा $date';
  }

  @override
  String get archivedBadge => 'अलग रखा';

  @override
  String get chipRetryNeeded => 'फिर से करना है';

  @override
  String chipAiUnverified(String label) {
    return 'AI: $label (पुष्टि नहीं)';
  }

  @override
  String scanTileTitle(String item, String when) {
    return '$item · $when';
  }

  @override
  String qualityChip(String quality) {
    return 'गुणवत्ता: $quality';
  }

  @override
  String get chipAudioKept => 'आवाज़ फ़ोन पर रखी है';

  @override
  String photoSemantics(int number) {
    return 'सबूत की फ़ोटो $number। पूरी बड़ी खुलेगी।';
  }

  @override
  String get photoMissing => 'यह फ़ोटो अब इस फ़ोन पर नहीं है।';

  @override
  String get photoRemove => 'फ़ोटो हटाएँ';

  @override
  String verifiedFindingLine(String finding) {
    return 'पक्का नतीजा: $finding';
  }

  @override
  String inspectorLine(String inspector, String when) {
    return '$inspector · $when';
  }

  @override
  String followUpChip(String status) {
    return 'आगे की जाँच: $status';
  }

  @override
  String get unassigned => 'किसी को नहीं सौंपी';

  @override
  String assignedToChip(String name) {
    return '$name को सौंपी';
  }

  @override
  String get followUpChangeTooltip => 'आगे की जाँच की स्थिति बदलें';

  @override
  String get followUpUpdate => 'स्थिति बदलें';

  @override
  String get assignAction => 'सौंपें';

  @override
  String get archiveAction => 'अलग रखें';

  @override
  String archiveConfirmTitle(String name) {
    return '$name को अलग रखें?';
  }

  @override
  String get archiveConfirmItemBody =>
      'यह सूचियों, कतारों और नई रिपोर्टों में नहीं दिखेगा। इसकी आवाज़-जाँच का इतिहास और देखकर जाँच इस फ़ोन पर बनी रहेंगी और मिटेंगी नहीं।';

  @override
  String get archiveConfirmLotBody =>
      'लॉट आपकी सूचियों और नई रिपोर्टों में नहीं दिखेगा। इसकी बोरियाँ, उनका आवाज़-जाँच इतिहास और देखकर जाँच इस फ़ोन पर बनी रहेंगी।';

  @override
  String get archiveConfirmLocationBody =>
      'यह जगह सूचियों और चुनने की लिस्ट में नहीं दिखेगी। वहाँ रखी बोरियाँ, उनका आवाज़-जाँच इतिहास और देखकर जाँच इस फ़ोन पर बनी रहेंगी।';

  @override
  String get archiveConfirmHarvestBody =>
      'फ़सल आपकी सूचियों और नई रिपोर्टों में नहीं दिखेगी। इसकी बोरियाँ, उनका आवाज़-जाँच इतिहास और देखकर जाँच इस फ़ोन पर बनी रहेंगी।';

  @override
  String get levelMeterLabel => 'माइक की आवाज़ का स्तर';

  @override
  String get levelMeterWaiting => 'माइक्रोफ़ोन के स्तरों का इंतज़ार';

  @override
  String levelMeterValue(int dbfs) {
    return '$dbfs dBFS';
  }

  @override
  String get voicePlacePhone => 'फ़ोन बोरी पर रखें';

  @override
  String get voiceListening => 'सुन रहा है';

  @override
  String get voiceDone => 'हो गया';

  @override
  String scanCouldNotRun(String detail) {
    return 'आवाज़-जाँच नहीं चल सकी: $detail';
  }

  @override
  String scanCouldNotSave(String detail) {
    return 'आवाज़-जाँच का नतीजा सेव नहीं हो सका, इसलिए कुछ भी नहीं रखा गया। जानकारी: $detail';
  }

  @override
  String get captureReady => 'सुनने को तैयार';

  @override
  String get captureListening => 'सुन रहा है — बिना हिले रहें';

  @override
  String get captureSaving => 'इस फ़ोन पर सेव हो रहा है';

  @override
  String get captureCheckingMic => 'माइक की अनुमति देखी जा रही है';

  @override
  String get captureGetReady => 'तैयार हो जाएँ — फ़ोन रखें';

  @override
  String captureSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'फ़ोन को डिब्बे पर दबाएँ',
      'other': 'फ़ोन को बोरी पर दबाएँ',
    });
    return '$_temp0';
  }

  @override
  String get captureResearchSubtitle =>
      'शोध रिकॉर्डिंग: ये 2 सेकंड लेबल लगाने के लिए इसी फ़ोन पर निजी रूप से रखे जाते हैं';

  @override
  String get captureStart => '2 सेकंड की रिकॉर्डिंग शुरू करें';

  @override
  String get captureStartAgain => '2 सेकंड की रिकॉर्डिंग फिर से करें';

  @override
  String get captureStartResearch => 'लेबल वाला नमूना रिकॉर्ड करें (2 सेकंड)';

  @override
  String get captureProgressLabel => 'रिकॉर्डिंग कितनी हुई';

  @override
  String percentValue(int percent) {
    return '$percent प्रतिशत';
  }

  @override
  String captureElapsed(String elapsed, String target) {
    return '$target में से $elapsed सेकंड';
  }

  @override
  String get captureChecking => 'इस फ़ोन पर रिकॉर्डिंग जाँची जा रही है…';

  @override
  String get hintWaiting => 'सुन रहा है…';

  @override
  String get hintTooQuiet => 'बहुत धीमा — और पास दबाएँ';

  @override
  String get hintTooLoud => 'बहुत तेज़ / रगड़ की आवाज़';

  @override
  String get hintHoldStill => 'बिना हिले रहें';

  @override
  String get appTitle => 'Kernel';

  @override
  String get roleFarmer => 'किसान';

  @override
  String get roleHousehold => 'घर';

  @override
  String get roleStorageFpo => 'भंडारण/FPO';

  @override
  String get roleBuyer => 'खरीदार';

  @override
  String get roleFarmerTagline => 'फ़सल और बिक्री से पहले की जाँच';

  @override
  String get roleHouseholdTagline => 'डिब्बे और रिमाइंडर';

  @override
  String get roleStorageFpoTagline => 'गोदाम और बारी-बारी जाँच';

  @override
  String get roleBuyerTagline => 'सप्लायर और लॉट की जाँच';

  @override
  String get navHome => 'होम';

  @override
  String get navScan => 'आवाज़-जाँच';

  @override
  String get navInventory => 'भंडार';

  @override
  String get navReports => 'रिपोर्ट';

  @override
  String get navInventoryFarmer => 'मेरा अनाज';

  @override
  String get navInventoryHousehold => 'मेरे डिब्बे';

  @override
  String get navInventoryFpo => 'गोदाम';

  @override
  String get navInventoryBuyer => 'लॉट';

  @override
  String get reportTitleFarmer => 'बिक्री से पहले की रिपोर्ट';

  @override
  String get reportTitleHousehold => 'भंडारण रिपोर्ट';

  @override
  String get reportTitleFpo => 'गोदाम रिपोर्ट';

  @override
  String get reportTitleBuyer => 'लॉट जाँच रिपोर्ट';

  @override
  String get locationTypeHome => 'घर';

  @override
  String get locationTypeContainer => 'डिब्बा';

  @override
  String get locationTypeWarehouse => 'गोदाम';

  @override
  String get locationTypeRoom => 'कमरा';

  @override
  String get locationTypeStack => 'ढेर';

  @override
  String get screeningPending => 'बाकी';

  @override
  String get screeningScreening => 'जाँच चल रही है';

  @override
  String get screeningNeedsPhysicalCheck => 'खोलकर जाँच बाकी';

  @override
  String get screeningReviewed => 'देख लिया';

  @override
  String get findingNoneFound => 'कुछ नहीं मिला';

  @override
  String get findingPestsFound => 'कीड़े मिले';

  @override
  String get findingInconclusive => 'पता नहीं चला';

  @override
  String get findingNoneFoundHelp =>
      'मैंने जाँचा और कोई कीड़ा या नुकसान नहीं दिखा';

  @override
  String get findingPestsFoundHelp =>
      'मुझे कीड़े, इल्लियाँ, जाले या नुकसान दिखा';

  @override
  String get findingInconclusiveHelp => 'जाँच से मैं तय नहीं कर पाया';

  @override
  String get followUpOpen => 'खुली';

  @override
  String get followUpInProgress => 'चल रही है';

  @override
  String get followUpDone => 'हो गई';

  @override
  String get reminderScheduled => 'तय है';

  @override
  String get reminderFired => 'अभी का समय';

  @override
  String get reminderDone => 'हो गया';

  @override
  String get reminderCancelled => 'रद्द';

  @override
  String get reasonSilence =>
      'बहुत धीमा: माइक तक लगभग कोई आवाज़ नहीं पहुँची। फ़ोन को अनाज पर ज़ोर से दबाएँ।';

  @override
  String get reasonClipping =>
      'बहुत तेज़: आवाज़ फट गई। रिकॉर्डिंग के समय थपथपाएँ, रगड़ें या ठोकें नहीं।';

  @override
  String get reasonHighNoise =>
      'पीछे बहुत शोर है। किसी शांत जगह जाएँ और बिना हिले रहें।';

  @override
  String get reasonTooShort =>
      'रिकॉर्डिंग बहुत छोटी थी। पूरे 2 सेकंड फ़ोन बिना हिलाए रखें।';

  @override
  String get reasonPermissionDenied =>
      'माइक की अनुमति बंद है। आवाज़-जाँच के लिए फ़ोन की सेटिंग में इसकी अनुमति दें।';

  @override
  String get reasonCaptureError =>
      'माइक रिकॉर्ड नहीं कर सका। माइक इस्तेमाल करने वाले दूसरे ऐप बंद करें और फिर कोशिश करें।';

  @override
  String get qualityPass => 'काम की';

  @override
  String get qualityRetry => 'फिर से करें';

  @override
  String get predictionClean => 'कोई संकेत नहीं मिला';

  @override
  String get predictionUncertain => 'पक्का नहीं';

  @override
  String get predictionInfested => 'कीड़े होने की आशंका';

  @override
  String get predictionNotEvaluated => 'नतीजा नहीं बना';

  @override
  String get sampleLabelClean => 'कोई निशान नहीं';

  @override
  String get sampleLabelInfested => 'कीड़े लगे';

  @override
  String get sampleLabelUnknown => 'पता नहीं';

  @override
  String get headlineRetry => 'रिकॉर्डिंग काम की नहीं — फिर से करें';

  @override
  String get headlineNotEvaluated =>
      'नतीजा नहीं बना — कोई मॉडल नहीं लगा है। अनाज को खुद देखकर जाँचें।';

  @override
  String get headlineNotEvaluatedWithModel =>
      'नतीजा नहीं बना — मॉडल इस रिकॉर्डिंग को जाँच नहीं सका। अनाज को खुद देखकर जाँचें।';

  @override
  String get headlineInspectionNeeded =>
      'देखकर जाँच ज़रूरी — मॉडल के नतीजे की पुष्टि नहीं हुई है';

  @override
  String get headlineClean =>
      'कोई संकेत नहीं मिला — यह गारंटी नहीं है; बेचने/रखने का फ़ैसला करने से पहले खुद देखकर जाँचें';

  @override
  String get provenanceNone => 'मॉडल: कोई नहीं — नतीजा नहीं बना';

  @override
  String provenanceExperimental(String version) {
    return 'मॉडल $version — प्रायोगिक';
  }

  @override
  String provenanceValidated(String version) {
    return 'मॉडल $version — परखा हुआ';
  }

  @override
  String dateTimeJoin(String date, String time) {
    return '$date, $time';
  }

  @override
  String get nextStepEyebrow => 'अगला कदम';

  @override
  String get nextNothingPending =>
      'अभी कुछ ज़रूरी नहीं है। हिसाब रखने के लिए नियमित आवाज़-जाँच करते रहें।';

  @override
  String get quickScanAction => 'अभी आवाज़-जाँच करें';

  @override
  String scansTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आज $count आवाज़-जाँच',
      one: 'आज 1 आवाज़-जाँच',
      zero: 'आज कोई आवाज़-जाँच नहीं',
    );
    return '$_temp0';
  }

  @override
  String scanActivityLine(int today, int week) {
    return 'आवाज़-जाँच: आज $today · पिछले 7 दिनों में $week';
  }

  @override
  String nextRegisterFirst(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'अपना पहला डिब्बा दर्ज करें',
      'other': 'अपनी पहली बोरी दर्ज करें',
    });
    return '$_temp0';
  }

  @override
  String get nextRegisterFirstBody =>
      'नाम, अनाज और मात्रा लिखें। एक मिनट लगता है।';

  @override
  String get nextRegisterFirstLot => 'अपनी पहली खेप दर्ज करें';

  @override
  String get nextRegisterFirstLotBody => 'सप्लायर, लॉट, अनाज और मात्रा।';

  @override
  String nextScanOne(String label) {
    return '$label की आवाज़-जाँच करें';
  }

  @override
  String nextScanSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बोरियों की आवाज़-जाँच बाकी है',
      one: '1 बोरी की आवाज़-जाँच बाकी है',
    );
    return '$_temp0';
  }

  @override
  String nextScanContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डिब्बों की आवाज़-जाँच बाकी है',
      one: '1 डिब्बे की आवाज़-जाँच बाकी है',
    );
    return '$_temp0';
  }

  @override
  String nextScanBody(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'फ़ोन को डिब्बे पर दबाकर 2 सेकंड की सुनने वाली जाँच।',
      'other': '2 सेकंड की सुनने वाली जाँच, एक बार में एक बोरी।',
    });
    return '$_temp0';
  }

  @override
  String nextInspectOne(String label) {
    return '$label की देखकर जाँच करें';
  }

  @override
  String nextInspectSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'निशान लगी $count बोरियों की देखकर जाँच करें',
      one: 'निशान लगी 1 बोरी की देखकर जाँच करें',
    );
    return '$_temp0';
  }

  @override
  String nextInspectContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'निशान लगे $count डिब्बों की देखकर जाँच करें',
      one: 'निशान लगे 1 डिब्बे की देखकर जाँच करें',
    );
    return '$_temp0';
  }

  @override
  String get nextInspectBody =>
      'मॉडल के नतीजे की पुष्टि नहीं हुई है। अनाज को हाथ से जाँचें।';

  @override
  String nextReviewOne(String label) {
    return '$label: दोबारा जाँच का समय';
  }

  @override
  String nextReviewSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बोरियों की दोबारा जाँच का समय',
      one: '1 बोरी की दोबारा जाँच का समय',
    );
    return '$_temp0';
  }

  @override
  String nextReviewContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डिब्बों की दोबारा जाँच का समय',
      one: '1 डिब्बे की दोबारा जाँच का समय',
    );
    return '$_temp0';
  }

  @override
  String get nextReviewBody =>
      'पिछली जाँच को काफ़ी समय हो गया। फिर से सुनें या देखकर जाँचें।';

  @override
  String nextReminderOne(String label) {
    return '$label: रिमाइंडर का समय';
  }

  @override
  String nextReminderMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिमाइंडर का समय',
      one: '1 रिमाइंडर का समय',
    );
    return '$_temp0';
  }

  @override
  String get nextReminderBody =>
      'आपकी लगाई दोबारा जाँच का समय आ गया है। इस अनाज को जाँचें।';

  @override
  String nextPhysicalOne(String label) {
    return 'लॉट $label: देखकर जाँच बाकी';
  }

  @override
  String nextPhysicalMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लॉट की देखकर जाँच बाकी',
      one: '1 लॉट की देखकर जाँच बाकी',
    );
    return '$_temp0';
  }

  @override
  String get nextPhysicalBody =>
      'लॉट खोलें और जाँच करने वाले ने जो देखा वह दर्ज करें। Kernel कभी भी लॉट मंज़ूर या नामंज़ूर नहीं करता।';

  @override
  String get nextFinishBatch => 'बारी-बारी जाँच पूरी करें';

  @override
  String nextFinishBatchOne(String label) {
    return 'बारी-बारी जाँच पूरी करें: $label';
  }

  @override
  String nextFinishBatchBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बोरियाँ बाकी, एक बार में एक',
      one: '1 बोरी बाकी, एक बार में एक',
      zero: 'इस बैच की हर बोरी की आवाज़-जाँच हो चुकी है',
    );
    return '$_temp0';
  }

  @override
  String get nextPreSale => 'बिक्री से पहले की रिपोर्ट भेजें';

  @override
  String nextPreSaleOne(String label) {
    return '$label की बिक्री से पहले की रिपोर्ट भेजें';
  }

  @override
  String get nextLotSummary => 'लॉट का सारांश भेजें';

  @override
  String nextLotSummaryOne(String label) {
    return '$label का लॉट सारांश भेजें';
  }

  @override
  String get nextExportBody =>
      'आपके रिकॉर्ड से इसी फ़ोन पर बनी। किसे भेजनी है, आप तय करें।';

  @override
  String get nextActionRegister => 'दर्ज करें';

  @override
  String get nextActionScan => 'आवाज़-जाँच शुरू करें';

  @override
  String get nextActionBatch => 'बारी-बारी जाँच शुरू करें';

  @override
  String get nextActionOpen => 'खोलें';

  @override
  String get nextActionQueue => 'जाँच की कतार खोलें';

  @override
  String get nextActionOpenLot => 'लॉट खोलें';

  @override
  String get nextActionContinueBatch => 'बारी-बारी जाँच जारी रखें';

  @override
  String get nextActionReport => 'रिपोर्ट खोलें';

  @override
  String get insightsTitle => 'जानकारी';

  @override
  String get insightsSubtitle => 'आपके अपने रिकॉर्ड से इसी फ़ोन पर निकाली गई';

  @override
  String get insightsCardSubtitle =>
      'नतीजे, रिकॉर्डिंग की दिक्कतें और किसे जाँच चाहिए';

  @override
  String get insightsWindowLabel => 'समय';

  @override
  String get insightsWindow7 => '7 दिन';

  @override
  String get insightsWindow30 => '30 दिन';

  @override
  String get insightsWindowAll => 'पूरा समय';

  @override
  String get insightsActivityTitle => 'आवाज़-जाँच का काम';

  @override
  String get insightsScansToday => 'आज की आवाज़-जाँच';

  @override
  String get insightsScans7 => 'पिछले 7 दिनों की आवाज़-जाँच';

  @override
  String get insightsRatesTitle => 'नतीजे';

  @override
  String get insightsRatesEmpty => 'इस समय में कोई आवाज़-जाँच नहीं';

  @override
  String get insightsRatesEmptyDetail =>
      'यहाँ नतीजे देखने के लिए किसी बोरी या डिब्बे की आवाज़-जाँच करें।';

  @override
  String get insightsExperimentalNote =>
      'प्रायोगिक मॉडल: इन नतीजों की पुष्टि नहीं हुई है और ये गलत हो सकते हैं। भंडारण या बिक्री के किसी भी फ़ैसले से पहले खुद देखकर जाँचें।';

  @override
  String get insightsNoModelResults =>
      'अभी मॉडल का कोई नतीजा नहीं: किसी भी काम की रिकॉर्डिंग को मॉडल ने नहीं परखा।';

  @override
  String get insightsRetryLabel => 'रिकॉर्डिंग काम की नहीं (फिर से करें)';

  @override
  String insightsBarValue(int count, int percent) {
    return '$count · $percent%';
  }

  @override
  String insightsTotalScans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'इस समय में $count आवाज़-जाँच',
      one: 'इस समय में 1 आवाज़-जाँच',
    );
    return '$_temp0';
  }

  @override
  String get insightsQualityTitle => 'रिकॉर्डिंग की दिक्कतें';

  @override
  String get insightsQualityEmpty => 'इस समय में कोई बेकार रिकॉर्डिंग नहीं';

  @override
  String get insightsQualityHint =>
      'फ़ोन को शांत जगह पर बोरी पर ज़ोर से दबाने से ज़्यादातर दिक्कतें दूर हो जाती हैं।';

  @override
  String get insightsInspectionsTitle => 'देखकर जाँच';

  @override
  String get insightsInspectionsEmpty => 'अभी कोई जाँच दर्ज नहीं';

  @override
  String insightsClosureRate(int percent) {
    return '$percent% जाँच पूरी हो गई हैं';
  }

  @override
  String get insightsStaleTitle => 'सबसे लंबे समय से बिना जाँच';

  @override
  String get staleNeverScanned => 'कभी आवाज़-जाँच नहीं हुई';

  @override
  String get qualityShortSilence => 'बहुत धीमा';

  @override
  String get qualityShortClipping => 'बहुत तेज़ (आवाज़ फटी)';

  @override
  String get qualityShortHighNoise => 'बहुत शोर';

  @override
  String get qualityShortTooShort => 'बहुत छोटी';

  @override
  String get qualityShortPermissionDenied => 'माइक बंद है';

  @override
  String get qualityShortCaptureError => 'रिकॉर्डिंग में गड़बड़ी';

  @override
  String get queueFilterResult => 'मॉडल का नतीजा';

  @override
  String get queueFilterAllResults => 'सभी नतीजे';

  @override
  String get queueFilterPlace => 'जगह';

  @override
  String get queueFilterAllPlaces => 'सभी जगहें';

  @override
  String get queueFilterAge => 'आख़िरी काम की आवाज़-जाँच';

  @override
  String get queueFilterAnyAge => 'कभी भी';

  @override
  String queueFilterWithinDays(int days) {
    return '$days दिन के अंदर';
  }

  @override
  String queueFilterAgeNote(int days) {
    return 'जिनकी आख़िरी काम की आवाज़-जाँच $days दिन से पुरानी है, वे \"आवाज़-जाँच बाकी\" में चली जाती हैं।';
  }

  @override
  String get queueNoMatch => 'इन फ़िल्टर से कोई चीज़ मेल नहीं खाती।';

  @override
  String get rankReasonInfested =>
      'यहाँ क्यों: कीड़े होने की आशंका (पुष्टि नहीं हुई)';

  @override
  String get rankReasonUncertain => 'यहाँ क्यों: मॉडल पक्का नहीं था';

  @override
  String get rankReasonClean => 'नीचे क्यों: कोई संकेत नहीं मिला (गारंटी नहीं)';

  @override
  String scannedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन पहले आवाज़-जाँच हुई',
      one: '1 दिन पहले आवाज़-जाँच हुई',
      zero: 'आज आवाज़-जाँच हुई',
    );
    return '$_temp0';
  }

  @override
  String get reminderSuggestedLabel => 'सुझाव — फ़ैसला आपका';

  @override
  String reminderSuggestedOther(String date) {
    return 'सुझाव: $date — फ़ैसला आपका';
  }

  @override
  String get reminderWordingTitle => 'सुझाए गए शब्द';

  @override
  String get settingsAdviceSection => 'फ़ोन पर AI सहायक (प्रायोगिक)';

  @override
  String get adviceToggle => 'फ़ोन पर AI सहायक चालू करें';

  @override
  String get adviceToggleBody =>
      'शुरू में बंद रहता है। यह सिर्फ़ इसी फ़ोन पर चलता है और आपकी रिकॉर्डिंग कभी नहीं सुनता; यह सिर्फ़ नतीजे और तारीखें देखता है। यह गलत हो सकता है। आप इसे कभी भी बंद कर सकते हैं।';

  @override
  String get adviceStatusTitle => 'सहायक की स्थिति';

  @override
  String get adviceStatusOff => 'बंद';

  @override
  String get adviceStatusNoModel => 'चालू — अभी कोई मॉडल नहीं लाया गया';

  @override
  String get adviceStatusLoading => 'मॉडल खुल रहा है…';

  @override
  String get adviceStatusReady => 'इस फ़ोन पर तैयार';

  @override
  String get adviceStatusBusy => 'लिख रहा है';

  @override
  String get adviceStatusFailed =>
      'मॉडल नहीं खुल सका — Kernel अपना सामान्य लिखा हुआ दिखाता है';

  @override
  String get adviceModelTitle => 'सहायक का मॉडल';

  @override
  String get adviceModelNone => 'अभी कोई मॉडल नहीं लाया गया';

  @override
  String get adviceModelId => 'मॉडल';

  @override
  String get adviceModelVersion => 'संस्करण';

  @override
  String get adviceModelSize => 'आकार';

  @override
  String get adviceModelBackend => 'किस पर चलता है';

  @override
  String get adviceBackendGpu => 'फ़ोन की ग्राफ़िक्स चिप (GPU)';

  @override
  String get adviceBackendCpu => 'फ़ोन का प्रोसेसर (CPU)';

  @override
  String get adviceBackendNone => 'अभी खुला नहीं';

  @override
  String get adviceImportAction => 'मॉडल लाएँ';

  @override
  String get adviceImporting => 'मॉडल लाया जा रहा है';

  @override
  String adviceImportCopying(String copied, String total) {
    return '$total में से $copied कॉपी हुआ';
  }

  @override
  String adviceImportCopied(String copied) {
    return '$copied कॉपी हुआ';
  }

  @override
  String get adviceImportVerifying => 'मॉडल फ़ाइल जाँची जा रही है…';

  @override
  String get adviceImportDone => 'मॉडल आ गया। यह इसी फ़ोन पर रहता है।';

  @override
  String adviceImportFailed(String detail) {
    return 'मॉडल नहीं लाया जा सका: $detail';
  }

  @override
  String adviceImportNoSpace(String needed, String free) {
    return 'जगह कम है: मॉडल को $needed चाहिए, पर इस फ़ोन में सिर्फ़ $free खाली है।';
  }

  @override
  String get adviceDeleteAction => 'मॉडल मिटाएँ';

  @override
  String get adviceDeleteConfirmTitle => 'सहायक का मॉडल मिटाएँ?';

  @override
  String get adviceDeleteConfirmBody =>
      'इससे मॉडल फ़ाइल इस फ़ोन से हट जाएगी। आपके रिकॉर्ड पर कोई असर नहीं होगा। आप बाद में इसे फिर ला सकते हैं।';

  @override
  String adviceDeleteFailed(String detail) {
    return 'मॉडल नहीं मिटाया जा सका: $detail';
  }

  @override
  String get adviceHelp =>
      'Google AI Edge Gallery से या Hugging Face litert-community/gemma-4-E2B-it-litert-lm से .litertlm मॉडल लें (Gemma की शर्तें लागू), फिर उसे यहाँ लाएँ।';

  @override
  String adviceProvenance(String modelVersion) {
    return 'इसी फ़ोन पर बना — प्रायोगिक · $modelVersion';
  }

  @override
  String get adviceNotDecision => 'यह फ़ैसला नहीं है — खुद देखकर जाँचें';

  @override
  String get adviceGenerating => 'इसी फ़ोन पर लिखा जा रहा है…';

  @override
  String get adviceExplainAction => 'इस नतीजे को समझाएँ';

  @override
  String get adviceExplainTitle => 'इस नतीजे का मतलब';

  @override
  String get adviceStaticRetry =>
      'रिकॉर्डिंग काम की नहीं थी, इसलिए कोई नतीजा नहीं सहेजा गया। फ़ोन को बोरी या डिब्बे पर ज़ोर से दबाएँ, हिलें नहीं, शांति रखें और फिर से रिकॉर्ड करें।';

  @override
  String get adviceStaticNotEvaluated =>
      'इस रिकॉर्डिंग का कोई नतीजा नहीं बना, इसलिए इससे कीड़ों के बारे में कुछ पता नहीं चलता। अनाज को खुद देखकर जाँचें।';

  @override
  String get adviceStaticInspection =>
      'प्रायोगिक मॉडल को कुछ ऐसा सुनाई दिया जिस पर ध्यान देना पड़ सकता है। इसकी पुष्टि नहीं हुई है। कोई भी फ़ैसला लेने से पहले अनाज को खुद देखकर जाँचें।';

  @override
  String get adviceStaticClean =>
      'प्रायोगिक मॉडल को कोई संकेत नहीं मिला। यह गारंटी नहीं है। भंडारण या बिक्री का फ़ैसला लेने से पहले अनाज को खुद देखकर जाँचें।';

  @override
  String get reportAiSummaryToggle => 'AI से बना सारांश जोड़ें';

  @override
  String get reportAiSummaryBody =>
      'रिपोर्ट के आँकड़ों से इसी फ़ोन पर बना। पहले आप इसे देखें और तय करें कि जोड़ना है या नहीं। प्रायोगिक।';

  @override
  String get reportAiPreviewTitle => 'AI से बना सारांश';

  @override
  String get reportAiPreviewBody =>
      'जोड़ने पर यह रिपोर्ट में अपने अलग, नाम लगे हिस्से में दिखेगा — आपके रिकॉर्ड और जाँच के नतीजों से अलग। इसे बदला नहीं जा सकता।';

  @override
  String get reportAiSummaryTitle => 'सारांश का मसौदा';

  @override
  String get reportAiInclude => 'जोड़ें';

  @override
  String get reportAiSkip => 'छोड़ें';

  @override
  String unitGb(String value) {
    return '$value GB';
  }

  @override
  String unitMb(String value) {
    return '$value MB';
  }

  @override
  String get hubTitle => 'मॉडल हब';

  @override
  String get hubSubtitle =>
      'Android ऐप में WAV क्लिप से कीटों का प्रयोगात्मक वर्गीकरण शामिल है। नीचे दिए गए वैकल्पिक डाउनलोड तस्वीरों का विश्लेषण, खोज और लाइव ध्वनि वर्गीकरण (YAMNet) जोड़ते हैं।';

  @override
  String get hubNeedsTitle => 'वैकल्पिक मॉडल डाउनलोड';

  @override
  String get hubNeedImage => 'तस्वीर समझना';

  @override
  String get hubNeedEmbeddings => 'एम्बेडिंग (खोज के लिए)';

  @override
  String get hubNeedSound => 'लाइव ध्वनि वर्गीकरण मॉडल (YAMNet)';

  @override
  String get hubInstalledChip => 'लगा हुआ है';

  @override
  String get hubMissingChip => 'नहीं है';

  @override
  String get hubAllInstalled =>
      'यहाँ दी गई सभी वैकल्पिक सुविधाओं के मॉडल इंस्टॉल हैं।';

  @override
  String get hubNothingToDownload =>
      'जो वैकल्पिक मॉडल अभी नहीं हैं, उनके लिए कोई डाउनलोड उपलब्ध नहीं है।';

  @override
  String hubDownloadSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वैकल्पिक मॉडल डाउनलोड करने हैं, लगभग $size',
      one: '1 वैकल्पिक मॉडल डाउनलोड करना है, लगभग $size',
    );
    return '$_temp0';
  }

  @override
  String get hubDownloadAction => 'वैकल्पिक मॉडल डाउनलोड करें';

  @override
  String hubDownloadFailed(String error) {
    return 'डाउनलोड शुरू नहीं हो सका: $error';
  }

  @override
  String get hubCatalogUnavailable => 'मॉडल की सूची नहीं पढ़ी जा सकी';

  @override
  String get hubInstalledUnavailable =>
      'इंस्टॉल किए गए वैकल्पिक मॉडल पढ़े नहीं जा सके';

  @override
  String get hubGalleryNote =>
      'Kernel उन फ़ाइलों का इस्तेमाल नहीं कर सकता जो AI Edge Gallery पहले ही डाउनलोड कर चुका है (Android हर ऐप की फ़ाइलें निजी रखता है), इसलिए वह वही मॉडल एक बार डाउनलोड करता है।';

  @override
  String get hubConsentTitle => 'कीट पहचान के वैकल्पिक मॉडल डाउनलोड करें?';

  @override
  String get hubConsentBody =>
      'ये मॉडल एक बार डाउनलोड होते हैं और फिर सिर्फ़ इसी फ़ोन पर चलते हैं। आप जो भी रिकॉर्ड करते हैं, वह कभी अपलोड नहीं होता।';

  @override
  String hubConsentSize(String size) {
    return 'आकार: $size';
  }

  @override
  String hubConsentLicense(String license) {
    return 'लाइसेंस: $license';
  }

  @override
  String hubConsentModelCard(String url) {
    return 'मॉडल कार्ड: $url';
  }

  @override
  String get hubSourceHf => 'Hugging Face से डाउनलोड';

  @override
  String get hubSourceGoogle => 'Google AI Edge से डाउनलोड';

  @override
  String hubSourceOther(String host) {
    return '$host से डाउनलोड';
  }

  @override
  String get hubWifiOnly => 'सिर्फ़ Wi-Fi पर';

  @override
  String get hubWifiOnlyBody =>
      'डाउनलोड से पहले Wi-Fi का इंतज़ार करें। ये फ़ाइलें बड़ी हैं।';

  @override
  String hubConsentTotal(String size) {
    return 'कुल: लगभग $size';
  }

  @override
  String get hubConsentAgree => 'सहमत हूँ, डाउनलोड करें';

  @override
  String get hubConsentNotNow => 'अभी नहीं';

  @override
  String get hubConsentGrantedTitle => 'मॉडल डाउनलोड की अनुमति दी गई';

  @override
  String get hubDownloadsTitle => 'डाउनलोड';

  @override
  String get hubPhaseQueued => 'शुरू होने का इंतज़ार';

  @override
  String get hubPhaseWifi => 'Wi-Fi का इंतज़ार';

  @override
  String hubPhaseSpace(String size) {
    return 'खाली जगह का इंतज़ार: $size चाहिए';
  }

  @override
  String hubFreeSpace(String free) {
    return 'इस फ़ोन पर $free खाली';
  }

  @override
  String hubPhaseDownloading(String done, String total) {
    return 'डाउनलोड हो रहा है: $total में से $done';
  }

  @override
  String get hubPhaseVerifying => 'फ़ाइल जाँची जा रही है';

  @override
  String get hubPhasePaused => 'रुका हुआ';

  @override
  String hubPhaseFailed(String reason) {
    return 'नहीं हो सका: $reason';
  }

  @override
  String get hubCancel => 'रद्द करें';

  @override
  String get hubInstalledTitle => 'इंस्टॉल किए गए वैकल्पिक मॉडल';

  @override
  String get hubInstalledEmpty => 'अभी कोई वैकल्पिक मॉडल इंस्टॉल नहीं है';

  @override
  String get hubInstalledEmptyDetail =>
      'Android ऐप में शामिल कीटों की WAV जाँच के लिए ये डाउनलोड ज़रूरी नहीं हैं।';

  @override
  String get hubFieldPath => 'फ़ाइल';

  @override
  String get hubFieldSize => 'आकार';

  @override
  String get hubFieldVersion => 'संस्करण';

  @override
  String get hubFieldCapabilities => 'क्या कर सकता है';

  @override
  String get hubFieldBackends => 'किस पर चलता है';

  @override
  String get hubMatchesGallery => 'AI Edge Gallery वाली फ़ाइल जैसी';

  @override
  String get hubRemove => 'हटाएँ';

  @override
  String get hubRemoveConfirmTitle => 'यह मॉडल हटाएँ?';

  @override
  String get hubRemoveConfirmBody =>
      'फ़ाइल इस फ़ोन से मिट जाएगी। जिन हिस्सों को इसकी ज़रूरत है, वे दोबारा डाउनलोड होने तक बंद रहेंगे।';

  @override
  String hubRemoveFailed(String error) {
    return 'हटाया नहीं जा सका: $error';
  }

  @override
  String get hubCapTextGen => 'लिखना';

  @override
  String get hubCapImageIn => 'तस्वीर समझना';

  @override
  String get hubCapAudioIn => 'आवाज़ समझना';

  @override
  String get hubCapEmbedText => 'शब्दों की एम्बेडिंग';

  @override
  String get hubCapEmbedImage => 'तस्वीर की एम्बेडिंग';

  @override
  String get hubCapEmbedAudio => 'आवाज़ की एम्बेडिंग';

  @override
  String get hubCapAudioClassify => 'आवाज़ पहचानना';

  @override
  String get hubCapImageClassify => 'तस्वीर पहचानना';

  @override
  String get hubCapObjectDetect => 'चीज़ें ढूँढना';

  @override
  String get hubCapSegment => 'आकार की रेखा ढूँढना';

  @override
  String get hubCapSensorClassify => 'सेंसर संकेत पहचानना';

  @override
  String get hubSearchHint => 'मॉडल और कीट जानकारी खोजें';

  @override
  String get hubSearchAction => 'खोजें';

  @override
  String get hubSearchModels => 'मॉडल';

  @override
  String get hubSearchPestInfo => 'कीट जानकारी';

  @override
  String hubSearchScore(String score) {
    return 'मिलान $score';
  }

  @override
  String get hubSearchNoResults => 'कुछ नहीं मिला। दूसरे शब्द आज़माएँ।';

  @override
  String hubSearchFailed(String error) {
    return 'खोज अभी उपलब्ध नहीं है: $error';
  }

  @override
  String get hubSearchNote =>
      'खोज इसी फ़ोन पर चलती है। मिलान का अंक भरोसे का अंक नहीं है।';

  @override
  String get hubNeedsReview => 'विशेषज्ञ की जाँच बाकी';

  @override
  String get hubSettingsSection => 'कीट पहचान, नक्शे और सेंसर';

  @override
  String get hubSettingsCard =>
      'तस्वीरों, खोज और लाइव ध्वनि के लिए वैकल्पिक मॉडल डाउनलोड सँभालें।';

  @override
  String get hubMapsToggle => 'Google Maps इस्तेमाल करें';

  @override
  String get hubMapsToggleBody =>
      'Google को सिर्फ़ नक्शे का हिस्सा और रास्ते की शुरुआत और अंत भेजा जाता है। कीट का नाम, नोट, फ़ोटो या आवाज़ कभी नहीं।';

  @override
  String get hubMapsConfirmTitle => 'Google Maps की अनुमति दें?';

  @override
  String get hubMapsConfirmBody =>
      'नक्शों के लिए इंटरनेट चाहिए। Google को सिर्फ़ नक्शे का वह हिस्सा जो आप देखते हैं और रास्ते की शुरुआत और अंत मिलता है। Kernel कभी कीट का नाम, नोट, फ़ोटो, आवाज़ या सेंसर डेटा नहीं भेजता। आप इसे कभी भी बंद कर सकते हैं।';

  @override
  String get hubMapsConfirmAgree => 'नक्शे चालू करें';

  @override
  String get hubKeepMediaToggle => 'देखे गए कीटों के साथ फ़ोटो और क्लिप रखें';

  @override
  String get hubKeepMediaToggleBody =>
      'बंद होने पर, जाँच के बाद फ़ोटो या आवाज़ की क्लिप मिटा दी जाती है। रखी गई फ़ाइलें इसी फ़ोन पर रहती हैं।';

  @override
  String get sensorTitle => 'सेंसर';

  @override
  String get sensorSubtitle =>
      'जोड़े गए सुनने वाले यंत्र। ये संकेत भेजते हैं, निदान नहीं।';

  @override
  String get sensorEmpty => 'अभी कोई सेंसर नहीं जुड़ा';

  @override
  String get sensorEmptyDetail =>
      'Kernel सेंसर पर लगा QR लेबल स्कैन करके उसे जोड़ें।';

  @override
  String get sensorPairAction => 'सेंसर जोड़ें';

  @override
  String get sensorPrivacyNote =>
      'सेंसर सिर्फ़ आवाज़ की विशेषताएँ भेजते हैं, आवाज़ कभी नहीं। सब कुछ इसी फ़ोन पर रहता है।';

  @override
  String get sensorSettingsCard => 'ब्लूटूथ सेंसर जोड़ें और जाँचें।';

  @override
  String get sensorTypeUsAir => 'अल्ट्रासोनिक (हवा)';

  @override
  String get sensorTypeContactPiezo => 'छूकर (पीज़ो)';

  @override
  String get sensorTypeContactAccel => 'छूकर (कंपन)';

  @override
  String get sensorTypeAudioAir => 'आवाज़ (हवा)';

  @override
  String get sensorLinkUnpaired => 'जुड़ा नहीं';

  @override
  String get sensorLinkPairing => 'जुड़ रहा है';

  @override
  String get sensorLinkConnecting => 'कनेक्ट हो रहा है';

  @override
  String get sensorLinkConnected => 'कनेक्ट है';

  @override
  String get sensorLinkAuthenticated => 'सुरक्षित रूप से कनेक्ट';

  @override
  String get sensorLinkDisconnected => 'कनेक्ट नहीं';

  @override
  String get sensorLinkError => 'कनेक्शन में दिक्कत';

  @override
  String get sensorStatusUnknown => 'स्थिति पता नहीं';

  @override
  String sensorBattery(int percent) {
    return 'बैटरी $percent%';
  }

  @override
  String get sensorBatteryUnknown => 'बैटरी पता नहीं';

  @override
  String get sensorHealthOk => 'सेंसर काम कर रहा है';

  @override
  String get sensorHealthJammed =>
      'जाम — पास में अल्ट्रासोनिक स्रोत है (जैसे कीट भगाने की मशीन); नतीजे जाँचे नहीं गए';

  @override
  String get sensorHealthClipped => 'आवाज़ बहुत तेज़ (क्लिप)';

  @override
  String get sensorHealthLowBattery => 'बैटरी कम';

  @override
  String get sensorHealthSurveyNeeded => 'सर्वे ज़रूरी';

  @override
  String get sensorHealthAuthFailed => 'सुरक्षा जाँच नहीं हुई — फिर से जोड़ें';

  @override
  String get sensorHealthSensorFault => 'सेंसर में खराबी — जाँच नहीं हुई';

  @override
  String get sensorHealthEventsOverwritten =>
      'कुछ घटनाएँ छूट गईं — इस अवधि की जाँच नहीं हुई';

  @override
  String get sensorNotEvaluatedTitle => 'जाँचा नहीं गया';

  @override
  String get sensorNotEvaluatedBody =>
      'यह सेंसर अभी जाँच नहीं कर सकता। इसका मतलब यह नहीं कि वहाँ कुछ नहीं है। खुद देखकर जाँचें।';

  @override
  String get sensorPairTitle => 'सेंसर जोड़ें';

  @override
  String get sensorPairInstructions => 'कैमरा सेंसर पर लगे QR लेबल की ओर करें।';

  @override
  String get sensorPairPrivacy =>
      'लेबल में सेंसर की सुरक्षा कुंजी है। यह इस फ़ोन पर सुरक्षित जगह रखी जाती है और कभी दिखाई या भेजी नहीं जाती।';

  @override
  String get sensorPairNotSensor => 'यह Kernel सेंसर का लेबल नहीं है।';

  @override
  String get sensorPairing =>
      'जोड़ा जा रहा है। Android का जोड़ने का अनुरोध स्वीकार करें।';

  @override
  String get sensorPairCancelled => 'जोड़ना रद्द हो गया।';

  @override
  String sensorPairFailed(String error) {
    return 'जोड़ा नहीं जा सका: $error';
  }

  @override
  String get sensorPairTryAgain => 'फिर से स्कैन करें';

  @override
  String sensorPairedSnack(String name) {
    return '$name जुड़ गया';
  }

  @override
  String get sensorCameraTitle => 'लेबल पढ़ने के लिए कैमरे की अनुमति दें';

  @override
  String get sensorCameraBody =>
      'Kernel कैमरे का इस्तेमाल सिर्फ़ सेंसर का QR लेबल पढ़ने के लिए करता है। कुछ रिकॉर्ड या भेजा नहीं जाता।';

  @override
  String get sensorPlaceTitle => 'यह सेंसर कहाँ है?';

  @override
  String get sensorPlaceSubtitle =>
      'जगह चुनें, और अगर यह किसी बोरी या डिब्बे पर है तो वह भी।';

  @override
  String get sensorPlaceLocation => 'जगह';

  @override
  String get sensorPlaceItem => 'बोरी या डिब्बा';

  @override
  String get sensorPlaceNone => 'तय नहीं';

  @override
  String get sensorPlaceNote =>
      'फिर सेंसर के सबूत उस बोरी या डिब्बे पर दिखेंगे, स्कैन और जाँच से अलग।';

  @override
  String get sensorPlaceSave => 'जगह सहेजें';

  @override
  String get sensorPlaceSkip => 'बाद में';

  @override
  String get sensorPlaceSaved => 'जगह सहेजी गई';

  @override
  String sensorPlaceFailed(String error) {
    return 'जगह सहेजी नहीं जा सकी: $error';
  }

  @override
  String get sensorPlaceNoLocations =>
      'अभी कोई जगह नहीं — पहले कमरा या गोदाम जोड़ें';

  @override
  String get sensorPlaceChange => 'जगह बदलें';

  @override
  String get sensorNotFound => 'यह सेंसर इस फ़ोन पर नहीं है।';

  @override
  String get sensorDetailsTitle => 'सेंसर की जानकारी';

  @override
  String get sensorFieldType => 'प्रकार';

  @override
  String get sensorFieldPlace => 'जगह';

  @override
  String get sensorFieldItem => 'किस पर रखा';

  @override
  String get sensorFieldFirmware => 'फ़र्मवेयर';

  @override
  String get sensorFieldKey => 'कुंजी की पहचान';

  @override
  String get sensorFieldLastSeen => 'आख़िरी बार दिखा';

  @override
  String get sensorLiveTitle => 'लाइव बैंड';

  @override
  String get sensorLiveNote =>
      'सिर्फ़ हर आवृत्ति बैंड की ऊर्जा। सेंसर कोई आवाज़ नहीं भेजता।';

  @override
  String get sensorLiveWaiting => 'सेंसर का इंतज़ार';

  @override
  String sensorBandRange(String low, String high) {
    return '$low–$high kHz';
  }

  @override
  String sensorBandLevel(String db) {
    return 'पृष्ठभूमि से $db dB ऊपर';
  }

  @override
  String sensorLivePeak(String khz) {
    return 'सबसे तेज़ $khz kHz पर';
  }

  @override
  String get sensorSurveyTitle => 'सर्वे';

  @override
  String sensorSurveyBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'जगह को $minutes मिनट शांत रखें ताकि सेंसर सामान्य पृष्ठभूमि सीख ले।',
      one: 'जगह को 1 मिनट शांत रखें ताकि सेंसर सामान्य पृष्ठभूमि सीख ले।',
    );
    return '$_temp0';
  }

  @override
  String sensorSurveyStart(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'सर्वे शुरू करें ($minutes मिनट)',
      one: 'सर्वे शुरू करें (1 मिनट)',
    );
    return '$_temp0';
  }

  @override
  String sensorSurveyRunning(int done, int total) {
    return 'सर्वे चल रहा है: $total में से $done मिनट';
  }

  @override
  String get sensorSurveyDone => 'सर्वे पूरा हुआ';

  @override
  String sensorSurveyFailed(String error) {
    return 'सर्वे नहीं हो सका: $error';
  }

  @override
  String get sensorSessionTitle => 'रात भर निगरानी';

  @override
  String get sensorSessionBody =>
      'Kernel पीछे से इस सेंसर को सुनता रहता है। चलते समय Android एक सूचना दिखाता है। पूरी रात चलाने के लिए ऐप सेटिंग खोलें और बैटरी उपयोग को \'बिना रोक\' (बैटरी ऑप्टिमाइज़ेशन बंद) करें।';

  @override
  String get sensorSessionStart => 'रात भर की निगरानी शुरू करें';

  @override
  String get sensorSessionStop => 'निगरानी रोकें';

  @override
  String get sensorSessionRunning => 'निगरानी चल रही है';

  @override
  String sensorSessionFailed(String error) {
    return 'निगरानी बदली नहीं जा सकी: $error';
  }

  @override
  String get sensorBatterySettings => 'ऐप सेटिंग खोलें';

  @override
  String get sensorSyncAction => 'घटनाएँ लाएँ';

  @override
  String sensorSynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नई घटनाएँ',
      one: '1 नई घटना',
      zero: 'कोई नई घटना नहीं',
    );
    return '$_temp0';
  }

  @override
  String sensorSyncFailed(String error) {
    return 'लाया नहीं जा सका: $error';
  }

  @override
  String get sensorTimelineTitle => 'घटनाओं की सूची';

  @override
  String get sensorTimelineEmpty => 'अभी कोई घटना दर्ज नहीं';

  @override
  String get sensorTimelineEmptyDetail =>
      'यह इस बात का सबूत नहीं कि वहाँ कुछ नहीं है। सेंसर में रखी घटनाएँ लाने के लिए \'घटनाएँ लाएँ\' दबाएँ।';

  @override
  String get sensorSummaryTitle => 'संकेत';

  @override
  String sensorEventsSummary(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes मिनट',
      one: '1 मिनट',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घटनाएँ',
      one: '1 घटना',
    );
    return '$_temp0 में $_temp1';
  }

  @override
  String get sensorSignalNotDiagnosis =>
      'संकेत हैं, निदान नहीं। खुद देखकर जाँचें।';

  @override
  String get sensorUnmatched => 'बिना मिलान का संकेत';

  @override
  String get sensorSigMouseUsv => 'चूहे जैसी अल्ट्रासोनिक आवाज़ें';

  @override
  String get sensorSigRat22k => 'बड़े चूहे जैसी 22 kHz आवाज़ें';

  @override
  String get sensorSigGrainLarva => 'अनाज की इल्ली जैसी कुतरने की टिक-टिक';

  @override
  String get sensorSigTermiteDrum => 'दीमक जैसी ठक-ठक';

  @override
  String sensorSigOther(String id) {
    return 'पहचान चिह्न: $id';
  }

  @override
  String sensorPack(String version) {
    return 'संकेत पैक $version';
  }

  @override
  String sensorScore(String score) {
    return 'नियम अंक $score (संभावना नहीं)';
  }

  @override
  String sensorEventLine(String time, String kind, String khz, int ms) {
    return '$time · $kind · $khz kHz · $ms ms';
  }

  @override
  String get sensorClassTonal => 'स्वर';

  @override
  String get sensorClassFmSweep => 'ऊपर-नीचे फिसलती आवाज़';

  @override
  String get sensorClassFlatTone => 'एक जैसा स्वर';

  @override
  String get sensorClassImpulse => 'टिक-टिक';

  @override
  String get sensorClassHarmonic => 'गूँजता स्वर';

  @override
  String get sensorClassChirp => 'रुक-रुक कर चीं-चीं';

  @override
  String get sensorClassEmitter => 'लगातार चलने वाला यंत्र';

  @override
  String get sensorEvidenceTitle => 'सेंसर के सबूत';

  @override
  String get sensorEvidenceBody =>
      'यहाँ रखे सेंसरों के संकेत। प्रायोगिक, और स्कैन व जाँच से अलग रखे गए।';

  @override
  String get sensorEvidenceOpen => 'सेंसर खोलें';

  @override
  String sensorEvidenceEmpty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'पिछले $days दिनों में कोई सेंसर घटना नहीं। यह इस बात का सबूत नहीं कि वहाँ कुछ नहीं है।',
      one: 'पिछले 1 दिन में कोई सेंसर घटना नहीं। यह इस बात का सबूत नहीं कि वहाँ कुछ नहीं है।',
    );
    return '$_temp0';
  }

  @override
  String sensorEvidenceWindow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'पिछले $days दिन',
      one: 'पिछला 1 दिन',
    );
    return '$_temp0';
  }

  @override
  String sensorNextActivityOne(String name) {
    return '$name पर सेंसर संकेत';
  }

  @override
  String sensorNextActivityMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count जगहों पर सेंसर संकेत',
      one: '1 जगह पर सेंसर संकेत',
    );
    return '$_temp0';
  }

  @override
  String get sensorNextActivityBody =>
      'संकेत हैं, निदान नहीं। खुद देखकर जाँचें।';

  @override
  String sensorNextAttentionOne(String name) {
    return 'सेंसर $name जाँचें';
  }

  @override
  String sensorNextAttentionMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सेंसरों पर ध्यान चाहिए',
      one: '1 सेंसर पर ध्यान चाहिए',
    );
    return '$_temp0';
  }

  @override
  String get sensorNextAttentionBody =>
      'जाम, आवाज़ बहुत तेज़, बैटरी कम या सर्वे ज़रूरी। इसके नतीजे जाँचे नहीं गए।';

  @override
  String get sensorNextOpen => 'सेंसर खोलें';

  @override
  String get pestIdTitle => 'कीट और जीव पहचान';

  @override
  String get pestIdSubtitle =>
      'कैमरे से देखें या आवाज़ सुनें। फ़ोन संभावित निशान ढूँढता है; असली क्या है, यह आप तय करते हैं।';

  @override
  String get pestHomeActionBody =>
      'कैमरे या आवाज़ से कीड़े, चूहे, मकड़ी, छिपकली और दूसरे जीव जाँचें';

  @override
  String get pestHeroAction => 'देखें या सुनें';

  @override
  String get pestSegmentGrain => 'अनाज की बोरी';

  @override
  String get pestSegmentPest => 'कीट और जीव';

  @override
  String get pestCameraCardTitle => 'कैमरे से देखें';

  @override
  String get pestCameraCardBody =>
      'हलचल, काले धब्बे और आँखों की चमक ढूँढता है। असली क्या है, आप पक्का करते हैं।';

  @override
  String get pestListenCardTitle => 'आवाज़ सुनें';

  @override
  String get pestListenCardBody =>
      'भिनभिनाहट, खरोंचने और चूँ-चूँ की आवाज़ पकड़ता है। आपने जो सुना, आप पक्का करते हैं।';

  @override
  String get pestSightingsCardTitle => 'मेरे देखे गए जीव';

  @override
  String pestSightingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count देखे गए जीव सहेजे गए',
      one: '1 देखा गया जीव सहेजा गया',
      zero: 'अभी कुछ सहेजा नहीं गया',
    );
    return '$_temp0';
  }

  @override
  String get pestOnPhoneNote =>
      'सब कुछ इसी फ़ोन पर जाँचा जाता है। तस्वीरें और आवाज़ें कभी अपलोड नहीं होतीं।';

  @override
  String get pestNotCertainNote =>
      'AI के नतीजे अनुमान हैं और गलत हो सकते हैं। कोई निशान न मिलना इस बात का सबूत नहीं कि वहाँ कुछ नहीं है।';

  @override
  String get pestCameraTitle => 'निशान ढूँढें';

  @override
  String get pestCameraTip =>
      'कोनों, दरारों और अनाज के पास फ़ोन स्थिर रखें। किसी बॉक्स को पक्का करने के लिए छुएँ, या पास से देखने के लिए फ़ोटो लें।';

  @override
  String get pestCameraDenied =>
      'कैमरे की अनुमति बंद है। निशान ढूँढने के लिए सेटिंग में इसे चालू करें। आपके सहेजे गए रिकॉर्ड देखे जा सकते हैं।';

  @override
  String get pestKindMotion => 'हलचल';

  @override
  String get pestKindSpecks => 'काले धब्बे';

  @override
  String get pestKindEyeshine => 'आँखों की चमक';

  @override
  String get pestKindEmbedding => 'मिलता-जुलता';

  @override
  String get pestKindModelBox => 'AI बॉक्स';

  @override
  String get pestKindSound => 'आवाज़';

  @override
  String pestConfirmBox(String kind) {
    return '$kind पक्का करें';
  }

  @override
  String get pestTorch => 'टॉर्च';

  @override
  String pestTorchValue(int percent) {
    return '$percent%';
  }

  @override
  String get pestCapture => 'फ़ोटो लें';

  @override
  String get pestCapturing => 'फ़ोटो ली जा रही है…';

  @override
  String get pestNothingHere => 'कीट नहीं है / यहाँ कुछ नहीं';

  @override
  String get pestNothingHereDone => 'कुछ सहेजा नहीं गया। तस्वीरें हटा दी गईं।';

  @override
  String get pestCandidatesNone =>
      'अभी कोई संभावित निशान नहीं। धीरे चलाएँ या टॉर्च चालू करें।';

  @override
  String pestCandidatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count संभावित निशान',
      one: '1 संभावित निशान',
    );
    return '$_temp0';
  }

  @override
  String get pestCaptureFailed => 'फ़ोटो नहीं ली जा सकी। फिर से कोशिश करें।';

  @override
  String get pestTilesTitle => 'पास से: जो असली है उसे छुएँ';

  @override
  String get pestTilesEmpty =>
      'इस फ़ोटो में पास का कोई हिस्सा नहीं। और पास से या टॉर्च के साथ फिर कोशिश करें।';

  @override
  String pestTileHint(String name) {
    return 'AI संकेत: $name (सत्यापित नहीं)';
  }

  @override
  String get pestTileConfirm => 'पक्का करने के लिए छुएँ';

  @override
  String get pestRetake => 'फिर से फ़ोटो लें';

  @override
  String get pestAnalysisTitle => 'AI विश्लेषण';

  @override
  String get pestAnalysing => 'इसी फ़ोन पर विश्लेषण हो रहा है…';

  @override
  String get pestAiLabel => 'AI का नाम';

  @override
  String get pestAiEstimated => 'AI का अनुमान';

  @override
  String get pestConfidenceLabel => 'AI का अनुमानित भरोसा — जाँचा-परखा नहीं';

  @override
  String pestConfidenceValue(int percent) {
    return '$percent% (AI का अपना अनुमान)';
  }

  @override
  String pestAgreement(int agree, int runs) {
    return '$runs में से $agree बार एक ही जवाब';
  }

  @override
  String get pestKeyFeatures => 'मुख्य पहचान';

  @override
  String get pestAnomalies => 'असामान्य बातें';

  @override
  String get pestInsights => 'जानकारी';

  @override
  String get pestNoMatch =>
      'कोई मिलता कार्ड नहीं। इसका मतलब यह नहीं कि वहाँ कुछ नहीं है। खुद देखकर जाँचें।';

  @override
  String get pestNotAPest =>
      'AI के अनुसार यह कीट नहीं है। यह सबूत नहीं है। शक हो तो खुद देखकर जाँचें।';

  @override
  String pestModelLine(String version, String prompt) {
    return 'मॉडल $version · प्रॉम्प्ट $prompt — प्रायोगिक';
  }

  @override
  String get pestAnalysisUnavailable => 'AI विश्लेषण उपलब्ध नहीं';

  @override
  String get pestAnalysisUnavailableBody =>
      'फ़ोन का AI इसका विश्लेषण नहीं कर सका। इसकी जगह सबसे नज़दीकी जानकारी कार्ड दिखाया जा रहा है।';

  @override
  String get pestNoCardFound =>
      'कोई मिलता जानकारी कार्ड नहीं। खुद देखकर जाँचें और शक हो तो किसी विशेषज्ञ से पूछें।';

  @override
  String get pestSafetyVenomousTitle => 'ज़हरीला — दूरी बनाए रखें';

  @override
  String get pestSafetyMedicalTitle => 'सेहत का खतरा — दूरी बनाए रखें';

  @override
  String get pestSafetyDistanceBody =>
      'इसे न छुएँ, न पकड़ें। काटने या डंक मारने पर डॉक्टरी इलाज लें। घरेलू नुस्खे न अपनाएँ।';

  @override
  String get pestSafetyProtectedTitle =>
      'संरक्षित वन्यजीव — इसे नुकसान न पहुँचाएँ';

  @override
  String get pestSafetyProtectedBody =>
      'इसे नुकसान न पहुँचाएँ, न पकड़ें, न मारें। राज्य वन विभाग या लाइसेंस वाले वन्यजीव बचाव दल को बुलाएँ।';

  @override
  String get pestSafetyCautionTitle => 'सावधान रहें';

  @override
  String get pestSafetyCautionBody =>
      'इसे नंगे हाथों से न छुएँ। कार्ड में दिए सुरक्षित कदम अपनाएँ।';

  @override
  String get pestCardTitle => 'जानकारी कार्ड';

  @override
  String get pestCardYourPick => 'आपकी पसंद';

  @override
  String get pestCardNeedsReview => 'विशेषज्ञ जाँच बाकी';

  @override
  String pestCardOtherNames(String names) {
    return 'दूसरे नाम: $names';
  }

  @override
  String get pestCardSigns => 'किन निशानों को देखें';

  @override
  String get pestCardHealthRisks => 'सेहत के खतरे';

  @override
  String get pestCardSafeSteps => 'सुरक्षित कदम';

  @override
  String get pestCardCallPro => 'विशेषज्ञ को कब बुलाएँ';

  @override
  String get pestCardFirstAid => 'प्राथमिक उपचार';

  @override
  String get pestCardLookAlikes => 'मिलते-जुलते जीव';

  @override
  String get pestCardLegal => 'कानूनी स्थिति';

  @override
  String get pestCardSources => 'स्रोत';

  @override
  String get pestExplain => 'समझाएँ';

  @override
  String get pestExplainTitle => 'कार्ड के आधार पर समझ';

  @override
  String get pestExplainFallback =>
      'अभी कोई समझ उपलब्ध नहीं। ऊपर दिया कार्ड ही मार्गदर्शन है।';

  @override
  String get pestPickCard => 'दूसरा कार्ड चुनें';

  @override
  String get pestPickCardTitle => 'यह कौन सा है?';

  @override
  String get pestPickCardBody =>
      'आपकी पसंद आपके सुधार के रूप में सहेजी जाती है। AI विश्लेषण वैसा ही रहता है।';

  @override
  String get pestPickCardClear => 'AI का नाम इस्तेमाल करें';

  @override
  String get pestMeasure => 'दूरी नापें';

  @override
  String get pestMeasuring => 'नापा जा रहा है…';

  @override
  String pestDistanceValue(
    String meters,
    String low,
    String high,
    String method,
  ) {
    return 'लगभग $meters मी. दूर ($low–$high मी.), $method से';
  }

  @override
  String get pestDistanceMethodDepth => 'गहराई सेंसर';

  @override
  String get pestDistanceMethodFocus => 'कैमरा फ़ोकस';

  @override
  String get pestDistanceUnavailable => 'दूरी उपलब्ध नहीं';

  @override
  String pestDistanceReason(String reason) {
    return 'कारण: $reason';
  }

  @override
  String get pestDistanceNoReason => 'फ़ोन इसे भरोसे से नाप नहीं सका।';

  @override
  String get pestSave => 'रिकॉर्ड सहेजें';

  @override
  String get pestDiscard => 'हटाएँ';

  @override
  String get pestStartAgain => 'फिर से शुरू करें';

  @override
  String get pestNoSignal =>
      'विश्लेषण के लिए कुछ नहीं। कैमरे या सुनने से फिर शुरू करें।';

  @override
  String get pestGroupInsect => 'कीड़ा';

  @override
  String get pestGroupArachnid => 'मकड़ी या बिच्छू';

  @override
  String get pestGroupRodent => 'चूहा';

  @override
  String get pestGroupReptile => 'सरीसृप (छिपकली, साँप आदि)';

  @override
  String get pestGroupOther => 'दूसरा जीव';

  @override
  String get pestGroupNotAPest => 'कीट नहीं';

  @override
  String get pestGroupUnknown => 'पता नहीं';

  @override
  String pestGroupHint(String group) {
    return 'संभावित समूह: $group (AI संकेत)';
  }

  @override
  String get pestSourceCamera => 'कैमरा';

  @override
  String get pestSourceMic => 'आवाज़';

  @override
  String get pestSourceSensor => 'सेंसर';

  @override
  String get pestListenTitle => 'आवाज़ सुनें';

  @override
  String get pestListenModeGeneral => 'सामान्य';

  @override
  String get pestListenModeMosquito => 'मच्छर पास से';

  @override
  String get pestListenModeNight => 'रात';

  @override
  String get pestListenModeGeneralBody =>
      'जहाँ आवाज़ आ रही है, उसके पास फ़ोन स्थिर रखें।';

  @override
  String get pestListenModeMosquitoBody =>
      'भिनभिनाहट से एक हथेली की दूरी पर फ़ोन रखें।';

  @override
  String get pestListenModeNightBody =>
      'फ़ोन कमरे में स्थिर रख दें। सुनते समय एक सूचना दिखती है, ताकि आप इसे कभी भी रोक सकें।';

  @override
  String get pestListenStart => 'सुनना शुरू करें';

  @override
  String get pestListenStop => 'रोकें';

  @override
  String get pestListening => 'इसी फ़ोन पर सुना जा रहा है…';

  @override
  String get pestListenNone => 'अभी कोई आवाज़ नहीं पकड़ी गई।';

  @override
  String get pestListenTapToConfirm =>
      'जो आवाज़ आपने भी सुनी, उसे छूकर पक्का करें';

  @override
  String get pestListenMicDenied =>
      'माइक्रोफ़ोन की अनुमति बंद है। सुनने के लिए सेटिंग में इसे चालू करें। आपके सहेजे गए रिकॉर्ड देखे जा सकते हैं।';

  @override
  String get pestListenNightNeedsNotice =>
      'रात मोड के लिए सूचनाएँ ज़रूरी हैं ताकि आप सुनना देख और रोक सकें। सूचनाएँ चालू करके फिर कोशिश करें।';

  @override
  String get pestListenAgain => 'फिर से सुनें';

  @override
  String pestSoundAt(String time) {
    return '$time पर आवाज़';
  }

  @override
  String get pestSoundConfirm => 'पक्का करने के लिए छुएँ';

  @override
  String pestSoundScore(String label, int percent) {
    return '$label · $percent%';
  }

  @override
  String get pestSoundNoLabels => 'आवाज़ का कोई नाम नहीं मिला।';

  @override
  String get pestSoundRawNote =>
      'आवाज़ पहचानने वाले मॉडल के कच्चे अंक, जाँचे-परखे नहीं';

  @override
  String get pestSoundDescribing => 'इसी फ़ोन पर आवाज़ का वर्णन हो रहा है…';

  @override
  String get pestSoundDescription => 'AI वर्णन (प्रायोगिक)';

  @override
  String get pestSoundNoDescription => 'कोई AI वर्णन उपलब्ध नहीं।';

  @override
  String pestSoundModel(String version) {
    return 'आवाज़ मॉडल $version — प्रायोगिक';
  }

  @override
  String get pestSoundCards => 'मिलते कार्ड';

  @override
  String get pestSoundNoCards => 'कोई मिलता कार्ड नहीं। खुद देखकर जाँचें।';

  @override
  String get pestClipGone => 'वह आवाज़ अब उपलब्ध नहीं है। फिर से सुनें।';

  @override
  String get pestSaveTitle => 'रिकॉर्ड सहेजें';

  @override
  String get pestSaveSubtitle => 'सिर्फ़ इसी फ़ोन पर सहेजा जाता है';

  @override
  String get pestSaveRoom => 'कमरा या जगह';

  @override
  String get pestSaveNoRoom => 'कोई कमरा नहीं';

  @override
  String get pestSaveNoRooms =>
      'अभी कोई कमरा या जगह नहीं। आप इन्हें भंडार में जोड़ सकते हैं।';

  @override
  String get pestSaveLocation => 'स्थान सहेजें';

  @override
  String get pestSaveLocationBody =>
      'ज़रूरी नहीं। स्थान सिर्फ़ अभी पूछा जाता है। घर के अंदर कमरा ज़्यादा काम का होता है।';

  @override
  String get pestLocating => 'स्थान लिया जा रहा है…';

  @override
  String get pestLocationDenied =>
      'स्थान की अनुमति नहीं मिली। पिन उपलब्ध नहीं है।';

  @override
  String get pestLocationImprecise =>
      'स्थान बहुत अंदाज़न है। पिन उपलब्ध नहीं है।';

  @override
  String get pestLocationOff => 'इस फ़ोन पर स्थान बंद है। पिन उपलब्ध नहीं है।';

  @override
  String get pestLocationFailed => 'स्थान नहीं मिल सका। पिन उपलब्ध नहीं है।';

  @override
  String pestLocationPinned(int meters) {
    return 'पिन सहेजने के लिए तैयार ($meters मी. के अंदर)';
  }

  @override
  String get pestKeepMedia => 'तस्वीर या आवाज़ रखें';

  @override
  String get pestKeepMediaBody =>
      'शुरू में बंद। रिकॉर्ड के साथ इसी फ़ोन पर निजी रूप से रखा जाता है, कभी अपलोड नहीं होता।';

  @override
  String get pestNotes => 'नोट';

  @override
  String get pestSaved => 'रिकॉर्ड सहेजा गया';

  @override
  String get pestSaveFailed => 'सहेजा नहीं जा सका। फिर कोशिश करें।';

  @override
  String get pestSightingsTitle => 'देखे गए जीव';

  @override
  String get pestSightingsSubtitle => 'इसी फ़ोन पर सहेजे गए, नए पहले';

  @override
  String get pestSightingsEmpty => 'अभी कोई रिकॉर्ड नहीं';

  @override
  String get pestSightingsEmptyDetail =>
      'निशान देखें या सुनें, और जो आप पक्का करें उसे सहेजें।';

  @override
  String get pestSightingUnnamed => 'बिना पहचान का रिकॉर्ड';

  @override
  String get pestNoFindingYet => 'अभी किसी व्यक्ति ने नहीं जाँचा';

  @override
  String pestFindingChip(String finding) {
    return 'जाँचा गया: $finding';
  }

  @override
  String get pestNotFound => 'यह रिकॉर्ड इस फ़ोन पर नहीं है।';

  @override
  String get pestDetailTitle => 'देखा गया जीव';

  @override
  String get pestDetailAiSection => 'AI विश्लेषण';

  @override
  String get pestDetailAiNote =>
      'AI का अनुमान — जाँचा-परखा नहीं। जैसा था वैसा सहेजा गया, कभी बदला नहीं जाता।';

  @override
  String get pestDetailValidation => 'आपकी पुष्टि';

  @override
  String get pestDetailConfirmed => 'आपने पक्का किया कि निशान असली था';

  @override
  String get pestDetailNotConfirmed => 'पक्का नहीं किया गया';

  @override
  String pestDetailYourPick(String name) {
    return 'आपकी पसंद: $name';
  }

  @override
  String get pestDetailVerified => 'सत्यापित नतीजा';

  @override
  String get pestDetailVerifiedBody =>
      'किसी व्यक्ति ने जाँच कर क्या पाया। AI विश्लेषण से अलग। इसे सिर्फ़ एक बार दर्ज किया जा सकता है।';

  @override
  String get pestDetailRecordFinding => 'नतीजा दर्ज करें';

  @override
  String pestDetailConfirmFinding(String finding) {
    return '\"$finding\" को सत्यापित नतीजे के रूप में सहेजें? बाद में इसे बदला नहीं जा सकता।';
  }

  @override
  String get pestDetailPlace => 'जगह';

  @override
  String get pestDetailPinLabel => 'पिन';

  @override
  String pestDetailPin(String lat, String lng, int meters) {
    return '$lat, $lng ($meters मी. के अंदर)';
  }

  @override
  String get pestDetailNoPlace => 'कोई कमरा या पिन सहेजा नहीं गया।';

  @override
  String get pestDetailShowMap => 'नक्शे पर दिखाएँ';

  @override
  String get pestDetailMediaKept => 'तस्वीर या आवाज़ इसी फ़ोन पर रखी गई';

  @override
  String pestNextRepeated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'कीट $count बार दिखे',
      one: 'एक कीट फिर दिखा',
    );
    return '$_temp0';
  }

  @override
  String pestNextRepeatedOne(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$label: $count बार दिखा',
      one: '$label: फिर दिखा',
    );
    return '$_temp0';
  }

  @override
  String get pestNextRepeatedBody =>
      'जगह जाँचें और कार्ड में दिए सुरक्षित कदम अपनाएँ।';

  @override
  String get pestNextSafety => 'एक रिकॉर्ड पर ध्यान ज़रूरी';

  @override
  String get pestNextSafetyBody =>
      'उसके पास जाने से पहले कार्ड में सुरक्षा के कदम पढ़ें।';

  @override
  String get pestNextAction => 'रिकॉर्ड देखें';

  @override
  String get mapTitle => 'देखे गए जीवों का नक्शा';

  @override
  String get mapCardBody => 'सटीक स्थान के साथ सहेजे गए रिकॉर्ड के पिन';

  @override
  String get mapConsentTitle => 'Google Maps इस्तेमाल करें?';

  @override
  String get mapConsentBody =>
      'नक्शा और पैदल रास्ता Google से आते हैं। Google को वह नक्शे का हिस्सा मिलता है जो आप देखते हैं, और रास्ते की शुरुआत और अंत की जगह।';

  @override
  String get mapConsentNever =>
      'Google को जीव, आपके नोट, तस्वीरें या आवाज़ें कभी नहीं मिलतीं।';

  @override
  String get mapConsentAllow => 'नक्शे की अनुमति दें';

  @override
  String get mapConsentDecline => 'अभी नहीं';

  @override
  String get mapConsentNeeded =>
      'नक्शे बंद हैं। जब तक आप अनुमति नहीं देते, कुछ नहीं भेजा जाता।';

  @override
  String get mapNotConfigured => 'नक्शा सेट नहीं है';

  @override
  String get mapNotConfiguredBody =>
      'इस ऐप में नक्शे की चाबी नहीं है। फिर भी आप किसी पिन को Google Maps ऐप में खोल सकते हैं।';

  @override
  String get mapOpenInGoogleMaps => 'Google Maps में खोलें';

  @override
  String get mapNoPins => 'अभी सटीक स्थान वाला कोई रिकॉर्ड नहीं';

  @override
  String get mapNoPinsDetail =>
      '25 मी. के अंदर के स्थान के साथ सहेजे गए रिकॉर्ड के पिन दिखते हैं।';

  @override
  String get mapNoPinsAction => 'रिकॉर्ड देखें';

  @override
  String mapPinLabel(String date) {
    return 'रिकॉर्ड $date';
  }

  @override
  String get mapRoute => 'यहाँ से रास्ता';

  @override
  String get mapRouting => 'रास्ता ढूँढा जा रहा है…';

  @override
  String mapRouteSummary(String distance, int minutes) {
    return '$distance · लगभग $minutes मिनट';
  }

  @override
  String get mapRouteFailed =>
      'रास्ता नहीं मिल सका। इंटरनेट कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get mapRouteNeedsLocation =>
      'रास्ते के लिए आपका स्थान चाहिए। स्थान की अनुमति देकर फिर कोशिश करें।';

  @override
  String get mapStartNavigation => 'रास्ता दिखाना शुरू करें';

  @override
  String get mapNavigationFailed => 'इस फ़ोन पर Google Maps नहीं खुल सका।';

  @override
  String mapDistanceKm(String km) {
    return '$km कि.मी.';
  }

  @override
  String mapDistanceM(int meters) {
    return '$meters मी.';
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get languageTitle => 'ભાષા';

  @override
  String get languageFollowDevice => 'ફોનની ભાષા વાપરો';

  @override
  String get languageSheetBody => 'Kernel ના શબ્દો તરત બદલાઈ જાય છે.';

  @override
  String get settingsSubtitle =>
      'ભાષા, અવાજ-તપાસ, ગોપનીયતા અને ફોન પર ચાલતી બાબતોની માહિતી';

  @override
  String get settingsScanning => 'અવાજ-તપાસ';

  @override
  String get settingsHaptics => 'શરૂઆતમાં અને અંતે કંપન';

  @override
  String get settingsHapticsBody =>
      'રેકોર્ડિંગ શરૂ અને બંધ થાય ત્યારે ફોન થોડો ધ્રૂજે છે, જેથી તમે ફોનને કોથળા પર દબાવી રાખી શકો.';

  @override
  String get settingsVoice => 'બોલીને સૂચના';

  @override
  String get settingsVoiceBody =>
      'શરૂઆતમાં બંધ હોય છે. આ ફોનમાં રહેલા અવાજમાં “ફોન કોથળા પર મૂકો”, “સાંભળે છે” અને “થઈ ગયું” બોલે છે. ઇન્ટરનેટ પરથી કંઈ લેવાતું નથી.';

  @override
  String get settingsRetain => 'રેકોર્ડિંગ આ ફોન પર રાખો';

  @override
  String get settingsRetainBody =>
      'શરૂઆતમાં બંધ હોય છે: દરેક 2 સેકન્ડનું રેકોર્ડિંગ તપાસ્યા પછી તરત કાઢી નખાય છે. ચાલુ કરો તો રેકોર્ડિંગ ઍપની અંદર ખાનગી રીતે રખાય છે, જેથી ફરી તપાસી શકાય. તે ક્યારેય અપલોડ થતાં નથી. “બધો ઇતિહાસ કાઢી નાખો” તેમને દૂર કરે છે.';

  @override
  String get settingsResearchSection => 'સંશોધન';

  @override
  String get settingsResearch => 'સંશોધન રેકોર્ડિંગ મોડ';

  @override
  String get settingsResearchBody =>
      'અનાજની જીવાતનું મોડેલ બનાવવામાં મદદ માટે લેબલવાળા નમૂના રેકોર્ડ કરો. આ રેકોર્ડિંગ રાખવાના સેટિંગથી અલગ છે; શરૂઆતમાં બંધ હોય છે.';

  @override
  String get researchConsentTitle => 'સંશોધન રેકોર્ડિંગ ચાલુ કરવું છે?';

  @override
  String get researchConsentBody =>
      'તમે “લેબલવાળો નમૂનો રેકોર્ડ કરો” પસંદ કરો ત્યારે તે 2 સેકન્ડનું રેકોર્ડિંગ તમે આપેલા લેબલ સાથે આ ફોન પર ખાનગી રીતે રખાય છે. “કોઈ નિશાની નથી” કે “જીવાત લાગી છે” લેબલ માટે જાતે કરેલી તપાસથી તેની ખાતરી થવી જોઈએ. કંઈ અપલોડ થતું નથી: તમે ડેટાસેટ ફાઇલ બનાવીને તે કોને આપવી તે જાતે નક્કી કરી શકો છો. ગમે ત્યારે આ બંધ કરો; “બધો ઇતિહાસ કાઢી નાખો” દરેક રેકોર્ડિંગ અને લેબલ દૂર કરે છે.';

  @override
  String get researchConsentAgree => 'હું સંમત છું, ચાલુ કરો';

  @override
  String get settingsSamplesCard => 'દરેક લેબલની ગણતરી અને ડેટાસેટ ફાઇલ';

  @override
  String get settingsPrivacy => 'ગોપનીયતા';

  @override
  String get deleteHistoryTitle => 'બધો ઇતિહાસ કાઢી નાખો';

  @override
  String get deleteHistoryBody =>
      'અવાજ-તપાસ, જોઈને તપાસ અને તેના ફોટા, રિમાઇન્ડર, લેબલવાળા નમૂના અને રાખેલાં રેકોર્ડિંગ દૂર કરે છે.';

  @override
  String get deleteHistoryConfirmTitle => 'બધો ઇતિહાસ કાઢી નાખવો છે?';

  @override
  String get deleteHistoryConfirmBody =>
      'આનાથી આ ફોન પરની દરેક અવાજ-તપાસ, જોઈને તપાસ (ફોટા સાથે), રિમાઇન્ડર, લેબલવાળો નમૂનો અને રાખેલું રેકોર્ડિંગ કાઢી નખાશે. તમારી નોંધેલી વસ્તુઓ, જગ્યાઓ, પાક અને લૉટ એમ જ રહેશે. આ પાછું લાવી શકાશે નહીં.';

  @override
  String get deleteHistoryConfirmAction => 'ઇતિહાસ કાઢી નાખો';

  @override
  String get deleteHistoryDone => 'બધો ઇતિહાસ કાઢી નખાયો';

  @override
  String deleteHistoryFailed(String detail) {
    return 'ઇતિહાસ કાઢી શકાયો નહીં: $detail';
  }

  @override
  String get settingsOnDevice => 'ફોન પર જ અવાજ-તપાસ';

  @override
  String get engineUnavailable => 'અવાજ-તપાસ એન્જિનની માહિતી મળતી નથી';

  @override
  String get engineModelPresent =>
      'પરિણામો પ્રાયોગિક છે અને તેની ખાતરી થઈ નથી.';

  @override
  String get engineNoModel =>
      'કોઈ મોડેલ લગાવેલું નથી, તેથી અવાજ-તપાસ ફક્ત રેકોર્ડિંગની ગુણવત્તા જુએ છે અને પરિણામમાં “પરિણામ મળ્યું નથી” દેખાય છે.';

  @override
  String get settingsFooter =>
      'બધી અવાજ-તપાસ આ ફોન પર જ થાય છે. Kernel ઇન્ટરનેટ વગર ચાલે છે અને ક્યારેય અવાજ અપલોડ કરતું નથી.';

  @override
  String get diagnosticsTitle => 'ટેકનિકલ માહિતી';

  @override
  String get diagnosticsCard =>
      'ચકાસણી માટે મોડેલ, પ્રોસેસર, સેમ્પલ રેટ અને ફોનની માહિતી';

  @override
  String get diagnosticsSubtitle => 'આ ફોન પર અવાજ-તપાસ એન્જિન શું કહે છે';

  @override
  String get notMeasured => 'હજી માપ્યું નથી';

  @override
  String get yes => 'હા';

  @override
  String get no => 'ના';

  @override
  String get diagModelInstalled => 'મોડેલ લગાવેલું છે';

  @override
  String get diagModelNote => 'મોડેલ વિશે નોંધ';

  @override
  String get diagDelegate => 'પ્રોસેસર';

  @override
  String get diagAudioTitle => 'અવાજ ઇનપુટ';

  @override
  String get diagTargetRate => 'લક્ષ્ય સેમ્પલ રેટ';

  @override
  String get diagEffectiveRate => 'ખરેખર સેમ્પલ રેટ';

  @override
  String get diagDeviceRate => 'ફોનનો ઇનપુટ રેટ';

  @override
  String get diagAudioSource => 'અવાજનો સ્રોત';

  @override
  String get diagDeviceTitle => 'ફોન';

  @override
  String get diagOs => 'એન્ડ્રોઇડ';

  @override
  String get diagAppVersion => 'ઍપ વર્ઝન';

  @override
  String get diagLogRowTitle => 'ડિવાઇસ-લોગની લાઇન';

  @override
  String get diagLogRowBody =>
      'આ લાઇન docs/device-validation.md ના ડિવાઇસ લોગમાં ચોંટાડો અને તમારું નામ ઉમેરો.';

  @override
  String get diagCopyRow => 'ડિવાઇસ-લોગની લાઇન કૉપિ કરો';

  @override
  String get diagCopied => 'લાઇન કૉપિ થઈ';

  @override
  String get qrTitle => 'QR લેબલથી ખોલો';

  @override
  String get qrInstructions => 'લેબલને ચોકઠાની અંદર રાખો. વંચાતાં જ તે ખૂલશે.';

  @override
  String get qrNotKernel =>
      'આ QR કોડ Kernel નું કોથળા લેબલ નથી. Kernel માંથી છાપેલા લેબલ તરફ કૅમેરા રાખો.';

  @override
  String get qrUnknownItem => 'આ લેબલ એવા કોથળાનું છે જે આ ફોન પર નથી.';

  @override
  String qrLookupFailed(String detail) {
    return 'કોથળો ખોલી શકાયો નહીં: $detail';
  }

  @override
  String get qrScanAnother => 'બીજું લેબલ વાંચો';

  @override
  String get qrRationaleTitle => 'કોથળાનાં લેબલ વાંચવા કૅમેરા વાપરો';

  @override
  String get qrRationaleBody =>
      'Kernel કૅમેરાનો ઉપયોગ ફક્ત કોથળાનાં QR લેબલ વાંચવા અને તપાસના ફોટા પાડવા માટે કરે છે. લેબલ આ ફોન પર જ વંચાય છે; કૅમેરાની તસવીરો સેવ કે અપલોડ થતી નથી.';

  @override
  String get qrAllowCamera => 'કૅમેરાને મંજૂરી આપો';

  @override
  String get qrCameraDenied =>
      'કૅમેરાની મંજૂરી ન મળી. છતાં તમે તમારા જથ્થામાંથી કોથળા ખોલી શકો છો.';

  @override
  String get qrCameraBlocked =>
      'Kernel માટે કૅમેરા બંધ કરેલો છે. ફોનનાં સેટિંગ્સ ખોલો, મંજૂરીઓ પસંદ કરો, પછી કૅમેરાને મંજૂરી આપો.';

  @override
  String get qrPrivacyNote => 'લેબલ આ ફોન પર જ વંચાય છે. કંઈ અપલોડ થતું નથી.';

  @override
  String get labelSampleTitle => 'સંશોધન રેકોર્ડિંગને લેબલ આપો';

  @override
  String get labelRuleNote =>
      'આ કોથળાની જાતે કરેલી તપાસથી ખાતરી થઈ હોય ત્યારે જ “કોઈ નિશાની નથી” કે “જીવાત લાગી છે” પસંદ કરો. નહીંતર “ખબર નથી” પસંદ કરો.';

  @override
  String get labelCleanHelp => 'તપાસમાં જીવાત ન મળી, તેની ખાતરી થઈ';

  @override
  String get labelCleanNeedsInspection =>
      'જીવાત ન મળી હોય એવી આ કોથળાની તપાસ જોઈએ';

  @override
  String get labelInfestedHelp => 'તપાસમાં જીવાત મળી, તેની ખાતરી થઈ';

  @override
  String get labelInfestedNeedsInspection =>
      'જીવાત મળી હોય એવી આ કોથળાની તપાસ જોઈએ';

  @override
  String get labelUnknownHelp => 'કોઈ તપાસથી આ કોથળાની સ્થિતિની ખાતરી થતી નથી';

  @override
  String get labelNeedsEvidence =>
      '“કોઈ નિશાની નથી” અને “જીવાત લાગી છે” માટે તેની સાથે મેળ ખાતી આ કોથળાની તપાસ જોઈએ. “ખબર નથી” પસંદ કરો અથવા પહેલાં તપાસ નોંધો.';

  @override
  String get evidenceTitle => 'ખાતરી આપતી તપાસ';

  @override
  String get evidenceBody => 'આ રેકોર્ડિંગ માટે કરેલી તપાસ પસંદ કરો.';

  @override
  String get sackMaterialField => 'કોથળો કે ડબ્બો શેનો બનેલો છે';

  @override
  String get notRecorded => 'નોંધ નથી';

  @override
  String get environmentField => 'આસપાસનું વાતાવરણ';

  @override
  String get environmentHelper =>
      'ક્યાં રેકોર્ડ કર્યું, દા.ત. શાંત ઓરડો કે પંખા ચાલુ હોય એવું ગોડાઉન';

  @override
  String get envQuietRoom => 'શાંત ઓરડો';

  @override
  String get envWarehouse => 'ગોડાઉન';

  @override
  String get envFansOn => 'પંખા કે મશીન ચાલુ';

  @override
  String get envOutdoors => 'બહાર ખુલ્લામાં';

  @override
  String get materialJute => 'શણ';

  @override
  String get materialWovenPp => 'પ્લાસ્ટિકનો વણેલો કોથળો (PP)';

  @override
  String get materialCotton => 'સુતરાઉ';

  @override
  String get materialPlastic => 'પ્લાસ્ટિકનો ડબ્બો';

  @override
  String get materialMetal => 'ધાતુનો ડબ્બો';

  @override
  String get materialOther => 'બીજું';

  @override
  String get sampleSave => 'લેબલવાળો નમૂનો સેવ કરો';

  @override
  String get sampleSaved => 'લેબલવાળો નમૂનો આ ફોન પર સેવ થયો';

  @override
  String sampleRejected(String detail) {
    return 'લેબલ સેવ ન થયું: $detail';
  }

  @override
  String get sampleUnusableRetry =>
      'આ રેકોર્ડિંગ કામનું નહોતું, તેથી તેને લેબલ આપી શકાય નહીં. શાંત જગ્યાએ ફરી રેકોર્ડ કરો.';

  @override
  String get sampleUnusableNotKept =>
      'આ રેકોર્ડિંગનો અવાજ રખાયો નથી, તેથી તેને લેબલ આપી શકાય નહીં.';

  @override
  String get sampleRecordAgain => 'ફરી રેકોર્ડ કરો';

  @override
  String get samplesTitle => 'સંશોધન નમૂના';

  @override
  String samplesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'આ ફોન પર $count લેબલવાળાં રેકોર્ડિંગ',
      one: 'આ ફોન પર 1 લેબલવાળું રેકોર્ડિંગ',
      zero: 'હજી કોઈ લેબલવાળું રેકોર્ડિંગ નથી',
    );
    return '$_temp0';
  }

  @override
  String get samplesResearchOff =>
      'સંશોધન રેકોર્ડિંગ મોડ બંધ છે. નવા નમૂના રેકોર્ડ કરવા સેટિંગ્સમાં તેને ચાલુ કરો.';

  @override
  String get samplesEmpty => 'હજી કોઈ લેબલવાળા નમૂના નથી';

  @override
  String get samplesEmptyDetail =>
      'સંશોધન મોડ ચાલુ રાખીને કોઈ કોથળો ખોલો અને “લેબલવાળો નમૂનો રેકોર્ડ કરો” પસંદ કરો.';

  @override
  String get datasetTitle => 'તાલીમ ડેટાસેટ';

  @override
  String get datasetBody =>
      'રાખેલાં રેકોર્ડિંગની એક ZIP અને તેનાં લેબલની એક CSV, આ ફોન પર જ બને છે. તે ક્યાં મોકલવી તે તમે નક્કી કરો છો; Kernel તેને ક્યારેય અપલોડ કરતું નથી.';

  @override
  String get datasetExport => 'ડેટાસેટ ફાઇલ બનાવો';

  @override
  String datasetExportFailed(String detail) {
    return 'ડેટાસેટ બનાવી કે મોકલી શકાયો નહીં. $detail';
  }

  @override
  String sampleLabelChip(String label) {
    return 'લેબલ: $label';
  }

  @override
  String get sampleConfirmed => 'તપાસથી ખાતરી થઈ';

  @override
  String get inspectionTitle => 'જાતે જોઈને તપાસ';

  @override
  String get saveInspection => 'તપાસ સેવ કરો';

  @override
  String get inspectionSaved => 'તપાસ સેવ થઈ';

  @override
  String get aiPanelTitle => 'AI નો અંદાજ (ખાતરી નથી)';

  @override
  String get aiPanelLoading => 'જોડેલી અવાજ-તપાસ ખૂલી રહી છે…';

  @override
  String get aiPanelNoScan =>
      'કોઈ અવાજ-તપાસ જોડેલી નથી. આ તપાસ પોતે જ પૂરી છે.';

  @override
  String scannedAt(String when) {
    return 'અવાજ-તપાસ $when';
  }

  @override
  String get aiPanelNotUsed => 'તમારું તારણ ભરવા માટે આનો ઉપયોગ થયો નથી';

  @override
  String get findingPanelTitle => 'તમારું ખાતરી કરેલું તારણ';

  @override
  String get findingPanelBody =>
      'અનાજ તપાસતી વખતે તમે જાતે જે જોયું તે. આ AI ના અંદાજથી અલગ રખાય છે.';

  @override
  String get findingMissing => 'તમને શું મળ્યું તે પસંદ કરો';

  @override
  String get inspectorField => 'તપાસ કરનારનું નામ';

  @override
  String get validationInspector => 'તપાસ કોણે કરી તે લખો';

  @override
  String get inspectionDateField => 'તપાસની તારીખ';

  @override
  String get observationsField => 'શું જોયું';

  @override
  String get observationsHelper => 'તમે શું જોયું, ક્યાં અને કેટલું';

  @override
  String get assigneeFieldOptional => 'આગળની તપાસ કોને સોંપવી (વૈકલ્પિક)';

  @override
  String get followUpStatusTitle => 'આગળની તપાસની સ્થિતિ';

  @override
  String get photosTitle => 'પુરાવાના ફોટા (વૈકલ્પિક)';

  @override
  String get photosBody =>
      'ફોટા આ તપાસ સાથે આ ફોન પર જ ખાનગી રીતે રહે છે. તે તમે જે જોયું તેનો પુરાવો છે, અવાજ-તપાસનાં પરિણામ નથી, અને ક્યારેય અપલોડ થતા નથી.';

  @override
  String get photoTake => 'ફોટો પાડો';

  @override
  String get photoPick => 'ગૅલેરીમાંથી પસંદ કરો';

  @override
  String get cameraDeniedPhoto =>
      'કૅમેરા બંધ છે. પુરાવાના ફોટા પાડવા ફોનનાં સેટિંગ્સમાં મંજૂરી આપો.';

  @override
  String photoFailed(String detail) {
    return 'ફોટો ઉમેરી શકાયો નહીં: $detail';
  }

  @override
  String get filterAll => 'બધું';

  @override
  String get filterNoMatch => 'આ ફિલ્ટર મુજબ કોઈ ખુલ્લી તપાસ નથી.';

  @override
  String get batchSetupTitle => 'ઓરડો કે થપ્પી પસંદ કરો';

  @override
  String get batchSetupSubtitle =>
      'Kernel તમને તેના કોથળા પાસે એક પછી એક લઈ જાય છે.';

  @override
  String get batchSequentialNote =>
      'દરેક કોથળા માટે એક રેકોર્ડિંગ. Kernel ક્યારેય ઘણા કોથળાની એકસાથે અવાજ-તપાસ કરતું નથી.';

  @override
  String get batchNoPlaces => 'હજી કોઈ ઓરડા કે થપ્પી નથી';

  @override
  String get batchNoPlacesDetail =>
      'એક ગોડાઉન તેના ઓરડા અને થપ્પીઓ સાથે ઉમેરો, પછી તેમાં કોથળા નોંધો.';

  @override
  String batchPlaceSubtitle(String type, int total, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total કોથળા',
      one: '1 કોથળો',
    );
    return '$type · $_temp0 · $needScan ની અવાજ-તપાસ બાકી';
  }

  @override
  String batchIntroSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count કોથળા, એક પછી એક',
      one: '1 કોથળો, એક પછી એક',
      zero: 'જોવા માટે કોઈ કોથળો નથી',
    );
    return '$_temp0';
  }

  @override
  String get batchSkipToday => 'આજે તપાસેલા કોથળા છોડો';

  @override
  String get batchSkipTodayBody =>
      'જે કોથળાનું આજનું રેકોર્ડિંગ પહેલેથી છે તે છોડી દો.';

  @override
  String batchWalkLine(int position, String label, String grain) {
    return '$position. $label · $grain';
  }

  @override
  String batchStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count કોથળાથી શરૂ કરો',
      one: '1 કોથળાથી શરૂ કરો',
    );
    return '$_temp0';
  }

  @override
  String get batchNothingToWalk =>
      'અહીંના દરેક કોથળાની કામની અવાજ-તપાસ પહેલેથી છે અથવા આજે તપાસ થઈ ગઈ છે.';

  @override
  String batchProgress(int position, int total) {
    return '$total માંથી કોથળો $position';
  }

  @override
  String get batchSkipSack => 'આ કોથળો છોડો';

  @override
  String get batchStop => 'ફેરો રોકો';

  @override
  String batchNextIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds સેકન્ડમાં આગળનો કોથળો',
      one: '1 સેકન્ડમાં આગળનો કોથળો',
    );
    return '$_temp0';
  }

  @override
  String batchSummaryIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds સેકન્ડમાં સારાંશ',
      one: '1 સેકન્ડમાં સારાંશ',
    );
    return '$_temp0';
  }

  @override
  String get batchNextSack => 'આગળનો કોથળો';

  @override
  String get batchFinish => 'પૂરું કરો';

  @override
  String get batchRetrySack => 'આ કોથળો ફરી રેકોર્ડ કરો';

  @override
  String get batchSummaryTitle => 'ફેરાનો સારાંશ';

  @override
  String batchSummarySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'આ ફેરામાં $count કોથળા',
      one: 'આ ફેરામાં 1 કોથળો',
    );
    return '$_temp0';
  }

  @override
  String get batchStatRecorded => 'રેકોર્ડ થયા';

  @override
  String get batchStatSkipped => 'છોડ્યા';

  @override
  String get batchStatRetry => 'ફરી કરવાના';

  @override
  String get rankedTitle => 'ક્રમમાં';

  @override
  String rankLabel(int rank) {
    return '#$rank';
  }

  @override
  String get queueSuggestionNote =>
      'આ ક્રમ ફક્ત પહેલાં શું તપાસવું તેનું સૂચન છે. કોઈ પણ નિર્ણય પહેલાં જાતે ખોલીને તપાસો.';

  @override
  String get queueNothingRanked =>
      'હજી કોઈ વસ્તુનું કામનું મોડેલ પરિણામ નથી, તેથી કંઈ ક્રમમાં નથી. પરિણામ વગરની વસ્તુઓ “અવાજ-તપાસ બાકી” માં છે.';

  @override
  String get queueNothingRankedShort => 'હજી કંઈ ક્રમમાં નથી';

  @override
  String needsScanTitle(int count) {
    return 'અવાજ-તપાસ બાકી ($count)';
  }

  @override
  String get needsScanChip => 'અવાજ-તપાસ બાકી';

  @override
  String get needsScanEmpty => 'દરેક વસ્તુની કામની અવાજ-તપાસ છે.';

  @override
  String get saveHarvest => 'પાક સેવ કરો';

  @override
  String get harvestNameField => 'પાકનું નામ';

  @override
  String get harvestNameHelper => 'દા.ત. “રવી ઘઉં 2026”';

  @override
  String get harvestedOnField => 'લણણીની તારીખ';

  @override
  String get notesFieldOptional => 'નોંધ (વૈકલ્પિક)';

  @override
  String get harvestAppBar => 'પાક';

  @override
  String get harvestNotFound => 'આ પાક આ ફોન પર મળ્યો નહીં.';

  @override
  String get harvestAddSack => 'આ પાકમાં કોથળો નોંધો';

  @override
  String get harvestSacksTitle => 'આ પાકના કોથળા';

  @override
  String get harvestSacksEmpty => 'આ પાકમાં હજી કોઈ કોથળો નથી';

  @override
  String get harvestSacksEmptyDetail =>
      'આ પાકમાંથી ભરેલા કોથળા નોંધો, પછી વેચતા પહેલાં તેની અવાજ-તપાસ કરો.';

  @override
  String get preSaleBody =>
      'ખરીદનાર માટે આ પાકના કોથળાનો સારાંશ. દરેક અવાજ-તપાસ સાથે તેનું મોડેલ વર્ઝન અને પ્રાયોગિક સ્થિતિ દેખાય છે, અને તપાસનાં ખાતરી કરેલાં તારણ અલગ લખેલાં હોય છે. આ ગુણવત્તાનું પ્રમાણપત્ર નથી.';

  @override
  String get notScannedYet => 'હજી અવાજ-તપાસ થઈ નથી';

  @override
  String get lotAppBar => 'લૉટ';

  @override
  String get lotNotFound => 'આ લૉટ આ ફોન પર મળ્યો નહીં.';

  @override
  String get supplierNotRecorded => 'સપ્લાયરની નોંધ નથી';

  @override
  String get fieldDeclaredQuantity => 'જણાવેલો જથ્થો';

  @override
  String get fieldReceived => 'મળ્યાની તારીખ';

  @override
  String get fieldScreened => 'તપાસેલા';

  @override
  String get screeningStatusTitle => 'તપાસની સ્થિતિ';

  @override
  String get screeningStatusBody =>
      'અવાજ-તપાસ અને ખોલીને કરેલી તપાસ જોયા પછી આ તમે નક્કી કરો છો. અવાજ-તપાસ તેને ક્યારેય બદલતી નથી, અને Kernel ક્યારેય કોઈ લૉટ સ્વીકારતું કે નકારતું નથી.';

  @override
  String currentStatus(String status) {
    return 'હાલ: $status';
  }

  @override
  String get lotSacksTitle => 'આ લૉટના કોથળા';

  @override
  String get lotSacksEmpty => 'આ લૉટમાં હજી કોઈ કોથળો નથી';

  @override
  String get lotSacksEmptyAction => 'આ લૉટમાં કોથળો નોંધો';

  @override
  String get sampleScansTitle => 'નમૂના અવાજ-તપાસ';

  @override
  String get sampleScansBody =>
      'આ માલના કોથળાની એક પછી એક અવાજ-તપાસ કરો. દરેક પરિણામ ખાતરી વગરનો મોડેલનો અંદાજ છે અને તેનાથી લૉટની સ્થિતિ બદલાતી નથી.';

  @override
  String get sampleScansStart => 'નમૂના અવાજ-તપાસ શરૂ કરો';

  @override
  String get physicalChecksTitle => 'ખોલીને તપાસ';

  @override
  String get physicalChecksBody =>
      'દરેક કોથળો ખોલીને અંદર જુઓ, પછી જે મળ્યું તે નોંધો. તમારાં તારણ અવાજ-તપાસથી અલગ રખાય છે.';

  @override
  String get recordPhysicalCheck => 'ખોલીને તપાસ નોંધો';

  @override
  String get noPhysicalCheckYet => 'હજી ખોલીને તપાસ થઈ નથી';

  @override
  String lotSummaryTitle(String code) {
    return 'લૉટ $code નો સારાંશ રિપોર્ટ';
  }

  @override
  String get lotSummaryBody =>
      'આ ફોનની નોંધોમાંથી: મોડેલની માહિતી સાથે નમૂના અવાજ-તપાસ, અને ખોલીને તપાસનાં તારણ અલગ. તમારા પોતાના નિર્ણયમાં મદદ માટે તેનો ઉપયોગ કરો.';

  @override
  String savedLot(String code) {
    return 'લૉટ $code સેવ થયો';
  }

  @override
  String get saveLot => 'લૉટ સેવ કરો';

  @override
  String get lotCodeField => 'લૉટ કોડ';

  @override
  String get lotCodeHelper => 'માલની પહોંચ પરનો નંબર';

  @override
  String get validationLotCode => 'લૉટ કોડ લખો';

  @override
  String get supplierFieldOptional => 'સપ્લાયરનું નામ (વૈકલ્પિક)';

  @override
  String get declaredQuantityField => 'જણાવેલો જથ્થો';

  @override
  String get receivedOnField => 'મળ્યાની તારીખ';

  @override
  String shareSubject(String title) {
    return 'Kernel $title';
  }

  @override
  String exportFailed(String detail) {
    return 'રિપોર્ટ બનાવી કે મોકલી શકાયો નહીં. $detail';
  }

  @override
  String get exportPanelBody =>
      'ફક્ત આ ફોનમાં રાખેલી નોંધોમાંથી બને છે. દરેક અવાજ-તપાસ સાથે તેનું મોડેલ વર્ઝન અને પ્રાયોગિક સ્થિતિ દેખાય છે. AI ના અંદાજ અને તપાસનાં ખાતરી કરેલાં તારણ અલગ અલગ લખાય છે.';

  @override
  String get exportCsv => 'CSV બનાવો';

  @override
  String get exportPdf => 'PDF બનાવો';

  @override
  String get exportLabelsPdf => 'લેબલની PDF બનાવો';

  @override
  String exportSavedAt(String path) {
    return 'આ ફોન પર સેવ થયું: $path';
  }

  @override
  String get sackLabelsTitle => 'કોથળાનાં લેબલ છાપો';

  @override
  String get sackLabelsBody =>
      'આ કોથળાનાં QR લેબલની એક PDF. તેને છાપીને દરેક લેબલ તેના કોથળા પર ચોંટાડો; લેબલ વાંચતાં Kernel માં તે કોથળો ખૂલે છે.';

  @override
  String get reportsTitle => 'રિપોર્ટ';

  @override
  String get reportsFarmerHint =>
      'કોઈ પાકનો વેચાણ પહેલાંનો સારાંશ તે પાકના પાના પર છે.';

  @override
  String get reportsBuyerHint => 'લૉટનો સારાંશ રિપોર્ટ દરેક લૉટના પાના પર છે.';

  @override
  String get recentScans => 'તાજેતરની અવાજ-તપાસ';

  @override
  String get recentScansEmpty =>
      'હજી કોઈ અવાજ-તપાસ નથી. તમે રેકોર્ડ કરેલી તપાસ અહીં દેખાશે.';

  @override
  String get inventorySubtitleFarmer => 'તમારા પાક અને નોંધેલા કોથળા';

  @override
  String get inventorySubtitleHousehold =>
      'તમારા અનાજના ડબ્બા અને તે ક્યાં રાખ્યા છે';

  @override
  String get inventorySubtitleFpo => 'ગોડાઉન, ઓરડા, થપ્પીઓ અને કોથળા';

  @override
  String get inventorySubtitleBuyer => 'આવતા લૉટ અને તેના કોથળા';

  @override
  String get newHarvestAction => 'નવો પાક';

  @override
  String registerItemAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ડબ્બો ઉમેરો',
      'other': 'કોથળો નોંધો',
    });
    return '$_temp0';
  }

  @override
  String get addPlace => 'જગ્યા ઉમેરો';

  @override
  String get addLocation => 'જગ્યા ઉમેરો';

  @override
  String itemsSectionTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ડબ્બા',
      'other': 'કોથળા',
    });
    return '$_temp0';
  }

  @override
  String get lotsSectionEmpty =>
      'હજી કોઈ લૉટ નથી. ઉમેરવા માટે આવેલો માલ નોંધો.';

  @override
  String get placesTitle => 'જગ્યાઓ';

  @override
  String get locationsTitle => 'જગ્યાઓ';

  @override
  String get placesEmpty =>
      'હજી કોઈ જગ્યા નથી. ડબ્બા ક્યાં રાખ્યા છે તે જણાવવા એક ઉમેરો.';

  @override
  String get locationsEmpty =>
      'હજી કોઈ ગોડાઉન નથી. એક ઉમેરો, પછી તેના ઓરડા અને થપ્પીઓ.';

  @override
  String get harvestsSectionEmpty =>
      'હજી કોઈ પાક નથી. તેના કોથળા એકસાથે રાખવા અને વેચાણ પહેલાંનો સારાંશ બનાવવા એક પાક બનાવો.';

  @override
  String harvestCardSubtitle(String grain, String date) {
    return '$grain · લણણી $date';
  }

  @override
  String sackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count કોથળા',
      one: '1 કોથળો',
      zero: 'હજી કોઈ કોથળો નથી',
    );
    return '$_temp0';
  }

  @override
  String get itemDetailAppBar => 'વિગત';

  @override
  String get itemNotFound => 'આ વસ્તુ આ ફોન પર મળી નહીં.';

  @override
  String archiveItemMenu(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ડબ્બો બાજુ પર મૂકો',
      'other': 'કોથળો બાજુ પર મૂકો',
    });
    return '$_temp0';
  }

  @override
  String get archivedSnack => 'બાજુ પર મૂક્યું. તેનો ઇતિહાસ આ ફોન પર રહેશે.';

  @override
  String get archivedItemNotice =>
      'યાદી, કતાર અને નવા રિપોર્ટમાં દેખાશે નહીં. તેનો અવાજ-તપાસ ઇતિહાસ અને તપાસ એમ જ રહે છે.';

  @override
  String get restoreAction => 'પાછું લાવો';

  @override
  String scanThisItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'આ ડબ્બાની અવાજ-તપાસ કરો',
      'other': 'આ કોથળાની અવાજ-તપાસ કરો',
    });
    return '$_temp0';
  }

  @override
  String get setReminderAction => 'ફરી તપાસનું રિમાઇન્ડર મૂકો';

  @override
  String get researchRecordTitle => 'લેબલવાળો નમૂનો રેકોર્ડ કરો';

  @override
  String get researchRecordSubtitle =>
      'સંશોધન મોડ: 2 સેકન્ડનું રેકોર્ડિંગ રાખો અને તાલીમ ડેટા માટે તેને લેબલ આપો';

  @override
  String get fieldQuantity => 'જથ્થો';

  @override
  String get fieldStoredSince => 'ક્યારથી ભરેલું';

  @override
  String storedSinceValue(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days દિવસ',
      one: '1 દિવસ',
    );
    return '$date ($_temp0)';
  }

  @override
  String get fieldLocation => 'જગ્યા';

  @override
  String get fieldLot => 'લૉટ';

  @override
  String get fieldHarvest => 'પાક';

  @override
  String nameWithType(String name, String type) {
    return '$name ($type)';
  }

  @override
  String registeredAs(String role) {
    return '$role તરીકે નોંધાયેલું';
  }

  @override
  String get scanHistoryTitle => 'અવાજ-તપાસનો ઇતિહાસ';

  @override
  String get scanHistoryAppendOnly =>
      'દરેક અવાજ-તપાસ જેવી રેકોર્ડ થઈ તેવી જ રખાય છે. નવી તપાસ જૂનીને ક્યારેય બદલતી નથી.';

  @override
  String scanHistoryEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'હજી કોઈ અવાજ-તપાસ નથી. એક રેકોર્ડ કરવા “આ ડબ્બાની અવાજ-તપાસ કરો” દબાવો.',
      'other': 'હજી કોઈ અવાજ-તપાસ નથી. એક રેકોર્ડ કરવા “આ કોથળાની અવાજ-તપાસ કરો” દબાવો.',
    });
    return '$_temp0';
  }

  @override
  String get inspectionsTitle => 'જોઈને તપાસ';

  @override
  String get inspectionsEmpty => 'હજી કોઈ તપાસ નોંધાઈ નથી.';

  @override
  String get remindersTitle => 'રિમાઇન્ડર';

  @override
  String get remindersEmpty => 'કોઈ રિમાઇન્ડર મૂકેલું નથી.';

  @override
  String recheckOn(String when) {
    return '$when એ ફરી તપાસ';
  }

  @override
  String get reminderMarkDone => 'થઈ ગયું તરીકે નિશાની કરો';

  @override
  String get reminderCancel => 'રિમાઇન્ડર રદ કરો';

  @override
  String get assignDialogTitle => 'તપાસ સોંપો';

  @override
  String get assignDialogLabel => 'કોને સોંપી';

  @override
  String get assignDialogHelper => 'આગળની તપાસ કોણ કરશે';

  @override
  String get assignClear => 'સોંપણી દૂર કરો';

  @override
  String savedNamed(String name) {
    return '$name સેવ થયું';
  }

  @override
  String saveFailed(String detail) {
    return 'સેવ થઈ શક્યું નહીં: $detail';
  }

  @override
  String saveItem(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ડબ્બો સેવ કરો',
      'other': 'કોથળો સેવ કરો',
    });
    return '$_temp0';
  }

  @override
  String itemLabelField(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ડબ્બાનું લેબલ',
      'other': 'કોથળાનું લેબલ',
    });
    return '$_temp0';
  }

  @override
  String itemLabelHelper(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ડબ્બા પર લખેલું નામ',
      'other': 'કોથળા પર લખેલું નામ',
    });
    return '$_temp0';
  }

  @override
  String get validationLabel => 'લેબલ લખો';

  @override
  String get grainTypeField => 'અનાજનો પ્રકાર';

  @override
  String get validationGrain => 'અનાજનો પ્રકાર લખો';

  @override
  String get quantityField => 'જથ્થો';

  @override
  String get unitField => 'એકમ';

  @override
  String get storageDateField => 'ભર્યાની તારીખ';

  @override
  String get harvestFieldOptional => 'પાક (વૈકલ્પિક)';

  @override
  String get harvestFieldNone =>
      'હજી કોઈ પાક નથી. “મારું અનાજ” માંથી એક બનાવો.';

  @override
  String get none => 'કંઈ નહીં';

  @override
  String get locationFieldOptional => 'જગ્યા (વૈકલ્પિક)';

  @override
  String locationFieldNone(String where) {
    return 'હજી કોઈ જગ્યા નથી. તમે તેને $where માંથી ઉમેરી શકો છો.';
  }

  @override
  String get lotFieldOptional => 'લૉટ (વૈકલ્પિક)';

  @override
  String get lotFieldNone => 'હજી કોઈ લૉટ નોંધાયો નથી.';

  @override
  String get locationAppBar => 'જગ્યા';

  @override
  String get locationNotFound => 'આ જગ્યા આ ફોન પર મળી નહીં.';

  @override
  String get archivedLocationNotice =>
      'આ જગ્યા બાજુ પર મૂકેલી છે. તેના કોથળા અને તેનો ઇતિહાસ એમ જ રહે છે.';

  @override
  String registerHere(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'અહીં ડબ્બો ઉમેરો',
      'other': 'અહીં કોથળો નોંધો',
    });
    return '$_temp0';
  }

  @override
  String get addInside => 'અંદર ઉમેરો';

  @override
  String get batchHere => 'અહીં એક પછી એક તપાસ';

  @override
  String get insideTitle => 'અંદર';

  @override
  String get insideEmpty => 'આ જગ્યાની અંદર હજી કંઈ નથી.';

  @override
  String itemsHereTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'અહીંના ડબ્બા',
      'other': 'અહીંના કોથળા',
    });
    return '$_temp0';
  }

  @override
  String itemsHereEmpty(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'અહીં હજી કોઈ ડબ્બો રાખેલો નથી.',
      'other': 'અહીં હજી કોઈ કોથળો રાખેલો નથી.',
    });
    return '$_temp0';
  }

  @override
  String get saveLocation => 'જગ્યા સેવ કરો';

  @override
  String get typeField => 'પ્રકાર';

  @override
  String get nameField => 'નામ';

  @override
  String get validationName => 'નામ લખો';

  @override
  String get parentFieldOptional => 'શેની અંદર (વૈકલ્પિક)';

  @override
  String get parentFieldHelper => 'દા.ત. ગોડાઉનની અંદરનો ઓરડો';

  @override
  String get parentTopLevel => 'કશાની અંદર નહીં (સૌથી ઉપર)';

  @override
  String get roleSelectTitle => 'તમારી ભૂમિકા પસંદ કરો';

  @override
  String get roleSelectSubtitle => 'એક ઍપ. ચાર પ્રકારનાં કામ.';

  @override
  String get roleCurrent => 'હાલની';

  @override
  String get roleSwitchKeepsRecords =>
      'ભૂમિકા બદલો તો પણ આ ફોન પરની દરેક નોંધ રહે છે. તમે ગમે ત્યારે પાછા બદલી શકો છો.';

  @override
  String roleSaveFailed(String detail) {
    return 'તમારી ભૂમિકા સેવ થઈ શકી નહીં: $detail';
  }

  @override
  String startDataError(String detail) {
    return 'Kernel આ ફોન પર પોતાનો ડેટા ખોલી શક્યું નહીં. કૃપા કરીને ઍપ ફરી શરૂ કરો.\n\nવિગત: $detail';
  }

  @override
  String get onboardingSkip => 'છોડો';

  @override
  String get onboardingBack => 'પાછળ';

  @override
  String get onboardingNext => 'આગળ';

  @override
  String onboardingStep(int step, int total) {
    return '$total માંથી પગલું $step';
  }

  @override
  String get onboardingPrivacyTitle => 'અવાજ તમારા ફોન પર જ રહે છે';

  @override
  String get onboardingPrivacy1 =>
      'Kernel અનાજનો અવાજ 2 સેકન્ડ સાંભળે છે અને અહીં જ આ ફોન પર તેને તપાસે છે.';

  @override
  String get onboardingPrivacy2 =>
      'કંઈ અપલોડ થતું નથી. કોઈ ખાતું નથી, કોઈ ક્લાઉડ નથી, અને બધું ઇન્ટરનેટ વગર ચાલે છે.';

  @override
  String get onboardingPrivacy3 =>
      'તમે સેટિંગ્સમાં રાખવાનું પસંદ ન કરો તો તપાસ પછી રેકોર્ડિંગ કાઢી નખાય છે.';

  @override
  String get onboardingHowTitle => 'અવાજ-તપાસ કેવી રીતે કરવી';

  @override
  String get onboardingHow1 =>
      'ફોનને કોથળા કે ડબ્બા પર સપાટ ટેકવો, માઇક તેને અડેલું રહે.';

  @override
  String get onboardingHow2 =>
      'શાંત ઓરડો પસંદ કરો. વાત કરવાનું બંધ કરો અને બને તો પંખા બંધ કરો.';

  @override
  String get onboardingHow3 => 'Kernel સાંભળે ત્યારે 2 સેકન્ડ જરાય હલશો નહીં.';

  @override
  String get onboardingHow4 =>
      'પરિણામો પ્રાયોગિક છે. નિર્ણય લેતા પહેલાં હંમેશાં અનાજ જાતે તપાસો.';

  @override
  String get onboardingRoleTitle => 'તમારી ભૂમિકા પસંદ કરો';

  @override
  String get heroEyebrowListen => 'તમારા અનાજનો અવાજ સાંભળો';

  @override
  String get heroStartScan => 'અવાજ-તપાસ શરૂ કરો';

  @override
  String get heroStartBatch => 'એક પછી એક તપાસ શરૂ';

  @override
  String get loading => 'ખૂલી રહ્યું છે…';

  @override
  String get farmerHomeTitle => 'ખેડૂતનું પાનું';

  @override
  String farmerHomeHarvestSubtitle(String name) {
    return 'પાક: $name';
  }

  @override
  String get farmerHeroTitle => 'અનાજની અવાજ-તપાસ';

  @override
  String get farmerHeroSubtitle =>
      'બતાવેલી રીતે 2 સેકન્ડનું રેકોર્ડિંગ શરૂ કરો';

  @override
  String get farmerEmptyDetail =>
      'અવાજ-તપાસ અને હિસાબ શરૂ કરવા એક કોથળો નોંધો.';

  @override
  String registeredSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count નોંધાયેલા કોથળા',
      one: '1 નોંધાયેલો કોથળો',
    );
    return '$_temp0';
  }

  @override
  String get noFollowUps => 'આગળની કોઈ તપાસ બાકી નથી';

  @override
  String sacksRequireFollowUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count કોથળાની આગળ તપાસ જરૂરી',
      one: '1 કોથળાની આગળ તપાસ જરૂરી',
    );
    return '$_temp0';
  }

  @override
  String get harvestsTitle => 'પાક';

  @override
  String get harvestsEmptyCard =>
      'વેચાણ પહેલાંના રિપોર્ટ માટે કોથળા એકસાથે રાખવા પાક બનાવો';

  @override
  String harvestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count પાક · સૌથી નવો ખોલો',
      one: '1 પાક · સૌથી નવો ખોલો',
    );
    return '$_temp0';
  }

  @override
  String get queueTitle => 'તપાસની કતાર';

  @override
  String get queueCardSubtitle => 'કયા કોથળા પહેલાં તપાસવા';

  @override
  String get preSaleCardSubtitle => 'તમારી નોંધોમાંથી સારાંશ બનાવો';

  @override
  String preSaleCardHarvest(String name) {
    return '$name નો વેચાણ પહેલાંનો સારાંશ';
  }

  @override
  String get householdHomeTitle => 'ઘરનો સંગ્રહ';

  @override
  String get householdHomeSubtitle => 'ઘરના અનાજનો હિસાબ';

  @override
  String get householdHeroTitle => 'ડબ્બાની અવાજ-તપાસ કરો';

  @override
  String get householdHeroSubtitle => 'અનાજની હાલત નોંધો';

  @override
  String get householdEmptyDetail =>
      'કેટલા દિવસથી ભરેલું છે તે જોવા અનાજનો ડબ્બો ઉમેરો.';

  @override
  String get remindersCardTitle => 'તપાસનાં રિમાઇન્ડર';

  @override
  String get remindersCardEmpty =>
      'કોઈ રિમાઇન્ડર નક્કી નથી. મૂકવા માટે કોઈ ડબ્બો ખોલો.';

  @override
  String remindersScheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count રિમાઇન્ડર નક્કી',
      one: '1 રિમાઇન્ડર નક્કી',
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
      other: '$days દિવસથી ભરેલું',
      one: '1 દિવસથી ભરેલું',
    );
    return '$_temp0';
  }

  @override
  String get reviewNeverScanned => 'હજી અવાજ-તપાસ થઈ નથી — જોવાનો સમય';

  @override
  String reviewDueSince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'જોવાનો સમય — છેલ્લી અવાજ-તપાસ $days દિવસ પહેલાં',
      one: 'જોવાનો સમય — છેલ્લી અવાજ-તપાસ 1 દિવસ પહેલાં',
    );
    return '$_temp0';
  }

  @override
  String reviewNextIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'આગળની તપાસ $days દિવસમાં',
      one: 'આગળની તપાસ 1 દિવસમાં',
    );
    return '$_temp0';
  }

  @override
  String get reviewDue => 'જોવાનો સમય';

  @override
  String reminderOn(String date) {
    return 'રિમાઇન્ડર $date';
  }

  @override
  String get recheckAction => 'ફરી તપાસો';

  @override
  String get remindMeAction => 'યાદ અપાવો';

  @override
  String get reminderSheetTitle => 'ફરી તપાસનું રિમાઇન્ડર મૂકો';

  @override
  String reminderSheetSubtitle(String label) {
    return '$label માટે. Kernel તમને આ ફોન પર જ યાદ અપાવશે.';
  }

  @override
  String reminderInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days દિવસમાં',
      one: '1 દિવસમાં',
    );
    return '$_temp0';
  }

  @override
  String get reminderDateLabel => 'તારીખ';

  @override
  String get reminderTimeLabel => 'સમય';

  @override
  String get reminderOnDeviceNote =>
      'રિમાઇન્ડર આ ફોન પર જ નક્કી થાય છે અને ઇન્ટરનેટ વગર ચાલે છે.';

  @override
  String get reminderSave => 'રિમાઇન્ડર સેવ કરો';

  @override
  String get reminderPastError => 'આગળનો કોઈ સમય પસંદ કરો.';

  @override
  String get reminderSet => 'રિમાઇન્ડર મુકાયું';

  @override
  String get reminderSetNotificationsOff =>
      'રિમાઇન્ડર સેવ થયું. સૂચનાઓ બંધ છે, તેથી તે ફક્ત ઍપની અંદર દેખાશે.';

  @override
  String reminderFailed(String detail) {
    return 'રિમાઇન્ડર મૂકી શકાયું નહીં: $detail';
  }

  @override
  String get fpoHomeTitle => 'ગોડાઉનની ઝલક';

  @override
  String get fpoHomeSubtitle => 'ગોડાઉન, ઓરડા અને થપ્પીઓ';

  @override
  String get fpoEmptyDetail =>
      'કોથળા નોંધો, પછી એક પછી એક તેની અવાજ-તપાસ કરો જેથી તપાસની કતાર બને.';

  @override
  String sacksScannedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'આજે $count કોથળાની અવાજ-તપાસ થઈ',
      one: 'આજે 1 કોથળાની અવાજ-તપાસ થઈ',
    );
    return '$_temp0';
  }

  @override
  String queueSummary(int flagged, int needScan) {
    String _temp0 = intl.Intl.pluralLogic(
      needScan,
      locale: localeName,
      other: '$needScan કોથળાની અવાજ-તપાસ બાકી',
      one: '1 કોથળાની અવાજ-તપાસ બાકી',
    );
    return '$flagged પર ધ્યાન આપો · $_temp0';
  }

  @override
  String get assignedTitle => 'સોંપેલી તપાસ';

  @override
  String get assignedNone => 'કોઈ ખુલ્લી તપાસ નથી';

  @override
  String inspectionsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count તપાસ ખુલ્લી',
      one: '1 તપાસ ખુલ્લી',
    );
    return '$_temp0';
  }

  @override
  String get fpoAddLocationTitle => 'ગોડાઉન, ઓરડો કે થપ્પી ઉમેરો';

  @override
  String get fpoAddLocationSubtitle => 'કોથળા ક્યાં રાખ્યા છે તે મુજબ ગોઠવો';

  @override
  String get buyerHomeTitle => 'આવતા લૉટ';

  @override
  String get buyerHomeSubtitle => 'ખરીદી પહેલાં તપાસ';

  @override
  String get heroEyebrowDelivery => 'નવો માલ';

  @override
  String get buyerHeroTitle => 'આવેલો માલ નોંધો';

  @override
  String get buyerHeroSubtitle => 'સપ્લાયર, લૉટ, અનાજ, જથ્થો';

  @override
  String get buyerHeroAction => 'નોંધો';

  @override
  String get lotsEmptyMessage => 'હજી કોઈ લૉટ નથી';

  @override
  String get lotsEmptyDetail => 'તેના કોથળા તપાસવા આવેલો માલ નોંધો.';

  @override
  String get lotsEmptyAction => 'તમારો પહેલો માલ નોંધો';

  @override
  String get buyerReportCardTitle => 'તપાસ રિપોર્ટ';

  @override
  String get buyerReportCardSubtitle =>
      'તમારી નોંધોમાંથી લૉટ તપાસનો રિપોર્ટ બનાવો';

  @override
  String lotTitle(String code, String grain) {
    return '$code / $grain';
  }

  @override
  String get lotNoSacks => 'આ લૉટમાં હજી કોઈ કોથળો નોંધાયો નથી';

  @override
  String lotScreenedCount(int screened, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total કોથળામાંથી',
      one: '1 કોથળામાંથી',
    );
    return '$_temp0 $screened તપાસેલા';
  }

  @override
  String supplierChip(String name) {
    return 'સપ્લાયર: $name';
  }

  @override
  String get scanAppBarTitle => 'અવાજ-તપાસ';

  @override
  String get guidedScanTitle => 'બતાવેલી રીતે અવાજ-તપાસ';

  @override
  String get researchScanTitle => 'લેબલવાળો નમૂનો રેકોર્ડ કરો';

  @override
  String grainAndLabel(String grain, String label) {
    return '$grain • $label';
  }

  @override
  String get researchScanNoticeTitle => 'સંશોધન રેકોર્ડિંગ';

  @override
  String get researchScanNotice =>
      'આ 2 સેકન્ડનું રેકોર્ડિંગ આ ફોન પર જ ખાનગી રીતે રખાય છે, જેથી તમે તાલીમ ડેટા માટે તેને લેબલ આપી શકો. તેને જીવાતના પરિણામ તરીકે બતાવાતું નથી અને ક્યારેય અપલોડ થતું નથી.';

  @override
  String positioningTip(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ફોનને ડબ્બા પર દબાવો, હલ્યા વગર શાંત રહો',
      'other': 'ફોનને કોથળા પર દબાવો, હલ્યા વગર શાંત રહો',
    });
    return '$_temp0';
  }

  @override
  String positioningTipDetail(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'શાંત ઓરડામાં ફોનને ડબ્બા પર સપાટ મૂકો, માઇક તેને અડેલું રહે. 2 સેકન્ડ વાત ન કરો અને તેને હલાવશો નહીં.',
      'other': 'શાંત જગ્યાએ ફોનને કોથળા પર સપાટ મૂકો, માઇક તેને અડેલું રહે. 2 સેકન્ડ વાત ન કરો અને કોથળો હલાવશો નહીં.',
    });
    return '$_temp0';
  }

  @override
  String get infoQualityTitle => 'રેકોર્ડિંગની ગુણવત્તા';

  @override
  String get infoQualityBody =>
      'કોઈ પણ પરિણામ બતાવતા પહેલાં પાછળનો ઘોંઘાટ, ફાટેલો અવાજ અને શાંતિ તપાસાય છે.';

  @override
  String get infoDurationTitle => 'રેકોર્ડિંગનો સમય';

  @override
  String get infoDurationShort => '2 સેકન્ડ';

  @override
  String infoDurationRate(String khz) {
    return '$khz kHz પર 2 સેકન્ડ';
  }

  @override
  String get infoOnDeviceTitle => 'ફોન પર જ વિશ્લેષણ';

  @override
  String get infoOnDeviceBody => 'અપલોડની જરૂર નથી';

  @override
  String infoOnDeviceWithModel(String provenance) {
    return 'અપલોડની જરૂર નથી. $provenance';
  }

  @override
  String get micDeniedTitle => 'માઇકની મંજૂરી બંધ છે';

  @override
  String get micDeniedSubtitle => 'અનાજનો અવાજ સાંભળવા Kernel ને માઇક જોઈએ.';

  @override
  String get micDeniedPrivacy =>
      'અવાજ-તપાસ 2 સેકન્ડનો અવાજ રેકોર્ડ કરીને આ ફોન પર જ તપાસે છે. અવાજ ક્યારેય અપલોડ થતો નથી, અને તમે સેટિંગ્સમાં રેકોર્ડિંગ રાખવાનું પસંદ ન કરો તો તપાસ પછી કાઢી નખાય છે.';

  @override
  String get micDeniedBlocked =>
      'Kernel માટે માઇક બંધ કરેલું છે. ફોનનાં સેટિંગ્સ ખોલો, મંજૂરીઓ પસંદ કરો, પછી માઇકને મંજૂરી આપો.';

  @override
  String get micDeniedAskAgain =>
      'આગલી વખતે Kernel પૂછે ત્યારે, અથવા ફોનનાં સેટિંગ્સમાં, તમે મંજૂરી આપી શકો છો.';

  @override
  String get micDeniedStillUsable =>
      'માઇક વગર પણ તમે વસ્તુઓ નોંધી શકો છો, તમારો જથ્થો જોઈ શકો છો, ખોલીને તપાસ નોંધી શકો છો અને રિપોર્ટ બનાવી શકો છો.';

  @override
  String get actionOpenSettings => 'સેટિંગ્સ ખોલો';

  @override
  String get actionTryAgain => 'ફરી પ્રયાસ કરો';

  @override
  String get actionBrowseInventory => 'જથ્થો જુઓ';

  @override
  String get resultAppBarTitle => 'પરિણામ';

  @override
  String get resultTitle => 'તપાસનું પરિણામ';

  @override
  String get scanNotFound => 'આ અવાજ-તપાસ આ ફોન પર મળી નહીં.';

  @override
  String get retryNothingSaved =>
      'આ રેકોર્ડિંગ માટે જીવાત વિશે કંઈ સેવ થયું નથી.';

  @override
  String predictedClassLine(String label) {
    return 'મોડેલનો અંદાજ (ખાતરી નથી): $label';
  }

  @override
  String modelScoreLine(String score) {
    return 'મોડેલ સ્કોર: $score (પ્રાયોગિક, આ ચોકસાઈનો આંકડો નથી)';
  }

  @override
  String get modelNoteTitleExperimental =>
      'પ્રાયોગિક મોડેલ — હજી સાબિત થયું નથી';

  @override
  String get modelNoteTitle => 'આ મોડેલ વિશે';

  @override
  String modelNoteOtherVersion(String version) {
    return 'આ અવાજ-તપાસમાં મોડેલ $version વપરાયું હતું, જે હવે ફોન પર નથી. તેની માહિતી આ તપાસ સાથે રખાઈ નથી, તેથી પરિણામને પ્રાયોગિક જ ગણો.';
  }

  @override
  String get physicalInspectionNote =>
      'અવાજથી તપાસ પ્રાયોગિક છે. સંગ્રહ કે વેચાણના કોઈ પણ નિર્ણય પહેલાં જાતે તપાસ જરૂરી છે.';

  @override
  String get actionRetry => 'ફરી કરો';

  @override
  String get actionRecordInspection => 'તપાસ નોંધો';

  @override
  String get actionScanAnother => 'બીજી અવાજ-તપાસ';

  @override
  String get recordingDetails => 'રેકોર્ડિંગની વિગત';

  @override
  String get fieldCaptured => 'રેકોર્ડ થયું';

  @override
  String get fieldDuration => 'સમય';

  @override
  String get fieldSampleRate => 'સેમ્પલ રેટ';

  @override
  String get fieldAnalysisTime => 'વિશ્લેષણનો સમય';

  @override
  String get fieldDevice => 'ફોન';

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
      'container': 'જે ડબ્બાનો અવાજ સાંભળવો છે તે પસંદ કરો',
      'other': 'જે કોથળાનો અવાજ સાંભળવો છે તે પસંદ કરો',
    });
    return '$_temp0';
  }

  @override
  String get batchScanTitle => 'એક પછી એક અવાજ-તપાસ';

  @override
  String get batchScanSubtitle => 'કોથળાની એક પછી એક અવાજ-તપાસ કરો';

  @override
  String get qrCardTitle => 'QR લેબલથી ખોલો';

  @override
  String qrCardSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'તે ડબ્બો ખોલવા Kernel લેબલ તરફ કૅમેરા રાખો',
      'other': 'તે કોથળો ખોલવા Kernel કોથળા લેબલ તરફ કૅમેરા રાખો',
    });
    return '$_temp0';
  }

  @override
  String get oneAtATimeTitle => 'એક વખતે એક';

  @override
  String get oneAtATimeBody =>
      'દરેક રેકોર્ડિંગ એક જ વસ્તુનું હોય છે. વસ્તુઓની એક પછી એક અવાજ-તપાસ કરો; એક તપાસ ક્યારેય ઘણી વસ્તુઓને એકસાથે જોતી નથી.';

  @override
  String emptyItemsMessage(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'હજી કોઈ ડબ્બો નથી',
      'other': 'હજી કોઈ કોથળો નથી',
    });
    return '$_temp0';
  }

  @override
  String emptyItemsAction(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'તમારો પહેલો ડબ્બો ઉમેરો',
      'other': 'તમારો પહેલો કોથળો નોંધો',
    });
    return '$_temp0';
  }

  @override
  String get scanTabEmptyDetail =>
      'પહેલાં એક નોંધો, પછી અવાજ-તપાસ માટે પાછા આવો.';

  @override
  String get scansTodayTitle => 'આજની અવાજ-તપાસ';

  @override
  String scansTodaySummary(int scans, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items વસ્તુઓની',
      one: '1 વસ્તુની',
    );
    String _temp1 = intl.Intl.pluralLogic(
      scans,
      locale: localeName,
      other: '$scans અવાજ-તપાસ',
      one: '1 અવાજ-તપાસ',
    );
    return 'મધરાતથી $_temp0 $_temp1';
  }

  @override
  String get scansTodayEmpty =>
      'આજે હજી કોઈ અવાજ-તપાસ નથી. તમે રેકોર્ડ કરેલી તપાસ તરત અહીં દેખાશે.';

  @override
  String get experimentalBadge => 'પ્રાયોગિક';

  @override
  String get errorCouldNotLoad => 'ખોલી શકાયું નહીં';

  @override
  String errorWithDetail(String prefix, String detail) {
    return '$prefix: $detail';
  }

  @override
  String fieldLabel(String label) {
    return '$label:';
  }

  @override
  String get validationQuantityEmpty => 'જથ્થો લખો';

  @override
  String get validationQuantityPositive => '0 થી મોટી સંખ્યા લખો';

  @override
  String get actionCancel => 'રદ કરો';

  @override
  String get actionSave => 'સેવ કરો';

  @override
  String get offlineLabel => 'ઑફલાઇન';

  @override
  String get onlineLabel => 'ઑનલાઇન';

  @override
  String get offlineSemantics => 'ઑફલાઇન. આ ફોન પર બધું ચાલતું રહે છે.';

  @override
  String get onlineSemantics => 'ઑનલાઇન. Kernel ને ઇન્ટરનેટની જરૂર નથી.';

  @override
  String get qrTooltip => 'QR લેબલથી કોથળો ખોલો';

  @override
  String get menuTooltip => 'મેનુ';

  @override
  String get menuSwitchRole => 'ભૂમિકા બદલો';

  @override
  String get menuSettings => 'સેટિંગ્સ';

  @override
  String itemTileSubtitle(String grain, String quantity, String date) {
    return '$grain · $quantity · ભર્યું $date';
  }

  @override
  String get archivedBadge => 'બાજુ પર મૂકેલું';

  @override
  String get chipRetryNeeded => 'ફરી કરવું પડશે';

  @override
  String chipAiUnverified(String label) {
    return 'AI: $label (ખાતરી નથી)';
  }

  @override
  String scanTileTitle(String item, String when) {
    return '$item · $when';
  }

  @override
  String qualityChip(String quality) {
    return 'ગુણવત્તા: $quality';
  }

  @override
  String get chipAudioKept => 'અવાજ ફોન પર રાખ્યો છે';

  @override
  String photoSemantics(int number) {
    return 'પુરાવાનો ફોટો $number. પૂરા કદમાં ખૂલે છે.';
  }

  @override
  String get photoMissing => 'આ ફોટો હવે આ ફોન પર નથી.';

  @override
  String get photoRemove => 'ફોટો કાઢો';

  @override
  String verifiedFindingLine(String finding) {
    return 'ખાતરી કરેલું તારણ: $finding';
  }

  @override
  String inspectorLine(String inspector, String when) {
    return '$inspector · $when';
  }

  @override
  String followUpChip(String status) {
    return 'આગળની તપાસ: $status';
  }

  @override
  String get unassigned => 'કોઈને સોંપી નથી';

  @override
  String assignedToChip(String name) {
    return '$name ને સોંપી';
  }

  @override
  String get followUpChangeTooltip => 'આગળની તપાસની સ્થિતિ બદલો';

  @override
  String get followUpUpdate => 'સ્થિતિ બદલો';

  @override
  String get assignAction => 'સોંપો';

  @override
  String get archiveAction => 'બાજુ પર મૂકો';

  @override
  String archiveConfirmTitle(String name) {
    return '$name બાજુ પર મૂકવું છે?';
  }

  @override
  String get archiveConfirmItemBody =>
      'તે યાદી, કતાર અને નવા રિપોર્ટમાં દેખાશે નહીં. તેનો અવાજ-તપાસ ઇતિહાસ અને તપાસ આ ફોન પર રહેશે અને કાઢી નખાશે નહીં.';

  @override
  String get archiveConfirmLotBody =>
      'આ લૉટ તમારી યાદી અને નવા રિપોર્ટમાં દેખાશે નહીં. તેના કોથળા, તેનો અવાજ-તપાસ ઇતિહાસ અને તપાસ આ ફોન પર રહેશે.';

  @override
  String get archiveConfirmLocationBody =>
      'આ જગ્યા યાદી અને પસંદગીમાં દેખાશે નહીં. ત્યાં રાખેલા કોથળા, તેનો અવાજ-તપાસ ઇતિહાસ અને તપાસ આ ફોન પર રહેશે.';

  @override
  String get archiveConfirmHarvestBody =>
      'આ પાક તમારી યાદી અને નવા રિપોર્ટમાં દેખાશે નહીં. તેના કોથળા, તેનો અવાજ-તપાસ ઇતિહાસ અને તપાસ આ ફોન પર રહેશે.';

  @override
  String get levelMeterLabel => 'માઇકના અવાજનું સ્તર';

  @override
  String get levelMeterWaiting => 'અવાજની રાહ જુએ છે';

  @override
  String levelMeterValue(int dbfs) {
    return '$dbfs dBFS';
  }

  @override
  String get voicePlacePhone => 'ફોન કોથળા પર મૂકો';

  @override
  String get voiceListening => 'સાંભળે છે';

  @override
  String get voiceDone => 'થઈ ગયું';

  @override
  String scanCouldNotRun(String detail) {
    return 'અવાજ-તપાસ ચાલી શકી નહીં: $detail';
  }

  @override
  String scanCouldNotSave(String detail) {
    return 'અવાજ-તપાસનું પરિણામ સેવ થઈ શક્યું નહીં, તેથી કંઈ રખાયું નથી. વિગત: $detail';
  }

  @override
  String get captureReady => 'સાંભળવા તૈયાર';

  @override
  String get captureListening => 'સાંભળે છે — હલશો નહીં';

  @override
  String get captureSaving => 'આ ફોન પર સેવ થાય છે';

  @override
  String get captureCheckingMic => 'માઇકની મંજૂરી તપાસે છે';

  @override
  String get captureGetReady => 'તૈયાર થાઓ — ફોન મૂકો';

  @override
  String captureSubtitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ફોનને ડબ્બા પર દબાવો',
      'other': 'ફોનને કોથળા પર દબાવો',
    });
    return '$_temp0';
  }

  @override
  String get captureResearchSubtitle =>
      'સંશોધન રેકોર્ડિંગ: આ 2 સેકન્ડ લેબલ આપવા માટે આ ફોન પર જ ખાનગી રીતે રખાય છે';

  @override
  String get captureStart => '2 સેકન્ડનું રેકોર્ડિંગ શરૂ કરો';

  @override
  String get captureStartAgain => '2 સેકન્ડનું રેકોર્ડિંગ ફરી કરો';

  @override
  String get captureStartResearch => 'લેબલવાળો નમૂનો રેકોર્ડ કરો (2 સે.)';

  @override
  String get captureProgressLabel => 'રેકોર્ડિંગ કેટલું થયું';

  @override
  String percentValue(int percent) {
    return '$percent ટકા';
  }

  @override
  String captureElapsed(String elapsed, String target) {
    return '$target સે. માંથી $elapsed સે.';
  }

  @override
  String get captureChecking => 'આ ફોન પર રેકોર્ડિંગ તપાસાય છે…';

  @override
  String get hintWaiting => 'સાંભળે છે…';

  @override
  String get hintTooQuiet => 'બહુ ધીમું — વધુ નજીક દબાવો';

  @override
  String get hintTooLoud => 'બહુ મોટો / ઘસાવાનો અવાજ';

  @override
  String get hintHoldStill => 'હલશો નહીં';

  @override
  String get appTitle => 'Kernel';

  @override
  String get roleFarmer => 'ખેડૂત';

  @override
  String get roleHousehold => 'ઘર';

  @override
  String get roleStorageFpo => 'સંગ્રહ/FPO';

  @override
  String get roleBuyer => 'ખરીદનાર';

  @override
  String get roleFarmerTagline => 'પાક અને વેચાણ પહેલાં તપાસ';

  @override
  String get roleHouseholdTagline => 'ડબ્બા અને રિમાઇન્ડર';

  @override
  String get roleStorageFpoTagline => 'ગોડાઉન અને એક પછી એક તપાસ';

  @override
  String get roleBuyerTagline => 'સપ્લાયર અને લૉટની તપાસ';

  @override
  String get navHome => 'હોમ';

  @override
  String get navScan => 'અવાજ-તપાસ';

  @override
  String get navInventory => 'જથ્થો';

  @override
  String get navReports => 'રિપોર્ટ';

  @override
  String get navInventoryFarmer => 'મારું અનાજ';

  @override
  String get navInventoryHousehold => 'મારા ડબ્બા';

  @override
  String get navInventoryFpo => 'ગોડાઉન';

  @override
  String get navInventoryBuyer => 'લૉટ';

  @override
  String get reportTitleFarmer => 'વેચાણ પહેલાંનો રિપોર્ટ';

  @override
  String get reportTitleHousehold => 'સંગ્રહ રિપોર્ટ';

  @override
  String get reportTitleFpo => 'ગોડાઉન રિપોર્ટ';

  @override
  String get reportTitleBuyer => 'લૉટ તપાસ રિપોર્ટ';

  @override
  String get locationTypeHome => 'ઘર';

  @override
  String get locationTypeContainer => 'ડબ્બો';

  @override
  String get locationTypeWarehouse => 'ગોડાઉન';

  @override
  String get locationTypeRoom => 'ઓરડો';

  @override
  String get locationTypeStack => 'થપ્પી';

  @override
  String get screeningPending => 'બાકી';

  @override
  String get screeningScreening => 'તપાસ ચાલુ';

  @override
  String get screeningNeedsPhysicalCheck => 'ખોલીને તપાસ બાકી';

  @override
  String get screeningReviewed => 'જોઈ લીધું';

  @override
  String get findingNoneFound => 'કંઈ મળ્યું નહીં';

  @override
  String get findingPestsFound => 'જીવાત મળી';

  @override
  String get findingInconclusive => 'નક્કી ન થયું';

  @override
  String get findingNoneFoundHelp =>
      'મેં તપાસ્યું અને કોઈ જીવાત કે નુકસાન દેખાયું નહીં';

  @override
  String get findingPestsFoundHelp => 'મને જીવાત, ઇયળ, જાળાં કે નુકસાન દેખાયું';

  @override
  String get findingInconclusiveHelp => 'તપાસીને પણ હું નક્કી ન કરી શક્યો';

  @override
  String get followUpOpen => 'ખુલ્લી';

  @override
  String get followUpInProgress => 'ચાલુ છે';

  @override
  String get followUpDone => 'થઈ ગઈ';

  @override
  String get reminderScheduled => 'નક્કી';

  @override
  String get reminderFired => 'હમણાંનો સમય';

  @override
  String get reminderDone => 'થઈ ગયું';

  @override
  String get reminderCancelled => 'રદ';

  @override
  String get reasonSilence =>
      'બહુ ધીમું: માઇક સુધી લગભગ કોઈ અવાજ પહોંચ્યો નહીં. ફોનને અનાજ પર જોરથી દબાવો.';

  @override
  String get reasonClipping =>
      'બહુ મોટો: અવાજ ફાટી ગયો. રેકોર્ડિંગ વખતે ટકોરા, ઘસારો કે ઠોકવાનું ન કરો.';

  @override
  String get reasonHighNoise =>
      'પાછળ બહુ ઘોંઘાટ છે. શાંત જગ્યાએ જાઓ અને હલશો નહીં.';

  @override
  String get reasonTooShort =>
      'રેકોર્ડિંગ બહુ ટૂંકું થયું. પૂરી 2 સેકન્ડ ફોન હલાવ્યા વગર રાખો.';

  @override
  String get reasonPermissionDenied =>
      'માઇકની મંજૂરી બંધ છે. અવાજ-તપાસ માટે ફોનનાં સેટિંગ્સમાં મંજૂરી આપો.';

  @override
  String get reasonCaptureError =>
      'માઇક રેકોર્ડ કરી શક્યું નહીં. માઇક વાપરતી બીજી ઍપ બંધ કરો અને ફરી પ્રયાસ કરો.';

  @override
  String get qualityPass => 'કામનું';

  @override
  String get qualityRetry => 'ફરી કરો';

  @override
  String get predictionClean => 'કોઈ સંકેત મળ્યો નહીં';

  @override
  String get predictionUncertain => 'નક્કી નથી';

  @override
  String get predictionInfested => 'જીવાત હોવાની શક્યતા';

  @override
  String get predictionNotEvaluated => 'પરિણામ મળ્યું નથી';

  @override
  String get sampleLabelClean => 'કોઈ નિશાની નથી';

  @override
  String get sampleLabelInfested => 'જીવાત લાગી છે';

  @override
  String get sampleLabelUnknown => 'ખબર નથી';

  @override
  String get headlineRetry => 'રેકોર્ડિંગ કામનું નથી — ફરી પ્રયાસ કરો';

  @override
  String get headlineNotEvaluated =>
      'પરિણામ મળ્યું નથી — કોઈ મોડેલ લગાવેલું નથી. જાતે ખોલીને તપાસો.';

  @override
  String get headlineNotEvaluatedWithModel =>
      'પરિણામ મળ્યું નથી — મોડેલ આ રેકોર્ડિંગ તપાસી શક્યું નહીં. જાતે ખોલીને તપાસો.';

  @override
  String get headlineInspectionNeeded =>
      'તપાસ જરૂરી — મોડેલના પરિણામની ખાતરી થઈ નથી';

  @override
  String get headlineClean =>
      'કોઈ સંકેત મળ્યો નહીં — આ ગેરંટી નથી; વેચાણ/સંગ્રહના નિર્ણય પહેલાં જાતે તપાસો';

  @override
  String get provenanceNone => 'મોડેલ: નથી — પરિણામ મળ્યું નથી';

  @override
  String provenanceExperimental(String version) {
    return 'મોડેલ $version — પ્રાયોગિક';
  }

  @override
  String provenanceValidated(String version) {
    return 'મોડેલ $version — સાબિત થયેલું';
  }

  @override
  String dateTimeJoin(String date, String time) {
    return '$date, $time';
  }

  @override
  String get nextStepEyebrow => 'આગળનું પગલું';

  @override
  String get nextNothingPending =>
      'હમણાં કંઈ તાકીદનું નથી. ધ્યાન રાખવા નિયમિત અવાજ-તપાસ કરતા રહો.';

  @override
  String get quickScanAction => 'હમણાં અવાજ-તપાસ કરો';

  @override
  String scansTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'આજે $count અવાજ-તપાસ',
      one: 'આજે 1 અવાજ-તપાસ',
      zero: 'આજે કોઈ અવાજ-તપાસ નથી',
    );
    return '$_temp0';
  }

  @override
  String scanActivityLine(int today, int week) {
    return 'અવાજ-તપાસ: આજે $today · છેલ્લા 7 દિવસમાં $week';
  }

  @override
  String nextRegisterFirst(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'તમારો પહેલો ડબ્બો નોંધો',
      'other': 'તમારો પહેલો કોથળો નોંધો',
    });
    return '$_temp0';
  }

  @override
  String get nextRegisterFirstBody =>
      'નામ, અનાજ અને જથ્થો લખો. એક મિનિટ લાગે છે.';

  @override
  String get nextRegisterFirstLot => 'તમારો પહેલો માલ નોંધો';

  @override
  String get nextRegisterFirstLotBody => 'સપ્લાયર, લૉટ, અનાજ અને જથ્થો.';

  @override
  String nextScanOne(String label) {
    return '$label ની અવાજ-તપાસ કરો';
  }

  @override
  String nextScanSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count કોથળાની અવાજ-તપાસ બાકી',
      one: '1 કોથળાની અવાજ-તપાસ બાકી',
    );
    return '$_temp0';
  }

  @override
  String nextScanContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ડબ્બાની અવાજ-તપાસ બાકી',
      one: '1 ડબ્બાની અવાજ-તપાસ બાકી',
    );
    return '$_temp0';
  }

  @override
  String nextScanBody(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'container': 'ફોનને ડબ્બા પર દબાવીને 2 સેકન્ડની સાંભળવાની તપાસ.',
      'other': '2 સેકન્ડની સાંભળવાની તપાસ, એક વખતે એક કોથળો.',
    });
    return '$_temp0';
  }

  @override
  String nextInspectOne(String label) {
    return '$label ની તપાસ કરો';
  }

  @override
  String nextInspectSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'નિશાન કરેલા $count કોથળાની તપાસ કરો',
      one: 'નિશાન કરેલા 1 કોથળાની તપાસ કરો',
    );
    return '$_temp0';
  }

  @override
  String nextInspectContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'નિશાન કરેલા $count ડબ્બાની તપાસ કરો',
      one: 'નિશાન કરેલા 1 ડબ્બાની તપાસ કરો',
    );
    return '$_temp0';
  }

  @override
  String get nextInspectBody =>
      'મોડેલના પરિણામની ખાતરી થઈ નથી. અનાજને હાથથી તપાસો.';

  @override
  String nextReviewOne(String label) {
    return '$label: ફરી જોવાનો સમય';
  }

  @override
  String nextReviewSacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count કોથળા ફરી જોવાનો સમય',
      one: '1 કોથળો ફરી જોવાનો સમય',
    );
    return '$_temp0';
  }

  @override
  String nextReviewContainers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ડબ્બા ફરી જોવાનો સમય',
      one: '1 ડબ્બો ફરી જોવાનો સમય',
    );
    return '$_temp0';
  }

  @override
  String get nextReviewBody =>
      'છેલ્લી તપાસને ઘણો સમય થયો. ફરી સાંભળો અથવા તપાસો.';

  @override
  String nextReminderOne(String label) {
    return '$label: રિમાઇન્ડરનો સમય';
  }

  @override
  String nextReminderMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count રિમાઇન્ડરનો સમય',
      one: '1 રિમાઇન્ડરનો સમય',
    );
    return '$_temp0';
  }

  @override
  String get nextReminderBody =>
      'તમે મૂકેલી ફરી તપાસનો સમય થયો છે. આ અનાજ તપાસો.';

  @override
  String nextPhysicalOne(String label) {
    return 'લૉટ $label: જાતે તપાસ બાકી';
  }

  @override
  String nextPhysicalMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count લૉટની જાતે તપાસ બાકી',
      one: '1 લૉટની જાતે તપાસ બાકી',
    );
    return '$_temp0';
  }

  @override
  String get nextPhysicalBody =>
      'લૉટ ખોલો અને માણસે જે જોયું તે નોંધો. Kernel ક્યારેય લૉટ સ્વીકારતું કે નકારતું નથી.';

  @override
  String get nextFinishBatch => 'એક પછી એક તપાસ પૂરી કરો';

  @override
  String nextFinishBatchOne(String label) {
    return 'એક પછી એક તપાસ પૂરી કરો: $label';
  }

  @override
  String nextFinishBatchBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count કોથળા બાકી, એક વખતે એક',
      one: '1 કોથળો બાકી, એક વખતે એક',
      zero: 'આ જૂથના બધા કોથળાની અવાજ-તપાસ થઈ ગઈ',
    );
    return '$_temp0';
  }

  @override
  String get nextPreSale => 'વેચાણ પહેલાંનો રિપોર્ટ મોકલો';

  @override
  String nextPreSaleOne(String label) {
    return '$label નો વેચાણ પહેલાંનો રિપોર્ટ મોકલો';
  }

  @override
  String get nextLotSummary => 'લૉટનો સારાંશ મોકલો';

  @override
  String nextLotSummaryOne(String label) {
    return '$label નો લૉટ સારાંશ મોકલો';
  }

  @override
  String get nextExportBody =>
      'તમારી નોંધોમાંથી આ જ ફોન પર બનેલો. કોને મોકલવો તે તમે નક્કી કરો.';

  @override
  String get nextActionRegister => 'નોંધો';

  @override
  String get nextActionScan => 'અવાજ-તપાસ શરૂ';

  @override
  String get nextActionBatch => 'એક પછી એક તપાસ શરૂ';

  @override
  String get nextActionOpen => 'ખોલો';

  @override
  String get nextActionQueue => 'તપાસની કતાર ખોલો';

  @override
  String get nextActionOpenLot => 'લૉટ ખોલો';

  @override
  String get nextActionContinueBatch => 'એક પછી એક તપાસ ચાલુ રાખો';

  @override
  String get nextActionReport => 'રિપોર્ટ ખોલો';

  @override
  String get insightsTitle => 'માહિતી';

  @override
  String get insightsSubtitle => 'તમારી પોતાની નોંધોમાંથી આ જ ફોન પર ગણેલી';

  @override
  String get insightsCardSubtitle =>
      'પરિણામો, રેકોર્ડિંગની મુશ્કેલીઓ અને શેની તપાસ જોઈએ';

  @override
  String get insightsWindowLabel => 'સમયગાળો';

  @override
  String get insightsWindow7 => '7 દિવસ';

  @override
  String get insightsWindow30 => '30 દિવસ';

  @override
  String get insightsWindowAll => 'આખો સમય';

  @override
  String get insightsActivityTitle => 'અવાજ-તપાસનું કામ';

  @override
  String get insightsScansToday => 'આજની અવાજ-તપાસ';

  @override
  String get insightsScans7 => 'છેલ્લા 7 દિવસની અવાજ-તપાસ';

  @override
  String get insightsRatesTitle => 'પરિણામો';

  @override
  String get insightsRatesEmpty => 'આ સમયગાળામાં કોઈ અવાજ-તપાસ નથી';

  @override
  String get insightsRatesEmptyDetail =>
      'અહીં પરિણામો જોવા કોઈ કોથળા કે ડબ્બાની અવાજ-તપાસ કરો.';

  @override
  String get insightsExperimentalNote =>
      'પ્રાયોગિક મોડેલ: આ પરિણામોની ખાતરી થઈ નથી અને તે ખોટાં હોઈ શકે. સંગ્રહ કે વેચાણના કોઈપણ નિર્ણય પહેલાં જાતે તપાસો.';

  @override
  String get insightsNoModelResults =>
      'હજી મોડેલનું કોઈ પરિણામ નથી: કામના કોઈ રેકોર્ડિંગને મોડેલે તપાસ્યું નથી.';

  @override
  String get insightsRetryLabel => 'રેકોર્ડિંગ કામનું નથી (ફરી કરો)';

  @override
  String insightsBarValue(int count, int percent) {
    return '$count · $percent%';
  }

  @override
  String insightsTotalScans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'આ સમયગાળામાં $count અવાજ-તપાસ',
      one: 'આ સમયગાળામાં 1 અવાજ-તપાસ',
    );
    return '$_temp0';
  }

  @override
  String get insightsQualityTitle => 'રેકોર્ડિંગની મુશ્કેલીઓ';

  @override
  String get insightsQualityEmpty => 'આ સમયગાળામાં કોઈ નકામું રેકોર્ડિંગ નથી';

  @override
  String get insightsQualityHint =>
      'શાંત જગ્યાએ ફોનને કોથળા પર જોરથી દબાવવાથી મોટાભાગની મુશ્કેલીઓ દૂર થાય છે.';

  @override
  String get insightsInspectionsTitle => 'તપાસ';

  @override
  String get insightsInspectionsEmpty => 'હજી કોઈ તપાસ નોંધાઈ નથી';

  @override
  String insightsClosureRate(int percent) {
    return '$percent% તપાસ પૂરી થઈ';
  }

  @override
  String get insightsStaleTitle => 'સૌથી લાંબા સમયથી તપાસ વગરના';

  @override
  String get staleNeverScanned => 'ક્યારેય અવાજ-તપાસ થઈ નથી';

  @override
  String get qualityShortSilence => 'બહુ ધીમું';

  @override
  String get qualityShortClipping => 'બહુ મોટું (અવાજ ફાટ્યો)';

  @override
  String get qualityShortHighNoise => 'બહુ ઘોંઘાટ';

  @override
  String get qualityShortTooShort => 'બહુ ટૂંકું';

  @override
  String get qualityShortPermissionDenied => 'માઇક બંધ છે';

  @override
  String get qualityShortCaptureError => 'રેકોર્ડિંગમાં ખામી';

  @override
  String get queueFilterResult => 'મોડેલનું પરિણામ';

  @override
  String get queueFilterAllResults => 'બધાં પરિણામો';

  @override
  String get queueFilterPlace => 'જગ્યા';

  @override
  String get queueFilterAllPlaces => 'બધી જગ્યાઓ';

  @override
  String get queueFilterAge => 'છેલ્લી કામની અવાજ-તપાસ';

  @override
  String get queueFilterAnyAge => 'ક્યારેય પણ';

  @override
  String queueFilterWithinDays(int days) {
    return '$days દિવસની અંદર';
  }

  @override
  String queueFilterAgeNote(int days) {
    return 'જેની છેલ્લી કામની અવાજ-તપાસ $days દિવસથી જૂની છે, તે \"અવાજ-તપાસ બાકી\" માં જાય છે.';
  }

  @override
  String get queueNoMatch => 'આ ફિલ્ટર સાથે કંઈ મેળ ખાતું નથી.';

  @override
  String get rankReasonInfested => 'અહીં કેમ: જીવાત હોવાની શક્યતા (ખાતરી નથી)';

  @override
  String get rankReasonUncertain => 'અહીં કેમ: મોડેલને નક્કી ખબર ન હતી';

  @override
  String get rankReasonClean => 'નીચે કેમ: કોઈ સંકેત મળ્યો નહીં (ગેરંટી નથી)';

  @override
  String scannedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days દિવસ પહેલાં અવાજ-તપાસ થઈ',
      one: '1 દિવસ પહેલાં અવાજ-તપાસ થઈ',
      zero: 'આજે અવાજ-તપાસ થઈ',
    );
    return '$_temp0';
  }

  @override
  String get reminderSuggestedLabel => 'સૂચન — પસંદગી તમારી';

  @override
  String reminderSuggestedOther(String date) {
    return 'સૂચન: $date — પસંદગી તમારી';
  }

  @override
  String get reminderWordingTitle => 'સૂચવેલા શબ્દો';

  @override
  String get settingsAdviceSection => 'ફોન પર AI સહાયક (પ્રાયોગિક)';

  @override
  String get adviceToggle => 'ફોન પરનો AI સહાયક વાપરો';

  @override
  String get adviceToggleBody =>
      'શરૂઆતમાં બંધ રહે છે. તે ફક્ત આ જ ફોન પર ચાલે છે અને તમારું રેકોર્ડિંગ ક્યારેય સાંભળતો નથી; તે ફક્ત પરિણામો અને તારીખો જુએ છે. તે ખોટો હોઈ શકે. તમે તેને ગમે ત્યારે બંધ કરી શકો.';

  @override
  String get adviceStatusTitle => 'સહાયકની સ્થિતિ';

  @override
  String get adviceStatusOff => 'બંધ';

  @override
  String get adviceStatusNoModel => 'ચાલુ — હજી મોડેલ લાવ્યા નથી';

  @override
  String get adviceStatusLoading => 'મોડેલ ખૂલી રહ્યું છે…';

  @override
  String get adviceStatusReady => 'આ ફોન પર તૈયાર';

  @override
  String get adviceStatusBusy => 'લખી રહ્યો છે';

  @override
  String get adviceStatusFailed =>
      'મોડેલ ખૂલી શક્યું નહીં — Kernel તેનું સામાન્ય લખાણ બતાવે છે';

  @override
  String get adviceModelTitle => 'સહાયકનું મોડેલ';

  @override
  String get adviceModelNone => 'હજી મોડેલ લાવ્યા નથી';

  @override
  String get adviceModelId => 'મોડેલ';

  @override
  String get adviceModelVersion => 'આવૃત્તિ';

  @override
  String get adviceModelSize => 'કદ';

  @override
  String get adviceModelBackend => 'શેના પર ચાલે છે';

  @override
  String get adviceBackendGpu => 'ફોનની ગ્રાફિક્સ ચિપ (GPU)';

  @override
  String get adviceBackendCpu => 'ફોનનું પ્રોસેસર (CPU)';

  @override
  String get adviceBackendNone => 'હજી ખૂલ્યું નથી';

  @override
  String get adviceImportAction => 'મોડેલ લાવો';

  @override
  String get adviceImporting => 'મોડેલ લવાઈ રહ્યું છે';

  @override
  String adviceImportCopying(String copied, String total) {
    return '$total માંથી $copied કૉપિ થયું';
  }

  @override
  String adviceImportCopied(String copied) {
    return '$copied કૉપિ થયું';
  }

  @override
  String get adviceImportVerifying => 'મોડેલ ફાઇલ તપાસાઈ રહી છે…';

  @override
  String get adviceImportDone => 'મોડેલ આવી ગયું. તે આ જ ફોન પર રહે છે.';

  @override
  String adviceImportFailed(String detail) {
    return 'મોડેલ લાવી શકાયું નહીં: $detail';
  }

  @override
  String adviceImportNoSpace(String needed, String free) {
    return 'જગ્યા ઓછી છે: મોડેલને $needed જોઈએ, પણ આ ફોનમાં ફક્ત $free ખાલી છે.';
  }

  @override
  String get adviceDeleteAction => 'મોડેલ કાઢી નાખો';

  @override
  String get adviceDeleteConfirmTitle => 'સહાયકનું મોડેલ કાઢી નાખવું છે?';

  @override
  String get adviceDeleteConfirmBody =>
      'આનાથી મોડેલ ફાઇલ આ ફોનમાંથી નીકળી જશે. તમારી નોંધો પર કોઈ અસર નહીં થાય. પછીથી ફરી લાવી શકો છો.';

  @override
  String adviceDeleteFailed(String detail) {
    return 'મોડેલ કાઢી શકાયું નહીં: $detail';
  }

  @override
  String get adviceHelp =>
      'Google AI Edge Gallery વડે અથવા Hugging Face litert-community/gemma-4-E2B-it-litert-lm પરથી .litertlm મોડેલ મેળવો (Gemma ની શરતો લાગુ), પછી તેને અહીં લાવો.';

  @override
  String adviceProvenance(String modelVersion) {
    return 'આ જ ફોન પર બનેલું — પ્રાયોગિક · $modelVersion';
  }

  @override
  String get adviceNotDecision => 'આ નિર્ણય નથી — જાતે તપાસો';

  @override
  String get adviceGenerating => 'આ જ ફોન પર લખાઈ રહ્યું છે…';

  @override
  String get adviceExplainAction => 'આ પરિણામ સમજાવો';

  @override
  String get adviceExplainTitle => 'આ પરિણામનો અર્થ';

  @override
  String get adviceStaticRetry =>
      'રેકોર્ડિંગ કામનું ન હતું, તેથી કોઈ પરિણામ સાચવ્યું નથી. ફોનને કોથળા કે ડબ્બા પર જોરથી દબાવો, હલશો નહીં, શાંત રહો અને ફરી રેકોર્ડ કરો.';

  @override
  String get adviceStaticNotEvaluated =>
      'આ રેકોર્ડિંગનું કોઈ પરિણામ મળ્યું નથી, તેથી તે જીવાત વિશે કંઈ કહેતું નથી. અનાજને જાતે તપાસો.';

  @override
  String get adviceStaticInspection =>
      'પ્રાયોગિક મોડેલને કંઈક એવું સંભળાયું જેના પર ધ્યાન આપવું પડે. તેની ખાતરી થઈ નથી. કોઈપણ નિર્ણય પહેલાં અનાજને જાતે તપાસો.';

  @override
  String get adviceStaticClean =>
      'પ્રાયોગિક મોડેલને કોઈ સંકેત મળ્યો નહીં. આ ગેરંટી નથી. સંગ્રહ કે વેચાણના નિર્ણય પહેલાં અનાજને જાતે તપાસો.';

  @override
  String get reportAiSummaryToggle => 'AI એ લખેલો સારાંશ ઉમેરો';

  @override
  String get reportAiSummaryBody =>
      'રિપોર્ટના આંકડા પરથી આ જ ફોન પર લખાયેલો. પહેલાં તમે જુઓ અને ઉમેરવો કે નહીં તે નક્કી કરો. પ્રાયોગિક.';

  @override
  String get reportAiPreviewTitle => 'AI એ લખેલો સારાંશ';

  @override
  String get reportAiPreviewBody =>
      'ઉમેરશો તો તે રિપોર્ટમાં અલગ, નામવાળા ભાગમાં દેખાશે — તમારી નોંધો અને તપાસનાં તારણોથી અલગ. તેને બદલી શકાતો નથી.';

  @override
  String get reportAiSummaryTitle => 'સારાંશનો મુસદ્દો';

  @override
  String get reportAiInclude => 'ઉમેરો';

  @override
  String get reportAiSkip => 'છોડો';

  @override
  String unitGb(String value) {
    return '$value GB';
  }

  @override
  String unitMb(String value) {
    return '$value MB';
  }

  @override
  String get pestIdTitle => 'Pest & animal ID';

  @override
  String get pestIdSubtitle =>
      'Look with the camera or listen. The phone finds possible signs; you confirm what is real.';

  @override
  String get pestHomeActionBody =>
      'Check for insects, rats, spiders, lizards and other animals with the camera or by sound';

  @override
  String get pestHeroAction => 'Look or listen';

  @override
  String get pestSegmentGrain => 'Grain sack';

  @override
  String get pestSegmentPest => 'Pest & animal';

  @override
  String get pestCameraCardTitle => 'Look with the camera';

  @override
  String get pestCameraCardBody =>
      'Finds movement, dark specks and eye shine. You confirm what is real.';

  @override
  String get pestListenCardTitle => 'Listen for sounds';

  @override
  String get pestListenCardBody =>
      'Picks up buzzing, scratching and squeaks. You confirm what you heard.';

  @override
  String get pestSightingsCardTitle => 'My sightings';

  @override
  String pestSightingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sightings saved',
      one: '1 sighting saved',
      zero: 'No sightings saved yet',
    );
    return '$_temp0';
  }

  @override
  String get pestOnPhoneNote =>
      'Everything is checked on this phone. Pictures and sounds are never uploaded.';

  @override
  String get pestNotCertainNote =>
      'AI results are estimates and may be wrong. A missed sign is not proof that nothing is there.';

  @override
  String get pestCameraTitle => 'Look for signs';

  @override
  String get pestCameraTip =>
      'Hold the phone still near corners, gaps and grain. Tap a box to confirm it, or capture to see close-ups.';

  @override
  String get pestCameraDenied =>
      'Camera access is off. Allow it in settings to look for signs. Your saved sightings stay available.';

  @override
  String get pestKindMotion => 'Movement';

  @override
  String get pestKindSpecks => 'Dark specks';

  @override
  String get pestKindEyeshine => 'Eye shine';

  @override
  String get pestKindEmbedding => 'Looks similar';

  @override
  String get pestKindModelBox => 'AI box';

  @override
  String get pestKindSound => 'Sound';

  @override
  String pestConfirmBox(String kind) {
    return 'Confirm $kind';
  }

  @override
  String get pestTorch => 'Torch';

  @override
  String pestTorchValue(int percent) {
    return '$percent%';
  }

  @override
  String get pestCapture => 'Capture';

  @override
  String get pestCapturing => 'Capturing…';

  @override
  String get pestNothingHere => 'Not a pest / nothing here';

  @override
  String get pestNothingHereDone =>
      'Nothing saved. The pictures were discarded.';

  @override
  String get pestCandidatesNone =>
      'No possible signs yet. Move slowly or turn on the torch.';

  @override
  String pestCandidatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count possible signs',
      one: '1 possible sign',
    );
    return '$_temp0';
  }

  @override
  String get pestCaptureFailed => 'Could not take a picture. Try again.';

  @override
  String get pestTilesTitle => 'Close-ups: tap the one that is real';

  @override
  String get pestTilesEmpty =>
      'No close-ups in this picture. Try again closer, or with the torch.';

  @override
  String pestTileHint(String name) {
    return 'AI hint: $name (not verified)';
  }

  @override
  String get pestTileConfirm => 'Tap to confirm';

  @override
  String get pestRetake => 'Capture again';

  @override
  String get pestAnalysisTitle => 'AI analysis';

  @override
  String get pestAnalysing => 'Analysing on this phone…';

  @override
  String get pestAiLabel => 'AI label';

  @override
  String get pestAiEstimated => 'AI-estimated';

  @override
  String get pestConfidenceLabel => 'AI-estimated confidence — not calibrated';

  @override
  String pestConfidenceValue(int percent) {
    return '$percent% (the AI\'s own estimate)';
  }

  @override
  String pestAgreement(int agree, int runs) {
    return 'Agreement $agree of $runs runs';
  }

  @override
  String get pestKeyFeatures => 'Key features';

  @override
  String get pestAnomalies => 'Anomalies';

  @override
  String get pestInsights => 'Insights';

  @override
  String get pestNoMatch =>
      'No matching card. This is not proof that nothing is there. Inspect physically.';

  @override
  String get pestNotAPest =>
      'The AI thinks this is not a pest. This is not proof. Inspect physically if unsure.';

  @override
  String pestModelLine(String version, String prompt) {
    return 'Model $version · prompt $prompt — Experimental';
  }

  @override
  String get pestAnalysisUnavailable => 'AI analysis unavailable';

  @override
  String get pestAnalysisUnavailableBody =>
      'The on-phone AI could not analyse this. Showing the closest knowledge card instead.';

  @override
  String get pestNoCardFound =>
      'No matching knowledge card. Inspect physically and ask a professional if unsure.';

  @override
  String get pestSafetyVenomousTitle => 'Venomous — keep your distance';

  @override
  String get pestSafetyMedicalTitle => 'Health risk — keep your distance';

  @override
  String get pestSafetyDistanceBody =>
      'Do not touch or handle it. Get medical care for any bite or sting. Do not use home remedies.';

  @override
  String get pestSafetyProtectedTitle => 'Protected wildlife — do not harm it';

  @override
  String get pestSafetyProtectedBody =>
      'Do not harm, capture or kill it. Call the State Forest Department or a licensed wildlife rescuer.';

  @override
  String get pestSafetyCautionTitle => 'Take care';

  @override
  String get pestSafetyCautionBody =>
      'Do not touch it with bare hands. Follow the safe steps on the card.';

  @override
  String get pestCardTitle => 'Knowledge card';

  @override
  String get pestCardYourPick => 'Your pick';

  @override
  String get pestCardNeedsReview => 'Needs expert review';

  @override
  String pestCardOtherNames(String names) {
    return 'Also called: $names';
  }

  @override
  String get pestCardSigns => 'Signs to look for';

  @override
  String get pestCardHealthRisks => 'Health risks';

  @override
  String get pestCardSafeSteps => 'Safe steps';

  @override
  String get pestCardCallPro => 'Call a professional when';

  @override
  String get pestCardFirstAid => 'First aid';

  @override
  String get pestCardLookAlikes => 'Look-alikes';

  @override
  String get pestCardLegal => 'Legal status';

  @override
  String get pestCardSources => 'Sources';

  @override
  String get pestExplain => 'Explain';

  @override
  String get pestExplainTitle => 'Explanation from the card';

  @override
  String get pestExplainFallback =>
      'No explanation right now. The card above is the guidance.';

  @override
  String get pestPickCard => 'Pick a different card';

  @override
  String get pestPickCardTitle => 'Which one is it?';

  @override
  String get pestPickCardBody =>
      'Your pick is saved as your correction. The AI analysis is kept as it was.';

  @override
  String get pestPickCardClear => 'Use the AI label';

  @override
  String get pestMeasure => 'Measure distance';

  @override
  String get pestMeasuring => 'Measuring…';

  @override
  String pestDistanceValue(
    String meters,
    String low,
    String high,
    String method,
  ) {
    return 'About $meters m away ($low–$high m), by $method';
  }

  @override
  String get pestDistanceMethodDepth => 'depth sensing';

  @override
  String get pestDistanceMethodFocus => 'camera focus';

  @override
  String get pestDistanceUnavailable => 'Distance not available';

  @override
  String pestDistanceReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get pestDistanceNoReason => 'The phone could not measure it reliably.';

  @override
  String get pestSave => 'Save sighting';

  @override
  String get pestDiscard => 'Discard';

  @override
  String get pestStartAgain => 'Start again';

  @override
  String get pestNoSignal =>
      'Nothing to analyse. Start again with the camera or listen mode.';

  @override
  String get pestGroupInsect => 'Insect';

  @override
  String get pestGroupArachnid => 'Spider or scorpion';

  @override
  String get pestGroupRodent => 'Rat or mouse';

  @override
  String get pestGroupReptile => 'Reptile';

  @override
  String get pestGroupOther => 'Other animal';

  @override
  String get pestGroupNotAPest => 'Not a pest';

  @override
  String get pestGroupUnknown => 'Unknown';

  @override
  String pestGroupHint(String group) {
    return 'Likely group: $group (AI hint)';
  }

  @override
  String get pestSourceCamera => 'Camera';

  @override
  String get pestSourceMic => 'Sound';

  @override
  String get pestSourceSensor => 'Sensor';

  @override
  String get pestListenTitle => 'Listen for sounds';

  @override
  String get pestListenModeGeneral => 'General';

  @override
  String get pestListenModeMosquito => 'Mosquito close-up';

  @override
  String get pestListenModeNight => 'Night';

  @override
  String get pestListenModeGeneralBody =>
      'Keep the phone still near where you hear the sound.';

  @override
  String get pestListenModeMosquitoBody =>
      'Hold the phone within a hand\'s width of the buzzing.';

  @override
  String get pestListenModeNightBody =>
      'Leave the phone still in the room. A notification shows while it listens, so you can stop it at any time.';

  @override
  String get pestListenStart => 'Start listening';

  @override
  String get pestListenStop => 'Stop';

  @override
  String get pestListening => 'Listening on this phone…';

  @override
  String get pestListenNone => 'No sounds picked up yet.';

  @override
  String get pestListenTapToConfirm =>
      'Tap a sound you also heard to confirm it';

  @override
  String get pestListenMicDenied =>
      'Microphone access is off. Allow it in settings to listen. Your saved sightings stay available.';

  @override
  String get pestListenNightNeedsNotice =>
      'Night mode needs notifications so you can see and stop listening. Allow notifications and try again.';

  @override
  String get pestListenAgain => 'Listen again';

  @override
  String pestSoundAt(String time) {
    return 'Sound at $time';
  }

  @override
  String get pestSoundConfirm => 'Tap to confirm';

  @override
  String pestSoundScore(String label, int percent) {
    return '$label · $percent%';
  }

  @override
  String get pestSoundNoLabels => 'No sound labels.';

  @override
  String get pestSoundRawNote => 'Raw sound-classifier scores, not calibrated';

  @override
  String get pestSoundDescribing => 'Describing the sound on this phone…';

  @override
  String get pestSoundDescription => 'AI description (experimental)';

  @override
  String get pestSoundNoDescription => 'No AI description available.';

  @override
  String pestSoundModel(String version) {
    return 'Sound model $version — Experimental';
  }

  @override
  String get pestSoundCards => 'Matching cards';

  @override
  String get pestSoundNoCards => 'No matching card. Inspect physically.';

  @override
  String get pestClipGone =>
      'That sound clip is no longer available. Listen again.';

  @override
  String get pestSaveTitle => 'Save sighting';

  @override
  String get pestSaveSubtitle => 'Saved only on this phone';

  @override
  String get pestSaveRoom => 'Room or place';

  @override
  String get pestSaveNoRoom => 'No room';

  @override
  String get pestSaveNoRooms =>
      'No rooms or places yet. You can add them in Inventory.';

  @override
  String get pestSaveLocation => 'Save location';

  @override
  String get pestSaveLocationBody =>
      'Optional. Location is asked only now. Indoors, the room is usually more useful.';

  @override
  String get pestLocating => 'Getting location…';

  @override
  String get pestLocationDenied =>
      'Location permission denied, saved room only';

  @override
  String get pestLocationImprecise => 'Location too imprecise, saved room only';

  @override
  String get pestLocationOff =>
      'Location is turned off on this phone, saved room only';

  @override
  String get pestLocationFailed => 'Could not get a location, saved room only';

  @override
  String pestLocationPinned(int meters) {
    return 'Pin saved (within $meters m)';
  }

  @override
  String get pestKeepMedia => 'Keep the picture or clip';

  @override
  String get pestKeepMediaBody =>
      'Off by default. Kept privately on this phone with the sighting, never uploaded.';

  @override
  String get pestNotes => 'Notes';

  @override
  String get pestSaved => 'Sighting saved';

  @override
  String get pestSaveFailed => 'Could not save. Try again.';

  @override
  String get pestSightingsTitle => 'Sightings';

  @override
  String get pestSightingsSubtitle => 'Saved on this phone, newest first';

  @override
  String get pestSightingsEmpty => 'No sightings yet';

  @override
  String get pestSightingsEmptyDetail =>
      'Look or listen for signs and save what you confirm.';

  @override
  String get pestSightingUnnamed => 'Unidentified sighting';

  @override
  String get pestNoFindingYet => 'Not checked by a person yet';

  @override
  String pestFindingChip(String finding) {
    return 'Checked: $finding';
  }

  @override
  String get pestNotFound => 'This sighting is not on this phone.';

  @override
  String get pestDetailTitle => 'Sighting';

  @override
  String get pestDetailAiSection => 'AI analysis';

  @override
  String get pestDetailAiNote =>
      'AI-estimated — not calibrated. Saved as it was and never edited.';

  @override
  String get pestDetailValidation => 'Your confirmation';

  @override
  String get pestDetailConfirmed => 'You confirmed the signal was real';

  @override
  String get pestDetailNotConfirmed => 'Not confirmed';

  @override
  String pestDetailYourPick(String name) {
    return 'Your pick: $name';
  }

  @override
  String get pestDetailVerified => 'Verified finding';

  @override
  String get pestDetailVerifiedBody =>
      'What a person found by checking. Separate from the AI analysis. It can be set once.';

  @override
  String get pestDetailRecordFinding => 'Record finding';

  @override
  String pestDetailConfirmFinding(String finding) {
    return 'Save \"$finding\" as the verified finding? It cannot be changed later.';
  }

  @override
  String get pestDetailPlace => 'Place';

  @override
  String get pestDetailPinLabel => 'Pin';

  @override
  String pestDetailPin(String lat, String lng, int meters) {
    return '$lat, $lng (within $meters m)';
  }

  @override
  String get pestDetailNoPlace => 'No room or pin saved.';

  @override
  String get pestDetailShowMap => 'Show on map';

  @override
  String get pestDetailMediaKept => 'Picture or clip kept on this phone';

  @override
  String pestNextRepeated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pests seen $count times',
      one: 'A pest was seen again',
    );
    return '$_temp0';
  }

  @override
  String pestNextRepeatedOne(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$label: seen $count times',
      one: '$label: seen again',
    );
    return '$_temp0';
  }

  @override
  String get pestNextRepeatedBody =>
      'Check the place and follow the safe steps on the card.';

  @override
  String get pestNextSafety => 'A sighting needs care';

  @override
  String get pestNextSafetyBody =>
      'Read the safety steps on the card before going near it.';

  @override
  String get pestNextAction => 'View sightings';

  @override
  String get mapTitle => 'Sightings map';

  @override
  String get mapCardBody => 'Pins for sightings saved with a precise location';

  @override
  String get mapConsentTitle => 'Use Google Maps?';

  @override
  String get mapConsentBody =>
      'The map and the walking route come from Google. Google receives the map area you look at and the start and end points of a route.';

  @override
  String get mapConsentNever =>
      'Google never receives the animal, your notes, pictures or sounds.';

  @override
  String get mapConsentAllow => 'Allow maps';

  @override
  String get mapConsentDecline => 'Not now';

  @override
  String get mapConsentNeeded =>
      'Maps are off. Nothing is sent until you allow them.';

  @override
  String get mapNotConfigured => 'Maps not configured';

  @override
  String get mapNotConfiguredBody =>
      'This build has no map key. You can still open a pin in the Google Maps app.';

  @override
  String get mapOpenInGoogleMaps => 'Open in Google Maps';

  @override
  String get mapNoPins => 'No sightings with a precise location yet';

  @override
  String get mapNoPinsDetail =>
      'Pins appear for sightings saved with a location within 25 m.';

  @override
  String get mapNoPinsAction => 'View sightings';

  @override
  String mapPinLabel(String date) {
    return 'Sighting $date';
  }

  @override
  String get mapRoute => 'Route from here';

  @override
  String get mapRouting => 'Finding a route…';

  @override
  String mapRouteSummary(String distance, int minutes) {
    return '$distance · about $minutes min';
  }

  @override
  String get mapRouteFailed =>
      'Could not get a route. Check the internet connection and try again.';

  @override
  String get mapRouteNeedsLocation =>
      'Your location is needed for a route. Allow location and try again.';

  @override
  String get mapStartNavigation => 'Start navigation';

  @override
  String get mapNavigationFailed => 'Could not open Google Maps on this phone.';

  @override
  String mapDistanceKm(String km) {
    return '$km km';
  }

  @override
  String mapDistanceM(int meters) {
    return '$meters m';
  }
}

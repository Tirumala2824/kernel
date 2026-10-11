import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/l10n/l10n.dart';

// Intended wording is independent of the generated localization getters.
// Each locale states both the offline scope and the internet exceptions.
const offlineCopy =
    <
      String,
      ({
        String scope,
        String offline,
        String online,
        String privacy,
        String settings,
      })
    >{
      'en': (
        scope: 'Local records and bundled checks work offline; model downloads and online maps need internet.',
        offline: 'Offline.',
        online: 'Online.',
        privacy: 'Audio stays on this phone.',
        settings: 'Kernel keeps audio on this phone.',
      ),
      'hi': (
        scope: 'फ़ोन पर सहेजे रिकॉर्ड और ऐप में शामिल जाँचें ऑफ़लाइन काम करती हैं; मॉडल डाउनलोड और ऑनलाइन नक्शों के लिए इंटरनेट चाहिए।',
        offline: 'ऑफ़लाइन।',
        online: 'ऑनलाइन।',
        privacy: 'ऑडियो इसी फ़ोन पर रहता है।',
        settings: 'Kernel ऑडियो इसी फ़ोन पर रखता है।',
      ),
      'bn': (
        scope: 'ফোনে রাখা রেকর্ড ও অ্যাপের সঙ্গে থাকা পরীক্ষাগুলি অফলাইনে কাজ করে; মডেল ডাউনলোড ও অনলাইন মানচিত্রের জন্য ইন্টারনেট দরকার।',
        offline: 'অফলাইন।',
        online: 'অনলাইন।',
        privacy: 'অডিও এই ফোনেই থাকে।',
        settings: 'Kernel অডিও এই ফোনেই রাখে।',
      ),
      'te': (
        scope: 'ఫోన్‌లోని రికార్డులు, యాప్‌తో వచ్చే తనిఖీలు ఆఫ్‌లైన్‌లో పనిచేస్తాయి; మోడల్ డౌన్‌లోడ్‌లకు, ఆన్‌లైన్ మ్యాప్‌లకు ఇంటర్నెట్ అవసరం.',
        offline: 'ఆఫ్‌లైన్.',
        online: 'ఆన్‌లైన్.',
        privacy: 'ఆడియో ఈ ఫోన్‌లోనే ఉంటుంది.',
        settings: 'Kernel ఆడియోను ఈ ఫోన్‌లోనే ఉంచుతుంది.',
      ),
      'mr': (
        scope: 'फोनवरील नोंदी आणि ॲपसोबतच्या तपासण्या ऑफलाइन काम करतात; मॉडेल डाउनलोड आणि ऑनलाइन नकाशांसाठी इंटरनेट लागते.',
        offline: 'ऑफलाइन.',
        online: 'ऑनलाइन.',
        privacy: 'ऑडिओ याच फोनवर राहतो.',
        settings: 'Kernel ऑडिओ याच फोनवर ठेवते.',
      ),
      'ta': (
        scope: 'போனில் உள்ள பதிவுகளும் செயலியுடன் வரும் சோதனைகளும் இணையமின்றி வேலை செய்யும்; மாதிரிப் பதிவிறக்கங்களுக்கும் இணைய வரைபடங்களுக்கும் இணையம் தேவை.',
        offline: 'இணைய இணைப்பு இல்லை.',
        online: 'இணைய இணைப்பு உள்ளது.',
        privacy: 'ஒலி இந்தப் போனிலேயே இருக்கும்.',
        settings: 'Kernel ஒலியை இந்தப் போனிலேயே வைத்திருக்கும்.',
      ),
      'gu': (
        scope: 'ફોનમાં રાખેલા રેકોર્ડ અને ઍપ સાથે આવતી તપાસો ઑફલાઇન કામ કરે છે; મોડેલ ડાઉનલોડ અને ઑનલાઇન નકશા માટે ઇન્ટરનેટ જોઈએ.',
        offline: 'ઑફલાઇન.',
        online: 'ઑનલાઇન.',
        privacy: 'ઑડિયો આ ફોનમાં જ રહે છે.',
        settings: 'Kernel ઑડિયો આ ફોનમાં જ રાખે છે.',
      ),
      'kn': (
        scope: 'ಫೋನ್‌ನಲ್ಲಿರುವ ದಾಖಲೆಗಳು ಮತ್ತು ಆ್ಯಪ್‌ನೊಂದಿಗೆ ಬರುವ ತಪಾಸಣೆಗಳು ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿ ಕೆಲಸ ಮಾಡುತ್ತವೆ; ಮಾದರಿ ಡೌನ್‌ಲೋಡ್‌ಗಳು ಮತ್ತು ಆನ್‌ಲೈನ್ ನಕ್ಷೆಗಳಿಗೆ ಇಂಟರ್ನೆಟ್ ಬೇಕು.',
        offline: 'ಆಫ್‌ಲೈನ್.',
        online: 'ಆನ್‌ಲೈನ್.',
        privacy: 'ಆಡಿಯೋ ಈ ಫೋನ್‌ನಲ್ಲೇ ಇರುತ್ತದೆ.',
        settings: 'Kernel ಆಡಿಯೋವನ್ನು ಈ ಫೋನ್‌ನಲ್ಲೇ ಇಡುತ್ತದೆ.',
      ),
      'ml': (
        scope: 'ഫോണിലുള്ള രേഖകളും ആപ്പിനൊപ്പം വരുന്ന പരിശോധനകളും ഓഫ്‌ലൈനിൽ പ്രവർത്തിക്കും; മോഡൽ ഡൗൺലോഡുകൾക്കും ഓൺലൈൻ ഭൂപടങ്ങൾക്കും ഇന്റർനെറ്റ് വേണം.',
        offline: 'ഓഫ്‌ലൈൻ.',
        online: 'ഓൺലൈൻ.',
        privacy: 'ഓഡിയോ ഈ ഫോണിൽത്തന്നെ ഇരിക്കും.',
        settings: 'Kernel ഓഡിയോ ഈ ഫോണിൽത്തന്നെ സൂക്ഷിക്കുന്നു.',
      ),
      'or': (
        scope: 'ଫୋନ୍‌ରେ ଥିବା ରେକର୍ଡ ଓ ଆପ୍ ସହିତ ଆସୁଥିବା ଯାଞ୍ଚଗୁଡ଼ିକ ଅଫଲାଇନ୍‌ରେ କାମ କରେ; ମଡେଲ୍ ଡାଉନଲୋଡ୍ ଓ ଅନଲାଇନ୍ ମାନଚିତ୍ର ପାଇଁ ଇଣ୍ଟରନେଟ୍ ଦରକାର।',
        offline: 'ଅଫଲାଇନ୍।',
        online: 'ଅନଲାଇନ୍।',
        privacy: 'ଅଡିଓ ଏହି ଫୋନ୍‌ରେ ହିଁ ରହେ।',
        settings: 'Kernel ଅଡିଓ ଏହି ଫୋନ୍‌ରେ ହିଁ ରଖେ।',
      ),
      'pa': (
        scope: 'ਫ਼ੋਨ ਵਿੱਚ ਰੱਖੇ ਰਿਕਾਰਡ ਅਤੇ ਐਪ ਨਾਲ ਆਉਂਦੀਆਂ ਜਾਂਚਾਂ ਆਫ਼ਲਾਈਨ ਕੰਮ ਕਰਦੀਆਂ ਹਨ; ਮਾਡਲ ਡਾਊਨਲੋਡ ਅਤੇ ਆਨਲਾਈਨ ਨਕਸ਼ਿਆਂ ਲਈ ਇੰਟਰਨੈੱਟ ਚਾਹੀਦਾ ਹੈ।',
        offline: 'ਆਫ਼ਲਾਈਨ।',
        online: 'ਆਨਲਾਈਨ।',
        privacy: 'ਆਡੀਓ ਇਸ ਫ਼ੋਨ ਵਿੱਚ ਹੀ ਰਹਿੰਦਾ ਹੈ।',
        settings: 'Kernel ਆਡੀਓ ਇਸ ਫ਼ੋਨ ਵਿੱਚ ਹੀ ਰੱਖਦਾ ਹੈ।',
      ),
    };

void main() {
  test('offline copy covers every shipped locale', () {
    expect(
      offlineCopy.keys.toSet(),
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
    );
  });

  for (final entry in offlineCopy.entries) {
    final code = entry.key;
    final copy = entry.value;
    final l = lookupAppLocalizations(Locale(code));
    test('$code onboarding names offline scope and internet exceptions', () {
      expect(l.onboardingPrivacy2, '${copy.privacy} ${copy.scope}');
    });
    test('$code offline indicator names internet exceptions', () {
      expect(l.offlineSemantics, '${copy.offline} ${copy.scope}');
    });
    test('$code online indicator does not promise no network is needed', () {
      expect(l.onlineSemantics, '${copy.online} ${copy.scope}');
    });
    test(
      '$code settings footer names offline scope and internet exceptions',
      () {
        expect(l.settingsFooter, '${copy.settings} ${copy.scope}');
      },
    );
  }
}

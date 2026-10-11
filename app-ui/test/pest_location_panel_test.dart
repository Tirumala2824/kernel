import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kernel_app/features/pest_id/pest_location_panel.dart';
import 'package:kernel_app/features/pest_id/pest_platform.dart';
import 'package:kernel_app/l10n/app_localizations.dart';

// Expected intent: a location fix is only staged, never persisted here.
const _readyPins = {
  'en': 'Pin ready to save (within 8 m)',
  'hi': 'पिन सहेजने के लिए तैयार (8 मी. के अंदर)',
  'bn': 'পিন সংরক্ষণের জন্য প্রস্তুত (8 মি.-এর মধ্যে)',
  'te': 'పిన్ సేవ్ చేయడానికి సిద్ధంగా ఉంది (8 మీ. లోపు)',
  'mr': 'पिन जतन करण्यासाठी तयार (8 मी. च्या आत)',
  'ta': 'பின் சேமிக்கத் தயார் (8 மீ.க்குள்)',
  'gu': 'પિન સાચવવા માટે તૈયાર (8 મી.ની અંદર)',
  'kn': 'ಪಿನ್ ಉಳಿಸಲು ಸಿದ್ಧವಾಗಿದೆ (8 ಮೀ. ಒಳಗೆ)',
  'ml': 'പിൻ സേവ് ചെയ്യാൻ തയ്യാറാണ് (8 മീ.-നുള്ളിൽ)',
  'or': 'ପିନ ସଞ୍ଚୟ କରିବାକୁ ପ୍ରସ୍ତୁତ (8 ମି. ଭିତରେ)',
  'pa': 'ਪਿੰਨ ਸੰਭਾਲਣ ਲਈ ਤਿਆਰ (8 ਮੀ. ਦੇ ਅੰਦਰ)',
};

const _unavailable = {
  'en': [
    'Location permission denied. No pin available.',
    'Location too imprecise. No pin available.',
    'Location is turned off on this phone. No pin available.',
    'Could not get a location. No pin available.',
  ],
  'hi': [
    'स्थान की अनुमति नहीं मिली। पिन उपलब्ध नहीं है।',
    'स्थान बहुत अंदाज़न है। पिन उपलब्ध नहीं है।',
    'इस फ़ोन पर स्थान बंद है। पिन उपलब्ध नहीं है।',
    'स्थान नहीं मिल सका। पिन उपलब्ध नहीं है।',
  ],
  'bn': [
    'অবস্থানের অনুমতি পাওয়া যায়নি। পিন পাওয়া যাচ্ছে না।',
    'অবস্থান খুব আন্দাজি। পিন পাওয়া যাচ্ছে না।',
    'এই ফোনে অবস্থান বন্ধ। পিন পাওয়া যাচ্ছে না।',
    'অবস্থান পাওয়া যায়নি। পিন পাওয়া যাচ্ছে না।',
  ],
  'te': [
    'స్థాన అనుమతి లేదు. పిన్ అందుబాటులో లేదు.',
    'స్థానం చాలా అస్పష్టం. పిన్ అందుబాటులో లేదు.',
    'ఈ ఫోన్‌లో స్థానం ఆఫ్‌లో ఉంది. పిన్ అందుబాటులో లేదు.',
    'స్థానం దొరకలేదు. పిన్ అందుబాటులో లేదు.',
  ],
  'mr': [
    'ठिकाणाची परवानगी नाकारली. पिन उपलब्ध नाही.',
    'ठिकाण खूप अंदाजे आहे. पिन उपलब्ध नाही.',
    'या फोनवर ठिकाण बंद आहे. पिन उपलब्ध नाही.',
    'ठिकाण मिळाले नाही. पिन उपलब्ध नाही.',
  ],
  'ta': [
    'இருப்பிட அனுமதி மறுக்கப்பட்டது. பின் கிடைக்கவில்லை.',
    'இருப்பிடம் மிகவும் தோராயமானது. பின் கிடைக்கவில்லை.',
    'இந்தப் போனில் இருப்பிடம் முடக்கப்பட்டுள்ளது. பின் கிடைக்கவில்லை.',
    'இருப்பிடம் கிடைக்கவில்லை. பின் கிடைக்கவில்லை.',
  ],
  'gu': [
    'સ્થાનની પરવાનગી ન મળી. પિન ઉપલબ્ધ નથી.',
    'સ્થાન બહુ અંદાજિત છે. પિન ઉપલબ્ધ નથી.',
    'આ ફોન પર સ્થાન બંધ છે. પિન ઉપલબ્ધ નથી.',
    'સ્થાન મળ્યું નહીં. પિન ઉપલબ્ધ નથી.',
  ],
  'kn': [
    'ಸ್ಥಳ ಅನುಮತಿ ನಿರಾಕರಿಸಲಾಗಿದೆ. ಪಿನ್ ಲಭ್ಯವಿಲ್ಲ.',
    'ಸ್ಥಳ ತುಂಬಾ ಅಂದಾಜಿನದು. ಪಿನ್ ಲಭ್ಯವಿಲ್ಲ.',
    'ಈ ಫೋನ್‌ನಲ್ಲಿ ಸ್ಥಳ ಆಫ್ ಆಗಿದೆ. ಪಿನ್ ಲಭ್ಯವಿಲ್ಲ.',
    'ಸ್ಥಳ ಸಿಗಲಿಲ್ಲ. ಪಿನ್ ಲಭ್ಯವಿಲ್ಲ.',
  ],
  'ml': [
    'സ്ഥാന അനുമതി നിരസിച്ചു. പിൻ ലഭ്യമല്ല.',
    'സ്ഥാനം വളരെ ഏകദേശമാണ്. പിൻ ലഭ്യമല്ല.',
    'ഈ ഫോണിൽ സ്ഥാനം ഓഫാണ്. പിൻ ലഭ്യമല്ല.',
    'സ്ഥാനം കിട്ടിയില്ല. പിൻ ലഭ്യമല്ല.',
  ],
  'or': [
    'ଅବସ୍ଥାନ ଅନୁମତି ମିଳିଲା ନାହିଁ। ପିନ ଉପଲବ୍ଧ ନାହିଁ।',
    'ଅବସ୍ଥାନ ବହୁତ ଅନୁମାନିକ। ପିନ ଉପଲବ୍ଧ ନାହିଁ।',
    'ଏହି ଫୋନରେ ଅବସ୍ଥାନ ବନ୍ଦ ଅଛି। ପିନ ଉପଲବ୍ଧ ନାହିଁ।',
    'ଅବସ୍ଥାନ ମିଳିଲା ନାହିଁ। ପିନ ଉପଲବ୍ଧ ନାହିଁ।',
  ],
  'pa': [
    'ਟਿਕਾਣੇ ਦੀ ਇਜਾਜ਼ਤ ਨਹੀਂ ਮਿਲੀ। ਪਿੰਨ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।',
    'ਟਿਕਾਣਾ ਬਹੁਤ ਅੰਦਾਜ਼ਨ ਹੈ। ਪਿੰਨ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।',
    'ਇਸ ਫ਼ੋਨ ਉੱਤੇ ਟਿਕਾਣਾ ਬੰਦ ਹੈ। ਪਿੰਨ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।',
    'ਟਿਕਾਣਾ ਨਹੀਂ ਮਿਲਿਆ। ਪਿੰਨ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।',
  ],
};

const _unavailableStatuses = [
  LocationFixStatus.denied,
  LocationFixStatus.imprecise,
  LocationFixStatus.serviceOff,
  LocationFixStatus.failed,
];

Future<void> _pumpPanel(WidgetTester tester, Locale locale, LocationFix fix) =>
    tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PestLocationPanel(fix: fix, locating: false, onLocate: () {}),
        ),
      ),
    );

void main() {
  test('location copy covers every shipped locale', () {
    expect(
      _readyPins.keys.toSet(),
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
    );
  });

  for (final locale in AppLocalizations.supportedLocales) {
    for (final (index, status) in _unavailableStatuses.indexed) {
      testWidgets(
        '${locale.languageCode}: ${status.name} has no available pin',
        (tester) async {
          await _pumpPanel(tester, locale, LocationFix(status));
          await tester.pumpAndSettle();

          expect(
            find.text(_unavailable[locale.languageCode]![index]),
            findsOneWidget,
          );
          expect(find.byKey(const Key('pest-pin')), findsNothing);
          expect(
            find.text(lookupAppLocalizations(locale).pestSaved),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('${locale.languageCode}: pin is ready, not saved', (
      tester,
    ) async {
      await _pumpPanel(tester, locale, classifyFix(12.97161, 77.59456, 8));
      await tester.pumpAndSettle();

      expect(find.text(_readyPins[locale.languageCode]!), findsOneWidget);
      expect(find.text('12.97161, 77.59456'), findsOneWidget);
      expect(find.text(lookupAppLocalizations(locale).pestSaved), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

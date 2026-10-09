import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// Localized strings for the current locale (generated from app_*.arb).
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Native names for the languages Kernel plans to support. Only those in
/// [AppLocalizations.supportedLocales] are offered in the picker.
const Map<String, String> nativeLanguageNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'bn': 'বাংলা',
  'te': 'తెలుగు',
  'mr': 'मराठी',
  'ta': 'தமிழ்',
  'gu': 'ગુજરાતી',
  'kn': 'ಕನ್ನಡ',
  'ml': 'മലയാളം',
  'or': 'ଓଡ଼ିଆ',
  'pa': 'ਪੰਜਾਬੀ',
};

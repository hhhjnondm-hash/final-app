import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppLocalization {
  static const List<Locale> supportedLocales = [
    Locale('ar', 'SA'),
    Locale('en', 'US'),
  ];

  static const Locale fallbackLocale = Locale('ar', 'SA');

  static const String assetPath = 'assets/l10n';

  static Future<void> initialize() async {
    await EasyLocalization.ensureInitialized();
  }

  static ThemeData getTheme(BuildContext context) {
    final locale = context.locale;
    
    if (locale.languageCode == 'ar') {
      return ThemeData(
        fontFamily: 'Amiri',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Amiri'),
          bodyMedium: TextStyle(fontFamily: 'Amiri'),
        ),
      );
    }
    
    return ThemeData(
      fontFamily: 'Roboto',
    );
  }

  static bool isRTL(BuildContext context) {
    return context.locale.languageCode == 'ar';
  }

  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return languageCode;
    }
  }
}

// Extension for easy localization
extension LocalizationExtension on BuildContext {
  String localized(String key) {
    return key.tr();
  }
}
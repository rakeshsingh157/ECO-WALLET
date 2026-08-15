import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'en';

  String get locale => _locale;
  bool get isHindi => _locale == 'hi';
  bool get isMarathi => _locale == 'mr';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString('app_locale');
      if (savedLocale != null && (savedLocale == 'en' || savedLocale == 'hi' || savedLocale == 'mr')) {
        _locale = savedLocale;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLocale(String langCode) async {
    if (langCode != _locale && (langCode == 'en' || langCode == 'hi' || langCode == 'mr')) {
      _locale = langCode;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_locale', _locale);
      } catch (_) {}
    }
  }

  String tr(String key) {
    return AppLocalization.translate(key, locale: _locale);
  }
}

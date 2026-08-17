import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'en';

  String get locale => _locale;
  bool get isHindi => _locale == 'hi';
  bool get isMarathi => _locale == 'mr';
  bool get isGujarati => _locale == 'gu';
  bool get isTamil => _locale == 'ta';
  bool get isTelugu => _locale == 'te';

  static const List<String> supportedLocales = ['en', 'hi', 'mr', 'gu', 'ta', 'te'];

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString('app_locale');
      if (savedLocale != null && supportedLocales.contains(savedLocale)) {
        _locale = savedLocale;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLocale(String langCode) async {
    if (langCode != _locale && supportedLocales.contains(langCode)) {
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

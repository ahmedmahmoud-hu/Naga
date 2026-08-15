import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  // اللغة الافتراضية للتطبيق (ممكن تخليها 'ar' لو حابب)
  Locale _locale = const Locale('en'); 

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('app_language') ?? 'en'; 
    _locale = Locale(savedLanguage);
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return; 

    _locale = newLocale;
    notifyListeners(); 

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', newLocale.languageCode);
  }
}
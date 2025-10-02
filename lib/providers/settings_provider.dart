// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  SettingsProvider() {
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Load locale
    final languageCode = prefs.getString('language_code') ?? 'en';
    _locale = Locale(languageCode);
    // Load theme
    final theme = prefs.getString('theme_mode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere((e) => e.toString() == 'ThemeMode.$theme');
    notifyListeners();
  }

  void setLocale(Locale newLocale) async {
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
    notifyListeners();
  }

  void setThemeMode(ThemeMode newThemeMode) async {
    _themeMode = newThemeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', newThemeMode.name);
    notifyListeners();
  }
}


// lib/providers/locale_provider.dart
/*import 'package:flutter/material.dart';
import 'package:medicine_reminder_app/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  // --- Singleton Setup ---
  LocaleProvider._privateConstructor() {
    _loadLocale();
  }
  static final LocaleProvider instance = LocaleProvider._privateConstructor();
  // --- End Singleton Setup ---

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    _locale = Locale(languageCode);
    ApiService.instance.setCurrentLocale(_locale);
    notifyListeners();
  }

  void setLocale(Locale newLocale) async {
    _locale = newLocale;
    ApiService.instance.setCurrentLocale(newLocale);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
    notifyListeners();
  }
}*/
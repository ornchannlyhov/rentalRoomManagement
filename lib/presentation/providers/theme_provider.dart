import 'package:flutter/material.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';

class ThemeProvider with ChangeNotifier {
  static const String localeKey = 'locale';
  static const String _themeKey = 'theme';
  final ApiHelper _apiHelper = ApiHelper.instance;

  // Default theme is now light.
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en', '');
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _loadTheme();
    await _loadLocale();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    try {
      // Defaults to 'light' if the value is null or 'system'.
      final themeValue =
          await _apiHelper.storage.read(key: _themeKey) ?? 'light';
      _themeMode = themeValue == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('❌ Error loading theme: $e');
    }
  }

  Future<void> _loadLocale() async {
    try {
      final localeValue = await _apiHelper.storage.read(key: localeKey) ?? 'en';
      _locale = Locale(localeValue, '');
      debugPrint('🌍 Locale loaded from storage: ${_locale.languageCode}');
    } catch (e) {
      debugPrint('❌ Error loading locale: $e');
    }
  }

  /// Toggles the theme between light and dark mode.
  Future<void> toggleTheme() async {
    try {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      await _apiHelper.storage.write(
        key: _themeKey,
        value: _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
      debugPrint('🎨 Theme toggled to: $_themeMode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error toggling theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // This function can still be used to set a theme directly,
    // but we ensure it only accepts light or dark.
    if (mode == ThemeMode.system) {
      _themeMode = ThemeMode.light; // Default to light if system is passed
    } else {
      _themeMode = mode;
    }

    try {
      await _apiHelper.storage.write(
        key: _themeKey,
        value: _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
      debugPrint('🎨 Theme set to: $_themeMode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error setting theme: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      debugPrint(
          '🌍 Setting locale from ${_locale.languageCode} to ${locale.languageCode}');
      _locale = locale;
      await _apiHelper.storage
          .write(key: localeKey, value: locale.languageCode);
      debugPrint('✅ Locale saved: ${locale.languageCode}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error setting locale: $e');
    }
  }

}

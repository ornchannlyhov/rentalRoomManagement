import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';

class ThemeProvider with ChangeNotifier {
  static const String localeKey = 'locale';
  static const String _themeKey = 'theme';
  final ApiHelper _apiHelper = ApiHelper.instance;


  ThemeMode _themeMode = ThemeMode.system;
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
      final themeValue = await _apiHelper.storage.read(key: _themeKey) ?? 'system';
      _themeMode = themeValue == 'light'
          ? ThemeMode.light
          : themeValue == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
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

  Future<void> toggleTheme() async {
    try {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : _themeMode == ThemeMode.dark
              ? ThemeMode.system
              : ThemeMode.light;
      await _apiHelper.storage.write(
        key: _themeKey,
        value: _themeMode == ThemeMode.light
            ? 'light'
            : _themeMode == ThemeMode.dark
                ? 'dark'
                : 'system',
      );
      debugPrint('🎨 Theme toggled to: $_themeMode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error toggling theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      await _apiHelper.storage.write(
        key: _themeKey,
        value: mode == ThemeMode.light
            ? 'light'
            : mode == ThemeMode.dark
                ? 'dark'
                : 'system',
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
      await _apiHelper.storage.write(key: localeKey, value: locale.languageCode);
      debugPrint('✅ Locale saved: ${locale.languageCode}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error setting locale: $e');
    }
  }

  Future<void> syncWithSystemTheme() async {
    try {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _themeMode =
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
      await _apiHelper.storage.write(
        key: _themeKey,
        value: _themeMode == ThemeMode.light ? 'light' : 'dark',
      );
      debugPrint('🎨 Theme synced with system: $_themeMode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error syncing with system theme: $e');
    }
  }
}

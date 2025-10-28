import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  static const String localeKey = 'locale';
  static const String _themeKey = 'theme';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
      final themeValue = await _storage.read(key: _themeKey) ?? 'system';
      _themeMode = themeValue == 'light'
          ? ThemeMode.light
          : themeValue == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
  
    } catch (e) {
      print('❌ Error loading theme: $e');
    }
  }

  Future<void> _loadLocale() async {
    try {
      final localeValue = await _storage.read(key: localeKey) ?? 'en';
      _locale = Locale(localeValue, '');
      print('🌍 Locale loaded from storage: ${_locale.languageCode}');
    } catch (e) {
      print('❌ Error loading locale: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : _themeMode == ThemeMode.dark
              ? ThemeMode.system
              : ThemeMode.light;
      await _storage.write(
        key: _themeKey,
        value: _themeMode == ThemeMode.light
            ? 'light'
            : _themeMode == ThemeMode.dark
                ? 'dark'
                : 'system',
      );
      print('🎨 Theme toggled to: $_themeMode');
      notifyListeners();
    } catch (e) {
      print('❌ Error toggling theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      await _storage.write(
        key: _themeKey,
        value: mode == ThemeMode.light
            ? 'light'
            : mode == ThemeMode.dark
                ? 'dark'
                : 'system',
      );
      print('🎨 Theme set to: $_themeMode');
      notifyListeners();
    } catch (e) {
      print('❌ Error setting theme: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      print('🌍 Setting locale from ${_locale.languageCode} to ${locale.languageCode}');
      _locale = locale;
      await _storage.write(key: localeKey, value: locale.languageCode);
      print('✅ Locale saved: ${locale.languageCode}');
      notifyListeners(); 
    } catch (e) {
      print('❌ Error setting locale: $e');
    }
  }

  Future<void> syncWithSystemTheme() async {
    try {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _themeMode = brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
      await _storage.write(
        key: _themeKey,
        value: _themeMode == ThemeMode.light ? 'light' : 'dark',
      );
      print('🎨 Theme synced with system: $_themeMode');
      notifyListeners();
    } catch (e) {
      print('❌ Error syncing with system theme: $e');
    }
  }
}

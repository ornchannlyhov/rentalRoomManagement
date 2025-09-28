import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  ThemeMode _themeMode = ThemeMode.system; // default to system

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadTheme() async {
    final themeValue = await _storage.read(key: _themeKey);
    if (themeValue == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeValue == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system; // default to system
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // if system, toggle to dark first
      _themeMode = ThemeMode.dark;
    }
    await _storage.write(
      key: _themeKey,
      value: _themeMode == ThemeMode.light
          ? 'light'
          : _themeMode == ThemeMode.dark
              ? 'dark'
              : 'system',
    );
    notifyListeners();
  }
}

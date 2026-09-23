// ============================================================
// lib/providers/settings_provider.dart
// ============================================================
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/local_storage.dart';

class SettingsProvider extends ChangeNotifier {
  late AppThemeType _themeType;
  late bool _soundEnabled;
  late AppThemeData _themeData;

  SettingsProvider() {
    _themeType = LocalStorage.getTheme();
    _soundEnabled = LocalStorage.getSoundEnabled();
    _themeData = AppThemes.getTheme(_themeType);
  }

  AppThemeType get themeType => _themeType;
  AppThemeData get themeData => _themeData;
  AppColors get colors => _themeData.colors;
  ThemeData get materialTheme => _themeData.materialTheme;
  bool get soundEnabled => _soundEnabled;

  Future<void> setTheme(AppThemeType type) async {
    _themeType = type;
    _themeData = AppThemes.getTheme(type);
    await LocalStorage.saveTheme(type);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool v) async {
    _soundEnabled = v;
    await LocalStorage.saveSoundEnabled(v);
    notifyListeners();
  }
}

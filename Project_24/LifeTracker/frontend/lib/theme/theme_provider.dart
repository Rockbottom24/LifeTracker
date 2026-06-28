import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._preferences);

  final SharedPreferences _preferences;
  static const String _themeKey = 'app_theme_style';

  AppStyle _style = AppStyle.system;

  AppStyle get style => _style;

  Future<void> load() async {
    final stored = _preferences.getString(_themeKey);
    _style = switch (stored) {
      'classic' => AppStyle.classic,
      'fantasy' => AppStyle.fantasy,
      _ => AppStyle.system,
    };
    notifyListeners();
  }

  Future<void> setStyle(AppStyle style) async {
    _style = style;
    await _preferences.setString(_themeKey, style.name);
    notifyListeners();
  }
}

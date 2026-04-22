import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _darkModeKey = 'dark_mode';
  static const _fontSizeKey = 'font_size';
  static const _showNuanceKey = 'show_nuance';
  static const _showEtymologyKey = 'show_etymology';

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 16.0;
  }

  static Future<void> setFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, value);
  }

  static Future<bool> getShowNuance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showNuanceKey) ?? true;
  }

  static Future<void> setShowNuance(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showNuanceKey, value);
  }

  static Future<bool> getShowEtymology() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showEtymologyKey) ?? true;
  }

  static Future<void> setShowEtymology(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showEtymologyKey, value);
  }
}

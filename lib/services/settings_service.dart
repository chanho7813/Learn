import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _darkModeKey = 'dark_mode';
  static const _fontSizeKey = 'font_size';
  static const _showPronunciationKey = 'show_pronunciation';
  static const _showBriefMeaningKey = 'show_brief_meaning';
  static const _showMeaningKey = 'show_meaning';
  static const _showSynonymsKey = 'show_synonyms';
  static const _showEtymologyKey = 'show_etymology';
  static const _showRelatedWordsKey = 'show_related_words';
  static const _showExampleKey = 'show_example';
  static const _showNuanceKey = 'show_nuance';
  static const _lastDayKey = 'last_day';
  static const _lastScrollOffsetKey = 'last_scroll_offset';
  static const _lastReadingIndexKey = 'last_reading_index';
  static const _lastReadingSectionKey = 'last_reading_section';

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

  static Future<bool> getShowPronunciation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showPronunciationKey) ?? true;
  }

  static Future<void> setShowPronunciation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showPronunciationKey, value);
  }

  static Future<bool> getShowBriefMeaning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showBriefMeaningKey) ?? true;
  }

  static Future<void> setShowBriefMeaning(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showBriefMeaningKey, value);
  }

  static Future<bool> getShowMeaning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showMeaningKey) ?? true;
  }

  static Future<void> setShowMeaning(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showMeaningKey, value);
  }

  static Future<bool> getShowSynonyms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showSynonymsKey) ?? true;
  }

  static Future<void> setShowSynonyms(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showSynonymsKey, value);
  }

  static Future<bool> getShowEtymology() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showEtymologyKey) ?? true;
  }

  static Future<void> setShowEtymology(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showEtymologyKey, value);
  }

  static Future<bool> getShowRelatedWords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showRelatedWordsKey) ?? true;
  }

  static Future<void> setShowRelatedWords(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showRelatedWordsKey, value);
  }

  static Future<bool> getShowExample() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showExampleKey) ?? true;
  }

  static Future<void> setShowExample(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showExampleKey, value);
  }

  static Future<bool> getShowNuance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showNuanceKey) ?? true;
  }

  static Future<void> setShowNuance(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showNuanceKey, value);
  }

  static Future<int> getLastDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastDayKey) ?? 1;
  }

  static Future<void> setLastDay(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastDayKey, value);
  }

  static Future<double> getLastScrollOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lastScrollOffsetKey) ?? 0.0;
  }

  static Future<void> setLastScrollOffset(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastScrollOffsetKey, value);
  }

  static Future<int> getLastReadingIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastReadingIndexKey) ?? 0;
  }

  static Future<void> setLastReadingIndex(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadingIndexKey, value);
  }

  static Future<int> getLastReadingSection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastReadingSectionKey) ?? 0;
  }

  static Future<void> setLastReadingSection(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadingSectionKey, value);
  }
}

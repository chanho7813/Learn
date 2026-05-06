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
  static const _lastEnglishIndexKey = 'last_english_index';
  static const _lastEnglishSectionKey = 'last_english_section';
  static const _lastMathIndexKey = 'last_math_index';
  static const _lastMathSectionKey = 'last_math_section';
  static const _claudeApiKeyKey = 'claude_api_key';
  static const _aiProviderKey = 'ai_provider';
  static const _groqApiKeyKey = 'groq_api_key';
  static const _geminiApiKeyKey = 'gemini_api_key';
  static const _gptApiKeyKey = 'gpt_api_key';

  static String _selectedChoiceKey({
    required String examKind,
    required String examId,
    required int year,
    required int questionNumber,
  }) {
    return 'selected_choice_${examKind}_${examId}_${year}_$questionNumber';
  }

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

  static Future<int> getLastEnglishIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastEnglishIndexKey) ?? 0;
  }

  static Future<void> setLastEnglishIndex(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastEnglishIndexKey, value);
  }

  static Future<int> getLastEnglishSection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastEnglishSectionKey) ?? 0;
  }

  static Future<void> setLastEnglishSection(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastEnglishSectionKey, value);
  }

  static Future<int> getLastMathIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastMathIndexKey) ?? 0;
  }

  static Future<void> setLastMathIndex(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastMathIndexKey, value);
  }

  static Future<int> getLastMathSection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastMathSectionKey) ?? 0;
  }

  static Future<void> setLastMathSection(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastMathSectionKey, value);
  }

  static Future<String?> getSelectedChoice({
    required String examKind,
    required String examId,
    required int year,
    required int questionNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(
      _selectedChoiceKey(
        examKind: examKind,
        examId: examId,
        year: year,
        questionNumber: questionNumber,
      ),
    );
  }

  static Future<void> setSelectedChoice({
    required String examKind,
    required String examId,
    required int year,
    required int questionNumber,
    required String? selectedLabel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _selectedChoiceKey(
      examKind: examKind,
      examId: examId,
      year: year,
      questionNumber: questionNumber,
    );
    if (selectedLabel == null || selectedLabel.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, selectedLabel);
    }
  }

  static Future<String> getClaudeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claudeApiKeyKey) ?? '';
  }

  static Future<void> setClaudeApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claudeApiKeyKey, value);
  }

  static Future<String> getAiProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_aiProviderKey) ?? 'groq';
  }

  static Future<void> setAiProvider(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiProviderKey, value);
  }

  static Future<String> getGroqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_groqApiKeyKey) ?? '';
  }

  static Future<void> setGroqApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groqApiKeyKey, value);
  }

  static Future<String> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKeyKey) ?? '';
  }

  static Future<void> setGeminiApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyKey, value);
  }

  static Future<String> getGptApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_gptApiKeyKey) ?? '';
  }

  static Future<void> setGptApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gptApiKeyKey, value);
  }
}

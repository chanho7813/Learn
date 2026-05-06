import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';

class StorageService {
  static const _key = 'wordup_words';
  static const _migrationKey = 'wordup_hardcoded_cleared';

  static Future<void> clearHardcodedWordsOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;
    await prefs.remove(_key);
    await prefs.setBool(_migrationKey, true);
  }

  static Future<List<Word>> loadWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> jsonList = json.decode(raw);
      return jsonList.map((j) => Word.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveWords(List<Word> words) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = words.map((w) => w.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  static Future<int> addWords(List<Word> newWords) async {
    final existing = await loadWords();
    final existingSet = existing.map((w) => w.word.toLowerCase()).toSet();
    int maxNumber = existing.fold(0, (m, w) => w.number > m ? w.number : m);
    int added = 0;
    for (final w in newWords) {
      if (!existingSet.contains(w.word.toLowerCase())) {
        maxNumber++;
        final numbered = Word(
          number: w.number > 0 ? w.number : maxNumber,
          word: w.word,
          pronunciation: w.pronunciation,
          briefMeaning: w.briefMeaning,
          meaning: w.meaning,
          exampleEn: w.exampleEn,
          exampleKo: w.exampleKo,
          nuances: w.nuances,
          etymology: w.etymology,
          etymologyExplain: w.etymologyExplain,
          relatedWords: w.relatedWords,
        );
        existing.add(numbered);
        existingSet.add(w.word.toLowerCase());
        added++;
      }
    }
    await saveWords(existing);
    return added;
  }

  static Future<void> deleteWord(String word) async {
    final words = await loadWords();
    words.removeWhere((w) => w.word == word);
    await saveWords(words);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static const _customMathKey = 'custom_math_exams';

  static Future<List<String>> getCustomMathExams() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_customMathKey) ?? [];
  }

  static Future<void> addCustomMathExam(String content) async {
    final prefs = await SharedPreferences.getInstance();
    final exams = prefs.getStringList(_customMathKey) ?? [];
    exams.add(content);
    await prefs.setStringList(_customMathKey, exams);
  }

  static Future<void> removeCustomMathExam(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final exams = prefs.getStringList(_customMathKey) ?? [];
    if (index >= 0 && index < exams.length) {
      exams.removeAt(index);
      await prefs.setStringList(_customMathKey, exams);
    }
  }

  static const _customEnglishKey = 'custom_english_exams';

  static Future<List<String>> getCustomEnglishExams() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_customEnglishKey) ?? [];
  }

  static Future<void> addCustomEnglishExam(String content) async {
    final prefs = await SharedPreferences.getInstance();
    final exams = prefs.getStringList(_customEnglishKey) ?? [];
    exams.add(content);
    await prefs.setStringList(_customEnglishKey, exams);
  }

  static Future<void> removeCustomEnglishExam(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final exams = prefs.getStringList(_customEnglishKey) ?? [];
    if (index >= 0 && index < exams.length) {
      exams.removeAt(index);
      await prefs.setStringList(_customEnglishKey, exams);
    }
  }
}

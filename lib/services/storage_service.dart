import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';

class StorageService {
  static const _key = 'wordup_words';
  static const _dataVersionKey = 'wordup_data_version';
  static const _currentDataVersion = 2;

  static Future<bool> needsAssetReload() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_dataVersionKey) ?? 0;
    return stored < _currentDataVersion;
  }

  static Future<void> markDataVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dataVersionKey, _currentDataVersion);
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
}

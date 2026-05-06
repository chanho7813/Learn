List<String> _stringListFromJson(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((item) {
          if (item is Map) {
            final phrase = item['phrase']?.toString().trim() ?? '';
            final meaning = item['meaning']?.toString().trim() ?? '';
            if (phrase.isEmpty) return '';
            return meaning.isEmpty ? phrase : '$phrase - $meaning';
          }
          return item.toString().trim();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const [];
    return trimmed
        .split(RegExp(r'\s*(?:\n|;)\s*'))
        .where((item) => item.trim().isNotEmpty)
        .map((item) => item.trim())
        .toList();
  }
  return const [];
}

class Word {
  final int number;
  final String word;
  final String pronunciation;
  final String briefMeaning;
  final String meaning;
  final String learningFocus;
  final String studyGuide;
  final String exampleEn;
  final String exampleKo;
  final List<NuanceEntry> nuances;
  final String etymology;
  final String etymologyExplain;
  final String wordFamily;
  final List<String> collocations;
  final String relatedWords;

  Word({
    required this.number,
    required this.word,
    this.pronunciation = '',
    required this.briefMeaning,
    required this.meaning,
    this.learningFocus = '',
    this.studyGuide = '',
    required this.exampleEn,
    required this.exampleKo,
    required this.nuances,
    required this.etymology,
    required this.etymologyExplain,
    this.wordFamily = '',
    this.collocations = const [],
    required this.relatedWords,
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'word': word,
    'pronunciation': pronunciation,
    'briefMeaning': briefMeaning,
    'meaning': meaning,
    'learningFocus': learningFocus,
    'studyGuide': studyGuide,
    'exampleEn': exampleEn,
    'exampleKo': exampleKo,
    'nuances': nuances.map((n) => n.toJson()).toList(),
    'etymology': etymology,
    'etymologyExplain': etymologyExplain,
    'wordFamily': wordFamily,
    'collocations': collocations,
    'relatedWords': relatedWords,
  };

  factory Word.fromJson(Map<String, dynamic> json) => Word(
    number: json['number'] ?? 0,
    word: json['word'] ?? '',
    pronunciation: json['pronunciation'] ?? '',
    briefMeaning: json['briefMeaning'] ?? '',
    meaning: json['meaning'] ?? '',
    learningFocus: json['learningFocus'] ?? '',
    studyGuide: json['studyGuide'] ?? '',
    exampleEn: json['exampleEn'] ?? '',
    exampleKo: json['exampleKo'] ?? '',
    nuances: ((json['nuances'] as List?) ?? const [])
        .map((n) => NuanceEntry.fromJson(n))
        .toList(),
    etymology: json['etymology'] ?? '',
    etymologyExplain: json['etymologyExplain'] ?? '',
    wordFamily: json['wordFamily'] ?? '',
    collocations: _stringListFromJson(json['collocations']),
    relatedWords: json['relatedWords'] ?? '',
  );
}

class NuanceEntry {
  final String word;
  final String description;
  final String etymology;

  NuanceEntry({
    required this.word,
    required this.description,
    this.etymology = '',
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'description': description,
    'etymology': etymology,
  };

  factory NuanceEntry.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return NuanceEntry(word: '', description: json.toString());
    }
    return NuanceEntry(
      word: json['word'] ?? '',
      description: json['description'] ?? '',
      etymology: json['etymology'] ?? '',
    );
  }
}

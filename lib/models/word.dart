class Word {
  final int number;
  final String word;
  final String pronunciation;
  final String briefMeaning;
  final String meaning;
  final String exampleEn;
  final String exampleKo;
  final List<NuanceEntry> nuances;
  final String etymology;
  final String etymologyExplain;
  final String relatedWords;

  Word({
    required this.number,
    required this.word,
    this.pronunciation = '',
    required this.briefMeaning,
    required this.meaning,
    required this.exampleEn,
    required this.exampleKo,
    required this.nuances,
    required this.etymology,
    required this.etymologyExplain,
    required this.relatedWords,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'word': word,
        'pronunciation': pronunciation,
        'briefMeaning': briefMeaning,
        'meaning': meaning,
        'exampleEn': exampleEn,
        'exampleKo': exampleKo,
        'nuances': nuances.map((n) => n.toJson()).toList(),
        'etymology': etymology,
        'etymologyExplain': etymologyExplain,
        'relatedWords': relatedWords,
      };

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        number: json['number'],
        word: json['word'],
        pronunciation: json['pronunciation'] ?? '',
        briefMeaning: json['briefMeaning'] ?? '',
        meaning: json['meaning'],
        exampleEn: json['exampleEn'],
        exampleKo: json['exampleKo'],
        nuances: (json['nuances'] as List)
            .map((n) => NuanceEntry.fromJson(n))
            .toList(),
        etymology: json['etymology'],
        etymologyExplain: json['etymologyExplain'] ?? '',
        relatedWords: json['relatedWords'] ?? '',
      );
}

class NuanceEntry {
  final String word;
  final String description;
  final String etymology;

  NuanceEntry({required this.word, required this.description, this.etymology = ''});

  Map<String, dynamic> toJson() => {'word': word, 'description': description, 'etymology': etymology};

  factory NuanceEntry.fromJson(Map<String, dynamic> json) =>
      NuanceEntry(word: json['word'], description: json['description'], etymology: json['etymology'] ?? '');
}

class SentencePair {
  final String en;
  final String ko;

  const SentencePair({required this.en, required this.ko});
}

class ReadingSection {
  final String title;
  final List<SentencePair> sentences;

  const ReadingSection({required this.title, required this.sentences});
}

class ReadingPassage {
  final String title;
  final String fileName;
  final List<ReadingSection> sections;

  const ReadingPassage({
    required this.title,
    required this.fileName,
    required this.sections,
  });

  int get totalSentences =>
      sections.fold(0, (sum, s) => sum + s.sentences.length);
}

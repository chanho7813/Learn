class SolutionConcept {
  final String title;
  final List<String> items;

  const SolutionConcept({required this.title, required this.items});
}

class SolutionVocab {
  final String word;
  final String meaning;

  const SolutionVocab({required this.word, required this.meaning});
}

class QuestionSolution {
  final int number;
  final String answer;
  final String answerText;
  final List<String> explanation;
  final List<SolutionConcept> concepts;
  final List<SolutionVocab> vocab;
  final String status;
  final bool verified;
  final String source;

  const QuestionSolution({
    required this.number,
    required this.answer,
    required this.answerText,
    required this.explanation,
    required this.concepts,
    required this.vocab,
    required this.status,
    required this.verified,
    required this.source,
  });

  bool get hasContent =>
      answer.isNotEmpty ||
      answerText.isNotEmpty ||
      explanation.isNotEmpty ||
      concepts.any(
        (concept) => concept.title.isNotEmpty || concept.items.isNotEmpty,
      ) ||
      vocab.any((item) => item.word.isNotEmpty || item.meaning.isNotEmpty);

  bool get isReady => status == 'verified' && verified && hasContent;
}

class ExamSolution {
  final String institution;
  final String institutionKo;
  final int year;
  final String examKind;
  final int questionCount;
  final Map<int, QuestionSolution> solutionsByNumber;

  const ExamSolution({
    required this.institution,
    required this.institutionKo,
    required this.year,
    required this.examKind,
    required this.questionCount,
    required this.solutionsByNumber,
  });

  QuestionSolution? solutionFor(int number) {
    final solution = solutionsByNumber[number];
    if (solution == null || !solution.isReady) return null;
    return solution;
  }
}

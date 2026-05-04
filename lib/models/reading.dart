class ReadingChoice {
  final String label;
  final String text;

  const ReadingChoice({required this.label, required this.text});
}

class ReadingQuestion {
  final int number;
  final String instruction;
  final List<String> passageSentences;
  final String? question;
  final List<ReadingChoice> choices;

  const ReadingQuestion({
    required this.number,
    required this.instruction,
    required this.passageSentences,
    this.question,
    required this.choices,
  });
}

class ReadingExam {
  final String institution;
  final String institutionKo;
  final int year;
  final String fileName;
  final int questionCount;
  final List<ReadingQuestion> questions;

  const ReadingExam({
    required this.institution,
    required this.institutionKo,
    required this.year,
    required this.fileName,
    required this.questionCount,
    required this.questions,
  });

  String get title => '$institutionKo ${year}학년도 편입 영어';
}

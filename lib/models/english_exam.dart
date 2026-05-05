class EnglishChoice {
  final String label;
  final String text;

  const EnglishChoice({required this.label, required this.text});
}

class EnglishQuestion {
  final int number;
  final String instruction;
  final List<String> passageSentences;
  final String? question;
  final List<EnglishChoice> choices;

  const EnglishQuestion({
    required this.number,
    required this.instruction,
    required this.passageSentences,
    this.question,
    required this.choices,
  });
}

class EnglishExam {
  final String institution;
  final String institutionKo;
  final int year;
  final String fileName;
  final int questionCount;
  final List<EnglishQuestion> questions;

  const EnglishExam({
    required this.institution,
    required this.institutionKo,
    required this.year,
    required this.fileName,
    required this.questionCount,
    required this.questions,
  });

  String get title => '$institutionKo $year학년도 편입 영어';
}

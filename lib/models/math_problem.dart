class MathChoice {
  final String label;
  final String text;

  const MathChoice({required this.label, required this.text});
}

class MathStatement {
  final String label;
  final String text;

  const MathStatement({required this.label, required this.text});
}

class MathQuestion {
  final int number;
  final String points;
  final String stem;
  final List<MathStatement> statementBox;
  final String statementBoxTitle;
  final String stemAfterBox;
  final List<MathChoice> choices;

  const MathQuestion({
    required this.number,
    required this.points,
    required this.stem,
    this.statementBox = const [],
    this.statementBoxTitle = '<보기>',
    this.stemAfterBox = '',
    required this.choices,
  });
}

class MathExam {
  final String university;
  final String universityName;
  final int year;
  final String subject;
  final String subjectName;
  final String fileName;
  final int questionCount;
  final List<MathQuestion> questions;

  const MathExam({
    required this.university,
    required this.universityName,
    required this.year,
    required this.subject,
    required this.subjectName,
    required this.fileName,
    required this.questionCount,
    required this.questions,
  });

  String get title => '$universityName $year학년도 편입$subjectName';
  int get totalProblems => questions.length;
}

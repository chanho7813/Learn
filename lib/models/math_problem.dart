class MathChoice {
  final String label;
  final String text;

  const MathChoice({required this.label, required this.text});
}

class MathQuestion {
  final int number;
  final String points;
  final String stem;
  final List<MathChoice> choices;

  const MathQuestion({
    required this.number,
    required this.points,
    required this.stem,
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

  String get title => '$universityName ${year}학년도 편입$subjectName';
  int get totalProblems => questions.length;
}

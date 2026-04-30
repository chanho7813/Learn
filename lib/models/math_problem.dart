class MathProblem {
  final String question;
  final String choices;
  final String solution;
  final String concepts;
  final String answer;

  const MathProblem({
    required this.question,
    required this.choices,
    required this.solution,
    required this.concepts,
    required this.answer,
  });
}

class MathSection {
  final String title;
  final MathProblem problem;

  const MathSection({required this.title, required this.problem});
}

class MathExam {
  final String title;
  final String fileName;
  final List<MathSection> sections;

  const MathExam({
    required this.title,
    required this.fileName,
    required this.sections,
  });

  int get totalProblems => sections.length;
}

import 'dart:convert';
import '../models/math_problem.dart';

class MathParser {
  static MathExam parseJson(String content, String fileName) {
    final Map<String, dynamic> data = json.decode(content);

    final university = data['university'] as String? ?? '';
    final universityName = data['university_name'] as String? ?? university;
    final year = data['year'] as int? ?? 0;
    final subject = data['subject'] as String? ?? 'math';
    final subjectName = data['subject_name'] as String? ?? '수학';
    final questionCount = data['question_count'] as int? ?? 0;

    final questions = <MathQuestion>[];
    final rawQuestions = data['questions'] as List<dynamic>? ?? [];

    for (final q in rawQuestions) {
      final map = q as Map<String, dynamic>;
      final choices = <MathChoice>[];
      for (final c in (map['choices'] as List<dynamic>? ?? [])) {
        final cMap = c as Map<String, dynamic>;
        choices.add(MathChoice(
          label: cMap['label'] as String? ?? '',
          text: cMap['text'] as String? ?? '',
        ));
      }

      questions.add(MathQuestion(
        number: map['number'] as int? ?? 0,
        points: map['points'] as String? ?? '',
        stem: map['stem'] as String? ?? '',
        choices: choices,
      ));
    }

    return MathExam(
      university: university,
      universityName: universityName,
      year: year,
      subject: subject,
      subjectName: subjectName,
      fileName: fileName,
      questionCount: questionCount,
      questions: questions,
    );
  }
}

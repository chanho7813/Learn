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
        choices.add(
          MathChoice(
            label: cMap['label'] as String? ?? '',
            text: cMap['text'] as String? ?? '',
          ),
        );
      }

      questions.add(
        MathQuestion(
          number: map['number'] as int? ?? 0,
          points: map['points'] as String? ?? '',
          stem: map['stem'] as String? ?? '',
          statementBox: _parseStatementBox(
            map['statement_box'] ?? map['statementBox'],
          ),
          statementBoxTitle: map['statement_box_title'] as String? ?? '<보기>',
          stemAfterBox:
              map['stem_after_box'] as String? ??
              map['stemAfterBox'] as String? ??
              '',
          choices: choices,
        ),
      );
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

  static List<MathStatement> _parseStatementBox(dynamic value) {
    if (value is List) {
      return value
          .map(_parseStatementItem)
          .where((item) => item.text.isNotEmpty || item.label.isNotEmpty)
          .toList();
    }

    if (value is String) {
      return value
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) => MathStatement(label: '', text: line))
          .toList();
    }

    return const [];
  }

  static MathStatement _parseStatementItem(dynamic value) {
    if (value is Map<String, dynamic>) {
      return MathStatement(
        label: value['label'] as String? ?? '',
        text: value['text'] as String? ?? '',
      );
    }

    return MathStatement(label: '', text: value?.toString().trim() ?? '');
  }
}

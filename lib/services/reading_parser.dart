import 'dart:convert';
import '../models/reading.dart';

class ReadingParser {
  static ReadingExam parseJson(String content, String fileName) {
    final Map<String, dynamic> data = json.decode(content);

    final institution = data['institution'] as String? ?? '';
    final institutionKo = data['institution_ko'] as String? ?? institution;
    final year = data['year'] as int? ?? 0;
    final questionCount = data['question_count'] as int? ?? 0;

    final questions = <ReadingQuestion>[];
    final rawQuestions = data['questions'] as List<dynamic>? ?? [];

    for (final q in rawQuestions) {
      final map = q as Map<String, dynamic>;
      final choices = <ReadingChoice>[];
      for (final c in (map['choices'] as List<dynamic>? ?? [])) {
        final cMap = c as Map<String, dynamic>;
        choices.add(ReadingChoice(
          label: cMap['label'] as String? ?? '',
          text: cMap['text'] as String? ?? '',
        ));
      }

      final rawSentences = map['passage_sentences'] as List<dynamic>? ?? [];

      questions.add(ReadingQuestion(
        number: map['number'] as int? ?? 0,
        instruction: map['instruction'] as String? ?? '',
        passageSentences: rawSentences.map((s) => s.toString()).toList(),
        question: map['question'] as String?,
        choices: choices,
      ));
    }

    return ReadingExam(
      institution: institution,
      institutionKo: institutionKo,
      year: year,
      fileName: fileName,
      questionCount: questionCount,
      questions: questions,
    );
  }
}

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

      final splitRegex =
          RegExp(r'(?<=[.!?][\"”’]?)\s+(?=[A-Z])');
      final sentences = <String>[];
      for (final s in rawSentences) {
        final text = s.toString();
        sentences.addAll(
          text.split(splitRegex).where((p) => p.trim().isNotEmpty),
        );
      }

      var instruction = map['instruction'] as String? ?? '';
      var question = map['question'] as String?;

      if (question == null || question.trim().isEmpty) {
        question = instruction;
        instruction = '';
      }

      questions.add(ReadingQuestion(
        number: map['number'] as int? ?? 0,
        instruction: instruction,
        passageSentences: sentences,
        question: question,
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

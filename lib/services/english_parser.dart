import 'dart:convert';
import '../models/english_exam.dart';

class EnglishParser {
  static EnglishExam parseJson(String content, String fileName) {
    final Map<String, dynamic> data = json.decode(content);

    final institution = data['institution'] as String? ?? '';
    final institutionKo = data['institution_ko'] as String? ?? institution;
    final year = data['year'] as int? ?? 0;
    final questionCount = data['question_count'] as int? ?? 0;

    final questions = <EnglishQuestion>[];
    final rawQuestions = data['questions'] as List<dynamic>? ?? [];

    for (final q in rawQuestions) {
      final map = q as Map<String, dynamic>;
      final choices = <EnglishChoice>[];
      for (final c in (map['choices'] as List<dynamic>? ?? [])) {
        final cMap = c as Map<String, dynamic>;
        choices.add(
          EnglishChoice(
            label: cMap['label'] as String? ?? '',
            text: cMap['text'] as String? ?? '',
          ),
        );
      }

      final passageSentences = _parsePassageSentences(map);
      final instruction = map['instruction'] as String? ?? '';
      final question = map['question'] as String?;

      questions.add(
        EnglishQuestion(
          number: map['number'] as int? ?? 0,
          instruction: instruction,
          passageSentences: passageSentences,
          question: question,
          choices: choices,
        ),
      );
    }

    return EnglishExam(
      institution: institution,
      institutionKo: institutionKo,
      year: year,
      fileName: fileName,
      questionCount: questionCount,
      questions: questions,
    );
  }

  static List<String> _parsePassageSentences(Map<String, dynamic> map) {
    final sentences = <String>[];
    final rawSentences = map['passage_sentences'];

    if (rawSentences is List) {
      for (final sentence in rawSentences) {
        final text = _normalizeText(sentence);
        if (text.isNotEmpty) {
          sentences.add(text);
        }
      }
      return sentences;
    }

    final rawParagraphs = map['passage_paragraphs'];
    if (rawParagraphs is List) {
      for (final paragraph in rawParagraphs) {
        final text = _normalizeText(paragraph);
        if (text.isNotEmpty) {
          sentences.add(text);
        }
      }
      return sentences;
    }

    final rawBlocks = map['passage_blocks'];

    if (rawBlocks is List) {
      for (final block in rawBlocks) {
        if (block is Map<String, dynamic>) {
          final label = block['label'] as String? ?? '';
          final text = _normalizeText(block['text']);
          if (text.isNotEmpty) {
            sentences.add(label.isEmpty ? text : '$label $text');
          }
        } else {
          final text = _normalizeText(block);
          if (text.isNotEmpty) {
            sentences.add(text);
          }
        }
      }
      return sentences;
    }

    final passage = _normalizeText(map['passage']);
    if (passage.isNotEmpty) {
      return [passage];
    }

    return sentences;
  }

  static String _normalizeText(dynamic value) {
    if (value == null) return '';
    return value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

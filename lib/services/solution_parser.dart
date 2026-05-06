import 'dart:convert';
import '../models/exam_solution.dart';

class SolutionParser {
  static ExamSolution parseJson(String content) {
    final Map<String, dynamic> data = json.decode(content);
    final rawSolutions = data['solutions'] as List<dynamic>? ?? [];
    final solutionsByNumber = <int, QuestionSolution>{};
    final source = data['source'];
    final defaultStatus = data['status'] as String? ?? '';
    final defaultVerified =
        data['verified'] as bool? ??
        (source is Map<String, dynamic> ? source['verified'] as bool? : null) ??
        false;
    final defaultSource = _parseSourceLabel(source);

    for (final raw in rawSolutions) {
      final map = raw as Map<String, dynamic>;
      final solution = QuestionSolution(
        number: map['number'] as int? ?? 0,
        answer: map['answer'] as String? ?? '',
        answerText:
            map['answer_text'] as String? ?? map['answerText'] as String? ?? '',
        explanation: _parseStringList(map['explanation']),
        concepts: _parseConcepts(map['concepts']),
        vocab: _parseVocab(map['vocab']),
        status: map['status'] as String? ?? defaultStatus,
        verified: map['verified'] as bool? ?? defaultVerified,
        source: _parseSourceLabel(map['source'], fallback: defaultSource),
      );
      if (solution.number > 0) {
        solutionsByNumber[solution.number] = solution;
      }
    }

    return ExamSolution(
      institution: data['institution'] as String? ?? '',
      institutionKo: data['institution_ko'] as String? ?? '',
      year: data['year'] as int? ?? 0,
      examKind: data['exam_kind'] as String? ?? '',
      questionCount: data['question_count'] as int? ?? 0,
      solutionsByNumber: solutionsByNumber,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  static String _parseSourceLabel(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Map<String, dynamic>) {
      final note = value['note']?.toString().trim() ?? '';
      final type = value['type']?.toString().trim() ?? '';
      if (note.isNotEmpty) return note;
      if (type.isNotEmpty) return type;
    }
    return fallback;
  }

  static List<SolutionConcept> _parseConcepts(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) {
          if (item is String) {
            return SolutionConcept(title: item.trim(), items: const []);
          }
          if (item is Map<String, dynamic>) {
            return SolutionConcept(
              title: item['title'] as String? ?? '',
              items: _parseStringList(item['items']),
            );
          }
          return const SolutionConcept(title: '', items: []);
        })
        .where(
          (concept) => concept.title.isNotEmpty || concept.items.isNotEmpty,
        )
        .toList();
  }

  static List<SolutionVocab> _parseVocab(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map<String, dynamic>>()
        .map(
          (map) => SolutionVocab(
            word: map['word'] as String? ?? '',
            meaning: map['meaning'] as String? ?? '',
          ),
        )
        .where((vocab) => vocab.word.isNotEmpty || vocab.meaning.isNotEmpty)
        .toList();
  }
}

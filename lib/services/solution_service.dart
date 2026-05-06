import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show rootBundle;
import '../models/english_problem.dart';
import '../models/exam_solution.dart';
import '../models/math_problem.dart';
import 'solution_parser.dart';

class SolutionService {
  static Future<ExamSolution?> loadEnglishSolution(EnglishExam exam) {
    return _load(
      'assets/solutions/english/${_solutionFileName(exam.fileName)}',
    );
  }

  static Future<ExamSolution?> loadMathSolution(MathExam exam) {
    return _load('assets/solutions/math/${_solutionFileName(exam.fileName)}');
  }

  static String _solutionFileName(String examFileName) {
    final baseName = examFileName.replaceFirst(RegExp(r'\.json$'), '');
    return '${baseName}_solution.json';
  }

  static Future<ExamSolution?> _load(String assetPath) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      return SolutionParser.parseJson(content);
    } on FlutterError {
      return null;
    }
  }
}

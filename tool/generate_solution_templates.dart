import 'dart:convert';
import 'dart:io';

void main() {
  final created = <String>[];
  created.addAll(
    _generateForSubject(
      examDir: Directory('assets/english'),
      solutionDir: Directory('assets/solutions/english'),
      examKind: 'english',
    ),
  );
  created.addAll(
    _generateForSubject(
      examDir: Directory('assets/math'),
      solutionDir: Directory('assets/solutions/math'),
      examKind: 'math',
    ),
  );

  if (created.isEmpty) {
    stdout.writeln('No solution templates created.');
    return;
  }

  stdout.writeln('Created ${created.length} solution templates:');
  for (final path in created) {
    stdout.writeln('- $path');
  }
}

List<String> _generateForSubject({
  required Directory examDir,
  required Directory solutionDir,
  required String examKind,
}) {
  if (!examDir.existsSync()) return const [];
  solutionDir.createSync(recursive: true);

  final created = <String>[];
  final files =
      examDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final baseName = _basenameWithoutExtension(file);
    final target = File('${solutionDir.path}/${baseName}_solution.json');
    if (target.existsSync()) continue;

    final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final questions = data['questions'] as List<dynamic>? ?? [];
    final output = <String, dynamic>{
      'institution': data['institution'] ?? data['university'] ?? '',
      'institution_ko': data['institution_ko'] ?? data['university_name'] ?? '',
      'year': data['year'] ?? 0,
      'exam_kind': examKind,
      'question_count': data['question_count'] ?? questions.length,
      'status': 'pending',
      'verified': false,
      'source': {
        'type': 'manual',
        'verified': false,
        'note': '정답/해설 미입력. 원문 대조 후 verified 처리 필요',
      },
      'schema': _schemaFor(examKind),
      'solutions': [
        for (final rawQuestion in questions)
          _emptySolution(rawQuestion as Map<String, dynamic>, examKind),
      ],
    };

    const encoder = JsonEncoder.withIndent('  ');
    target.writeAsStringSync('${encoder.convert(output)}\n');
    created.add(target.path);
  }

  return created;
}

Map<String, dynamic> _schemaFor(String examKind) {
  final schema = <String, dynamic>{
    'number': '문제 번호',
    'status': 'pending 또는 verified',
    'verified': '검증 완료 여부',
    'source': '검증 근거',
    'answer': '정답 번호',
    'answer_text': '정답 선택지 내용',
    'explanation': '해설 문단 배열',
    'concepts': '문제 풀이에 필요한 개념/유형',
  };
  if (examKind == 'english') {
    schema['vocab'] = '영어 문제용 핵심 어휘';
  }
  return schema;
}

Map<String, dynamic> _emptySolution(
  Map<String, dynamic> question,
  String examKind,
) {
  final solution = <String, dynamic>{
    'number': question['number'] ?? 0,
    'status': 'pending',
    'verified': false,
    'source': '',
    'answer': '',
    'answer_text': '',
    'explanation': <String>[],
    'concepts': <Map<String, dynamic>>[],
  };
  if (examKind == 'english') {
    solution['vocab'] = <Map<String, dynamic>>[];
  }
  return solution;
}

String _basenameWithoutExtension(File file) {
  final name = file.uri.pathSegments.last;
  return name.replaceFirst(RegExp(r'\.json$'), '');
}

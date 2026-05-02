import '../models/math_problem.dart';

class MathParser {
  static MathExam parse(String content, String fileName) {
    final lines = content.split('\n');
    String title = '';
    String parsedFileName = '';
    final sections = <MathSection>[];

    bool inFrontmatter = false;
    String currentSectionTitle = '';
    String currentTag = '';
    final tagContents = <String, StringBuffer>{};

    void flushSection() {
      if (currentSectionTitle.isEmpty) return;
      final question = (tagContents['문제']?.toString() ?? '').trim();
      if (question.isEmpty) return;
      sections.add(MathSection(
        title: currentSectionTitle,
        problem: MathProblem(
          question: question,
          choices: (tagContents['보기']?.toString() ?? '').trim(),
          solution: (tagContents['풀이']?.toString() ?? '').trim(),
          concepts: (tagContents['개념']?.toString() ?? '').trim(),
          answer: (tagContents['정답']?.toString() ?? '').trim(),
        ),
      ));
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (line == '---') {
        if (!inFrontmatter && title.isEmpty) {
          inFrontmatter = true;
          continue;
        } else if (inFrontmatter) {
          inFrontmatter = false;
          continue;
        }
      }

      if (inFrontmatter) {
        if (line.startsWith('title:')) {
          title = line.substring(6).trim();
        } else if (line.startsWith('fileName:')) {
          parsedFileName = line.substring(9).trim();
        }
        continue;
      }

      if (line.startsWith('## ')) {
        flushSection();
        currentSectionTitle = line.substring(3).trim();
        currentTag = '';
        tagContents.clear();
        continue;
      }

      if (line.startsWith('[') && line.endsWith(']')) {
        final tag = line.substring(1, line.length - 1);
        if (['문제', '보기', '풀이', '개념', '정답'].contains(tag)) {
          currentTag = tag;
          tagContents[tag] = StringBuffer();
          continue;
        }
      }

      if (currentTag.isNotEmpty) {
        final buf = tagContents[currentTag]!;
        if (buf.isNotEmpty) buf.write('\n');
        buf.write(rawLine.trimRight());
      }
    }

    flushSection();

    return MathExam(
      title: title.isEmpty ? fileName : title,
      fileName: parsedFileName.isNotEmpty ? parsedFileName : fileName,
      sections: sections,
    );
  }
}

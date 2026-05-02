import '../models/reading.dart';

class ReadingParser {
  static ReadingPassage parse(String content, String fileName) {
    final lines = content.split('\n');
    String title = '';
    String parsedFileName = '';
    final sections = <ReadingSection>[];
    String currentSectionTitle = '';
    final currentPairs = <SentencePair>[];

    bool inFrontmatter = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

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
        if (currentSectionTitle.isNotEmpty && currentPairs.isNotEmpty) {
          sections.add(ReadingSection(
            title: currentSectionTitle,
            sentences: List.from(currentPairs),
          ));
          currentPairs.clear();
        }
        currentSectionTitle = line.substring(3).trim();
        continue;
      }

      if (line.isEmpty) continue;

      final nextNonEmpty = _findNextNonEmpty(lines, i + 1);
      if (nextNonEmpty != null && _isKorean(lines[nextNonEmpty].trim())) {
        currentPairs.add(SentencePair(
          en: line,
          ko: lines[nextNonEmpty].trim(),
        ));
        i = nextNonEmpty;
      }
    }

    if (currentSectionTitle.isNotEmpty && currentPairs.isNotEmpty) {
      sections.add(ReadingSection(
        title: currentSectionTitle,
        sentences: List.from(currentPairs),
      ));
    }

    return ReadingPassage(
      title: title.isEmpty ? fileName : title,
      fileName: parsedFileName.isNotEmpty ? parsedFileName : fileName,
      sections: sections,
    );
  }

  static int? _findNextNonEmpty(List<String> lines, int from) {
    for (int i = from; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty) return i;
    }
    return null;
  }

  static bool _isKorean(String text) {
    final koreanRegex = RegExp(r'[가-힯ᄀ-ᇿ㄰-㆏]');
    return koreanRegex.hasMatch(text);
  }
}

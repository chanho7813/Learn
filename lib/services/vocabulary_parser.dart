import '../models/word.dart';

class VocabularyParser {
  static List<Word> parse(String content) {
    final words = <Word>[];
    final lines = content.split('\n');

    final tocEntries = <int, String>{};
    for (final line in lines) {
      final tocMatch = RegExp(r'^\s*(\d{2,3})\.\s+(.+?)\s{2,}(.+)$').firstMatch(line);
      if (tocMatch != null) {
        tocEntries[int.parse(tocMatch.group(1)!)] = tocMatch.group(3)!.trim();
      }
    }

    final wordHeaderPattern = RegExp(r'^#(\d{2,3})\s+(.+)$');

    int i = 0;
    while (i < lines.length) {
      final headerMatch = wordHeaderPattern.firstMatch(lines[i].trim());
      if (headerMatch != null) {
        final number = int.parse(headerMatch.group(1)!);
        final rawText = headerMatch.group(2)!.trim();

        String wordText = rawText;
        String pronunciation = '';
        final pronMatch = RegExp(r'^(.+?)\s*\[(.+?)\]').firstMatch(rawText);
        if (pronMatch != null) {
          wordText = pronMatch.group(1)!.trim();
          pronunciation = pronMatch.group(2)!.trim();
        }

        int blockEnd = i + 1;
        while (blockEnd < lines.length) {
          final nextHeader = wordHeaderPattern.firstMatch(lines[blockEnd].trim());
          if (nextHeader != null) break;
          blockEnd++;
        }

        final block = lines.sublist(i + 1, blockEnd).join('\n');
        final word = _parseWordBlock(
            number, wordText, pronunciation, block, tocEntries[number] ?? '');
        if (word != null) words.add(word);

        i = blockEnd;
      } else {
        i++;
      }
    }

    return words;
  }

  static Word? _parseWordBlock(int number, String wordText,
      String pronunciation, String block, String briefMeaning) {
    final meaning = _extractSection(block, '📌 뜻');
    final exampleSection = _extractSection(block, '💬 예문');
    final nuanceSection = _extractSection(block, '🎨 뉘앙스');
    final etymologySection = _extractSection(block, '🔍 어원');

    String exampleEn = '';
    String exampleKo = '';

    for (final line in exampleSection.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('→')) {
        exampleEn = trimmed.replaceAll(RegExp('["“”„‟]'), '').trim();
      } else if (trimmed.startsWith('→')) {
        exampleKo = trimmed.substring(1).trim();
      }
    }

    final nuances = <NuanceEntry>[];
    for (final line in nuanceSection.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('•')) {
        final parts = trimmed.substring(1).trim();
        final spaceIdx = parts.indexOf(RegExp(r'\s{2,}'));
        if (spaceIdx > 0) {
          nuances.add(NuanceEntry(
            word: parts.substring(0, spaceIdx).trim(),
            description: parts.substring(spaceIdx).trim(),
          ));
        } else {
          final koreanIdx = parts.indexOf(RegExp(r'[가-힯]'));
          if (koreanIdx > 0) {
            nuances.add(NuanceEntry(
              word: parts.substring(0, koreanIdx).trim(),
              description: parts.substring(koreanIdx).trim(),
            ));
          } else {
            nuances.add(NuanceEntry(word: parts, description: ''));
          }
        }
      } else if (trimmed.startsWith('└') && nuances.isNotEmpty) {
        final etymologyText = trimmed.substring(1).trim();
        final last = nuances.removeLast();
        nuances.add(NuanceEntry(
          word: last.word,
          description: last.description,
          etymology: etymologyText,
        ));
      }
    }

    String etymology = '';
    String etymologyExplain = '';
    String relatedWords = '';
    for (final line in etymologySection.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('→')) {
        etymologyExplain =
            trimmed.substring(1).trim().replaceAll('“', '').replaceAll('”', '');
      } else if (trimmed.startsWith('🔗')) {
        relatedWords = trimmed.replaceFirst('🔗', '').trim();
      } else if (trimmed.isNotEmpty && !trimmed.startsWith('━')) {
        if (etymology.isEmpty) {
          etymology = trimmed;
        }
      }
    }

    return Word(
      number: number,
      word: wordText,
      pronunciation: pronunciation,
      briefMeaning: briefMeaning,
      meaning: meaning
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .join(', '),
      exampleEn: exampleEn,
      exampleKo: exampleKo,
      nuances: nuances,
      etymology: etymology,
      etymologyExplain: etymologyExplain,
      relatedWords: relatedWords,
    );
  }

  static String _extractSection(String block, String marker) {
    final idx = block.indexOf(marker);
    if (idx < 0) return '';

    final start = block.indexOf('\n', idx);
    if (start < 0) return '';

    final markers = ['📌', '💬', '🎨', '🔍', '━━'];
    int end = block.length;
    for (final m in markers) {
      if (m ==
          marker.substring(
              0, marker.indexOf(' ') > 0 ? marker.indexOf(' ') : 2)) {
        continue;
      }
      final mIdx = block.indexOf(m, start);
      if (mIdx > 0 && mIdx < end) end = mIdx;
    }

    return block.substring(start, end).trim();
  }
}

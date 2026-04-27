import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reading.dart';
import '../services/settings_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import 'word_detail_screen.dart';

String _cleanWord(String raw) {
  var cleaned = raw.replaceFirst(RegExp(r'^[^a-zA-Z]+'), '');
  cleaned = cleaned.replaceFirst(RegExp(r'[^a-zA-Z]+$'), '');
  return cleaned.toLowerCase();
}

class ReadingDetailScreen extends StatefulWidget {
  final ReadingPassage passage;

  const ReadingDetailScreen({super.key, required this.passage});

  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen> {
  final Set<String> _revealedSentences = {};
  final Set<String> _selectedWords = {};
  bool _showAll = false;
  double _fontSize = 16.0;
  int _currentSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final size = await SettingsService.getFontSize();
    if (mounted) setState(() => _fontSize = size);
  }

  String _sentenceKey(int sectionIndex, int sentenceIndex) =>
      '$sectionIndex-$sentenceIndex';

  void _toggleSentence(int sectionIndex, int sentenceIndex) {
    final key = _sentenceKey(sectionIndex, sentenceIndex);
    setState(() {
      if (_revealedSentences.contains(key)) {
        _revealedSentences.remove(key);
      } else {
        _revealedSentences.add(key);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      _showAll = !_showAll;
      if (_showAll) {
        for (int s = 0; s < widget.passage.sections.length; s++) {
          for (int i = 0;
              i < widget.passage.sections[s].sentences.length;
              i++) {
            _revealedSentences.add(_sentenceKey(s, i));
          }
        }
      } else {
        _revealedSentences.clear();
      }
    });
  }

  void _goToSection(int index) {
    final clamped = index.clamp(0, widget.passage.sections.length - 1);
    if (clamped == _currentSectionIndex) return;
    setState(() {
      _currentSectionIndex = clamped;
      _revealedSentences.clear();
      _showAll = false;
    });
  }

  Future<void> _analyzeWord(String word, String sentence) async {
    if (word.isEmpty) return;
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    '$word 분석 중...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final result = await GeminiService.analyzeWord(
        word: word,
        sentence: sentence,
      );
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordDetailScreen(
            word: result,
            onAddToWordbook: (w) async {
              final added = await StorageService.addWords([w]);
              if (added > 0) {
                setState(() => _selectedWords.add(word));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('\'${w.word}\' 단어장에 추가됨')),
                  );
                }
                return true;
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이미 단어장에 있는 단어입니다')),
                  );
                }
                return false;
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _showSelectedWords() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final words = _selectedWords.toList()..sort();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withAlpha(51),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '추가 예정 단어',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${words.length}',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (words.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() => _selectedWords.clear());
                              setSheetState(() {});
                            },
                            child: const Text('초기화'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (words.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            '영어 문장에서 단어를 길게 눌러 추가하세요',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withAlpha(128),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: words.map((word) {
                              return Chip(
                                label: Text(word),
                                deleteIcon:
                                    const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(
                                      () => _selectedWords.remove(word));
                                  setSheetState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: words.join('\n')));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${words.length}개 단어가 클립보드에 복사되었습니다'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('클립보드에 복사'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sections = widget.passage.sections;
    final section = sections[_currentSectionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.passage.title,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          Badge(
            isLabelVisible: _selectedWords.isNotEmpty,
            label: Text('${_selectedWords.length}'),
            child: IconButton(
              onPressed: _showSelectedWords,
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: '추가 예정 단어',
            ),
          ),
          IconButton(
            onPressed: _toggleAll,
            icon: Icon(
              _showAll
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            tooltip: _showAll ? '전체 해석 숨기기' : '전체 해석 보기',
          ),
        ],
      ),
      body: Column(
        children: [
          if (sections.length > 1)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentSectionIndex > 0
                        ? () => _goToSection(_currentSectionIndex - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.surfaceContainerHighest.withAlpha(128),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.tertiaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      section.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _currentSectionIndex < sections.length - 1
                        ? () => _goToSection(_currentSectionIndex + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.surfaceContainerHighest.withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: sections.length > 1
                  ? (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity > 300) {
                        _goToSection(_currentSectionIndex - 1);
                      } else if (velocity < -300) {
                        _goToSection(_currentSectionIndex + 1);
                      }
                    }
                  : null,
              behavior: HitTestBehavior.translucent,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: section.sentences.length,
                itemBuilder: (context, index) {
                  final pair = section.sentences[index];
                  final key = _sentenceKey(_currentSectionIndex, index);
                  final isRevealed = _revealedSentences.contains(key);

                  return _SentenceCard(
                    pair: pair,
                    isRevealed: isRevealed,
                    fontSize: _fontSize,
                    selectedWords: _selectedWords,
                    onTap: () =>
                        _toggleSentence(_currentSectionIndex, index),
                    onWordAnalyze: (word) =>
                        _analyzeWord(word, pair.en),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenceCard extends StatelessWidget {
  final SentencePair pair;
  final bool isRevealed;
  final double fontSize;
  final Set<String> selectedWords;
  final VoidCallback onTap;
  final ValueChanged<String> onWordAnalyze;

  const _SentenceCard({
    required this.pair,
    required this.isRevealed,
    required this.fontSize,
    required this.selectedWords,
    required this.onTap,
    required this.onWordAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isRevealed
                  ? colorScheme.primaryContainer
                      .withAlpha(isDark ? 51 : 38)
                  : Colors.transparent,
              border: Border.all(
                color: isRevealed
                    ? colorScheme.primary.withAlpha(77)
                    : colorScheme.outlineVariant.withAlpha(51),
                width: isRevealed ? 1.0 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  children: _buildWordWidgets(colorScheme),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topLeft,
                  child: isRevealed
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(
                                left: 12, top: 8, bottom: 8, right: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color:
                                      colorScheme.primary.withAlpha(128),
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Text(
                              pair.ko,
                              style: TextStyle(
                                fontSize: fontSize - 1,
                                height: 1.6,
                                color:
                                    colorScheme.onSurface.withAlpha(179),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWordWidgets(ColorScheme colorScheme) {
    final words = pair.en.split(' ');
    return List.generate(words.length, (i) {
      final word = words[i];
      final clean = _cleanWord(word);
      final isSelected = clean.isNotEmpty && selectedWords.contains(clean);
      final display = i < words.length - 1 ? '$word ' : word;

      if (clean.isEmpty) {
        return Text(
          display,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.6,
            color: colorScheme.onSurface,
          ),
        );
      }

      return GestureDetector(
        onLongPress: () => onWordAnalyze(clean),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: colorScheme.primary.withAlpha(38),
                  borderRadius: BorderRadius.circular(3),
                )
              : null,
          child: Text(
            display,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.6,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    });
  }
}

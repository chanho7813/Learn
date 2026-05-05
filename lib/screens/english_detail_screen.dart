import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../models/english_exam.dart';
import '../models/word.dart';
import '../services/settings_service.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

String _cleanWord(String raw) {
  var cleaned = raw.replaceFirst(RegExp(r'^[^a-zA-Z]+'), '');
  cleaned = cleaned.replaceFirst(RegExp(r'[^a-zA-Z]+$'), '');
  return cleaned.toLowerCase();
}

String _stripInlineMarkup(String raw) {
  return raw.replaceAll(RegExp(r'</?u>'), '');
}

class _InlineTextSegment {
  final String text;
  final bool underlined;

  const _InlineTextSegment(this.text, {required this.underlined});
}

class EnglishDetailScreen extends StatefulWidget {
  final EnglishExam exam;

  const EnglishDetailScreen({super.key, required this.exam});

  @override
  State<EnglishDetailScreen> createState() => _EnglishDetailScreenState();
}

class _EnglishDetailScreenState extends State<EnglishDetailScreen> {
  final Set<String> _selectedWords = {};
  final TextEditingController _passageSearchController =
      TextEditingController();
  double _fontSize = 16.0;
  int _currentIndex = 0;
  bool _isSearchingPassage = false;
  String _passageSearch = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _passageSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final size = await SettingsService.getFontSize();
    final section = await SettingsService.getLastEnglishSection();
    if (mounted) {
      setState(() {
        _fontSize = size;
        _currentIndex = section.clamp(0, widget.exam.questions.length - 1);
      });
    }
  }

  void _goTo(int index) {
    final clamped = index.clamp(0, widget.exam.questions.length - 1);
    if (clamped == _currentIndex) return;
    setState(() {
      _currentIndex = clamped;
    });
    SettingsService.setLastEnglishSection(clamped);
  }

  void _togglePassageSearch() {
    setState(() {
      _isSearchingPassage = !_isSearchingPassage;
      if (!_isSearchingPassage) {
        _passageSearch = '';
        _passageSearchController.clear();
      }
    });
  }

  int _passageSearchHitCount(EnglishQuestion question) {
    final query = _passageSearch.trim();
    if (query.isEmpty) return 0;

    final pattern = RegExp(RegExp.escape(query), caseSensitive: false);
    return question.passageSentences.fold<int>(
      0,
      (count, sentence) =>
          count + pattern.allMatches(_stripInlineMarkup(sentence)).length,
    );
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
      final result = await AiService.analyzeWord(
        word: word,
        sentence: sentence,
      );
      if (!mounted) return;
      Navigator.pop(context);
      _showWordAnalysisSheet(result);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showWordAnalysisSheet(Word result) {
    bool added = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            final cs = theme.colorScheme;
            return DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withAlpha(51),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.word,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                if (result.pronunciation.isNotEmpty)
                                  Text(
                                    result.pronunciation,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurface.withAlpha(153),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: added
                                ? null
                                : () async {
                                    final count = await StorageService.addWords(
                                      [result],
                                    );
                                    if (count > 0) {
                                      setState(
                                        () => _selectedWords.add(
                                          result.word.toLowerCase(),
                                        ),
                                      );
                                      setSheetState(() => added = true);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '\'${result.word}\' 단어장에 추가됨',
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      setSheetState(() => added = true);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('이미 단어장에 있는 단어입니다'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: Icon(
                              added
                                  ? Icons.bookmark
                                  : Icons.bookmark_add_outlined,
                              color: added ? cs.primary : null,
                              size: 28,
                            ),
                            tooltip: added ? '추가됨' : '단어장에 추가',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.meaning,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      if (result.etymology.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(
                              Icons.history_edu,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '어원',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.etymology,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
                        ),
                        if (result.etymologyExplain.isNotEmpty)
                          Text(
                            '→ ${result.etymologyExplain}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: cs.onSurface.withAlpha(153),
                              height: 1.4,
                            ),
                          ),
                      ],
                      if (result.relatedWords.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '관련어: ${result.relatedWords}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.primary,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (result.exampleEn.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withAlpha(77),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.exampleEn,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                              if (result.exampleKo.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '→ ${result.exampleKo}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withAlpha(153),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
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
    final questions = widget.exam.questions;
    final q = questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            onPressed: _togglePassageSearch,
            icon: Icon(_isSearchingPassage ? Icons.close : Icons.search),
            tooltip: _isSearchingPassage ? '검색 닫기' : '지문 검색',
          ),
          if (_selectedWords.isNotEmpty)
            Badge(
              label: Text('${_selectedWords.length}'),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchingPassage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _passageSearchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() {
                  _passageSearch = value;
                }),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  hintText: '현재 지문에서 검색',
                  helperText: _passageSearch.trim().isEmpty
                      ? null
                      : '${_passageSearchHitCount(q)}개 일치',
                  suffixIcon: _passageSearch.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _passageSearchController.clear();
                            setState(() => _passageSearch = '');
                          },
                          icon: const Icon(Icons.clear),
                          tooltip: '검색어 지우기',
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (questions.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0
                        ? () => _goTo(_currentIndex - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withAlpha(128),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
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
                      '${q.number}번',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _currentIndex < questions.length - 1
                        ? () => _goTo(_currentIndex + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: questions.length > 1
                  ? (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity > 300) _goTo(_currentIndex - 1);
                      if (velocity < -300) _goTo(_currentIndex + 1);
                    }
                  : null,
              behavior: HitTestBehavior.translucent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  if (q.instruction.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          51,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        q.instruction,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withAlpha(179),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (q.passageSentences.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(51),
                          width: 0.5,
                        ),
                      ),
                      child: Wrap(
                        children: _buildPassageWidgets(
                          q.passageSentences,
                          colorScheme,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (q.question != null && q.question!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange.withAlpha(15),
                        border: Border.all(
                          color: Colors.orange.withAlpha(77),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        q.question!,
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (q.choices.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(77),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: q.choices.map((c) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${c.label} ',
                                  style: TextStyle(
                                    fontSize: _fontSize,
                                    height: 1.6,
                                  ),
                                ),
                                ..._buildWordWidgets(c.text, colorScheme),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPassageWidgets(
    List<String> sentences,
    ColorScheme colorScheme,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      if (sentence.isEmpty) continue;
      widgets.addAll(
        _buildWordWidgets(
          sentence,
          colorScheme,
          highlightSearch: true,
          appendTrailingSpace: i < sentences.length - 1,
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildWordWidgets(
    String sentence,
    ColorScheme colorScheme, {
    bool highlightSearch = false,
    bool appendTrailingSpace = false,
  }) {
    final plainSentence = _stripInlineMarkup(sentence);
    final segments = _parseInlineSegments(sentence);
    final query = _passageSearch.trim().toLowerCase();
    final widgets = <Widget>[];

    for (final segment in segments) {
      final matches = RegExp(r'\s+|\S+').allMatches(segment.text);
      for (final match in matches) {
        final token = match.group(0) ?? '';
        if (token.isEmpty) continue;

        if (token.trim().isEmpty) {
          widgets.add(
            Text(
              token,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.6,
                color: colorScheme.onSurface,
              ),
            ),
          );
          continue;
        }

        widgets.add(
          _buildTextToken(
            token,
            plainSentence,
            colorScheme,
            highlightSearch: highlightSearch,
            underlined: segment.underlined,
            query: query,
          ),
        );
      }
    }

    if (appendTrailingSpace) {
      widgets.add(
        Text(
          ' ',
          style: TextStyle(
            fontSize: _fontSize,
            height: 1.6,
            color: colorScheme.onSurface,
          ),
        ),
      );
    }

    return widgets;
  }

  List<_InlineTextSegment> _parseInlineSegments(String sentence) {
    final segments = <_InlineTextSegment>[];
    final pattern = RegExp(r'<u>(.*?)</u>', dotAll: true);
    var index = 0;

    for (final match in pattern.allMatches(sentence)) {
      if (match.start > index) {
        segments.add(
          _InlineTextSegment(
            sentence.substring(index, match.start),
            underlined: false,
          ),
        );
      }
      segments.add(_InlineTextSegment(match.group(1) ?? '', underlined: true));
      index = match.end;
    }

    if (index < sentence.length) {
      segments.add(
        _InlineTextSegment(sentence.substring(index), underlined: false),
      );
    }

    return segments.isEmpty
        ? [_InlineTextSegment(sentence, underlined: false)]
        : segments;
  }

  Widget _buildTextToken(
    String word,
    String sentence,
    ColorScheme colorScheme, {
    required bool highlightSearch,
    required bool underlined,
    required String query,
  }) {
    final clean = _cleanWord(word);
    final isSelected = clean.isNotEmpty && _selectedWords.contains(clean);
    final isSearchHit =
        highlightSearch &&
        query.isNotEmpty &&
        word.toLowerCase().contains(query);

    if (clean.isEmpty) {
      return Text(
        word,
        style: TextStyle(
          fontSize: _fontSize,
          height: 1.6,
          color: colorScheme.onSurface,
          decoration: underlined ? TextDecoration.underline : null,
          decorationThickness: underlined ? 1.2 : null,
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _analyzeWord(clean, sentence),
      child: Container(
        decoration: isSearchHit
            ? BoxDecoration(
                color: Colors.amber.withAlpha(90),
                borderRadius: BorderRadius.circular(3),
              )
            : isSelected
            ? BoxDecoration(
                color: colorScheme.primary.withAlpha(38),
                borderRadius: BorderRadius.circular(3),
              )
            : null,
        child: Text(
          word,
          style: TextStyle(
            fontSize: _fontSize,
            height: 1.6,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            decoration: underlined ? TextDecoration.underline : null,
            decorationThickness: underlined ? 1.2 : null,
          ),
        ),
      ),
    );
  }
}

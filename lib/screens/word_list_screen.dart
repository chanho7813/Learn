import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';

class WordListScreen extends StatefulWidget {
  final List<Word> words;
  const WordListScreen({super.key, required this.words});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> with WidgetsBindingObserver {
  late List<Word> _words;
  int _currentDay = 1;
  String _search = '';
  final Set<int> _expandedWords = {};
  final Set<int> _checkedWords = {};
  bool _showPronunciation = true;
  bool _showBriefMeaning = true;
  bool _showMeaning = true;
  bool _showEtymology = true;
  bool _showRelatedWords = true;
  bool _showExample = true;
  bool _showNuance = true;
  bool _aiLoading = false;
  static const int _wordsPerDay = 25;
  final ScrollController _scrollController = ScrollController();

  static const _accentColors = [
    Color(0xFF0891B2),
    Color(0xFF6366F1),
    Color(0xFFD97706),
    Color(0xFFE11D48),
    Color(0xFF7C3AED),
    Color(0xFF0284C7),
    Color(0xFFDB2777),
    Color(0xFF059669),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _words = List.from(widget.words)
      ..sort((a, b) => a.number.compareTo(b.number));
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _savePosition();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _savePosition();
    }
  }

  Future<void> _savePosition() async {
    await SettingsService.setLastDay(_currentDay);
    if (_scrollController.hasClients) {
      await SettingsService.setLastScrollOffset(_scrollController.offset);
    }
  }

  Future<void> _loadSettings() async {
    final pronunciation = await SettingsService.getShowPronunciation();
    final briefMeaning = await SettingsService.getShowBriefMeaning();
    final meaning = await SettingsService.getShowMeaning();
    final etymology = await SettingsService.getShowEtymology();
    final relatedWords = await SettingsService.getShowRelatedWords();
    final example = await SettingsService.getShowExample();
    final nuance = await SettingsService.getShowNuance();
    final lastDay = await SettingsService.getLastDay();
    final lastOffset = await SettingsService.getLastScrollOffset();
    if (mounted) {
      setState(() {
        _showPronunciation = pronunciation;
        _showBriefMeaning = briefMeaning;
        _showMeaning = meaning;
        _showEtymology = etymology;
        _showRelatedWords = relatedWords;
        _showExample = example;
        _showNuance = nuance;
        _currentDay = lastDay.clamp(1, _totalDays);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && lastOffset > 0) {
          _scrollController.jumpTo(
            lastOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          );
        }
      });
    }
  }

  int get _totalDays => (_words.length / _wordsPerDay).ceil().clamp(1, 9999);

  bool get _isSearching => _search.isNotEmpty;

  void _goToDay(int day) {
    final clamped = day.clamp(1, _totalDays);
    if (clamped == _currentDay) return;
    setState(() {
      _currentDay = clamped;
      _expandedWords.clear();
    });
    SettingsService.setLastDay(_currentDay);
  }

  List<Word> get _displayWords {
    if (_isSearching) {
      final q = _search.toLowerCase();
      return _words
          .where((w) =>
              w.word.toLowerCase().contains(q) ||
              w.meaning.toLowerCase().contains(q) ||
              w.briefMeaning.toLowerCase().contains(q))
          .toList();
    }
    final start = (_currentDay - 1) * _wordsPerDay;
    final end = (start + _wordsPerDay).clamp(0, _words.length);
    if (start >= _words.length) return [];
    return _words.sublist(start, end);
  }

  Future<void> _addWordByAi(String query) async {
    setState(() => _aiLoading = true);
    try {
      final word = await AiService.analyzeWord(word: query.trim(), sentence: '');
      await StorageService.addWords([word]);
      final updated = await StorageService.loadWords();
      if (mounted) {
        setState(() {
          _words = updated..sort((a, b) => a.number.compareTo(b.number));
          _aiLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${word.word}" 단어가 추가되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _aiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('단어 추가 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteWord(Word word) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('단어 삭제'),
        content: Text('"${word.word}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (confirm != true) return;

    await StorageService.deleteWord(word.word);
    setState(() {
      _words.removeWhere((w) => w.word == word.word);
      _expandedWords.remove(word.number);
      if (_currentDay > _totalDays) _currentDay = _totalDays;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayWords = _displayWords;

    return Scaffold(
      appBar: AppBar(
        title: Text('단어 목록 (${_words.length})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: '단어 또는 뜻 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentDay > 1
                        ? () => _goToDay(_currentDay - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.surfaceContainerHighest.withAlpha(128),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                      'Day $_currentDay / $_totalDays',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _currentDay < _totalDays
                        ? () => _goToDay(_currentDay + 1)
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
              onHorizontalDragEnd: _isSearching ? null : (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 300) {
                  _goToDay(_currentDay - 1);
                } else if (velocity < -300) {
                  _goToDay(_currentDay + 1);
                }
              },
              behavior: HitTestBehavior.translucent,
              child: displayWords.isEmpty
                ? Center(
                    child: _isSearching && _search.trim().isNotEmpty
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '검색 결과가 없습니다',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withAlpha(128),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _aiLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(),
                                    )
                                  : FilledButton.icon(
                                      onPressed: () => _addWordByAi(_search),
                                      icon: const Icon(Icons.auto_awesome),
                                      label: Text('"${_search.trim()}" AI로 추가'),
                                    ),
                            ],
                          )
                        : Text(
                            '단어가 없습니다',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withAlpha(128),
                            ),
                          ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: displayWords.length,
                    itemBuilder: (context, index) {
                      final word = displayWords[index];
                      final isExpanded = _expandedWords.contains(word.number);
                      final accent =
                          _accentColors[index % _accentColors.length];

                      final isChecked = _checkedWords.contains(word.number);

                      return _WordCard(
                        word: word,
                        isExpanded: isExpanded,
                        isChecked: isChecked,
                        accentColor: accent,
                        showPronunciation: _showPronunciation,
                        showBriefMeaning: _showBriefMeaning,
                        showMeaning: _showMeaning,
                        showEtymology: _showEtymology,
                        showRelatedWords: _showRelatedWords,
                        showExample: _showExample,
                        showNuance: _showNuance,
                        onCheck: () => setState(() {
                          if (isChecked) {
                            _checkedWords.remove(word.number);
                          } else {
                            _checkedWords.add(word.number);
                          }
                        }),
                        onTap: () => setState(() {
                          if (isExpanded) {
                            _expandedWords.remove(word.number);
                          } else {
                            _expandedWords.add(word.number);
                          }
                        }),
                        onDelete: () => _deleteWord(word),
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

class _WordCard extends StatelessWidget {
  final Word word;
  final bool isExpanded;
  final bool isChecked;
  final Color accentColor;
  final bool showPronunciation;
  final bool showBriefMeaning;
  final bool showMeaning;
  final bool showEtymology;
  final bool showRelatedWords;
  final bool showExample;
  final bool showNuance;
  final VoidCallback onCheck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WordCard({
    required this.word,
    required this.isExpanded,
    required this.isChecked,
    required this.accentColor,
    required this.showPronunciation,
    required this.showBriefMeaning,
    required this.showMeaning,
    required this.showEtymology,
    required this.showRelatedWords,
    required this.showExample,
    required this.showNuance,
    required this.onCheck,
    required this.onTap,
    required this.onDelete,
  });

  bool get _hasExpandableContent =>
      showNuance && word.nuances.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark
              ? colorScheme.surfaceContainerHighest.withAlpha(77)
              : Colors.white,
          border: Border.all(
            color: isExpanded
                ? accentColor.withAlpha(128)
                : colorScheme.outlineVariant.withAlpha(77),
            width: isExpanded ? 1.5 : 0.8,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: accentColor.withAlpha(isExpanded ? 20 : 8),
                blurRadius: isExpanded ? 8 : 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _hasExpandableContent ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: accentColor, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 6, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onCheck,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? accentColor
                                  : accentColor.withAlpha(isDark ? 51 : 30),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            alignment: Alignment.center,
                            child: isChecked
                                ? Icon(Icons.check, size: 16, color: isDark ? Colors.black : Colors.white)
                                : Text(
                                    '${word.number}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    word.word,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (showPronunciation &&
                                      word.pronunciation.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '[${word.pronunciation}]',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withAlpha(128),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (showBriefMeaning && word.briefMeaning.isNotEmpty)
                                Text(
                                  word.briefMeaning,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        colorScheme.onSurface.withAlpha(153),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (_hasExpandableContent)
                          Icon(
                            isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: colorScheme.onSurface.withAlpha(102),
                            size: 20,
                          ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 16,
                              color: colorScheme.error.withAlpha(128)),
                          onPressed: onDelete,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showMeaning &&
                            word.meaning.isNotEmpty &&
                            word.meaning != word.briefMeaning)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              word.meaning,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(height: 1.4, fontSize: 12),
                            ),
                          ),
                        if (showEtymology && word.etymology.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _MiniHeader(
                                    icon: Icons.history_edu,
                                    title: '어원',
                                    color: Color(0xFFD97706)),
                                const SizedBox(height: 3),
                                Text(
                                  word.etymology,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(height: 1.3, fontSize: 10),
                                ),
                                if (word.etymologyExplain.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '→ ${word.etymologyExplain}',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurface
                                          .withAlpha(153),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                                if (showRelatedWords && word.relatedWords.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.link,
                                          size: 11,
                                          color: colorScheme.primary),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          word.relatedWords,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontSize: 10,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (showExample && word.exampleEn.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withAlpha(isDark ? 77 : 51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.exampleEn,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.3,
                                    fontSize: 11,
                                    color:
                                        colorScheme.onSurface.withAlpha(204),
                                  ),
                                ),
                                if (word.exampleKo.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '→ ${word.exampleKo}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withAlpha(153),
                                      height: 1.3,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: isExpanded
                        ? _ExpandedContent(
                            word: word,
                            accentColor: accentColor,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  final Word word;
  final Color accentColor;

  const _ExpandedContent({
    required this.word,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
            height: 1,
            color: accentColor.withAlpha(38),
            indent: 12,
            endIndent: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniHeader(
                  icon: Icons.palette_outlined,
                  title: '뉘앙스 비교',
                  color: colorScheme.tertiary),
              const SizedBox(height: 4),
              ...word.nuances.map((n) {
                final isMain =
                    n.word.toLowerCase() == word.word.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isMain
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              n.word,
                              style: TextStyle(
                                fontWeight:
                                    isMain ? FontWeight.bold : FontWeight.w500,
                                fontSize: 10,
                                color: isMain
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              n.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withAlpha(179),
                                height: 1.3,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (n.etymology.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 1),
                          child: Text(
                            '└ ${n.etymology}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFD97706),
                              fontSize: 9,
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _MiniHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }
}

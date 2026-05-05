import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/word.dart';
import '../services/storage_service.dart';
import '../services/vocabulary_parser.dart';
import 'word_list_screen.dart';
import 'english_list_screen.dart';
import 'math_list_screen.dart';
import 'extract_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Word> _words = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _loading = true);
    if (await StorageService.needsAssetReload()) {
      final words = await _loadFromAssets();
      if (words.isNotEmpty) {
        await StorageService.saveWords(words);
        await StorageService.markDataVersion();
      }
    }
    var words = await StorageService.loadWords();
    if (words.isEmpty) {
      words = await _loadFromAssets();
      if (words.isNotEmpty) {
        await StorageService.saveWords(words);
        await StorageService.markDataVersion();
      }
    }
    setState(() {
      _words = words;
      _loading = false;
    });
  }

  Future<List<Word>> _loadFromAssets() async {
    final allWords = <Word>[];
    for (int i = 1; i <= 5; i++) {
      try {
        final content = await rootBundle.loadString(
            'assets/wordbooks/vocabulary_$i.txt');
        allWords.addAll(VocabularyParser.parse(content));
      } catch (_) {}
    }
    return allWords;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadWords,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'WordUp',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '영어 단어 암기 · 영어 · 수학',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withAlpha(153),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primaryContainer.withAlpha(179),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_words.length}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '저장된 단어',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _MenuButton(
                      icon: Icons.list_alt_rounded,
                      label: '단어 목록 보기',
                      subtitle: _words.isEmpty
                          ? '저장된 단어 없음'
                          : '${_words.length}개 단어 · ${(_words.length / 25).ceil()}일 분량',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WordListScreen(words: _words),
                          ),
                        );
                        _loadWords();
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      icon: Icons.auto_stories_outlined,
                      label: '영어',
                      subtitle: '편입 영어 기출문제',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EnglishListScreen(),
                          ),
                        );
                        _loadWords();
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      icon: Icons.calculate_outlined,
                      label: '수학',
                      subtitle: '편입수학 문제 풀이',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MathListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      icon: Icons.auto_awesome,
                      label: 'AI 시험지 추출',
                      subtitle: '시험지 이미지 → 문제 추출',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExtractScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      icon: Icons.settings_outlined,
                      label: '설정',
                      subtitle: '테마, 글꼴 크기, API 키',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              onThemeChanged: widget.onThemeChanged,
                              onDataCleared: _loadWords,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = onTap != null;

    return Material(
      color: enabled
          ? colorScheme.surfaceContainerHighest.withAlpha(128)
          : colorScheme.surfaceContainerHighest.withAlpha(51),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon,
                  size: 28,
                  color: enabled
                      ? colorScheme.primary
                      : colorScheme.onSurface.withAlpha(77)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: enabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withAlpha(102),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: colorScheme.onSurface.withAlpha(77)),
            ],
          ),
        ),
      ),
    );
  }
}

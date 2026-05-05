import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/english_exam.dart';
import '../services/english_parser.dart';
import '../services/settings_service.dart';
import 'english_detail_screen.dart';

class EnglishListScreen extends StatefulWidget {
  const EnglishListScreen({super.key});

  @override
  State<EnglishListScreen> createState() => _EnglishListScreenState();
}

class _EnglishListScreenState extends State<EnglishListScreen> {
  List<EnglishExam> _exams = [];
  bool _loading = true;
  int _lastEnglishIndex = 0;

  static const _englishFiles = [
    'chungang_2026_english.json',
    'chungang_2025_english.json',
    'chungang_2024_english.json',
    'chungang_2022_english.json',
    'chungang_2021_english.json',
    'chungang_2020_english.json',
    'myongji_2025_english.json',
    'myongji_2024_english.json',
    'myongji_2023_english.json',
    'myongji_2022_english.json',
    'myongji_2021_english.json',
    'myongji_2020_english.json',
    'aerospace_2026_english.json',
    'aerospace_2025_english.json',
    'aerospace_2024_english.json',
    'seoul_2025_english.json',
    'seoul_2024_english.json',
    'seoul_2023_english.json',
  ];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final exams = <EnglishExam>[];
    for (final file in _englishFiles) {
      try {
        final content = await rootBundle.loadString('assets/english/$file');
        exams.add(EnglishParser.parseJson(content, file));
      } catch (_) {}
    }

    final lastIndex = await SettingsService.getLastEnglishIndex();
    if (mounted) {
      setState(() {
        _exams = exams;
        _lastEnglishIndex = exams.isEmpty ? 0 : lastIndex.clamp(0, exams.length - 1);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('영어')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? Center(
                  child: Text(
                    '등록된 시험이 없습니다',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withAlpha(128),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exams.length,
                  itemBuilder: (context, index) {
                    final exam = _exams[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExamCard(
                        exam: exam,
                        isLastRead: index == _lastEnglishIndex,
                        onTap: () async {
                          await SettingsService.setLastEnglishIndex(index);
                          setState(() => _lastEnglishIndex = index);
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EnglishDetailScreen(exam: exam),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final EnglishExam exam;
  final bool isLastRead;
  final VoidCallback onTap;

  const _ExamCard({
    required this.exam,
    this.isLastRead = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? colorScheme.surfaceContainerHighest.withAlpha(77)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 1,
      shadowColor: colorScheme.shadow.withAlpha(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLastRead
                  ? colorScheme.primary.withAlpha(128)
                  : colorScheme.outlineVariant.withAlpha(77),
              width: isLastRead ? 1.5 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLastRead
                      ? colorScheme.primary
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: isLastRead
                      ? colorScheme.onPrimary
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exam.questionCount}문제${isLastRead ? ' · 마지막으로 읽음' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isLastRead
                            ? colorScheme.primary
                            : colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withAlpha(77),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

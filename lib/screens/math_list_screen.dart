import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/math_problem.dart';
import '../services/math_parser.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import 'math_detail_screen.dart';

class MathListScreen extends StatefulWidget {
  const MathListScreen({super.key});

  @override
  State<MathListScreen> createState() => _MathListScreenState();
}

class _MathListScreenState extends State<MathListScreen> {
  List<MathExam> _exams = [];
  bool _loading = true;
  int _lastMathIndex = 0;
  int _assetExamCount = 0;

  static const _mathFiles = [
    'myongji_2023_math.txt',
  ];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final exams = <MathExam>[];
    for (final file in _mathFiles) {
      try {
        final content = await rootBundle.loadString('assets/math/$file');
        exams.add(MathParser.parse(content, file));
      } catch (_) {}
    }
    final assetCount = exams.length;

    final customExams = await StorageService.getCustomMathExams();
    for (int i = 0; i < customExams.length; i++) {
      try {
        final exam = MathParser.parse(customExams[i], 'custom_$i.txt');
        if (exam.sections.isNotEmpty) exams.add(exam);
      } catch (_) {}
    }

    final lastIndex = await SettingsService.getLastMathIndex();
    if (mounted) {
      setState(() {
        _exams = exams;
        _assetExamCount = assetCount;
        _lastMathIndex = exams.isEmpty ? 0 : lastIndex.clamp(0, exams.length - 1);
        _loading = false;
      });
    }
  }

  Future<void> _deleteCustomExam(int examIndex) async {
    final customIndex = examIndex - _assetExamCount;
    if (customIndex < 0) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('시험 삭제'),
        content: Text('${_exams[examIndex].title}을(를) 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('삭제',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await StorageService.removeCustomMathExam(customIndex);
    _loadExams();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('수학')),
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
                    final isCustom = index >= _assetExamCount;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExamCard(
                        exam: exam,
                        isLastRead: index == _lastMathIndex,
                        isCustom: isCustom,
                        onTap: () async {
                          await SettingsService.setLastMathIndex(index);
                          setState(() => _lastMathIndex = index);
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MathDetailScreen(exam: exam),
                            ),
                          );
                        },
                        onLongPress: isCustom ? () => _deleteCustomExam(index) : null,
                      ),
                    );
                  },
                ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final MathExam exam;
  final bool isLastRead;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ExamCard({
    required this.exam,
    this.isLastRead = false,
    this.isCustom = false,
    required this.onTap,
    this.onLongPress,
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
        onLongPress: onLongPress,
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
                  Icons.calculate_outlined,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            exam.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AI',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLastRead
                          ? '${exam.totalProblems}문제 · 마지막으로 봄'
                          : '${exam.totalProblems}문제${isCustom ? ' · 길게 눌러 삭제' : ''}',
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

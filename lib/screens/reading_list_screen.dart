import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/reading.dart';
import '../services/reading_parser.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import 'reading_detail_screen.dart';

class ReadingListScreen extends StatefulWidget {
  const ReadingListScreen({super.key});

  @override
  State<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends State<ReadingListScreen> {
  List<ReadingPassage> _passages = [];
  bool _loading = true;
  int _lastReadingIndex = 0;
  int _assetPassageCount = 0;

  static const _readingFiles = [
    'myongji_2025_06_30.txt',
    'myongji_2024_06_30.txt',
    'myongji_2023_06_15.txt',
    'hongik_2025_01_40.txt',
    'hongik_2024_01_40.txt',
    'hongik_2023_01_40.txt',
    'hongik_2021_01_40.txt',
    'jungang_2024_01_40.txt',
    'jungang_2023_01_40.txt',
    'jungang_2021_01_40.txt',
  ];

  @override
  void initState() {
    super.initState();
    _loadPassages();
  }

  Future<void> _loadPassages() async {
    final passages = <ReadingPassage>[];
    for (final file in _readingFiles) {
      try {
        final content =
            await rootBundle.loadString('assets/readings/$file');
        passages.add(ReadingParser.parse(content, file));
      } catch (_) {}
    }
    final assetCount = passages.length;

    final customExams = await StorageService.getCustomReadingExams();
    for (int i = 0; i < customExams.length; i++) {
      try {
        final passage = ReadingParser.parse(customExams[i], 'custom_$i.txt');
        if (passage.sections.isNotEmpty) passages.add(passage);
      } catch (_) {}
    }

    final lastIndex = await SettingsService.getLastReadingIndex();
    if (mounted) {
      setState(() {
        _passages = passages;
        _assetPassageCount = assetCount;
        _lastReadingIndex = passages.isEmpty ? 0 : lastIndex.clamp(0, passages.length - 1);
        _loading = false;
      });
    }
  }

  Future<void> _deleteCustomPassage(int passageIndex) async {
    final customIndex = passageIndex - _assetPassageCount;
    if (customIndex < 0) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('지문 삭제'),
        content: Text('${_passages[passageIndex].title}을(를) 삭제할까요?'),
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
    await StorageService.removeCustomReadingExam(customIndex);
    _loadPassages();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('리딩')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _passages.isEmpty
              ? Center(
                  child: Text(
                    '등록된 지문이 없습니다',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withAlpha(128),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _passages.length,
                  itemBuilder: (context, index) {
                    final passage = _passages[index];
                    final isCustom = index >= _assetPassageCount;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PassageCard(
                        passage: passage,
                        isLastRead: index == _lastReadingIndex,
                        isCustom: isCustom,
                        onTap: () async {
                          await SettingsService.setLastReadingIndex(index);
                          setState(() => _lastReadingIndex = index);
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReadingDetailScreen(passage: passage),
                            ),
                          );
                        },
                        onLongPress: isCustom ? () => _deleteCustomPassage(index) : null,
                      ),
                    );
                  },
                ),
    );
  }
}

class _PassageCard extends StatelessWidget {
  final ReadingPassage passage;
  final bool isLastRead;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PassageCard({
    required this.passage,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            passage.title,
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
                          ? '${passage.sections.length}개 지문 · ${passage.totalSentences}문장 · 마지막으로 읽음'
                          : '${passage.sections.length}개 지문 · ${passage.totalSentences}문장${isCustom ? ' · 길게 눌러 삭제' : ''}',
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

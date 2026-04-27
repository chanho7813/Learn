import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/reading.dart';
import '../services/reading_parser.dart';
import 'reading_detail_screen.dart';

class ReadingListScreen extends StatefulWidget {
  const ReadingListScreen({super.key});

  @override
  State<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends State<ReadingListScreen> {
  List<ReadingPassage> _passages = [];
  bool _loading = true;

  static const _readingFiles = [
    'myongji_2025_06_30.txt',
    'myongji_2024_06_30.txt',
    'myongji_2023_16_30.txt',
    'myongji_2023_06_15.txt',
    'hongik_2025_29_40.txt',
    'hongik_2024_29_40.txt',
    'hongik_2023_29_40.txt',
    'hongik_2021_29_40.txt',
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
    if (mounted) {
      setState(() {
        _passages = passages;
        _loading = false;
      });
    }
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PassageCard(
                        passage: passage,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReadingDetailScreen(passage: passage),
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

class _PassageCard extends StatelessWidget {
  final ReadingPassage passage;
  final VoidCallback onTap;

  const _PassageCard({required this.passage, required this.onTap});

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
              color: colorScheme.outlineVariant.withAlpha(77),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passage.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${passage.sections.length}개 지문 · ${passage.totalSentences}문장',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(128),
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

import 'package:flutter/material.dart';
import '../models/word.dart';

class WordDetailScreen extends StatelessWidget {
  final Word word;
  const WordDetailScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(word.word),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            word.word,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '#${word.number.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          _SectionCard(
            icon: Icons.translate,
            title: '뜻',
            color: colorScheme.primary,
            child: Text(
              word.meaning,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
          ),

          if (word.exampleEn.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.format_quote,
              title: '예문',
              color: colorScheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.exampleEn,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  if (word.exampleKo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '→ ${word.exampleKo}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (word.nuances.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.palette_outlined,
              title: '뉘앙스 비교',
              color: colorScheme.tertiary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: word.nuances.map((n) {
                  final isMain = n.word.toLowerCase() == word.word.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isMain
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            n.word,
                            style: TextStyle(
                              fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                              color: isMain
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              n.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withAlpha(179),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          if (word.etymology.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.history_edu,
              title: '어원',
              color: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.etymology, style: theme.textTheme.bodyMedium),
                  if (word.etymologyExplain.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '→ ${word.etymologyExplain}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                  if (word.relatedWords.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(128),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              word.relatedWords,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

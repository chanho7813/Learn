import 'package:flutter/material.dart';

import '../models/word.dart';

class WordStudySection extends StatelessWidget {
  final Word word;
  final bool compact;
  final bool showRelatedWords;

  const WordStudySection({
    super.key,
    required this.word,
    this.compact = false,
    this.showRelatedWords = true,
  });

  static bool hasStudyContent(Word word, {bool showRelatedWords = true}) =>
      word.learningFocus.isNotEmpty ||
      word.studyGuide.isNotEmpty ||
      word.etymology.isNotEmpty ||
      word.etymologyExplain.isNotEmpty ||
      word.wordFamily.isNotEmpty ||
      word.collocations.isNotEmpty ||
      (showRelatedWords && word.relatedWords.isNotEmpty);

  bool get _hasStrategy =>
      word.learningFocus.isNotEmpty || word.studyGuide.isNotEmpty;

  bool get _hasEtymology =>
      word.etymology.isNotEmpty || word.etymologyExplain.isNotEmpty;

  bool get _hasFamily => word.wordFamily.isNotEmpty;

  bool get _hasCollocations => word.collocations.isNotEmpty;

  bool get _hasRelated => showRelatedWords && word.relatedWords.isNotEmpty;

  bool get hasContent =>
      _hasStrategy ||
      _hasEtymology ||
      _hasFamily ||
      _hasCollocations ||
      _hasRelated;

  @override
  Widget build(BuildContext context) {
    if (!hasContent) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacing = compact ? 10.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasStrategy) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(102),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primary.withAlpha(51)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_outlined, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      word.learningFocus.isEmpty ? '학습 전략' : word.learningFocus,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (word.studyGuide.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    word.studyGuide,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: spacing),
        ],
        if (_hasEtymology) ...[
          _StudyHeader(
            icon: Icons.history_edu,
            title: '어원 구조',
            color: Colors.orange,
            compact: compact,
          ),
          if (word.etymology.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              word.etymology,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ],
          if (word.etymologyExplain.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '뜻 연결: ${word.etymologyExplain}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withAlpha(153),
                height: 1.45,
                fontSize: compact ? 11 : null,
              ),
            ),
          ],
          SizedBox(height: spacing),
        ],
        if (_hasFamily) ...[
          _StudyHeader(
            icon: Icons.account_tree_outlined,
            title: '같은 어근/친척 단어',
            color: cs.tertiary,
            compact: compact,
          ),
          const SizedBox(height: 4),
          Text(
            word.wordFamily,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          SizedBox(height: spacing),
        ],
        if (_hasCollocations) ...[
          _StudyHeader(
            icon: Icons.hub_outlined,
            title: '자주 붙는 표현',
            color: cs.secondary,
            compact: compact,
          ),
          const SizedBox(height: 5),
          ...word.collocations.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing),
        ],
        if (_hasRelated) ...[
          _StudyHeader(
            icon: Icons.link,
            title: '관련어',
            color: cs.primary,
            compact: compact,
          ),
          const SizedBox(height: 4),
          Text(
            word.relatedWords,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.primary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _StudyHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool compact;

  const _StudyHeader({
    required this.icon,
    required this.title,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: compact ? 15 : 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

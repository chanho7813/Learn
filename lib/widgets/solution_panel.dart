import 'package:flutter/material.dart';
import '../models/exam_solution.dart';
import 'math_tex.dart';

class SolutionRevealButton extends StatelessWidget {
  final bool isRevealed;
  final VoidCallback onTap;

  const SolutionRevealButton({
    super.key,
    required this.isRevealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRevealed
                    ? Icons.visibility_off_outlined
                    : Icons.check_circle_outline,
                size: 20,
                color: isRevealed
                    ? colorScheme.onSurface.withAlpha(128)
                    : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isRevealed ? '해답 숨기기' : '정답/해설 보기',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isRevealed
                      ? colorScheme.onSurface.withAlpha(128)
                      : colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SolutionPanel extends StatelessWidget {
  final QuestionSolution? solution;
  final bool renderMath;
  final double fontSize;

  const SolutionPanel({
    super.key,
    required this.solution,
    required this.renderMath,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = solution;

    if (item == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: _decoration(colorScheme),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              '해답 준비 중',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: _decoration(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '정답 ${item.answer}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (item.answerText.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(child: _contentText(item.answerText, colorScheme)),
              ],
            ],
          ),
          if (item.source.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '검증: ${item.source}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (item.explanation.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '해설',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < item.explanation.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == item.explanation.length - 1 ? 0 : 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ',
                      style: TextStyle(
                        fontSize: fontSize - 1,
                        height: 1.6,
                        color: colorScheme.onSurface.withAlpha(153),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: _contentText(item.explanation[i], colorScheme),
                    ),
                  ],
                ),
              ),
          ],
          if (item.concepts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '개념',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final concept in item.concepts) ...[
                  if (concept.title.isNotEmpty)
                    _ConceptChip(label: concept.title),
                  for (final conceptItem in concept.items)
                    _ConceptChip(label: conceptItem),
                ],
              ],
            ),
          ],
          if (item.vocab.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '어휘',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            for (final vocab in item.vocab)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${vocab.word}: ${vocab.meaning}',
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    height: 1.5,
                    color: colorScheme.onSurface.withAlpha(204),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  BoxDecoration _decoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.primaryContainer.withAlpha(64),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colorScheme.primary.withAlpha(77), width: 1),
    );
  }

  Widget _contentText(String text, ColorScheme colorScheme) {
    if (renderMath) {
      return MathTex(
        text: text,
        fontSize: fontSize - 1,
        color: colorScheme.onSurface,
        height: 1.6,
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize - 1,
        height: 1.6,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class _ConceptChip extends StatelessWidget {
  final String label;

  const _ConceptChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withAlpha(204),
        ),
      ),
    );
  }
}

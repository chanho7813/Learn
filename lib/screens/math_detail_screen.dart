import 'package:flutter/material.dart';
import '../models/math_problem.dart';
import '../services/settings_service.dart';
import '../widgets/math_tex.dart';

class MathDetailScreen extends StatefulWidget {
  final MathExam exam;

  const MathDetailScreen({super.key, required this.exam});

  @override
  State<MathDetailScreen> createState() => _MathDetailScreenState();
}

class _MathDetailScreenState extends State<MathDetailScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final size = await SettingsService.getFontSize();
    final section = await SettingsService.getLastMathSection();
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
      _showAnswer = false;
    });
    SettingsService.setLastMathSection(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final questions = widget.exam.questions;
    final q = questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exam.title,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Column(
        children: [
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
                      backgroundColor:
                          colorScheme.surfaceContainerHighest.withAlpha(128),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
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
                      '${q.number}번${q.points.isNotEmpty ? ' [${q.points}]' : ''}',
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
                      backgroundColor:
                          colorScheme.surfaceContainerHighest.withAlpha(128),
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
                  _QuestionCard(question: q, fontSize: _fontSize),
                  const SizedBox(height: 12),
                  _RevealButton(
                    label: _showAnswer ? '정답 숨기기' : '정답 보기',
                    icon: _showAnswer
                        ? Icons.visibility_off_outlined
                        : Icons.check_circle_outline,
                    isRevealed: _showAnswer,
                    onTap: () => setState(() => _showAnswer = !_showAnswer),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topLeft,
                    child: _showAnswer
                        ? _AnswerHint(colorScheme: colorScheme)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final MathQuestion question;
  final double fontSize;

  const _QuestionCard({required this.question, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? colorScheme.surfaceContainerHighest.withAlpha(77)
            : Colors.white,
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(77),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MathTex(
            text: question.stem,
            fontSize: fontSize,
            color: colorScheme.onSurface,
          ),
          if (question.choices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: question.choices.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MathTex(
                      text: '${c.label} ${c.text}',
                      fontSize: fontSize - 1,
                      color: colorScheme.onSurface.withAlpha(204),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RevealButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isRevealed;
  final VoidCallback onTap;

  const _RevealButton({
    required this.label,
    required this.icon,
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
                icon,
                size: 20,
                color: isRevealed
                    ? colorScheme.onSurface.withAlpha(128)
                    : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
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

class _AnswerHint extends StatelessWidget {
  final ColorScheme colorScheme;

  const _AnswerHint({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            '정답/풀이는 추후 추가 예정',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

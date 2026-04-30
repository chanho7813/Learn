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
  int _currentSectionIndex = 0;
  bool _showSolution = false;
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
        _currentSectionIndex =
            section.clamp(0, widget.exam.sections.length - 1);
      });
    }
  }

  void _goToSection(int index) {
    final clamped = index.clamp(0, widget.exam.sections.length - 1);
    if (clamped == _currentSectionIndex) return;
    setState(() {
      _currentSectionIndex = clamped;
      _showSolution = false;
      _showAnswer = false;
    });
    SettingsService.setLastMathSection(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sections = widget.exam.sections;
    final section = sections[_currentSectionIndex];
    final problem = section.problem;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exam.title,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          if (sections.length > 1)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentSectionIndex > 0
                        ? () => _goToSection(_currentSectionIndex - 1)
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
                      section.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _currentSectionIndex < sections.length - 1
                        ? () => _goToSection(_currentSectionIndex + 1)
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
              onHorizontalDragEnd: sections.length > 1
                  ? (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity > 300) {
                        _goToSection(_currentSectionIndex - 1);
                      } else if (velocity < -300) {
                        _goToSection(_currentSectionIndex + 1);
                      }
                    }
                  : null,
              behavior: HitTestBehavior.translucent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _ProblemCard(
                    problem: problem,
                    fontSize: _fontSize,
                  ),
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
                        ? _AnswerCard(answer: problem.answer, fontSize: _fontSize)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                  _RevealButton(
                    label: _showSolution ? '풀이 숨기기' : '풀이 보기',
                    icon: _showSolution
                        ? Icons.visibility_off_outlined
                        : Icons.lightbulb_outline,
                    isRevealed: _showSolution,
                    onTap: () =>
                        setState(() => _showSolution = !_showSolution),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topLeft,
                    child: _showSolution
                        ? _SolutionCard(
                            problem: problem, fontSize: _fontSize)
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

class _ProblemCard extends StatelessWidget {
  final MathProblem problem;
  final double fontSize;

  const _ProblemCard({required this.problem, required this.fontSize});

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
            text: problem.question,
            fontSize: fontSize,
            color: colorScheme.onSurface,
          ),
          if (problem.choices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: MathTex(
                text: problem.choices,
                fontSize: fontSize - 1,
                color: colorScheme.onSurface.withAlpha(204),
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

class _AnswerCard extends StatelessWidget {
  final String answer;
  final double fontSize;

  const _AnswerCard({required this.answer, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          MathTex(
            text: '정답: $answer',
            fontSize: fontSize + 2,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  final MathProblem problem;
  final double fontSize;

  const _SolutionCard({required this.problem, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(77),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '풀이',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.orange.withAlpha(128),
                  width: 2.5,
                ),
              ),
            ),
            child: MathTex(
              text: problem.solution,
              fontSize: fontSize - 1,
              color: colorScheme.onSurface.withAlpha(204),
            ),
          ),
          if (problem.concepts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.school_outlined,
                    size: 18, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  '핵심 개념',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: MathTex(
                text: problem.concepts,
                fontSize: fontSize - 1,
                color: colorScheme.onSurface.withAlpha(179),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

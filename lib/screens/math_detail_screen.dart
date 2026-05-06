import 'package:flutter/material.dart';
import '../models/exam_solution.dart';
import '../models/math_problem.dart';
import '../services/settings_service.dart';
import '../services/solution_service.dart';
import '../widgets/math_tex.dart';
import '../widgets/solution_panel.dart';

class MathDetailScreen extends StatefulWidget {
  final MathExam exam;

  const MathDetailScreen({super.key, required this.exam});

  @override
  State<MathDetailScreen> createState() => _MathDetailScreenState();
}

class _MathDetailScreenState extends State<MathDetailScreen> {
  final Map<int, String> _selectedChoices = {};
  int _currentIndex = 0;
  bool _showSolution = false;
  double _fontSize = 16.0;
  ExamSolution? _solution;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final size = await SettingsService.getFontSize();
    final section = await SettingsService.getLastMathSection();
    final solution = await SolutionService.loadMathSolution(widget.exam);
    final selectedChoices = <int, String>{};
    for (final question in widget.exam.questions) {
      final label = await SettingsService.getSelectedChoice(
        examKind: 'math',
        examId: '${widget.exam.university}_${widget.exam.subject}',
        year: widget.exam.year,
        questionNumber: question.number,
      );
      if (label != null && label.isNotEmpty) {
        selectedChoices[question.number] = label;
      }
    }
    if (mounted) {
      setState(() {
        _fontSize = size;
        _currentIndex = section.clamp(0, widget.exam.questions.length - 1);
        _solution = solution;
        _selectedChoices
          ..clear()
          ..addAll(selectedChoices);
      });
    }
  }

  void _goTo(int index) {
    final clamped = index.clamp(0, widget.exam.questions.length - 1);
    if (clamped == _currentIndex) return;
    setState(() {
      _currentIndex = clamped;
      _showSolution = false;
    });
    SettingsService.setLastMathSection(clamped);
  }

  Future<void> _selectChoice(int questionNumber, String label) async {
    final current = _selectedChoices[questionNumber];
    final next = current == label ? null : label;
    setState(() {
      if (next == null) {
        _selectedChoices.remove(questionNumber);
      } else {
        _selectedChoices[questionNumber] = next;
      }
    });
    await SettingsService.setSelectedChoice(
      examKind: 'math',
      examId: '${widget.exam.university}_${widget.exam.subject}',
      year: widget.exam.year,
      questionNumber: questionNumber,
      selectedLabel: next,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final questions = widget.exam.questions;
    final q = questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title, style: const TextStyle(fontSize: 14)),
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
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withAlpha(128),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
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
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withAlpha(128),
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
                  _QuestionCard(
                    question: q,
                    fontSize: _fontSize,
                    selectedChoice: _selectedChoices[q.number],
                    onChoiceSelected: (label) => _selectChoice(q.number, label),
                  ),
                  const SizedBox(height: 12),
                  SolutionRevealButton(
                    isRevealed: _showSolution,
                    onTap: () => setState(() => _showSolution = !_showSolution),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topLeft,
                    child: _showSolution
                        ? SolutionPanel(
                            solution: _solution?.solutionFor(q.number),
                            renderMath: true,
                            fontSize: _fontSize,
                          )
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
  final String? selectedChoice;
  final ValueChanged<String> onChoiceSelected;

  const _QuestionCard({
    required this.question,
    required this.fontSize,
    required this.selectedChoice,
    required this.onChoiceSelected,
  });

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
          if (question.statementBox.isNotEmpty) ...[
            const SizedBox(height: 16),
            _StatementBox(
              lines: question.statementBox,
              title: question.statementBoxTitle,
              fontSize: fontSize,
            ),
          ],
          if (question.stemAfterBox.isNotEmpty) ...[
            const SizedBox(height: 16),
            MathTex(
              text: question.stemAfterBox,
              fontSize: fontSize,
              color: colorScheme.onSurface,
            ),
          ],
          if (question.choices.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ChoiceGrid(
              choices: question.choices,
              fontSize: fontSize,
              selectedChoice: selectedChoice,
              onChoiceSelected: onChoiceSelected,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatementBox extends StatelessWidget {
  final List<MathStatement> lines;
  final String title;
  final double fontSize;

  const _StatementBox({
    required this.lines,
    required this.title,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Center(
              child: Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == lines.length - 1 ? 0 : 8,
                  ),
                  child: MathTex(
                    text: _formatLine(lines[i]),
                    fontSize: fontSize - 1,
                    color: colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLine(MathStatement statement) {
    if (statement.label.isEmpty) return statement.text;
    return '${statement.label} ${statement.text}';
  }
}

class _ChoiceGrid extends StatelessWidget {
  final List<MathChoice> choices;
  final double fontSize;
  final String? selectedChoice;
  final ValueChanged<String> onChoiceSelected;

  const _ChoiceGrid({
    required this.choices,
    required this.fontSize,
    required this.selectedChoice,
    required this.onChoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 28.0;
          const runSpacing = 12.0;
          final columns = _columnCount(constraints.maxWidth);
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: choices.map((choice) {
              final isSelected = selectedChoice == choice.label;
              return SizedBox(
                width: itemWidth,
                child: Material(
                  color: isSelected
                      ? colorScheme.primaryContainer.withAlpha(128)
                      : colorScheme.surface.withAlpha(0),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => onChoiceSelected(choice.label),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary.withAlpha(153)
                              : colorScheme.outlineVariant.withAlpha(77),
                          width: isSelected ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Center(
                              child: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      size: fontSize + 4,
                                      color: colorScheme.primary,
                                    )
                                  : Text(
                                      choice.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: fontSize - 1,
                                        height: 1,
                                        color: colorScheme.onSurface.withAlpha(
                                          179,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          Expanded(
                            child: MathTex(
                              text: choice.text,
                              fontSize: fontSize - 1,
                              color: colorScheme.onSurface.withAlpha(204),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  int _columnCount(double width) {
    final longestChoice = choices.fold<int>(
      0,
      (longest, choice) =>
          choice.text.length > longest ? choice.text.length : longest,
    );

    if (width < 420 || longestChoice > 90) return 1;
    if (width < 760 || longestChoice > 40) return 2;
    return 4;
  }
}

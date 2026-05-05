import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathTex extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final double height;

  const MathTex({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color,
    this.height = 1.8,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Theme.of(context).colorScheme.onSurface;
    final parts = _parse(text);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: parts.map((part) {
        if (part.isMath) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Math.tex(
              part.content,
              textStyle: TextStyle(fontSize: fontSize, color: textColor),
              onErrorFallback: (_) => Text(
                part.content,
                style: TextStyle(
                  fontSize: fontSize,
                  height: height,
                  color: textColor,
                ),
              ),
            ),
          );
        }
        return Text(
          part.content,
          style: TextStyle(
            fontSize: fontSize,
            height: height,
            color: textColor,
          ),
        );
      }).toList(),
    );
  }

  static List<_Part> _parse(String input) {
    final parts = <_Part>[];
    final delimiterRegex = RegExp(
      r'\\\((.+?)\\\)|\\\[(.+?)\\\]|\$\$(.+?)\$\$|\$(.+?)\$',
      dotAll: true,
    );

    if (delimiterRegex.hasMatch(input)) {
      int lastEnd = 0;
      for (final match in delimiterRegex.allMatches(input)) {
        if (match.start > lastEnd) {
          final text = input.substring(lastEnd, match.start);
          if (text.isNotEmpty) parts.add(_Part(text, false));
        }
        final latex = match.groups([1, 2, 3, 4]).whereType<String>().first;
        parts.add(_Part(latex, true));
        lastEnd = match.end;
      }
      if (lastEnd < input.length) {
        parts.add(_Part(input.substring(lastEnd), false));
      }
    } else if (_hasLatexCommands(input)) {
      final koreanRun = RegExp(r'[가-힣ㄱ-ㅣ][가-힣ㄱ-ㅣ\s,.\-?!:;()~·…“”]*');
      int lastEnd = 0;

      for (final match in koreanRun.allMatches(input)) {
        if (match.start > lastEnd) {
          final mathPart = input.substring(lastEnd, match.start).trim();
          if (mathPart.isNotEmpty) parts.add(_Part(mathPart, true));
        }
        final textPart = match.group(0)!.trim();
        if (textPart.isNotEmpty) parts.add(_Part(' $textPart ', false));
        lastEnd = match.end;
      }

      if (lastEnd < input.length) {
        final mathPart = input.substring(lastEnd).trim();
        if (mathPart.isNotEmpty) parts.add(_Part(mathPart, true));
      }

      if (parts.isEmpty) {
        parts.add(_Part(input, true));
      }
    } else {
      parts.add(_Part(input, false));
    }

    return parts;
  }

  static bool _hasLatexCommands(String text) {
    return RegExp(r'\\[a-zA-Z]+').hasMatch(text);
  }
}

class _Part {
  final String content;
  final bool isMath;
  const _Part(this.content, this.isMath);
}

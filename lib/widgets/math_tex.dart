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
    final regex = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);
    int lastEnd = 0;

    for (final match in regex.allMatches(input)) {
      if (match.start > lastEnd) {
        final text = input.substring(lastEnd, match.start);
        if (text.isNotEmpty) parts.add(_Part(text, false));
      }
      final latex = match.group(1) ?? match.group(2) ?? '';
      parts.add(_Part(latex, true));
      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      parts.add(_Part(input.substring(lastEnd), false));
    }

    return parts;
  }
}

class _Part {
  final String content;
  final bool isMath;
  const _Part(this.content, this.isMath);
}

import 'package:flutter/material.dart';

class StyledWordSegment {
  final String text;
  final Color? color;
  final int rawStartIndex;
  final int rawEndIndex;

  const StyledWordSegment({
    required this.text,
    this.color,
    required this.rawStartIndex,
    required this.rawEndIndex,
  });
}

class TextSpanParser {
  static final RegExp _tagRegex = RegExp(
    r'(\[color:(#[0-9a-fA-F]{3,8}|[a-zA-Z]+)\]([\s\S]*?)\[/color\]|<color=(#[0-9a-fA-F]{3,8}|[a-zA-Z]+)>([\s\S]*?)</color>)',
  );

  /// Converts standard or tagged string into a rich TextSpan
  static TextSpan parseToTextSpan(String content, TextStyle baseStyle) {
    if (content.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    final matches = _tagRegex.allMatches(content);
    if (matches.isEmpty) {
      return TextSpan(text: content, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final colorStr = match.group(2) ?? match.group(4) ?? '';
      final innerText = match.group(3) ?? match.group(5) ?? '';
      final parsedColor = parseColor(colorStr) ?? baseStyle.color;

      spans.add(TextSpan(
        text: innerText,
        style: baseStyle.copyWith(color: parsedColor),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  /// Extracts plain text stripping color tags
  static String stripTags(String content) {
    return content.replaceAllMapped(_tagRegex, (match) {
      return match.group(3) ?? match.group(5) ?? '';
    });
  }

  /// Parses human-readable or hex color string
  static Color? parseColor(String colorStr) {
    final clean = colorStr.trim().toLowerCase();
    if (clean.startsWith('#')) {
      final hex = clean.substring(1);
      if (hex.length == 6) {
        final val = int.tryParse(hex, radix: 16);
        if (val != null) return Color(0xFF000000 | val);
      } else if (hex.length == 8) {
        final val = int.tryParse(hex, radix: 16);
        if (val != null) return Color(val);
      } else if (hex.length == 3) {
        final r = hex[0];
        final g = hex[1];
        final b = hex[2];
        final val = int.tryParse('$r$r$g$g$b$b', radix: 16);
        if (val != null) return Color(0xFF000000 | val);
      }
    }

    // Named color fallback
    switch (clean) {
      case 'purple':
        return const Color(0xFF6C5CE7);
      case 'blue':
        return const Color(0xFF0D99FF);
      case 'white':
        return const Color(0xFFFFFFFF);
      case 'black':
        return const Color(0xFF000000);
      case 'red':
        return const Color(0xFFFF4757);
      case 'green':
        return const Color(0xFF2ED573);
      case 'yellow':
      case 'amber':
        return const Color(0xFFFFA502);
      case 'orange':
        return const Color(0xFFFF7F50);
      case 'cyan':
        return const Color(0xFF00D2D3);
      case 'pink':
        return const Color(0xFFFF6B81);
      default:
        return null;
    }
  }

  /// Formats color to #HEX string
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Extracts individual words along with their color styling
  static List<StyledWordSegment> extractWordSegments(String content) {
    final segments = <StyledWordSegment>[];
    final matches = _tagRegex.allMatches(content).toList();
    
    // We walk character by character to detect words and tags
    int pos = 0;
    while (pos < content.length) {
      // Check if pos is at a match start
      Match? currentMatch;
      for (final m in matches) {
        if (m.start == pos) {
          currentMatch = m;
          break;
        }
      }

      if (currentMatch != null) {
        final colorStr = currentMatch.group(2) ?? currentMatch.group(4) ?? '';
        final innerText = currentMatch.group(3) ?? currentMatch.group(5) ?? '';
        final color = parseColor(colorStr);

        // Split innerText by whitespace while keeping words
        final innerWords = innerText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        for (final word in innerWords) {
          segments.add(StyledWordSegment(
            text: word,
            color: color,
            rawStartIndex: currentMatch.start,
            rawEndIndex: currentMatch.end,
          ));
        }
        pos = currentMatch.end;
      } else {
        // Collect untagged word
        if (content[pos].trim().isEmpty) {
          pos++;
          continue;
        }
        int wordEnd = pos;
        while (wordEnd < content.length &&
            content[wordEnd].trim().isNotEmpty &&
            !matches.any((m) => m.start == wordEnd)) {
          wordEnd++;
        }
        final word = content.substring(pos, wordEnd);
        segments.add(StyledWordSegment(
          text: word,
          color: null,
          rawStartIndex: pos,
          rawEndIndex: wordEnd,
        ));
        pos = wordEnd;
      }
    }

    return segments;
  }

  /// Applies a color to a specific word or phrase in content
  static String applyColorToWord(String content, String word, Color? color) {
    if (word.isEmpty) return content;

    // Check if word is already inside a tag
    final pattern = RegExp(
      r'\[color:(#[0-9a-fA-F]{3,8}|[a-zA-Z]+)\](' +
          RegExp.escape(word) +
          r')\[/color\]',
      caseSensitive: false,
    );

    if (color == null || color == Colors.transparent) {
      // Remove color from word
      if (pattern.hasMatch(content)) {
        return content.replaceAllMapped(pattern, (m) => m.group(2)!);
      }
      return content;
    }

    final hex = colorToHex(color);
    if (pattern.hasMatch(content)) {
      return content.replaceAllMapped(pattern, (m) => '[color:$hex]${m.group(2)}[/color]');
    }

    // Wrap first untagged occurrence of word
    final wordPattern = RegExp(r'\b' + RegExp.escape(word) + r'\b');
    if (wordPattern.hasMatch(content)) {
      return content.replaceFirst(wordPattern, '[color:$hex]$word[/color]');
    }

    // Fallback simple replace
    return content.replaceFirst(word, '[color:$hex]$word[/color]');
  }

  /// Applies a color to any arbitrary selected characters or text range
  static String applyColorToSubstring(String content, String selectedText, Color? color) {
    if (selectedText.isEmpty) return content;

    final hex = color != null && color != Colors.transparent ? colorToHex(color) : null;

    if (hex == null) {
      final pattern = RegExp(
        r'\[color:(#[0-9a-fA-F]{3,8}|[a-zA-Z]+)\](' +
            RegExp.escape(selectedText) +
            r')\[/color\]',
        caseSensitive: false,
      );
      if (pattern.hasMatch(content)) {
        return content.replaceAllMapped(pattern, (m) => m.group(2)!);
      }
      return content;
    }

    final tagPattern = RegExp(
      r'\[color:(#[0-9a-fA-F]{3,8}|[a-zA-Z]+)\](' +
          RegExp.escape(selectedText) +
          r')\[/color\]',
      caseSensitive: false,
    );
    if (tagPattern.hasMatch(content)) {
      return content.replaceAllMapped(tagPattern, (m) => '[color:$hex]${m.group(2)}[/color]');
    }

    return content.replaceFirst(selectedText, '[color:$hex]$selectedText[/color]');
  }
}

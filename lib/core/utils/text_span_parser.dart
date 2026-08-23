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

    final normalized = content.replaceAll(r'\n', '\n');
    final matches = _tagRegex.allMatches(normalized);
    if (matches.isEmpty) {
      return TextSpan(text: normalized, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: normalized.substring(lastIndex, match.start),
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

    if (lastIndex < normalized.length) {
      spans.add(TextSpan(
        text: normalized.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  /// Extracts plain text stripping color tags
  static String stripTags(String content) {
    final normalized = content.replaceAll(r'\n', '\n');
    return normalized.replaceAllMapped(_tagRegex, (match) {
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

  /// Parses tagged string (e.g. "[color:#6C5CE7]Uber's Eats[/color]") into clean text and ranges
  static (String, List<ColoredRange>) parseTaggedTextToClean(String content) {
    if (content.isEmpty) return ('', <ColoredRange>[]);

    final normalized = content.replaceAll(r'\n', '\n');
    final matches = _tagRegex.allMatches(normalized).toList();
    if (matches.isEmpty) {
      return (normalized, <ColoredRange>[]);
    }

    final cleanBuffer = StringBuffer();
    final ranges = <ColoredRange>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        cleanBuffer.write(normalized.substring(lastIndex, match.start));
      }

      final colorStr = match.group(2) ?? match.group(4) ?? '';
      final innerText = match.group(3) ?? match.group(5) ?? '';
      final parsedColor = parseColor(colorStr);

      final start = cleanBuffer.length;
      cleanBuffer.write(innerText);
      final end = cleanBuffer.length;

      if (parsedColor != null && end > start) {
        ranges.add(ColoredRange(start: start, end: end, color: parsedColor));
      }

      lastIndex = match.end;
    }

    if (lastIndex < normalized.length) {
      cleanBuffer.write(normalized.substring(lastIndex));
    }

    return (cleanBuffer.toString(), ranges);
  }

  /// Extracts individual words along with their assigned color styling from clean text and ranges
  static List<StyledWordSegment> extractCleanWordSegments(String cleanText, List<ColoredRange> ranges) {
    final segments = <StyledWordSegment>[];
    final regex = RegExp(r'\S+');
    for (final match in regex.allMatches(cleanText)) {
      final word = match.group(0)!;
      final start = match.start;
      final end = match.end;

      Color? wordColor;
      for (final r in ranges) {
        if (r.start <= start && r.end >= end) {
          wordColor = r.color;
          break;
        } else if (r.start < end && r.end > start) {
          wordColor = r.color;
          break;
        }
      }

      segments.add(StyledWordSegment(
        text: word,
        color: wordColor,
        rawStartIndex: start,
        rawEndIndex: end,
      ));
    }
    return segments;
  }
}

class ColoredRange {
  int start;
  int end;
  Color color;

  ColoredRange({required this.start, required this.end, required this.color});

  ColoredRange copy() => ColoredRange(start: start, end: end, color: color);

  @override
  String toString() => 'ColoredRange($start..$end, color: $color)';
}

/// WYSIWYG rich text editing controller that renders colored text spans inline
/// and allows continuous typing in the active or adjacent text color.
class RichColorTextEditingController extends TextEditingController {
  List<ColoredRange> ranges = [];
  Color? activeColor;

  RichColorTextEditingController({String? taggedText, this.activeColor}) {
    if (taggedText != null && taggedText.isNotEmpty) {
      final parsed = TextSpanParser.parseTaggedTextToClean(taggedText);
      text = parsed.$1;
      ranges = parsed.$2;
    }
  }

  void setFromTaggedText(String taggedText) {
    final parsed = TextSpanParser.parseTaggedTextToClean(taggedText);
    text = parsed.$1;
    ranges = parsed.$2;
    notifyListeners();
  }

  String toTaggedString() {
    if (ranges.isEmpty) return text;
    final buffer = StringBuffer();
    int currentPos = 0;
    final sorted = List<ColoredRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final r in sorted) {
      final start = r.start.clamp(0, text.length);
      final end = r.end.clamp(start, text.length);
      if (start > currentPos) {
        buffer.write(text.substring(currentPos, start));
      }
      if (end > start) {
        final hex = TextSpanParser.colorToHex(r.color);
        buffer.write('[color:$hex]${text.substring(start, end)}[/color]');
      }
      currentPos = end;
    }
    if (currentPos < text.length) {
      buffer.write(text.substring(currentPos));
    }
    return buffer.toString();
  }

  @override
  set value(TextEditingValue newValue) {
    final oldText = text;
    final newText = newValue.text;

    if (oldText != newText) {
      _adjustRangesOnTextChange(oldText, newText, newValue.selection);
    }

    super.value = newValue;
  }

  void _adjustRangesOnTextChange(String oldText, String newText, TextSelection newSelection) {
    final diff = newText.length - oldText.length;

    // Find prefix matching length
    int prefixLen = 0;
    while (prefixLen < oldText.length &&
        prefixLen < newText.length &&
        oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    // Find suffix matching length
    int suffixLen = 0;
    while (suffixLen < (oldText.length - prefixLen) &&
        suffixLen < (newText.length - prefixLen) &&
        oldText[oldText.length - 1 - suffixLen] == newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }

    final oldChangeStart = prefixLen;
    final oldChangeEnd = oldText.length - suffixLen;
    final insertedLen = newText.length - prefixLen - suffixLen;

    final updatedRanges = <ColoredRange>[];

    for (final r in ranges) {
      // 1. Span is strictly before edit point
      if (r.end < oldChangeStart) {
        updatedRanges.add(r);
      }
      // 2. Span is strictly after edit point
      else if (r.start >= oldChangeEnd) {
        updatedRanges.add(ColoredRange(
          start: r.start + diff,
          end: r.end + diff,
          color: r.color,
        ));
      }
      // 3. User is typing at the boundary or inside this span
      else {
        // If typing directly at the end or inside the span
        if (oldChangeStart > r.start && oldChangeStart <= r.end && oldChangeStart == oldChangeEnd) {
          // Insertion inside or at right edge of span -> Expand span with typed text!
          updatedRanges.add(ColoredRange(
            start: r.start,
            end: r.end + insertedLen,
            color: r.color,
          ));
        } else if (oldChangeStart == r.start && oldChangeStart == oldChangeEnd) {
          // Insertion at left edge: if active color matches, expand; else shift
          if (activeColor != null && activeColor == r.color) {
            updatedRanges.add(ColoredRange(
              start: r.start,
              end: r.end + insertedLen,
              color: r.color,
            ));
          } else {
            updatedRanges.add(ColoredRange(
              start: r.start + insertedLen,
              end: r.end + insertedLen,
              color: r.color,
            ));
          }
        } else {
          // Overwrite or deletion overlapping this span
          final newStart = r.start < oldChangeStart ? r.start : oldChangeStart + insertedLen;
          final newEnd = r.end > oldChangeEnd ? r.end + diff : oldChangeStart;
          if (newEnd > newStart) {
            updatedRanges.add(ColoredRange(
              start: newStart,
              end: newEnd,
              color: r.color,
            ));
          }
        }
      }
    }

    // Clamp and clean
    ranges = updatedRanges.where((r) => r.start < r.end && r.start >= 0 && r.end <= newText.length).toList();
    _normalizeRanges();
  }

  void _normalizeRanges() {
    if (ranges.isEmpty) return;
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <ColoredRange>[];
    for (final r in ranges) {
      if (merged.isEmpty) {
        merged.add(r);
      } else {
        final last = merged.last;
        if (last.end >= r.start && last.color == r.color) {
          if (r.end > last.end) {
            last.end = r.end;
          }
        } else if (last.end < r.start) {
          merged.add(r);
        } else {
          last.end = r.start;
          merged.add(r);
        }
      }
    }
    ranges = merged.where((r) => r.start < r.end).toList();
  }

  void applyColorToSelection(Color? color) {
    if (!selection.isValid || selection.isCollapsed) return;
    final start = selection.start < selection.end ? selection.start : selection.end;
    final end = selection.start > selection.end ? selection.start : selection.end;
    applyColorToRange(start, end, color);
  }

  void applyColorToRange(int start, int end, Color? color) {
    if (start >= end || start < 0 || end > text.length) return;

    final updated = <ColoredRange>[];
    for (final r in ranges) {
      if (r.end <= start || r.start >= end) {
        updated.add(r);
      } else {
        if (r.start < start) {
          updated.add(ColoredRange(start: r.start, end: start, color: r.color));
        }
        if (r.end > end) {
          updated.add(ColoredRange(start: end, end: r.end, color: r.color));
        }
      }
    }

    if (color != null && color != Colors.transparent) {
      updated.add(ColoredRange(start: start, end: end, color: color));
    }

    ranges = updated;
    _normalizeRanges();
    notifyListeners();
  }

  void applyColorToWord(String word, Color? color) {
    final idx = text.indexOf(word);
    if (idx != -1) {
      applyColorToRange(idx, idx + word.length, color);
    }
  }

  Color? getColorAtCursor(int cursor) {
    for (final r in ranges) {
      if (cursor >= r.start && cursor <= r.end) {
        return r.color;
      }
    }
    return null;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle(color: Colors.white, fontSize: 14);
    if (ranges.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    int currentPos = 0;
    final sorted = List<ColoredRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final r in sorted) {
      final start = r.start.clamp(0, text.length);
      final end = r.end.clamp(start, text.length);
      if (start > currentPos) {
        spans.add(TextSpan(
          text: text.substring(currentPos, start),
          style: baseStyle,
        ));
      }
      if (end > start) {
        spans.add(TextSpan(
          text: text.substring(start, end),
          style: baseStyle.copyWith(color: r.color),
        ));
      }
      currentPos = end;
    }

    if (currentPos < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPos),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans, style: baseStyle);
  }
}

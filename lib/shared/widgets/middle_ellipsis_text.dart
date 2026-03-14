import 'package:flutter/widgets.dart';

/// A single-line text widget that truncates the middle of long strings
/// with an ellipsis (e.g., "prefix…suffix") so both ends remain visible.
///
/// This widget handles Unicode text safely, including emojis and other
/// characters that span multiple UTF-16 code units (surrogate pairs).
class MiddleEllipsisText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String ellipsis;
  final String? semanticsLabel;

  const MiddleEllipsisText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.ellipsis = '…',
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Sanitize text to remove any unpaired surrogates that could cause crashes.
    final String safeText = _sanitizeUtf16(text);

    return LayoutBuilder(
      builder: (context, constraints) {
        final TextStyle effectiveStyle = DefaultTextStyle.of(
          context,
        ).style.merge(style);
        final TextDirection direction = Directionality.of(context);
        final double maxWidth = constraints.maxWidth;

        // Measure full text width first.
        final fullSpan = TextSpan(text: safeText, style: effectiveStyle);
        final fullPainter = TextPainter(
          text: fullSpan,
          textDirection: direction,
          maxLines: 1,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        if (fullPainter.width <= maxWidth) {
          return Text(
            safeText,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.clip,
            textAlign: textAlign,
            semanticsLabel: semanticsLabel,
          );
        }

        // Use grapheme clusters (Characters) to safely split text without
        // breaking surrogate pairs or emoji sequences.
        final characters = safeText.characters;
        final int totalGraphemes = characters.length;

        // Pre-measure ellipsis width (used implicitly during search).
        final ellipsisSpan = TextSpan(text: ellipsis, style: effectiveStyle);
        final ellipsisPainter = TextPainter(
          text: ellipsisSpan,
          textDirection: direction,
          maxLines: 1,
        )..layout(minWidth: 0, maxWidth: double.infinity);
        final double _ = ellipsisPainter.width; // hint width; not used directly

        // Binary search the maximum number of visible graphemes (k), split
        // between start and end. For a given k, we use ceil(k/2) from start
        // and floor(k/2) from end.
        int low = 0;
        int high = totalGraphemes;
        int bestK = 0;
        String bestStart = '';
        String bestEnd = '';

        while (low <= high) {
          final int k = (low + high) >> 1; // candidate visible grapheme count
          final int leftCount = (k + 1) >> 1; // ceil(k/2)
          final int rightCount = k - leftCount; // floor(k/2)

          // Use Characters.take/takeLast to safely extract grapheme clusters.
          final String start = characters.take(leftCount).toString();
          final String end = rightCount == 0
              ? ''
              : characters.takeLast(rightCount).toString();

          final trialSpan = TextSpan(
            text: '$start$ellipsis$end',
            style: effectiveStyle,
          );
          final trialPainter = TextPainter(
            text: trialSpan,
            textDirection: direction,
            maxLines: 1,
          )..layout(minWidth: 0, maxWidth: double.infinity);

          if (trialPainter.width <= maxWidth) {
            bestK = k;
            bestStart = start;
            bestEnd = end;
            low = k + 1; // try to fit more
          } else {
            high = k - 1; // need fewer characters
          }
        }

        if (bestK == 0) {
          return Text(
            ellipsis,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.clip,
            textAlign: textAlign,
            semanticsLabel: semanticsLabel ?? safeText,
          );
        }

        final String display = '$bestStart$ellipsis$bestEnd';
        return Text(
          display,
          style: effectiveStyle,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textAlign: textAlign,
          semanticsLabel: semanticsLabel ?? safeText,
        );
      },
    );
  }

  /// Removes unpaired UTF-16 surrogates that would cause "not well-formed
  /// UTF-16" errors during text layout.
  ///
  /// A valid UTF-16 string requires:
  /// - High surrogates (0xD800-0xDBFF) must be followed by low surrogates
  /// - Low surrogates (0xDC00-0xDFFF) must be preceded by high surrogates
  static String _sanitizeUtf16(String input) {
    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final int codeUnit = input.codeUnitAt(i);

      // Check if this is a high surrogate (0xD800-0xDBFF)
      if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        // Check if next character is a valid low surrogate
        if (i + 1 < input.length) {
          final int nextCodeUnit = input.codeUnitAt(i + 1);
          if (nextCodeUnit >= 0xDC00 && nextCodeUnit <= 0xDFFF) {
            // Valid surrogate pair - include both
            buffer.writeCharCode(codeUnit);
            buffer.writeCharCode(nextCodeUnit);
            i++; // Skip the low surrogate in next iteration
            continue;
          }
        }
        // Unpaired high surrogate - replace with replacement character
        buffer.writeCharCode(0xFFFD);
      } else if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
        // Unpaired low surrogate - replace with replacement character
        buffer.writeCharCode(0xFFFD);
      } else {
        // Regular character - include as-is
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }
}

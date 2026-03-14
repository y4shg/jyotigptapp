import 'package:checks/checks.dart';
import 'package:jyotigptapp/shared/widgets/markdown/markdown_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JyotiGPTappMarkdownPreprocessor.normalize', () {
    test('empty string returns empty', () {
      check(JyotiGPTappMarkdownPreprocessor.normalize('')).equals('');
    });

    test('CRLF is converted to LF', () {
      final result =
          JyotiGPTappMarkdownPreprocessor.normalize('hello\r\nworld');
      check(result).not((s) => s.contains('\r'));
      check(result).contains('hello\nworld');
    });

    test('auto-closes unmatched fence (odd count)', () {
      final result =
          JyotiGPTappMarkdownPreprocessor.normalize('```python\ncode');
      check(result).endsWith('```');
      // Should have exactly 2 fences now (even)
      final fenceCount = RegExp(r'```').allMatches(result).length;
      check(fenceCount.isEven).isTrue();
    });

    test('dedents indented opening fence', () {
      final result = JyotiGPTappMarkdownPreprocessor.normalize(
        '    ```python\ncode\n```',
      );
      check(result).contains('```python');
      check(result).not((s) => s.contains('    ```python'));
    });

    test('dedents indented closing fence', () {
      final result = JyotiGPTappMarkdownPreprocessor.normalize(
        '```python\ncode\n    ```',
      );
      // The closing fence should not be indented.
      check(result).not((s) => s.contains('    ```'));
    });

    test('moves fence after list marker to new line', () {
      final result = JyotiGPTappMarkdownPreprocessor.normalize(
        '- ```python\ncode\n```',
      );
      // The fence should be on its own line after the list marker.
      check(result).contains('- \n```python');
    });

    test('ensures closing fence on own line', () {
      final result = JyotiGPTappMarkdownPreprocessor.normalize(
        '```\nsome code```\n',
      );
      // "code```" at EOL should become "code\n```"
      check(result).contains('some code\n```');
    });

    test('fixes numeric heading by inserting ZWNJ after dot', () {
      final result =
          JyotiGPTappMarkdownPreprocessor.normalize('### 1. First');
      // Should insert \u200C between the dot and space.
      check(result).contains('1.\u200C');
    });

    test('fixes Setext heading false positive', () {
      final result = JyotiGPTappMarkdownPreprocessor.normalize(
        '**Bold**\n---',
      );
      // Should add a blank line between the bold text and the dashes.
      check(result).contains('**Bold**\n\n');
    });
  });

  group('JyotiGPTappMarkdownPreprocessor.sanitize', () {
    test('empty string returns empty', () {
      check(JyotiGPTappMarkdownPreprocessor.sanitize('')).equals('');
    });

    test('removes <think>...</think> blocks', () {
      final result = JyotiGPTappMarkdownPreprocessor.sanitize(
        'before<think>internal reasoning</think>after',
      );
      check(result).not((s) => s.contains('think'));
      check(result).not((s) => s.contains('internal'));
      check(result).contains('before');
      check(result).contains('after');
    });

    test(
      'removes <details type="reasoning">...</details> blocks',
      () {
        final result = JyotiGPTappMarkdownPreprocessor.sanitize(
          'before<details type="reasoning">hidden</details>after',
        );
        check(result).not((s) => s.contains('hidden'));
        check(result).contains('before');
        check(result).contains('after');
      },
    );

    test('collapses 3+ newlines to double newline', () {
      final result = JyotiGPTappMarkdownPreprocessor.sanitize(
        'a\n\n\n\nb',
      );
      check(result).equals('a\n\nb');
    });
  });

  group('JyotiGPTappMarkdownPreprocessor.toPlainText', () {
    test('whitespace-only returns empty', () {
      check(JyotiGPTappMarkdownPreprocessor.toPlainText('   ')).equals('');
    });

    test('removes code blocks, keeps inline code text', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        '```dart\nvoid main() {}\n```\nUse `print` here',
      );
      check(result).not((s) => s.contains('void main'));
      check(result).contains('print');
    });

    test('removes images ![alt](url)', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        'See ![photo](http://img.png) here',
      );
      check(result).not((s) => s.contains('photo'));
      check(result).not((s) => s.contains('http'));
    });

    test('keeps link text [text](url)', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        'Click [here](http://example.com) now',
      );
      check(result).contains('here');
      check(result).not((s) => s.contains('http'));
    });

    test('strips **bold** markers', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        'This is **bold** text',
      );
      check(result).contains('bold');
      check(result).not((s) => s.contains('**'));
    });

    test('strips ***bold italic*** markers', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        'This is ***important*** text',
      );
      check(result).contains('important');
      check(result).not((s) => s.contains('***'));
    });

    test('strips ~~strikethrough~~ markers', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        'This is ~~deleted~~ text',
      );
      check(result).contains('deleted');
      check(result).not((s) => s.contains('~~'));
    });

    test('strips # heading markers', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        '## My Heading\nParagraph',
      );
      check(result).contains('My Heading');
      check(result).not((s) => s.contains('##'));
    });

    test('strips list markers (-, *, 1.)', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        '- item one\n* item two\n1. item three',
      );
      check(result).contains('item one');
      check(result).contains('item two');
      check(result).contains('item three');
    });

    test('strips > blockquote markers', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        '> quoted text',
      );
      check(result).contains('quoted text');
      check(result).not((s) => s.startsWith('>'));
    });

    test('removes HTML tags', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        'Hello <b>world</b>',
      );
      check(result).contains('world');
      check(result).not((s) => s.contains('<b>'));
    });

    test('normalizes whitespace', () {
      final result = JyotiGPTappMarkdownPreprocessor.toPlainText(
        'hello   world\n\nnew  paragraph',
      );
      check(result).not((s) => s.contains('  '));
    });
  });

  group('JyotiGPTappMarkdownPreprocessor.softenInlineCode', () {
    test('short input returned unchanged', () {
      final result =
          JyotiGPTappMarkdownPreprocessor.softenInlineCode('short');
      check(result).equals('short');
    });

    test('inserts ZWSP every chunkSize chars for long input', () {
      // Default chunkSize is 24.
      final input = 'a' * 48;
      final result =
          JyotiGPTappMarkdownPreprocessor.softenInlineCode(input);
      // Should have ZWSP at positions 24 and 48.
      check(result).contains('\u200B');
      check(result.length).equals(48 + 2);
    });

    test('custom chunkSize works', () {
      final input = 'abcdefghij'; // length 10
      final result =
          JyotiGPTappMarkdownPreprocessor.softenInlineCode(
        input,
        chunkSize: 5,
      );
      // ZWSP inserted after position 5 and position 10.
      check(result).equals('abcde\u200Bfghij\u200B');
    });
  });
}

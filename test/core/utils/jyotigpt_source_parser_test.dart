import 'package:checks/checks.dart';
import 'package:jyotigptapp/core/utils/jyotigpt_source_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseJyotiGPTSourceList', () {
    group('returns empty list for invalid input', () {
      test('null input', () {
        check(parseJyotiGPTSourceList(null)).isEmpty();
      });

      test('non-list input', () {
        check(parseJyotiGPTSourceList('string')).isEmpty();
        check(parseJyotiGPTSourceList(42)).isEmpty();
        check(parseJyotiGPTSourceList({})).isEmpty();
      });

      test('empty list', () {
        check(parseJyotiGPTSourceList([])).isEmpty();
      });

      test('list of non-maps', () {
        check(parseJyotiGPTSourceList([1, 'a', true])).isEmpty();
      });
    });

    group('parses single source', () {
      test('with id, name, and URL', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {
              'id': 'src-1',
              'name': 'Test Source',
              'url': 'https://example.com',
            },
          },
        ]);

        check(result).length.equals(1);
        check(result.first.id).equals('src-1');
        check(result.first.title).equals('Test Source');
        check(result.first.url).equals('https://example.com');
      });

      test('with top-level fields merged into source', () {
        final result = parseJyotiGPTSourceList([
          {
            'id': 'top-id',
            'name': 'Top Name',
            'url': 'https://top.com',
          },
        ]);

        check(result).length.equals(1);
        check(result.first.id).equals('top-id');
        check(result.first.title).equals('Top Name');
        check(result.first.url).equals('https://top.com');
      });

      test('top-level fields do not override source fields', () {
        final result = parseJyotiGPTSourceList([
          {
            'id': 'top-id',
            'name': 'Top Name',
            'source': {
              'id': 'source-id',
              'name': 'Source Name',
            },
          },
        ]);

        check(result).length.equals(1);
        check(result.first.id).equals('source-id');
        check(result.first.title).equals('Source Name');
      });
    });

    group('deduplicates by ID', () {
      test('two entries with same source ID produce one result', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'same-id', 'name': 'First'},
            'document': ['snippet A'],
          },
          {
            'source': {'id': 'same-id', 'name': 'Second'},
            'document': ['snippet B'],
          },
        ]);

        check(result).length.equals(1);
        check(result.first.id).equals('same-id');
      });

      test('different IDs produce separate results', () {
        final result = parseJyotiGPTSourceList([
          {'source': {'id': 'id-1', 'name': 'First'}},
          {'source': {'id': 'id-2', 'name': 'Second'}},
        ]);

        check(result).length.equals(2);
      });
    });

    group('handles metadata', () {
      test('single metadata object is treated as array of one', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'meta-src'},
            'metadata': {'name': 'Meta Name', 'type': 'web'},
          },
        ]);

        check(result).length.equals(1);
        check(result.first.title).equals('Meta Name');
        check(result.first.type).equals('web');
      });

      test('metadata array', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'meta-src'},
            'metadata': [
              {'name': 'Meta 1'},
              {'name': 'Meta 2'},
            ],
            'document': ['doc1', 'doc2'],
          },
        ]);

        check(result).length.equals(1);
        check(result.first.metadata).isNotNull();
        final items =
            result.first.metadata!['items'] as List<dynamic>;
        check(items.length).equals(2);
      });

      test('metadata with URL extracts url', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'u-src'},
            'metadata': {
              'url': 'https://meta-url.com/page',
            },
          },
        ]);

        check(result).length.equals(1);
        check(result.first.url).equals('https://meta-url.com/page');
      });
    });

    group('generates fallback IDs', () {
      test('missing source ID gets fallback and result id is null',
          () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'name': 'No ID'},
          },
        ]);

        check(result).length.equals(1);
        check(result.first.id).isNull();
        check(result.first.title).equals('No ID');
      });

      test('multiple missing IDs get unique fallbacks', () {
        final result = parseJyotiGPTSourceList([
          {'source': {'name': 'A'}},
          {'source': {'name': 'B'}},
        ]);

        check(result).length.equals(2);
        check(result[0].id).isNull();
        check(result[1].id).isNull();
      });
    });

    group('handles URLs in source.id field', () {
      test('URL as id is used as url and name', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'https://example.com/article'},
          },
        ]);

        check(result).length.equals(1);
        check(result.first.id).equals('https://example.com/article');
        check(result.first.url)
            .equals('https://example.com/article');
        check(result.first.title)
            .equals('https://example.com/article');
      });
    });

    group('extracts documents/snippets', () {
      test('document list items become snippets', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'doc-src'},
            'document': ['This is the snippet text.'],
          },
        ]);

        check(result).length.equals(1);
        check(result.first.snippet)
            .equals('This is the snippet text.');
      });

      test('empty document list yields null snippet', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'empty-doc'},
            'document': <String>[],
          },
        ]);

        check(result).length.equals(1);
        check(result.first.snippet).isNull();
      });

      test('whitespace-only documents yield null snippet', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'ws-doc'},
            'document': ['   '],
          },
        ]);

        check(result).length.equals(1);
        check(result.first.snippet).isNull();
      });

      test('multiple documents are accumulated', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'multi-doc'},
            'document': ['first', 'second'],
          },
        ]);

        check(result).length.equals(1);
        check(result.first.snippet).equals('first');
        final docs =
            result.first.metadata!['documents'] as List<dynamic>;
        check(docs).length.equals(2);
      });
    });

    group('type extraction', () {
      test('type from source', () {
        final result = parseJyotiGPTSourceList([
          {
            'source': {'id': 'typed', 'type': 'file'},
          },
        ]);

        check(result.first.type).equals('file');
      });

      test('type from top-level entry', () {
        final result = parseJyotiGPTSourceList([
          {
            'id': 'typed',
            'type': 'collection',
          },
        ]);

        check(result.first.type).equals('collection');
      });
    });
  });
}

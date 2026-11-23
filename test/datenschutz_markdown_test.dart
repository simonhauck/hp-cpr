import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/features/datenschutz/domain/datenschutz_markdown.dart';

void main() {
  group('parseDatenschutzMarkdown', () {
    test('parses headings and strips the bold markers around them', () {
      final blocks = parseDatenschutzMarkdown(
        '# **Titel**\n\n## **1. Abschnitt**\n',
      );

      expect(blocks.map((b) => b.headingLevel), [1, 2]);
      expect(blocks.map((b) => b.plainText), ['Titel', '1. Abschnitt']);
      expect(blocks.every((b) => b.spans.every((s) => s.bold)), isTrue);
    });

    test('joins the lines of a paragraph and splits on blank lines', () {
      final blocks = parseDatenschutzMarkdown('Eins\nzwei\n\nDrei\n');

      expect(blocks.map((b) => b.plainText), ['Eins zwei', 'Drei']);
      expect(blocks.any((b) => b.isHeading), isFalse);
    });

    test('parses bold spans inside a paragraph', () {
      final blocks = parseDatenschutzMarkdown('Ein **fetter** Text');

      expect(blocks.single.spans, const [
        DatenschutzSpan('Ein '),
        DatenschutzSpan('fetter', bold: true),
        DatenschutzSpan(' Text'),
      ]);
    });

    test('parses a whole bold paragraph', () {
      final blocks = parseDatenschutzMarkdown('**Alles fett.**');

      expect(blocks.single.spans, const [
        DatenschutzSpan('Alles fett.', bold: true),
      ]);
    });

    test('parses links and keeps the url', () {
      final blocks = parseDatenschutzMarkdown(
        'Siehe [GitHub](https://github.com) jetzt.',
      );

      expect(blocks.single.spans, const [
        DatenschutzSpan('Siehe '),
        DatenschutzSpan('GitHub', url: 'https://github.com'),
        DatenschutzSpan(' jetzt.'),
      ]);
    });

    test('parses a link inside a bold span as bold link', () {
      final blocks = parseDatenschutzMarkdown('**siehe [hier](https://a.de)**');

      expect(blocks.single.spans, const [
        DatenschutzSpan('siehe ', bold: true),
        DatenschutzSpan('hier', bold: true, url: 'https://a.de'),
      ]);
    });

    test('ignores empty input', () {
      expect(parseDatenschutzMarkdown(''), isEmpty);
      expect(parseDatenschutzMarkdown('\n\n'), isEmpty);
    });
  });

  group('bundled Datenschutzerklärung', () {
    List<DatenschutzBlock> load(String name) =>
        parseDatenschutzMarkdown(File('assets/legal/$name').readAsStringSync());

    test('both variants start with the title and have the storage section', () {
      for (final name in ['datenschutz_web.md', 'datenschutz_app.md']) {
        final blocks = load(name);
        final headings = blocks.where((b) => b.isHeading).toList();

        expect(headings.first.plainText, 'Datenschutzerklärung', reason: name);
        expect(
          headings.map((b) => b.plainText),
          contains(endsWith('Speicherung von Daten auf Ihrem Gerät')),
          reason: name,
        );
        expect(blocks.last.plainText, isNotEmpty);
      }
    });

    test('only the web variant covers server logfiles, GitHub and fonts', () {
      final web = load('datenschutz_web.md').map((b) => b.plainText).join('\n');
      final app = load('datenschutz_app.md').map((b) => b.plainText).join('\n');

      expect(web, contains('Google Fonts'));
      expect(web, contains('Logfiles'));
      expect(app, isNot(contains('Google Fonts')));
      expect(app, isNot(contains('Logfiles')));
      expect(app, isNot(contains('GitHub, Inc.')));
    });

    test('headings are numbered consecutively', () {
      for (final name in ['datenschutz_web.md', 'datenschutz_app.md']) {
        final numbers = [
          for (final block in load(name))
            if (block.headingLevel == 2)
              int.parse(block.plainText.split('.').first),
        ];

        expect(numbers, [for (var i = 1; i <= numbers.length; i++) i]);
      }
    });
  });
}

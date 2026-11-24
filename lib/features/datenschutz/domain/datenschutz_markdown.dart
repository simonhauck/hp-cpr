/// A span of inline text in a [DatenschutzBlock].
class DatenschutzSpan {
  const DatenschutzSpan(this.text, {this.bold = false, this.url});

  final String text;
  final bool bold;

  /// The link target, or null for plain text.
  final String? url;

  @override
  bool operator ==(Object other) =>
      other is DatenschutzSpan &&
      other.text == text &&
      other.bold == bold &&
      other.url == url;

  @override
  int get hashCode => Object.hash(text, bold, url);

  @override
  String toString() => 'DatenschutzSpan($text, bold: $bold, url: $url)';
}

/// A heading or paragraph of the Datenschutzerklärung.
class DatenschutzBlock {
  const DatenschutzBlock({required this.spans, this.headingLevel});

  /// 1 or 2 for headings, null for paragraphs.
  final int? headingLevel;
  final List<DatenschutzSpan> spans;

  bool get isHeading => headingLevel != null;

  String get plainText => spans.map((span) => span.text).join();
}

final _headingPattern = RegExp(r'^(#{1,2})\s+(.*)$');
final _inlinePattern = RegExp(r'\*\*(.+?)\*\*|\[([^\]]+)\]\(([^)\s]+)\)');

/// Parses the Markdown subset used by the bundled Datenschutzerklärung.
///
/// Supported are `#` and `##` headings, paragraphs separated by blank lines,
/// `**bold**` spans (also around a whole paragraph), and `[text](url)` links.
List<DatenschutzBlock> parseDatenschutzMarkdown(String source) {
  final blocks = <DatenschutzBlock>[];
  final paragraph = <String>[];

  void flush() {
    if (paragraph.isEmpty) return;
    blocks.add(
      DatenschutzBlock(spans: _parseInline(paragraph.join(' '), bold: false)),
    );
    paragraph.clear();
  }

  for (final rawLine in source.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      flush();
      continue;
    }
    final heading = _headingPattern.firstMatch(line);
    if (heading != null) {
      flush();
      blocks.add(
        DatenschutzBlock(
          headingLevel: heading.group(1)!.length,
          spans: _parseInline(heading.group(2)!, bold: false),
        ),
      );
      continue;
    }
    paragraph.add(line);
  }
  flush();
  return blocks;
}

List<DatenschutzSpan> _parseInline(String text, {required bool bold}) {
  final spans = <DatenschutzSpan>[];
  var position = 0;

  void addText(String value) {
    if (value.isEmpty) return;
    spans.add(DatenschutzSpan(value, bold: bold));
  }

  for (final match in _inlinePattern.allMatches(text)) {
    addText(text.substring(position, match.start));
    final boldText = match.group(1);
    if (boldText != null) {
      spans.addAll(_parseInline(boldText, bold: true));
    } else {
      spans.add(
        DatenschutzSpan(match.group(2)!, bold: bold, url: match.group(3)),
      );
    }
    position = match.end;
  }
  addText(text.substring(position));
  return spans;
}

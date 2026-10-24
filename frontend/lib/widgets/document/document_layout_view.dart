import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../models/ai/scan_document_result.dart';
import '../../styles/screens/scan/scan_result_screen_styles.dart';
import '../../utils/math_text_formatter.dart';

/// Plain or mixed text: converts only the LaTeX parts, keeps normal text.
String _toReadableMathText(String value) {
  return MathTextFormatter.ensureReadable(value);
}

/// A whole formula as readable symbols. Used when Math.tex can't draw it
/// and for the screen-reader label.
String _formulaToReadable(String formula) {
  return MathTextFormatter.latexToReadable(formula);
}

class DocumentLayoutView extends StatelessWidget {
  const DocumentLayoutView({
    super.key,
    required this.pages,
    required this.useBraille,
    this.fallbackText = '',
    this.fallbackBraille = '',
    this.semanticLabel,
  });

  final List<DocumentPage> pages;
  final bool useBraille;

  final String fallbackText;
  final String fallbackBraille;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (useBraille) {
      return _buildBrailleReadingView();
    }

    final List<DocumentPage> visiblePages = pages
        .where((DocumentPage page) {
          return page.blocks.any((DocumentBlock block) => block.hasContent);
        })
        .toList(growable: false);

    if (visiblePages.isEmpty) {
      return _buildPlainTextFallback();
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Padding(
        padding: ScanResultScreenStyles.contentPreviewPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List<Widget>.generate(visiblePages.length, (int index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visiblePages.length - 1
                    ? 0
                    : ScanResultScreenStyles.documentPageSpacing,
              ),
              child: _ReadableDocumentPage(
                page: visiblePages[index],
                pageNumber: index + 1,
                showPageLabel: visiblePages.length > 1,
              ),
            );
          }, growable: false),
        ),
      ),
    );
  }

  Widget _buildBrailleReadingView() {
    String content = fallbackBraille.trim();

    if (content.isEmpty) {
      content = pages
          .expand((DocumentPage page) => page.blocks)
          .where((DocumentBlock block) => block.hasBraille)
          .map((DocumentBlock block) {
            return block.brailleContent.trim();
          })
          .where((String value) => value.isNotEmpty)
          .join('\n\n');
    }

    if (content.isEmpty) {
      return const Padding(
        padding: ScanResultScreenStyles.layoutUnavailablePadding,
        child: Text(
          'No Braille content is available.',
          textAlign: TextAlign.center,
          style: ScanResultScreenStyles.layoutUnavailableStyle,
        ),
      );
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Padding(
        padding: ScanResultScreenStyles.braillePreviewPadding,
        child: SelectableText(
          content,
          style: ScanResultScreenStyles.brailleContentStyle,
        ),
      ),
    );
  }

  Widget _buildPlainTextFallback() {
    final String content = _normalizeProse(fallbackText);

    if (content.isEmpty) {
      return const Padding(
        padding: ScanResultScreenStyles.layoutUnavailablePadding,
        child: Text(
          'No document content is available.',
          textAlign: TextAlign.center,
          style: ScanResultScreenStyles.layoutUnavailableStyle,
        ),
      );
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Padding(
        padding: ScanResultScreenStyles.contentPreviewPadding,
        child: _ReadableMixedMathContent(content: content),
      ),
    );
  }

  static String _normalizeProse(String value) {
    return value
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r' *\n *'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

typedef WordBraillePair = ({String word, String braille});

final RegExp _wordSeparator = RegExp(r'\s+');

// Liblouis writes each space between words as one blank Braille cell.
final RegExp _brailleWordSeparator = RegExp('[⠀\\s]+');

/// Pairs each word of [text] with the Braille group at the same position
/// in [braille], keeping the lines of [text].
///
/// [text] must be the text the Braille was translated from. In UEB text,
/// Liblouis keeps every space as a blank cell, so word n of the text is
/// group n of the Braille. Returns null when the counts differ; the block
/// is then shown as one unit instead.
@visibleForTesting
List<List<WordBraillePair>>? pairWordsWithBraille(String text, String braille) {
  final List<List<String>> lines = text
      .split('\n')
      .map((String line) {
        return line
            .split(_wordSeparator)
            .where((String word) => word.isNotEmpty)
            .toList(growable: false);
      })
      .where((List<String> words) => words.isNotEmpty)
      .toList(growable: false);

  final List<String> brailleWords = braille
      .split(_brailleWordSeparator)
      .where((String group) => group.isNotEmpty)
      .toList(growable: false);

  final int wordCount = lines.fold(
    0,
    (int count, List<String> words) => count + words.length,
  );

  if (wordCount == 0 || wordCount != brailleWords.length) {
    return null;
  }

  int nextBrailleWord = 0;

  return <List<WordBraillePair>>[
    for (final List<String> words in lines)
      <WordBraillePair>[
        for (final String word in words)
          (word: word, braille: brailleWords[nextBrailleWord++]),
      ],
  ];
}

/// Text and its Braille in one preview.
///
/// UEB text blocks show each word in its own column with its Braille
/// directly beneath; when a block's word and Braille counts differ, it is
/// shown as one unit with its full Braille beneath. Formulas and tables
/// keep their rendered view with their Braille beneath as a full-width
/// unit. The Braille is visual only: screen readers read the words, and
/// the Braille stays available through the screens' Copy Braille action.
class TextBrailleLayoutView extends StatelessWidget {
  const TextBrailleLayoutView({
    super.key,
    required this.pages,
    this.semanticLabel,
  });

  final List<DocumentPage> pages;
  final String? semanticLabel;

  /// Whether [pages] carry Braille per block. Older scans and materials
  /// only have one combined Braille string and keep separate sections.
  static bool canDisplay(List<DocumentPage> pages) {
    return pages.any(
      (DocumentPage page) =>
          page.blocks.any((DocumentBlock block) => block.hasBraille),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DocumentPage> visiblePages = pages
        .where((DocumentPage page) {
          return page.blocks.any((DocumentBlock block) => block.hasContent);
        })
        .toList(growable: false);

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Padding(
        padding: ScanResultScreenStyles.contentPreviewPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (
              int index = 0;
              index < visiblePages.length;
              index++
            ) ...<Widget>[
              if (index > 0)
                const SizedBox(
                  height: ScanResultScreenStyles.documentPageSpacing,
                ),
              if (visiblePages.length > 1) ...<Widget>[
                Text(
                  'Page ${index + 1}',
                  style: ScanResultScreenStyles.documentPageLabelStyle,
                ),
                const SizedBox(
                  height: ScanResultScreenStyles.documentPageLabelSpacing,
                ),
              ],
              ..._buildBlocks(visiblePages[index]),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBlocks(DocumentPage page) {
    final List<Widget> widgets = <Widget>[];

    for (final DocumentBlock block in page.blocks) {
      if (!block.hasContent) {
        continue;
      }

      if (widgets.isNotEmpty) {
        widgets.add(
          const SizedBox(height: ScanResultScreenStyles.unifiedBlockSpacing),
        );
      }

      widgets.add(_TextBrailleBlock(block: block));
    }

    return widgets;
  }
}

class _TextBrailleBlock extends StatelessWidget {
  const _TextBrailleBlock({required this.block});

  final DocumentBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.isHeldForReview) {
      return _HeldForReviewBlock(block: block);
    }

    final String content = _ReadableDocumentPage.readableBlockContent(block);
    final String braille = block.hasBraille ? block.brailleContent.trim() : '';

    if (block.hasTableData) {
      return _BlockWithBraille(
        braille: braille,
        child: _ReadableDocumentTable(block: block, fallbackContent: content),
      );
    }

    // Word pairs only for plain UEB text. Text with math markup keeps its
    // rendered math, so it is shown as one unit.
    final bool isPlainUebText =
        braille.isNotEmpty &&
        block.isUebBraille &&
        !block.isFormula &&
        !RegExp(r'\\[A-Za-z]+').hasMatch(content) &&
        !_ReadableMixedMathContent.inlineMathPattern.hasMatch(content);

    if (isPlainUebText) {
      // The Braille was translated from the normalized content.
      final List<List<WordBraillePair>>? lines = pairWordsWithBraille(
        block.normalizedContent,
        braille,
      );

      if (lines != null) {
        return _WordBrailleLines(lines: lines);
      }
    }

    return _BlockWithBraille(
      braille: braille,
      child: _ReadableDocumentPage.isStandaloneFormula(block)
          ? _ReadableFormula(content: content)
          : _ReadableMixedMathContent(content: content),
    );
  }
}

/// Lines of word columns. A column moves to the next row as a whole, so a
/// word never separates from its Braille.
class _WordBrailleLines extends StatelessWidget {
  const _WordBrailleLines({required this.lines});

  final List<List<WordBraillePair>> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < lines.length; index++) ...<Widget>[
          if (index > 0)
            const SizedBox(height: ScanResultScreenStyles.wordRowSpacing),
          Wrap(
            spacing: ScanResultScreenStyles.wordColumnSpacing,
            runSpacing: ScanResultScreenStyles.wordRowSpacing,
            children: <Widget>[
              for (final WordBraillePair pair in lines[index])
                _WordBrailleColumn(pair: pair),
            ],
          ),
        ],
      ],
    );
  }
}

class _WordBrailleColumn extends StatelessWidget {
  const _WordBrailleColumn({required this.pair});

  final WordBraillePair pair;

  @override
  Widget build(BuildContext context) {
    // Each column is its own screen reader stop that reads the word only,
    // not the Braille dot patterns.
    return Semantics(
      container: true,
      label: pair.word,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(pair.word, style: ScanResultScreenStyles.recognizedContentStyle),
          const SizedBox(height: ScanResultScreenStyles.wordBrailleSpacing),
          Text(pair.braille, style: ScanResultScreenStyles.brailleContentStyle),
        ],
      ),
    );
  }
}

/// A block the AI service held for review: readable text, with a note that
/// no Braille was produced and a toggle for the original LaTeX. Screen
/// readers read the readable text and the note.
@visibleForTesting
const String heldForReviewNote =
    'Needs review: no Braille was produced for this part. '
    'Compare it with the printed page.';

@visibleForTesting
const String showOriginalLabel = 'Show original';

@visibleForTesting
const String hideOriginalLabel = 'Hide original';

class _HeldForReviewBlock extends StatefulWidget {
  const _HeldForReviewBlock({required this.block});

  final DocumentBlock block;

  @override
  State<_HeldForReviewBlock> createState() => _HeldForReviewBlockState();
}

class _HeldForReviewBlockState extends State<_HeldForReviewBlock> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final DocumentBlock block = widget.block;
    final String original = block.rawContent.trim();
    final String readable = block.normalizedContent.trim().isNotEmpty
        ? block.normalizedContent.trim()
        : original;

    // Records saved before readable text existed show the LaTeX itself,
    // so there is nothing separate to reveal.
    final bool hasSeparateOriginal =
        original.isNotEmpty && original != readable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SelectableText(
          readable,
          style: ScanResultScreenStyles.recognizedContentStyle,
        ),
        if (hasSeparateOriginal) ...<Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              style: ScanResultScreenStyles.showOriginalButtonStyle,
              onPressed: () {
                setState(() {
                  _showOriginal = !_showOriginal;
                });
              },
              child: Text(
                _showOriginal ? hideOriginalLabel : showOriginalLabel,
              ),
            ),
          ),
          if (_showOriginal)
            SelectableText(
              original,
              style: ScanResultScreenStyles.originalLatexStyle,
            ),
        ],
        const SizedBox(height: ScanResultScreenStyles.reviewNoteSpacing),
        Container(
          padding: ScanResultScreenStyles.reviewNotePadding,
          decoration: const BoxDecoration(
            color: ScanResultScreenStyles.reviewNoteBackgroundColor,
            borderRadius: ScanResultScreenStyles.reviewNoteRadius,
            border: ScanResultScreenStyles.reviewNoteBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                ScanResultScreenStyles.reviewNoteIcon,
                size: ScanResultScreenStyles.reviewNoteIconSize,
                color: ScanResultScreenStyles.primaryColor,
              ),
              const SizedBox(width: ScanResultScreenStyles.reviewNoteSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      heldForReviewNote,
                      style: ScanResultScreenStyles.reviewNoteStyle,
                    ),
                    Text(
                      'Reason: ${block.reviewReason}',
                      style: ScanResultScreenStyles.reviewReasonStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A block shown as one unit with its full Braille beneath it.
class _BlockWithBraille extends StatelessWidget {
  const _BlockWithBraille({required this.child, required this.braille});

  final Widget child;
  final String braille;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        child,
        if (braille.isNotEmpty) ...<Widget>[
          const SizedBox(height: ScanResultScreenStyles.wordBrailleSpacing),
          ExcludeSemantics(
            child: Text(
              braille,
              style: ScanResultScreenStyles.brailleContentStyle,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReadableDocumentPage extends StatelessWidget {
  const _ReadableDocumentPage({
    required this.page,
    required this.pageNumber,
    required this.showPageLabel,
  });

  final DocumentPage page;
  final int pageNumber;
  final bool showPageLabel;

  @override
  Widget build(BuildContext context) {
    final List<Widget> contentWidgets = _buildReadableContent();

    if (contentWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showPageLabel) ...<Widget>[
          Text(
            'Page $pageNumber',
            style: ScanResultScreenStyles.documentPageLabelStyle,
          ),
          const SizedBox(
            height: ScanResultScreenStyles.documentPageLabelSpacing,
          ),
        ],
        ...contentWidgets,
      ],
    );
  }

  List<Widget> _buildReadableContent() {
    final List<Widget> widgets = <Widget>[];
    final List<String> pendingContent = <String>[];

    DocumentBlock? previousBlock;

    // A bbox is usable only when it contains four ordered coordinates:
    // [left, top, right, bottom].
    bool hasValidBox(DocumentBlock block) {
      final List<double> box = block.boundingBox;

      return box.length >= 4 &&
          box.take(4).every((double value) => value.isFinite) &&
          box[2] > box[0] &&
          box[3] > box[1];
    }

    double blockHeight(DocumentBlock block) {
      return block.boundingBox[3] - block.boundingBox[1];
    }

    void flushPendingContent() {
      if (pendingContent.isEmpty) {
        return;
      }

      final String combinedContent = pendingContent
          .where((String value) => value.trim().isNotEmpty)
          .join(' ')
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .trim();

      pendingContent.clear();

      if (combinedContent.isEmpty) {
        return;
      }

      _addWithSpacing(
        widgets,
        _ReadableMixedMathContent(content: combinedContent),
      );
    }

    bool startsNewParagraph(DocumentBlock previous, DocumentBlock current) {
      // If OCR did not provide usable positions, do not invent a break.
      if (!hasValidBox(previous) || !hasValidBox(current)) {
        return false;
      }

      final List<double> a = previous.boundingBox;
      final List<double> b = current.boundingBox;

      final double averageHeight =
          (blockHeight(previous) + blockHeight(current)) / 2;

      // Positive vertical distance between the previous block's
      // bottom edge and the current block's top edge.
      final double verticalGap = b[1] - a[3];

      // Blocks that overlap vertically are likely on the same
      // printed line, even if OCR returned them separately.
      if (verticalGap <= 0) {
        return false;
      }

      // A gap noticeably larger than the typical text height
      // is an indication of a paragraph or section break.
      if (verticalGap > averageHeight * 0.75) {
        return true;
      }

      // An indented block following an earlier line may indicate
      // the start of a new paragraph.
      if (page.width > 0) {
        final double indentation = b[0] - a[0];
        final double minimumIndent = page.width * 0.035;

        if (indentation > minimumIndent && verticalGap > averageHeight * 0.15) {
          return true;
        }
      }

      return false;
    }

    for (final DocumentBlock block in page.blocks) {
      if (block.isHeldForReview) {
        flushPendingContent();
        _addWithSpacing(widgets, _HeldForReviewBlock(block: block));
        previousBlock = null;
        continue;
      }

      final String content = readableBlockContent(block);

      if (block.hasTableData) {
        flushPendingContent();

        _addWithSpacing(
          widgets,
          _ReadableDocumentTable(block: block, fallbackContent: content),
        );

        previousBlock = null;
        continue;
      }

      if (content.isEmpty) {
        continue;
      }

      if (isStandaloneFormula(block)) {
        flushPendingContent();

        _addWithSpacing(widgets, _ReadableFormula(content: content));

        previousBlock = null;
        continue;
      }

      if (previousBlock != null && startsNewParagraph(previousBlock, block)) {
        flushPendingContent();
      }

      pendingContent.add(content);
      previousBlock = block;
    }

    flushPendingContent();

    return widgets;
  }

  void _addWithSpacing(List<Widget> widgets, Widget child) {
    if (widgets.isNotEmpty) {
      widgets.add(
        const SizedBox(height: ScanResultScreenStyles.unifiedBlockSpacing),
      );
    }

    widgets.add(child);
  }

  static bool isStandaloneFormula(DocumentBlock block) {
    // Keep explicitly identified display equations separate.
    // An inline formula should remain with its surrounding text.
    return block.type == 'display_formula';
  }

  /// The content shown for [block]: readable text, or LaTeX marked for
  /// rendering when the block contains math.
  static String readableBlockContent(DocumentBlock block) {
    final String normalizedContent = block.normalizedContent.trim();
    final String rawContent = block.rawContent.trim();

    final String content = normalizedContent.isNotEmpty
        ? normalizedContent
        : rawContent;

    final String formulaContent = rawContent.isNotEmpty ? rawContent : content;

    if (formulaContent.isEmpty) {
      return content;
    }

    if (_containsMixedMathContent(formulaContent)) {
      return formulaContent;
    }

    if (_shouldRenderAsFormula(block, formulaContent)) {
      final String formula = formulaContent
          .replaceAll('```latex', '')
          .replaceAll('```math', '')
          .replaceAll('```', '')
          .trim();

      if (formula.isEmpty) {
        return content;
      }

      // Do not add another pair of delimiters if OCR already
      // supplied a complete marked math expression.
      if (_ReadableMixedMathContent.inlineMathPattern.hasMatch(formula)) {
        return formula;
      }

      // Math can't span line breaks; join OCR pieces onto one line.
      return r'$' + formula.replaceAll(RegExp(r'\s*\n\s*'), ' ') + r'$';
    }

    // Preserve raw LaTeX commands when normalization removed
    // information needed for visual math rendering.
    return RegExp(r'\\[A-Za-z]+').hasMatch(formulaContent)
        ? formulaContent
        : content;
  }

  static bool _containsMixedMathContent(String content) {
    final Iterable<RegExpMatch> matches = _ReadableMixedMathContent
        .inlineMathPattern
        .allMatches(content);

    if (matches.isEmpty) {
      return false;
    }

    final String prose = content
        .replaceAll(_ReadableMixedMathContent.inlineMathPattern, ' ')
        .replaceAll(r'$', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return prose.isNotEmpty;
  }

  static bool _shouldRenderAsFormula(DocumentBlock block, String content) {
    if (content.isEmpty) {
      return false;
    }

    final String compactContent = content.replaceAll(RegExp(r'\s+'), '');

    final bool hasLatexCommand = RegExp(r'\\[A-Za-z]+').hasMatch(content);

    // Render LaTeX even when the backend mistakenly labels it as text.
    if (hasLatexCommand) {
      return true;
    }

    final bool hasRelation = RegExp(r'[=<>≤≥≠]').hasMatch(content);

    final bool hasOperation = RegExp(
      r'[A-Za-z0-9)\]}][+\-*/^_][A-Za-z0-9(\[{]',
    ).hasMatch(compactContent);

    final bool hasFunctionNotation = RegExp(
      r'\b[A-Za-z]\s*\([^)]*\)',
    ).hasMatch(content);

    final int naturalWordCount = RegExp(
      r'[A-Za-z]{3,}',
    ).allMatches(content).length;

    if (block.isFormula) {
      return hasRelation ||
          hasOperation ||
          hasFunctionNotation ||
          naturalWordCount < 3;
    }

    return naturalWordCount <= 1 &&
        (hasRelation || hasOperation || hasFunctionNotation);
  }
}

class _ReadableMixedMathContent extends StatelessWidget {
  const _ReadableMixedMathContent({required this.content});

  final String content;

  static final RegExp inlineMathPattern = RegExp(
    r'\$\$([\s\S]*?)\$\$'
    r'|\$([^$]+?)\$'
    r'|\\\[([\s\S]*?)\\\]'
    r'|\\\(([\s\S]*?)\\\)',
  );

  static String _cleanFormula(String value) {
    String formula = value
        .replaceAll('```latex', '')
        .replaceAll('```math', '')
        .replaceAll('```', '')
        .trim();

    if (formula.startsWith(r'$$') && formula.endsWith(r'$$')) {
      formula = formula.substring(2, formula.length - 2).trim();
    } else if (formula.startsWith(r'$') && formula.endsWith(r'$')) {
      formula = formula.substring(1, formula.length - 1).trim();
    } else if (formula.startsWith(r'\[') && formula.endsWith(r'\]')) {
      formula = formula.substring(2, formula.length - 2).trim();
    } else if (formula.startsWith(r'\(') && formula.endsWith(r'\)')) {
      formula = formula.substring(2, formula.length - 2).trim();
    }

    return formula;
  }

  static TextSpan _textSpan(String value) {
    final String readable = _toReadableMathText(value);

    final bool hasLeadingSpace =
        value.isNotEmpty && RegExp(r'^\s').hasMatch(value);

    final bool hasTrailingSpace =
        value.isNotEmpty && RegExp(r'\s$').hasMatch(value);

    return TextSpan(
      text:
          '${hasLeadingSpace ? ' ' : ''}'
          '$readable'
          '${hasTrailingSpace ? ' ' : ''}',
    );
  }

  static InlineSpan _formulaSpan(String value) {
    final String formula = _cleanFormula(value);

    if (formula.isEmpty) {
      return const TextSpan(text: '');
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Math.tex(
        formula,
        mathStyle: MathStyle.text,
        textStyle: ScanResultScreenStyles.recognizedContentStyle,
        onErrorFallback: (_) {
          return Text(
            _formulaToReadable(formula),
            style: ScanResultScreenStyles.recognizedContentStyle,
          );
        },
      ),
    );
  }

  static List<InlineSpan> _parseLine(String line) {
    final List<InlineSpan> spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final RegExpMatch match in inlineMathPattern.allMatches(line)) {
      if (match.start > currentIndex) {
        spans.add(_textSpan(line.substring(currentIndex, match.start)));
      }

      final String formula =
          match.group(1) ??
          match.group(2) ??
          match.group(3) ??
          match.group(4) ??
          '';

      spans.add(_formulaSpan(formula));

      currentIndex = match.end;
    }

    if (currentIndex < line.length) {
      spans.add(_textSpan(line.substring(currentIndex)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final String normalizedContent = content
        .replaceAll('```latex', '')
        .replaceAll('```math', '')
        .replaceAll('```', '')
        .trim();

    if (normalizedContent.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<InlineSpan> spans = <InlineSpan>[];

    final List<String> lines = normalizedContent.split('\n');

    for (int index = 0; index < lines.length; index++) {
      if (index > 0) {
        spans.add(const TextSpan(text: '\n'));
      }

      spans.addAll(_parseLine(lines[index]));
    }

    return SelectableText.rich(
      TextSpan(
        style: ScanResultScreenStyles.recognizedContentStyle,
        children: spans,
      ),
      textAlign: TextAlign.start,
    );
  }
}

class _ReadableFormula extends StatelessWidget {
  const _ReadableFormula({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final String formula = _prepareFormula(content);

    if (formula.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Mathematical expression: ${_formulaToReadable(formula)}',
      child: Padding(
        padding: ScanResultScreenStyles.formulaPreviewPadding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Math.tex(
            formula,
            mathStyle: MathStyle.display,
            textStyle: ScanResultScreenStyles.formulaContentStyle,
            onErrorFallback: (_) {
              return SelectableText(
                _formulaToReadable(formula),
                style: ScanResultScreenStyles.formulaContentStyle,
              );
            },
          ),
        ),
      ),
    );
  }

  String _prepareFormula(String value) {
    String formula = value.trim();

    formula = formula
        .replaceAll('```latex', '')
        .replaceAll('```math', '')
        .replaceAll('```', '')
        .trim();

    if (formula.startsWith(r'\[') && formula.endsWith(r'\]')) {
      formula = formula.substring(2, formula.length - 2).trim();
    }

    if (formula.startsWith(r'\(') && formula.endsWith(r'\)')) {
      formula = formula.substring(2, formula.length - 2).trim();
    }

    if (formula.startsWith(r'$$') && formula.endsWith(r'$$')) {
      formula = formula.substring(2, formula.length - 2).trim();
    } else if (formula.startsWith(r'$') && formula.endsWith(r'$')) {
      formula = formula.substring(1, formula.length - 1).trim();
    }

    return formula;
  }
}

class _ReadableDocumentTable extends StatelessWidget {
  const _ReadableDocumentTable({
    required this.block,
    required this.fallbackContent,
  });

  final DocumentBlock block;
  final String fallbackContent;

  @override
  Widget build(BuildContext context) {
    final List<List<String>> rows = block.tableRows;

    if (rows.isEmpty) {
      return SelectableText(
        fallbackContent,
        style: ScanResultScreenStyles.recognizedContentStyle,
      );
    }

    int columnCount = 0;

    for (final List<String> row in rows) {
      columnCount = math.max(columnCount, row.length);
    }

    if (columnCount == 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : columnCount * ScanResultScreenStyles.tableMinimumColumnWidth;

        final double tableWidth = math.max(
          availableWidth,
          columnCount * ScanResultScreenStyles.tableMinimumColumnWidth,
        );

        return ClipRRect(
          borderRadius: ScanResultScreenStyles.tableRadius,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: tableWidth,
              decoration: const BoxDecoration(
                color: ScanResultScreenStyles.tableBackgroundColor,
                border: ScanResultScreenStyles.tableOuterBorder,
              ),
              child: Table(
                border: TableBorder.all(
                  color: ScanResultScreenStyles.tableBorderColor,
                  width: ScanResultScreenStyles.tableBorderWidth,
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: List<TableRow>.generate(rows.length, (int rowIndex) {
                  final List<String> row = rows[rowIndex];

                  return TableRow(
                    decoration: BoxDecoration(
                      color: rowIndex == 0
                          ? ScanResultScreenStyles.tableLabelBackgroundColor
                          : rowIndex.isEven
                          ? ScanResultScreenStyles.tableAlternatingRowColor
                          : ScanResultScreenStyles.tableBackgroundColor,
                    ),
                    children: List<Widget>.generate(columnCount, (
                      int columnIndex,
                    ) {
                      final String cell = columnIndex < row.length
                          ? row[columnIndex]
                          : '';

                      return Padding(
                        padding: ScanResultScreenStyles.tableCellPadding,
                        child: SelectableText(
                          cell,
                          style: rowIndex == 0
                              ? ScanResultScreenStyles.tableLabelTextStyle
                              : ScanResultScreenStyles.tableCellTextStyle,
                        ),
                      );
                    }, growable: false),
                  );
                }, growable: false),
              ),
            ),
          ),
        );
      },
    );
  }
}

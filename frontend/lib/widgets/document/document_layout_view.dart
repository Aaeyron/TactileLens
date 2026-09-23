import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../models/ai/scan_document_result.dart';
import '../../styles/screens/scan/scan_result_screen_styles.dart';

String _toReadableMathText(String value) {
  String result = value
      .replaceAll('```latex', '')
      .replaceAll('```math', '')
      .replaceAll('```', '')
      .replaceAll(r'\[', '')
      .replaceAll(r'\]', '')
      .replaceAll(r'\(', '')
      .replaceAll(r'\)', '')
      .replaceAll(r'$$', '')
      .trim();

  final RegExp fractionPattern = RegExp(
    r'\\(?:dfrac|tfrac|frac)\s*\{([^{}]*)\}\s*\{([^{}]*)\}',
  );

  for (int attempt = 0; attempt < 5; attempt++) {
    final String converted = result.replaceAllMapped(fractionPattern, (
      Match match,
    ) {
      return '(${match.group(1)})⁄(${match.group(2)})';
    });

    if (converted == result) {
      break;
    }

    result = converted;
  }

  result = result.replaceAllMapped(
    RegExp(r'\\sqrt\s*\[([^\]]+)\]\s*\{([^{}]*)\}'),
    (Match match) => '${match.group(1)}√(${match.group(2)})',
  );

  result = result.replaceAllMapped(
    RegExp(r'\\sqrt\s*\{([^{}]*)\}'),
    (Match match) => '√(${match.group(1)})',
  );

  result = result.replaceAllMapped(
    RegExp(
      r'\\(?:text|textrm|mathrm|mathbf|mathit|operatorname)\s*\{([^{}]*)\}',
    ),
    (Match match) => match.group(1) ?? '',
  );

  const Map<String, String> replacements = <String, String>{
    r'\leq': '≤',
    r'\le': '≤',
    r'\geq': '≥',
    r'\ge': '≥',
    r'\neq': '≠',
    r'\ne': '≠',
    r'\times': '×',
    r'\div': '÷',
    r'\cdot': '·',
    r'\pm': '±',
    r'\sum': '∑',
    r'\prod': '∏',
    r'\int': '∫',
    r'\infty': '∞',
    r'\pi': 'π',
    r'\theta': 'θ',
    r'\alpha': 'α',
    r'\beta': 'β',
    r'\left': '',
    r'\right': '',
    r'\,': ' ',
    r'\;': ' ',
    r'\:': ' ',
    r'\!': '',
    r'\quad': ' ',
    r'\qquad': '  ',
  };

  replacements.forEach((String source, String replacement) {
    result = result.replaceAll(source, replacement);
  });

  result = result.replaceAllMapped(
    RegExp(r'\^\{?(-?\d+)\}?'),
    (Match match) => _toSuperscript(match.group(1) ?? ''),
  );

  return result
      .replaceAllMapped(
        RegExp(r'\\([A-Za-z]+)'),
        (Match match) => match.group(1) ?? '',
      )
      .replaceAll('{', '(')
      .replaceAll('}', ')')
      .replaceAll(r'\_', '_')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
}

String _toSuperscript(String value) {
  const Map<String, String> characters = <String, String>{
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '-': '⁻',
  };

  return value
      .split('')
      .map((String character) => characters[character] ?? character)
      .join();
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
    final String content = _toReadableMathText(_normalizeProse(fallbackText));

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
        child: SelectableText(
          content,
          style: ScanResultScreenStyles.recognizedContentStyle,
        ),
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
    final List<String> pendingText = <String>[];

    void flushPendingText() {
      if (pendingText.isEmpty) {
        return;
      }

      final String combinedText = pendingText
          .map(_normalizeTextBlock)
          .where((String value) => value.isNotEmpty)
          .join(' ')
          .replaceAll(RegExp(r' {2,}'), ' ')
          .trim();

      pendingText.clear();

      if (combinedText.isEmpty) {
        return;
      }

      _addWithSpacing(
        widgets,
        SelectableText(
          combinedText,
          style: ScanResultScreenStyles.recognizedContentStyle,
        ),
      );
    }

    for (final DocumentBlock block in page.blocks) {
      final String normalizedContent = block.normalizedContent.trim();
      final String rawContent = block.rawContent.trim();

      final String content = normalizedContent.isNotEmpty
          ? normalizedContent
          : rawContent;

      final String formulaContent = rawContent.isNotEmpty
          ? rawContent
          : content;

      if (block.hasTableData) {
        flushPendingText();

        _addWithSpacing(
          widgets,
          _ReadableDocumentTable(block: block, fallbackContent: content),
        );

        continue;
      }

      if (_containsMixedMathContent(formulaContent)) {
        flushPendingText();

        _addWithSpacing(
          widgets,
          _ReadableMixedMathContent(content: formulaContent),
        );

        continue;
      }

      if (_shouldRenderAsFormula(block, formulaContent)) {
        flushPendingText();

        _addWithSpacing(widgets, _ReadableFormula(content: formulaContent));

        continue;
      }

      if (content.isNotEmpty) {
        pendingText.add(content);
      }
    }

    flushPendingText();

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

  bool _containsMixedMathContent(String content) {
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

  bool _shouldRenderAsFormula(DocumentBlock block, String content) {
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

  String _normalizeTextBlock(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    int contentIndex = 0;

    for (final RegExpMatch match in inlineMathPattern.allMatches(content)) {
      _addText(children, content.substring(contentIndex, match.start));

      final String formula =
          (match.group(1) ??
                  match.group(2) ??
                  match.group(3) ??
                  match.group(4) ??
                  '')
              .trim();

      _addFormula(children, formula);

      contentIndex = match.end;
    }

    final String remainingContent = content.substring(contentIndex);

    // Paddle occasionally omits the final closing dollar sign.
    final int unmatchedDollarIndex = remainingContent.indexOf(r'$');

    if (unmatchedDollarIndex >= 0) {
      _addText(children, remainingContent.substring(0, unmatchedDollarIndex));

      _addFormula(
        children,
        remainingContent
            .substring(unmatchedDollarIndex + 1)
            .replaceAll(r'$', '')
            .trim(),
      );
    } else {
      _addText(children, remainingContent);
    }

    if (children.isEmpty) {
      return SelectableText(
        _toReadableMathText(content),
        style: ScanResultScreenStyles.recognizedContentStyle,
      );
    }

    return Semantics(
      label: _toReadableMathText(content).replaceAll(r'$', ''),
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 8,
        children: children,
      ),
    );
  }

  static void _addText(List<Widget> children, String value) {
    final String normalizedText = _toReadableMathText(
      value,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalizedText.isEmpty) {
      return;
    }

    children.add(
      Text(
        normalizedText,
        style: ScanResultScreenStyles.recognizedContentStyle,
      ),
    );
  }

  static void _addFormula(List<Widget> children, String formula) {
    if (formula.isEmpty) {
      return;
    }

    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Math.tex(
          formula,
          mathStyle: MathStyle.text,
          textStyle: ScanResultScreenStyles.recognizedContentStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
          onErrorFallback: (_) {
            return Text(
              _toReadableMathText(formula),
              style: ScanResultScreenStyles.recognizedContentStyle,
            );
          },
        ),
      ),
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
      label: 'Mathematical expression: ${_toReadableMathText(formula)}',
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
                _toReadableMathText(formula),
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

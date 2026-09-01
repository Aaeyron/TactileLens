import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../models/ai/scan_document_result.dart';

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

  static const double _pageSpacing = 16;
  static const double _minimumPageHeight = 160;
  static const double _minimumBlockSize = 1;
  static const double _minimumFontSize = 6;
  static const double _maximumFontSize = 18;
  static const double _richBlockReferenceWidth = 320;

  static const Color _pageColor = Colors.white;
  static const Color _braillePageColor = Color(0xFFF5F9FF);
  static const Color _borderColor = Color(0xFFD7E0EA);
  static const Color _textColor = Color(0xFF243447);
  static const Color _brailleColor = Color(0xFF294861);
  static const Color _tableBorderColor = Color(0xFFB8C7D6);
  static const Color _tableHeaderColor = Color(0xFFEAF2F8);

  static const BorderRadius _pageRadius = BorderRadius.all(Radius.circular(16));

  static const List<BoxShadow> _pageShadow = <BoxShadow>[
    BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  String get _fallbackContent {
    return useBraille ? fallbackBraille.trim() : fallbackText.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return _buildFallback();
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        children: List<Widget>.generate(pages.length, (int index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == pages.length - 1 ? 0 : _pageSpacing,
            ),
            child: _DocumentLayoutPage(
              page: pages[index],
              useBraille: useBraille,
            ),
          );
        }, growable: false),
      ),
    );
  }

  Widget _buildFallback() {
    if (_fallbackContent.isEmpty) {
      return const Center(
        child: Text(
          'No document content is available.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _brailleColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: useBraille ? _braillePageColor : _pageColor,
        borderRadius: _pageRadius,
        border: Border.all(color: _borderColor),
        boxShadow: _pageShadow,
      ),
      child: SelectableText(
        _fallbackContent,
        style: TextStyle(
          color: useBraille ? _brailleColor : _textColor,
          fontSize: useBraille ? 17 : 15,
          height: useBraille ? 1.5 : 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DocumentLayoutPage extends StatelessWidget {
  const _DocumentLayoutPage({required this.page, required this.useBraille});

  final DocumentPage page;
  final bool useBraille;

  String _contentOf(DocumentBlock block) {
    return useBraille
        ? block.brailleContent.trim()
        : block.normalizedContent.trim();
  }

  bool _hasValidBounds(DocumentBlock block) {
    if (block.boundingBox.length < 4) {
      return false;
    }

    final double left = block.boundingBox[0];
    final double top = block.boundingBox[1];
    final double right = block.boundingBox[2];
    final double bottom = block.boundingBox[3];

    return left.isFinite &&
        top.isFinite &&
        right.isFinite &&
        bottom.isFinite &&
        right > left &&
        bottom > top;
  }

  double _maximumRight() {
    double maximum = 0;

    for (final DocumentBlock block in page.blocks) {
      if (_hasValidBounds(block) && block.boundingBox[2] > maximum) {
        maximum = block.boundingBox[2];
      }
    }

    return maximum;
  }

  double _maximumBottom() {
    double maximum = 0;

    for (final DocumentBlock block in page.blocks) {
      if (_hasValidBounds(block) && block.boundingBox[3] > maximum) {
        maximum = block.boundingBox[3];
      }
    }

    return maximum;
  }

  List<DocumentBlock> get _positionedBlocks {
    return page.blocks
        .where((DocumentBlock block) {
          return _contentOf(block).isNotEmpty && _hasValidBounds(block);
        })
        .toList(growable: false);
  }

  String get _fallbackContent {
    return page.blocks
        .map(_contentOf)
        .where((String content) => content.isNotEmpty)
        .join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final List<DocumentBlock> positionedBlocks = _positionedBlocks;

    if (positionedBlocks.isEmpty) {
      return _buildFallbackPage();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double detectedWidth = _maximumRight();
        final double detectedHeight = _maximumBottom();

        final double sourceWidth = page.width > 0
            ? page.width.toDouble()
            : detectedWidth;

        final double sourceHeight = page.height > 0
            ? page.height.toDouble()
            : detectedHeight;

        if (sourceWidth <= 0 || sourceHeight <= 0) {
          return _buildFallbackPage();
        }

        final double availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : sourceWidth;

        final double scale = availableWidth / sourceWidth;

        final double canvasHeight = (sourceHeight * scale)
            .clamp(DocumentLayoutView._minimumPageHeight, double.infinity)
            .toDouble();

        return Container(
          width: availableWidth,
          height: canvasHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: useBraille
                ? DocumentLayoutView._braillePageColor
                : DocumentLayoutView._pageColor,
            borderRadius: DocumentLayoutView._pageRadius,
            border: Border.all(color: DocumentLayoutView._borderColor),
            boxShadow: DocumentLayoutView._pageShadow,
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: positionedBlocks
                .map((DocumentBlock block) {
                  final double sourceLeft = block.boundingBox[0];
                  final double sourceTop = block.boundingBox[1];
                  final double sourceRight = block.boundingBox[2];
                  final double sourceBottom = block.boundingBox[3];

                  final double left =
                      sourceLeft.clamp(0, sourceWidth).toDouble() * scale;

                  final double top =
                      sourceTop.clamp(0, sourceHeight).toDouble() * scale;

                  final double width = ((sourceRight - sourceLeft) * scale)
                      .clamp(
                        DocumentLayoutView._minimumBlockSize,
                        availableWidth,
                      )
                      .toDouble();

                  final double height = ((sourceBottom - sourceTop) * scale)
                      .clamp(DocumentLayoutView._minimumBlockSize, canvasHeight)
                      .toDouble();

                  final String content = _contentOf(block);

                  final int lineCount = content
                      .split('\n')
                      .length
                      .clamp(1, 1000);

                  final double fontSize = ((height / lineCount) * 0.68)
                      .clamp(
                        DocumentLayoutView._minimumFontSize,
                        DocumentLayoutView._maximumFontSize,
                      )
                      .toDouble();

                  return Positioned(
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                    child: ClipRect(
                      child: Semantics(
                        label: content,
                        child: _PositionedDocumentContent(
                          block: block,
                          content: content,
                          useBraille: useBraille,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        );
      },
    );
  }

  Widget _buildFallbackPage() {
    if (_fallbackContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: useBraille
            ? DocumentLayoutView._braillePageColor
            : DocumentLayoutView._pageColor,
        borderRadius: DocumentLayoutView._pageRadius,
        border: Border.all(color: DocumentLayoutView._borderColor),
        boxShadow: DocumentLayoutView._pageShadow,
      ),
      child: SelectableText(
        _fallbackContent,
        style: TextStyle(
          color: useBraille
              ? DocumentLayoutView._brailleColor
              : DocumentLayoutView._textColor,
          fontSize: useBraille ? 17 : 15,
          height: useBraille ? 1.5 : 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PositionedDocumentContent extends StatelessWidget {
  const _PositionedDocumentContent({
    required this.block,
    required this.content,
    required this.useBraille,
    required this.fontSize,
  });

  final DocumentBlock block;
  final String content;
  final bool useBraille;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (useBraille) {
      return Text(
        content,
        overflow: TextOverflow.clip,
        style: TextStyle(
          color: DocumentLayoutView._brailleColor,
          fontSize: fontSize,
          height: 1.1,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (block.hasTableData) {
      return _buildTable();
    }

    if (block.isFormula) {
      return _buildFormula();
    }

    return Text(
      content,
      overflow: TextOverflow.clip,
      style: TextStyle(
        color: DocumentLayoutView._textColor,
        fontSize: fontSize,
        height: 1.15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFormula() {
    final String formula = _prepareFormula(content);

    if (formula.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: DocumentLayoutView._richBlockReferenceWidth,
          child: Math.tex(
            formula,
            mathStyle: MathStyle.display,
            textStyle: const TextStyle(
              color: DocumentLayoutView._textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            onErrorFallback: (_) {
              return Text(
                _readableFormulaFallback(formula),
                style: const TextStyle(
                  color: DocumentLayoutView._textColor,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    final List<List<String>> rows = block.tableRows;

    if (rows.isEmpty) {
      return Text(
        content,
        overflow: TextOverflow.clip,
        style: TextStyle(
          color: DocumentLayoutView._textColor,
          fontSize: fontSize,
          height: 1.15,
        ),
      );
    }

    int columnCount = 0;

    for (final List<String> row in rows) {
      if (row.length > columnCount) {
        columnCount = row.length;
      }
    }

    if (columnCount == 0) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: DocumentLayoutView._richBlockReferenceWidth,
          child: Table(
            border: TableBorder.all(
              color: DocumentLayoutView._tableBorderColor,
              width: 1,
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: List<TableRow>.generate(rows.length, (int rowIndex) {
              final List<String> row = rows[rowIndex];

              return TableRow(
                decoration: BoxDecoration(
                  color: rowIndex == 0
                      ? DocumentLayoutView._tableHeaderColor
                      : DocumentLayoutView._pageColor,
                ),
                children: List<Widget>.generate(columnCount, (int columnIndex) {
                  final String cell = columnIndex < row.length
                      ? row[columnIndex]
                      : '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    child: Text(
                      cell,
                      style: TextStyle(
                        color: DocumentLayoutView._textColor,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: rowIndex == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  );
                }, growable: false),
              );
            }, growable: false),
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

  String _readableFormulaFallback(String value) {
    return value
        .replaceAll(r'\times', '×')
        .replaceAll(r'\div', '÷')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\cdot', '·')
        .replaceAll(r'\left', '')
        .replaceAll(r'\right', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .trim();
  }
}

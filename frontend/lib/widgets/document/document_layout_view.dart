import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  // Consistent base sizes, independent of OCR bounding-box height.
  static const double _contentFontSize = 14;
  static const double _brailleFontSize = 18;
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
          fontSize: useBraille ? _brailleFontSize : _contentFontSize,
          height: useBraille ? 1.55 : 1.45,
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
        final double sourceWidth = math.max(
          page.width.toDouble(),
          _maximumRight(),
        );

        final double sourceHeight = math.max(
          page.height.toDouble(),
          _maximumBottom(),
        );

        final double availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 360;

        if (availableWidth <= 0 || sourceWidth <= 0 || sourceHeight <= 0) {
          return _buildFallbackPage();
        }

        final List<DocumentBlock> visibleBlocks = page.blocks
            .where((block) => _contentOf(block).isNotEmpty)
            .toList(growable: false);

        final double viewportHeight =
            (sourceHeight * availableWidth / sourceWidth)
                .clamp(220.0, 420.0)
                .toDouble();

        return Container(
          width: availableWidth,
          height: viewportHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: useBraille
                ? DocumentLayoutView._braillePageColor
                : DocumentLayoutView._pageColor,
            borderRadius: DocumentLayoutView._pageRadius,
            border: Border.all(color: DocumentLayoutView._borderColor),
            boxShadow: DocumentLayoutView._pageShadow,
          ),
          child: _ZoomableDocumentCanvas(
            child: _MeasuredDocumentCanvas(
              sourceSize: Size(sourceWidth, sourceHeight),
              minimumWidth: availableWidth,
              bounds: visibleBlocks
                  .map((block) {
                    if (!_hasValidBounds(block)) {
                      return null;
                    }

                    return Rect.fromLTRB(
                      block.boundingBox[0],
                      block.boundingBox[1],
                      block.boundingBox[2],
                      block.boundingBox[3],
                    );
                  })
                  .toList(growable: false),
              children: visibleBlocks
                  .map((block) {
                    return Semantics(
                      sortKey: OrdinalSortKey(block.order.toDouble()),
                      label: _contentOf(block),
                      excludeSemantics: true,
                      child: _PositionedDocumentContent(
                        block: block,
                        content: _contentOf(block),
                        useBraille: useBraille,
                        fontSize: useBraille
                            ? DocumentLayoutView._brailleFontSize
                            : DocumentLayoutView._contentFontSize,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
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
          fontSize: useBraille
              ? DocumentLayoutView._brailleFontSize
              : DocumentLayoutView._contentFontSize,
          height: useBraille ? 1.55 : 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ZoomableDocumentCanvas extends StatefulWidget {
  const _ZoomableDocumentCanvas({required this.child});

  final Widget child;

  @override
  State<_ZoomableDocumentCanvas> createState() {
    return _ZoomableDocumentCanvasState();
  }
}

class _ZoomableDocumentCanvasState extends State<_ZoomableDocumentCanvas> {
  static const double _minimumScale = 1;
  static const double _maximumScale = 8;
  static const double _zoomThreshold = 1.01;

  final TransformationController _transformationController =
      TransformationController();

  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController
      ..removeListener(_handleTransformationChanged)
      ..dispose();

    super.dispose();
  }

  void _handleTransformationChanged() {
    final bool isZoomed =
        _transformationController.value.getMaxScaleOnAxis() > _zoomThreshold;

    if (isZoomed == _isZoomed || !mounted) {
      return;
    }

    setState(() {
      _isZoomed = isZoomed;
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Document preview. Pinch to zoom and drag to inspect.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _resetZoom,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: _minimumScale,
          maxScale: _maximumScale,
          panEnabled: _isZoomed,
          scaleEnabled: true,
          clipBehavior: Clip.hardEdge,
          boundaryMargin: const EdgeInsets.all(40),
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasuredDocumentCanvas extends MultiChildRenderObjectWidget {
  const _MeasuredDocumentCanvas({
    required this.sourceSize,
    required this.minimumWidth,
    required this.bounds,
    required super.children,
  });

  final Size sourceSize;
  final double minimumWidth;
  final List<Rect?> bounds;

  @override
  _RenderDocumentCanvas createRenderObject(BuildContext context) {
    return _RenderDocumentCanvas(sourceSize, minimumWidth, bounds);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDocumentCanvas renderObject,
  ) {
    renderObject.update(sourceSize, minimumWidth, bounds);
  }
}

class _DocumentCanvasParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderDocumentCanvas extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DocumentCanvasParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DocumentCanvasParentData> {
  _RenderDocumentCanvas(this._sourceSize, this._minimumWidth, this._bounds);

  Size _sourceSize;
  double _minimumWidth;
  List<Rect?> _bounds;

  static const double _padding = 20;
  static const double _gap = 12;

  void update(Size sourceSize, double minimumWidth, List<Rect?> bounds) {
    _sourceSize = sourceSize;
    _minimumWidth = minimumWidth;
    _bounds = bounds;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DocumentCanvasParentData) {
      child.parentData = _DocumentCanvasParentData();
    }
  }

  @override
  void performLayout() {
    final List<RenderBox> children = getChildrenAsList();

    double scale = math.max(
      0.001,
      (_minimumWidth - _padding * 2) / _sourceSize.width,
    );

    // Measure actual rendered content before positioning it.
    // Expand page coordinates rather than shrinking individual glyphs.
    for (int i = 0; i < children.length; i++) {
      final RenderBox child = children[i];

      child.layout(const BoxConstraints(), parentUsesSize: true);

      final Rect? box = _bounds[i];

      if (box != null) {
        scale = math.max(scale, (child.size.width + _gap) / box.width);

        scale = math.max(scale, (child.size.height + _gap) / box.height);
      }
    }

    double right = math.max(
      _minimumWidth - _padding,
      _sourceSize.width * scale + _padding,
    );

    double bottom = _sourceSize.height * scale + _padding;

    final List<Rect> placed = <Rect>[];

    final List<int> ordered = List<int>.generate(children.length, (i) => i);

    // Position valid blocks top-to-bottom.
    ordered.sort((a, b) {
      final Rect? first = _bounds[a];
      final Rect? second = _bounds[b];

      if (first == null) {
        return second == null ? a.compareTo(b) : 1;
      }

      if (second == null) {
        return -1;
      }

      final int vertical = first.top.compareTo(second.top);

      return vertical != 0 ? vertical : first.left.compareTo(second.left);
    });

    for (final int i in ordered) {
      final RenderBox child = children[i];
      final Rect? box = _bounds[i];

      final double left = box == null
          ? _padding
          : math.max(0.0, box.left) * scale + _padding;

      double top = box == null
          ? bottom + _gap
          : math.max(0.0, box.top) * scale + _padding;

      Rect target = Offset(left, top) & child.size;

      // If OCR boxes overlap, move only colliding content downward.
      // Keep the horizontal column position.
      bool collision;

      do {
        collision = false;

        for (final Rect other in placed) {
          if (target.overlaps(other.inflate(_gap / 2))) {
            top = other.bottom + _gap;
            target = Offset(left, top) & child.size;
            collision = true;
          }
        }
      } while (collision);

      final _DocumentCanvasParentData data =
          child.parentData! as _DocumentCanvasParentData;

      data.offset = target.topLeft;

      placed.add(target);

      right = math.max(right, target.right);
      bottom = math.max(bottom, target.bottom);
    }

    size = constraints.constrain(Size(right + _padding, bottom + _padding));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final _DocumentCanvasParentData data =
        child.parentData! as _DocumentCanvasParentData;

    transform.translateByDouble(data.offset.dx, data.offset.dy, 0, 1);
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
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: DocumentLayoutView._richBlockReferenceWidth,
        ),
        child: Text(
          content,
          style: TextStyle(
            color: DocumentLayoutView._brailleColor,
            fontSize: fontSize,
            height: 1.41,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (block.hasTableData) {
      return _buildTable();
    }

    if (block.isFormula) {
      return _buildFormula();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: DocumentLayoutView._richBlockReferenceWidth,
      ),
      child: Text(
        content,
        style: TextStyle(
          color: DocumentLayoutView._textColor,
          fontSize: fontSize,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFormula() {
    final String formula = _prepareFormula(content);

    if (formula.isEmpty) {
      return const SizedBox.shrink();
    }

    // No FittedBox: equations use the same base size as ordinary text.
    return Math.tex(
      formula,
      mathStyle: MathStyle.display,
      textStyle: TextStyle(
        color: DocumentLayoutView._textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
      onErrorFallback: (_) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DocumentLayoutView._richBlockReferenceWidth,
          ),
          child: Text(
            // Preserve the notation when LaTeX parsing fails.
            formula,
            style: TextStyle(
              color: DocumentLayoutView._textColor,
              fontSize: fontSize,
              height: 1.35,
            ),
          ),
        );
      },
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

    return SizedBox(
      width: math.max(
        DocumentLayoutView._richBlockReferenceWidth,
        columnCount * 140.0,
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Text(
                  cell,
                  style: TextStyle(
                    color: DocumentLayoutView._textColor,
                    fontSize: fontSize,
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

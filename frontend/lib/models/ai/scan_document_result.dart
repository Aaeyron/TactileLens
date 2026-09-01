import '../../utils/document_reading_order.dart';

class ScanDocumentResult {
  const ScanDocumentResult({
    required this.model,
    required this.pipelineVersion,
    required this.device,
    required this.pageCount,
    required this.processingTimeMs,
    required this.blocks,
    required this.pages,
  });

  final String model;
  final String pipelineVersion;
  final String device;
  final int pageCount;
  final double processingTimeMs;
  final List<DocumentBlock> blocks;
  final List<DocumentPage> pages;

  factory ScanDocumentResult.fromJson(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw const FormatException('The document scan was not successful.');
    }

    final dynamic rawBlocks = json['blocks'];

    if (rawBlocks is! List) {
      throw const FormatException(
        'The document scan response does not contain valid blocks.',
      );
    }

    final List<DocumentPage> pages = _parsePages(json['pages']);

    final List<DocumentBlock> parsedBlocks = _parseBlocks(rawBlocks);

    final List<DocumentBlock> orderedBlocks = pages.isNotEmpty
        ? pages
              .expand((DocumentPage page) => page.blocks)
              .toList(growable: false)
        : DocumentReadingOrder.sort<DocumentBlock>(
            blocks: parsedBlocks,
            boundingBoxOf: (DocumentBlock block) => block.boundingBox,
          );

    final int reportedPageCount = _readInteger(json['page_count']);

    return ScanDocumentResult(
      model: _readString(json['model']),
      pipelineVersion: _readString(json['pipeline_version']),
      device: _readString(json['device']),
      pageCount: reportedPageCount > 0 ? reportedPageCount : pages.length,
      processingTimeMs: _readDouble(json['processing_time_ms']),
      blocks: List<DocumentBlock>.unmodifiable(orderedBlocks),
      pages: List<DocumentPage>.unmodifiable(pages),
    );
  }

  bool get hasContent {
    return blocks.any((DocumentBlock block) => block.hasContent);
  }

  bool get hasText {
    return blocks.any((DocumentBlock block) => block.isText);
  }

  bool get hasFormulas {
    return blocks.any((DocumentBlock block) => block.isFormula);
  }

  bool get hasTables {
    return blocks.any((DocumentBlock block) => block.isTable);
  }

  bool get hasBraille {
    return blocks.any((DocumentBlock block) => block.hasBraille);
  }

  bool get hasBrailleErrors {
    return blocks.any(
      (DocumentBlock block) =>
          !block.brailleSuccess && block.brailleError.isNotEmpty,
    );
  }

  List<DocumentBlock> get textBlocks {
    return List<DocumentBlock>.unmodifiable(
      blocks.where((DocumentBlock block) => block.isText),
    );
  }

  List<DocumentBlock> get formulaBlocks {
    return List<DocumentBlock>.unmodifiable(
      blocks.where((DocumentBlock block) => block.isFormula),
    );
  }

  List<DocumentBlock> get tableBlocks {
    return List<DocumentBlock>.unmodifiable(
      blocks.where((DocumentBlock block) => block.isTable),
    );
  }

  List<DocumentBlock> get brailleBlocks {
    return List<DocumentBlock>.unmodifiable(
      blocks.where((DocumentBlock block) => block.hasBraille),
    );
  }

  List<DocumentBlock> get uebBrailleBlocks {
    return List<DocumentBlock>.unmodifiable(
      blocks.where(
        (DocumentBlock block) => block.hasBraille && block.isUebBraille,
      ),
    );
  }

  List<DocumentBlock> get nemethBrailleBlocks {
    return List<DocumentBlock>.unmodifiable(
      blocks.where(
        (DocumentBlock block) => block.hasBraille && block.isNemethBraille,
      ),
    );
  }

  String get combinedContent {
    return _combinePageContent(
      contentOf: (DocumentBlock block) => block.normalizedContent,
    );
  }

  String get combinedBraille {
    return _combinePageContent(
      contentOf: (DocumentBlock block) {
        return block.hasBraille ? block.brailleContent : '';
      },
    );
  }

  String _combinePageContent({
    required String Function(DocumentBlock block) contentOf,
  }) {
    if (pages.isNotEmpty) {
      final List<String> pageContents = pages
          .map((DocumentPage page) {
            return page.blocks
                .map(contentOf)
                .map((String content) => content.trim())
                .where((String content) => content.isNotEmpty)
                .join('\n\n');
          })
          .where((String content) => content.isNotEmpty)
          .toList(growable: false);

      if (pageContents.isNotEmpty) {
        // Three line breaks distinguish separate scanned pages.
        return pageContents.join('\n\n\n');
      }
    }

    return blocks
        .map(contentOf)
        .map((String content) => content.trim())
        .where((String content) => content.isNotEmpty)
        .join('\n\n');
  }

  static List<DocumentBlock> _parseBlocks(List<dynamic> values) {
    final List<DocumentBlock> blocks = <DocumentBlock>[];

    for (int index = 0; index < values.length; index++) {
      final dynamic value = values[index];

      if (value is! Map) {
        continue;
      }

      blocks.add(
        DocumentBlock.fromJson(
          Map<String, dynamic>.from(value),
          fallbackId: index,
          fallbackOrder: index,
        ),
      );
    }

    // Page-level reading order is normalized after parsing.
    return blocks;
  }

  static List<DocumentPage> _parsePages(dynamic value) {
    if (value is! List) {
      return const <DocumentPage>[];
    }

    final List<DocumentPage> pages = <DocumentPage>[];

    for (int index = 0; index < value.length; index++) {
      final dynamic page = value[index];

      if (page is! Map) {
        continue;
      }

      pages.add(
        DocumentPage.fromJson(
          Map<String, dynamic>.from(page),
          fallbackPageIndex: index,
        ),
      );
    }

    return pages;
  }

  static String _readString(dynamic value) {
    return value is String ? value : '';
  }

  static int _readInteger(dynamic value) {
    return value is num ? value.toInt() : 0;
  }

  static double _readDouble(dynamic value) {
    return value is num ? value.toDouble() : 0.0;
  }
}

class DocumentPage {
  const DocumentPage({
    required this.pageIndex,
    required this.width,
    required this.height,
    required this.blocks,
  });

  final int pageIndex;
  final int width;
  final int height;
  final List<DocumentBlock> blocks;

  factory DocumentPage.fromJson(
    Map<String, dynamic> json, {
    required int fallbackPageIndex,
  }) {
    final dynamic rawBlocks = json['blocks'];

    final int width = json['width'] is num ? (json['width'] as num).toInt() : 0;

    final int height = json['height'] is num
        ? (json['height'] as num).toInt()
        : 0;

    final List<DocumentBlock> parsedBlocks = rawBlocks is List
        ? ScanDocumentResult._parseBlocks(rawBlocks)
        : const <DocumentBlock>[];

    final List<DocumentBlock> orderedBlocks =
        DocumentReadingOrder.sort<DocumentBlock>(
          blocks: parsedBlocks,
          pageWidth: width.toDouble(),
          boundingBoxOf: (DocumentBlock block) => block.boundingBox,
        );

    return DocumentPage(
      pageIndex: json['page_index'] is num
          ? (json['page_index'] as num).toInt()
          : fallbackPageIndex,
      width: width,
      height: height,
      blocks: List<DocumentBlock>.unmodifiable(orderedBlocks),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'page_index': pageIndex,
      'width': width,
      'height': height,
      'blocks': blocks
          .map((DocumentBlock block) => block.toJson())
          .toList(growable: false),
    };
  }
}

class DocumentBlock {
  const DocumentBlock({
    required this.id,
    required this.order,
    required this.type,
    required this.rawContent,
    required this.normalizedContent,
    required this.boundingBox,
    required this.polygonPoints,
    required this.isText,
    required this.isFormula,
    required this.isTable,
    required this.tableRows,
    required this.brailleContent,
    required this.brailleCode,
    required this.brailleSuccess,
    required this.brailleError,
  });

  final int id;
  final int order;
  final String type;

  /// Original, unchanged output produced by PaddleOCR-VL.
  final String rawContent;

  /// Cleaned and accessible content produced by the backend.
  final String normalizedContent;

  final List<double> boundingBox;
  final List<List<double>> polygonPoints;

  final bool isText;
  final bool isFormula;
  final bool isTable;

  /// Structured rows and cells for recognized table blocks.
  ///
  /// Older saved records may have an empty list because they were
  /// created before structured table support was introduced.
  final List<List<String>> tableRows;

  /// Unicode Braille produced by Liblouis.
  final String brailleContent;

  /// Braille translation standard used by the backend.
  ///
  /// Expected values are `ueb` and `nemeth`.
  final String brailleCode;

  final bool brailleSuccess;
  final String brailleError;

  String get content => normalizedContent;

  bool get hasContent {
    return normalizedContent.trim().isNotEmpty ||
        tableRows.any(
          (List<String> row) =>
              row.any((String cell) => cell.trim().isNotEmpty),
        );
  }

  bool get hasTableData {
    return isTable && tableRows.isNotEmpty;
  }

  bool get wasNormalized {
    return rawContent != normalizedContent;
  }

  bool get hasBraille {
    return brailleSuccess && brailleContent.trim().isNotEmpty;
  }

  bool get isUebBraille {
    return brailleCode.toLowerCase() == 'ueb';
  }

  bool get isNemethBraille {
    return brailleCode.toLowerCase() == 'nemeth';
  }

  factory DocumentBlock.fromJson(
    Map<String, dynamic> json, {
    required int fallbackId,
    required int fallbackOrder,
  }) {
    final String type = json['type'] is String
        ? (json['type'] as String).trim().toLowerCase()
        : 'unknown';

    final String legacyContent = _readContent(json['content']);

    final String receivedRawContent = _readContent(json['raw_content']);

    final String receivedNormalizedContent = _readContent(
      json['normalized_content'],
    );

    final String rawContent = receivedRawContent.isNotEmpty
        ? receivedRawContent
        : legacyContent;

    final String normalizedContent = receivedNormalizedContent.isNotEmpty
        ? receivedNormalizedContent
        : legacyContent;

    final List<List<String>> tableRows = _parseTableRows(json['table_rows']);

    final bool isTable = json['is_table'] is bool
        ? json['is_table'] as bool
        : _isTableType(type) || tableRows.isNotEmpty;

    final String brailleContent = _readContent(json['braille_content']);

    final String brailleCode = _readContent(json['braille_code']);

    final String brailleError = _readContent(json['braille_error']);

    final bool brailleSuccess = json['braille_success'] is bool
        ? json['braille_success'] as bool
        : brailleContent.isNotEmpty;

    return DocumentBlock(
      id: json['id'] is num ? (json['id'] as num).toInt() : fallbackId,
      order: json['order'] is num
          ? (json['order'] as num).toInt()
          : fallbackOrder,
      type: type,
      rawContent: rawContent,
      normalizedContent: normalizedContent,
      boundingBox: _parseNumberList(json['bbox']),
      polygonPoints: _parsePolygonPoints(json['polygon_points']),
      isText: json['is_text'] is bool
          ? json['is_text'] as bool
          : type == 'text',
      isFormula: json['is_formula'] is bool
          ? json['is_formula'] as bool
          : _isFormulaType(type),
      isTable: isTable,
      tableRows: tableRows,
      brailleContent: brailleContent,
      brailleCode: brailleCode,
      brailleSuccess: brailleSuccess,
      brailleError: brailleError,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'order': order,
      'type': type,
      'raw_content': rawContent,
      'normalized_content': normalizedContent,
      'bbox': boundingBox,
      'polygon_points': polygonPoints,
      'is_text': isText,
      'is_formula': isFormula,
      'is_table': isTable,
      'table_rows': tableRows,
      'braille_content': brailleContent,
      'braille_code': brailleCode,
      'braille_success': brailleSuccess,
      'braille_error': brailleError,
    };
  }

  static String _readContent(dynamic value) {
    return value is String ? value.trim() : '';
  }

  static bool _isFormulaType(String type) {
    return type == 'formula' ||
        type == 'display_formula' ||
        type == 'inline_formula';
  }

  static bool _isTableType(String type) {
    return type == 'table';
  }

  static List<List<String>> _parseTableRows(dynamic value) {
    if (value is! List) {
      return const <List<String>>[];
    }

    final List<List<String>> rows = <List<String>>[];

    for (final dynamic rawRow in value) {
      if (rawRow is! List) {
        continue;
      }

      final List<String> cells = rawRow
          .map((dynamic cell) {
            return cell?.toString().trim() ?? '';
          })
          .toList(growable: false);

      final bool hasContent = cells.any((String cell) => cell.isNotEmpty);

      if (!hasContent) {
        continue;
      }

      rows.add(List<String>.unmodifiable(cells));
    }

    return List<List<String>>.unmodifiable(rows);
  }

  static List<double> _parseNumberList(dynamic value) {
    if (value is! List) {
      return const <double>[];
    }

    return List<double>.unmodifiable(
      value.whereType<num>().map((num number) => number.toDouble()),
    );
  }

  static List<List<double>> _parsePolygonPoints(dynamic value) {
    if (value is! List) {
      return const <List<double>>[];
    }

    return List<List<double>>.unmodifiable(
      value.whereType<List>().map((List<dynamic> point) {
        return _parseNumberList(point);
      }),
    );
  }
}

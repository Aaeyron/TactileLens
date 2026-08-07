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

  factory ScanDocumentResult.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['success'] != true) {
      throw const FormatException(
        'The document scan was not successful.',
      );
    }

    final dynamic rawBlocks = json['blocks'];

    if (rawBlocks is! List) {
      throw const FormatException(
        'The document scan response does not contain valid blocks.',
      );
    }

    final List<DocumentBlock> blocks =
        _parseBlocks(rawBlocks);

    final List<DocumentPage> pages =
        _parsePages(json['pages']);

    final int reportedPageCount =
        _readInteger(json['page_count']);

    return ScanDocumentResult(
      model: _readString(json['model']),
      pipelineVersion:
          _readString(json['pipeline_version']),
      device: _readString(json['device']),
      pageCount: reportedPageCount > 0
          ? reportedPageCount
          : pages.length,
      processingTimeMs:
          _readDouble(json['processing_time_ms']),
      blocks: List<DocumentBlock>.unmodifiable(blocks),
      pages: List<DocumentPage>.unmodifiable(pages),
    );
  }

  bool get hasContent => blocks.any(
        (DocumentBlock block) =>
            block.content.trim().isNotEmpty,
      );

  bool get hasText => blocks.any(
        (DocumentBlock block) => block.isText,
      );

  bool get hasFormulas => blocks.any(
        (DocumentBlock block) => block.isFormula,
      );

  List<DocumentBlock> get textBlocks =>
      List<DocumentBlock>.unmodifiable(
        blocks.where(
          (DocumentBlock block) => block.isText,
        ),
      );

  List<DocumentBlock> get formulaBlocks =>
      List<DocumentBlock>.unmodifiable(
        blocks.where(
          (DocumentBlock block) => block.isFormula,
        ),
      );

  static List<DocumentBlock> _parseBlocks(
    List<dynamic> values,
  ) {
    final List<DocumentBlock> blocks =
        <DocumentBlock>[];

    for (int index = 0; index < values.length; index++) {
      final dynamic value = values[index];

      if (value is! Map) continue;

      blocks.add(
        DocumentBlock.fromJson(
          Map<String, dynamic>.from(value),
          fallbackId: index,
          fallbackOrder: index,
        ),
      );
    }

    // Preserve the order supplied by the backend.
    return blocks;
  }

  static List<DocumentPage> _parsePages(dynamic value) {
    if (value is! List) {
      return const <DocumentPage>[];
    }

    final List<DocumentPage> pages = <DocumentPage>[];

    for (int index = 0; index < value.length; index++) {
      final dynamic page = value[index];

      if (page is! Map) continue;

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

    final List<DocumentBlock> blocks =
        rawBlocks is List
            ? ScanDocumentResult._parseBlocks(rawBlocks)
            : const <DocumentBlock>[];

    return DocumentPage(
      pageIndex: json['page_index'] is num
          ? (json['page_index'] as num).toInt()
          : fallbackPageIndex,
      width: json['width'] is num
          ? (json['width'] as num).toInt()
          : 0,
      height: json['height'] is num
          ? (json['height'] as num).toInt()
          : 0,
      blocks: List<DocumentBlock>.unmodifiable(blocks),
    );
  }
}

class DocumentBlock {
  const DocumentBlock({
    required this.id,
    required this.order,
    required this.type,
    required this.content,
    required this.boundingBox,
    required this.polygonPoints,
    required this.isText,
    required this.isFormula,
  });

  final int id;
  final int order;
  final String type;
  final String content;
  final List<double> boundingBox;
  final List<List<double>> polygonPoints;
  final bool isText;
  final bool isFormula;

  factory DocumentBlock.fromJson(
    Map<String, dynamic> json, {
    required int fallbackId,
    required int fallbackOrder,
  }) {
    final String type =
        json['type'] is String
            ? json['type'] as String
            : 'unknown';

    return DocumentBlock(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : fallbackId,
      order: json['order'] is num
          ? (json['order'] as num).toInt()
          : fallbackOrder,
      type: type,
      content: json['content'] is String
          ? (json['content'] as String).trim()
          : '',
      boundingBox:
          _parseNumberList(json['bbox']),
      polygonPoints:
          _parsePolygonPoints(json['polygon_points']),
      isText: json['is_text'] is bool
          ? json['is_text'] as bool
          : type == 'text',
      isFormula: json['is_formula'] is bool
          ? json['is_formula'] as bool
          : _isFormulaType(type),
    );
  }

  static bool _isFormulaType(String type) {
    return type == 'formula' ||
        type == 'display_formula' ||
        type == 'inline_formula';
  }

  static List<double> _parseNumberList(
    dynamic value,
  ) {
    if (value is! List) {
      return const <double>[];
    }

    return List<double>.unmodifiable(
      value
          .whereType<num>()
          .map(
            (num number) => number.toDouble(),
          ),
    );
  }

  static List<List<double>> _parsePolygonPoints(
    dynamic value,
  ) {
    if (value is! List) {
      return const <List<double>>[];
    }

    return List<List<double>>.unmodifiable(
      value.whereType<List>().map(
            (List<dynamic> point) =>
                _parseNumberList(point),
          ),
    );
  }
}
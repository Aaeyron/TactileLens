class ScanDocumentResult {
  const ScanDocumentResult({
    required this.model,
    required this.pipelineVersion,
    required this.device,
    required this.pageCount,
    required this.processingTimeMs,
    required this.blocks,
  });

  final String model;
  final String pipelineVersion;
  final String device;
  final int pageCount;
  final double processingTimeMs;
  final List<DocumentBlock> blocks;

  factory ScanDocumentResult.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'];

    if (json['success'] != true || rawBlocks is! List) {
      throw const FormatException('Invalid document scan response.');
    }

    final blocks = rawBlocks
        .whereType<Map>()
        .map(
          (block) => DocumentBlock.fromJson(
            Map<String, dynamic>.from(block),
          ),
        )
        .toList(growable: false)
      ..sort((first, second) => first.order.compareTo(second.order));

    return ScanDocumentResult(
      model: json['model'] as String? ?? '',
      pipelineVersion: json['pipeline_version'] as String? ?? '',
      device: json['device'] as String? ?? '',
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      processingTimeMs:
          (json['processing_time_ms'] as num?)?.toDouble() ?? 0,
      blocks: List<DocumentBlock>.unmodifiable(blocks),
    );
  }

  List<DocumentBlock> get textBlocks => List<DocumentBlock>.unmodifiable(
        blocks.where((block) => block.isText),
      );

  List<DocumentBlock> get formulaBlocks =>
      List<DocumentBlock>.unmodifiable(
        blocks.where((block) => block.isFormula),
      );
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

  factory DocumentBlock.fromJson(Map<String, dynamic> json) {
    return DocumentBlock(
      id: (json['id'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'unknown',
      content: json['content'] as String? ?? '',
      boundingBox: _parseNumberList(json['bbox']),
      polygonPoints: _parsePolygonPoints(json['polygon_points']),
      isText: json['is_text'] as bool? ?? false,
      isFormula: json['is_formula'] as bool? ?? false,
    );
  }

  static List<double> _parseNumberList(dynamic value) {
    if (value is! List) return const <double>[];

    return List<double>.unmodifiable(
      value.whereType<num>().map((number) => number.toDouble()),
    );
  }

  static List<List<double>> _parsePolygonPoints(dynamic value) {
    if (value is! List) return const <List<double>>[];

    return List<List<double>>.unmodifiable(
      value.whereType<List>().map(_parseNumberList),
    );
  }
}


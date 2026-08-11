class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.recognizedContent,
    required this.brailleContent,
    required this.documentBlocks,
    required this.createdAt,
    required this.updatedAt,
    this.sourceImagePath,
    this.modelName,
    this.pipelineVersion,
    this.processingTimeMs,
  });

  final int id;
  final int userId;
  final String title;
  final String recognizedContent;
  final String brailleContent;
  final List<Map<String, dynamic>> documentBlocks;
  final String? sourceImagePath;
  final String? modelName;
  final String? pipelineVersion;
  final double? processingTimeMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: _requiredInteger(json['id'], 'History ID'),
      userId: _requiredInteger(json['user_id'], 'User ID'),
      title: _readString(json['title'], fallback: 'Untitled Scan'),
      recognizedContent: _readString(json['recognized_content']),
      brailleContent: _readString(json['braille_content']),
      documentBlocks: _parseDocumentBlocks(json['document_blocks']),
      sourceImagePath: _readNullableString(json['source_image_path']),
      modelName: _readNullableString(json['model_name']),
      pipelineVersion: _readNullableString(json['pipeline_version']),
      processingTimeMs: _readNullableDouble(json['processing_time_ms']),
      createdAt: _requiredDateTime(json['created_at'], 'Creation date'),
      updatedAt: _requiredDateTime(json['updated_at'], 'Update date'),
    );
  }

  HistoryRecord copyWith({String? title}) {
    return HistoryRecord(
      id: id,
      userId: userId,
      title: title ?? this.title,
      recognizedContent: recognizedContent,
      brailleContent: brailleContent,
      documentBlocks: documentBlocks,
      sourceImagePath: sourceImagePath,
      modelName: modelName,
      pipelineVersion: pipelineVersion,
      processingTimeMs: processingTimeMs,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int _requiredInteger(dynamic value, String fieldName) {
    final parsedValue = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');

    if (parsedValue == null || parsedValue <= 0) {
      throw FormatException('$fieldName is missing or invalid.');
    }

    return parsedValue;
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value is! String) {
      return fallback;
    }

    final cleanValue = value.trim();

    return cleanValue.isEmpty ? fallback : cleanValue;
  }

  static String? _readNullableString(dynamic value) {
    if (value is! String) {
      return null;
    }

    final cleanValue = value.trim();

    return cleanValue.isEmpty ? null : cleanValue;
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static DateTime _requiredDateTime(dynamic value, String fieldName) {
    final parsedDate = DateTime.tryParse(value?.toString() ?? '');

    if (parsedDate == null) {
      throw FormatException('$fieldName is missing or invalid.');
    }

    return parsedDate.toLocal();
  }

  static List<Map<String, dynamic>> _parseDocumentBlocks(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return List<Map<String, dynamic>>.unmodifiable(
      value.whereType<Map>().map((block) => Map<String, dynamic>.from(block)),
    );
  }
}

class HistoryPagination {
  const HistoryPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory HistoryPagination.fromJson(Map<String, dynamic> json) {
    return HistoryPagination(
      page: _readInteger(json['page'], fallback: 1),
      limit: _readInteger(json['limit'], fallback: 20),
      total: _readInteger(json['total']),
      totalPages: _readInteger(json['totalPages']),
    );
  }

  bool get hasNextPage => page < totalPages;

  static int _readInteger(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class HistoryPage {
  const HistoryPage({required this.records, required this.pagination});

  final List<HistoryRecord> records;
  final HistoryPagination pagination;

  factory HistoryPage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawPagination = json['pagination'];

    if (json['success'] != true || rawData is! List || rawPagination is! Map) {
      throw const FormatException('The history response is invalid.');
    }

    final records = rawData
        .whereType<Map>()
        .map(
          (record) => HistoryRecord.fromJson(Map<String, dynamic>.from(record)),
        )
        .toList(growable: false);

    return HistoryPage(
      records: List<HistoryRecord>.unmodifiable(records),
      pagination: HistoryPagination.fromJson(
        Map<String, dynamic>.from(rawPagination),
      ),
    );
  }
}

import 'dart:convert';

class MaterialModel {
  const MaterialModel({
    this.id,
    this.folderId,
    required this.title,
    required this.subject,
    required this.description,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.filePath,
    required this.uploadDate,
    this.sourceType = uploadedFileSourceType,
    this.recognizedContent = '',
    this.brailleContent = '',
    this.documentBlocks = const <Map<String, dynamic>>[],
    this.modelName,
    this.pipelineVersion,
    this.processingTimeMs,
  });

  static const String uploadedFileSourceType = 'uploaded_file';
  static const String scanResultSourceType = 'scan_result';

  final int? id;
  final int? folderId;

  final String title;
  final String subject;
  final String description;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String filePath;
  final DateTime uploadDate;

  final String sourceType;
  final String recognizedContent;
  final String brailleContent;
  final List<Map<String, dynamic>> documentBlocks;
  final String? modelName;
  final String? pipelineVersion;
  final double? processingTimeMs;

  bool get isScanResult {
    return sourceType == scanResultSourceType;
  }

  bool get isUploadedFile {
    return sourceType == uploadedFileSourceType;
  }

  bool get hasRecognizedContent {
    return recognizedContent.trim().isNotEmpty;
  }

  bool get hasBrailleContent {
    return brailleContent.trim().isNotEmpty;
  }

  bool get isInFolder {
    return folderId != null;
  }

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: _readOptionalInteger(json['id']),
      folderId: _readOptionalInteger(json['folder_id']),
      title: _readString(json['title']),
      subject: _readString(json['subject']),
      description: _readString(json['description']),
      fileName: _readString(json['file_name']),
      fileType: _readString(json['file_type']),
      fileSize: _readInteger(json['file_size']),
      filePath: _readString(json['file_path']),
      uploadDate: _readDateTime(json['uploaded_at']),
      sourceType: _readString(
        json['source_type'],
        fallback: uploadedFileSourceType,
      ),
      recognizedContent: _readString(json['recognized_content']),
      brailleContent: _readString(json['braille_content']),
      documentBlocks: _readDocumentBlocks(json['document_blocks']),
      modelName: _readOptionalString(json['model_name']),
      pipelineVersion: _readOptionalString(json['pipeline_version']),
      processingTimeMs: _readOptionalDouble(json['processing_time_ms']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'folder_id': folderId,
      'title': title,
      'subject': subject,
      'description': description,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'file_path': filePath,
      'uploaded_at': uploadDate.toIso8601String(),
      'source_type': sourceType,
      'recognized_content': recognizedContent,
      'braille_content': brailleContent,
      'document_blocks': jsonEncode(documentBlocks),
      'model_name': modelName,
      'pipeline_version': pipelineVersion,
      'processing_time_ms': processingTimeMs,
    };
  }

  MaterialModel copyWithFolderId(int? folderId) {
    return MaterialModel(
      id: id,
      folderId: folderId,
      title: title,
      subject: subject,
      description: description,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      filePath: filePath,
      uploadDate: uploadDate,
      sourceType: sourceType,
      recognizedContent: recognizedContent,
      brailleContent: brailleContent,
      documentBlocks: documentBlocks,
      modelName: modelName,
      pipelineVersion: pipelineVersion,
      processingTimeMs: processingTimeMs,
    );
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value is! String) {
      return fallback;
    }

    final String normalizedValue = value.trim();

    return normalizedValue.isEmpty ? fallback : normalizedValue;
  }

  static String? _readOptionalString(dynamic value) {
    final String normalizedValue = _readString(value);

    return normalizedValue.isEmpty ? null : normalizedValue;
  }

  static int _readInteger(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _readOptionalInteger(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _readOptionalDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is String) {
      final DateTime? parsedValue = DateTime.tryParse(value);

      if (parsedValue != null) {
        return parsedValue;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static List<Map<String, dynamic>> _readDocumentBlocks(dynamic value) {
    dynamic parsedValue = value;

    if (value is String) {
      if (value.trim().isEmpty) {
        return const <Map<String, dynamic>>[];
      }

      try {
        parsedValue = jsonDecode(value);
      } on FormatException {
        return const <Map<String, dynamic>>[];
      }
    }

    if (parsedValue is! List) {
      return const <Map<String, dynamic>>[];
    }

    return List<Map<String, dynamic>>.unmodifiable(
      parsedValue.whereType<Map>().map((Map block) {
        return Map<String, dynamic>.from(block);
      }),
    );
  }
}

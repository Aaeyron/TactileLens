import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';

class PaddleOnnxNativeService {
  const PaddleOnnxNativeService();

  static const MethodChannel _channel = MethodChannel(
    'com.tactilelens.app/paddle_onnx',
  );

  bool get isSupported => Platform.isAndroid;

  Future<Map<String, dynamic>> runtimeInfo() {
    return _invokeMap('runtimeInfo');
  }

  Future<Map<String, dynamic>> validateModels({int threadCount = 4}) {
    return _invokeMap('validateModels', <String, dynamic>{
      'threadCount': threadCount.clamp(1, 8),
    });
  }

  // Temporary benchmark method.
  // Remove after production camera-image recognition succeeds.
  Future<Map<String, dynamic>> recognizeTestImage({int threadCount = 4}) {
    return _invokeMap('recognizeTestImage', <String, dynamic>{
      'threadCount': threadCount.clamp(1, 8),
    });
  }

  // ---- Full-page offline OCR (PaddleOCR SDK + PP-OCRv6) ----

  /// Loads the detector + recognizer once and keeps them in memory.
  /// Safe to call repeatedly; later calls return immediately.
  Future<Map<String, dynamic>> initializeOcr({int threadCount = 4}) {
    return _invokeMap('initializeOcr', <String, dynamic>{
      'threadCount': threadCount.clamp(1, 8),
    });
  }

    /// Frees the native OCR engine. The next scan will reload the models.
  Future<Map<String, dynamic>> releaseOcr() {
    return _invokeMap('releaseOcr');
  }

  // ---- Page layout detection (PP-DocLayoutV3) ----

  /// Loads the layout model once and keeps it in memory.
  /// The first call also copies the model from the APK to internal storage.
  Future<Map<String, dynamic>> initializeLayout({int threadCount = 4}) {
    return _invokeMap('initializeLayout', <String, dynamic>{
      'threadCount': threadCount.clamp(1, 8),
    });
  }

    /// Frees the native layout model.
  Future<Map<String, dynamic>> releaseLayout() {
    return _invokeMap('releaseLayout');
  }

  // ---- Full offline document pipeline (layout + OCR + formulas) ----

  /// Loads the OCR, layout and formula models once and keeps them loaded.
  /// The first call also copies the large models into internal storage.
  Future<Map<String, dynamic>> initializeDocumentPipeline({
    int threadCount = 4,
  }) {
    return _invokeMap('initializeDocumentPipeline', <String, dynamic>{
      'threadCount': threadCount.clamp(1, 8),
    });
  }

  /// Frees all three offline models.
  Future<Map<String, dynamic>> releaseDocumentPipeline() {
    return _invokeMap('releaseDocumentPipeline');
  }

  /// Full offline page scan: text + formulas in reading order.
  Future<OfflineDocumentResult> scanDocumentResult({
    required String imagePath,
    int threadCount = 4,
    double layoutThreshold = 0.5,
  }) async {
    final String normalizedImagePath = imagePath.trim();

    if (normalizedImagePath.isEmpty) {
      throw const PaddleOnnxNativeException(
        'The image path is required for an offline document scan.',
        code: 'missing_image_path',
      );
    }

    final Map<String, dynamic> response = await _invokeMap(
      'scanDocument',
      <String, dynamic>{
        'imagePath': normalizedImagePath,
        'threadCount': threadCount.clamp(1, 8),
        'layoutThreshold': layoutThreshold.clamp(0.05, 0.95).toDouble(),
      },
    );

    return OfflineDocumentResult.fromMap(response);
  }

  /// One formula image (or one [left, top, right, bottom] box in it)
  /// to LaTeX.
  Future<OfflineFormulaResult> recognizeFormulaResult({
    required String imagePath,
    int threadCount = 4,
    List<double>? box,
  }) async {
    final String normalizedImagePath = imagePath.trim();

    if (normalizedImagePath.isEmpty) {
      throw const PaddleOnnxNativeException(
        'The image path is required for formula recognition.',
        code: 'missing_image_path',
      );
    }

    if (box != null && box.length != 4) {
      throw const PaddleOnnxNativeException(
        'The formula box must be [left, top, right, bottom].',
        code: 'invalid_box',
      );
    }

    final Map<String, dynamic> response = await _invokeMap(
      'recognizeFormula',
      <String, dynamic>{
        'imagePath': normalizedImagePath,
        'threadCount': threadCount.clamp(1, 8),
        'box': ?box,
      },
    );

    return OfflineFormulaResult.fromMap(response);
  }

  /// Detects page regions (text, display/inline formulas, tables, ...)
  /// in reading order.
  Future<OfflineLayoutResult> detectLayoutResult({
    required String imagePath,
    int threadCount = 4,
    double threshold = 0.5,
  }) async {
    final String normalizedImagePath = imagePath.trim();

    if (normalizedImagePath.isEmpty) {
      throw const PaddleOnnxNativeException(
        'The image path is required for layout detection.',
        code: 'missing_image_path',
      );
    }

    final Map<String, dynamic> response = await _invokeMap(
      'detectLayout',
      <String, dynamic>{
        'imagePath': normalizedImagePath,
        'threadCount': threadCount.clamp(1, 8),
        'threshold': threshold.clamp(0.05, 0.95).toDouble(),
      },
    );

    return OfflineLayoutResult.fromMap(response);
  }

  // Production offline-recognition method (raw map).
  Future<Map<String, dynamic>> recognizeImage({
    required String imagePath,
    int threadCount = 4,
  }) {
    final String normalizedImagePath = imagePath.trim();

    if (normalizedImagePath.isEmpty) {
      throw const PaddleOnnxNativeException(
        'The image path is required for offline recognition.',
        code: 'missing_image_path',
      );
    }

    return _invokeMap('recognizeImage', <String, dynamic>{
      'imagePath': normalizedImagePath,
      'threadCount': threadCount.clamp(1, 8),
    });
  }

  /// Same as [recognizeImage], but returns a typed, safely converted result.
  Future<OfflineOcrResult> recognizeImageResult({
    required String imagePath,
    int threadCount = 4,
  }) async {
    final Map<String, dynamic> response = await recognizeImage(
      imagePath: imagePath,
      threadCount: threadCount,
    );

    return OfflineOcrResult.fromMap(response);
  }

  Future<Map<String, dynamic>> _invokeMap(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    if (!isSupported) {
      throw const PaddleOnnxNativeException(
        'Offline ONNX recognition is currently available only on Android.',
      );
    }

    try {
      final Object? response = await _channel.invokeMethod<Object?>(
        method,
        arguments,
      );

      if (response is! Map) {
        throw const PaddleOnnxNativeException(
          'The ONNX runtime returned an invalid response.',
        );
      }

      return Map<String, dynamic>.from(response);
    } on PlatformException catch (error) {
      throw PaddleOnnxNativeException(
        error.message ?? 'The Android ONNX operation failed.',
        code: error.code,
      );
    } on MissingPluginException {
      throw const PaddleOnnxNativeException(
        'The Android ONNX channel is unavailable. Fully restart the app.',
        code: 'missing_plugin',
      );
    }
  }
}

// ---- Typed offline OCR result ----

class OfflineOcrResult {
  const OfflineOcrResult({
    required this.success,
    required this.isEmpty,
    required this.text,
    required this.blocks,
    required this.lineCount,
    required this.detectionTimeMs,
    required this.recognitionTimeMs,
    required this.totalTimeMs,
    required this.coldLoadTimeMs,
    required this.threadCount,
  });

  factory OfflineOcrResult.fromMap(Map<String, dynamic> map) {
    final Object? rawBlocks = map['blocks'];

    final List<OfflineOcrBlock> blocks = rawBlocks is List
        ? rawBlocks
            .whereType<Map>()
            .map(OfflineOcrBlock.fromMap)
            .toList(growable: false)
        : const <OfflineOcrBlock>[];

    return OfflineOcrResult(
      success: map['success'] == true,
      isEmpty: map['is_empty'] == true || blocks.isEmpty,
      text: (map['text'] as String?) ?? '',
      blocks: blocks,
      lineCount: _toInt(map['line_count']),
      detectionTimeMs: _toInt(map['detection_time_ms']),
      recognitionTimeMs: _toInt(map['recognition_time_ms']),
      totalTimeMs: _toInt(map['total_time_ms']),
      coldLoadTimeMs: _toInt(map['cold_load_time_ms']),
      threadCount: _toInt(map['thread_count']),
    );
  }

  final bool success;
  final bool isEmpty;
  final String text;
  final List<OfflineOcrBlock> blocks;
  final int lineCount;
  final int detectionTimeMs;
  final int recognitionTimeMs;
  final int totalTimeMs;
  final int coldLoadTimeMs;
  final int threadCount;
}

class OfflineOcrBlock {
  const OfflineOcrBlock({
    required this.index,
    required this.text,
    required this.confidence,
    required this.box,
  });

  factory OfflineOcrBlock.fromMap(Map<dynamic, dynamic> map) {
    final Object? rawBox = map['box'];

    final List<OfflineOcrPoint> box = rawBox is List
        ? rawBox
            .whereType<Map>()
            .map(OfflineOcrPoint.fromMap)
            .toList(growable: false)
        : const <OfflineOcrPoint>[];

    return OfflineOcrBlock(
      index: _toInt(map['index']),
      text: (map['text'] as String?) ?? '',
      confidence: _toDouble(map['confidence']),
      box: box,
    );
  }

  final int index;
  final String text;
  final double confidence;
  final List<OfflineOcrPoint> box;

  /// Left edge of the detected region (useful for reading order).
  double get left =>
      box.isEmpty ? 0 : box.map((OfflineOcrPoint p) => p.x).reduce(math.min);

  /// Top edge of the detected region (useful for reading order).
  double get top =>
      box.isEmpty ? 0 : box.map((OfflineOcrPoint p) => p.y).reduce(math.min);
}

class OfflineOcrPoint {
  const OfflineOcrPoint({required this.x, required this.y});

  factory OfflineOcrPoint.fromMap(Map<dynamic, dynamic> map) {
    return OfflineOcrPoint(
      x: _toDouble(map['x']),
      y: _toDouble(map['y']),
    );
  }

  final double x;
  final double y;
}

// ---- Typed offline layout result ----

class OfflineLayoutResult {
  const OfflineLayoutResult({
    required this.success,
    required this.isEmpty,
    required this.regions,
    required this.imageWidth,
    required this.imageHeight,
    required this.threshold,
    required this.preprocessTimeMs,
    required this.inferenceTimeMs,
    required this.postprocessTimeMs,
    required this.totalTimeMs,
    required this.coldLoadTimeMs,
    required this.threadCount,
  });

  factory OfflineLayoutResult.fromMap(Map<String, dynamic> map) {
    final Object? rawRegions = map['regions'];

    final List<OfflineLayoutRegion> regions = rawRegions is List
        ? rawRegions
            .whereType<Map>()
            .map(OfflineLayoutRegion.fromMap)
            .toList(growable: false)
        : const <OfflineLayoutRegion>[];

    return OfflineLayoutResult(
      success: map['success'] == true,
      isEmpty: map['is_empty'] == true || regions.isEmpty,
      regions: regions,
      imageWidth: _toInt(map['image_width']),
      imageHeight: _toInt(map['image_height']),
      threshold: _toDouble(map['threshold']),
      preprocessTimeMs: _toInt(map['preprocess_time_ms']),
      inferenceTimeMs: _toInt(map['inference_time_ms']),
      postprocessTimeMs: _toInt(map['postprocess_time_ms']),
      totalTimeMs: _toInt(map['total_time_ms']),
      coldLoadTimeMs: _toInt(map['cold_load_time_ms']),
      threadCount: _toInt(map['thread_count']),
    );
  }

  final bool success;
  final bool isEmpty;

  /// Regions already sorted by the model's reading order.
  final List<OfflineLayoutRegion> regions;

  final int imageWidth;
  final int imageHeight;
  final double threshold;
  final int preprocessTimeMs;
  final int inferenceTimeMs;
  final int postprocessTimeMs;
  final int totalTimeMs;
  final int coldLoadTimeMs;
  final int threadCount;

  /// All display + inline formula regions, in reading order.
  List<OfflineLayoutRegion> get formulas => regions
      .where((OfflineLayoutRegion region) => region.isFormula)
      .toList(growable: false);
}

class OfflineLayoutRegion {
  const OfflineLayoutRegion({
    required this.order,
    required this.labelId,
    required this.label,
    required this.category,
    required this.score,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory OfflineLayoutRegion.fromMap(Map<dynamic, dynamic> map) {
    final Object? rawBox = map['box'];
    final Map<dynamic, dynamic> box =
        rawBox is Map ? rawBox : const <dynamic, dynamic>{};

    return OfflineLayoutRegion(
      order: _toInt(map['order']),
      labelId: _toInt(map['label_id']),
      label: (map['label'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'text',
      score: _toDouble(map['score']),
      left: _toDouble(box['left']),
      top: _toDouble(box['top']),
      right: _toDouble(box['right']),
      bottom: _toDouble(box['bottom']),
    );
  }

  /// Reading-order rank from the model (lower = earlier).
  final int order;
  final int labelId;

  /// Raw model label, e.g. "text", "display_formula", "inline_formula".
  final String label;

  /// Simplified routing category:
  /// text, formula_display, formula_inline, formula_number, table, figure.
  final String category;

  final double score;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  bool get isDisplayFormula => category == 'formula_display';
  bool get isInlineFormula => category == 'formula_inline';
  bool get isFormula => isDisplayFormula || isInlineFormula;
}

// ---- Typed offline formula result ----

class OfflineFormulaResult {
  const OfflineFormulaResult({
    required this.success,
    required this.latex,
    required this.rawLatex,
    required this.tokenCount,
    required this.reachedEnd,
    required this.preprocessTimeMs,
    required this.inferenceTimeMs,
    required this.decodeTimeMs,
    required this.totalTimeMs,
    required this.coldLoadTimeMs,
    required this.threadCount,
  });

  factory OfflineFormulaResult.fromMap(Map<String, dynamic> map) {
    return OfflineFormulaResult(
      success: map['success'] == true,
      latex: (map['latex'] as String?) ?? '',
      rawLatex: (map['raw_latex'] as String?) ?? '',
      tokenCount: _toInt(map['token_count']),
      reachedEnd: map['reached_end'] == true,
      preprocessTimeMs: _toInt(map['preprocess_time_ms']),
      inferenceTimeMs: _toInt(map['inference_time_ms']),
      decodeTimeMs: _toInt(map['decode_time_ms']),
      totalTimeMs: _toInt(map['total_time_ms']),
      coldLoadTimeMs: _toInt(map['cold_load_time_ms']),
      threadCount: _toInt(map['thread_count']),
    );
  }

  final bool success;

  /// Cleaned LaTeX, e.g. \left(\sqrt{2}\right)^{2}=2
  final String latex;

  /// Tokenizer output before space cleanup (for debugging).
  final String rawLatex;

  final int tokenCount;

  /// False if the model hit its token limit before finishing.
  final bool reachedEnd;

  final int preprocessTimeMs;
  final int inferenceTimeMs;
  final int decodeTimeMs;
  final int totalTimeMs;
  final int coldLoadTimeMs;
  final int threadCount;
}

// ---- Typed offline document result ----

class OfflineDocumentResult {
  const OfflineDocumentResult({
    required this.success,
    required this.isEmpty,
    required this.blocks,
    required this.markdown,
    required this.formulaCount,
    required this.inlineFormulaCount,
    required this.regionCount,
    required this.ocrLineCount,
    required this.droppedFormulaLineCount,
    required this.unassignedLineCount,
    required this.needsReviewCount,
    required this.imageWidth,
    required this.imageHeight,
    required this.layoutTimeMs,
    required this.ocrTimeMs,
    required this.formulaTimeMs,
    required this.totalTimeMs,
    required this.threadCount,
  });

  factory OfflineDocumentResult.fromMap(Map<String, dynamic> map) {
    final Object? rawBlocks = map['blocks'];

    final List<OfflineDocumentBlock> blocks = rawBlocks is List
        ? rawBlocks
            .whereType<Map>()
            .map(OfflineDocumentBlock.fromMap)
            .toList(growable: false)
        : const <OfflineDocumentBlock>[];

    return OfflineDocumentResult(
      success: map['success'] == true,
      isEmpty: map['is_empty'] == true || blocks.isEmpty,
      blocks: blocks,
      markdown: (map['markdown'] as String?) ?? '',
      formulaCount: _toInt(map['formula_count']),
      inlineFormulaCount: _toInt(map['inline_formula_count']),
      regionCount: _toInt(map['region_count']),
      ocrLineCount: _toInt(map['ocr_line_count']),
      droppedFormulaLineCount: _toInt(map['dropped_formula_line_count']),
      unassignedLineCount: _toInt(map['unassigned_line_count']),
      needsReviewCount: _toInt(map['needs_review_count']),
      imageWidth: _toInt(map['image_width']),
      imageHeight: _toInt(map['image_height']),
      layoutTimeMs: _toInt(map['layout_time_ms']),
      ocrTimeMs: _toInt(map['ocr_time_ms']),
      formulaTimeMs: _toInt(map['formula_time_ms']),
      totalTimeMs: _toInt(map['total_time_ms']),
      threadCount: _toInt(map['thread_count']),
    );
  }

  final bool success;
  final bool isEmpty;

  /// Text and formula blocks, already in reading order.
  final List<OfflineDocumentBlock> blocks;

  /// Whole page as Markdown; display formulas are wrapped in $$ ... $$.
  final String markdown;

  final int formulaCount;
  final int inlineFormulaCount;
  final int regionCount;
  final int ocrLineCount;
  final int droppedFormulaLineCount;
  final int unassignedLineCount;
  final int needsReviewCount;
  final int imageWidth;
  final int imageHeight;
  final int layoutTimeMs;
  final int ocrTimeMs;
  final int formulaTimeMs;
  final int totalTimeMs;
  final int threadCount;
}

class OfflineDocumentBlock {
  const OfflineDocumentBlock({
    required this.index,
    required this.type,
    required this.label,
    required this.content,
    required this.latex,
    required this.score,
    required this.confidence,
    required this.minConfidence,
    required this.lineCount,
    required this.inlineFormulaCount,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.needsReview,
    required this.source,
    required this.error,
  });

  factory OfflineDocumentBlock.fromMap(Map<dynamic, dynamic> map) {
    final Object? rawBox = map['box'];
    final Map<dynamic, dynamic> box =
        rawBox is Map ? rawBox : const <dynamic, dynamic>{};

    return OfflineDocumentBlock(
      index: _toInt(map['index']),
      type: (map['type'] as String?) ?? 'text',
      label: (map['label'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      latex: map['latex'] as String?,
      score: _toDouble(map['score']),
      confidence: _toDouble(map['confidence']),
      minConfidence:
          map['min_confidence'] is num ? _toDouble(map['min_confidence']) : null,
      lineCount: _toInt(map['line_count']),
      inlineFormulaCount: _toInt(map['inline_formula_count']),
      left: _toDouble(box['left']),
      top: _toDouble(box['top']),
      right: _toDouble(box['right']),
      bottom: _toDouble(box['bottom']),
      needsReview: map['needs_review'] == true,
      source: (map['source'] as String?) ?? '',
      error: map['error'] as String?,
    );
  }

  final int index;

  /// "formula" for equations; otherwise the layout category
  /// (text, table, figure, formula_number, ...).
  final String type;

  /// Raw layout label, e.g. "text", "display_formula", "paragraph_title".
  final String label;

  /// OCR text for text blocks, LaTeX for formula blocks.
  final String content;

  /// LaTeX for formula blocks, null otherwise.
  final String? latex;

  final double score;
  final double confidence;
  final double? minConfidence;
  final int lineCount;
  final int inlineFormulaCount;
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// True when the teacher should double-check this block.
  final bool needsReview;

  /// "ocr" or "formula".
  final String source;

  /// Set only if formula recognition failed for this block.
  final String? error;

  bool get isFormula => type == 'formula';
}

int _toInt(Object? value) => value is num ? value.toInt() : 0;

double _toDouble(Object? value) => value is num ? value.toDouble() : 0.0;

class PaddleOnnxNativeException implements Exception {
  const PaddleOnnxNativeException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
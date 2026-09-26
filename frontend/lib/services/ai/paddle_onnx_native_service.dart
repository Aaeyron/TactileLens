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

int _toInt(Object? value) => value is num ? value.toInt() : 0;

double _toDouble(Object? value) => value is num ? value.toDouble() : 0.0;

class PaddleOnnxNativeException implements Exception {
  const PaddleOnnxNativeException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PaddleOcrVlNativeService {
  const PaddleOcrVlNativeService();

  static const MethodChannel _channel = MethodChannel(
    'com.tactilelens.app/paddleocr_vl',
  );

  bool get isSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  Future<PaddleOcrVlRuntimeInfo> initialize() async {
    final Map<Object?, Object?> result = await _invokeMap('initialize');

    if (result['success'] != true) {
      throw const PaddleOcrVlNativeException(
        'The PaddleOCR-VL native runtime could not be initialized.',
      );
    }

    return PaddleOcrVlRuntimeInfo(
      success: true,
      version: _readString(result['version'], fallback: 'unknown'),
      systemInformation: _readString(
        result['system_information'],
        fallback: 'System information unavailable.',
      ),
      modelDirectory: _readString(result['model_directory'], fallback: ''),
    );
  }

  Future<String> modelDirectory() async {
    final Map<Object?, Object?> result = await _invokeMap('modelDirectory');

    return _readString(result['model_directory'], fallback: '');
  }

  Future<PaddleOcrVlModelLoadResult> loadModels({int threadCount = 4}) async {
    final int normalizedThreadCount = threadCount.clamp(1, 8);

    final Map<Object?, Object?> result = await _invokeMap(
      'loadModels',
      <String, Object>{'threadCount': normalizedThreadCount},
    );

    return PaddleOcrVlModelLoadResult(
      success: result['success'] == true,
      loaded: result['loaded'] == true,
      threadCount: _readInteger(
        result['thread_count'],
        fallback: normalizedThreadCount,
      ),
      loadTimeMs: _readInteger(result['load_time_ms'], fallback: 0),
      modelPath: _readString(result['model_path'], fallback: ''),
      projectorPath: _readString(result['projector_path'], fallback: ''),
      modelSizeBytes: _readInteger(result['model_size_bytes'], fallback: 0),
      projectorSizeBytes: _readInteger(
        result['projector_size_bytes'],
        fallback: 0,
      ),
      error: _readNullableString(result['error']),
    );
  }

  Future<PaddleOcrVlModelStatus> modelStatus() async {
    final Map<Object?, Object?> result = await _invokeMap('modelsLoaded');

    return PaddleOcrVlModelStatus(
      loaded: result['loaded'] == true,
      loadTimeMs: _readInteger(result['load_time_ms'], fallback: 0),
      error: _readNullableString(result['error']),
    );
  }

  Future<PaddleOcrVlScanResult> scanImage({
    required String imagePath,
    String prompt = 'OCR:',
    int maximumTokens = 256,
    int threadCount = 4,
  }) async {
    final String normalizedImagePath = imagePath.trim();

    if (normalizedImagePath.isEmpty) {
      throw const PaddleOcrVlNativeException('The scan image path is missing.');
    }

    final String normalizedPrompt = prompt.trim().isEmpty
        ? 'OCR:'
        : prompt.trim();
    final int normalizedMaximumTokens = maximumTokens.clamp(1, 1024);
    final int normalizedThreadCount = threadCount.clamp(1, 8);

    final Map<Object?, Object?> result =
        await _invokeMap('scanImage', <String, Object>{
          'imagePath': normalizedImagePath,
          'prompt': normalizedPrompt,
          'maximumTokens': normalizedMaximumTokens,
          'threadCount': normalizedThreadCount,
        });

    return PaddleOcrVlScanResult(
      success: result['success'] == true,
      content: _readString(result['content'], fallback: ''),
      scanTimeMs: _readInteger(result['scan_time_ms'], fallback: 0),
      error: _readNullableString(result['error']),
    );
  }

  Future<bool> unloadModels() async {
    final Map<Object?, Object?> result = await _invokeMap('unloadModels');

    return result['success'] == true && result['loaded'] != true;
  }

  Future<String> runtimeVersion() async {
    final Map<Object?, Object?> result = await _invokeMap('version');
    return _readString(result['version'], fallback: 'unknown');
  }

  Future<String> systemInformation() async {
    final Map<Object?, Object?> result = await _invokeMap('systemInformation');

    return _readString(
      result['system_information'],
      fallback: 'System information unavailable.',
    );
  }

  Future<Map<Object?, Object?>> _invokeMap(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    if (!isSupported) {
      throw const PaddleOcrVlNativeException(
        'Offline PaddleOCR-VL is currently available only on Android.',
      );
    }

    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>(method, arguments);

      if (result == null) {
        throw PaddleOcrVlNativeException(
          'PaddleOCR-VL returned no result for $method.',
        );
      }

      return result;
    } on PlatformException catch (error) {
      throw PaddleOcrVlNativeException(
        error.message ?? 'The PaddleOCR-VL native operation failed.',
      );
    } on MissingPluginException {
      throw const PaddleOcrVlNativeException(
        'The offline PaddleOCR-VL runtime is unavailable. '
        'Reinstall the latest Android application build.',
      );
    }
  }

  static String _readString(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  static int _readInteger(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return fallback;
  }
}

class PaddleOcrVlRuntimeInfo {
  const PaddleOcrVlRuntimeInfo({
    required this.success,
    required this.version,
    required this.systemInformation,
    required this.modelDirectory,
  });

  final bool success;
  final String version;
  final String systemInformation;
  final String modelDirectory;
}

class PaddleOcrVlModelLoadResult {
  const PaddleOcrVlModelLoadResult({
    required this.success,
    required this.loaded,
    required this.threadCount,
    required this.loadTimeMs,
    required this.modelPath,
    required this.projectorPath,
    required this.modelSizeBytes,
    required this.projectorSizeBytes,
    required this.error,
  });

  final bool success;
  final bool loaded;
  final int threadCount;
  final int loadTimeMs;
  final String modelPath;
  final String projectorPath;
  final int modelSizeBytes;
  final int projectorSizeBytes;
  final String? error;

  Duration get loadDuration {
    return Duration(milliseconds: loadTimeMs);
  }
}

class PaddleOcrVlModelStatus {
  const PaddleOcrVlModelStatus({
    required this.loaded,
    required this.loadTimeMs,
    required this.error,
  });

  final bool loaded;
  final int loadTimeMs;
  final String? error;
}

class PaddleOcrVlScanResult {
  const PaddleOcrVlScanResult({
    required this.success,
    required this.content,
    required this.scanTimeMs,
    required this.error,
  });

  final bool success;
  final String content;
  final int scanTimeMs;
  final String? error;

  Duration get scanDuration {
    return Duration(milliseconds: scanTimeMs);
  }
}

class PaddleOcrVlNativeException implements Exception {
  const PaddleOcrVlNativeException(this.message);

  final String message;

  @override
  String toString() => message;
}

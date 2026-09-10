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
    if (!isSupported) {
      throw const PaddleOcrVlNativeException(
        'Offline PaddleOCR-VL is currently available only on Android.',
      );
    }

    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>('initialize');

      if (result == null) {
        throw const PaddleOcrVlNativeException(
          'PaddleOCR-VL returned no initialization information.',
        );
      }

      final bool success = result['success'] == true;

      if (!success) {
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
      );
    } on PlatformException catch (error) {
      throw PaddleOcrVlNativeException(
        error.message ??
            'The PaddleOCR-VL native runtime could not be initialized.',
      );
    } on MissingPluginException {
      throw const PaddleOcrVlNativeException(
        'The offline PaddleOCR-VL runtime is unavailable. '
        'Reinstall the latest Android application build.',
      );
    }
  }

  Future<String> runtimeVersion() async {
    if (!isSupported) {
      return 'unavailable';
    }

    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>('version');

      return _readString(result?['version'], fallback: 'unknown');
    } on PlatformException {
      return 'unavailable';
    } on MissingPluginException {
      return 'unavailable';
    }
  }

  Future<String> systemInformation() async {
    if (!isSupported) {
      return 'System information unavailable.';
    }

    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>('systemInformation');

      return _readString(
        result?['system_information'],
        fallback: 'System information unavailable.',
      );
    } on PlatformException {
      return 'System information unavailable.';
    } on MissingPluginException {
      return 'System information unavailable.';
    }
  }

  static String _readString(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }
}

class PaddleOcrVlRuntimeInfo {
  const PaddleOcrVlRuntimeInfo({
    required this.success,
    required this.version,
    required this.systemInformation,
  });

  final bool success;
  final String version;
  final String systemInformation;
}

class PaddleOcrVlNativeException implements Exception {
  const PaddleOcrVlNativeException(this.message);

  final String message;

  @override
  String toString() => message;
}

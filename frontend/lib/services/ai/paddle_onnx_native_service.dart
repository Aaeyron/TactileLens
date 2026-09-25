import 'dart:io';

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

class PaddleOnnxNativeException implements Exception {
  const PaddleOnnxNativeException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

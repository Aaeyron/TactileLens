import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OfflineBrailleService {
  const OfflineBrailleService();

  static const MethodChannel _channel = MethodChannel(
    'com.tactilelens.app/liblouis',
  );

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const OfflineBrailleException(
        'Offline Braille translation is currently '
        'available only on Android.',
      );
    }

    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>('initialize');

      if (result?['success'] != true) {
        throw const OfflineBrailleException(
          'Liblouis could not be initialized.',
        );
      }
    } on PlatformException catch (error) {
      throw OfflineBrailleException(
        error.message ?? 'Liblouis could not be initialized.',
      );
    } on MissingPluginException {
      throw const OfflineBrailleException(
        'The offline Braille translator is unavailable. '
        'Reinstall the latest Android application build.',
      );
    }
  }

  Future<OfflineBrailleResult> translateText(String content) {
    return translateBlock(content, isFormula: false, isTable: false);
  }

  Future<OfflineBrailleResult> translateFormula(String content) {
    return translateBlock(content, isFormula: true, isTable: false);
  }

  Future<OfflineBrailleResult> translateBlock(
    String content, {
    required bool isFormula,
    bool isTable = false,
  }) async {
    final String normalizedContent = content.trim();

    final String expectedCode = isFormula || isTable ? 'nemeth' : 'ueb';

    if (normalizedContent.isEmpty) {
      return OfflineBrailleResult(
        success: true,
        code: expectedCode,
        content: '',
        error: null,
      );
    }

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return OfflineBrailleResult(
        success: false,
        code: expectedCode,
        content: '',
        error:
            'Offline Braille translation is currently '
            'available only on Android.',
      );
    }

    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>('translateBlock', <String, Object>{
            'content': normalizedContent,
            'isFormula': isFormula,
            'isTable': isTable,
          });

      if (result == null) {
        return OfflineBrailleResult(
          success: false,
          code: expectedCode,
          content: '',
          error: 'Liblouis returned no translation result.',
        );
      }

      final bool success = result['success'] == true;

      final String code = result['code'] is String
          ? result['code'] as String
          : expectedCode;

      final String translatedContent = result['content'] is String
          ? result['content'] as String
          : '';

      final String? error =
          result['error'] is String &&
              (result['error'] as String).trim().isNotEmpty
          ? (result['error'] as String).trim()
          : null;

      return OfflineBrailleResult(
        success: success && translatedContent.trim().isNotEmpty,
        code: code,
        content: translatedContent,
        error: error,
      );
    } on PlatformException catch (error) {
      return OfflineBrailleResult(
        success: false,
        code: expectedCode,
        content: '',
        error: error.message ?? 'Offline Braille translation failed.',
      );
    } on MissingPluginException {
      return OfflineBrailleResult(
        success: false,
        code: expectedCode,
        content: '',
        error:
            'The offline Braille translator is unavailable. '
            'Reinstall the latest Android application build.',
      );
    } catch (error) {
      debugPrint('Unexpected offline Braille error: $error');

      return OfflineBrailleResult(
        success: false,
        code: expectedCode,
        content: '',
        error:
            'An unexpected offline Braille translation '
            'error occurred.',
      );
    }
  }

  Future<String> runtimeVersion() async {
    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>('version');

      return result?['version'] is String
          ? result!['version'] as String
          : 'unknown';
    } on PlatformException {
      return 'unavailable';
    } on MissingPluginException {
      return 'unavailable';
    }
  }
}

class OfflineBrailleResult {
  const OfflineBrailleResult({
    required this.success,
    required this.code,
    required this.content,
    required this.error,
  });

  final bool success;
  final String code;
  final String content;
  final String? error;
}

class OfflineBrailleException implements Exception {
  const OfflineBrailleException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/ai/scan_document_result.dart';
import 'offline_ocr_service.dart';

class AIService {
  AIService({
    http.Client? client,
    OfflineOcrService? offlineOcrService,
    String? baseUrl,
    String? scanMode,
    this.requestTimeout = const Duration(minutes: 5),
  }) : _client = client ?? http.Client(),
       _offlineOcrService = offlineOcrService ?? OfflineOcrService(),
       _baseUrl = _normalizeBaseUrl(baseUrl ?? _configuredBaseUrl),
       _scanMode = _normalizeScanMode(scanMode ?? _configuredScanMode);

  static const String _configuredBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'http://10.0.2.2:5001',
  );

  /// Supported modes:
  ///
  /// offline:
  /// Always use the bundled on-device text recognizer.
  ///
  /// hybrid:
  /// Try PaddleOCR-VL first and use offline OCR if the server
  /// cannot be reached.
  ///
  /// remote:
  /// Require PaddleOCR-VL and report connection failures.
  static const String _configuredScanMode = String.fromEnvironment(
    'AI_SCAN_MODE',
    defaultValue: 'offline',
  );

  static const String offlineMode = 'offline';
  static const String hybridMode = 'hybrid';
  static const String remoteMode = 'remote';

  final http.Client _client;
  final OfflineOcrService _offlineOcrService;
  final String _baseUrl;
  final String _scanMode;
  final Duration requestTimeout;

  bool _disposed = false;

  Future<ScanDocumentResult> scanDocument(File imageFile) async {
    _ensureAvailable();

    if (!await imageFile.exists()) {
      throw const AIServiceException('The selected image could not be found.');
    }

    if (_scanMode == offlineMode) {
      return _scanOffline(imageFile);
    }

    try {
      return await _scanRemotely(imageFile);
    } on AIServiceConnectionException catch (error) {
      if (_scanMode != hybridMode) {
        rethrow;
      }

      debugPrint(
        'PaddleOCR-VL is unavailable. '
        'Using offline OCR instead: ${error.message}',
      );

      return _scanOffline(imageFile);
    }
  }

  Future<ScanDocumentResult> _scanOffline(File imageFile) async {
    debugPrint('Using bundled offline text recognition.');

    try {
      return await _offlineOcrService.scanDocument(imageFile);
    } on OfflineOcrException catch (error) {
      throw AIServiceException(error.message);
    }
  }

  Future<ScanDocumentResult> _scanRemotely(File imageFile) async {
    final int imageSize = await imageFile.length();

    debugPrint(
      'Sending scan to PaddleOCR-VL: '
      '${imageFile.path} (${_formatBytes(imageSize)})',
    );

    final Uri uri = Uri.parse('$_baseUrl/api/scan-document');

    debugPrint('AI endpoint: $uri');

    final Stopwatch stopwatch = Stopwatch()..start();

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    try {
      final http.StreamedResponse streamedResponse = await _client
          .send(request)
          .timeout(requestTimeout);

      final http.Response response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(requestTimeout);

      final Map<String, dynamic> payload = _decodePayload(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AIServiceException(
          _readErrorMessage(payload) ??
              'The AI service returned status '
                  '${response.statusCode}.',
        );
      }

      debugPrint(
        'PaddleOCR-VL scan completed in '
        '${stopwatch.elapsed.inSeconds} seconds.',
      );

      return ScanDocumentResult.fromJson(payload);
    } on TimeoutException {
      debugPrint(
        'AI scan timed out after '
        '${requestTimeout.inMinutes} minutes.',
      );

      throw const AIServiceConnectionException(
        'The PaddleOCR-VL service did not respond.',
      );
    } on SocketException catch (error) {
      debugPrint('AI socket connection failed: $error');

      throw const AIServiceConnectionException(
        'Unable to reach the PaddleOCR-VL service.',
      );
    } on FormatException catch (error) {
      throw AIServiceException(error.message);
    } on http.ClientException catch (error) {
      debugPrint('AI client connection failed: $error');

      throw AIServiceConnectionException(
        'AI connection failed: ${error.message}',
      );
    } on AIServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Unexpected PaddleOCR-VL error: $error');

      debugPrintStack(stackTrace: stackTrace);

      throw const AIServiceException(
        'An unexpected error occurred while scanning '
        'the document.',
      );
    } finally {
      stopwatch.stop();
    }
  }

  Map<String, dynamic> _decodePayload(String responseBody) {
    if (responseBody.trim().isEmpty) {
      throw const FormatException('The AI service returned an empty response.');
    }

    final dynamic decoded = jsonDecode(responseBody);

    if (decoded is! Map) {
      throw const FormatException('The AI service returned invalid data.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  String? _readErrorMessage(Map<String, dynamic> payload) {
    final dynamic detail = payload['detail'];
    final dynamic message = payload['message'];
    final dynamic error = payload['error'];

    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }

    return null;
  }

  void _ensureAvailable() {
    if (_disposed) {
      throw const AIServiceException(
        'The scanning service is no longer available.',
      );
    }
  }

  static String _normalizeScanMode(String value) {
    final String normalized = value.trim().toLowerCase();

    switch (normalized) {
      case hybridMode:
      case remoteMode:
        return normalized;
      case offlineMode:
      default:
        return offlineMode;
    }
  }

  static String _normalizeBaseUrl(String value) {
    final String normalized = value.trim();

    if (normalized.endsWith('/')) {
      return normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  static String _formatBytes(int bytes) {
    const int megabyte = 1024 * 1024;

    if (bytes >= megabyte) {
      return '${(bytes / megabyte).toStringAsFixed(1)} MB';
    }

    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _client.close();

    unawaited(_offlineOcrService.dispose());
  }
}

class AIServiceException implements Exception {
  const AIServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AIServiceConnectionException extends AIServiceException {
  const AIServiceConnectionException(super.message);
}

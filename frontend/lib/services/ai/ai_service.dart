import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/ai/scan_document_result.dart';
import '../../utils/session_manager.dart';
import 'offline_ocr_service.dart';

class AIService {
  AIService({
    http.Client? client,
    OfflineOcrService? offlineOcrService,
    String? baseUrl,
    String? scanMode,
    this.requestTimeout = const Duration(minutes: 3),
  }) : _client = client ?? http.Client(),
       _offlineOcrService = offlineOcrService ?? OfflineOcrService(),
       _baseUrl = _normalizeBaseUrl(baseUrl ?? _configuredBaseUrl),
       _scanMode = _normalizeScanMode(scanMode ?? _configuredScanMode);

  static const String _configuredBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
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
  ///
  /// session:
  /// Guest users use offline. Signed-in users use remote.
  static const String _configuredScanMode = String.fromEnvironment(
    'AI_SCAN_MODE',
    defaultValue: 'session',
  );

  static const String offlineMode = 'offline';
  static const String hybridMode = 'hybrid';
  static const String remoteMode = 'remote';
  static const String sessionMode = 'session';

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

    String effectiveMode = _scanMode;

    if (effectiveMode == sessionMode) {
      if (await SessionManager.isGuest()) {
        effectiveMode = offlineMode;
      } else if (await SessionManager.isLoggedIn()) {
        effectiveMode = remoteMode;
      } else {
        throw const AIServiceException(
          'Please sign in or enter Guest Mode before scanning.',
        );
      }
    }

    _ensureAvailable();

    debugPrint('OCR selected mode: $effectiveMode');

    if (effectiveMode == offlineMode) {
      return _scanOffline(imageFile);
    }

    try {
      return await _scanRemotely(imageFile);
    } on AIServiceConnectionException catch (error) {
      if (effectiveMode != hybridMode) {
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

    final String? token = await SessionManager.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const AIServiceException(
        'Your session has expired. Please sign in again to use online scanning.',
      );
    }

    // Sent once, never retried: after a 502/503, or a connection that
    // drops mid-request, the image may already have reached the hosted
    // OCR service, and sending it again would start a second job.
    return _sendScanRequest(uri, token, imageFile);
  }

  Future<ScanDocumentResult> _sendScanRequest(
    Uri uri,
    String token,
    File imageFile,
  ) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final http.MultipartRequest request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final http.StreamedResponse streamedResponse = await _client
          .send(request)
          .timeout(requestTimeout);

      final http.Response response = await http.Response.fromStream(
        streamedResponse,
      );

      final Map<String, dynamic>? payload = _tryDecodePayload(response.body);

      if (response.statusCode == 401) {
        throw const AIServiceException(
          'Your session has expired. Please sign in again to use online scanning.',
        );
      }

      // Node returns 502-504 when the AI server behind it is unreachable.
      // Treat these as connection errors so hybrid mode can fall back.
      if (response.statusCode == 504) {
        throw AIServiceException(
          _readErrorMessage(payload) ??
              'The AI service did not respond in time.',
        );
      }

      if (response.statusCode == 502 || response.statusCode == 503) {
        throw AIServiceConnectionException(
          _readErrorMessage(payload) ?? 'The AI service is unavailable.',
        );
      }

      if (payload == null) {
        throw const AIServiceException('The AI service returned invalid data.');
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

      throw const AIServiceException(
        'This scan took too long. Try again with a clearer photo.',
      );
    } on SocketException catch (error) {
      debugPrint('AI socket connection failed: $error');

      throw const AIServiceConnectionException(
        'Unable to reach the PaddleOCR-VL service.',
      );
    } on http.ClientException catch (error) {
      debugPrint('AI client connection failed: $error');

      throw const AIServiceConnectionException(
        'Unable to reach the scanning service. Check your connection and try again.',
      );
    } on FileSystemException {
      throw const AIServiceException('The selected image could not be read.');
    } on AIServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Unexpected PaddleOCR-VL error: $error');

      debugPrintStack(stackTrace: stackTrace);

      throw const AIServiceException(
        'An unexpected error occurred while scanning the document.',
      );
    } finally {
      stopwatch.stop();
    }
  }

  Map<String, dynamic>? _tryDecodePayload(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(responseBody);

      if (decoded is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
  }

  String? _readErrorMessage(Map<String, dynamic>? payload) {
    if (payload == null) {
      return null;
    }

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
      case sessionMode:
      case offlineMode:
      case hybridMode:
      case remoteMode:
        return normalized;
      default:
        throw ArgumentError.value(
          value,
          'scanMode',
          'Expected session, offline, hybrid, or remote.',
        );
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

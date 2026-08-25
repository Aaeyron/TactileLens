import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/ai/scan_document_result.dart';

class AIService {
  AIService({
    http.Client? client,
    String? baseUrl,
    this.requestTimeout = const Duration(minutes: 5),
  }) : _client = client ?? http.Client(),
       _baseUrl = _normalizeBaseUrl(baseUrl ?? _configuredBaseUrl);

  static const String _configuredBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'http://10.0.2.2:5001',
  );

  final http.Client _client;
  final String _baseUrl;
  final Duration requestTimeout;

  Future<ScanDocumentResult> scanDocument(File imageFile) async {
    if (!await imageFile.exists()) {
      throw const AIServiceException('The selected image could not be found.');
    }

    final int imageSize = await imageFile.length();

    debugPrint(
      'Sending scan to AI: ${imageFile.path} '
      '(${_formatBytes(imageSize)})',
    );

    debugPrint(
      'AI endpoint: '
      '$_baseUrl/api/scan-document',
    );

    final Stopwatch stopwatch = Stopwatch()..start();

    final Uri uri = Uri.parse('$_baseUrl/api/scan-document');

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
        'AI scan completed in '
        '${stopwatch.elapsed.inSeconds} seconds.',
      );

      return ScanDocumentResult.fromJson(payload);
    } on TimeoutException {
      debugPrint(
        'AI scan timed out after '
        '${requestTimeout.inMinutes} minutes.',
      );

      throw const AIServiceException(
        'The document is taking longer than expected to process. '
        'Try cropping the image or scanning it again with clearer lighting.',
      );
    } on SocketException catch (error) {
      debugPrint('AI socket connection failed: $error');

      throw const AIServiceException(
        'Unable to reach the AI service. '
        'Check that the AI server is running.',
      );
    } on FormatException catch (error) {
      throw AIServiceException(error.message);
    } on http.ClientException catch (error) {
      throw AIServiceException('AI connection failed: ${error.message}');
    } on AIServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Unexpected AI service error: $error');

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
    _client.close();
  }
}

class AIServiceException implements Exception {
  const AIServiceException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}

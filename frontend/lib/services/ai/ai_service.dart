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
    Duration requestTimeout = const Duration(minutes: 2),
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _configuredBaseUrl,
        _requestTimeout = requestTimeout;

  static const String _configuredBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'http://10.0.2.2:5001',
  );

  final http.Client _client;
  final String _baseUrl;
  final Duration _requestTimeout;

  Future<ScanDocumentResult> scanDocument(File imageFile) async {
    if (!await imageFile.exists()) {
      throw const AIServiceException('The selected image could not be found.');
    }

    final uri = Uri.parse('$_baseUrl/api/scan-document');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      final payload = _decodePayload(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AIServiceException(
          _readErrorMessage(payload) ??
              'The AI service returned status ${response.statusCode}.',
        );
      }

      return ScanDocumentResult.fromJson(payload);
    } on TimeoutException {
      throw const AIServiceException(
        'Document scanning took too long. Please try again.',
      );
    } on SocketException {
      throw const AIServiceException(
        'Unable to reach the AI service. Check the server and network.',
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
        'An unexpected error occurred while scanning the document.',
      );
    }
  }

  Map<String, dynamic> _decodePayload(String responseBody) {
    if (responseBody.trim().isEmpty) {
      throw const FormatException('The AI service returned an empty response.');
    }

    final decoded = jsonDecode(responseBody);

    if (decoded is! Map) {
      throw const FormatException('The AI service returned invalid data.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  String? _readErrorMessage(Map<String, dynamic> payload) {
    final detail = payload['detail'];
    final message = payload['message'];
    final error = payload['error'];

    if (detail is String && detail.isNotEmpty) return detail;
    if (message is String && message.isNotEmpty) return message;
    if (error is String && error.isNotEmpty) return error;
    return null;
  }

  void dispose() {
    _client.close();
  }
}

class AIServiceException implements Exception {
  const AIServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}


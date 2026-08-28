import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../database/history/history_database.dart';
import '../../models/history/history_model.dart';
import '../../utils/session_manager.dart';
import '../auth/auth_service.dart';

class HistoryService {
  HistoryService({
    http.Client? client,
    this._requestTimeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _requestTimeout;

  static const int defaultPage = 1;
  static const int defaultLimit = 20;

  // ==========================
  // Create History
  // ==========================

  Future<HistoryRecord> createHistory({
    required String title,
    required String recognizedContent,
    required String brailleContent,
    required List<Map<String, dynamic>> documentBlocks,
    String? sourceImagePath,
    String? modelName,
    String? pipelineVersion,
    double? processingTimeMs,
  }) async {
    final String cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw const HistoryServiceException(
        'The history title must not be empty.',
      );
    }

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      return HistoryDatabase.instance.insertHistory(
        title: cleanTitle,
        recognizedContent: recognizedContent,
        brailleContent: brailleContent,
        documentBlocks: documentBlocks,
        sourceImagePath: sourceImagePath,
        modelName: modelName,
        pipelineVersion: pipelineVersion,
        processingTimeMs: processingTimeMs,
      );
    }

    final Uri uri = Uri.parse('${AuthService.baseUrl}/api/history');

    final http.Response response = await _send(
      () async => _client.post(
        uri,
        headers: await _authorizedHeaders(),
        body: jsonEncode(<String, dynamic>{
          'title': cleanTitle,
          'recognized_content': recognizedContent.trim(),
          'braille_content': brailleContent.trim(),
          'document_blocks': documentBlocks,
          'model_name': _nullableText(modelName),
          'pipeline_version': _nullableText(pipelineVersion),
          'processing_time_ms': processingTimeMs,
        }),
      ),
    );

    final Map<String, dynamic> payload = _decodeResponse(response);

    return _readHistoryRecord(payload);
  }

  // ==========================
  // List History
  // ==========================

  Future<HistoryPage> getHistory({
    int page = defaultPage,
    int limit = defaultLimit,
  }) async {
    if (page <= 0) {
      throw const HistoryServiceException(
        'The page number must be greater than zero.',
      );
    }

    if (limit <= 0 || limit > 100) {
      throw const HistoryServiceException(
        'The history limit must be between 1 and 100.',
      );
    }

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      return HistoryDatabase.instance.getHistory(page: page, limit: limit);
    }

    final Uri uri = Uri.parse('${AuthService.baseUrl}/api/history').replace(
      queryParameters: <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final http.Response response = await _send(
      () async => _client.get(uri, headers: await _authorizedHeaders()),
    );

    final Map<String, dynamic> payload = _decodeResponse(response);

    return HistoryPage.fromJson(payload);
  }

  // ==========================
  // Get One History Record
  // ==========================

  Future<HistoryRecord> getHistoryById(int historyId) async {
    _validateHistoryId(historyId);

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      final HistoryRecord? record = await HistoryDatabase.instance
          .getHistoryById(historyId);

      if (record == null) {
        throw const HistoryServiceException(
          'The history record could not be found.',
          statusCode: 404,
        );
      }

      return record;
    }

    final Uri uri = Uri.parse('${AuthService.baseUrl}/api/history/$historyId');

    final http.Response response = await _send(
      () async => _client.get(uri, headers: await _authorizedHeaders()),
    );

    final Map<String, dynamic> payload = _decodeResponse(response);

    return _readHistoryRecord(payload);
  }

  // ==========================
  // Rename History
  // ==========================

  Future<HistoryRecord> renameHistory({
    required int historyId,
    required String title,
  }) async {
    _validateHistoryId(historyId);

    final String cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw const HistoryServiceException(
        'The history title must not be empty.',
      );
    }

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      final HistoryRecord? record = await HistoryDatabase.instance
          .renameHistory(historyId: historyId, title: cleanTitle);

      if (record == null) {
        throw const HistoryServiceException(
          'The history record could not be found.',
          statusCode: 404,
        );
      }

      return record;
    }

    final Uri uri = Uri.parse('${AuthService.baseUrl}/api/history/$historyId');

    final http.Response response = await _send(
      () async => _client.patch(
        uri,
        headers: await _authorizedHeaders(),
        body: jsonEncode(<String, dynamic>{'title': cleanTitle}),
      ),
    );

    final Map<String, dynamic> payload = _decodeResponse(response);

    return _readHistoryRecord(payload);
  }

  // ==========================
  // Delete History
  // ==========================

  Future<void> deleteHistory(int historyId) async {
    _validateHistoryId(historyId);

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      final int deletedRows = await HistoryDatabase.instance.deleteHistory(
        historyId,
      );

      if (deletedRows == 0) {
        throw const HistoryServiceException(
          'The history record could not be found.',
          statusCode: 404,
        );
      }

      return;
    }

    final Uri uri = Uri.parse('${AuthService.baseUrl}/api/history/$historyId');

    final http.Response response = await _send(
      () async => _client.delete(uri, headers: await _authorizedHeaders()),
    );

    _decodeResponse(response);
  }

  // ==========================
  // Authentication Headers
  // ==========================

  Future<Map<String, String>> _authorizedHeaders() async {
    final String? accessToken = await SessionManager.getAccessToken();

    if (accessToken == null) {
      throw const HistoryAuthenticationException(
        'Please sign in to access your scan history.',
      );
    }

    return <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==========================
  // Request Handling
  // ==========================

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const HistoryServiceException(
        'The history request took too long. Please try again.',
      );
    } on SocketException {
      throw const HistoryServiceException(
        'Unable to reach the TactileLens server.',
      );
    } on http.ClientException catch (error) {
      throw HistoryServiceException(
        'History connection failed: ${error.message}',
      );
    } on HistoryServiceException {
      rethrow;
    } catch (error) {
      throw HistoryServiceException(
        'An unexpected history error occurred: $error',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final Map<String, dynamic> payload = _decodePayload(response.body);

    if (response.statusCode == 401) {
      throw HistoryAuthenticationException(
        _readMessage(payload) ??
            'Your session has expired. Please sign in again.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HistoryServiceException(
        _readMessage(payload) ??
            'The history request failed with status '
                '${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    if (payload['success'] != true) {
      throw HistoryServiceException(
        _readMessage(payload) ?? 'The history request was unsuccessful.',
      );
    }

    return payload;
  }

  Map<String, dynamic> _decodePayload(String responseBody) {
    if (responseBody.trim().isEmpty) {
      throw const HistoryServiceException(
        'The server returned an empty response.',
      );
    }

    try {
      final dynamic decoded = jsonDecode(responseBody);

      if (decoded is! Map) {
        throw const FormatException();
      }

      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const HistoryServiceException(
        'The server returned invalid history data.',
      );
    }
  }

  HistoryRecord _readHistoryRecord(Map<String, dynamic> payload) {
    final dynamic rawRecord = payload['data'];

    if (rawRecord is! Map) {
      throw const HistoryServiceException(
        'The history record is missing from the response.',
      );
    }

    try {
      return HistoryRecord.fromJson(Map<String, dynamic>.from(rawRecord));
    } on FormatException catch (error) {
      throw HistoryServiceException(error.message);
    }
  }

  String? _readMessage(Map<String, dynamic> payload) {
    final dynamic message = payload['message'] ?? payload['error'];

    if (message is! String || message.trim().isEmpty) {
      return null;
    }

    return message.trim();
  }

  String? _nullableText(String? value) {
    final String? cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }

  void _validateHistoryId(int historyId) {
    if (historyId <= 0) {
      throw const HistoryServiceException('The history ID is invalid.');
    }
  }

  void dispose() {
    _client.close();
  }
}

class HistoryServiceException implements Exception {
  const HistoryServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class HistoryAuthenticationException extends HistoryServiceException {
  const HistoryAuthenticationException(super.message) : super(statusCode: 401);
}

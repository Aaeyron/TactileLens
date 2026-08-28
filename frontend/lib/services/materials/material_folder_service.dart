import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../database/materials/material_database.dart';
import '../../database/materials/material_folder_database.dart';
import '../../models/materials/material_folder_model.dart';
import '../../utils/session_manager.dart';
import '../auth/auth_service.dart';

class MaterialFolderService {
  MaterialFolderService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration requestTimeout;

  static String get baseUrl {
    return '${AuthService.baseUrl}/api/material-folders';
  }

  // ==========================
  // Get Folders
  // ==========================

  Future<List<MaterialFolderModel>> getFolders() async {
    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      return MaterialFolderDatabase.instance.getFolders();
    }

    final http.Response response = await _send(() async {
      return _client.get(
        Uri.parse(baseUrl),
        headers: await _authorizedHeaders(),
      );
    });

    final Map<String, dynamic> payload = _decodePayload(response);

    final dynamic rawFolders = payload['data'];

    if (rawFolders is! List) {
      throw const MaterialFolderServiceException(
        'The server returned invalid folder data.',
      );
    }

    return List<MaterialFolderModel>.unmodifiable(
      rawFolders.whereType<Map>().map((Map folder) {
        return MaterialFolderModel.fromJson(Map<String, dynamic>.from(folder));
      }),
    );
  }

  // ==========================
  // Create Folder
  // ==========================

  Future<MaterialFolderModel> createFolder(String name) async {
    final String normalizedName = _validateFolderName(name);

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      try {
        return await MaterialFolderDatabase.instance.createFolder(
          normalizedName,
        );
      } on DatabaseException catch (error) {
        if (_isDuplicateDatabaseError(error)) {
          throw const MaterialFolderServiceException(
            'You already have a folder with this name.',
            statusCode: 409,
          );
        }

        throw const MaterialFolderServiceException(
          'Unable to create the folder.',
        );
      }
    }

    final http.Response response = await _send(() async {
      return _client.post(
        Uri.parse(baseUrl),
        headers: await _authorizedHeaders(),
        body: jsonEncode(<String, dynamic>{'name': normalizedName}),
      );
    });

    return _readFolderResponse(response);
  }

  // ==========================
  // Rename Folder
  // ==========================

  Future<MaterialFolderModel> renameFolder({
    required int folderId,
    required String name,
  }) async {
    _validatePositiveId(folderId, message: 'The folder ID is invalid.');

    final String normalizedName = _validateFolderName(name);

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      try {
        final MaterialFolderModel? folder = await MaterialFolderDatabase
            .instance
            .renameFolder(folderId: folderId, name: normalizedName);

        if (folder == null) {
          throw const MaterialFolderServiceException(
            'Folder not found.',
            statusCode: 404,
          );
        }

        return folder;
      } on DatabaseException catch (error) {
        if (_isDuplicateDatabaseError(error)) {
          throw const MaterialFolderServiceException(
            'You already have a folder with this name.',
            statusCode: 409,
          );
        }

        throw const MaterialFolderServiceException(
          'Unable to rename the folder.',
        );
      }
    }

    final http.Response response = await _send(() async {
      return _client.patch(
        Uri.parse('$baseUrl/$folderId'),
        headers: await _authorizedHeaders(),
        body: jsonEncode(<String, dynamic>{'name': normalizedName}),
      );
    });

    return _readFolderResponse(response);
  }

  // ==========================
  // Delete Folder
  // ==========================

  Future<void> deleteFolder(int folderId) async {
    _validatePositiveId(folderId, message: 'The folder ID is invalid.');

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      final bool deleted = await MaterialFolderDatabase.instance.deleteFolder(
        folderId,
      );

      if (!deleted) {
        throw const MaterialFolderServiceException(
          'Folder not found.',
          statusCode: 404,
        );
      }

      return;
    }

    final http.Response response = await _send(() async {
      return _client.delete(
        Uri.parse('$baseUrl/$folderId'),
        headers: await _authorizedHeaders(),
      );
    });

    _decodePayload(response);
  }

  // ==========================
  // Move Material
  // ==========================

  Future<void> moveMaterialToFolder({
    required int materialId,
    required int? folderId,
  }) async {
    _validatePositiveId(materialId, message: 'The material ID is invalid.');

    if (folderId != null) {
      _validatePositiveId(folderId, message: 'The folder ID is invalid.');
    }

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      if (folderId != null) {
        final MaterialFolderModel? folder = await MaterialFolderDatabase
            .instance
            .getFolderById(folderId);

        if (folder == null) {
          throw const MaterialFolderServiceException(
            'Folder not found.',
            statusCode: 404,
          );
        }
      }

      final int affectedRows = await MaterialDatabase.instance
          .updateMaterialFolder(materialId: materialId, folderId: folderId);

      if (affectedRows == 0) {
        throw const MaterialFolderServiceException(
          'Material not found.',
          statusCode: 404,
        );
      }

      return;
    }

    final http.Response response = await _send(() async {
      return _client.patch(
        Uri.parse('$baseUrl/materials/$materialId'),
        headers: await _authorizedHeaders(),
        body: jsonEncode(<String, dynamic>{'folder_id': folderId}),
      );
    });

    _decodePayload(response);
  }

  // ==========================
  // Response Helpers
  // ==========================

  MaterialFolderModel _readFolderResponse(http.Response response) {
    final Map<String, dynamic> payload = _decodePayload(response);

    final dynamic rawFolder = payload['data'];

    if (rawFolder is! Map) {
      throw const MaterialFolderServiceException(
        'The server returned invalid folder data.',
      );
    }

    return MaterialFolderModel.fromJson(Map<String, dynamic>.from(rawFolder));
  }

  String _validateFolderName(String name) {
    final String normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw const MaterialFolderServiceException('A folder name is required.');
    }

    if (normalizedName.length > 80) {
      throw const MaterialFolderServiceException(
        'Folder names cannot exceed 80 characters.',
      );
    }

    return normalizedName;
  }

  void _validatePositiveId(int id, {required String message}) {
    if (id <= 0) {
      throw MaterialFolderServiceException(message);
    }
  }

  bool _isDuplicateDatabaseError(DatabaseException error) {
    final String message = error.toString().toLowerCase();

    return message.contains('unique') || message.contains('constraint');
  }

  // ==========================
  // Authentication
  // ==========================

  Future<Map<String, String>> _authorizedHeaders() async {
    final String? accessToken = await SessionManager.getAccessToken();

    if (accessToken == null) {
      throw const MaterialFolderAuthenticationException(
        'Please sign in to manage folders.',
      );
    }

    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  // ==========================
  // HTTP Wrapper
  // ==========================

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(requestTimeout);
    } on TimeoutException {
      throw const MaterialFolderServiceException(
        'The folder request took too long. Please try again.',
      );
    } on SocketException {
      throw const MaterialFolderServiceException(
        'Unable to reach the TactileLens server.',
      );
    } on http.ClientException catch (error) {
      throw MaterialFolderServiceException(
        'Folder connection failed: ${error.message}',
      );
    }
  }

  // ==========================
  // Response Decoder
  // ==========================

  Map<String, dynamic> _decodePayload(http.Response response) {
    Map<String, dynamic> payload = <String, dynamic>{};

    if (response.body.trim().isNotEmpty) {
      try {
        final dynamic decodedBody = jsonDecode(response.body);

        if (decodedBody is Map) {
          payload = Map<String, dynamic>.from(decodedBody);
        }
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw const MaterialFolderServiceException(
            'The server returned invalid folder data.',
          );
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    final String message =
        _readErrorMessage(payload) ??
        'The folder request failed with '
            'status ${response.statusCode}.';

    if (response.statusCode == 401) {
      throw MaterialFolderAuthenticationException(message);
    }

    throw MaterialFolderServiceException(
      message,
      statusCode: response.statusCode,
    );
  }

  String? _readErrorMessage(Map<String, dynamic> payload) {
    for (final String key in <String>['message', 'detail', 'error']) {
      final dynamic value = payload[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}

class MaterialFolderServiceException implements Exception {
  const MaterialFolderServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    return message;
  }
}

class MaterialFolderAuthenticationException
    extends MaterialFolderServiceException {
  const MaterialFolderAuthenticationException(super.message)
    : super(statusCode: 401);
}

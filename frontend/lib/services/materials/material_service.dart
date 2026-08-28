import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../database/materials/material_database.dart';
import '../../database/materials/material_folder_database.dart';
import '../../models/materials/material_model.dart';
import '../../utils/session_manager.dart';
import '../auth/auth_service.dart';

class MaterialService {
  MaterialService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration requestTimeout;

  static String get serverUrl {
    return AuthService.baseUrl;
  }

  static String get baseUrl {
    return '$serverUrl/api/materials';
  }

  // ==========================
  // File URL Builder
  // ==========================

  String getFileUrl(String filePath) {
    final String normalizedPath = filePath
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');

    return Uri.parse('$serverUrl/').resolve(normalizedPath).toString();
  }

  // ==========================
  // Get All Materials
  // ==========================

  Future<List<MaterialModel>> getMaterials() async {
    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      return MaterialDatabase.instance.getAllMaterials();
    }

    final Uri uri = Uri.parse(baseUrl);

    final http.Response response = await _send(() async {
      return _client.get(uri, headers: await _authorizedHeaders());
    });

    final Map<String, dynamic> payload = _decodePayload(response);

    final dynamic rawMaterials = payload['data'];

    if (rawMaterials is! List) {
      throw const MaterialServiceException(
        'The server returned invalid material data.',
      );
    }

    return List<MaterialModel>.unmodifiable(
      rawMaterials.whereType<Map>().map((Map material) {
        return MaterialModel.fromJson(Map<String, dynamic>.from(material));
      }),
    );
  }

  // ==========================
  // Upload or Save Material
  // ==========================

  Future<MaterialModel> uploadMaterial({
    required File file,

    // Retained temporarily for compatibility with
    // existing callers. The authenticated backend now
    // reads the user ID from the JWT instead.
    int? userId,

    required String title,
    required String subject,
    String? description,
    String sourceType = MaterialModel.uploadedFileSourceType,
    String recognizedContent = '',
    String brailleContent = '',
    List<Map<String, dynamic>> documentBlocks = const <Map<String, dynamic>>[],
    String? modelName,
    String? pipelineVersion,
    double? processingTimeMs,
  }) async {
    final String cleanTitle = title.trim();
    final String cleanSubject = subject.trim();

    if (cleanTitle.isEmpty) {
      throw const MaterialServiceException('The material title is required.');
    }

    if (cleanSubject.isEmpty) {
      throw const MaterialServiceException('The material subject is required.');
    }

    if (!await file.exists()) {
      throw const MaterialServiceException(
        'The selected material file could not be found.',
      );
    }

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      return _saveGuestMaterial(
        file: file,
        title: cleanTitle,
        subject: cleanSubject,
        description: description,
        sourceType: sourceType,
        recognizedContent: recognizedContent,
        brailleContent: brailleContent,
        documentBlocks: documentBlocks,
        modelName: modelName,
        pipelineVersion: pipelineVersion,
        processingTimeMs: processingTimeMs,
      );
    }

    return _uploadAuthenticatedMaterial(
      file: file,
      title: cleanTitle,
      subject: cleanSubject,
      description: description,
      sourceType: sourceType,
      recognizedContent: recognizedContent,
      brailleContent: brailleContent,
      documentBlocks: documentBlocks,
      modelName: modelName,
      pipelineVersion: pipelineVersion,
      processingTimeMs: processingTimeMs,
    );
  }

  // ==========================
  // Save Guest Material
  // ==========================

  Future<MaterialModel> _saveGuestMaterial({
    required File file,
    required String title,
    required String subject,
    required String? description,
    required String sourceType,
    required String recognizedContent,
    required String brailleContent,
    required List<Map<String, dynamic>> documentBlocks,
    required String? modelName,
    required String? pipelineVersion,
    required double? processingTimeMs,
  }) async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();

    final Directory materialsDirectory = Directory(
      path.join(appDirectory.path, 'materials'),
    );

    if (!await materialsDirectory.exists()) {
      await materialsDirectory.create(recursive: true);
    }

    final String storedFileName =
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${path.basename(file.path)}';

    final File savedFile = await file.copy(
      path.join(materialsDirectory.path, storedFileName),
    );

    final MaterialModel material = MaterialModel(
      title: title,
      subject: subject,
      description: description?.trim() ?? '',
      fileName: storedFileName,
      fileType: path.extension(file.path),
      fileSize: await savedFile.length(),
      filePath: savedFile.path,
      uploadDate: DateTime.now(),
      sourceType: sourceType,
      recognizedContent: recognizedContent.trim(),
      brailleContent: brailleContent.trim(),
      documentBlocks: List<Map<String, dynamic>>.unmodifiable(documentBlocks),
      modelName: _nullableText(modelName),
      pipelineVersion: _nullableText(pipelineVersion),
      processingTimeMs: processingTimeMs,
    );

    try {
      final int id = await MaterialDatabase.instance.insertMaterial(material);

      return MaterialModel(
        id: id,
        title: material.title,
        subject: material.subject,
        description: material.description,
        fileName: material.fileName,
        fileType: material.fileType,
        fileSize: material.fileSize,
        filePath: material.filePath,
        uploadDate: material.uploadDate,
        sourceType: material.sourceType,
        recognizedContent: material.recognizedContent,
        brailleContent: material.brailleContent,
        documentBlocks: material.documentBlocks,
        modelName: material.modelName,
        pipelineVersion: material.pipelineVersion,
        processingTimeMs: material.processingTimeMs,
      );
    } catch (_) {
      try {
        if (await savedFile.exists()) {
          await savedFile.delete();
        }
      } catch (_) {
        // The original database error is more useful.
      }

      rethrow;
    }
  }

  // ==========================
  // Upload Authenticated Material
  // ==========================

  Future<MaterialModel> _uploadAuthenticatedMaterial({
    required File file,
    required String title,
    required String subject,
    required String? description,
    required String sourceType,
    required String recognizedContent,
    required String brailleContent,
    required List<Map<String, dynamic>> documentBlocks,
    required String? modelName,
    required String? pipelineVersion,
    required double? processingTimeMs,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/upload');

    final http.MultipartRequest request = http.MultipartRequest('POST', uri);

    request.headers.addAll(await _authorizedHeaders(includeContentType: false));

    request.fields.addAll(<String, String>{
      'title': title,
      'subject': subject,
      'source_type': sourceType,
      'recognized_content': recognizedContent.trim(),
      'braille_content': brailleContent.trim(),
      'document_blocks': jsonEncode(documentBlocks),
    });

    final String? cleanDescription = _nullableText(description);

    final String? cleanModelName = _nullableText(modelName);

    final String? cleanPipelineVersion = _nullableText(pipelineVersion);

    if (cleanDescription != null) {
      request.fields['description'] = cleanDescription;
    }

    if (cleanModelName != null) {
      request.fields['model_name'] = cleanModelName;
    }

    if (cleanPipelineVersion != null) {
      request.fields['pipeline_version'] = cleanPipelineVersion;
    }

    if (processingTimeMs != null) {
      request.fields['processing_time_ms'] = processingTimeMs.toString();
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final http.Response response = await _send(() async {
      final http.StreamedResponse streamedResponse = await _client.send(
        request,
      );

      return http.Response.fromStream(streamedResponse);
    });

    final Map<String, dynamic> payload = _decodePayload(response);

    final dynamic materialData = payload['data'];

    if (materialData is! Map) {
      throw const MaterialServiceException(
        'The server returned invalid material data.',
      );
    }

    return MaterialModel.fromJson(Map<String, dynamic>.from(materialData));
  }

  // ==========================
  // Move Material to Folder
  // ==========================

  Future<MaterialModel> moveMaterialToFolder({
    required int materialId,
    required int? folderId,
  }) async {
    if (materialId <= 0) {
      throw const MaterialServiceException('The material ID is invalid.');
    }

    if (folderId != null && folderId <= 0) {
      throw const MaterialServiceException('The folder ID is invalid.');
    }

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      return _moveGuestMaterialToFolder(
        materialId: materialId,
        folderId: folderId,
      );
    }

    final Uri uri = Uri.parse('$baseUrl/$materialId/folder');

    final http.Response response = await _send(() async {
      return _client.patch(
        uri,
        headers: await _authorizedHeaders(),
        body: jsonEncode(<String, dynamic>{'folder_id': folderId}),
      );
    });

    final Map<String, dynamic> payload = _decodePayload(response);

    final dynamic materialData = payload['data'];

    if (materialData is! Map) {
      throw const MaterialServiceException(
        'The server returned invalid material data.',
      );
    }

    return MaterialModel.fromJson(Map<String, dynamic>.from(materialData));
  }

  // ==========================
  // Move Guest Material to Folder
  // ==========================

  Future<MaterialModel> _moveGuestMaterialToFolder({
    required int materialId,
    required int? folderId,
  }) async {
    final MaterialModel? existingMaterial = await MaterialDatabase.instance
        .getMaterialById(materialId);

    if (existingMaterial == null) {
      throw const MaterialServiceException(
        'Material not found.',
        statusCode: 404,
      );
    }

    if (folderId != null) {
      final folder = await MaterialFolderDatabase.instance.getFolderById(
        folderId,
      );

      if (folder == null) {
        throw const MaterialServiceException(
          'The selected folder could not be found.',
          statusCode: 404,
        );
      }
    }

    final int affectedRows = await MaterialDatabase.instance
        .updateMaterialFolder(materialId: materialId, folderId: folderId);

    if (affectedRows == 0) {
      throw const MaterialServiceException('The material could not be moved.');
    }

    final MaterialModel? updatedMaterial = await MaterialDatabase.instance
        .getMaterialById(materialId);

    if (updatedMaterial == null) {
      throw const MaterialServiceException(
        'The updated material could not be loaded.',
      );
    }

    return updatedMaterial;
  }

  // ==========================
  // Delete Material
  // ==========================

  Future<void> deleteMaterial(int id) async {
    if (id <= 0) {
      throw const MaterialServiceException('The material ID is invalid.');
    }

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      await _deleteGuestMaterial(id);
      return;
    }

    final Uri uri = Uri.parse('$baseUrl/$id');

    final http.Response response = await _send(() async {
      return _client.delete(uri, headers: await _authorizedHeaders());
    });

    _decodePayload(response);
  }

  // ==========================
  // Delete Guest Material
  // ==========================

  Future<void> _deleteGuestMaterial(int id) async {
    final MaterialModel? material = await MaterialDatabase.instance
        .getMaterialById(id);

    if (material == null) {
      throw const MaterialServiceException('Material not found.');
    }

    final File storedFile = File(material.filePath);

    await MaterialDatabase.instance.deleteMaterial(id);

    try {
      if (await storedFile.exists()) {
        await storedFile.delete();
      }
    } catch (_) {
      // The database record is already removed.
    }
  }

  // ==========================
  // Authentication Headers
  // ==========================

  Future<Map<String, String>> _authorizedHeaders({
    bool includeContentType = true,
  }) async {
    final String? accessToken = await SessionManager.getAccessToken();

    if (accessToken == null) {
      throw const MaterialAuthenticationException(
        'Please sign in to access your materials.',
      );
    }

    return <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      if (includeContentType) 'Content-Type': 'application/json',
    };
  }

  // ==========================
  // HTTP Request Wrapper
  // ==========================

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(requestTimeout);
    } on TimeoutException {
      throw const MaterialServiceException(
        'The materials request took too long. Please try again.',
      );
    } on SocketException {
      throw const MaterialServiceException(
        'Unable to reach the TactileLens server.',
      );
    } on http.ClientException catch (error) {
      throw MaterialServiceException(
        'Materials connection failed: '
        '${error.message}',
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
          throw const MaterialServiceException(
            'The server returned invalid data.',
          );
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    final String message =
        _readErrorMessage(payload) ??
        'The materials request failed with '
            'status ${response.statusCode}.';

    if (response.statusCode == 401) {
      throw MaterialAuthenticationException(message);
    }

    throw MaterialServiceException(message, statusCode: response.statusCode);
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

  String? _nullableText(String? value) {
    final String normalizedValue = value?.trim() ?? '';

    return normalizedValue.isEmpty ? null : normalizedValue;
  }

  void dispose() {
    _client.close();
  }
}

class MaterialServiceException implements Exception {
  const MaterialServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class MaterialAuthenticationException extends MaterialServiceException {
  const MaterialAuthenticationException(super.message) : super(statusCode: 401);
}

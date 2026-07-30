import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:http/http.dart' as http;

import '../../models/materials/material_model.dart';
import '../../database/materials/material_database.dart';
import '../../utils/session_manager.dart';

class MaterialService {

  // ==========================
  // Backend Base URL
  // ==========================

  static const String serverUrl =
      'http://192.168.1.5:5000';

  static const String baseUrl =
      '$serverUrl/api/materials';


  // ==========================
  // File URL Builder
  // ==========================

  String getFileUrl(String filePath) {
  final normalizedPath =
      filePath.replaceAll('\\', '/');

  return '$serverUrl/$normalizedPath';
}

  // ==========================
  // Get All Materials
  // ==========================

  Future<List<MaterialModel>> getMaterials() async {
    final isGuest = await SessionManager.isGuest();

if (isGuest) {
  return await MaterialDatabase.instance.getAllMaterials();
}

    final response = await http.get(
      Uri.parse(baseUrl),
    );

    if (response.statusCode == 200) {
      final responseData =
          jsonDecode(response.body);

      final List<dynamic> materialsJson =
          responseData['data'];

      return materialsJson
          .map(
            (json) =>
                MaterialModel.fromJson(json),
          )
          .toList();
    }

    throw Exception(
      'Failed to load materials.',
    );
  }

  // ==========================
  // Upload Material
  // ==========================

  Future<MaterialModel> uploadMaterial({
    required File file,
    required int userId,
    required String title,
    required String subject,
    String? description,
  }) async {

     final isGuest = await SessionManager.isGuest();

if (isGuest) {

  // Get application documents directory
  final appDirectory =
      await getApplicationDocumentsDirectory();

  // Create materials folder
  final materialsFolder = Directory(
    p.join(appDirectory.path, "materials"),
  );

  if (!await materialsFolder.exists()) {
    await materialsFolder.create(recursive: true);
  }

  // Create a unique file name
  final fileName =
      "${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}";

  final savedFile = await file.copy(
    p.join(
      materialsFolder.path,
      fileName,
    ),
  );

  final material = MaterialModel(
  title: title,
  subject: subject,
  description: description ?? "",
  fileName: fileName,
  fileType: p.extension(file.path),
  fileSize: await savedFile.length(),
  filePath: savedFile.path,
  uploadDate: DateTime.now(),
);

  final id =
      await MaterialDatabase.instance.insertMaterial(material);

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
);
}

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload'),
    );

    // ==========================
    // Material Information
    // ==========================

    request.fields['user_id'] =
        userId.toString();

    request.fields['title'] =
        title;

    request.fields['subject'] =
        subject;

    if (description != null &&
        description.isNotEmpty) {
      request.fields['description'] =
          description;
    }

    // ==========================
    // File
    // ==========================

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    // ==========================
    // Send Request
    // ==========================

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    // ==========================
    // Handle Successful Upload
    // ==========================

    if (response.statusCode == 201) {
      final responseData =
          jsonDecode(response.body);

      return MaterialModel.fromJson(
        responseData['data'],
      );
    }

    // ==========================
    // Handle Upload Error
    // ==========================

    throw Exception(
      'Failed to upload material: '
      '${response.body}',
    );
  }

  // ==========================
  // Delete Material
  // ==========================

  Future<void> deleteMaterial(
  int id,
) async {

  final isGuest = await SessionManager.isGuest();

  if (isGuest) {
  final material = await MaterialDatabase.instance.getMaterialById(id);

  if (material != null) {
    final file = File(material.filePath);

   try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore file deletion errors.
    }
  }

  await MaterialDatabase.instance.deleteMaterial(id);
  return;
}

  final response = await http.delete(
    Uri.parse('$baseUrl/$id'),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to delete material.',
    );
  }
}
}
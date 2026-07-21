import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/materials/material_model.dart';

class MaterialService {
  // ==========================
  // Backend Base URL
  // ==========================

  static const String baseUrl =
      'http://YOUR_IP_ADDRESS:5000/api/materials';

  // ==========================
  // Get All Materials
  // ==========================

  Future<List<MaterialModel>> getMaterials() async {
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
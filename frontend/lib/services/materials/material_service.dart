import 'dart:convert';

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
    throw UnimplementedError();
  }

  // ==========================
  // Upload Material
  // ==========================

  Future<void> uploadMaterial({
    required MaterialModel material,
  }) async {
    throw UnimplementedError();
  }

  // ==========================
  // Delete Material
  // ==========================

  Future<void> deleteMaterial(int id) async {
    throw UnimplementedError();
  }
}
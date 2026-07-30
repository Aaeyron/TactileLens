import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../../models/materials/material_model.dart';

class MaterialDatabase {
  MaterialDatabase._();

  static final MaterialDatabase instance =
      MaterialDatabase._();

  // ==========================
  // Insert Material
  // ==========================

  Future<int> insertMaterial(
    MaterialModel material,
  ) async {
    final db = await AppDatabase.instance.database;

      return await db.insert(
        "materials",
        {
        "user_id": null,
        "title": material.title,
        "subject": material.subject,
        "description": "",
        "file_name": material.fileName,
        "file_path": material.filePath,
        "file_type": material.fileType,
        "file_size": material.fileSize,
        "uploaded_at":
        material.uploadDate.toIso8601String(),
      },
    );
  }

  // ==========================
  // Get All Materials
  // ==========================

  Future<List<MaterialModel>> getAllMaterials() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      "materials",
      orderBy: "uploaded_at DESC",
    );

     return result.map((json) {
      return MaterialModel.fromJson(
        Map<String, dynamic>.from(json),
      );
    }).toList();
  }

  // ==========================
// Get Material By ID
// ==========================

Future<MaterialModel?> getMaterialById(
  int id,
) async {
  final db = await AppDatabase.instance.database;

  final result = await db.query(
    "materials",
    where: "id = ?",
    whereArgs: [id],
    limit: 1,
  );

  if (result.isEmpty) {
    return null;
  }

  return MaterialModel.fromJson(
    Map<String, dynamic>.from(result.first),
  );
}

  // ==========================
  // Delete Material
  // ==========================

  Future<int> deleteMaterial(
    int id,
  ) async {
    final db = await AppDatabase.instance.database;

    return await db.delete(
      "materials",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ==========================
  // Delete All Materials
  // ==========================

  Future<void> deleteAllMaterials() async {
    final db = await AppDatabase.instance.database;

    await db.delete("materials");
  }
}
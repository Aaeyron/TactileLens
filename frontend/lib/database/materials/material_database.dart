import '../../models/materials/material_model.dart';
import '../app_database.dart';

class MaterialDatabase {
  MaterialDatabase._();

  static final MaterialDatabase instance = MaterialDatabase._();

  static const String _materialsTable = 'materials';

  static const String _guestOwnershipCondition = 'user_id IS NULL';

  // ==========================
  // Insert Material
  // ==========================

  Future<int> insertMaterial(MaterialModel material) async {
    final database = await AppDatabase.instance.database;

    final Map<String, dynamic> values = material.toJson()
      ..remove('id')
      ..['user_id'] = null;

    return database.insert(_materialsTable, values);
  }

  // ==========================
  // Get All Materials
  // ==========================

  Future<List<MaterialModel>> getAllMaterials() async {
    final database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> queryResult = await database.query(
      _materialsTable,
      where: _guestOwnershipCondition,
      orderBy: 'uploaded_at DESC, id DESC',
    );

    return List<MaterialModel>.unmodifiable(
      queryResult.map((Map<String, Object?> record) {
        return MaterialModel.fromJson(Map<String, dynamic>.from(record));
      }),
    );
  }

  // ==========================
  // Get Materials by Folder
  // ==========================

  Future<List<MaterialModel>> getMaterialsByFolderId(int folderId) async {
    final database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> queryResult = await database.query(
      _materialsTable,
      where: '$_guestOwnershipCondition AND folder_id = ?',
      whereArgs: <Object>[folderId],
      orderBy: 'uploaded_at DESC, id DESC',
    );

    return List<MaterialModel>.unmodifiable(
      queryResult.map((Map<String, Object?> record) {
        return MaterialModel.fromJson(Map<String, dynamic>.from(record));
      }),
    );
  }

  // ==========================
  // Get Unfiled Materials
  // ==========================

  Future<List<MaterialModel>> getUnfiledMaterials() async {
    final database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> queryResult = await database.query(
      _materialsTable,
      where: '$_guestOwnershipCondition AND folder_id IS NULL',
      orderBy: 'uploaded_at DESC, id DESC',
    );

    return List<MaterialModel>.unmodifiable(
      queryResult.map((Map<String, Object?> record) {
        return MaterialModel.fromJson(Map<String, dynamic>.from(record));
      }),
    );
  }

  // ==========================
  // Get Material by ID
  // ==========================

  Future<MaterialModel?> getMaterialById(int id) async {
    final database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> queryResult = await database.query(
      _materialsTable,
      where: '$_guestOwnershipCondition AND id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (queryResult.isEmpty) {
      return null;
    }

    return MaterialModel.fromJson(Map<String, dynamic>.from(queryResult.first));
  }

  // ==========================
  // Move Material to Folder
  // ==========================

  Future<int> updateMaterialFolder({
    required int materialId,
    required int? folderId,
  }) async {
    final database = await AppDatabase.instance.database;

    return database.update(
      _materialsTable,
      <String, dynamic>{'folder_id': folderId},
      where: '$_guestOwnershipCondition AND id = ?',
      whereArgs: <Object>[materialId],
    );
  }

  // ==========================
  // Delete Material
  // ==========================

  Future<int> deleteMaterial(int id) async {
    final database = await AppDatabase.instance.database;

    return database.delete(
      _materialsTable,
      where: '$_guestOwnershipCondition AND id = ?',
      whereArgs: <Object>[id],
    );
  }

  // ==========================
  // Delete All Guest Materials
  // ==========================

  Future<int> deleteAllGuestMaterials() async {
    final database = await AppDatabase.instance.database;

    return database.delete(_materialsTable, where: _guestOwnershipCondition);
  }
}

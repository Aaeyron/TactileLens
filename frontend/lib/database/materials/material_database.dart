import '../../models/materials/material_model.dart';
import '../app_database.dart';

class MaterialDatabase {
  MaterialDatabase._();

  static final MaterialDatabase instance = MaterialDatabase._();

  static const String _materialsTable = 'materials';

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
      orderBy: 'uploaded_at DESC, id DESC',
    );

    return List<MaterialModel>.unmodifiable(
      queryResult.map((Map<String, Object?> record) {
        return MaterialModel.fromJson(Map<String, dynamic>.from(record));
      }),
    );
  }

  // ==========================
  // Get Material By ID
  // ==========================

  Future<MaterialModel?> getMaterialById(int id) async {
    final database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> queryResult = await database.query(
      _materialsTable,
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (queryResult.isEmpty) {
      return null;
    }

    return MaterialModel.fromJson(Map<String, dynamic>.from(queryResult.first));
  }

  // ==========================
  // Delete Material
  // ==========================

  Future<int> deleteMaterial(int id) async {
    final database = await AppDatabase.instance.database;

    return database.delete(
      _materialsTable,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  // ==========================
  // Delete All Materials
  // ==========================

  Future<int> deleteAllMaterials() async {
    final database = await AppDatabase.instance.database;

    return database.delete(_materialsTable);
  }
}

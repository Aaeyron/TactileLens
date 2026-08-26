import 'package:sqflite/sqflite.dart';

import '../../models/materials/material_folder_model.dart';
import '../app_database.dart';

class MaterialFolderDatabase {
  MaterialFolderDatabase._();

  static final MaterialFolderDatabase instance = MaterialFolderDatabase._();

  static const String _foldersTable = 'material_folders';
  static const String _materialsTable = 'materials';

  // ==========================
  // Create Folder
  // ==========================

  Future<MaterialFolderModel> createFolder(String name) async {
    final Database database = await AppDatabase.instance.database;

    final String normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw const FormatException('A folder name is required.');
    }

    final DateTime now = DateTime.now();

    final int folderId = await database.insert(_foldersTable, <String, dynamic>{
      'name': normalizedName,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);

    return MaterialFolderModel(
      id: folderId,
      name: normalizedName,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ==========================
  // Get All Folders
  // ==========================

  Future<List<MaterialFolderModel>> getFolders() async {
    final Database database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> queryResult = await database.rawQuery('''
      SELECT
        folders.id,
        folders.name,
        folders.created_at,
        folders.updated_at,
        COUNT(materials.id) AS item_count
      FROM $_foldersTable AS folders
      LEFT JOIN $_materialsTable AS materials
        ON materials.folder_id = folders.id
      GROUP BY
        folders.id,
        folders.name,
        folders.created_at,
        folders.updated_at
      ORDER BY
        folders.name COLLATE NOCASE ASC,
        folders.id ASC
    ''');

    return List<MaterialFolderModel>.unmodifiable(
      queryResult.map((Map<String, Object?> record) {
        return MaterialFolderModel.fromJson(Map<String, dynamic>.from(record));
      }),
    );
  }

  // ==========================
  // Get Folder by ID
  // ==========================

  Future<MaterialFolderModel?> getFolderById(int folderId) async {
    final Database database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> queryResult = await database.rawQuery(
      '''
        SELECT
          folders.id,
          folders.name,
          folders.created_at,
          folders.updated_at,
          COUNT(materials.id) AS item_count
        FROM $_foldersTable AS folders
        LEFT JOIN $_materialsTable AS materials
          ON materials.folder_id = folders.id
        WHERE folders.id = ?
        GROUP BY
          folders.id,
          folders.name,
          folders.created_at,
          folders.updated_at
        LIMIT 1
      ''',
      <Object>[folderId],
    );

    if (queryResult.isEmpty) {
      return null;
    }

    return MaterialFolderModel.fromJson(
      Map<String, dynamic>.from(queryResult.first),
    );
  }

  // ==========================
  // Find Folder by Name
  // ==========================

  Future<MaterialFolderModel?> findFolderByName(String name) async {
    final Database database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> queryResult = await database.query(
      _foldersTable,
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
      whereArgs: <Object>[name.trim()],
      limit: 1,
    );

    if (queryResult.isEmpty) {
      return null;
    }

    final Map<String, dynamic> record = Map<String, dynamic>.from(
      queryResult.first,
    )..['item_count'] = 0;

    return MaterialFolderModel.fromJson(record);
  }

  // ==========================
  // Rename Folder
  // ==========================

  Future<MaterialFolderModel?> renameFolder({
    required int folderId,
    required String name,
  }) async {
    final Database database = await AppDatabase.instance.database;

    final String normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw const FormatException('A folder name is required.');
    }

    final DateTime updatedAt = DateTime.now();

    final int affectedRows = await database.update(
      _foldersTable,
      <String, dynamic>{
        'name': normalizedName,
        'updated_at': updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[folderId],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    if (affectedRows == 0) {
      return null;
    }

    return getFolderById(folderId);
  }

  // ==========================
  // Delete Folder
  // ==========================

  Future<bool> deleteFolder(int folderId) async {
    final Database database = await AppDatabase.instance.database;

    final int affectedRows = await database.delete(
      _foldersTable,
      where: 'id = ?',
      whereArgs: <Object>[folderId],
    );

    return affectedRows > 0;
  }

  // ==========================
  // Delete All Folders
  // ==========================

  Future<int> deleteAllFolders() async {
    final Database database = await AppDatabase.instance.database;

    return database.delete(_foldersTable);
  }
}

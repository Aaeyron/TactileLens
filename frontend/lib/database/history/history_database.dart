import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/history/history_model.dart';
import '../app_database.dart';

class HistoryDatabase {
  HistoryDatabase._();

  static final HistoryDatabase instance = HistoryDatabase._();

  static const String _historyTable = 'scan_history';
  static const String _historyImagesDirectoryName = 'history_images';
  static const int _guestUserId = 1;

  Future<HistoryRecord> insertHistory({
    required String title,
    required String recognizedContent,
    required String brailleContent,
    required List<Map<String, dynamic>> documentBlocks,
    String? sourceImagePath,
    String? modelName,
    String? pipelineVersion,
    double? processingTimeMs,
  }) async {
    final Database database = await AppDatabase.instance.database;
    final DateTime timestamp = DateTime.now();

    String? storedImagePath;
    int? insertedId;

    try {
      storedImagePath = await _copyHistoryImage(sourceImagePath);

      final int id = await database.insert(_historyTable, <String, dynamic>{
        'user_id': _guestUserId,
        'title': title.trim(),
        'recognized_content': recognizedContent.trim(),
        'braille_content': brailleContent.trim(),
        'document_blocks': jsonEncode(documentBlocks),
        'source_image_path': storedImagePath,
        'model_name': _nullableText(modelName),
        'pipeline_version': _nullableText(pipelineVersion),
        'processing_time_ms': processingTimeMs,
        'created_at': timestamp.toIso8601String(),
        'updated_at': timestamp.toIso8601String(),
      });

      insertedId = id;

      final HistoryRecord? record = await getHistoryById(id);

      if (record == null) {
        throw StateError('The local history record could not be loaded.');
      }

      return record;
    } catch (_) {
      if (insertedId != null) {
        await database.delete(
          _historyTable,
          where: 'id = ?',
          whereArgs: <Object>[insertedId],
        );
      }

      await _deleteHistoryImage(storedImagePath);
      rethrow;
    }
  }

  Future<HistoryPage> getHistory({
    required int page,
    required int limit,
  }) async {
    final Database database = await AppDatabase.instance.database;
    final int offset = (page - 1) * limit;

    final List<Map<String, Object?>> countResult = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM $_historyTable',
    );

    final int total = Sqflite.firstIntValue(countResult) ?? 0;

    final List<Map<String, Object?>> rows = await database.query(
      _historyTable,
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );

    final List<HistoryRecord> records = rows
        .map(_recordFromRow)
        .toList(growable: false);

    final int totalPages = total == 0 ? 0 : (total + limit - 1) ~/ limit;

    return HistoryPage(
      records: List<HistoryRecord>.unmodifiable(records),
      pagination: HistoryPagination(
        page: page,
        limit: limit,
        total: total,
        totalPages: totalPages,
      ),
    );
  }

  Future<HistoryRecord?> getHistoryById(int historyId) async {
    final Database database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> rows = await database.query(
      _historyTable,
      where: 'id = ?',
      whereArgs: <Object>[historyId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _recordFromRow(rows.first);
  }

  Future<HistoryRecord?> renameHistory({
    required int historyId,
    required String title,
  }) async {
    final Database database = await AppDatabase.instance.database;

    final int affectedRows = await database.update(
      _historyTable,
      <String, dynamic>{
        'title': title.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[historyId],
    );

    if (affectedRows == 0) {
      return null;
    }

    return getHistoryById(historyId);
  }

  Future<int> deleteHistory(int historyId) async {
    final Database database = await AppDatabase.instance.database;
    final HistoryRecord? record = await getHistoryById(historyId);

    if (record == null) {
      return 0;
    }

    final int affectedRows = await database.delete(
      _historyTable,
      where: 'id = ?',
      whereArgs: <Object>[historyId],
    );

    if (affectedRows > 0) {
      await _deleteHistoryImage(record.sourceImagePath);
    }

    return affectedRows;
  }

  Future<int> deleteAllHistory() async {
    final Database database = await AppDatabase.instance.database;

    final List<Map<String, Object?>> rows = await database.query(
      _historyTable,
      columns: <String>['source_image_path'],
    );

    final int affectedRows = await database.delete(_historyTable);

    if (affectedRows > 0) {
      for (final Map<String, Object?> row in rows) {
        final Object? rawPath = row['source_image_path'];

        if (rawPath is String) {
          await _deleteHistoryImage(rawPath);
        }
      }
    }

    return affectedRows;
  }

  Future<Directory> _getHistoryImagesDirectory() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();

    final Directory historyImagesDirectory = Directory(
      path.join(appDirectory.path, _historyImagesDirectoryName),
    );

    if (!await historyImagesDirectory.exists()) {
      await historyImagesDirectory.create(recursive: true);
    }

    return historyImagesDirectory;
  }

  Future<String?> _copyHistoryImage(String? sourceImagePath) async {
    final String? normalizedPath = _nullableText(sourceImagePath);

    if (normalizedPath == null) {
      return null;
    }

    final File sourceFile = File(normalizedPath);

    if (!await sourceFile.exists()) {
      return null;
    }

    final Directory historyImagesDirectory = await _getHistoryImagesDirectory();

    final String sourceExtension = path.extension(sourceFile.path);
    final String extension = sourceExtension.isEmpty ? '.png' : sourceExtension;

    final String fileName =
        'scan_${DateTime.now().microsecondsSinceEpoch}$extension';

    final File storedFile = await sourceFile.copy(
      path.join(historyImagesDirectory.path, fileName),
    );

    return storedFile.path;
  }

  Future<void> _deleteHistoryImage(String? sourceImagePath) async {
    final String? normalizedPath = _nullableText(sourceImagePath);

    if (normalizedPath == null) {
      return;
    }

    final Directory historyImagesDirectory = await _getHistoryImagesDirectory();

    final String resolvedDirectory = path.canonicalize(
      historyImagesDirectory.path,
    );

    final String resolvedImagePath = path.canonicalize(normalizedPath);

    if (!path.isWithin(resolvedDirectory, resolvedImagePath)) {
      return;
    }

    final File imageFile = File(resolvedImagePath);

    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } on FileSystemException {
      // The database record is already deleted. Ignore cleanup failure.
    }
  }

  HistoryRecord _recordFromRow(Map<String, Object?> row) {
    final Map<String, dynamic> values = Map<String, dynamic>.from(row);
    final dynamic rawBlocks = values['document_blocks'];

    if (rawBlocks is String && rawBlocks.trim().isNotEmpty) {
      try {
        final dynamic decodedBlocks = jsonDecode(rawBlocks);

        values['document_blocks'] = decodedBlocks is List
            ? decodedBlocks
            : const <dynamic>[];
      } on FormatException {
        values['document_blocks'] = const <dynamic>[];
      }
    } else {
      values['document_blocks'] = const <dynamic>[];
    }

    return HistoryRecord.fromJson(values);
  }

  String? _nullableText(String? value) {
    final String normalizedValue = value?.trim() ?? '';

    return normalizedValue.isEmpty ? null : normalizedValue;
  }
}

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'tactilelens.db';

  static const int _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    final Database? existingDatabase = _database;

    if (existingDatabase != null) {
      return existingDatabase;
    }

    final Database initializedDatabase = await _initializeDatabase();

    _database = initializedDatabase;

    return initializedDatabase;
  }

  Future<Database> _initializeDatabase() async {
    final String databaseDirectory = await getDatabasesPath();

    final String databasePath = path.join(databaseDirectory, _databaseName);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database database, int version) async {
    await database.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        description TEXT,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        uploaded_at TEXT NOT NULL,
        source_type TEXT NOT NULL DEFAULT 'uploaded_file',
        recognized_content TEXT NOT NULL DEFAULT '',
        braille_content TEXT NOT NULL DEFAULT '',
        document_blocks TEXT NOT NULL DEFAULT '[]',
        model_name TEXT,
        pipeline_version TEXT,
        processing_time_ms REAL
      )
    ''');
  }

  Future<void> _upgradeDatabase(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      final Batch migration = database.batch();

      migration.execute('''
        ALTER TABLE materials
        ADD COLUMN source_type TEXT
        NOT NULL DEFAULT 'uploaded_file'
      ''');

      migration.execute('''
        ALTER TABLE materials
        ADD COLUMN recognized_content TEXT
        NOT NULL DEFAULT ''
      ''');

      migration.execute('''
        ALTER TABLE materials
        ADD COLUMN braille_content TEXT
        NOT NULL DEFAULT ''
      ''');

      migration.execute('''
        ALTER TABLE materials
        ADD COLUMN document_blocks TEXT
        NOT NULL DEFAULT '[]'
      ''');

      migration.execute('''
        ALTER TABLE materials
        ADD COLUMN model_name TEXT
      ''');

      migration.execute('''
        ALTER TABLE materials
        ADD COLUMN pipeline_version TEXT
      ''');

      migration.execute('''
        ALTER TABLE materials
        ADD COLUMN processing_time_ms REAL
      ''');

      await migration.commit(noResult: true);
    }
  }

  Future<void> close() async {
    final Database? currentDatabase = _database;

    if (currentDatabase == null) {
      return;
    }

    await currentDatabase.close();
    _database = null;
  }
}

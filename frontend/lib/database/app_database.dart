import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'tactilelens.db';

  static const int _databaseVersion = 4;

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
      onConfigure: _configureDatabase,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _configureDatabase(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDatabase(Database database, int version) async {
    await database.execute('''
      CREATE TABLE material_folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        CHECK (
          LENGTH(TRIM(name)) BETWEEN 1 AND 80
        )
      )
    ''');

    await database.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        folder_id INTEGER,
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
        processing_time_ms REAL,
        FOREIGN KEY (folder_id)
          REFERENCES material_folders(id)
          ON DELETE SET NULL
      )
    ''');

    await database.execute('''
  CREATE TABLE scan_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL DEFAULT 1,
    title TEXT NOT NULL,
    recognized_content TEXT NOT NULL DEFAULT '',
    braille_content TEXT NOT NULL DEFAULT '',
    document_blocks TEXT NOT NULL DEFAULT '[]',
    source_image_path TEXT,
    model_name TEXT,
    pipeline_version TEXT,
    processing_time_ms REAL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
''');

    await _createHistoryIndexes(database);

    await _createFolderIndexes(database);
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

    if (oldVersion < 4) {
      await database.transaction((Transaction transaction) async {
        await transaction.execute('''
      CREATE TABLE IF NOT EXISTS scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 1,
        title TEXT NOT NULL,
        recognized_content TEXT NOT NULL DEFAULT '',
        braille_content TEXT NOT NULL DEFAULT '',
        document_blocks TEXT NOT NULL DEFAULT '[]',
        source_image_path TEXT,
        model_name TEXT,
        pipeline_version TEXT,
        processing_time_ms REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

        await transaction.execute('''
      CREATE INDEX IF NOT EXISTS
        scan_history_created_at_index
      ON scan_history (created_at DESC)
    ''');
      });
    }

    if (oldVersion < 3) {
      await database.transaction((Transaction transaction) async {
        await transaction.execute('''
          CREATE TABLE IF NOT EXISTS material_folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL COLLATE NOCASE UNIQUE,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            CHECK (
              LENGTH(TRIM(name)) BETWEEN 1 AND 80
            )
          )
        ''');

        await transaction.execute('''
          ALTER TABLE materials
          ADD COLUMN folder_id INTEGER
          REFERENCES material_folders(id)
          ON DELETE SET NULL
        ''');

        await transaction.execute('''
          CREATE INDEX IF NOT EXISTS
            materials_folder_id_index
          ON materials (folder_id)
        ''');

        await transaction.execute('''
          CREATE INDEX IF NOT EXISTS
            material_folders_name_index
          ON material_folders (name)
        ''');
      });
    }
  }

  Future<void> _createFolderIndexes(Database database) async {
    await database.execute('''
      CREATE INDEX IF NOT EXISTS
        materials_folder_id_index
      ON materials (folder_id)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
        material_folders_name_index
      ON material_folders (name)
    ''');
  }

  Future<void> _createHistoryIndexes(Database database) async {
    await database.execute('''
    CREATE INDEX IF NOT EXISTS
      scan_history_created_at_index
    ON scan_history (created_at DESC)
  ''');
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

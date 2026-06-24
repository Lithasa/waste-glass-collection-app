import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/collection_local_model.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();

  LocalDbService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'waste_glass_collection.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collection_records (
            localRecordId TEXT PRIMARY KEY,
            supplierCode TEXT NOT NULL,
            clearKg REAL NOT NULL,
            colouredKg REAL NOT NULL,
            condition TEXT NOT NULL,
            collectedAt TEXT NOT NULL,
            isSynced INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertCollection(CollectionLocalModel record) async {
    final db = await database;

    await db.insert(
      'collection_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CollectionLocalModel>> getAllCollections() async {
    final db = await database;
    final result = await db.query(
      'collection_records',
      orderBy: 'collectedAt ASC',
    );

    return result.map((item) => CollectionLocalModel.fromMap(item)).toList();
  }

  Future<List<CollectionLocalModel>> getUnsyncedCollections() async {
    final db = await database;
    final result = await db.query(
      'collection_records',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'collectedAt ASC',
    );

    return result.map((item) => CollectionLocalModel.fromMap(item)).toList();
  }

  Future<void> markAsSynced(String localRecordId) async {
    final db = await database;

    await db.update(
      'collection_records',
      {'isSynced': 1},
      where: 'localRecordId = ?',
      whereArgs: [localRecordId],
    );
  }

  Future<void> markAllAsSynced() async {
    final db = await database;

    await db.update(
      'collection_records',
      {'isSynced': 1},
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('collection_records');
  }
}

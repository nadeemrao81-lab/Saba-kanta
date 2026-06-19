// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/weigh_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'saba_kanta.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE weigh_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serialNo INTEGER NOT NULL,
        partyName TEXT NOT NULL,
        commodity TEXT NOT NULL,
        driverName TEXT,
        vehicleNo TEXT,
        firstWeight REAL NOT NULL,
        secondWeight REAL NOT NULL,
        netWeight REAL NOT NULL,
        ratePerMaund REAL NOT NULL,
        totalAmount REAL NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL
      )
    ''');
  }

  // INSERT
  Future<int> insertRecord(WeighRecord record) async {
    final db = await database;
    final id = await db.insert('weigh_records', record.toMap()..remove('id'));
    return id;
  }

  // GET ALL
  Future<List<WeighRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query(
      'weigh_records',
      orderBy: 'serialNo DESC',
    );
    return maps.map((m) => WeighRecord.fromMap(m)).toList();
  }

  // GET BY ID
  Future<WeighRecord?> getRecord(int id) async {
    final db = await database;
    final maps = await db.query(
      'weigh_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return WeighRecord.fromMap(maps.first);
  }

  // SEARCH BY PARTY NAME
  Future<List<WeighRecord>> searchByPartyName(String query) async {
    final db = await database;
    final maps = await db.query(
      'weigh_records',
      where: 'partyName LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'serialNo DESC',
    );
    return maps.map((m) => WeighRecord.fromMap(m)).toList();
  }

  // SEARCH BY VEHICLE NO
  Future<List<WeighRecord>> searchByVehicleNo(String query) async {
    final db = await database;
    final maps = await db.query(
      'weigh_records',
      where: 'vehicleNo LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'serialNo DESC',
    );
    return maps.map((m) => WeighRecord.fromMap(m)).toList();
  }

  // UPDATE
  Future<int> updateRecord(WeighRecord record) async {
    final db = await database;
    return await db.update(
      'weigh_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // DELETE
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'weigh_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // GET NEXT SERIAL NUMBER
  Future<int> getNextSerialNo() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT MAX(serialNo) as maxSerial FROM weigh_records');
    final maxSerial = result.first['maxSerial'];
    return (maxSerial == null ? 0 : maxSerial as int) + 1;
  }

  // GET RECORDS COUNT
  Future<int> getRecordsCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM weigh_records');
    return (result.first['count'] as int?) ?? 0;
  }
}

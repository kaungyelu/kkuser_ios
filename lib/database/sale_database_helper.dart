import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SaleDatabaseHelper {
  static final SaleDatabaseHelper _instance = SaleDatabaseHelper._internal();
  static Database? _database;

  factory SaleDatabaseHelper() => _instance;

  SaleDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "SalesDB.db");
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT NOT NULL,
            name TEXT NOT NULL,
            com INTEGER NOT NULL,
            za INTEGER NOT NULL,
            numbers TEXT NOT NULL,
            bets TEXT NOT NULL,
            total_amount REAL NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  String _getCurrentTimestamp() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }

  Future<bool> saveSale(String key, String name, int com, int za, 
      String numbersJson, String betsJson, double totalAmount) async {
    final db = await database;
    try {
      int result = await db.insert('sales', {
        'key': key,
        'name': name,
        'com': com,
        'za': za,
        'numbers': numbersJson,
        'bets': betsJson,
        'total_amount': totalAmount,
        'created_at': _getCurrentTimestamp(),
      });
      return result != -1;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSale(int id, String name, int com, int za, 
      String numbersJson, String betsJson, double totalAmount) async {
    final db = await database;
    try {
      int rowsAffected = await db.update(
        'sales',
        {
          'name': name,
          'com': com,
          'za': za,
          'numbers': numbersJson,
          'bets': betsJson,
          'total_amount': totalAmount,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return rowsAffected > 0;
    } catch (e) {
      return false;
    }
  }

  Future<int> getSlipCount(String key) async {
    final db = await database;
    var res = await db.rawQuery('SELECT COUNT(*) FROM sales WHERE key = ?', [key]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getSalesByKey(String key) async {
    final db = await database;
    return await db.query(
      'sales',
      where: 'key = ?',
      whereArgs: [key],
      orderBy: 'created_at DESC',
    );
  }

  Future<bool> deleteSale(int id) async {
    final db = await database;
    int result = await db.delete('sales', where: 'id = ?', whereArgs: [id]);
    return result > 0;
  }

  Future<double> getTotalAmountByKey(String key) async {
    final db = await database;
    var res = await db.rawQuery('SELECT SUM(total_amount) FROM sales WHERE key = ?', [key]);
    return (res.first.values.first as num?)?.toDouble() ?? 0.0;
  }

  Future<String> getAllSalesAsJson() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sales', orderBy: 'created_at DESC');
    return jsonEncode(maps);
  }

  Future<bool> deleteSalesByKey(String key) async {
    final db = await database;
    int result = await db.delete('sales', where: 'key = ?', whereArgs: [key]);
    return result > 0;
  }
}
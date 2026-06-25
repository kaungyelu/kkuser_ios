import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class NameDatabaseHelper {
  static final NameDatabaseHelper _instance = NameDatabaseHelper._internal();
  static Database? _database;

  factory NameDatabaseHelper() => _instance;

  NameDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "NamesDB.db");
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Name (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            com INTEGER NOT NULL,
            za INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<bool> checkAdminExists() async {
    final db = await database;
    var result = await db.query('Name', where: 'name = ?', whereArgs: ['Admin']);
    return result.isNotEmpty;
  }

  Future<void> insertAdmin() async {
    final db = await database;
    await db.insert('Name', {
      'name': 'Admin',
      'com': 15,
      'za': 80,
    });
  }

  Future<List<Map<String, dynamic>>> getAllNames() async {
    final db = await database;
    return await db.query('Name', orderBy: 'name ASC');
  }

  Future<bool> checkNameExists(String name) async {
    final db = await database;
    var result = await db.query('Name', where: 'name = ?', whereArgs: [name]);
    return result.isNotEmpty;
  }

  Future<int> insertName(String name, int com, int za) async {
    final db = await database;
    try {
      return await db.insert('Name', {
        'name': name,
        'com': com,
        'za': za,
      });
    } catch (e) {
      return -1;
    }
  }

  Future<bool> updateName(int id, String name, int com, int za) async {
    final db = await database;
    int rowsAffected = await db.update(
      'Name',
      {'name': name, 'com': com, 'za': za},
      where: 'id = ?',
      whereArgs: [id],
    );
    return rowsAffected > 0;
  }

  Future<bool> deleteName(int id) async {
    final db = await database;
    int rowsAffected = await db.delete('Name', where: 'id = ?', whereArgs: [id]);
    return rowsAffected > 0;
  }

  Future<String> getAllUsersAsJson() async {
    final List<Map<String, dynamic>> names = await getAllNames();
    List<Map<String, dynamic>> formattedList = names.map((item) {
      return {
        'name': item['name'],
        'com': item['com'],
        'za': item['za'],
      };
    }).toList();

    return jsonEncode(formattedList);
  }
}
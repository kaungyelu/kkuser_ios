import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class TimeDatabaseHelper {
  static final TimeDatabaseHelper _instance = TimeDatabaseHelper._internal();
  static Database? _database;

  factory TimeDatabaseHelper() => _instance;

  TimeDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "TimesDB.db");
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS TimeC (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            pno TEXT DEFAULT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllTimes() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM TimeC ORDER BY date DESC, time DESC');
  }

  Future<bool> updatePno(String date, String time, String pno) async {
    final db = await database;
    try {
      int rowsAffected = await db.update(
        'TimeC',
        {'pno': pno},
        where: 'date = ? AND time = ?',
        whereArgs: [date, time],
      );

      if (rowsAffected == 0) {
        int result = await db.insert('TimeC', {
          'date': date,
          'time': time,
          'pno': pno,
        });
        return result != -1;
      }
      return rowsAffected > 0;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTimeByDateTime(String date, String time) async {
    final db = await database;
    return await db.rawQuery(
      'SELECT * FROM TimeC WHERE date = ? AND time = ?',
      [date, time],
    );
  }

  Future<bool> deleteTime(int id) async {
    final db = await database;
    int result = await db.delete('TimeC', where: 'id = ?', whereArgs: [id]);
    return result > 0;
  }

  Future<bool> insertTime(String date, String time) async {
    final db = await database;
    try {
      int result = await db.insert('TimeC', {
        'date': date,
        'time': time,
      });
      return result != -1;
    } catch (e) {
      return false;
    }
  }
}
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _db;

  // Getter để lấy đối tượng database
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // Khởi tạo DB và copy từ assets nếu chưa có
  static Future<Database> _initDB() async {
    const String dbName = 'doan2.db';
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    // Kiểm tra DB đã tồn tại chưa, nếu chưa thì copy từ assets
    if (!await File(path).exists()) {
      print("➡ Copy database from assets to: $path");
      try {
        ByteData data = await rootBundle.load('assets/$dbName');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print( "Lỗi copy DB từ assets: $e");
        // Có thể throw lỗi ở đây để thông báo cho phần gọi hàm
        throw Exception("Failed to copy database from assets: $e");
      }
    }

    // Trả về đối tượng database đã mở, không có version và onUpgrade
    return await openDatabase(path);
  }

  static Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    try {
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      print("Lỗi rawQuery: $e");
      return [];
    }
  }

  static Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    try {
      return await db.insert(table, data);
    } catch (e) {
      print("Lỗi insert: $e");
      return 0;
    }
  }

  static Future<int> update(String table, int id, Map<String, dynamic> data, {String idColumn = 'id'}) async {
    final db = await database;
    try {
      return await db.update(table, data, where: '$idColumn = ?', whereArgs: [id]);
    } catch (e) {
      print("Lỗi update: $e");
      return 0;
    }
  }

  static Future<int> delete(String table, int id, {String idColumn = 'id'}) async {
    final db = await database;
    try {
      return await db.delete(table, where: '$idColumn = ?', whereArgs: [id]);
    } catch (e) {
      print("Lỗi delete: $e");
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    try {
      return await db.query(table);
    } catch (e) {
      print("Lỗi getAll: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getById(String table, int id, {String idColumn = 'id'}) async {
    final db = await database;
    try {
      final result = await db.query(table, where: '$idColumn = ?', whereArgs: [id]);
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print("Lỗi getById: $e");
      return null;
    }
  }
  static Future<int> rawInsert(String sql, List<Object?> arguments) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  static Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }
}

import 'package:flutter/material.dart';
import 'package:doan/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:doan/model/nhanvien.dart';


class LoginProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

 Future<NhanVien?> login(String userName, String password) async {
  final db = await DatabaseHelper.database;

  final result = await db.query(
    'USER',
    where: 'USERNAME = ? AND PASSWORD = ?',
    whereArgs: [userName.trim(), password.trim()],
  );

  if (result.isNotEmpty) {
    final manv = result.first['MANV'];
    final nhanvienResult = await db.query(
      'NHANVIEN',
      where: 'MANHANVIEN = ?',
      whereArgs: [manv],
    );

    if (nhanvienResult.isNotEmpty) {
      final nhanVien = NhanVien.fromMap(nhanvienResult.first);

      // Lưu SharedPreferences nếu muốn
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('manv', nhanVien.maNhanVien);
      await prefs.setString('hoten', nhanVien.hoTen);
      await prefs.setString('chucvu', nhanVien.chucVu);
      await prefs.setString('sdt', nhanVien.sdt);

      return nhanVien;
    }
  }

  return null;
}

}

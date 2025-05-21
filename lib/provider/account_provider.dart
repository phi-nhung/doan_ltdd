import 'package:flutter/material.dart';
import 'package:doan/model/nhanvien.dart';
import 'package:doan/database_helper.dart';

class AccountProvider extends ChangeNotifier {
  NhanVien? _nhanVien;

  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  AccountProvider() {
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  NhanVien? get nhanVien => _nhanVien;
  bool get isEditing => _isEditing;
  TextEditingController get nameController => _nameController;
  TextEditingController get phoneController => _phoneController;

  void setNhanVien(NhanVien nhanVien) {
    _nhanVien = nhanVien;
    _nameController.text = nhanVien.hoTen;
    _phoneController.text = nhanVien.sdt;
    notifyListeners();
  }

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  Future<NhanVien> getNhanVienById(int maNhanVien) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'NHANVIEN',
      where: 'MANHANVIEN = ?',
      whereArgs: [maNhanVien],
    );

    if (result.isNotEmpty) {
      return NhanVien.fromMap(result.first);
    } else {
      throw Exception("Không tìm thấy nhân viên với mã $maNhanVien");
    }
  }


  Future<void> updateNhanVienFromControllers(
    String name,
    String phone, {
    void Function(String)? showError,
    void Function(String)? showSuccess,
  }) async {
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      showError?.call("Vui lòng nhập đầy đủ thông tin.");
      return;
    }

    if (phone.length < 10 || phone.length > 11) {
      showError?.call("Số điện thoại không hợp lệ.");
      return;
    }

    if (_nhanVien == null) {
      showError?.call("Thông tin nhân viên không hợp lệ.");
      return;
    }

    final updatedNhanVien = NhanVien(
      maNhanVien: _nhanVien!.maNhanVien,
      hoTen: name.trim(),
      chucVu: _nhanVien!.chucVu,
      sdt: phone.trim(),
    );

    try {
      final result = await DatabaseHelper.update(
        'NHANVIEN',
        _nhanVien!.maNhanVien,
        updatedNhanVien.toMap(),
        idColumn: 'MANHANVIEN',
      );

      if (result > 0) {
        final reloadedNhanVien = await getNhanVienById(_nhanVien!.maNhanVien!);
        _nhanVien = reloadedNhanVien;
        _nameController.text = reloadedNhanVien.hoTen;
        _phoneController.text = reloadedNhanVien.sdt;

        _isEditing = false;
        notifyListeners();

        showSuccess?.call("Cập nhật thông tin thành công.");
      } else {
        showError?.call("Cập nhật không thành công.");
      }
    } catch (e) {
      showError?.call("Đã có lỗi xảy ra: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

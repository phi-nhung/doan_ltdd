import 'package:flutter/material.dart';
import 'package:doan/database_helper.dart'; // Đảm bảo đường dẫn này đúng
import 'package:sqflite/sqflite.dart'; // Import sqflite để truy cập đối tượng Database trực tiếp

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _usernameController = TextEditingController(); // Controller cho Tên đăng nhập
  final TextEditingController _hotenController = TextEditingController();    // Controller cho Họ tên
  final TextEditingController _phoneController = TextEditingController();    // Controller cho Số điện thoại
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isAccountFound = false; // Trạng thái: đã tìm thấy tài khoản chưa
  String? _foundUsername; // Tên đăng nhập của người dùng tìm thấy (để hiển thị lại và dùng khi reset mật khẩu)
  int? _foundManvForReset; // Biến này vẫn cần để tìm NHANVIEN, nhưng không dùng để update USER

  @override
  void dispose() {
    _usernameController.dispose();
    _hotenController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Hàm tiện ích để xây dựng TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(255, 224, 224, 224), // Xám nhẹ
        prefixIcon: Icon(icon, color: Color.fromARGB(255, 42, 45, 50)),
        labelText: labelText,
        labelStyle: const TextStyle(color: Color.fromARGB(255, 74, 74, 74)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Hàm tìm tài khoản bằng Username, Họ tên và Số điện thoại
  Future<void> _findAccountByCriteria() async {
    final String username = _usernameController.text.trim();
    final String hoten = _hotenController.text.trim();
    final String phoneNumber = _phoneController.text.trim();

    if (username.isEmpty || hoten.isEmpty || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ Tên đăng nhập, Họ tên và Số điện thoại.')),
      );
      return;
    }

    try {
      // Bước 1: Tìm kiếm USER bằng USERNAME
      final userResult = await DatabaseHelper.rawQuery(
        'SELECT MANV, USERNAME FROM USER WHERE USERNAME = ?',
        [username],
      );

      if (userResult.isNotEmpty) {
        final int manv = userResult.first['MANV']; // Lấy MANV
        final String foundUsernameFromDb = userResult.first['USERNAME']; // Lấy username từ DB

        // Bước 2: Tìm kiếm NHANVIEN bằng MANV, HOTEN và SDT
        final nhanVienResult = await DatabaseHelper.rawQuery(
          'SELECT MANHANVIEN FROM NHANVIEN WHERE MANHANVIEN = ? AND HOTEN = ? AND SDT = ?',
          [manv, hoten, phoneNumber],
        );

        if (nhanVienResult.isNotEmpty) {
          // Nếu cả hai điều kiện đều đúng, tài khoản được xác định
          setState(() {
            _isAccountFound = true;
            _foundUsername = foundUsernameFromDb; // Lưu username để hiển thị và dùng khi reset
            _foundManvForReset = manv; // Lưu MANV (chỉ để đảm bảo logic tìm kiếm đúng)
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tìm thấy tài khoản: $_foundUsername. Vui lòng đặt lại mật khẩu.')),
          );
        } else {
          // Thông tin NHANVIEN không khớp
          setState(() {
            _isAccountFound = false;
            _foundUsername = null;
            _foundManvForReset = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Họ tên hoặc Số điện thoại không khớp với tài khoản này.')),
          );
        }
      } else {
        // Không tìm thấy USER với username đã nhập
        setState(() {
          _isAccountFound = false;
          _foundUsername = null;
          _foundManvForReset = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy tài khoản với tên đăng nhập này.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tìm tài khoản: ${e.toString()}')),
      );
    }
  }

  // Hàm đặt lại mật khẩu
  Future<void> _resetPassword() async {
    if (!_isAccountFound || _foundUsername == null) { // Kiểm tra _foundUsername
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tìm tài khoản trước.')),
      );
      return;
    }

    final String newPassword = _newPasswordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu mới và xác nhận.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới và xác nhận không khớp.')),
      );
      return;
    }

    if (newPassword.length < 6) { // Ví dụ: yêu cầu mật khẩu tối thiểu 6 ký tự
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự.')),
      );
      return;
    }

    try {
      // Lấy đối tượng Database trực tiếp từ DatabaseHelper
      final Database db = await DatabaseHelper.database;

      // DEBUGGING: In ra giá trị trước khi cập nhật
      print('DEBUG: Cố gắng cập nhật USER với USERNAME: $_foundUsername');
      print('DEBUG: Mật khẩu mới: $newPassword');

      // Thực hiện lệnh UPDATE trực tiếp bằng USERNAME
      final int rowsAffected = await db.update(
        'USER', // Tên bảng
        {
          'PASSWORD': newPassword, // Dữ liệu cần cập nhật
        },
        where: 'USERNAME = ?', // Điều kiện WHERE
        whereArgs: [_foundUsername], // Giá trị cho điều kiện WHERE (USERNAME)
      );

      // DEBUGGING: In ra số dòng ảnh hưởng
      print('DEBUG: Số dòng ảnh hưởng: $rowsAffected');

      if (rowsAffected > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt lại mật khẩu thành công!')),
        );
        Navigator.pop(context); // Quay lại màn hình đăng nhập
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt lại mật khẩu thất bại. Vui lòng thử lại.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đặt lại mật khẩu: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 247, 247), // Nền trắng sữa
      appBar: AppBar(
        title: const Text(
          'Quên Mật khẩu',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 107, 66, 38), // Nâu mocha
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Đặt lại mật khẩu",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 30, 30, 30),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Nhập thông tin tài khoản của bạn để xác thực",
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 74, 74, 74),
              ),
            ),
            const SizedBox(height: 30),

            // Trường Tên đăng nhập
            _buildTextField(
              controller: _usernameController,
              labelText: 'Tên đăng nhập',
              icon: Icons.person,
              enabled: !_isAccountFound, // Chỉ cho phép chỉnh sửa khi chưa tìm thấy tài khoản
            ),
            const SizedBox(height: 15),

            // Trường Họ tên
            _buildTextField(
              controller: _hotenController,
              labelText: 'Họ tên',
              icon: Icons.badge_outlined,
              enabled: !_isAccountFound, // Chỉ cho phép chỉnh sửa khi chưa tìm thấy tài khoản
            ),
            const SizedBox(height: 15),

            // Trường Số điện thoại
            _buildTextField(
              controller: _phoneController,
              labelText: 'Số điện thoại',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              enabled: !_isAccountFound, // Chỉ cho phép chỉnh sửa khi chưa tìm thấy tài khoản
            ),
            const SizedBox(height: 15),

            // Nút "Tìm tài khoản" hoặc "Đã tìm thấy tài khoản"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 107, 66, 38), // Nâu mocha
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isAccountFound ? null : _findAccountByCriteria, // Vô hiệu hóa nút nếu đã tìm thấy
                child: Text(
                  _isAccountFound ? "Đã tìm thấy tài khoản" : "Tìm tài khoản",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            // Phần đặt lại mật khẩu (chỉ hiện khi tài khoản đã được xác định)
            if (_isAccountFound) ...[
              const SizedBox(height: 25),
              Text(
                "Tên đăng nhập: $_foundUsername",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _newPasswordController,
                labelText: 'Mật khẩu mới',
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _confirmPasswordController,
                labelText: 'Xác nhận mật khẩu mới',
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 107, 66, 38), // Nâu mocha
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _resetPassword,
                  child: const Text(
                    "Đặt lại mật khẩu",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

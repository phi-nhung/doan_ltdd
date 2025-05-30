import 'package:flutter/material.dart';
import 'package:doan/database_helper.dart'; // Đảm bảo đường dẫn này đúng với file DatabaseHelper của bạn

class CreateEmployeeAccountScreen extends StatefulWidget {
  const CreateEmployeeAccountScreen({Key? key}) : super(key: key);

  @override
  State<CreateEmployeeAccountScreen> createState() => _CreateEmployeeAccountScreenState();
}

class _CreateEmployeeAccountScreenState extends State<CreateEmployeeAccountScreen> {
  // Controllers cho các trường nhập liệu
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _hotenController = TextEditingController();
  final TextEditingController _sdtController = TextEditingController();

  // Danh sách các lựa chọn chức vụ
  String _selectedChucVu = 'Nhân viên'; // Giá trị mặc định
  final List<String> _chucVuOptions = ['Nhân viên', 'Quản lý']; // Có thể lấy từ DB nếu có bảng chức vụ

  @override
  void dispose() {
    // Giải phóng controllers khi widget không còn được sử dụng
    _usernameController.dispose();
    _passwordController.dispose();
    _hotenController.dispose();
    _sdtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 247, 247), // Nền trắng sữa
      appBar: AppBar(
        title: const Text(
          'Cấp Tài khoản Nhân viên',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.brown
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Để tránh tràn màn hình khi bàn phím hiện lên
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trường Tên đăng nhập
              _buildTextField(
                controller: _usernameController,
                labelText: 'Tên đăng nhập',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),

              // Trường Mật khẩu
              _buildTextField(
                controller: _passwordController,
                labelText: 'Mật khẩu',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 15),

              // Trường Họ tên
              _buildTextField(
                controller: _hotenController,
                labelText: 'Họ tên',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 15),

              // Trường Số điện thoại
              _buildTextField(
                controller: _sdtController,
                labelText: 'Số điện thoại',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),

              // Dropdown chọn Chức vụ
              DropdownButtonFormField<String>(
                value: _selectedChucVu,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 224, 224, 224), // Xám nhẹ
                  prefixIcon: const Icon(Icons.work_outline, color: Color.fromARGB(255, 42, 45, 50)),
                  labelText: 'Chức vụ',
                  labelStyle: const TextStyle(color: Color.fromARGB(255, 74, 74, 74)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _chucVuOptions.map((String chucVu) {
                  return DropdownMenuItem<String>(
                    value: chucVu,
                    child: Text(chucVu),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedChucVu = newValue!;
                  });
                },
              ),
              const SizedBox(height: 30),

              // Nút Tạo Tài khoản
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown, // Nâu mocha
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    // Lấy dữ liệu từ controllers
                    final String username = _usernameController.text.trim();
                    final String password = _passwordController.text;
                    final String hoten = _hotenController.text.trim();
                    final String sdt = _sdtController.text.trim();

                    // Kiểm tra validation cơ bản
                    if (username.isEmpty || password.isEmpty || hoten.isEmpty || sdt.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
                      );
                      return;
                    }
                    if (sdt.length < 10 || sdt.length > 11 || !RegExp(r'^[0-9]+$').hasMatch(sdt)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Số điện thoại không hợp lệ.')),
                      );
                      return;
                    }

                    try {
                      // Bước 1: Chèn dữ liệu vào bảng NHANVIEN trước
                      // Để lấy được MANHANVIEN (ID tự động tăng)
                      int manhanvienId = await DatabaseHelper.insert(
                        'NHANVIEN',
                        {
                          'HOTEN': hoten,
                          'CHUCVU': _selectedChucVu,
                          'SDT': sdt,
                        },
                      );

                      if (manhanvienId > 0) {
                        // Bước 2: Chèn dữ liệu vào bảng USER, sử dụng MANHANVIEN vừa nhận được
                        int userId = await DatabaseHelper.insert(
                          'USER',
                          {
                            'USERNAME': username,
                            'PASSWORD': password,
                            'MANV': manhanvienId, // Gán MANV từ NHANVIEN vừa tạo
                          },
                        );

                        if (userId > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tạo tài khoản $username thành công!')),
                          );
                          // Xóa dữ liệu trên form sau khi tạo thành công
                          _usernameController.clear();
                          _passwordController.clear();
                          _hotenController.clear();
                          _sdtController.clear();
                          setState(() {
                            _selectedChucVu = 'Nhân viên'; // Reset chức vụ về mặc định
                          });
                        } else {
                          // Nếu tạo USER thất bại, cân nhắc xóa NHANVIEN vừa tạo để tránh dữ liệu rác
                          await DatabaseHelper.delete('NHANVIEN', manhanvienId, idColumn: 'MANHANVIEN');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tạo tài khoản USER thất bại. Tên đăng nhập có thể đã tồn tại.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tạo thông tin NHANVIEN thất bại.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi tạo tài khoản: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text(
                    "Tạo Tài khoản",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm tiện ích để xây dựng TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(255, 224, 224, 224), // Xám nhẹ
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 42, 45, 50)),
        labelText: labelText,
        labelStyle: const TextStyle(color: Color.fromARGB(255, 74, 74, 74)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

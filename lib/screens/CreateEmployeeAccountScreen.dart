import 'package:flutter/material.dart';
import 'package:doan/database_helper.dart';

class CreateEmployeeAccountScreen extends StatefulWidget {
  const CreateEmployeeAccountScreen({Key? key}) : super(key: key);

  @override
  State<CreateEmployeeAccountScreen> createState() => _CreateEmployeeAccountScreenState();
}

class _CreateEmployeeAccountScreenState extends State<CreateEmployeeAccountScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _hotenController = TextEditingController();
  final TextEditingController _sdtController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // Thêm controller xác nhận mật khẩu

  String _selectedChucVu = 'Nhân viên';
  final List<String> _chucVuOptions = ['Nhân viên', 'Quản lý'];

  Map<String, dynamic>? _nhanVienData;
  bool _daCoTaiKhoan = false;
  bool _dangTim = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _hotenController.dispose();
    _sdtController.dispose();
    _confirmPasswordController.dispose(); // dispose controller mới
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 247, 247),
      appBar: AppBar(
        title: const Text('Cấp Tài khoản Nhân viên', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _sdtController,
                labelText: 'Số điện thoại',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                onChanged: (value) async {
                  if (value.length == 10 && !_dangTim) {
                    _dangTim = true;
                    final nhanvien = await DatabaseHelper.getItemByColumn('NHANVIEN', 'SDT', value);
                    if (nhanvien != null) {
                      final user = await DatabaseHelper.getItemByColumn('USER', 'MANV', nhanvien['MANHANVIEN']);
                      setState(() {
                        _nhanVienData = nhanvien;
                        _hotenController.text = nhanvien['HOTEN'] ?? '';
                        _selectedChucVu = (nhanvien['MACV'] == 1) ? 'Quản lý' : 'Nhân viên';
                        _daCoTaiKhoan = user != null;
                      });

                      if (_daCoTaiKhoan) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nhân viên này đã có tài khoản.')),
                        );
                      }
                    } else {
                      setState(() {
                        _nhanVienData = null;
                        _hotenController.clear();
                        _selectedChucVu = 'Nhân viên';
                        _daCoTaiKhoan = false;
                      });
                    }
                    _dangTim = false;
                  }
                },
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _hotenController,
                labelText: 'Họ tên',
                icon: Icons.badge_outlined,
                enabled: _nhanVienData == null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedChucVu,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 224, 224, 224),
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
                onChanged: _nhanVienData == null
                    ? (String? newValue) {
                        setState(() {
                          _selectedChucVu = newValue!;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _usernameController,
                labelText: 'Tên đăng nhập',
                icon: Icons.person_outline,
                enabled: !_daCoTaiKhoan,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _passwordController,
                labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                icon: Icons.lock_outline,
                isPassword: true,
                enabled: !_daCoTaiKhoan,
              ),
              const SizedBox(height: 15),
              // Thêm trường xác nhận mật khẩu
              _buildTextField(
                controller: _confirmPasswordController,
                labelText: 'Xác nhận lại mật khẩu',
                icon: Icons.lock_outline,
                isPassword: true,
                enabled: !_daCoTaiKhoan,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (_daCoTaiKhoan) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nhân viên này đã có tài khoản. Không thể tạo thêm.')),
                      );
                      return;
                    }

                    final String username = _usernameController.text.trim();
                    final String password = _passwordController.text;
                    final String confirmPassword = _confirmPasswordController.text; // Lấy xác nhận mật khẩu
                    final String hoten = _hotenController.text.trim();
                    final String sdt = _sdtController.text.trim();

                    if (username.isEmpty || password.isEmpty || hoten.isEmpty || sdt.isEmpty || confirmPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
                      );
                      return;
                    }

                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự.')),
                      );
                      return;
                    }

                    if (sdt.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(sdt)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Số điện thoại không hợp lệ.')),
                      );
                      return;
                    }

                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mật khẩu xác nhận không khớp.')),
                      );
                      return;
                    }

                    try {
                      int manhanvienId;

                      if (_nhanVienData != null) {
                        manhanvienId = _nhanVienData!['MANHANVIEN'];
                      } else {
                        int chucVuValue = (_selectedChucVu == "Quản lý") ? 1 : 2;
                        manhanvienId = await DatabaseHelper.insert(
                          'NHANVIEN',
                          {
                            'HOTEN': hoten,
                            'MACV': chucVuValue,
                            'SDT': sdt,
                          },
                        );

                        if (manhanvienId <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tạo thông tin nhân viên thất bại.')),
                          );
                          return;
                        }
                      }

                      int userId = await DatabaseHelper.insert(
                        'USER',
                        {
                          'USERNAME': username,
                          'PASSWORD': password,
                          'MANV': manhanvienId,
                        },
                      );

                      if (userId > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tạo tài khoản $username thành công!')),
                        );
                        _usernameController.clear();
                        _passwordController.clear();
                        _hotenController.clear();
                        _sdtController.clear();
                        setState(() {
                          _selectedChucVu = 'Nhân viên';
                          _nhanVienData = null;
                          _daCoTaiKhoan = false;
                        });
                      } else {
                        if (_nhanVienData == null) {
                          await DatabaseHelper.delete('NHANVIEN', manhanvienId, idColumn: 'MANHANVIEN');
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tạo tài khoản thất bại. Tên đăng nhập có thể đã tồn tại.')),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(255, 224, 224, 224),
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

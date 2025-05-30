import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doan/model/nhanvien.dart';
import 'package:doan/provider/account_provider.dart';

class ProfileScreen extends StatefulWidget {
  final NhanVien nhanVien;
  const ProfileScreen({Key? key, required this.nhanVien}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final nhanVien = widget.nhanVien;
    _nameController = TextEditingController(text: nhanVien.hoTen);
    _phoneController = TextEditingController(text: nhanVien.sdt);
    _positionController = TextEditingController(text: nhanVien.chucVu);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, _) {
        if (accountProvider.nhanVien == null) {
          accountProvider.setNhanVien(widget.nhanVien);
          _nameController.text = widget.nhanVien.hoTen;
          _phoneController.text = widget.nhanVien.sdt;
        } else {
          _nameController.text = accountProvider.nameController.text;
          _phoneController.text = accountProvider.phoneController.text;
        }

        _positionController = TextEditingController(
          text: accountProvider.nhanVien?.chucVu ?? '',
        );

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 247, 247, 247),
          appBar: AppBar(
            title: const Text(
              "Thông tin tài khoản",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color.fromARGB(255, 107, 66, 38),
            actions: [
              IconButton(
                icon: Icon(accountProvider.isEditing ? Icons.check : Icons.edit),
                color: Colors.white,
                onPressed: () {
                  if (accountProvider.isEditing) {
                    accountProvider.updateNhanVienFromControllers(
                      _nameController.text,
                      _phoneController.text,
                      showError: (msg) => ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg))),
                      showSuccess: (msg) => ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg))),
                    );
                  } else {
                    accountProvider.toggleEditing();
                  }
                },
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  "Họ tên",
                  _nameController,
                  Icons.person,
                  enabled: accountProvider.isEditing,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  "Chức vụ",
                  _positionController,
                  Icons.work,
                  enabled: false,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  "Số điện thoại",
                  _phoneController,
                  Icons.phone,
                  enabled: accountProvider.isEditing,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 107, 66, 38),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: accountProvider.isEditing
                        ? () {
                            accountProvider.updateNhanVienFromControllers(
                              _nameController.text,
                              _phoneController.text,
                              showError: (msg) => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(msg))),
                              showSuccess: (msg) => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(msg))),
                            );
                          }
                        : null,
                    child: const Text(
                      "Lưu thông tin",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => _showChangePasswordDialog(context),
                    child: const Text(
                      "Đổi mật khẩu",
                      style: TextStyle(
                        color: Color.fromARGB(255, 107, 66, 38),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(255, 224, 224, 224),
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 42, 45, 50)),
        labelText: label,
        labelStyle: const TextStyle(color: Color.fromARGB(255, 74, 74, 74)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Đổi mật khẩu"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mật khẩu hiện tại"),
                ),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mật khẩu mới"),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Xác nhận mật khẩu mới"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                final oldPass = oldPasswordController.text;
                final newPass = newPasswordController.text;
                final confirmPass = confirmPasswordController.text;

                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mật khẩu xác nhận không khớp")),
                  );
                  return;
                }

                Provider.of<AccountProvider>(context, listen: false).changePassword(
                  oldPassword: oldPass,
                  newPassword: newPass,
                  showError: (msg) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  },
                  showSuccess: (msg) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  },
                );
              },
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
  }
}

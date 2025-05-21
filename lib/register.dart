import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 247, 247, 247), // Nền trắng sữa
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tạo tài khoản mới",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 30, 30, 30),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Nhập thông tin bên dưới để tiếp tục",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 74, 74, 74),
                ),
              ),
              SizedBox(height: 30),

              // Họ tên
              _buildTextField("Họ tên", Icons.person),
              SizedBox(height: 15),

              // Email
              _buildTextField("Email", Icons.email),
              SizedBox(height: 15),

              // Mật khẩu
              _buildTextField("Mật khẩu", Icons.lock, isPassword: true),
              SizedBox(height: 15),

              // Xác nhận mật khẩu
              _buildTextField("Xác nhận mật khẩu", Icons.lock, isPassword: true),
              SizedBox(height: 25),

              // Nút đăng ký
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
                  onPressed: () {},
                  child: Text(
                    "Đăng ký",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Chuyển sang đăng nhập
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Đã có tài khoản?", style: TextStyle(color: Color.fromARGB(255, 74, 74, 74))),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Đăng nhập",
                      style: TextStyle(
                        color: Color.fromARGB(255, 107, 66, 38),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Color.fromARGB(255, 224, 224, 224), // Xám nhẹ
        prefixIcon: Icon(icon, color: Color.fromARGB(255, 42, 45, 50)),
        hintText: hint,
        hintStyle: TextStyle(color: Color.fromARGB(255, 74, 74, 74)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

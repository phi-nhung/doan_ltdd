import 'package:doan/adminHome.dart';
import 'package:doan/provider/account_provider.dart';
import 'package:doan/register.dart';
import 'package:doan/screens/forgotPasswordScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_provider.dart';
import 'package:doan/model/nhanvien.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  

  @override
  Widget build(BuildContext context,) {
    final TextEditingController _userNameControlelr = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    return Scaffold(
      
      backgroundColor: Color.fromARGB(255, 247, 247, 247), // Trắng sữa
      
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Chào mừng bạn!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 30, 30, 30), // Đen tinh tế
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Đăng nhập để tiếp tục",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 74, 74, 74), // Xám đậm
                ),
              ),
              SizedBox(height: 30),

              // Email Input
              _buildTextField("Tên đăng nhập", Icons.person_outline, controller: _userNameControlelr),
              SizedBox(height: 15),

              // Password Input
              _buildTextField("Mật khẩu", Icons.lock, isPassword: true, controller: _passwordController),
              SizedBox(height: 25),

              // Login Button
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
                  onPressed: () async {
                  final userName = _userNameControlelr.text.trim();
                  final password = _passwordController.text;

                  final loginProvider = Provider.of<LoginProvider>(context, listen: false);
                  final NhanVien? nhanVien = await loginProvider.login(userName, password);

                  if (nhanVien != null) {
                    Provider.of<AccountProvider>(context, listen: false).setNhanVien(nhanVien);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminHome(), 
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sai tên đăng nhập hoặc mật khẩu')),
                    );
                  }
                },


                  child: Text(
                    "Đăng nhập",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Forgot Password & Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Quên mật khẩu?", style: TextStyle(color: Color.fromARGB(255, 74, 74, 74))),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(), 
                        ),
                      );
                    },
                    child: Text(
                      "Đặt lại",
                      style: TextStyle(
                        color: Color.fromARGB(255, 107, 66, 38), // Nâu mocha
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon,
    {bool isPassword = false, required TextEditingController controller}) {
  return TextField(
    controller: controller,
    obscureText: isPassword,
    decoration: InputDecoration(
      filled: true,
      fillColor: Color.fromARGB(255, 224, 224, 224),
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

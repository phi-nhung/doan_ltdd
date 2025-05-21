import 'package:doan/account.dart';
import 'package:doan/doanhthu.dart';
import 'package:doan/login.dart';
import 'package:doan/model/nhanvien.dart';
import 'package:doan/provider/account_provider.dart';
import 'package:doan/qlban.dart';
import 'package:doan/qlmathang.dart';
import 'package:doan/qlnhanvien.dart';
import 'package:doan/quanlykhachhang.dart';
import 'package:doan/screens/CreateEmployeeAccountScreen.dart';
import 'package:doan/screens/order_list_screen.dart';
import 'package:doan/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nhanVienProvider = Provider.of<AccountProvider>(context);
    final nhanVien = nhanVienProvider.nhanVien;

    if (nhanVien == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String chucVu = nhanVien.chucVu.toLowerCase();

    final List<_DashboardItem> allItems = [
      _DashboardItem(const OrderScreen(), Icons.sell_outlined, "Bán hàng"),
      _DashboardItem(OrderListScreen(), Icons.list_alt_rounded, "Đơn hàng"),
      _DashboardItem(const QL_Ban(), Icons.table_chart, "Quản lý bàn"),
      _DashboardItem(const QL_MatHang(), Icons.menu_book, "Quản lý menu"),
      _DashboardItem(QL_KhachHang(), Icons.person_pin_outlined, "Khách hàng"),
      _DashboardItem(const QL_NhanVien(), Icons.people, "Nhân viên"),
      _DashboardItem(DoanhThu(), Icons.bar_chart_outlined, "Doanh thu"),
      _DashboardItem(const OrderScreen(), Icons.settings, "Cài đặt"),
      _DashboardItem(const CreateEmployeeAccountScreen(), Icons.person_add_alt_1_rounded, "Cấp tài tài khoản"),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "KIOT",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 50),
        ),
        backgroundColor: Colors.brown,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                _showUserMenu(context, nhanVien);
              },
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Text(
                        nhanVien.hoTen,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: allItems
            .map((item) => _buildDashboardItem(context, item.widget, item.icon, item.title, chucVu))
            .toList(),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, Widget app, IconData icon, String title, String chucVu) {
    return GestureDetector(
      onTap: () {
        final allowedForNhanVien = [
          "Bán hàng",
          "Đơn hàng",
          "Quản lý bàn",
          "Khách hàng",
          "Doanh thu",
          "Cài đặt",
        ];

        if ((chucVu == 'nhân viên' || chucVu == 'nhan vien') && !allowedForNhanVien.contains(title)) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Thông báo"),
              content: const Text("Chỉ có quản lý mới được thực thi chức năng này."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Đóng"),
                )
              ],
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => app),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.brown),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showUserMenu(BuildContext context, NhanVien nhanVien) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 60, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'account',
          child: Row(
            children: [
              Icon(Icons.account_circle, color: Colors.black),
              SizedBox(width: 8),
              Text('Tài khoản'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black),
              SizedBox(width: 8),
              Text('Đăng xuất'),
            ],
          ),
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value == 'account') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(nhanVien: nhanVien),
          ),
        );
      } else if (value == 'logout') {
        _handleLogout(context);
      }
    });
  }

  void _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _DashboardItem {
  final Widget widget;
  final IconData icon;
  final String title;

  _DashboardItem(this.widget, this.icon, this.title);
}

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
import 'package:doan/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doan/screens/settings_screen.dart';
import 'utils/app_localizations.dart';
import 'package:doan/provider/locale_provider.dart';

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

    final String chucVu = nhanVien.maCV.toString().toLowerCase();
    print ('Chức vụ của nhân viên: $chucVu');

    final List<_DashboardItem> allItems = [
      _DashboardItem(const OrderScreen(), Icons.sell_outlined, 
        AppLocalizations.get(context, 'sell')),
      _DashboardItem(OrderListScreen(), Icons.list_alt_rounded, 
        AppLocalizations.get(context, 'orders')),
      _DashboardItem(const QL_Ban(), Icons.table_chart, 
        AppLocalizations.get(context, 'table_management')),
      _DashboardItem(const QL_MatHang(), Icons.menu_book, 
        AppLocalizations.get(context, 'menu_management')),
      _DashboardItem(QL_KhachHang(), Icons.person_pin_outlined, 
        AppLocalizations.get(context, 'customers')),
      _DashboardItem(const QL_NhanVien(), Icons.people, 
        AppLocalizations.get(context, 'employees')),
      _DashboardItem(DoanhThu(), Icons.bar_chart_outlined, 
        AppLocalizations.get(context, 'revenue')),
      // _DashboardItem(const SettingsScreen(), Icons.settings, 
      //   AppLocalizations.get(context, 'settings')),
      _DashboardItem(const CreateEmployeeAccountScreen(), Icons.person_add_alt_1_rounded, 
        AppLocalizations.get(context, 'create_account')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Consumer<LocaleProvider>(
          builder: (context, provider, child) => Text(
            AppLocalizations.get(context, 'app_name'),
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold, 
              fontSize: 50
            ),
          ),
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
      body: Consumer<LocaleProvider>(
        builder: (context, provider, child) {
          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            
            children: allItems
                .map((item) => _buildDashboardItem(
                    context, item.widget, item.icon, item.title, chucVu))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, Widget app, IconData icon, String title, String chucVu) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) => GestureDetector(
        onTap: () {
          final allowedForNhanVien = [
            AppLocalizations.get(context, 'sell'),
            AppLocalizations.get(context, 'orders'),
            AppLocalizations.get(context, 'table_management'),
            AppLocalizations.get(context, 'customers'),
            AppLocalizations.get(context, 'revenue'),
            AppLocalizations.get(context, 'settings'),
          ];
          if ((chucVu == '2' ) && !allowedForNhanVien.contains(title)) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(AppLocalizations.get(context, 'notification')),
                content: Text(AppLocalizations.get(context, 'admin_only')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.get(context, 'close')),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.brown),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserMenu(BuildContext context, NhanVien nhanVien) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 60, 0, 0),
      items: [
        PopupMenuItem(
          value: 'account',
          child: Row(
            children: [
              Icon(Icons.account_circle, color: Colors.black),
              SizedBox(width: 8),
              Text(AppLocalizations.get(context, 'account')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black),
              SizedBox(width: 8),
              Text(AppLocalizations.get(context, 'logout')),
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

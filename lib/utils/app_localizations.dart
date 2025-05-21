import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/locale_provider.dart';

class AppLocalizations {
  static String get(BuildContext context, String key) {
    final locale = Provider.of<LocaleProvider>(context, listen: true).locale.languageCode;
    final _localizedValues = {
      'vi': {
        // Navigation & Titles
        'coffee_shop': 'Quán Cafe',
        'menu': 'Thực đơn',
        'home': 'Trang chủ',
        
        // Dashboard Items
        'order': 'Bán hàng',
        'orders': 'Đơn hàng',
        'table_management': 'Quản lý bàn',
        'menu_management': 'Quản lý menu',
        'customers': 'Khách hàng',
        'employees': 'Nhân viên',
        'revenue': 'Doanh thu',
        'settings': 'Cài đặt',
        
        // Settings Screen
        'dark_mode': 'Chế độ tối',
        'language': 'Ngôn ngữ',
        'notifications': 'Thông báo',
        'security': 'Bảo mật',
        'version': 'Phiên bản',
        
        // Order Screen
        'take_away': 'Mang đi',
        'at_table': 'Tại bàn',
        'table': 'Bàn',
        'empty': 'Trống',
        'in_use': 'Đang sử dụng',
        'search_product': 'Tìm kiếm sản phẩm',
        'add': 'Thêm',
        'cancel': 'Hủy',
        'save': 'Lưu',
        
        // Account
        'account': 'Tài khoản',
        'profile': 'Hồ sơ',
        'logout': 'Đăng xuất',
        'full_name': 'Họ và tên',
        'email': 'Email',
        'phone': 'Số điện thoại',
        
        // Common
        'all': 'Tất cả',
        'today': 'Hôm nay',
        'yesterday': 'Hôm qua',
        'this_week': 'Tuần này',
        'edit': 'Chỉnh sửa',
        'delete': 'Xóa',
        'confirm': 'Xác nhận',
        'font': 'Phông chữ',
        'dashboard': 'Trang chủ quản trị',
      },
      'en': {
        // Navigation & Titles
        'coffee_shop': 'Coffee Shop',
        'menu': 'Menu',
        'home': 'Home',
        
        // Dashboard Items
        'order': 'Order',
        'orders': 'Orders',
        'table_management': 'Table Management',
        'menu_management': 'Menu Management',
        'customers': 'Customers',
        'employees': 'Employees',
        'revenue': 'Revenue',
        'settings': 'Settings',
        
        // Settings Screen
        'dark_mode': 'Dark Mode',
        'language': 'Language',
        'notifications': 'Notifications',
        'security': 'Security',
        'version': 'Version',
        
        // Order Screen
        'take_away': 'Take Away',
        'at_table': 'Dine In',
        'table': 'Table',
        'empty': 'Empty',
        'in_use': 'In Use',
        'search_product': 'Search Product',
        'add': 'Add',
        'cancel': 'Cancel',
        'save': 'Save',
        
        // Account
        'account': 'Account',
        'profile': 'Profile',
        'logout': 'Logout',
        'full_name': 'Full Name',
        'email': 'Email',
        'phone': 'Phone',
        
        // Common
        'all': 'All',
        'today': 'Today',
        'yesterday': 'Yesterday',
        'this_week': 'This Week',
        'edit': 'Edit',
        'delete': 'Delete',
        'confirm': 'Confirm',
        'font': 'Font',
        'dashboard': 'Dashboard',
      }
    };
    return _localizedValues[locale]?[key] ?? key;
  }
}

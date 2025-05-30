import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/locale_provider.dart';

class AppLocalizations {
  static String get(BuildContext context, String key) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    final _localizedValues = {
      'vi': {
        // App Name
        'app_name': 'SEOR',
        
        // Dashboard Items
        'sell': 'Bán hàng',
        'orders': 'Đơn hàng',
        'table_management': 'Quản lý bàn',
        'menu_management': 'Quản lý menu',
        'customers': 'Khách hàng',
        'employees': 'Nhân viên',
        'revenue': 'Doanh thu',
        'settings': 'Cài đặt',
        'create_account': 'Cấp tài khoản',
        
        // Account Menu
        'account': 'Tài khoản',
        'logout': 'Đăng xuất',
        
        // Messages
        'loading': 'Đang tải...',
        'admin_only': 'Chỉ có quản lý mới được thực thi chức năng này.',
        'notification': 'Thông báo',
        'close': 'Đóng',
        
        // Settings Screen
        'settings_title': 'Cài đặt',
        'language': 'Ngôn ngữ',
        'vietnamese': 'Tiếng Việt',
        'english': 'Tiếng Anh',
        'theme': 'Giao diện',
        'dark_mode': 'Chế độ tối',
        'light_mode': 'Chế độ sáng',
        'font': 'Phông chữ',
        'save': 'Lưu',
        'cancel': 'Hủy',
      },
      'en': {
        // App Name
        'app_name': 'SEOR',
        
        // Dashboard Items
        'sell': 'Sell',
        'orders': 'Orders',
        'table_management': 'Table Management',
        'menu_management': 'Menu Management',
        'customers': 'Customers',
        'employees': 'Employees',
        'revenue': 'Revenue',
        'settings': 'Settings',
        'create_account': 'Create Account',
        
        // Account Menu
        'account': 'Account',
        'logout': 'Logout',
        
        // Messages
        'loading': 'Loading...',
        'admin_only': 'Only administrators can access this feature.',
        'notification': 'Notification',
        'close': 'Close',
        
        // Settings Screen  
        'settings_title': 'Settings',
        'language': 'Language',
        'vietnamese': 'Vietnamese',
        'english': 'English', 
        'theme': 'Theme',
        'dark_mode': 'Dark mode',
        'light_mode': 'Light mode',
        'font': 'Font',
        'save': 'Save',
        'cancel': 'Cancel',
      }
    };
    return _localizedValues[locale]?[key] ?? key;
  }
}

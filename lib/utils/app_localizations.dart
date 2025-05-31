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
        'success': 'Thành công',
        'error': 'Lỗi',
        'confirm': 'Xác nhận',
        'cancel': 'Hủy',
        'save': 'Lưu',
        'delete': 'Xóa',
        'edit': 'Sửa',
        'add': 'Thêm',
        'search': 'Tìm kiếm',
        'no_data': 'Không có dữ liệu',
        
        // Settings Screen
        'settings_title': 'Cài đặt',
        'language': 'Ngôn ngữ',
        'vietnamese': 'Tiếng Việt',
        'english': 'Tiếng Anh',
        'font': 'Phông chữ',
        
        // Login Screen
        'login': 'Đăng nhập',
        'username': 'Tên đăng nhập',
        'password': 'Mật khẩu',
        'forgot_password': 'Quên mật khẩu?',
        'login_failed': 'Đăng nhập thất bại',
        
        // Checkout Screen
        'checkout': 'Thanh toán',
        'payment_method': 'Phương thức thanh toán',
        'cash': 'Tiền mặt',
        'card': 'Thẻ',
        'transfer': 'Chuyển khoản',
        'discount': 'Giảm giá',
        'additional_fee': 'Phụ thu',
        'total': 'Tổng tiền',
        'confirm_payment': 'Xác nhận thanh toán',
        'print_invoice': 'In hóa đơn',
        'print_invoice_confirm': 'Bạn có muốn in hóa đơn không?',
        'yes': 'Có',
        'no': 'Không',
        
        // Customer Management
        'customer_info': 'Thông tin khách hàng',
        'customer_name': 'Họ tên',
        'phone': 'Số điện thoại',
        'address': 'Địa chỉ',
        'email': 'Email',
        'points': 'Điểm tích lũy',
        'customer_type': 'Loại khách hàng',
        'regular': 'Thường',
        'silver': 'Bạc',
        'gold': 'Vàng',
        'add_customer': 'Thêm khách hàng',
        'edit_customer': 'Sửa thông tin khách hàng',
        'search_customer': 'Tìm khách hàng',
        
        // Menu Management
        'menu_item': 'Món ăn',
        'price': 'Giá',
        'category': 'Danh mục',
        'image': 'Hình ảnh',
        'status': 'Trạng thái',
        'available': 'Còn hàng',
        'unavailable': 'Hết hàng',
        
        // Table Management
        'table': 'Bàn',
        'status': 'Trạng thái',
        'empty': 'Trống',
        'occupied': 'Đang sử dụng',
        'reserved': 'Đã đặt trước',
        
        // Revenue
        'daily': 'Hôm nay',
        'weekly': 'Tuần này',
        'monthly': 'Tháng này',
        'yearly': 'Năm nay',
        'total_revenue': 'Tổng doanh thu',
        'total_orders': 'Tổng đơn hàng',
        'average_order': 'Đơn hàng trung bình',
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
        'success': 'Success',
        'error': 'Error',
        'confirm': 'Confirm',
        'cancel': 'Cancel',
        'save': 'Save',
        'delete': 'Delete',
        'edit': 'Edit',
        'add': 'Add',
        'search': 'Search',
        'no_data': 'No data available',
        
        // Settings Screen
        'settings_title': 'Settings',
        'language': 'Language',
        'vietnamese': 'Vietnamese',
        'english': 'English',
        'font': 'Font',
        
        // Login Screen
        'login': 'Login',
        'username': 'Username',
        'password': 'Password',
        'forgot_password': 'Forgot Password?',
        'login_failed': 'Login Failed',
        
        // Checkout Screen
        'checkout': 'Checkout',
        'payment_method': 'Payment Method',
        'cash': 'Cash',
        'card': 'Card',
        'transfer': 'Transfer',
        'discount': 'Discount',
        'additional_fee': 'Additional Fee',
        'total': 'Total',
        'confirm_payment': 'Confirm Payment',
        'print_invoice': 'Print Invoice',
        'print_invoice_confirm': 'Do you want to print the invoice?',
        'yes': 'Yes',
        'no': 'No',
        
        // Customer Management
        'customer_info': 'Customer Information',
        'customer_name': 'Full Name',
        'phone': 'Phone Number',
        'address': 'Address',
        'email': 'Email',
        'points': 'Points',
        'customer_type': 'Customer Type',
        'regular': 'Regular',
        'silver': 'Silver',
        'gold': 'Gold',
        'add_customer': 'Add Customer',
        'edit_customer': 'Edit Customer',
        'search_customer': 'Search Customer',
        
        // Menu Management
        'menu_item': 'Menu Item',
        'price': 'Price',
        'category': 'Category',
        'image': 'Image',
        'status': 'Status',
        'available': 'Available',
        'unavailable': 'Unavailable',
        
        // Table Management
        'table': 'Table',
        'status': 'Status',
        'empty': 'Empty',
        'occupied': 'Occupied',
        'reserved': 'Reserved',
        
        // Revenue
        'daily': 'Today',
        'weekly': 'This Week',
        'monthly': 'This Month',
        'yearly': 'This Year',
        'total_revenue': 'Total Revenue',
        'total_orders': 'Total Orders',
        'average_order': 'Average Order',
      }
    };
    return _localizedValues[locale]?[key] ?? key;
  }
}

import 'package:doan/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/cart_provider.dart';
import '../provider/account_provider.dart';
import '../model/cart_item.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  final int? tableNumber;
  final VoidCallback onCheckout;

  const CheckoutScreen({
    Key? key,
    required this.tableNumber,
    required this.onCheckout,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'Tiền mặt';
  double _discount = 0;
  double _additionalFee = 0;
  Map<String, dynamic>? _customer;  // Add this line to track selected customer
  bool _applyDiscount = false;
  int _pointsToDeduct = 0;

  // Add this method to show customer search dialog
  Future<void> _showCustomerSearchDialog() async {
    final TextEditingController phoneController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tìm khách hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Hủy'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: Text('Tìm'),
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) return;

              try {
                // Sửa câu query để lấy thêm thông tin loại khách hàng
                final results = await DatabaseHelper.rawQuery(
                  '''
                  SELECT kh.*, lkh.TENLOAIKH, lkh.CHIETKHAU 
                  FROM KHACHHANG kh
                  LEFT JOIN LOAIKHACHHANG lkh ON 
                    CASE 
                      WHEN kh.DIEMTL >= 1000 THEN lkh.MALOAIKH = 3
                      WHEN kh.DIEMTL >= 500 THEN lkh.MALOAIKH = 2
                      ELSE lkh.MALOAIKH = 1
                    END
                  WHERE kh.SDT = ?
                  ''',
                  [phone]
                );

                if (results.isNotEmpty) {
                  // Tự động áp dụng chiết khấu từ loại khách hàng
                  setState(() {
                    _customer = results.first;
                    // Không tự động set _discount, chỉ lưu chiết khấu vào _customer
                  });
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không tìm thấy khách hàng')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _customer = result);
    }
  }

  void _showNewCustomerForm(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thêm khách hàng mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Họ tên *'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Số điện thoại *'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Địa chỉ'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Hủy'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: Text('Thêm'),
            onPressed: () async {
              final phone = phoneController.text.trim();
              final name = nameController.text.trim();
              
              if (phone.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui lòng nhập họ tên và số điện thoại')),
                );
                return;
              }

              try {
                // Kiểm tra số điện thoại đã tồn tại
                final existing = await DatabaseHelper.rawQuery(
                  'SELECT * FROM KHACHHANG WHERE SDT = ?',
                  [phone]
                );

                if (existing.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Số điện thoại đã tồn tại')),
                  );
                  return;
                }

                // Thêm khách hàng mới
                final id = await DatabaseHelper.rawInsert(
                  '''INSERT INTO KHACHHANG (HOTEN, SDT, DIACHI, EMAIL, DIEMTL)
                     VALUES (?, ?, ?, ?, 0)''',
                  [name, phone, addressController.text, emailController.text]
                );

                final newCustomer = {
                  'MAKH': id,
                  'HOTEN': name,
                  'SDT': phone,
                  'DIACHI': addressController.text,
                  'EMAIL': emailController.text,
                  'DIEMTL': 0,
                };

                setState(() => _customer = newCustomer);
                setState(() => _discount = 0);
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã thêm khách hàng mới')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Update the save order button
  Widget _buildSaveOrderButton(CartProvider cartProvider, items, totalAmount, nhanVien) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
      ),
      onPressed: () async {
        try {
          // Get correct items list based on table number
          final orderItems = widget.tableNumber != null 
              ? cartProvider.tableItems[widget.tableNumber] ?? []
              : items;

          await cartProvider.saveOrder(
            items: orderItems,
            totalAmount: totalAmount,
            paymentMethod: _selectedPaymentMethod,
            tableNumber: widget.tableNumber,
            manv: nhanVien.maNhanVien,
            tennv: nhanVien.hoTen,
            customer: _customer,
            discount: _applyDiscount ? _discount : 0,
            additionalFee: _additionalFee,
          );
          
          // Clear the appropriate cart
          if (widget.tableNumber != null) {
            cartProvider.clearTableCart(widget.tableNumber!);
          } else {
            cartProvider.clearCart();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thanh toán thành công')),
          );
          
          widget.onCheckout();
          Navigator.of(context).pop();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      },
      child: Text('Xác nhận thanh toán'),
    );
  }

  // Sửa lại widget _buildCustomerSection()
  Widget _buildCustomerSection() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với icon và title
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person, color: Colors.brown),
              title: Text(
                'Thông tin khách hàng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: _customer == null
                  ? TextButton.icon(
                      icon: Icon(Icons.search),
                      label: Text('Tìm khách hàng'),
                      onPressed: _showCustomerSearchDialog,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.edit),
                          label: Text('Thay đổi'),
                          onPressed: _showCustomerSearchDialog,
                        ),
                        IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => setState(() => _customer = null),
                        ),
                      ],
                    ),
            ),

            // Hiển thị thông tin khách hàng nếu có
            if (_customer != null) ...[
              Divider(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          _customer!['HOTEN'] ?? '',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          _customer!['SDT'] ?? '',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.stars_outlined, size: 20, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Điểm tích lũy: ${_customer!['DIEMTL'] ?? 0}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.brown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.card_membership, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Loại khách hàng: ${_customer!['TENLOAIKH'] ?? 'Thường'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_customer!['CHIETKHAU'] != null && _customer!['CHIETKHAU'] > 0)
                      Row(
                        children: [
                          Icon(Icons.discount, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Chiết khấu: ${_customer!['CHIETKHAU']}%',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ] else ...[
              // Hiển thị khi chưa chọn khách hàng
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: TextButton.icon(
                    icon: Icon(Icons.person_add),
                    label: Text('Thêm khách hàng mới'),
                    onPressed: () => _showNewCustomerForm(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.brown,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);
    final nhanVien = accountProvider.nhanVien!;
    final items = widget.tableNumber != null
        ? cartProvider.tableItems[widget.tableNumber] ?? []
        : cartProvider.items;
    final totalAmount = widget.tableNumber != null
        ? cartProvider.getTableTotalAmount(widget.tableNumber!)
        : cartProvider.totalAmount;
    final points = cartProvider.calculatePoints(totalAmount);

    final chietKhauPercent = (_customer != null && _customer!['CHIETKHAU'] != null)
      ? ((_customer!['CHIETKHAU'] as num) * 100)
      : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tableNumber != null 
            ? 'Thanh toán - Bàn ${widget.tableNumber}' 
            : 'Thanh toán mang về'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Thông tin nhân viên
            Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text('Nhân viên: ${nhanVien.hoTen}'),
                subtitle: Text('Mã NV: ${nhanVien.maNhanVien}'),
              ),
            ),

            // Danh sách sản phẩm
            Card(
              margin: EdgeInsets.all(8),
              child: Column(
                children: [
                  ...items.map((item) => ListTile(
                    leading: item.item.image != null
                        ? Image.memory(item.item.image!, width: 40, height: 40)
                        : Icon(Icons.image),
                    title: Text(item.item.name),
                    subtitle: Text(
                      'Đơn giá: ${NumberFormat('#,##0').format(item.item.price)}đ'
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('SL: ${item.quantity}'),
                        Text(
                          '${NumberFormat('#,##0').format(item.item.price * item.quantity)}đ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            // Thông tin khách hàng
            _buildCustomerSection(),

            // Phương thức thanh toán
            Card(
              margin: EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Phương thức thanh toán'),
                  ),
                  RadioListTile<String>(
                    title: Text('Tiền mặt'),
                    value: 'Tiền mặt',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                  ),
                  RadioListTile<String>(
                    title: Text('Thẻ'),
                    value: 'Thẻ',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                  ),
                  RadioListTile<String>(
                    title: Text('Chuyển khoản'),
                    value: 'Chuyển khoản',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                  ),
                  if (_selectedPaymentMethod == 'Chuyển khoản')
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.asset(
                        'assets/qr.jpg',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              ),
            ),

            // Giảm giá và phụ thu
            Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_customer != null && _customer!['CHIETKHAU'] != null && (_customer!['CHIETKHAU'] as num) > 0)
                      Row(
                        children: [
                          Switch(
                            value: _applyDiscount,
                            onChanged: (val) async {
                              setState(() {
                                _applyDiscount = val;
                                if (_applyDiscount) {
                                  _discount = (_customer!['CHIETKHAU'] as num) * 100;
                                  _pointsToDeduct = cartProvider.calculatePoints(totalAmount).toInt();
                                } else {
                                  _discount = 0;
                                  _pointsToDeduct = 0;
                                }
                              });
                              if (_applyDiscount && _customer != null && _customer!['DIEMTL'] != null) {
                                // Trừ điểm tích lũy trong DB
                                int newPoint = (_customer!['DIEMTL'] as int) - _pointsToDeduct;
                                if (newPoint < 0) newPoint = 0;
                                await DatabaseHelper.rawUpdate(
                                  'UPDATE KHACHHANG SET DIEMTL = ? WHERE MAKH = ?',
                                  [newPoint, _customer!['MAKH']]
                                );
                              }
                            },
                          ),
                          Text('Áp dụng chiết khấu thành viên (${chietKhauPercent.round()}%)'),
                        ],
                      ),
                    if (_applyDiscount && _pointsToDeduct > 0)
                      Text('Đã sử dụng $_pointsToDeduct điểm tích lũy để nhận chiết khấu.'),
                    TextField(
                      decoration: InputDecoration(labelText: 'Giảm giá (%)'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _discount = double.tryParse(value) ?? 0;
                          if (_discount > 0) _applyDiscount = true;
                          if (_discount == 0) _applyDiscount = false;
                        });
                      },
                      controller: TextEditingController(text: _discount > 0 ? _discount.toString() : ''),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(labelText: 'Phụ thu'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _additionalFee = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Tổng cộng
            Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng tiền:'),
                        Text('${NumberFormat('#,##0').format(totalAmount)}đ'),
                      ],
                    ),
                    if (_discount > 0) ...[
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Chiết khấu thành viên (${_discount.round()}%):'),
                          Text(
                            '-${NumberFormat('#,##0').format(totalAmount * _discount / 100)}đ',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                    if (_additionalFee > 0) ...[
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phụ thu:'),
                          Text('+${NumberFormat('#,##0').format(_additionalFee)}đ'),
                        ],
                      ),
                    ],
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Thành tiền:', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${NumberFormat('#,##0').format(totalAmount * (1 - _discount / 100) + _additionalFee)}đ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Điểm tích lũy:'),
                        Text(_discount > 0 ? '-$_pointsToDeduct điểm' : '+$points điểm', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Nút thanh toán
            Padding(
              padding: EdgeInsets.all(8),
              child: _buildSaveOrderButton(cartProvider, items, totalAmount, nhanVien),
            ),
          ],
        ),
      ),
    );
  }
}
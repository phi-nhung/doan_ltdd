/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/cart_provider.dart' as cart_provider;
import '../model/cart_item.dart';  
import '../database_helper.dart';

class CheckoutScreen extends StatefulWidget {
  final int? tableNumber;
  final VoidCallback onCheckout;

  const CheckoutScreen({
    super.key, 
    required this.tableNumber, 
    required this.onCheckout
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'Tiền mặt';
  double _discount = 0;
  double _additionalFee = 0;

  Future<void> _updateTableStatus(int tableNumber, String status) async {
    try {
      await DatabaseHelper.rawUpdate(
        '''
        UPDATE BAN
        SET TRANGTHAI = ?
        WHERE MABAN = ?
        ''',
        [status, tableNumber],
      );
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái bàn: $e');
    }
  }

  Future<void> _saveOrder(List<CartItem> items, double totalAmount) async {
    try {
      final now = DateTime.now();
      final orderSql = '''
        INSERT INTO HOADON 
        (NGAYTAO, TONGTIEN, HINHTHUCMUA, MABAN, MANV, GIO, DIEMCONG, GIAMGIA) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''';
      
      final orderId = await DatabaseHelper.rawInsert(
        orderSql,
        [
          now.toIso8601String(),
          totalAmount * (1 - _discount / 100) + _additionalFee,
          _selectedPaymentMethod,
          widget.tableNumber,
          1, // MANV mặc định
          '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
          0, // DIEMCONG mặc định
          _discount // Giảm giá phần trăm
        ]
      );

      // Thêm chi tiết hóa đơn và cập nhật kho
      for (var item in items) {
        await DatabaseHelper.rawInsert('''
          INSERT INTO CHITIETHOADON 
          (MAHD, MASANPHAM, SOLUONG, DONGIA, THANHTIEN, GHICHU)
          VALUES (?, ?, ?, ?, ?, ?)
        ''', [
          orderId, 
          item.item.id, 
          item.quantity, 
          item.item.price,
          item.item.price * item.quantity,
          'Đá: ${item.icePercentage}%, Đường: ${item.sugarPercentage}%'
        ]);

        // Cập nhật số lượng tồn
        await DatabaseHelper.rawUpdate('''
          UPDATE SANPHAM 
          SET SOLUONGTON = SOLUONGTON - ?,
              TRANGTHAI = CASE 
                WHEN (SOLUONGTON - ?) <= 0 THEN 'hết hàng'
                ELSE TRANGTHAI 
              END
          WHERE MASANPHAM = ?
        ''', [item.quantity, item.quantity, item.item.id]);
      }

      // Cập nhật trạng thái bàn
      if (widget.tableNumber != null) {
        await _updateTableStatus(widget.tableNumber!, 'Trống');
      }

    } catch (e) {
      throw Exception('Lỗi khi lưu hóa đơn: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<cart_provider.CartProvider>(context);
    final items = cartProvider.items;
    final totalAmount = cartProvider.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tableNumber != null ? 'Thanh toán - Bàn ${widget.tableNumber}' : 'Thanh toán'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết đơn hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.item.name),
                        subtitle: Text('Số lượng: ${item.quantity}'),
                        trailing: Text('${item.item.price} đ'),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng cộng:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('$totalAmount đ', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListTile(
                  title: const Text('Tiền mặt'),
                  leading: Radio<String>(
                    value: 'Tiền mặt',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Thẻ tín dụng'),
                  leading: Radio<String>(
                    value: 'Thẻ tín dụng',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                /* ElevatedButton(
                  onPressed: () {
                    _saveOrder(items, totalAmount).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đặt hàng thành công')),
                      );
                      widget.onCheckout();
                      Navigator.of(context).pop();
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đặt hàng thất bại: $error')),
                      );
                    });
                  },
                  child: const Text('Xác nhận đặt hàng'),
                ), */
              ],
            ),
          ),
          // Thêm phần giảm giá và phụ thu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Giảm giá (%)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _discount = double.tryParse(value) ?? 0;
                    });
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Phụ thu'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _additionalFee = double.tryParse(value) ?? 0;
                    });
                  },
                ),
                Text(
                  'Tổng tiền: ${totalAmount.toStringAsFixed(0)}đ',
                  style: TextStyle(fontSize: 16),
                ),
                if (_discount > 0)
                  Text(
                    'Giảm giá (${_discount.toStringAsFixed(0)}%): -${(totalAmount * _discount / 100).toStringAsFixed(0)}đ',
                    style: TextStyle(color: Colors.red),
                  ),
                if (_additionalFee > 0)
                  Text(
                    'Phụ thu: +${_additionalFee.toStringAsFixed(0)}đ',
                    style: TextStyle(color: Colors.blue),
                  ),
                Text(
                  'Thành tiền: ${(totalAmount * (1 - _discount / 100) + _additionalFee).toStringAsFixed(0)}đ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, List<CartItem> items, double totalAmount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn phương thức thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tiền mặt'),
              leading: Radio<String>(
                value: 'Tiền mặt',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                  Navigator.of(ctx).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('Thẻ tín dụng'),
              leading: Radio<String>(
                value: 'Thẻ tín dụng',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} */
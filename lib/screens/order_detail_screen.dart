import 'package:flutter/material.dart';
import 'package:doan/model/oder.dart';
import 'package:intl/intl.dart';
import 'package:doan/order_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  final int orderId;
  final OrderService _orderService = OrderService();

  OrderDetailScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng #${orderId}'),
      ),
      body: FutureBuilder<Order?>(
        future: _orderService.fetchOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Không tìm thấy đơn hàng.'));
          } else {
            final order = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Mã đơn hàng: ${order.mahd}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text('Mã khách hàng: ${order.makh}'),
                  Text('Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(order.ngaytao)}'),
                  Text('Tổng tiền: ${NumberFormat('#,##0').format(order.tongtien)}đ'),
                  Text('Hình thức mua: ${order.hinhthucmua}'),
                  Text('Điểm cộng: ${order.diemcong}'),
                  if (order.manv != null) Text('Mã nhân viên: ${order.manv}'),
                  if (order.maban != null) Text('Mã bàn: ${order.maban}'),
                  // Thêm thông tin chi tiết khác nếu cần
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
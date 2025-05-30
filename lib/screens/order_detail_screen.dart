import 'package:doan/invoice_exporter.dart';
import 'package:doan/model/orderItem.dart';
// Đổi import này thành tên file chứa OrderService của bạn, ví dụ:
// import 'package:doan/order_service.dart';
import 'package:doan/order_provider.dart'; // <--- Dựa vào tên file của bạn, có thể là order_service.dart
import 'package:flutter/material.dart';
import 'package:doan/model/oder.dart'; // New Order model (tên file là 'oder.dart' có thể là lỗi chính tả, nên là 'order.dart')
import 'package:intl/intl.dart'; // Import InvoiceExporter

class OrderDetailScreen extends StatelessWidget {
  final int orderId;
  // Đảm bảo OrderService được khởi tạo đúng cách
  final OrderService _orderService = OrderService();

  OrderDetailScreen({super.key, required this.orderId}); // Thêm key nếu cần

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng #${orderId}'),
        backgroundColor: const Color.fromARGB(255, 107, 66, 38), // Nâu mocha
        foregroundColor: Colors.white,
        actions: [
          // --- THÊM NÚT IN HÓA ĐƠN VÀO ĐÂY ---
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'In hóa đơn',
            onPressed: () async {
              // Khởi tạo InvoiceExporter
              final InvoiceExporter exporter = InvoiceExporter();
              try {
                // Gọi hàm xuất hóa đơn, truyền context và orderId
                await exporter.exportInvoiceToPdf(context, orderId);
                // Hiển thị thông báo thành công (tùy chọn)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang tạo và mở hóa đơn PDF...')),
                );
              } catch (e) {
                // Xử lý lỗi nếu có
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi in hóa đơn: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([
          _orderService.fetchOrderById(orderId),
          _orderService.fetchOrderItems(orderId),
        ]).then((results) {
          return {
            'order': results[0] as Order?, // Đảm bảo kiểu trả về khớp với fetchOrderById
            'items': results[1] as List<OrderItem>,
          };
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!['order'] == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng.'));
          } else {
            final order = snapshot.data!['order'] as Order;
            final orderItems = snapshot.data!['items'] as List<OrderItem>;

            // Xác định tên khách hàng hiển thị
            String customerDisplayName = 'Khách vãng lai';
            if (order.tenKhachHang != null && order.tenKhachHang!.isNotEmpty) {
              customerDisplayName = order.tenKhachHang!;
              if (order.sdt != null && order.sdt!.isNotEmpty) {
                customerDisplayName += ' - ${order.sdt!}';
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Mã đơn hàng: ${order.mahd ?? 'N/A'}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ngày lập: ${DateFormat('dd/MM/yyyy HH:mm').format(order.ngaytao)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Nhân viên lập: ${order.hoTenNhanVien ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Khách hàng: $customerDisplayName',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 5),
                  if (order.maban != null)
                    Text(
                      'Bàn: ${order.maban}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  const SizedBox(height: 20),

                  Text(
                    'Danh sách sản phẩm:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                  ),
                  const SizedBox(height: 10),
                  // Header cho danh sách sản phẩm
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.brown[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 4, child: Text('Tên món', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        Expanded(flex: 3, child: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Danh sách các món hàng
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orderItems.length,
                    itemBuilder: (context, index) {
                      final item = orderItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            Expanded(flex: 4, child: Text(item.tenMonAn)),
                            Expanded(flex: 2, child: Text('${item.soLuong}', textAlign: TextAlign.center)),
                            Expanded(flex: 3, child: Text('${NumberFormat('#,##0').format(item.donGia)}đ', textAlign: TextAlign.right)),
                            Expanded(flex: 3, child: Text('${NumberFormat('#,##0').format(item.soLuong * item.donGia)}đ', textAlign: TextAlign.right)),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(height: 30, thickness: 2, color: Colors.brown[300]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tổng tiền hóa đơn:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800])),
                      Text('${NumberFormat('#,##0').format(order.tongtien)}đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Hình thức mua: ${order.hinhthucmua}', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  Text('Điểm cộng: ${order.diemcong}', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
import 'package:doan/invoice_exporter.dart';
import 'package:doan/model/orderItem.dart';
import 'package:doan/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:doan/model/oder.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final int orderId;
  final OrderService _orderService = OrderService();

  OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng #$orderId'),
        backgroundColor: const Color.fromARGB(255, 107, 66, 38),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'In hóa đơn',
            onPressed: () async {
              final InvoiceExporter exporter = InvoiceExporter();
              try {
                await exporter.exportInvoiceToPdf(context, orderId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang tạo và mở hóa đơn PDF...')),
                );
              } catch (e) {
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
            'order': results[0] as Order?,
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

            final int tongTienGoc = orderItems.fold(0, (sum, item) => sum + (item.soLuong * item.donGia).toInt());
            final double giamGia = tongTienGoc - order.tongtien;

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
                      Text('Tổng tiền món ăn:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      Text('${NumberFormat('#,##0').format(tongTienGoc)}đ', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    ],
                  ),
                  if (giamGia > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Giảm giá:', style: TextStyle(fontSize: 16, color: Colors.red[700])),
                        Text('-${NumberFormat('#,##0').format(giamGia)}đ', style: TextStyle(fontSize: 16, color: Colors.red[700])),
                      ],
                    ),
                  const SizedBox(height: 10),
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

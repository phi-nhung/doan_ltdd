import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:doan/model/oder.dart'; 
import 'package:doan/model/orderItem.dart'; 
import 'package:doan/order_provider.dart'; 
import 'package:google_fonts/google_fonts.dart';

class InvoiceExporter {
  final OrderService _orderService = OrderService();

  Future<void> exportInvoiceToPdf(BuildContext context, int orderId) async {
    try {
      // 1. Lấy dữ liệu hóa đơn và chi tiết hóa đơn
      final order = await _orderService.fetchOrderById(orderId);
      final orderItems = await _orderService.fetchOrderItems(orderId);

      if (order == null) {
        // Hiển thị thông báo nếu không tìm thấy hóa đơn
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy hóa đơn #${orderId}')),
        );
        return;
      }

      if (orderItems.isEmpty) {
        // Hiển thị thông báo nếu không có chi tiết sản phẩm
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hóa đơn #${orderId} không có sản phẩm nào.')),
        );
        return;
      }

      // 2. Tạo tài liệu PDF
      final pdf = pw.Document();

      // Định dạng tiền tệ
      final currencyFormat = NumberFormat('#,##0', 'vi_VN');

      // Xác định tên khách hàng hiển thị
      String customerDisplayName = 'Khách vãng lai';
      if (order.tenKhachHang != null && order.tenKhachHang!.isNotEmpty) {
        customerDisplayName = order.tenKhachHang!;
        if (order.sdt != null && order.sdt!.isNotEmpty) {
          customerDisplayName += ' - ${order.sdt!}';
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Tiêu đề hóa đơn
              pw.Center(
                child: pw.Text(
                  'HÓA ĐƠN THANH TOÁN',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),

              // Thông tin cửa hàng/công ty (có thể tùy chỉnh)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Tên cửa hàng: Coffee Shop ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Địa chỉ: 123 Đường ABC, Quận 1, TP.HCM'),
                      pw.Text('Điện thoại: 0123 456 789'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Mã hóa đơn: #${order.mahd ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Ngày lập: ${DateFormat('dd/MM/yyyy HH:mm').format(order.ngaytao)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Thông tin khách hàng và nhân viên
              pw.Text('Thông tin khách hàng:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Tên khách hàng: $customerDisplayName'),
              pw.Text('Nhân viên lập: ${order.hoTenNhanVien ?? 'N/A'}'),
              if (order.maban != null) pw.Text('Số bàn: ${order.maban}'),
              pw.SizedBox(height: 20),

              // Bảng danh sách sản phẩm
              pw.Table.fromTextArray(
                headers: ['STT', 'Tên sản phẩm', 'Số lượng', 'Đơn giá', 'Thành tiền'],
                data: List<List<String>>.generate(
                  orderItems.length,
                  (index) {
                    final item = orderItems[index];
                    return [
                      (index + 1).toString(),
                      item.tenMonAn,
                      item.soLuong.toString(),
                      '${currencyFormat.format(item.donGia)}đ',
                      '${currencyFormat.format(item.soLuong * item.donGia)}đ',
                    ];
                  },
                ),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
              pw.SizedBox(height: 20),

              // Tổng kết hóa đơn
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Tổng cộng: ${currencyFormat.format(order.tongtien)}đ',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Giảm giá: ${currencyFormat.format(0)}đ', // Cần thêm logic giảm giá nếu có
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Phụ thu: ${currencyFormat.format(0)}đ', // Cần thêm logic phụ thu nếu có
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Divider(),
                    pw.Text(
                      'Thành tiền: ${currencyFormat.format(order.tongtien)}đ', // Tính toán lại nếu có giảm giá/phụ thu
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Hình thức mua: ${order.hinhthucmua}'),
                    pw.Text('Điểm tích lũy: +${order.diemcong} điểm'),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text('Cảm ơn quý khách đã sử dụng dịch vụ của chúng tôi!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ];
          },
        ),
      );

      // 3. Lưu file PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/hoa_don_${order.mahd}.pdf');
      await file.writeAsBytes(await pdf.save());

      // 4. Mở file PDF
      OpenFilex.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất hóa đơn #${order.mahd} thành công!')),
      );

    } catch (e) {
      print('Lỗi khi xuất hóa đơn PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xuất hóa đơn: ${e.toString()}')),
      );
    }
  }
}

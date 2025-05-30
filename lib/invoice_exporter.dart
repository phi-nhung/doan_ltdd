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

class InvoiceExporter {
  final OrderService _orderService = OrderService();

  static pw.Font? _vietnameseFontRegular;
  static pw.Font? _vietnameseFontBold;

  Future<void> _loadFonts() async {
    if (_vietnameseFontRegular == null || _vietnameseFontBold == null) {
      try {
        final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
        _vietnameseFontRegular = pw.Font.ttf(fontData);

        final fontBoldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
        _vietnameseFontBold = pw.Font.ttf(fontBoldData);
      } catch (e) {
        print('Lỗi khi tải phông chữ từ assets: $e');
        throw Exception('Không thể tải phông chữ cho PDF. Vui lòng kiểm tra assets/fonts và pubspec.yaml.');
      }
    }
  }

  Future<void> exportInvoiceToPdf(BuildContext context, int orderId) async {
    try {
      await _loadFonts();

      if (_vietnameseFontRegular == null || _vietnameseFontBold == null) {
        throw Exception('Phông chữ chưa được tải hoặc bị lỗi.');
      }

      final order = await _orderService.fetchOrderById(orderId);
      final orderItems = await _orderService.fetchOrderItems(orderId);

      if (order == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy hóa đơn #${orderId}')),
        );
        return;
      }

      if (orderItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hóa đơn #${orderId} không có sản phẩm nào.')),
        );
        return;
      }

      final pdf = pw.Document();

      final currencyFormat = NumberFormat('#,##0', 'vi_VN');

      String customerDisplayName = 'Khách vãng lai';
      if (order.tenKhachHang != null && order.tenKhachHang!.isNotEmpty) {
        customerDisplayName = order.tenKhachHang!;
        if (order.sdt != null && order.sdt!.isNotEmpty) {
          customerDisplayName += ' - ${order.sdt!}';
        }
      }

      // Tạo một ThemeData cơ bản, sau đó gọi copyWith trên nó
      final baseTheme = pw.ThemeData.base(); // Lấy theme cơ bản
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: baseTheme.copyWith( // <--- SỬA LỖI Ở ĐÂY
            defaultTextStyle: pw.TextStyle(font: _vietnameseFontRegular, fontSize: 10),
            // Các thuộc tính khác bạn muốn copyWith
          ),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'HÓA ĐƠN THANH TOÁN',
                  style: pw.TextStyle(font: _vietnameseFontBold, fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Tên cửa hàng: Coffee Shop ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: _vietnameseFontBold)),
                      pw.Text('Địa chỉ: 123 Đường ABC, Quận 1, TP.HCM', style: pw.TextStyle(font: _vietnameseFontRegular)),
                      pw.Text('Điện thoại: 0123 456 789', style: pw.TextStyle(font: _vietnameseFontRegular)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Mã hóa đơn: #${order.mahd ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: _vietnameseFontBold)),
                      pw.Text('Ngày lập: ${DateFormat('dd/MM/yyyy HH:mm').format(order.ngaytao)}', style: pw.TextStyle(font: _vietnameseFontRegular)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Text('Thông tin khách hàng:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: _vietnameseFontBold)),
              pw.Text('Tên khách hàng: $customerDisplayName', style: pw.TextStyle(font: _vietnameseFontRegular)),
              pw.Text('Nhân viên lập: ${order.hoTenNhanVien ?? 'N/A'}', style: pw.TextStyle(font: _vietnameseFontRegular)),
              if (order.maban != null) pw.Text('Số bàn: ${order.maban}', style: pw.TextStyle(font: _vietnameseFontRegular)),
              pw.SizedBox(height: 20),

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
                defaultColumnWidth: const pw.FlexColumnWidth(1.0),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(font: _vietnameseFontBold, fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
                cellStyle: pw.TextStyle(font: _vietnameseFontRegular),
              ),
              pw.SizedBox(height: 20),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Tổng cộng: ${currencyFormat.format(order.tongtien)}đ',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: _vietnameseFontBold),
                    ),
                    pw.Text(
                      'Giảm giá: ${currencyFormat.format(0)}đ',
                      style: pw.TextStyle(fontSize: 14, font: _vietnameseFontRegular),
                    ),
                    pw.Text(
                      'Phụ thu: ${currencyFormat.format(0)}đ',
                      style: pw.TextStyle(fontSize: 14, font: _vietnameseFontRegular),
                    ),
                    pw.Divider(),
                    pw.Text(
                      'Thành tiền: ${currencyFormat.format(order.tongtien)}đ',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red, font: _vietnameseFontBold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Hình thức mua: ${order.hinhthucmua}', style: pw.TextStyle(font: _vietnameseFontRegular)),
                    pw.Text('Điểm tích lũy: +${order.diemcong} điểm', style: pw.TextStyle(font: _vietnameseFontRegular)),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text('Cảm ơn quý khách đã sử dụng dịch vụ của chúng tôi!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, font: _vietnameseFontRegular)),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/hoa_don_${order.mahd}.pdf');
      await file.writeAsBytes(await pdf.save());

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
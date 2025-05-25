import 'dart:typed_data'; // For Uint8List if product image is used

class OrderItem {
  final int maChiTietHD;
  final int mahd;
  final int mamh;
  final int soLuong;
  final double donGia;
  final String tenMonAn; // Tên của sản phẩm
  final Uint8List? anhMonAn; // Ảnh của sản phẩm (nếu có)

  OrderItem({
    required this.maChiTietHD,
    required this.mahd,
    required this.mamh,
    required this.soLuong,
    required this.donGia,
    required this.tenMonAn,
    this.anhMonAn,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      maChiTietHD: map['MACHITIET'] as int,
      mahd: map['MAHD'] as int,
      mamh: map['MASP'] as int,
      soLuong: map['SOLUONG'] as int,
      donGia: (map['DONGIA'] as num).toDouble(),
      tenMonAn: map['TENSANPHAM'] as String,
      anhMonAn: map['HINHANH'] is Uint8List ? map['HINHANH'] as Uint8List : null,
    );
  }
}

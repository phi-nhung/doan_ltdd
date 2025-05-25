import 'package:flutter/foundation.dart';

class Order {
  final int? mahd;
  final DateTime ngaytao;
  final double tongtien;
  final int diemcong;
  final String hinhthucmua;
  final int makh;
  final int? manv;
  final int? maban;
  final String? sdt; // Đây là SDT của khách hàng

  final String? tenKhachHang;
  final String? hoTenNhanVien;
  final int? soBan;

  Order({
    this.mahd,
    required this.ngaytao,
    required this.tongtien,
    required this.diemcong,
    required this.hinhthucmua,
    required this.makh,
    this.manv,
    this.maban,
    this.tenKhachHang,
    this.hoTenNhanVien,
    this.soBan,
    this.sdt,
  });

  Map<String, dynamic> toMap() {
    return {
      'MAHD': mahd,
      'NGAYTAO': ngaytao.toIso8601String(),
      'TONGTIEN': tongtien,
      'DIEMCONG': diemcong,
      'HINHTHUCMUA': hinhthucmua,
      'MAKH': makh,
      'MANV': manv,
      'MABAN': maban,
      // SDT không phải là cột trực tiếp của HOADON, nó là từ JOIN
      // 'SDT': sdt,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      mahd: map['MAHD'] as int?,
      ngaytao: DateTime.parse(map['NGAYTAO'] as String),
      tongtien: (map['TONGTIEN'] as num?)?.toDouble() ?? 0.0,
      diemcong: map['DIEMCONG'] as int? ?? 0,
      hinhthucmua: map['HINHTHUCMUA'] as String? ?? '',
      makh: map['MAKH'] as int? ?? -1,
      manv: map['MANV'] as int?,
      maban: map['MABAN'] as int?,
      tenKhachHang: map['HOTEN'] as String?,
      hoTenNhanVien: map['HOTENNHANVIEN'] as String?,
      soBan: map['SOBAN'] as int?,
      sdt: map['SDT'] as String?, // Lấy từ alias SDTKH trong truy vấn SQL
    );
  }
}

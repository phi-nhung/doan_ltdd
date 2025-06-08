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
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
    return Order(
      mahd: parseInt(map['MAHD']),
      ngaytao: DateTime.parse(map['NGAYTAO'] as String),
      tongtien: (map['TONGTIEN'] as num?)?.toDouble() ?? 0.0,
      diemcong: parseInt(map['DIEMCONG']) ?? 0,
      hinhthucmua: map['HINHTHUCMUA'] as String? ?? '',
      makh: parseInt(map['MAKH']) ?? -1,
      manv: parseInt(map['MANV']),
      maban: parseInt(map['MABAN']),
      tenKhachHang: map['HOTEN'] as String?,
      hoTenNhanVien: map['HOTENNHANVIEN'] as String?,
      soBan: parseInt(map['SOBAN']),
      sdt: map['SDT'] as String?,
    );
  }
}
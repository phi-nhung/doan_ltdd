class Order {
  final int? mahd;
  final DateTime ngaytao;
  final double tongtien;
  final int diemcong;
  final String hinhthucmua;
  final int makh;
  final int? manv;
  final int? maban;
  final String? sdt;

  // Thông tin bổ sung từ khóa ngoại
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
      'SDT':sdt,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      mahd: map['MAHD'],
      ngaytao: DateTime.parse(map['NGAYTAO']),
      tongtien: map['TONGTIEN']?.toDouble() ?? 0.0,
      diemcong: map['DIEMCONG'],
      hinhthucmua: map['HINHTHUCMUA'],
      makh: map['MAKH'],
      manv: map['MANV'],
      maban: map['MABAN'],
      tenKhachHang: map['TENKHACHHANG'],
      hoTenNhanVien: map['HOTENNHANVIEN'],
      soBan: map['SOBAN'],
      sdt:map['SDT']
    );
  }
}

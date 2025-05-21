class NhanVien {
  final int maNhanVien;
  final String hoTen;
  final String chucVu;
  final String sdt;

  NhanVien({
    required this.maNhanVien,
    required this.hoTen,
    required this.chucVu,
    required this.sdt,
  });

  factory NhanVien.fromMap(Map<String, dynamic> map) {
    return NhanVien(
      maNhanVien: map['MANHANVIEN'],
      hoTen: map['HOTEN'],
      chucVu: map['CHUCVU'],
      sdt: map['SDT'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'MANHANVIEN': maNhanVien,
      'HOTEN': hoTen,
      'CHUCVU': chucVu,
      'SDT': sdt,
    };
  }
}

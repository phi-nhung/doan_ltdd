class NhanVien {
  final int maNhanVien;
  final String hoTen;
  final int maCV; // Đổi từ String chucVu sang int maCV
  final String sdt;

  NhanVien({
    required this.maNhanVien,
    required this.hoTen,
    required this.maCV,
    required this.sdt,
  });

  factory NhanVien.fromMap(Map<String, dynamic> map) {
    return NhanVien(
      maNhanVien: map['MANHANVIEN'],
      hoTen: map['HOTEN'],
      maCV: map['MACV'], // Đổi từ CHUCVU sang MACV
      sdt: map['SDT'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'MANHANVIEN': maNhanVien,
      'HOTEN': hoTen,
      'MACV': maCV, // Đổi từ CHUCVU sang MACV
      'SDT': sdt,
    };
  }
}

class TableModel {
  final int maban;
  final int soban;
  final String trangthai;

  TableModel({required this.maban, required this.soban, required this.trangthai});

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      maban: map['MABAN'],
      soban: map['SOBAN'],
      trangthai: map['TRANGTHAI'] ?? 'Trống',
    );
  }
}
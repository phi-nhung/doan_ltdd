import 'dart:typed_data';

class Item {
  final int id;
  final String name;
  final String unit;
  final double price;
  final int quantity;
  final String status;
  final Uint8List? image;
  final String category;
  final String description;

  Item({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
    required this.status,
    this.image,
    required this.category,
    this.description = '',
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['MASANPHAM'],
      name: map['TENSANPHAM'],
      unit: map['DONVITINH'] ?? '',
      price: (map['GIABAN'] is int) ? (map['GIABAN'] as int).toDouble() : (map['GIABAN'] as double),
      quantity: map['SOLUONGTON'] ?? 0,
      status: map['TRANGTHAI'] ?? '',
      image: map['HINHANH'],
      category: map['TENDANHMUC'] ?? '',
      description: '', // Nếu có cột mô tả thì lấy thêm
    );
  }
}


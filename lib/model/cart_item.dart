import '../model/item.dart';

class CartItem {
  final Item item;
  int quantity;
  final double icePercentage;
  final double sugarPercentage;
  final int? tableNumber;

  CartItem({
    required this.item,
    required this.quantity,
    this.icePercentage = 50,
    this.sugarPercentage = 50,
    this.tableNumber,
  });

  double get total => item.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'quantity': quantity,
      'icePercentage': icePercentage,
      'sugarPercentage': sugarPercentage,
      'tableNumber': tableNumber,
    };
  }
}
import '../model/item.dart';

class CartItem {
  final Item item;
  int quantity;
  final int? tableNumber;

  CartItem({
    required this.item,
    required this.quantity,
    this.tableNumber,
  });

  double get total => item.price * quantity;
}
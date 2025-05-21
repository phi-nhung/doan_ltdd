// Add your CartProvider class implementation here

import 'package:flutter/material.dart';
import '../model/item.dart';
import '../database_helper.dart';
class CartItem {
  final Item item;
  final double icePercentage;
  final double sugarPercentage;
  final int quantity;

  CartItem({
    required this.item,
    required this.icePercentage,
    required this.sugarPercentage,
    this.quantity = 1,
  });
}

class CartProvider with ChangeNotifier {
  List<CartItem> items = [];
  Map<int, List<CartItem>> tableItems = {};

  Future<bool> checkStock(Item item, int quantity) async {
    try {
      final result = await DatabaseHelper.rawQuery(
        'SELECT SOLUONGTON FROM SANPHAM WHERE MASANPHAM = ?',
        [item.id]
      );
      
      if (result.isNotEmpty) {
        final currentStock = result.first['SOLUONGTON'] as int;
        return currentStock >= quantity;
      }
      return false;
    } catch (e) {
      print('Lỗi kiểm tra tồn kho: $e');
      return false;
    }
  }

  void addToCart(Item item, double icePercentage, double sugarPercentage, {int? tableNumber}) {
    final cartItem = CartItem(
      item: item,
      icePercentage: icePercentage,
      sugarPercentage: sugarPercentage,
    );
    if (tableNumber != null) {
      tableItems.putIfAbsent(tableNumber, () => []);
      tableItems[tableNumber]!.add(cartItem);
    } else {
      items.add(cartItem);
    }
    notifyListeners();
  }

  void clearCart() {
    items.clear();
    notifyListeners();
  }

  void clearTableCart(int tableNumber) {
    tableItems.remove(tableNumber);
    notifyListeners();
  }

  double getTableTotalAmount(int tableNumber) {
    final tableCart = tableItems[tableNumber] ?? [];
    return tableCart.fold(0, (sum, item) => sum + (item.item.price * item.quantity));
  }

  // ... (other imports and code)

  double get totalAmount {
    double total = 0;
    for (var item in items) {
      total += item.item.price * item.quantity;
    }
    return total;
  }
  double totalAmountByTable(int tableNumber) {
    double total = 0;
    if (tableItems.containsKey(tableNumber)) {
      for (var item in tableItems[tableNumber]!) {
        total += item.item.price * item.quantity;
      }
    }
    return total;
  }
   void removeFromCart(CartItem item) {
    items.remove(item);
    notifyListeners();
  }
}
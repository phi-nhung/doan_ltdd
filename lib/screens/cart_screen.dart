import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/cart_provider.dart' as cart_provider;
import '../model/cart_item.dart';
import 'checkout_screen.dart';
import '../model/item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showEditQuantityDialog(BuildContext context, CartItem cartItem, cart_provider.CartProvider cart) {
    // Copy phần code _showEditQuantityDialog từ file cũ
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<cart_provider.CartProvider>(
      builder: (context, cart, child) {
        if (cart.items.isEmpty) {
          return Center(
            child: Text('Giỏ hàng trống'),
          );
        }

        return ListView.builder(
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            final item = cart.items[index];
            return Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: item.item.image != null
                    ? Image.memory(item.item.image!, width: 50, height: 50)
                    : Icon(Icons.image),
                title: Text(item.item.name),
                subtitle: Text(
                  'Số lượng: ${item.quantity} x ${item.item.price}đ\n'
                  'Đá: ${item.icePercentage}% | Đường: ${item.sugarPercentage}%'
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /* IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showEditQuantityDialog(context, item, cart),
                    ), */
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => cart.removeFromCart(item),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
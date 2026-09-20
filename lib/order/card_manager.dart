import 'package:flutter/foundation.dart';
import '../models/Product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartManager {

  static final List<CartItem> cartItems = [];

  static final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);


  static void addProduct(Product product, {int quantity = 1}) {
    final existingIndex = cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      cartItems[existingIndex].quantity += quantity;
    } else {

      cartItems.add(CartItem(product: product, quantity: quantity));
    }

    _updateCount();
  }

  static void updateQuantity(int index, int delta) {
    cartItems[index].quantity += delta;
    if (cartItems[index].quantity <= 0) {
      cartItems.removeAt(index);
    }
    _updateCount();
  }


  static void removeItem(int index) {
    cartItems.removeAt(index);
    _updateCount();
  }


  static void _updateCount() {
    cartItemCount.value = cartItems.length;
  }

  static void clearCart() {
    cartItems.clear();
    cartItemCount.value = 0;
  }
}
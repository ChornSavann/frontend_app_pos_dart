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

  static void addProduct(Product product) {
    final existingIndex = cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      cartItems[existingIndex].quantity += 1;
    } else {
      cartItems.add(CartItem(product: product, quantity: 1));
    }

    _updateCount();
  }

  static void updateQuantity(int index, int delta) {
    cartItems[index].quantity += delta;
    if (cartItems[index].quantity <= 0) {
      cartItems.removeAt(index); // បើថយដល់ 0 លុបចេញពី Cart តែម្ដង
    }
    _updateCount();
  }

  static void _updateCount() {
    // គណនាចំនួនសរុប (Total items count)
    int totalCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
    cartItemCount.value = totalCount;
  }

  static void clearCart() {
    cartItems.clear();
    cartItemCount.value = 0;
  }
}
import 'package:flutter/foundation.dart';
import '../models/Product.dart';

// ១. បង្កើត Class សម្រាប់កាន់កាប់ Product និង Quantity
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartManager {
  // ប្រើ CartItem ជំនួសឱ្យ Product ផ្ទាល់ ដើម្បីអាចគ្រប់គ្រង Qty បាន
  static final List<CartItem> cartItems = [];

  static final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);


  // static void addProduct(Product product) {
  //   final existingIndex = cartItems.indexWhere((item) => item.product.id == product.id);
  //
  //   if (existingIndex >= 0) {
  //     cartItems[existingIndex].quantity += 1;
  //   } else {
  //     cartItems.add(CartItem(product: product, quantity: 1));
  //   }
  //
  //   _updateCount();
  // }
  static void addProduct(Product product, {int quantity = 1}) {
    final existingIndex = cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      cartItems[existingIndex].quantity += quantity;
    } else {

      cartItems.add(CartItem(product: product, quantity: quantity));
    }

    _updateCount();
  }

  // ៣. មុខងារ Update Quantity (+/-)
  static void updateQuantity(int index, int delta) {
    cartItems[index].quantity += delta;
    if (cartItems[index].quantity <= 0) {
      cartItems.removeAt(index);
    }
    _updateCount();
  }

  // 🟢 មុខងារលុបទំនិញចេញទាំងស្រុងតាម index
  static void removeItem(int index) {
    cartItems.removeAt(index);
    _updateCount();
  }

  // static void _updateCount() {
  //   int totalCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
  //   cartItemCount.value = totalCount;
  // }
  static void _updateCount() {
    // រាប់យកតែចំនួន row ក្នុង Cart (លទ្ធផលគឺ 3)
    cartItemCount.value = cartItems.length;
  }

  // ៤. មុខងារ Clear Cart (សរសេរឱ្យត្រូវឈ្មោះ clearCart)
  static void clearCart() {
    cartItems.clear();
    cartItemCount.value = 0;
  }
}
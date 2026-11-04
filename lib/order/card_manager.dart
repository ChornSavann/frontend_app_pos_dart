import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';
import '../models/Product.dart';

class CartItem {
  final Product product;
  int quantity;
  double? alertQuantity;
  CartItem({required this.product, this.quantity = 1, this.alertQuantity});
}

class CartManager {
  static final List<CartItem> cartItems = [];

  static final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);

  // static void addProduct(Product product, {int quantity = 1}) {
  //   final existingIndex = cartItems.indexWhere((item) => item.product.id == product.id);
  //
  //   if (existingIndex >= 0) {
  //     cartItems[existingIndex].quantity += quantity;
  //   } else {
  //
  //     cartItems.add(CartItem(product: product, quantity: quantity));
  //   }
  //
  //   _updateCount();
  // }

  static void addProduct(
    BuildContext context,
    Product product, {
    int quantity = 1,
    double? promoPrice,
  }) {
    double currentStock = product.stockQuantity ?? 0.0;
    // double alertQty = product.alertQuantity ?? 0.0;
    double alertQty = 1;
    if (currentStock <= alertQty || currentStock < quantity) {
      AppSnackBar.showError(
        context,
        "ស្តុកសម្រាប់ ${product.name} អស់ ឬបានធ្លាក់ដល់កម្រិតកំណត់!",
      );
      return;
    }

    final existingIndex = cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      int totalNewQuantity = cartItems[existingIndex].quantity + quantity;
      if ((currentStock - totalNewQuantity) < alertQty) {
        AppSnackBar.showError(
          context,
          "មិនអាចបន្ថែមលើសពីកម្រិតស្តុកកំណត់បានទេ!",
        );
        return;
      }
      cartItems[existingIndex].quantity += quantity;
    } else {
      final effectivePrice = promoPrice ?? product.sellingPrice;
      Product itemProduct = product.copyWith(sellingPrice: effectivePrice);

      cartItems.add(CartItem(product: itemProduct, quantity: quantity));
    }

    _updateCount();
    AppSnackBar.showSuccess(
      context,
      "បានបន្ថែម ${product.name} (ចំនួន $quantity) ចូលកន្ត្រក!",
    );
  }


  static void updateQuantity(BuildContext context, int index, int delta) {
    if (delta < 0) {
      cartItems[index].quantity += delta;
      if (cartItems[index].quantity <= 0) {
        cartItems.removeAt(index);
      }
      _updateCount();
      return;
    }

    final item = cartItems[index];
    double currentStock = item.product.stockQuantity ?? 0.0;
    double alertQty = item.alertQuantity ?? 0.0;
    if (currentStock <= 5) {
      AppSnackBar.showError(
        context,
        "ស្តុកសម្រាប់ ${item.product.name} បានធ្លាក់ដល់កម្រិតកំណត់ (សល់តិចជាង ឬស្មើ 5)!",
      );
      return;
    }

    int newQuantity = item.quantity + delta;
    if ((currentStock - newQuantity) < alertQty || newQuantity > currentStock) {
      AppSnackBar.showError(context, "មិនអាចបន្ថែមលើសពីកម្រិតស្តុកកំណត់បានទេ!");
      return;
    }

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

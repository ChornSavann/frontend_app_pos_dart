import 'package:get/get.dart';
import 'package:pos_inventory/models/Product.dart';


class FavoriteController extends GetxController {
  var favoriteList = <Product>[].obs;

  void toggleFavorite(Product product) {
    if (favoriteList.any((p) => p.id == product.id)) {
      favoriteList.removeWhere((p) => p.id == product.id);
      product.isFavorite = false;

      Get.snackbar(
        "Removed",
        "${product.name} removed from favorites",
        snackPosition: SnackPosition.TOP,
      );
    } else {
      product.isFavorite = true;
      favoriteList.add(product);

      Get.snackbar(
        "Added",
        "${product.name} added to favorites",
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void clearAllFavorites() {
    for (var product in favoriteList) {
      product.isFavorite = false;
    }
    favoriteList.clear();
  }
}
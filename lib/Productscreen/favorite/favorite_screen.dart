import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/Productscreen/models/product_promotion_model.dart'; // 👈 នាំយក Promotion Model
import 'package:pos_inventory/Productscreen/show_product_screnn.dart';
import 'package:pos_inventory/api/promotion/api_promotion.dart'; // 👈 នាំយក Promotion API
import '../../msg/appSnackBar.dart';
import '../../order/card_manager.dart';
import 'controller/favoritecontroller.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final FavoriteController favController = Get.find();
  final ApiPromotion _apiPromotion = ApiPromotion();

  Map<int, ProductPromotionModel> _activePromotionsMap = {};
  bool _isLoadingPromo = true;

  @override
  void initState() {
    super.initState();
    _loadActivePromotions();
  }

  Future<void> _loadActivePromotions() async {
    try {
      final promotions = await _apiPromotion.fetchPromotions();
      if (mounted) {
        setState(() {
          // 🌟 ដកលក្ខខណ្ឌ quantity out ចោល ឱ្យវាបង្ហាញ Promotion ជានិច្ចទោះ quantity 0 ក៏ដោយ ឱ្យតែ isActive ជា true
          _activePromotionsMap = {
            for (var promo in promotions.where((p) => p.isActive))
              promo.productId: promo,
          };
          _isLoadingPromo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPromo = false);
      }
      debugPrint("Error loading promotions in favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Favorite Products',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          Obx(() {
            if (favController.favoriteList.isEmpty) {
              return const SizedBox.shrink();
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_sweep_rounded,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Clear All Favorites",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        content: const Text(
                          "Are you sure you want to remove all products from your favorites list? This action cannot be undone.",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              favController.clearAllFavorites();
                              Get.back();
                              AppSnackBar.showSuccess(
                                context,
                                "All favorites cleared!",
                              );
                            },
                            child: const Text(
                              "Yes, Clear",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade100, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.red,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Clear All",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (favController.favoriteList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 70,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No favorite products yet!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: favController.favoriteList.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final product = favController.favoriteList[index];

            // 🌟 ឆែករក Promotion របស់ Product នេះ
            final ProductPromotionModel? promo =
                _activePromotionsMap[product.id];

            double originalPrice = product.sellingPrice;
            double finalPrice = originalPrice;

            if (promo != null) {
              double discountAmount = promo.discountType == 'percentage'
                  ? (originalPrice * promo.discountValue) / 100
                  : promo.discountValue;
              finalPrice = (originalPrice - discountAmount).clamp(
                0.0,
                double.infinity,
              );
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: promo != null
                      ? const Color(0xFF14B8A6).withValues(alpha: 0.5)
                      : Colors.grey.shade100,
                  width: promo != null ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ShowProductScreen(productId: product.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // 🖼️ Product Image with Promotion Badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 65,
                              height: 65,
                              child:
                                  product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                    )
                                  : const Icon(
                                      Icons.shopping_bag_rounded,
                                      color: Color(0xFF0F766E),
                                    ),
                            ),
                          ),
                          if (promo != null)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  promo.discountType == 'percentage'
                                      ? "-${promo.discountValue}%"
                                      : "-\$${promo.discountValue}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // 📝 Product Name & Prices
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (promo != null) ...[
                                  Text(
                                    "\$${originalPrice.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  "\$${finalPrice.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Color(0xFF0F766E),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 🛒 Action Buttons (Add to Cart & Remove)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.add_shopping_cart,
                              color: Color(0xFF0F766E),
                            ),
                            onPressed: () {
                              // 🌟 ឆែកស្តុក Promotion ពេលចុចបន្ថែម (បើអស់ quantity ឱ្យលោត Error)
                              if (promo != null &&
                                  promo.quantity != null &&
                                  promo.quantity! <= 0) {
                                AppSnackBar.showError(
                                  context,
                                  "ស្តុកបញ្ចុះតម្លៃសម្រាប់ ${product.name} បានអស់ហើយ!",
                                );
                                return;
                              }
                              CartManager.addProduct(
                                context,
                                product,
                                promoPrice: promo != null ? finalPrice : null,
                              );
                            },
                            tooltip: "Add to Cart",
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              favController.toggleFavorite(product);
                            },
                            tooltip: "Remove",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

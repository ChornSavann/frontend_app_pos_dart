import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pos_inventory/Productscreen/models/product_model_banner.dart';
import 'package:pos_inventory/Productscreen/models/product_promotion_model.dart';
import 'package:pos_inventory/Productscreen/show_product_screnn.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/api/promotion/api_promotion.dart';

class BannerProductScreen extends StatefulWidget {
  final int? categoryId;
  const BannerProductScreen({super.key, this.categoryId});

  @override
  State<BannerProductScreen> createState() => _BannerProductScreenState();
}

class _BannerProductScreenState extends State<BannerProductScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  final ApiProduct _apiProductService = ApiProduct();
  final ApiPromotion _apiPromotion = ApiPromotion();

  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  @override
  void didUpdateWidget(covariant BannerProductScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      setState(() {
        _dataFuture = _fetchData();
      });
    }
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final results = await Future.wait([
        _apiProductService.fetchProductsandcategory(
          categoryId: widget.categoryId,
        ),
        _apiPromotion.fetchPromotions(),
      ]);

      final allProducts = results[0] as List<ProductModelBanner>;
      final promotions = results[1] as List<ProductPromotionModel>;

      final filteredProducts = allProducts.where((product) {
        final stock =
            num.tryParse((product.stockQuantity ?? '0').toString()) ?? 0;
        final alertQty = product.alertQuantity ?? 5;
        return stock >= alertQty;
      }).toList();

      final Map<int, ProductPromotionModel> promoMap = {
        for (var promo in promotions.where((p) => p.isActive))
          promo.productId: promo,
      };

      return {'products': filteredProducts, 'promotions': promoMap};
    } catch (e) {
      debugPrint("Error fetching banner data: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || (snapshot.data!['products'] as List).isEmpty) {
          return const SizedBox(
            height: 140,
            child: Center(
              child: Text(
                "មិនមានទិន្នន័យផលិតផលសម្រាប់ Banner ទេ",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          );
        }

        final products = snapshot.data!['products'] as List<ProductModelBanner>;
        final promoMap =
            snapshot.data!['promotions'] as Map<int, ProductPromotionModel>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              carouselController: _controller,
              options: CarouselOptions(
                height: 215.0,
                autoPlay: true,
                enlargeCenterPage: false,
                viewportFraction: 0.92,
                aspectRatio: 16 / 9,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: products.map((product) {
                final ProductPromotionModel? promo = promoMap[product.id];

                double originalPrice =
                    num.tryParse(
                      (product.sellingPrice ?? '0').toString(),
                    )?.toDouble() ??
                    0.0;
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

                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0F766E,
                            ).withValues(alpha: 0.12),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShowProductScreen(
                                    productId: product.id ?? 0,
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.05),
                                        Colors.black.withValues(alpha: 0.45),
                                        Colors.black.withValues(alpha: 0.88),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),

                                Positioned(
                                  top: 14,
                                  left: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: promo != null
                                          ? Colors.deepOrange
                                          : const Color(0xFF0F766E),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          promo != null
                                              ? Icons.local_offer_rounded
                                              : Icons
                                                    .local_fire_department_rounded,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          promo != null
                                              ? (promo.discountType ==
                                                        'percentage'
                                                    ? "-${promo.discountValue}% OFF"
                                                    : "-\$${promo.discountValue} OFF")
                                              : "SPECIAL OFFER",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Positioned(
                                  bottom: 14,
                                  left: 14,
                                  right: 14,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              product.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              promo?.title ??
                                                  product.description,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.85,
                                                ),
                                                fontSize: 11.5,
                                                height: 1.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (promo != null &&
                                                originalPrice > 0) ...[
                                              Text(
                                                "\$${originalPrice.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  color: Colors.grey.shade300,
                                                  fontSize: 10.5,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                            Text(
                                              "\$${finalPrice.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.amberAccent,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                products.length > 8 ? 8 : products.length,
                (index) {
                  int activeIndex =
                      _currentIndex %
                      (products.length > 8 ? 8 : products.length);
                  bool isSelected = activeIndex == index;

                  return GestureDetector(
                    onTap: () {
                      int targetPage =
                          (index *
                                  (products.length /
                                      (products.length > 8
                                          ? 8
                                          : products.length)))
                              .floor();
                      _controller.animateToPage(targetPage);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isSelected ? 22.0 : 6.0,
                      height: 6.0,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: isSelected
                            ? const Color(0xFF0F766E)
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

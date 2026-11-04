import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pos_inventory/Productscreen/show_product_screnn.dart';
import 'dart:ui';

class AutoPlayBanner extends StatefulWidget {
  const AutoPlayBanner({super.key});

  @override
  State<AutoPlayBanner> createState() => _AutoPlayBannerState();
}

class _AutoPlayBannerState extends State<AutoPlayBanner> {
  final ApiProduct apiProduct = ApiProduct();

  List<dynamic> _banners = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      setState(() => _isLoading = true);
      final data = await apiProduct.fetchProducts();
      final filteredData = data.where((product) {
        final stock =
            num.tryParse((product.stockQuantity ?? 0).toString()) ?? 0;
        return stock >= 10;
      }).toList();

      setState(() {
        _banners = filteredData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching banners: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌙 Light / dark colors
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color placeholderColor = isDark
        ? const Color(0xFF1E2740)
        : Colors.grey.shade100;
    final Color errorColor = isDark
        ? const Color(0xFF1E2740)
        : Colors.grey.shade200;
    final Color accent = isDark
        ? const Color(0xFF6366F1)
        : const Color(0xFF4F46E5);
    final Color inactiveDot = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.grey.shade300;

    if (_isLoading) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: placeholderColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: accent),
        ),
      );
    }

    // បើគ្មានទិន្នន័យ ឬចំនួនតិចជាង 10 គឺវាមិនបង្ហាញអ្វីទាំងអស់ (SizedBox.shrink)
    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.99,
            aspectRatio: 16 / 9,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 900),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: _banners.map((product) {
            final String title = product.name;
            final String subtitle =
                product.description ?? 'ផលិតផលថ្មីប្រចាំហាង លក់ដាច់ខ្លាំង ✨';
            final String price = product.sellingPrice != null
                ? "\$${product.sellingPrice.toStringAsFixed(2)}"
                : "";

            String imageUrl = '';
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
              imageUrl = product.imageUrl!;
            }

            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ShowProductScreen(productId: product.id),
                      ),
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.08 : 0.0,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.35)
                              : Colors.indigo.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          imageUrl.isNotEmpty
                              ? Container(
                            color: Colors.grey.shade900,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: placeholderColor,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  Container(
                                    color: errorColor,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          )
                              : Container(
                            color: const Color(
                              0xFF4F46E5,
                            ).withValues(alpha: isDark ? 0.18 : 0.1),
                            child: Icon(
                              Icons.shopping_bag,
                              size: 50,
                              color: accent,
                            ),
                          ),

                          // 🌑 Premium gradient overlay (clear on top, dark at bottom)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.black.withValues(alpha: 0.88),
                                ],
                                stops: const [0.0, 0.3, 0.68, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),

                          // 🏷️ Glassmorphism category badge
                          Positioned(
                            top: 12,
                            left: 14,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 8.0,
                                  sigmaY: 8.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome,
                                        color: Colors.amberAccent,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (product.categoryName ??
                                            product.brandName ??
                                            'FEATURED')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 💰 Price tag (gradient pill)
                          if (price.isNotEmpty)
                            Positioned(
                              top: 12,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4F46E5),
                                      Color(0xFF6366F1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  price,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),

                          // 📝 Title & Subtitle
                          Positioned(
                            bottom: 14,
                            left: 16,
                            right: 56,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ➡️ Small glass arrow button (the whole banner is tappable)
                          Positioned(
                            bottom: 14,
                            right: 14,
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 8.0,
                                  sigmaY: 8.0,
                                ),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // 🔘 Modern indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
            bool isActive = _currentIndex == entry.key;
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 22.0 : 6.0,
                height: 6.0,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive ? accent : inactiveDot,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
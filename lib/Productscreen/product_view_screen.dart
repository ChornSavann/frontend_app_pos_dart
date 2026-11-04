import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/Productscreen/banner_product_screen.dart';
import 'package:pos_inventory/Productscreen/models/product_promotion_model.dart';
import 'package:pos_inventory/Productscreen/show_product_screnn.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/api/promotion/api_promotion.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';
import 'package:pos_inventory/partail/button_screen.dart';
import '../models/Product.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../order/card_manager.dart';
import '../order/cart_screen.dart';
import '../partail/app_bar_screen.dart';
import 'favorite/controller/favoritecontroller.dart';
import 'favorite/favorite_screen.dart';

class ProductViewScreen extends StatefulWidget {
  const ProductViewScreen({super.key});

  @override
  State<ProductViewScreen> createState() => _ProductViewScreenState();
}

class _ProductViewScreenState extends State<ProductViewScreen> {
  final FavoriteController favController = Get.put(FavoriteController());

  ApiProduct apiProduct = ApiProduct();
  final ApiPromotion _apiPromotion = ApiPromotion();

  late Future<List<Product>> _futureProducts;
  late Future<List<CategoryModel>> _fetchCategories;
  late Future<List<BrandModel>> _fetchBrands;

  Map<int, ProductPromotionModel> _activePromotionsMap = {};

  int _selectedCategoryId = 0;
  int _selectedBrandId = 0;

  bool _isAllCategoriesExpanded = false;
  bool _isAllBrandsExpanded = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _refreshProductList();
    _loadActivePromotions();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivePromotions() async {
    try {
      final promotions = await _apiPromotion.fetchPromotions();
      final now = DateTime.now();

      if (mounted) {
        setState(() {
          _activePromotionsMap = {
            for (var promo in promotions.where((p) {
              bool isActive = p.isActive;
              bool isNotExpired = true;
              if (p.endDate != null && p.endDate!.isNotEmpty) {
                try {
                  DateTime parsedEndDate = DateTime.parse(p.endDate!);
                  isNotExpired = parsedEndDate.isAfter(now);
                } catch (e) {
                  debugPrint("Error parsing date: $e");
                }
              }
              return isActive && isNotExpired;
            }))
              int.parse(promo.productId.toString()): promo,
          };
        });
      }
    } catch (e) {
      debugPrint("Error loading promotions: $e");
    }
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      },
    );
  }

  void _refreshProductList() {
    setState(() {
      _futureProducts = apiProduct.fetchProducts();
      _fetchCategories = apiProduct.fetchCategories();
      _fetchBrands = apiProduct.fetchBrands();
      _loadActivePromotions();
    });
  }

  void _navigateToFavoriteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoriteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌙 NEW: dark mode colors (only colors changed, nothing else)
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF151C2E) : Colors.white;
    final Color titleColor = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final Color tealText = isDark
        ? const Color(0xFF2DD4BF)
        : const Color(0xFF0F766E);
    final Color cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF8F9FA),
      appBar: AppBarScreen(onFavoriteTap: _navigateToFavoriteScreen),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 Search Bar Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: TextStyle(fontSize: 14, color: titleColor),
                decoration: InputDecoration(
                  hintText: "Search products...",
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF0F766E),
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Colors.grey,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cardBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF0F766E),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 🔄 Main Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              children: [
                // 🌟 Banner Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 240,
                      child: BannerProductScreen(
                        categoryId: _selectedCategoryId,
                      ),
                    ),
                  ),
                ),

                // 📌 Categories Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Categories",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : Colors.black87,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isAllCategoriesExpanded =
                                !_isAllCategoriesExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            _isAllCategoriesExpanded ? "Show Less" : "View All",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🏷️ Category Selector (Animated CrossFade)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: _isAllCategoriesExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: SizedBox(
                    height: 90,
                    child: FutureBuilder<List<CategoryModel>>(
                      future: _fetchCategories,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return const Center(
                            child: Text("Error loading categories"),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text("No categories found"),
                          );
                        }

                        final categories = snapshot.data!;
                        final filteredCategories = categories.where((cat) {
                          return cat.productsCount > 0;
                        }).toList();

                        final allCategories = [
                          CategoryModel(
                            id: 0,
                            name: "All",
                            iconName: "grid_view",
                            image: '',
                            productsCount: 1,
                          ),
                          ...filteredCategories,
                        ];

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          itemCount: allCategories.length,
                          itemBuilder: (context, index) {
                            final cat = allCategories[index];
                            final isSelected = cat.id == _selectedCategoryId;
                            return _buildCategoryItem(cat, isSelected);
                          },
                        );
                      },
                    ),
                  ),
                  secondChild: FutureBuilder<List<CategoryModel>>(
                    future: _fetchCategories,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final categories = snapshot.data!;
                      final filteredCategories = categories.where((cat) {
                        return cat.productsCount > 0;
                      }).toList();

                      final allCategories = [
                        CategoryModel(
                          id: 0,
                          name: "All",
                          iconName: "grid_view",
                          image: '',
                          productsCount: 1,
                        ),
                        ...filteredCategories,
                      ];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.82,
                              ),
                          itemCount: allCategories.length,
                          itemBuilder: (context, index) {
                            final cat = allCategories[index];
                            final isSelected = cat.id == _selectedCategoryId;
                            return _buildCategoryItem(cat, isSelected);
                          },
                        ),
                      );
                    },
                  ),
                ),

                // 📌 Brands Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Brands",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : Colors.black87,
                        ),
                      ),
                      // 🌟 ពេលចុច View All របស់ Brands ឱ្យវាបើក/បិទ Grid View ទាំងអស់នៅនឹងកន្លែង
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isAllBrandsExpanded = !_isAllBrandsExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            _isAllBrandsExpanded ? "Show Less" : "View All",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🏷️ Brand Selector (Animated CrossFade)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: _isAllBrandsExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,

                  // 1️⃣ បង្ហាញជា ListView ផ្ដេកធម្មតា
                  firstChild: SizedBox(
                    height: 90,
                    child: FutureBuilder<List<BrandModel>>(
                      future: _fetchBrands,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return const Center(
                            child: Text("Error loading brands"),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text("No brands found"));
                        }

                        final brands = snapshot.data!;
                        final filteredbrands = brands.where((brandid) {
                          return brandid.productCount > 0;
                        }).toList();

                        final allBrands = [
                          BrandModel(
                            id: 0,
                            name: "All",
                            iconName: "grid_view",
                            logo: '',
                            productCount: 1,
                            slug: '',
                          ),
                          ...filteredbrands,
                        ];

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          itemCount: allBrands.length,
                          itemBuilder: (context, index) {
                            final brand = allBrands[index];
                            final isSelected = brand.id == _selectedBrandId;
                            return _buildBrandItem(brand, isSelected);
                          },
                        );
                      },
                    ),
                  ),

                  // 2️⃣ បង្ហាញជា GridView ទាំងអស់ពេលចុច View All របស់ Brands
                  secondChild: FutureBuilder<List<BrandModel>>(
                    future: _fetchBrands,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final brands = snapshot.data!;
                      final filteredbrands = brands.where((brandid) {
                        return brandid.productCount > 0;
                      }).toList();

                      final allBrands = [
                        BrandModel(
                          id: 0,
                          name: "All",
                          iconName: "grid_view",
                          logo: '',
                          productCount: 1,
                          slug: '',
                        ),
                        ...filteredbrands,
                      ];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.82,
                              ),
                          itemCount: allBrands.length,
                          itemBuilder: (context, index) {
                            final brand = allBrands[index];
                            final isSelected = brand.id == _selectedBrandId;
                            return _buildBrandItem(brand, isSelected);
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // 🛍️ Product Grid View (Responsive Setup)
                FutureBuilder<List<Product>>(
                  future: _futureProducts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: Text("No products found.")),
                      );
                    } else {
                      final allProducts = snapshot.data!;

                      final products = allProducts.where((product) {
                        bool matchesSearch = product.name
                            .toLowerCase()
                            .contains(_searchQuery);
                        bool hasEnoughStock =
                            product.stockQuantity >=
                            (product.alertQuantity ?? 10.0);
                        return matchesSearch && hasEnoughStock;
                      }).toList();

                      if (products.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Text(
                              "No matching products found.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 600
                              ? 3
                              : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.65,
                                ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              bool isAvailableToSell =
                                  (product.stockQuantity ?? 0) >=
                                  (product.alertQuantity ?? 0);

                              final ProductPromotionModel? promo =
                                  _activePromotionsMap[product.id];

                              double originalPrice = product.sellingPrice;
                              double finalPrice = originalPrice;

                              if (promo != null) {
                                double discountAmount =
                                    promo.discountType == 'percentage'
                                    ? (originalPrice * promo.discountValue) /
                                          100
                                    : promo.discountValue;
                                finalPrice = (originalPrice - discountAmount)
                                    .clamp(0.0, double.infinity);
                              }

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ShowProductScreen(
                                        productId: product.id,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: promo != null
                                          ? const Color(
                                              0xFF14B8A6,
                                            ).withValues(alpha: 0.5)
                                          : cardBorder,
                                      width: promo != null ? 1.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            height: 135,
                                            width: double.infinity,
                                            margin: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1E2740)
                                                  : const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child:
                                                  product.imageUrl != null &&
                                                      product
                                                          .imageUrl!
                                                          .isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl:
                                                          product.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => const Center(
                                                            child: SizedBox(
                                                              width: 15,
                                                              height: 15,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            ),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 35,
                                                            color: Colors.grey,
                                                          ),
                                                    )
                                                  : const Center(
                                                      child: Icon(
                                                        Icons
                                                            .shopping_bag_rounded,
                                                        size: 35,
                                                        color: Color(
                                                          0xFF0F766E,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),

                                          if (promo != null)
                                            Positioned(
                                              top: 14,
                                              left: 14,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.deepOrange,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  promo.discountType ==
                                                          'percentage'
                                                      ? "-${promo.discountValue}%"
                                                      : "-\$${promo.discountValue}",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),

                                          Positioned(
                                            top: 14,
                                            right: 14,
                                            child: Obx(() {
                                              bool isFavorite = favController
                                                  .favoriteList
                                                  .any(
                                                    (p) => p.id == product.id,
                                                  );

                                              return InkWell(
                                                onTap: () {
                                                  favController.toggleFavorite(
                                                    product,
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.9),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.06,
                                                            ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    isFavorite
                                                        ? Icons.favorite_rounded
                                                        : Icons
                                                              .favorite_border_rounded,
                                                    size: 16,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),

                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            0,
                                            12,
                                            10,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: titleColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star_rounded,
                                                        size: 13,
                                                        color: Colors.amber,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        "4.8",
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFFCBD5E1,
                                                                )
                                                              : const Color(
                                                                  0xFF334155,
                                                                ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "(${product.stockQuantity.toInt()})",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    promo?.title ??
                                                        product.description ??
                                                        "Fresh & Delicious",
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      color: promo != null
                                                          ? tealText
                                                          : Colors.grey[400],
                                                      fontWeight: promo != null
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (promo != null)
                                                          Text(
                                                            "\$${originalPrice.toStringAsFixed(2)}",
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey
                                                                  .shade400,
                                                              fontSize: 10.5,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                            ),
                                                          ),
                                                        Text(
                                                          "\$${finalPrice.toStringAsFixed(2)}",
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color: tealText,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 32,
                                                    width: 32,
                                                    child: ElevatedButton(
                                                      onPressed:
                                                          isAvailableToSell
                                                          ? () {
                                                              // ❌ លុបលក្ខខណ្ឌឆែក quantity <= 0 ចេញ ដើម្បីឱ្យទោះបីជាសល់ 0 ក៏អាច add បាន

                                                              double
                                                              originalPrice =
                                                                  product
                                                                      .sellingPrice;
                                                              double
                                                              finalPrice =
                                                                  originalPrice;

                                                              if (promo !=
                                                                  null) {
                                                                double
                                                                discountAmount =
                                                                    promo.discountType ==
                                                                        'percentage'
                                                                    ? (originalPrice *
                                                                              promo.discountValue) /
                                                                          100
                                                                    : promo
                                                                          .discountValue;
                                                                finalPrice =
                                                                    (originalPrice -
                                                                            discountAmount)
                                                                        .clamp(
                                                                          0.0,
                                                                          double
                                                                              .infinity,
                                                                        );
                                                              }

                                                              CartManager.addProduct(
                                                                context,
                                                                product,
                                                                promoPrice:
                                                                    promo !=
                                                                        null
                                                                    ? finalPrice
                                                                    : null,
                                                              );
                                                            }
                                                          : null,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF0F766E,
                                                            ),
                                                        disabledBackgroundColor:
                                                            isDark
                                                            ? const Color(
                                                                0xFF334155,
                                                              )
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.zero,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                50,
                                                              ),
                                                        ),
                                                        elevation: 0,
                                                      ),
                                                      child: const Icon(
                                                        Icons.add_rounded,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
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
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: const ButtonScreen(currentIndex: 1),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 15),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 2.0,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.shopping_cart_rounded,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCategoryItem(CategoryModel cat, bool isSelected) {
    // 🌙 NEW: dark mode colors
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color normalColor = isDark ? const Color(0xFFE2E8F0) : Colors.black87;

    final String? imageUrl = cat.imageUrl;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = cat.id;
          if (cat.id == 0) {
            _futureProducts = apiProduct.fetchProducts();
          } else {
            _futureProducts = apiProduct.fetchProducts(categoryId: cat.id);
          }
        });
      },
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? Colors.amber.withValues(alpha: 0.18)
                          : Colors.amber.shade50)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: cat.name == "All"
                    ? Icon(
                        Icons.grid_view_rounded,
                        size: 26,
                        color: isSelected ? Colors.amber[800] : normalColor,
                      )
                    : (imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.network(
                                imageUrl,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.fastfood_rounded,
                                      size: 24,
                                      color: isSelected
                                          ? Colors.amber[800]
                                          : normalColor,
                                    ),
                              ),
                            )
                          : Icon(
                              Icons.fastfood_rounded,
                              size: 24,
                              color: isSelected
                                  ? Colors.amber[800]
                                  : normalColor,
                            )),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.amber[800] : normalColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandItem(BrandModel brand, bool isSelected) {
    // 🌙 NEW: dark mode colors
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color normalColor = isDark ? const Color(0xFFE2E8F0) : Colors.black87;

    final String? imageUrl = brand.logo;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBrandId = brand.id!;
          if (brand.id == 0) {
            _futureProducts = apiProduct.fetchProducts();
          } else {
            _futureProducts = apiProduct.fetchProducts(brandId: brand.id);
          }
        });
      },
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? Colors.amber.withValues(alpha: 0.18)
                          : Colors.amber.shade50)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: brand.name == "All"
                    ? Icon(
                        Icons.grid_view_rounded,
                        size: 26,
                        color: isSelected ? Colors.amber[800] : normalColor,
                      )
                    : (imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.network(
                                imageUrl,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.branding_watermark_rounded,
                                      size: 24,
                                      color: isSelected
                                          ? Colors.amber[800]
                                          : normalColor,
                                    ),
                              ),
                            )
                          : Icon(
                              Icons.branding_watermark_rounded,
                              size: 24,
                              color: isSelected
                                  ? Colors.amber[800]
                                  : normalColor,
                            )),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              brand.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.amber[800] : normalColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

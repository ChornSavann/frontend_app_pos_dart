import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pos_inventory/Productscreen/banner_product_screen.dart';
import 'package:pos_inventory/Productscreen/show_product_id_screen.dart';
import 'package:pos_inventory/Productscreen/show_product_screnn.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/partail/button_screen.dart';

import '../api/api_brand.dart';
import '../constants/baseurl/base_url_api.dart';
import '../models/Product.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../order/card_manager.dart';
import '../order/cart_screen.dart';
import '../partail/app_bar_screen.dart';

class ProductViewScreen extends StatefulWidget {
  const ProductViewScreen({super.key});

  @override
  State<ProductViewScreen> createState() => _ProductViewScreenState();
}

class _ProductViewScreenState extends State<ProductViewScreen> {
  ApiProduct apiProduct = ApiProduct();
  late Future<List<Product>> _futureProducts;
  late Future<List<CategoryModel>> _fetchCategories;
  late Future<List<BrandModel>> _fetchBrands;
  int _selectedCategoryId = 0;
  int _selectedBrandId = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _refreshProductList();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void showTopSnackBar(BuildContext context, String productName) {
    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -60.0, end: 0.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Added $productName to Cart",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
       appBar: const AppBarScreen(),
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
                    color: Colors.black.withOpacity(0.04),
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
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: "Search products...",
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
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
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none, // គ្មានខ្សែកត់ក្រៅពេលធម្មតា
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade100,
                      width: 1,
                    ),
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

          const SizedBox(height: 10),

          // 🔄 2. ផ្នែកខាងក្រោមនេះ (Banner+Categories + Brands + Product Grid) អាច Scroll បានទាំងអស់គ្នា
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              children: [
                // 🌟 1. Banner Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 268,
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
                    children: const [
                      Text(
                        "Categories",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "View All",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🏷️ Category Selector (Horizontal List)
                SizedBox(
                  height: 90,
                  child: FutureBuilder<List<CategoryModel>>(
                    future: _fetchCategories,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading categories"),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No categories found"));
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
                          // 🟢 ប្រើប្រាស់ imageUrl ដែលបានទាញយកមកពី Laravel Accessor ស្រាប់ (សុវត្ថិភាពពេល Hosting)
                          final String? imageUrl = cat.image;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = cat.id;
                                if (cat.id == 0) {
                                  _futureProducts = apiProduct.fetchProducts();
                                } else {
                                  _futureProducts = apiProduct.fetchProducts(
                                    categoryId: cat.id,
                                  );
                                }
                              });
                            },
                            child: Container(
                              width: 76,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.amber.shade50
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: cat.name == "All"
                                          ? Icon(
                                              Icons.grid_view_rounded,
                                              size: 26,
                                              color: isSelected
                                                  ? Colors.amber[800]
                                                  : Colors.black87,
                                            )
                                          : (imageUrl != null &&
                                                    imageUrl.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          100,
                                                        ),
                                                    child: Image.network(
                                                      imageUrl, // 🟢 ដាក់ Full URL ចូលផ្ទាល់
                                                      width: 38,
                                                      height: 38,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Icon(
                                                            Icons
                                                                .fastfood_rounded,
                                                            size: 24,
                                                            color: isSelected
                                                                ? Colors
                                                                      .amber[800]
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.fastfood_rounded,
                                                    size: 24,
                                                    color: isSelected
                                                        ? Colors.amber[800]
                                                        : Colors.black87,
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
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.amber[800]
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // 📌 Brands Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Brands",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "View All",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🏷️ Brand Selector (Horizontal List)
                // 🏷️ Brand Selector (Horizontal List)
                SizedBox(
                  height: 90,
                  child: FutureBuilder<List<BrandModel>>(
                    future: _fetchBrands,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading brands"),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                          // 🟢 ប្រើប្រាស់ logoUrl ដែលបានទាញយកមកពី Laravel Accessor ស្រាប់ (សុវត្ថិភាពពេល Hosting)
                          final String? imageUrl = brand.logo;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedBrandId = brand.id!;
                                if (brand.id == 0) {
                                  _futureProducts = apiProduct.fetchProducts();
                                } else {
                                  _futureProducts = apiProduct.fetchProducts(
                                    brandId: brand.id,
                                  );
                                }
                              });
                            },
                            child: Container(
                              width: 76,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.amber.shade50
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: brand.name == "All"
                                          ? Icon(
                                        Icons.grid_view_rounded,
                                        size: 26,
                                        color: isSelected
                                            ? Colors.amber[800]
                                            : Colors.black87,
                                      )
                                          : (imageUrl != null && imageUrl.isNotEmpty
                                          ? ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(
                                          100,
                                        ),
                                        child: Image.network(
                                          imageUrl, // 🟢 ដាក់ Full URL ចូលផ្ទាល់
                                          width: 38,
                                          height: 38,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                              context,
                                              error,
                                              stackTrace,
                                              ) => Icon(
                                            Icons
                                                .branding_watermark_rounded,
                                            size: 24,
                                            color: isSelected
                                                ? Colors
                                                .amber[800]
                                                : Colors
                                                .black87,
                                          ),
                                        ),
                                      )
                                          : Icon(
                                        Icons
                                            .branding_watermark_rounded,
                                        size: 24,
                                        color: isSelected
                                            ? Colors.amber[800]
                                            : Colors.black87,
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
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.amber[800]
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // 🛍️ Product Grid View
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
                        return product.name.toLowerCase().contains(
                          _searchQuery,
                        );
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

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio:
                                  0.75,
                            ),
                        itemBuilder: (context, index) {
                          final product = products[index];

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ShowProductScreen(productId: product.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🖼️ Product Image Section (កំណត់កម្ពស់ថេរ 130 ឱ្យរូបភាពពេញស្អាត)
                                  Stack(
                                    children: [
                                      Container(
                                        height:
                                            135, // 🟢 កំណត់កម្ពស់រូបភាពឱ្យថេរ ធានាថាគ្រប់កាតស្មើគ្នា
                                        width: double.infinity,
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child:
                                              product.imageUrl != null &&
                                                  product.imageUrl!.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: product.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  placeholder: (context, url) =>
                                                      const Center(
                                                        child: SizedBox(
                                                          width: 15,
                                                          height: 15,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
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
                                                    Icons.shopping_bag_rounded,
                                                    size: 35,
                                                    color: Color(0xFF0F766E),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      // Favorite Icon Button
                                      Positioned(
                                        top: 14,
                                        right: 14,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {});
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.06),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.favorite_border_rounded,
                                              size: 14,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // 📝 Details Section
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
                                              // 🏷️ Product Name
                                              Text(
                                                product.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 3),

                                              // ⭐ Star Rating & Review Count
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star_rounded,
                                                    size: 13,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    "4.8", // អាចដាក់ជា Rating ពិតប្រាកដ ឬរក្សាតាមតម្រូវការ
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF334155),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "(${product.stockQuantity.toInt()})",
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),

                                              // 📄 Description (Short)
                                              Text(
                                                product.description ??
                                                    "Fresh & Delicious",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: Colors.grey[400],
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // 💰 Price & Add Button
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "\$${product.sellingPrice.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  color: Color(0xFF0F766E),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 30,
                                                width: 30,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    CartManager.addProduct(
                                                      product,
                                                    );
                                                    showTopSnackBar(
                                                      context,
                                                      product.name,
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF0F766E),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: EdgeInsets.zero,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
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
          child: const Icon(Icons.point_of_sale_rounded, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

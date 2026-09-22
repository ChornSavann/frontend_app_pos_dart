import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/purchase/create_purchase_screen.dart';

import '../../models/Product.dart';

class LowStockScreen extends StatefulWidget {
  final List<dynamic> lowStockProducts;

  const LowStockScreen({super.key, required this.lowStockProducts});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  final ApiProduct _apiProduct = ApiProduct();
  late List<dynamic> _products;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _products = widget.lowStockProducts;
  }

  // 🔄 Function សម្រាប់ទាញយកទិន្នន័យ Low Stock សាថ្មីពី Server
  Future<void> _refreshLowStockData() async {
    setState(() => _isLoading = true);
    try {
      List<Product> allProducts = await _apiProduct.fetchProducts();

      setState(() {
        _products = allProducts
            .where((p) => (p.stockQuantity ?? 0) <= 10)
            .map(
              (p) => {
                'id': p.id,
                'name': p.name,
                'stock_quantity': p.stockQuantity,
                'image_url': p.imageUrl,
              },
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Error refreshing low stock: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚠️ ផលិតផលជិតអស់ស្តុក',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(
              child: Text(
                'គ្មានទំនិញជិតអស់ស្តុកទេ',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final String? imageUrl =
                    product['image_url'] ?? product['image'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    // 🟢 ផ្នែកបង្ហាញរូបភាពផលិតផល
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade100,
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                              )
                            : const Icon(
                                Icons.storefront_rounded,
                                color: Colors.blueAccent,
                                size: 24,
                              ),
                      ),
                    ),
                    title: Text(
                      product['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'ស្តុកនៅសល់: ${product['stock_quantity'] ?? 0} ឯកតា',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePurchaseScreen(
                            productId: product['id'],
                            productName: product['name'],
                            productQuantity: product['stock_quantity'],
                          ),
                        ),
                      );

                      // 🟢 បើ Purchase ជោគជ័យ ធ្វើការហៅ Function Refresh ទិន្នន័យក្នុង Screen នេះភ្លាម
                      if (result == true) {
                        debugPrint("🔄 Refreshing low stock list...");
                        await _refreshLowStockData();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

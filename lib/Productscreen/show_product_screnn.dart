import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/models/Product.dart';

import '../msg/appSnackBar.dart';
import '../order/card_manager.dart';

class ShowProductScreen extends StatefulWidget {
  final int productId;

  const ShowProductScreen({super.key, required this.productId});

  @override
  State<ShowProductScreen> createState() => _ShowProductScreenState();
}

class _ShowProductScreenState extends State<ShowProductScreen> {
  bool _isLoading = true;
  Product? _product;
  int _quantity = 1;
  final ApiProduct apiProduct = ApiProduct();

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    setState(() => _isLoading = true);

    try {
      final Product productData = await apiProduct.getProductById(
        widget.productId,
      );

      if (!mounted) return;

      setState(() {
        _product = productData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "ព័ត៌មានលម្អិតទំនិញ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: () {
              // កូដសម្រាប់ Share ទំនិញ
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              "រកមិនឃើញទំនិញនេះទេ",
              style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // ទុកគម្លាតបាតក្រោមសម្រាប់ Sticky Bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Product Image Banner with Soft Shadow & Gradient
            Center(
              child: Container(
                height: 290,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: (_product!.imageUrl != null && _product!.imageUrl!.isNotEmpty)
                      ? Image.network(
                    _product!.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.broken_image_rounded, size: 60, color: Colors.grey[400]),
                      );
                    },
                  )
                      : Center(
                    child: Icon(Icons.image_not_supported_rounded, size: 60, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🏷️ Product Name, Price & Stock Badge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // តម្លៃលក់ (Selling Price) លេចធ្លោរ
                      Text(
                        "\$${_product!.sellingPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5), // ពណ៌ Indigo ស្អាតទំនើប
                        ),
                      ),
                      // ស្តុក Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _product!.stockQuantity > 0 ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _product!.stockQuantity > 0 ? "ស្តុក: ${_product!.stockQuantity}" : "អស់ពីស្តុក",
                          style: TextStyle(
                            fontSize: 12,
                            color: _product!.stockQuantity > 0 ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _product!.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (_product!.description != null && _product!.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _product!.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 📊 Financial & Cost Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.shopping_bag_rounded,
                    "តម្លៃដើម (Cost Price)",
                    "\$${_product!.costPrice.toStringAsFixed(2)}",
                    Colors.orange,
                    isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 🔖 General Details Card (SKU, Category, Brand, Unit)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.qr_code_rounded,
                    "SKU",
                    _product!.sku,
                    isDarkMode ? Colors.grey[300]! : Colors.grey[800]!,
                    isDarkMode,
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(
                    Icons.qr_code_scanner_rounded,
                    "Barcode",
                    _product!.barcode ?? 'N/A',
                    isDarkMode ? Colors.grey[300]! : Colors.grey[800]!,
                    isDarkMode,
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(
                    Icons.category_rounded,
                    "ប្រភេទ (Category)",
                    _product!.categoryName ?? 'N/A',
                    Colors.purple,
                    isDarkMode,
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(
                    Icons.branding_watermark_rounded,
                    "ប្រេន (Brand)",
                    _product!.brandName ?? 'N/A',
                    Colors.teal,
                    isDarkMode,
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  _buildInfoRow(
                    Icons.straighten_rounded,
                    "ខ្នាត (Unit)",
                    _product!.unitName ?? 'N/A',
                    Colors.indigo,
                    isDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // 🛒 Sticky Bottom Action Bar (ប៊ូតុងបញ្ជាទិញនៅខាងក្រោមបង្អស់)
      bottomSheet: _isLoading || _product == null
          ? null
          : Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // ➖➕ Quantity Selector
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text(
                      "$_quantity",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        if (_quantity < _product!.stockQuantity) {
                          setState(() => _quantity++);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 🚀 Add to Cart Button with Gradient
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      CartManager.addProduct(_product!, quantity: _quantity);
                      AppSnackBar.showSuccess(
                        context,
                        "បានបន្ថែម ${_product!.name} (ចំនួន $_quantity) ចូលកន្ត្រក!",
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width:5),
                        const Text(
                          "Add to Cart",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      Color valueColor,
      bool isDarkMode,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}
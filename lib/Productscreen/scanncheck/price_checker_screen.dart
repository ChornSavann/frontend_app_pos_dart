import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';

import '../../models/Product.dart';

class PriceCheckerScreen extends StatefulWidget {
  const PriceCheckerScreen({super.key});

  @override
  State<PriceCheckerScreen> createState() => _PriceCheckerScreenState();
}

class _PriceCheckerScreenState extends State<PriceCheckerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;
  bool _isLoadingProducts = true;
  List<Product> _allProducts = [];
  Map<String, dynamic>? _scannedProduct;

  final ApiProduct apiProduct = ApiProduct();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      List<Product> products = await apiProduct.fetchProducts();
      setState(() {
        _allProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
      debugPrint("Error loading products: $e");
    }
  }

  void _checkProductByBarcode(String barcode) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      var match = _allProducts.firstWhere(
        (p) => p.barcode?.trim() == barcode.trim(),
        orElse: () => Product(
          id: 0,
          name: '',
          slug: '',
          categoryId: 0,
          brandId: 0,
          unitId: 0,
          sku: '',
          costPrice: 0.0,
          sellingPrice: 0.0,
          stockQuantity: 0.0,
          alertQuantity: 0.0,
          isActive: 1,
        ),
      );

      if (match.id != 0) {
        setState(() {
          _scannedProduct = {
            'name': match.name,
            'price': match.sellingPrice ?? match.costPrice ?? 0.0,
            'stock': match.stockQuantity ?? 0.0,
            'unit': match.unitName ?? 'Pcs',
            'image': match.imageUrl,
            'barcode': barcode,
          };
        });
      } else {
        setState(() {
          _scannedProduct = null;
        });
        AppSnackBar.showError(
          context,
          'រកមិនឃើញទំនិញដែលមាន Barcode: $barcode ទេ',
        );
      }
    } catch (e) {
      debugPrint("Scan error: $e");
    } finally {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Price & Stock Checker',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                final torchState = state.torchState;
                return IconButton(
                  icon: Icon(
                    torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.amber,
                    size: 20,
                  ),
                  onPressed: () => _controller.toggleTorch(),
                );
              },
            ),
          ),
        ],
      ),
      body: _isLoadingProducts
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent),
            )
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _checkProductByBarcode(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),

                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 260,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.indigoAccent,
                            width: 3.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigoAccent.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Scan product barcode inside frame',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🏷️ បង្ហាញលទ្ធផលទំនិញທີ່ស្កេនបានយ៉ាងស្អាតនៅផ្នែកខាងក្រោម
                if (_scannedProduct != null)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // 🖼️ រូបភាពទំនិញ
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 75,
                              height: 75,
                              color: Colors.grey.shade100,
                              child: _scannedProduct!['image'] != null
                                  ? Image.network(
                                      _scannedProduct!['image'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_rounded,
                                      color: Colors.indigo,
                                      size: 34,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // 📝 ឈ្មោះ តម្លៃ និងស្តុក
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _scannedProduct!['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '\$${(_scannedProduct!['price'] as double).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 19,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            ((_scannedProduct!['stock']
                                                    as double) >
                                                0)
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Stock: ${_scannedProduct!['stock']} ${_scannedProduct!['unit']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              ((_scannedProduct!['stock']
                                                      as double) >
                                                  0)
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

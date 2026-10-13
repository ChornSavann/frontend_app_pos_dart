import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_inventory/Productscreen/show_product_id_screen.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';
import '../../models/Product.dart';
import '../../purchase/create_purchase_screen.dart';

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
            'id': match.id,
            'name': match.name,
            'price': match.sellingPrice ?? match.costPrice ?? 0.0,
            'stock': match.stockQuantity ?? 0.0,
            'unit': match.unitName ?? 'Pcs',
            'image': match.imageUrl,
            'barcode': barcode,
            'product': match,
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
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        title: const Text(
          'Price & Stock Checker',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF111827),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                final torchState = state.torchState;
                return IconButton(
                  icon: Icon(
                    torchState == TorchState.on
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: torchState == TorchState.on
                        ? Colors.amberAccent
                        : Colors.white70,
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
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : Stack(
              children: [
                // 📷 Scanner
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

                // 🎯 Modern Scanner Overlay Framework (មានភ្លើងសញ្ញាបៃតងពេលចាប់បាន Barcode)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 300,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            ..._buildCustomScannerCorners(
                              color: _isProcessing
                                  ? Colors.greenAccent
                                  : Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          // ប្តូរពណ៌ផ្ទៃដูกន្លែងអרט ប្រសិនបើចាប់បាន
                          color: _isProcessing
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _isProcessing
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isProcessing
                                  ? Icons.check_circle_rounded
                                  : Icons.qr_code_scanner_rounded,
                              color: _isProcessing
                                  ? Colors.greenAccent
                                  : Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isProcessing
                                  ? 'ស្កេនបានជោគជ័យ!'
                                  : 'ដាក់ Barcode ក្នុងស៊ុមដើម្បីស្កេន',
                              style: TextStyle(
                                color: _isProcessing
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_scannedProduct != null)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  color: const Color(0xFFF1F5F9),
                                  child: _scannedProduct!['image'] != null
                                      ? Image.network(
                                          _scannedProduct!['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => const Icon(
                                                Icons
                                                    .image_not_supported_rounded,
                                                color: Colors.grey,
                                                size: 28,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.inventory_2_rounded,
                                          color: Color(0xFF4F46E5),
                                          size: 32,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // 📝 Details Info
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
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${(_scannedProduct!['price'] as double).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color:
                                                ((_scannedProduct!['stock']
                                                        as double) >
                                                    0)
                                                ? const Color(0xFF10B981)
                                                : Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Stock: ${_scannedProduct!['stock']} ${_scannedProduct!['unit']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(height: 1, color: Colors.grey.shade100),
                          const SizedBox(height: 14),

                          // 🔘 Action Buttons (View Details & Add Stock)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    if (_scannedProduct != null) {
                                      final int productId =
                                          _scannedProduct!['id'] ?? 0;
                                      await _controller.stop();
                                      if (!mounted) return;

                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ShowProductIdScreen(
                                                productId: productId,
                                              ),
                                        ),
                                      );

                                      if (mounted) {
                                        _controller.start();
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.visibility_rounded,
                                    size: 16,
                                    color: Color(0xFF334155),
                                  ),
                                  label: const Text(
                                    'View Details',
                                    style: TextStyle(
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Add Stock Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (_scannedProduct != null) {
                                      await _controller.stop();
                                      final int productId =
                                          _scannedProduct!['id'] ?? 0;
                                      final String productName =
                                          _scannedProduct!['name'] ?? '';

                                      if (!mounted) return;

                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreatePurchaseScreen(
                                                productId: productId,
                                                productName: productName,
                                                productQuantity: 1,
                                              ),
                                        ),
                                      );

                                      if (mounted) {
                                        _controller.start();
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.add_shopping_cart_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Add Stock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
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
    );
  }

  // 🎨 Custom Corner Borders អាចប្តូរពណ៌តាមស្ថានភាពស្កេន
  List<Widget> _buildCustomScannerCorners({required Color color}) {
    const double cornerSize = 28.0;
    const double borderWidth = 4.5;

    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: borderWidth),
              left: BorderSide(color: color, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: borderWidth),
              right: BorderSide(color: color, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: borderWidth),
              left: BorderSide(color: color, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: borderWidth),
              right: BorderSide(color: color, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(16),
            ),
          ),
        ),
      ),
    ];
  }
}

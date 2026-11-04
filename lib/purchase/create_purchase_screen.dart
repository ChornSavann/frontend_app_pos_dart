import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:pos_inventory/api/api_purchase.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';
import 'package:pos_inventory/purchase/scane_barcode/barcode_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/Product.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';

// ═════════════════════════════════════════════════════════════
// UI ONLY: design tokens
// ═════════════════════════════════════════════════════════════
class _C {
  static const bg = Color(0xFFF2F4F8);
  static const ink = Color(0xFF142033);
  static const muted = Color(0xFF6C7A8E);
  static const line = Color(0xFFE0E6EE);
  static const navy = Color(0xFF0E2A47);
  static const red = Color(0xFFD32F2F);
  static const green = Color(0xFF2E9E6B);
}

class CreatePurchaseScreen extends StatefulWidget {
  final dynamic productId;
  final String? productName;
  final dynamic productQuantity;
  final Function? onScan;
  const CreatePurchaseScreen({
    super.key,
    this.productId,
    this.productName,
    this.productQuantity,
    this.onScan,
  });

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingProducts = true;

  List<dynamic> _suppliers = [];
  String? _selectedSupplierId;
  bool _isLoadingSuppliers = true;

  // Controllers
  final TextEditingController _purchaseNumberController =
  TextEditingController();
  final TextEditingController _discountController = TextEditingController(
    text: '0',
  );
  final TextEditingController _taxController = TextEditingController(text: '0');
  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _itemQuantityController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();

  String? _userId;
  final String _paymentMethod = 'cash';
  final String _status = 'completed';

  List<dynamic> _products = [];
  String? _selectedProductId;
  String? _selectedProductName;

  final List<Map<String, dynamic>> _purchaseItems = [];

  double _subtotal = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchProducts();
    _fetchSuppliers();
    if (widget.productId != null) {
      _selectedProductId = widget.productId.toString();
      _selectedProductName = widget.productName;
    }
    if (widget.productQuantity != null) {
      _itemQuantityController.text = widget.productQuantity.toString();
    }
    _generatePurchaseNumber();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('user_id');
    setState(() {
      _userId = userId != null ? userId.toString() : '1';
    });
  }

  final ApiPurchase apiPurchase = ApiPurchase();

  Future<void> _fetchSuppliers() async {
    try {
      List<Supplier> suppliersList = await apiPurchase.getAllSuppliers();
      setState(() {
        _suppliers = suppliersList
            .map((supplier) => {'id': supplier.id, 'name': supplier.name})
            .toList();
        _isLoadingSuppliers = false;
      });
    } catch (e) {
      print('Error fetching suppliers: $e');
      setState(() => _isLoadingSuppliers = false);
    }
  }

  Future<void> _fetchProducts() async {
    try {
      List<Product> productsList = await apiPurchase.fetchProducts();
      setState(() {
        _products = productsList
            .map(
              (product) => {
            'id': product.id.toString(),
            'name': product.name,
            'price': product.costPrice ?? 0.0,
            'base_unit_name': product.unitName,
            'image_url': product.imageUrl,
            'barcode': product.barcode,
          },
        )
            .toList();
        _isLoadingProducts = false;

        if (widget.productId != null) {
          String targetId = widget.productId.toString();
          bool exists = _products.any((p) => p['id'] == targetId);

          if (exists) {
            _selectedProductId = targetId;
            _selectedProductName = widget.productName;

            var matchedProduct = _products.firstWhere(
                  (p) => p['id'] == targetId,
              orElse: () => <String, dynamic>{},
            );
            if (matchedProduct.isNotEmpty) {
              _itemPriceController.text = matchedProduct['price'].toString();
            }
          }
        }
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onScan: (scannedCode) {
            _findAndAddProductByBarcode(scannedCode);
          },
        ),
      ),
    );
  }

  // 🔍 មុខងារស្វែងរកផលិតផលតាម Barcode (រួមបញ្ចូលទាំង Local Hive Cache ពេលអត់មានអ៊ិនធឺណិត)
  void _findAndAddProductByBarcode(String barcode) {
    String cleanScannedBarcode = barcode.trim();
    print("🔍 Scanned Barcode: '$cleanScannedBarcode'");

    // ១. ឆែកមើលក្នុង List បច្ចុប្បន្ន
    Map<String, dynamic> matchedProduct = {};
    try {
      matchedProduct = _products.firstWhere(
            (p) => p['barcode']?.toString().trim() == cleanScannedBarcode,
        orElse: () => <String, dynamic>{}, // 👈 កែតម្រូវ Type ត្រង់នេះឱ្យច្បាស់លាស់
      );
    } catch (e) {
      matchedProduct = {};
    }

    // ២. បើរកមិនឃើញក្នុង List ទេ ឆែកក្នុង Local Hive Box (Offline Mode)
    if (matchedProduct.isEmpty) {
      try {
        var box = Hive.box('offline_products');
        var cachedProduct = box.get(cleanScannedBarcode);
        if (cachedProduct != null) {
          matchedProduct = Map<String, dynamic>.from(cachedProduct);
        }
      } catch (e) {
        print("Hive error: $e");
      }
    }

    // ៣. បើរកឃើញ ធ្វើការ Add ចូល List
    if (matchedProduct.isNotEmpty) {
      setState(() {
        int existingIndex = _purchaseItems.indexWhere(
              (item) =>
          item['product_id'].toString() == matchedProduct['id'].toString(),
        );

        if (existingIndex >= 0) {
          _purchaseItems[existingIndex]['quantity'] += 1.0;
          _purchaseItems[existingIndex]['total_price'] =
              _purchaseItems[existingIndex]['quantity'] *
                  _purchaseItems[existingIndex]['unit_cost'];
        } else {
          _purchaseItems.add({
            'product_id': int.tryParse(matchedProduct['id'].toString()) ?? 0,
            'product_name': matchedProduct['name'].toString(),
            'unit_cost':
            double.tryParse(matchedProduct['price'].toString()) ?? 0.0,
            'quantity': 10.0,
            'total_price':
            double.tryParse(matchedProduct['price'].toString()) ?? 0.0,
            'image_url': matchedProduct['image_url'],
          });
        }
        _calculateTotals();
      });
      HapticFeedback.mediumImpact();
      AppSnackBar.showSuccess(context, 'បានបន្ថែម: ${matchedProduct['name']}');
    } else {
      AppSnackBar.showError(
        context,
        'រកមិនឃើញផលិតផលដែលមាន Barcode: $cleanScannedBarcode',
      );
    }
  }

  void _addItemToCart() {
    if (_selectedProductId == null) {
      AppSnackBar.showError(context, 'សូមជ្រើសរើសទំនិញ (Product)');
      return;
    }
    double qty = double.tryParse(_itemQuantityController.text) ?? 0;
    double price = double.tryParse(_itemPriceController.text) ?? 0;

    if (qty <= 0 || price <= 0) {
      AppSnackBar.showError(context, 'សូមបញ្ចូលចំនួន និងតម្លៃឱ្យបានត្រឹមត្រូវ');
      return;
    }

    var selectedProductData = _products.firstWhere(
          (p) => p['id'].toString() == _selectedProductId.toString(),
      orElse: () => <String, dynamic>{},
    );

    setState(() {
      int existingIndex = _purchaseItems.indexWhere(
            (item) =>
        item['product_id'].toString() == _selectedProductId.toString(),
      );

      if (existingIndex >= 0) {
        _purchaseItems[existingIndex]['quantity'] += qty;
        _purchaseItems[existingIndex]['total_price'] =
            _purchaseItems[existingIndex]['quantity'] *
                _purchaseItems[existingIndex]['unit_cost'];
      } else {
        _purchaseItems.add({
          'product_id': int.tryParse(_selectedProductId.toString()) ?? 0,
          'product_name': _selectedProductName ?? 'Unknown Product',
          'unit_cost': price,
          'quantity': qty,
          'total_price': qty * price,
          'image_url': selectedProductData.isNotEmpty
              ? selectedProductData['image_url']
              : null,
        });
      }

      _selectedProductId = null;
      _selectedProductName = null;
      _itemQuantityController.clear();
      _itemPriceController.clear();

      _calculateTotals();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _purchaseItems.removeAt(index);
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    double sub = 0;
    for (var item in _purchaseItems) {
      sub += (item['total_price'] as num).toDouble();
    }

    double discount = double.tryParse(_discountController.text) ?? 0;
    double tax = double.tryParse(_taxController.text) ?? 0;

    setState(() {
      _subtotal = sub;
      _total = (_subtotal - discount) + tax;
      if (_total < 0) _total = 0;
    });
  }

  Future<void> _submitPurchase() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSupplierId == null) {
        AppSnackBar.showError(context, 'សូមជ្រើសរើស Supplier');
        return;
      }

      if (_purchaseItems.isEmpty) {
        AppSnackBar.showError(context, 'សូមបន្ថែមទំនិញយ៉ាងហោចណាស់ ១');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final Map<String, dynamic> purchaseDataMap = {
          'purchase_number': _purchaseNumberController.text.trim().isEmpty
              ? null
              : _purchaseNumberController.text.trim(),
          'supplier_id': _selectedSupplierId,
          'user_id': _userId ?? '1',
          'subtotal': _subtotal,
          'discount': double.tryParse(_discountController.text) ?? 0,
          'tax': double.tryParse(_taxController.text) ?? 0,
          'total': _total,
          'payment_method': _paymentMethod,
          'status': _status,
          'notes': _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          'items': _purchaseItems,
        };

        bool success = await apiPurchase.createPurchase(
          PurchaseModel.fromJson(purchaseDataMap),
        );

        setState(() => _isLoading = false);

        if (success) {
          if (mounted) {
            AppSnackBar.showSuccess(context, 'Purchase created successfully!');
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            AppSnackBar.showError(context, 'Error: Failed to create purchase');
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          AppSnackBar.showError(context, 'Connection Error: $e');
        }
      }
    }
  }

  void _generatePurchaseNumber() {
    String datePart = DateTime.now()
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');
    int randomNum = 1000 + DateTime.now().millisecond % 9000;
    setState(() {
      _purchaseNumberController.text = 'PUR-$datePart-$randomNum';
    });
  }

  @override
  void dispose() {
    _purchaseNumberController.dispose();
    _itemQuantityController.dispose();
    _itemPriceController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // UI ONLY: everything below this line is presentation.
  // No business logic above was changed.
  // ═══════════════════════════════════════════════════════════

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.muted, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: _C.navy,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: icon == null ? null : Icon(icon, color: _C.navy, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _C.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(_C.line),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(_C.navy, 1.6),
      errorBorder: border(_C.red),
      focusedErrorBorder: border(_C.red, 1.6),
    );
  }

  // 📦 Product selector field (opens the picker sheet)
  Widget _buildProductSelector() {
    final selected = _selectedProductId == null
        ? <String, dynamic>{}
        : _products.firstWhere(
          (p) => p['id'].toString() == _selectedProductId,
      orElse: () => <String, dynamic>{},
    );
    final hasSelection = selected.isNotEmpty;
    final String name = hasSelection ? '${selected['name'] ?? ''}' : '';
    final String unit =
    hasSelection ? '${selected['base_unit_name'] ?? ''}' : '';
    final dynamic imageUrl = hasSelection ? selected['image_url'] : null;

    return Material(
      color: _C.bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _showProductPicker,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              _ProductThumb(url: imageUrl?.toString(), size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Product',
                      style: TextStyle(color: _C.muted, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasSelection ? name : 'Choose a product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                        hasSelection ? FontWeight.bold : FontWeight.w500,
                        color: hasSelection ? _C.ink : _C.muted,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _UnitChip(text: unit),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.unfold_more_rounded, color: _C.muted),
            ],
          ),
        ),
      ),
    );
  }

  // 🔍 Bottom sheet with search, image, unit and cost for every product
  void _showProductPicker() {
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final q = query.trim().toLowerCase();
            final filtered = _products.where((p) {
              if (q.isEmpty) return true;
              final hay = '${p['name'] ?? ''} ${p['barcode'] ?? ''}'
                  .toLowerCase();
              return hay.contains(q);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _C.line,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 14, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Product',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _C.ink,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(sheetContext),
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: _C.bg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: _C.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: TextField(
                        onChanged: (v) => setSheet(() => query = v),
                        decoration: InputDecoration(
                          hintText: 'Search name or barcode',
                          hintStyle: const TextStyle(
                            color: _C.muted,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _C.muted,
                          ),
                          filled: true,
                          fillColor: _C.bg,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filtered.length} products',
                          style: const TextStyle(
                            color: _C.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                        child: Text(
                          'No products found',
                          style: TextStyle(
                            color: _C.muted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final prod = filtered[i];
                          final bool isSelected =
                              _selectedProductId == prod['id'].toString();
                          final bool inCart = _purchaseItems.any(
                                (item) =>
                            item['product_id'].toString() ==
                                prod['id'].toString(),
                          );
                          final String unit =
                              '${prod['base_unit_name'] ?? ''}';

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              // same selection logic as the old dropdown
                              final String value = prod['id'].toString();
                              setState(() {
                                _selectedProductId = value;
                                var selectedItem = _products.firstWhere(
                                      (p) => p['id'].toString() == value,
                                  orElse: () => <String, dynamic>{},
                                );
                                if (selectedItem.isNotEmpty) {
                                  _selectedProductName =
                                  selectedItem['name'];
                                  _itemPriceController.text =
                                      selectedItem['price'].toString();
                                }
                              });
                              Navigator.pop(sheetContext);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _C.navy.withValues(alpha: 0.07)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? _C.navy : _C.line,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _ProductThumb(
                                    url: prod['image_url']?.toString(),
                                    size: 54,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${prod['name'] ?? 'Product'}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.5,
                                            color: _C.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            if (unit.isNotEmpty)
                                              _UnitChip(text: unit),
                                            if (inCart)
                                              const _UnitChip(
                                                text: 'In cart',
                                                color: _C.green,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${prod['price']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _C.navy,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? _C.navy
                                            : _C.line,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildHero(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final count = _purchaseItems.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 4, 8, 22),
      decoration: const BoxDecoration(
        color: _C.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              else
                const SizedBox(width: 48),
              const Expanded(
                child: Text(
                  'Create Purchase',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: _openScanner,
                  tooltip: 'Scan Barcode',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$ ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_basket_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count ${count == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildItemTile(int index) {
    final item = _purchaseItems[index];
    final String? imageUrl = item['image_url'];

    return Container(
      margin: EdgeInsets.only(bottom: index == _purchaseItems.length - 1 ? 0 : 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 52,
              color: Colors.white,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.inventory_2_rounded,
                    color: _C.navy,
                    size: 22,
                  );
                },
              )
                  : const Icon(
                Icons.inventory_2_rounded,
                color: _C.navy,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: _C.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item['quantity']} x \$${item['unit_cost']}',
                  style: const TextStyle(color: _C.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${(item['total_price'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _C.navy,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _removeItem(index),
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _C.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: _C.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: _C.muted, fontSize: 12),
              ),
              Text(
                '\$ ${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _C.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitPurchase,
                style: FilledButton.styleFrom(
                  backgroundColor: _C.navy,
                  disabledBackgroundColor: _C.navy.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Purchase',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discountValue = double.tryParse(_discountController.text) ?? 0;
    final taxValue = double.tryParse(_taxController.text) ?? 0;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHero(context),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Purchase info ──
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle(
                              icon: Icons.receipt_long_outlined,
                              title: 'Purchase Info',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _purchaseNumberController,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _C.ink,
                              ),
                              decoration: _inputDecoration(
                                label: 'Purchase Number',
                                icon: Icons.tag_rounded,
                                suffix: IconButton(
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    color: _C.navy,
                                  ),
                                  onPressed: _generatePurchaseNumber,
                                  tooltip: 'Generate New Number',
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'សូមបញ្ចូល Purchase Number'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _isLoadingSuppliers
                                ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _C.navy,
                                ),
                              ),
                            )
                                : DropdownButtonFormField<String>(
                              value: _selectedSupplierId,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(14),
                              dropdownColor: Colors.white,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _C.muted,
                              ),
                              decoration: _inputDecoration(
                                label: 'Select Supplier',
                                icon: Icons.business_outlined,
                              ),
                              hint: const Text('Choose a supplier'),
                              items: _suppliers
                                  .map<DropdownMenuItem<String>>((
                                  supplier,
                                  ) {
                                return DropdownMenuItem<String>(
                                  value: supplier['id'].toString(),
                                  child: Text(
                                    supplier['name'] ?? 'Supplier Name',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(
                                    () => _selectedSupplierId = value,
                              ),
                              validator: (value) => value == null
                                  ? 'សូមជ្រើសរើស Supplier'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 2. Add products ──
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              icon: Icons.add_shopping_cart_rounded,
                              title: 'Add Products',
                              trailing: TextButton.icon(
                                onPressed: _openScanner,
                                icon: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 18,
                                ),
                                label: const Text('Scan Barcode'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _C.navy,
                                  backgroundColor:
                                  _C.navy.withValues(alpha: 0.08),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 📦 Product Dropdown
                            _isLoadingProducts
                                ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _C.navy,
                                ),
                              ),
                            )
                                : _buildProductSelector(),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _itemQuantityController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _C.ink,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Quantity',
                                      icon: Icons.numbers_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _itemPriceController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _C.ink,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Unit Cost (\$)',
                                      icon: Icons.attach_money_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 50,
                              child: FilledButton.tonalIcon(
                                onPressed: _addItemToCart,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                  _C.navy.withValues(alpha: 0.1),
                                  foregroundColor: _C.navy,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 3. Selected items ──
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              icon: Icons.list_alt_rounded,
                              title: 'Selected Items',
                              trailing: _purchaseItems.isEmpty
                                  ? null
                                  : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _C.navy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_purchaseItems.length}',
                                  style: const TextStyle(
                                    color: _C.navy,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (_purchaseItems.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 26,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: _C.bg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 36,
                                      color: _C.muted,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'No items yet',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _C.ink,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Scan a barcode or choose a product above',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _C.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                children: [
                                  for (var i = 0; i < _purchaseItems.length; i++)
                                    _buildItemTile(i),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 4. Summary ──
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle(
                              icon: Icons.calculate_outlined,
                              title: 'Summary',
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _discountController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => _calculateTotals(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _C.ink,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Discount (\$)',
                                      icon: Icons.sell_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _taxController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => _calculateTotals(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _C.ink,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Tax (\$)',
                                      icon: Icons.percent_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _C.navy.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _C.navy.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _SummaryRow(
                                    label: 'Subtotal:',
                                    value: '\$ ${_subtotal.toStringAsFixed(2)}',
                                  ),
                                  const SizedBox(height: 8),
                                  _SummaryRow(
                                    label: 'Discount:',
                                    value:
                                    '- \$ ${discountValue.toStringAsFixed(2)}',
                                    valueColor: _C.green,
                                  ),
                                  const SizedBox(height: 8),
                                  _SummaryRow(
                                    label: 'Tax:',
                                    value: '+ \$ ${taxValue.toStringAsFixed(2)}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1, color: _C.line),
                                  ),
                                  _SummaryRow(
                                    label: 'Grand Total:',
                                    value: '\$ ${_total.toStringAsFixed(2)}',
                                    big: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 5. Notes ──
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle(
                              icon: Icons.sticky_note_2_outlined,
                              title: 'Notes',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _noteController,
                              maxLines: 3,
                              style: const TextStyle(color: _C.ink),
                              decoration: _inputDecoration(
                                label: 'Notes (Optional)',
                              ),
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
        ),
        bottomNavigationBar: keyboardOpen ? null : _buildBottomBar(context),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// UI ONLY: small presentation widgets
// ═════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _C.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: _C.navy),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: _C.ink,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool big;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.big = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: big ? 16 : 13.5,
            fontWeight: big ? FontWeight.bold : FontWeight.w500,
            color: big ? _C.ink : _C.muted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (big ? _C.navy : _C.ink),
          ),
        ),
      ],
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String? url;
  final double size;
  const _ProductThumb({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty && url != 'null';
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: hasUrl
            ? Image.network(
          url!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.inventory_2_rounded,
            color: _C.navy,
            size: size * 0.45,
          ),
        )
            : Icon(
          Icons.inventory_2_rounded,
          color: _C.navy,
          size: size * 0.45,
        ),
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String text;
  final Color color;
  const _UnitChip({required this.text, this.color = _C.navy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
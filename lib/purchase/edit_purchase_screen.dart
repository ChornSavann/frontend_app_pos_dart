import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_purchase.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';
import '../models/Product.dart';
import '../msg/appSnackBar.dart';

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
  static const orange = Color(0xFFEF6C00);
}

class EditPurchaseScreen extends StatefulWidget {
  final PurchaseModel purchase;

  const EditPurchaseScreen({super.key, required this.purchase});

  @override
  State<EditPurchaseScreen> createState() => _EditPurchaseScreenState();
}

class _EditPurchaseScreenState extends State<EditPurchaseScreen> {
  bool _isLoading = false;
  bool _isLoadingSuppliers = true;
  bool _isLoadingProducts = true;

  List<dynamic> _suppliers = [];
  String? _selectedSupplierId;

  List<dynamic> _products = [];
  List<Map<String, dynamic>> _purchaseItems = [];

  late TextEditingController _purchaseNumberController;
  late TextEditingController _discountController;
  late TextEditingController _taxController;
  late TextEditingController _noteController;

  final ScrollController _scrollController = ScrollController();

  String _paymentMethod = 'cash';
  String _status = 'completed';
  double _subtotal = 0.0;
  double _total = 0.0;

  final ApiPurchase apiPurchase = ApiPurchase();

  @override
  void initState() {
    super.initState();

    _purchaseNumberController = TextEditingController(
      text: widget.purchase.purchaseNumber ?? '',
    );
    _selectedSupplierId = widget.purchase.supplierId?.toString();
    _paymentMethod = widget.purchase.paymentMethod;
    _status = widget.purchase.status;
    _subtotal = widget.purchase.subtotal;
    _total = widget.purchase.total;

    _discountController = TextEditingController(
      text: widget.purchase.discount.toString(),
    );
    _taxController = TextEditingController(
      text: widget.purchase.tax.toString(),
    );
    _noteController = TextEditingController(text: widget.purchase.notes ?? '');

    // 🟢 ទាញយក items ចាស់ព្រមទាំង image_url មកជាមួយ
    if (widget.purchase.items != null && widget.purchase.items!.isNotEmpty) {
      _purchaseItems = widget.purchase.items!.map<Map<String, dynamic>>((item) {
        return {
          'product_id': item['product_id']?.toString() ?? '',
          'product_name': item['product_name']?.toString() ?? 'Product',
          'unit_cost':
              double.tryParse(
                (item['unit_cost'] ?? item['price'] ?? 0).toString(),
              ) ??
              0.0,
          'quantity':
              double.tryParse((item['quantity'] ?? 1).toString()) ?? 1.0,
          'image_url': item['image_url'] ?? item['product']?['image_url'],
        };
      }).toList();
    }

    _fetchSuppliers();
    _fetchProducts();
    _calculateTotals();
  }

  // ───────────────────────────────────────────────────────────
  // Add-product bottom sheet (visual redesign only; the search,
  // add-item and scroll logic are unchanged)
  // ───────────────────────────────────────────────────────────
  void _showAddProductDialog() {
    TextEditingController searchController = TextEditingController();
    List<dynamic> filteredProducts = List.from(_products);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.72,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _C.line,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 14, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Product to Add',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _C.ink,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(modalContext).pop(),
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

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search product name...',
                          hintStyle: const TextStyle(
                            color: _C.muted,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _C.muted,
                            size: 22,
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
                        onChanged: (value) {
                          setModalState(() {
                            filteredProducts = _products.where((product) {
                              final name = product['name']
                                  .toString()
                                  .toLowerCase();
                              return name.contains(value.toLowerCase());
                            }).toList();
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        '${filteredProducts.length} products',
                        style: const TextStyle(color: _C.muted, fontSize: 12),
                      ),
                    ),

                    Expanded(
                      child: _isLoadingProducts
                          ? const Center(
                              child: CircularProgressIndicator(color: _C.navy),
                            )
                          : filteredProducts.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: _C.muted,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No products found',
                                    style: TextStyle(
                                      color: _C.muted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final String? imageUrl = product['image_url'];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _C.line),
                                  ),
                                  child: Row(
                                    children: [
                                      _ProductThumb(url: imageUrl, size: 54),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'] ?? 'Unknown',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                                color: _C.ink,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Price: \$${double.parse(product['price'].toString()).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: _C.navy,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _C.navy,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            Navigator.of(modalContext).pop();
                                            setState(() {
                                              Map<String, dynamic> newItem = {
                                                'product_id': product['id']
                                                    .toString(),
                                                'product_name': product['name']
                                                    .toString(),
                                                'unit_cost':
                                                    double.tryParse(
                                                      product['price']
                                                          .toString(),
                                                    ) ??
                                                    0.0,
                                                'quantity': 1.0,
                                                'image_url':
                                                    product['image_url'],
                                              };
                                              _purchaseItems.add(newItem);
                                              _calculateTotals();
                                            });

                                            Future.delayed(
                                              const Duration(milliseconds: 150),
                                              () {
                                                if (_scrollController
                                                    .hasClients) {
                                                  _scrollController.animateTo(
                                                    _scrollController
                                                        .position
                                                        .maxScrollExtent,
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    curve: Curves.easeOut,
                                                  );
                                                }
                                              },
                                            );
                                          },
                                          child: const Icon(
                                            Icons.add_rounded,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ],
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

  Future<void> _fetchSuppliers() async {
    try {
      List<Supplier> suppliersList = await apiPurchase.getAllSuppliers();
      setState(() {
        _suppliers = suppliersList
            .map((s) => {'id': s.id, 'name': s.name})
            .toList();
        _isLoadingSuppliers = false;
      });
    } catch (e) {
      setState(() => _isLoadingSuppliers = false);
    }
  }

  Future<void> _fetchProducts() async {
    try {
      List<Product> productsList = await apiPurchase.fetchProducts();
      setState(() {
        _products = productsList
            .map(
              (p) => {
                'id': p.id,
                'name': p.name,
                'price': p.costPrice ?? 0.0,
                'image_url': p.imageUrl,
              },
            )
            .toList();

        for (var i = 0; i < _purchaseItems.length; i++) {
          if (_purchaseItems[i]['image_url'] == null ||
              _purchaseItems[i]['image_url'] == '') {
            final matchedProduct = _products.firstWhere(
              (p) =>
                  p['id'].toString() ==
                  _purchaseItems[i]['product_id'].toString(),
              orElse: () => <String, dynamic>{},
            );
            if (matchedProduct.isNotEmpty &&
                matchedProduct['image_url'] != null) {
              _purchaseItems[i]['image_url'] = matchedProduct['image_url'];
            }
          }
        }

        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  void _calculateTotals() {
    double sub = 0.0;
    for (var item in _purchaseItems) {
      double qty = item['quantity'] ?? 0;
      double price = item['unit_cost'] ?? 0;
      sub += (qty * price);
    }

    double discount = double.tryParse(_discountController.text) ?? 0;
    double tax = double.tryParse(_taxController.text) ?? 0;

    setState(() {
      _subtotal = sub;
      _total = (_subtotal - discount) + tax;
      if (_total < 0) _total = 0;
    });
  }

  Future<void> _submitUpdate() async {
    if (_selectedSupplierId == null) {
      AppSnackBar.showError(context, 'សូមជ្រើសរើស Supplier');
      return;
    }

    if (_purchaseItems.isEmpty) {
      AppSnackBar.showError(context, 'សូមបញ្ចូលសាច់ទំនិញយ៉ាងតិច១');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> formattedItems = _purchaseItems.map((item) {
        double qty = item['quantity'];
        double price = item['unit_cost'];
        return {
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'unit_cost': price,
          'quantity': qty,
          'total_price': qty * price,
        };
      }).toList();

      final Map<String, dynamic> purchaseDataMap = {
        'purchase_number': _purchaseNumberController.text.trim(),
        'supplier_id': _selectedSupplierId,
        'user_id': widget.purchase.userId,
        'subtotal': _subtotal,
        'discount': double.tryParse(_discountController.text) ?? 0,
        'tax': double.tryParse(_taxController.text) ?? 0,
        'total': _total,
        'payment_method': _paymentMethod,
        'status': _status,
        'notes': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        'items': formattedItems,
      };

      bool success = await apiPurchase.updatePurchase(
        widget.purchase.id,
        PurchaseModel.fromJson(purchaseDataMap),
      );

      setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Purchase updated successfully!');
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to update purchase');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    }
  }

  @override
  void dispose() {
    _purchaseNumberController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // UI ONLY: everything below is presentation. The callbacks that
  // are wired to widgets are the same ones as in the old code.
  // ═══════════════════════════════════════════════════════════

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    bool dense = false,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(dense ? 12 : 14),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      labelText: label,
      isDense: dense,
      labelStyle: const TextStyle(color: _C.muted, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: _C.navy,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: icon == null ? null : Icon(icon, color: _C.navy, size: 20),
      filled: true,
      fillColor: dense ? Colors.white : _C.bg,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: dense ? 12 : 16,
      ),
      border: border(_C.line),
      enabledBorder: border(dense ? _C.line : Colors.transparent),
      focusedBorder: border(_C.navy, 1.6),
    );
  }

  Widget _buildHero(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final count = _purchaseItems.length;
    final bool completed = _status.toLowerCase() == 'completed';
    final Color statusColor = completed ? _C.green : _C.orange;

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
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Edit Purchase',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((widget.purchase.purchaseNumber ?? '').isNotEmpty)
                      Text(
                        widget.purchase.purchaseNumber ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(int index) {
    final item = _purchaseItems[index];
    final double itemTotal = (item['quantity'] ?? 0) * (item['unit_cost'] ?? 0);
    final String? imageUrl = item['image_url'];

    return Container(
      margin: EdgeInsets.only(
        bottom: index == _purchaseItems.length - 1 ? 0 : 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProductThumb(url: imageUrl, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['product_name'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: _C.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _purchaseItems.removeAt(index);
                    _calculateTotals();
                  });
                },
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _C.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: _C.red,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item['quantity'].toString(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _C.ink,
                  ),
                  decoration: _inputDecoration(label: 'Qty', dense: true),
                  onChanged: (val) {
                    item['quantity'] = double.tryParse(val) ?? 1.0;
                    _calculateTotals();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: item['unit_cost'].toString(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _C.ink,
                  ),
                  decoration: _inputDecoration(
                    label: 'Price (\$)',
                    dense: true,
                  ),
                  onChanged: (val) {
                    item['unit_cost'] = double.tryParse(val) ?? 0.0;
                    _calculateTotals();
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: _C.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '\$${itemTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _C.navy,
                        ),
                      ),
                    ),
                  ],
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
                onPressed: _isLoading ? null : _submitUpdate,
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
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Update Purchase',
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
        body: Column(
          children: [
            _buildHero(context),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
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

                          // Purchase Number Input
                          TextField(
                            controller: _purchaseNumberController,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _C.ink,
                            ),
                            decoration: _inputDecoration(
                              label: 'Purchase Number',
                              icon: Icons.tag_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Supplier Dropdown (មានភ្ជាប់សុវត្ថិភាពការពារ Crash)
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
                                  value:
                                      _suppliers.any(
                                        (s) =>
                                            s['id'].toString() ==
                                            _selectedSupplierId,
                                      )
                                      ? _selectedSupplierId
                                      : null,
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
                                  items: _suppliers
                                      .map<DropdownMenuItem<String>>((
                                        supplier,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: supplier['id'].toString(),
                                          child: Text(
                                            supplier['name'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      })
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedSupplierId = val),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 2. Purchase items ──
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.inventory_2_outlined,
                            title: 'Purchase Products',
                            trailing: TextButton.icon(
                              onPressed: _showAddProductDialog,
                              style: TextButton.styleFrom(
                                foregroundColor: _C.navy,
                                backgroundColor: _C.navy.withValues(
                                  alpha: 0.08,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Item'),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // List of Purchase Items with Images
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
                                    'Tap "Add Item" to add a product',
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

                    // ── 3. Summary ──
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(
                            icon: Icons.calculate_outlined,
                            title: 'Summary',
                          ),
                          const SizedBox(height: 14),

                          // Discount & Tax Inputs
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
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
                                child: TextField(
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

                          // Financial Summary
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

                    // ── 4. Notes ──
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(
                            icon: Icons.sticky_note_2_outlined,
                            title: 'Notes',
                          ),
                          const SizedBox(height: 14),

                          // Notes Input
                          TextField(
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

  const _SectionTitle({required this.icon, required this.title, this.trailing});

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
    final hasUrl = url != null && url!.isNotEmpty;
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

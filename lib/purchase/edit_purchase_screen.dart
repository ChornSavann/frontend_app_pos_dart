import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_purchase.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';
import '../models/Product.dart';
import '../msg/appSnackBar.dart';

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
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Product to Add',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search product name...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        filteredProducts = _products.where((product) {
                          final name = product['name'].toString().toLowerCase();
                          return name.contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: _isLoadingProducts
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2563EB),
                            ),
                          )
                        : filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No products found',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final String? imageUrl = product['image_url'];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade100,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      color: const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.08),
                                      child:
                                          imageUrl != null &&
                                              imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.inventory_2_rounded,
                                                      color: Color(0xFF2563EB),
                                                      size: 24,
                                                    );
                                                  },
                                            )
                                          : const Icon(
                                              Icons.inventory_2_rounded,
                                              color: Color(0xFF2563EB),
                                              size: 24,
                                            ),
                                    ),
                                  ),
                                  title: Text(
                                    product['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Price: \$${double.parse(product['price'].toString()).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  trailing: SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2563EB,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                                  product['price'].toString(),
                                                ) ??
                                                0.0,
                                            'quantity': 1.0,
                                            'image_url': product['image_url'],
                                          };
                                          _purchaseItems.add(newItem);
                                          _calculateTotals();
                                        });

                                        Future.delayed(
                                          const Duration(milliseconds: 150),
                                          () {
                                            if (_scrollController.hasClients) {
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
                                      child: const Icon(Icons.add, size: 20),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Edit Purchase',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Purchase Number Input
            TextField(
              controller: _purchaseNumberController,
              decoration: InputDecoration(
                labelText: 'Purchase Number',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF2563EB),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            // Supplier Dropdown (មានភ្ជាប់សុវត្ថិភាពការពារ Crash)
            _isLoadingSuppliers
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  )
                : DropdownButtonFormField<String>(
                    value:
                        _suppliers.any(
                          (s) => s['id'].toString() == _selectedSupplierId,
                        )
                        ? _selectedSupplierId
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Select Supplier',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon: const Icon(
                        Icons.business_outlined,
                        color: Color(0xFF2563EB),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _suppliers.map<DropdownMenuItem<String>>((supplier) {
                      return DropdownMenuItem<String>(
                        value: supplier['id'].toString(),
                        child: Text(supplier['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSupplierId = val),
                  ),
            const SizedBox(height: 20),

            // Header for Purchase Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Purchase Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddProductDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(
                      0xFF2563EB,
                    ).withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Add Item',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // List of Purchase Items with Images
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _purchaseItems.length,
              itemBuilder: (context, index) {
                final item = _purchaseItems[index];
                final double itemTotal =
                    (item['quantity'] ?? 0) * (item['unit_cost'] ?? 0);
                final String? imageUrl = item['image_url'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 42,
                              height: 42,
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.08),
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.inventory_2_rounded,
                                              color: Color(0xFF2563EB),
                                              size: 20,
                                            );
                                          },
                                    )
                                  : const Icon(
                                      Icons.inventory_2_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['product_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _purchaseItems.removeAt(index);
                                _calculateTotals();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item['quantity'].toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Qty',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                item['quantity'] = double.tryParse(val) ?? 1.0;
                                _calculateTotals();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: item['unit_cost'].toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price (\$)',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                item['unit_cost'] = double.tryParse(val) ?? 0.0;
                                _calculateTotals();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            alignment: Alignment.centerRight,
                            width: 75,
                            child: Text(
                              '\$${itemTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Discount & Tax Inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotals(),
                    decoration: InputDecoration(
                      labelText: 'Discount (\$)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotals(),
                    decoration: InputDecoration(
                      labelText: 'Tax (\$)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Financial Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        '\$ ${_subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '\$ ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes Input
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Update Purchase',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

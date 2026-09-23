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
    // ១. ឆែកមើលក្នុង List បច្ចុប្បន្នមុន
    var matchedProduct = _products.firstWhere(
      (p) => p['barcode']?.toString() == barcode,
      orElse: () => {},
    );

    // ២. បើរកមិនឃើញក្នុង List ទេ ព្យាយាមឆែកក្នុង Local Hive Box (Offline Mode)
    if (matchedProduct.isEmpty) {
      try {
        var box = Hive.box('offline_products');
        var cachedProduct = box.get(barcode);
        if (cachedProduct != null) {
          matchedProduct = Map<String, dynamic>.from(cachedProduct);
        }
      } catch (e) {
        print("Hive error: $e");
      }
    }

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
            'quantity': 1.0,
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
        'រកមិនឃើញផលិតផលដែលមាន Barcode នេះទេ: $barcode',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Create Purchase',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 2.0),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.qr_code_scanner,
                  color: Colors.indigo,
                  size: 25,
                ),
                onPressed: _openScanner,
                tooltip: 'Scan Barcode',
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _purchaseNumberController,
                decoration: InputDecoration(
                  labelText: 'Purchase Number',
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _generatePurchaseNumber,
                    tooltip: 'Generate New Number',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'សូមបញ្ចូល Purchase Number'
                    : null,
              ),
              const SizedBox(height: 16),

              _isLoadingSuppliers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedSupplierId,
                      decoration: InputDecoration(
                        labelText: 'Select Supplier',
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      hint: const Text('Choose a supplier'),
                      items: _suppliers.map<DropdownMenuItem<String>>((
                        supplier,
                      ) {
                        return DropdownMenuItem<String>(
                          value: supplier['id'].toString(),
                          child: Text(supplier['name'] ?? 'Supplier Name'),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSupplierId = value),
                      validator: (value) =>
                          value == null ? 'សូមជ្រើសរើស Supplier' : null,
                    ),
              const SizedBox(height: 20),
              const Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Products',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _openScanner,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Scan Barcode'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 📦 Product Dropdown
              _isLoadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedProductId,
                      decoration: InputDecoration(
                        labelText: 'Select Product',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      hint: const Text('Choose a product'),
                      items: _products.map<DropdownMenuItem<String>>((product) {
                        String productName = product['name'] ?? 'Product';
                        String baseUnitName = product['base_unit_name'] ?? '';
                        return DropdownMenuItem<String>(
                          value: product['id'].toString(),
                          child: Text(
                            baseUnitName.isNotEmpty
                                ? '$productName ($baseUnitName)'
                                : productName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProductId = value;
                          var selectedItem = _products.firstWhere(
                            (p) => p['id'].toString() == value,
                            orElse: () => <String, dynamic>{},
                          );
                          if (selectedItem.isNotEmpty) {
                            _selectedProductName = selectedItem['name'];
                            _itemPriceController.text = selectedItem['price']
                                .toString();
                          }
                        });
                      },
                    ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _itemQuantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _itemPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Unit Cost (\$)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _addItemToCart,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_purchaseItems.isNotEmpty) ...[
                const Text(
                  'Selected Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _purchaseItems.length,
                  itemBuilder: (context, index) {
                    final item = _purchaseItems[index];
                    final String? imageUrl = item['image_url'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: Colors.blue.withValues(alpha: 0.1),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.inventory_2_rounded,
                                        color: Colors.indigo,
                                        size: 20,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.indigo,
                                    size: 20,
                                  ),
                          ),
                        ),
                        title: Text(
                          item['product_name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Qty: ${item['quantity']} x \$${item['unit_cost']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${(item['total_price'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateTotals(),
                      decoration: InputDecoration(
                        labelText: 'Discount (\$)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateTotals(),
                      decoration: InputDecoration(
                        labelText: 'Tax (\$)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('\$ ${_subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$ ${_total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Purchase',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}

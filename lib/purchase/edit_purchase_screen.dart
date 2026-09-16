import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_purchase.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';
import '../models/Product.dart';

class EditPurchaseScreen extends StatefulWidget {
  final PurchaseModel purchase; // 👈 ទទួលទិន្នន័យចាស់មក edit

  const EditPurchaseScreen({super.key, required this.purchase});

  @override
  State<EditPurchaseScreen> createState() => _EditPurchaseScreenState();
}

class _EditPurchaseScreenState extends State<EditPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingSuppliers = true;
  bool _isLoadingProducts = true;

  // 🏢 បញ្ជី Supplier & Product
  List<dynamic> _suppliers = [];
  String? _selectedSupplierId;

  List<dynamic> _products = [];
  String? _selectedProductId;
  String? _selectedProductName;

  // Controllers
  late TextEditingController _purchaseNumberController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _taxController;
  late TextEditingController _noteController;

  String _paymentMethod = 'cash';
  String _status = 'completed';
  double _subtotal = 0.0;
  double _total = 0.0;

  final ApiPurchase apiPurchase = ApiPurchase();

  @override
  void initState() {
    super.initState();

    // 📥 ផ្ដល់តម្លៃចាស់ចូលទៅក្នុង Controllers
    _purchaseNumberController = TextEditingController(text: widget.purchase.purchaseNumber ?? '');
    _selectedSupplierId = widget.purchase.supplierId?.toString();
    _paymentMethod = widget.purchase.paymentMethod;
    _status = widget.purchase.status;
    _subtotal = widget.purchase.subtotal;
    _total = widget.purchase.total;

    _discountController = TextEditingController(text: widget.purchase.discount.toString());
    _taxController = TextEditingController(text: widget.purchase.tax.toString());
    _noteController = TextEditingController(text: widget.purchase.notes ?? '');

    // ប្រសិនបើមាន items ចាស់ យកមកទាញដាក់ក្នុង form (ឧទាហរណ៍យក item ដំបូង)
    if (widget.purchase.items != null && widget.purchase.items!.isNotEmpty) {
      final firstItem = widget.purchase.items![0];
      _selectedProductId = firstItem['product_id']?.toString();
      _selectedProductName = firstItem['product_name']?.toString();
      _quantityController = TextEditingController(text: firstItem['quantity']?.toString() ?? '1');
      _priceController = TextEditingController(text: firstItem['unit_cost']?.toString() ?? '0');
    } else {
      _quantityController = TextEditingController(text: '1');
      _priceController = TextEditingController(text: '0');
    }

    _fetchSuppliers();
    _fetchProducts();
  }

  Future<void> _fetchSuppliers() async {
    try {
      List<Supplier> suppliersList = await apiPurchase.getAllSuppliers();
      setState(() {
        _suppliers = suppliersList.map((s) => {'id': s.id, 'name': s.name}).toList();
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
        _products = productsList.map((p) => {
          'id': p.id,
          'name': p.name,
          'price': p.costPrice,
          'base_unit_name': p.unitName,
        }).toList();
        _isLoadingProducts = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  void _calculateTotals() {
    double qty = double.tryParse(_quantityController.text) ?? 0;
    double price = double.tryParse(_priceController.text) ?? 0;
    double discount = double.tryParse(_discountController.text) ?? 0;
    double tax = double.tryParse(_taxController.text) ?? 0;

    setState(() {
      _subtotal = qty * price;
      _total = (_subtotal - discount) + tax;
      if (_total < 0) _total = 0;
    });
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSupplierId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('សូមជ្រើសរើស Supplier')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
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
          'notes': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          'items': [
            {
              'product_id': _selectedProductId,
              'product_name': _selectedProductName ?? 'Unknown Product',
              'unit_cost': double.tryParse(_priceController.text) ?? 0,
              'quantity': double.tryParse(_quantityController.text) ?? 0,
              'total_price': _subtotal,
            },
          ],
        };

        bool success = await apiPurchase.updatePurchase(
          widget.purchase.id,
          PurchaseModel.fromJson(purchaseDataMap),
        );

        setState(() => _isLoading = false);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Purchase updated successfully!')),
            );
            Navigator.pop(context, true); // Return true ដើម្បីបញ្ជាក់ថាបាន Update រร็จ
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update purchase')),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _purchaseNumberController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
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
          'Edit Purchase',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'សូមបញ្ចូល Purchase Number' : null,
              ),
              const SizedBox(height: 16),

              // Supplier Dropdown
              _isLoadingSuppliers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                value: _selectedSupplierId,
                decoration: InputDecoration(
                  labelText: 'Select Supplier',
                  prefixIcon: const Icon(Icons.business_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _suppliers.map<DropdownMenuItem<String>>((supplier) {
                  return DropdownMenuItem<String>(
                    value: supplier['id'].toString(),
                    child: Text(supplier['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSupplierId = val),
                validator: (val) => val == null ? 'សូមជ្រើសរើស Supplier' : null,
              ),
              const SizedBox(height: 16),

              // Product Dropdown
              _isLoadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                value: _selectedProductId,
                decoration: InputDecoration(
                  labelText: 'Select Product',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _products.map<DropdownMenuItem<String>>((product) {
                  return DropdownMenuItem<String>(
                    value: product['id'].toString(),
                    child: Text(product['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedProductId = val;
                    var selected = _products.firstWhere((p) => p['id'].toString() == val);
                    _selectedProductName = selected['name'];
                    _priceController.text = selected['price'].toString();
                    _calculateTotals();
                  });
                },
                validator: (val) => val == null ? 'សូមជ្រើសរើសទំនិញ' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateTotals(),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'បញ្ចូលចំនួន' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateTotals(),
                      decoration: InputDecoration(
                        labelText: 'Unit Cost (\$)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'បញ្ចូលតម្លៃ' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateTotals(),
                      decoration: InputDecoration(
                        labelText: 'Discount (\$)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Totals Box
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
                        const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '\$ ${_total.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade700),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Update Purchase',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
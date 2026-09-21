import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_inventory/api/api_brand.dart';
import 'package:pos_inventory/api/api_category.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/models/Product.dart';

import '../msg/appSnackBar.dart';

class ProductUpdateScreen extends StatefulWidget {
  final Product product;

  const ProductUpdateScreen({super.key, required this.product});

  @override
  State<ProductUpdateScreen> createState() => _ProductUpdateScreenState();
}

class _ProductUpdateScreenState extends State<ProductUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final ApiProduct apiProduct = ApiProduct();
  final ApiCategory apiCategory = ApiCategory();
  final ApiBrand apiBrand = ApiBrand();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockQuantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryIdController;
  late TextEditingController _unitIdController;
  late TextEditingController _brandIdController;

  File? _selectedImage;
  bool _isLoading = false;
  List<dynamic> _categories = [];
  List<dynamic> _units = [];
  List<dynamic> _brand = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _skuController = TextEditingController(text: widget.product.sku);
    _barcodeController = TextEditingController(
      text: widget.product.barcode ?? '',
    );
    _costPriceController = TextEditingController(
      text: widget.product.costPrice.toString(),
    );
    _sellingPriceController = TextEditingController(
      text: widget.product.sellingPrice.toString(),
    );
    _stockQuantityController = TextEditingController(
      text: widget.product.stockQuantity.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.product.description ?? '',
    );
    _categoryIdController = TextEditingController(
      text: widget.product.categoryId.toString(),
    );

    _unitIdController = TextEditingController(
      text: (widget.product.unitId ?? 1).toString(),
    );

    _brandIdController = TextEditingController(
      text: widget.product.brandId.toString(),
    );

    _fetchCategories();
    _fetchBrand();
    _fetchUnits();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockQuantityController.dispose();
    _descriptionController.dispose();
    _categoryIdController.dispose();
    _unitIdController.dispose();
    _brandIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await apiCategory.fetchCategory();
      setState(() => _categories = data);
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> _fetchUnits() async {
    try {
      final data = await apiProduct.fetchUnits();
      setState(() => _units = data);
    } catch (e) {
      debugPrint("Error fetching units: $e");
    }
  }

  Future<void> _fetchBrand() async {
    try {
      final data = await apiBrand.fetchBrands();
      setState(() => _brand = data);
    } catch (e) {
      debugPrint("Error fetching brand: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxHeight: 1200,
      maxWidth: 1200,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> productData = {
      'id': widget.product.id,
      'name': _nameController.text,
      'sku': _skuController.text,
      'barcode': _barcodeController.text,
      'cost_price': double.tryParse(_costPriceController.text) ?? 0.0,
      'selling_price': double.tryParse(_sellingPriceController.text) ?? 0.0,
      'stock_quantity': double.tryParse(_stockQuantityController.text) ?? 0.0,
      'category_id': _categoryIdController.text,
      'brand_id': _brandIdController.text,
      'unit_id': _unitIdController.text,
      'description': _descriptionController.text,
      'image': _selectedImage,
    };

    Map<String, dynamic> result = await apiProduct.updateProduct(productData);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        AppSnackBar.showSuccess(
          context,
          result['message'] ?? 'Updated successfully!',
        );
        Navigator.pop(context, true);
      } else {
        AppSnackBar.showError(context, result['message'] ?? 'Update failed!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          "Update Product",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 🌟 1. Premium Large Image Banner Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Product Image",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickImage,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: const Color(0xFFF1F5F9),
                                    child: _selectedImage != null
                                        ? Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : (widget.product.imageUrl != null &&
                                                  widget
                                                      .product
                                                      .imageUrl!
                                                      .isNotEmpty
                                              ? Image.network(
                                                  widget.product.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          size: 40,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                )),
                                  ),

                                  // 🌟 Dark Overlay ពេលយក Mouse ឬដៃတို့មើលទៅរលោងស្អាត
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.black.withOpacity(0.2),
                                  ),

                                  // 📷 Floating Camera Icon Button (រាងមូលតូចល្មម មានសោភ័ណភាពខ្ពស់)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Change Photo",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 14),

                    // 📝 2. General Information Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "General Information",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration(
                              'Product Name',
                              Icons.shopping_bag_outlined,
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Product name is required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _skuController,
                            decoration: _inputDecoration(
                              'SKU Code',
                              Icons.qr_code_scanner,
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'SKU is required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _barcodeController,
                            decoration: _inputDecoration(
                              'Barcode (Optional)',
                              Icons.qr_code,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 💰 3. Pricing & Inventory Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Pricing & Inventory",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _costPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _inputDecoration(
                                    'Cost Price (\$)',
                                    Icons.money_off,
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _sellingPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _inputDecoration(
                                    'Selling Price (\$)',
                                    Icons.attach_money,
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _stockQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              'Stock Quantity',
                              Icons.inventory_2_outlined,
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 🗂️ 4. Organization Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Organization",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Category Dropdown
                          DropdownButtonFormField<String>(
                            value:
                                _categories.any(
                                  (cat) =>
                                      cat['id'].toString() ==
                                      _categoryIdController.text,
                                )
                                ? _categoryIdController.text
                                : null,
                            decoration: _inputDecoration(
                              'Category',
                              Icons.category_outlined,
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat['id'].toString(),
                                child: Text(cat['name'].toString()),
                              );
                            }).toList(),
                            onChanged: (value) => setState(
                              () => _categoryIdController.text = value!,
                            ),
                            validator: (value) => value == null
                                ? 'Please select a category'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Brand Dropdown
                          DropdownButtonFormField<String>(
                            value:
                                _brand.any(
                                  (cat) =>
                                      cat.id.toString() ==
                                      _brandIdController.text,
                                )
                                ? _brandIdController.text
                                : null,
                            decoration: _inputDecoration(
                              'Brand',
                              Icons.branding_watermark_outlined,
                            ),
                            items: _brand.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id.toString(),
                                child: Text(cat.name.toString()),
                              );
                            }).toList(),
                            onChanged: (value) => setState(
                              () => _brandIdController.text = value!,
                            ),
                            validator: (value) =>
                                value == null ? 'Please select a brand' : null,
                          ),
                          const SizedBox(height: 14),

                          // Unit Dropdown
                          DropdownButtonFormField<String>(
                            value:
                                _units.any(
                                  (unit) =>
                                      unit['id'].toString() ==
                                      _unitIdController.text,
                                )
                                ? _unitIdController.text
                                : null,
                            decoration: _inputDecoration(
                              'Unit',
                              Icons.straighten_outlined,
                            ),
                            items: _units.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit['id'].toString(),
                                child: Text(
                                  "${unit['name']} (${unit['short_name'] ?? ''})",
                                ),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _unitIdController.text = value!),
                            validator: (value) =>
                                value == null ? 'Please select a unit' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 📝 5. Additional Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Additional Details",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              'Description (Optional)',
                              Icons.description_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 💾 Save Button
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _updateProduct,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }
}

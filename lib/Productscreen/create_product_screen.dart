import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_inventory/api/api_brand.dart';
import 'package:pos_inventory/api/api_category.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/Product.dart';
import '../msg/appSnackBar.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedCategoryId;
  int? _selectedUnitId;
  int? _selectedBrandId;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _stockQuantityController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ApiProduct apiProduct = ApiProduct();

  @override
  void initState() {
    super.initState();
    _stockQuantityController.text = "0";
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
    super.dispose();
  }

  Future<void> _getImages() async {
    try {
      final List<XFile> pickedFile = await _picker.pickMultiImage(
        requestFullMetadata: true,
        imageQuality: 90,
        maxHeight: 1200,
        maxWidth: 1200,
      );

      if (pickedFile.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFile);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No image selected')));
        }
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _generateSku() {
    final now = DateTime.now();
    final randomNum = (1000 + (DateTime.now().millisecond % 9000));
    setState(() {
      _skuController.text =
          "SKU-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$randomNum";
    });
  }

  void _generateBarcode() {
    int randomNum =
        10000000 + (DateTime.now().microsecondsSinceEpoch % 90000000);
    setState(() {
      _barcodeController.text = 'P-$randomNum';
    });
  }

  Future<void> cacheProductsToLocal() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        List<Product> products = await apiProduct.fetchProducts();
        var box = Hive.box('offline_products');
        await box.clear();

        for (var product in products) {
          box.put(product.barcode, product.toJson());
        }
        print("✅ Cached products successfully for offline mode!");
      } catch (e) {
        print("Error caching products: $e");
      }
    }
  }

  void _scanBarcode() {
    final MobileScannerController scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text(
              'Scan Product Barcode',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: scannerController,
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
                      onPressed: () => scannerController.toggleTorch(),
                    );
                  },
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: scannerController,
                onDetect: (capture) async {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      final scannedCode = barcode.rawValue!.trim();

                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      setState(() {
                        _barcodeController.text = scannedCode;
                      });
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircularProgressIndicator(
                                  color: Color(0xFF2563EB),
                                  strokeWidth: 2.5,
                                ),
                                SizedBox(width: 16),
                                Text(
                                  "កំពុងស្វែងរកទិន្នន័យ...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      // 3️⃣ ឆែកមើលក្នុង API ខាងក្រៅ
                      final publicProduct = await apiProduct
                          .fetchProductInfoFromPublicBarcode(scannedCode);

                      if (mounted) Navigator.pop(context);

                      if (publicProduct != null &&
                          publicProduct['name'] != null) {
                        setState(() {
                          _nameController.text = publicProduct['name'];
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '✨ បានទាញយកឈ្មោះផលិតផលពីប្រព័ន្ធខាងក្រៅជោគជ័យ!',
                              ),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          _showQuickAddProductDialog(scannedCode);
                        }
                      }

                      break;
                    }
                  }
                },
              ),

              // 🔲 Scan Frame Overlay
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 260,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 3.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.3),
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
                        'ដាក់ Barcode ឲ្យចំក្នុងស៊ុមដើម្បីស្កេន',
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
            ],
          ),
        ),
      ),
    );
  }

  // 💡 មុខងារបង្ហាញ Dialog ឱ្យបញ្ចូលឈ្មោះផលិតផលថ្មីភ្លាមៗ ពេលស្កេនចំ Barcode គ្មានក្នុងប្រព័ន្ធ
  void _showQuickAddProductDialog(String barcode) {
    final TextEditingController quickNameController = TextEditingController();
    final TextEditingController quickPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_shopping_cart,
                color: Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'រកមិនឃើញទំនិញ (New Product)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Barcode: $barcode',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quickNameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Product Name',
                hintText: 'បញ្ចូលឈ្មោះទំនិញថ្មី...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quickPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Selling Price (\$)',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('បោះបង់', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (quickNameController.text.trim().isNotEmpty) {
                setState(() {
                  _nameController.text = quickNameController.text.trim();
                  if (quickPriceController.text.trim().isNotEmpty) {
                    _sellingPriceController.text = quickPriceController.text
                        .trim();
                  }
                });
                Navigator.pop(context);
                AppSnackBar.showSuccess(
                  context,
                  'បានបញ្ចូលឈ្មោះទំនិញថ្មីដោយជោគជ័យ!',
                );
              } else {
                AppSnackBar.showError(context, 'សូមបញ្ចូលឈ្មោះទំនិញ!');
              }
            },
            child: const Text('យល់ព្រម', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );

      Map<String, dynamic> productData = {
        'category_id': _selectedCategoryId,
        'unit_id': _selectedUnitId,
        'brand_id': _selectedBrandId,
        'name': _nameController.text,
        'sku': _skuController.text,
        'barcode': _barcodeController.text.isNotEmpty
            ? _barcodeController.text
            : null,
        'cost_price': double.parse(_costPriceController.text),
        'selling_price': double.parse(_sellingPriceController.text),
        'stock_quantity': double.parse(_stockQuantityController.text),
        'description': _descriptionController.text,
        'image': _selectedImages.isNotEmpty ? _selectedImages[0].path : null,
      };

      Map<String, dynamic> result = await apiProduct.createProduct(productData);

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        _showSuccessDialog(
          result['message'] ?? 'Product created successfully!',
          onClose: () {
            Navigator.pop(context, true);
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create product'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String message, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Success!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (onClose != null) onClose();
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: const Text(
          "Create Product",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              onPressed: _scanBarcode,
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFF2563EB),
                size: 24,
              ),
              tooltip: 'Scan Barcode',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 1. Image Banner Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    const Text(
                      "Product Image (Optional)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _getImages,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              color: const Color(0xFFF1F5F9),
                              child: _selectedImages.isNotEmpty
                                  ? Image.file(
                                      File(_selectedImages[0].path),
                                      fit: BoxFit.cover,
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF2563EB,
                                            ).withValues(alpha: 0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_a_photo_rounded,
                                            size: 30,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          "Tap to choose product image",
                                          style: TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            if (_selectedImages.isNotEmpty)
                              Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.black.withValues(alpha: 0.25),
                              ),
                            if (_selectedImages.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
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
              const SizedBox(height: 16),

              // 📝 2. General Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    const Text(
                      "General Information",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: "Product Name",
                      icon: Icons.shopping_bag_outlined,
                    ),
                    const SizedBox(height: 14),

                    // SKU Field
                    TextFormField(
                      controller: _skuController,
                      decoration: _inputDecorationWithAction(
                        label: 'SKU Code',
                        icon: Icons.qr_code_scanner,
                        actionLabel: 'Generate',
                        onActionPressed: _generateSku,
                      ),
                      validator: (v) => v!.isEmpty ? 'SKU is required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Barcode Field
                    TextFormField(
                      controller: _barcodeController,
                      decoration: _inputDecorationWithAction(
                        label: 'Barcode (Optional)',
                        icon: Icons.qr_code,
                        actionLabel: 'Generate',
                        onActionPressed: _generateBarcode,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _costPriceController,
                            label: "Cost Price (\$)",
                            icon: Icons.money_off,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _sellingPriceController,
                            label: "Selling Price (\$)",
                            icon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🗂️ 3. Organization Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    FutureBuilder<List<dynamic>>(
                      future: ApiCategory().fetchCategory(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        final categoryList = snapshot.data ?? [];
                        return DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: _inputDecoration(
                            "Select Category",
                            Icons.category_outlined,
                          ),
                          items: categoryList.map((category) {
                            return DropdownMenuItem<int>(
                              value: category['id'],
                              child: Text(category['name'].toString()),
                            );
                          }).toList(),
                          validator: (value) =>
                              value == null ? 'Please select a category' : null,
                          onChanged: (int? newValue) =>
                              setState(() => _selectedCategoryId = newValue),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Brand Dropdown
                    FutureBuilder<List<dynamic>>(
                      future: ApiBrand().fetchBrands(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        final brandList = snapshot.data ?? [];
                        return DropdownButtonFormField<int>(
                          value: _selectedBrandId,
                          decoration: _inputDecoration(
                            "Select Brand",
                            Icons.branding_watermark_outlined,
                          ),
                          items: brandList.map((brand) {
                            return DropdownMenuItem<int>(
                              value: brand.id,
                              child: Text(brand.name.toString()),
                            );
                          }).toList(),
                          validator: (value) =>
                              value == null ? 'Please select a brand' : null,
                          onChanged: (int? newValue) =>
                              setState(() => _selectedBrandId = newValue),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Unit Dropdown
                    FutureBuilder<List<dynamic>>(
                      future: ApiProduct().fetchUnits(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        final unitList = snapshot.data ?? [];
                        return DropdownButtonFormField<int>(
                          value: _selectedUnitId,
                          decoration: _inputDecoration(
                            "Select Unit (e.g. Pcs, Box)",
                            Icons.straighten,
                          ),
                          items: unitList.map((unit) {
                            return DropdownMenuItem<int>(
                              value: unit['id'],
                              child: Text(
                                "${unit['name']} (${unit['short_name'] ?? ''})",
                              ),
                            );
                          }).toList(),
                          validator: (value) =>
                              value == null ? 'Please select a unit' : null,
                          onChanged: (int? newValue) =>
                              setState(() => _selectedUnitId = newValue),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 📝 4. Additional Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    const Text(
                      "Additional Details",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: "Description (Optional)",
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      isRequired: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 💾 Save Button
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
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
                  onPressed: _submitProduct,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Save Product",
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
              const SizedBox(height: 30),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  InputDecoration _inputDecorationWithAction({
    required String label,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onActionPressed,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      suffixIcon: TextButton.icon(
        onPressed: onActionPressed,
        icon: const Icon(
          Icons.auto_awesome,
          size: 14,
          color: Color(0xFF2563EB),
        ),
        label: Text(
          actionLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      decoration: _inputDecoration(label, icon),
    );
  }
}

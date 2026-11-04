import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos_inventory/Productscreen/scanncheck/scanner_screen.dart';
import 'package:pos_inventory/api/api_brand.dart';
import 'package:pos_inventory/api/api_category.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/Product.dart';
import '../models/category.dart';
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
  final TextEditingController _alertQuantityController =
      TextEditingController();
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

  Future<void> _getImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxHeight: 1200,
        maxWidth: 1200,
      );

      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('មិនមានរូបភាពបានថតទេ')));
        }
      }
    } catch (e) {
      debugPrint("Error capturing image: $e");
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // 🟢 អនុញ្ញាតឱ្យយើងគ្រប់គ្រងកម្ពស់និងទីតាំងបានល្អជាងមុន
      backgroundColor:
          Colors.transparent, // ធ្វើឱ្យផ្ទៃខាងក្រោយថ្លា ដើម្បីបង្ហាញកោងស្អាត
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(
            16.0,
          ), // 🟢 ធ្វើឱ្យវាអណ្តែតឡើងលើបន្តិច និងមានគន្លាតពីគែមទាំងសងខាង
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF2563EB),
                  ),
                  title: const Text(
                    'Camera',
                    style: TextStyle(
                      fontFamily: 'KantumruyPro',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _getImageFromCamera();
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF2563EB),
                  ),
                  title: const Text(
                    'Gallery',
                    style: TextStyle(
                      fontFamily: 'KantumruyPro',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _getImages();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
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
  //
  // // 📂 Categories Offline Aware
  // Future<List<dynamic>> _fetchCategoriesOfflineAware() async {
  //   var connectivityResult = await Connectivity().checkConnectivity();
  //   var box = Hive.box('offline_categories');
  //
  //   if (connectivityResult != ConnectivityResult.none) {
  //     try {
  //       List<dynamic> categories = await ApiCategory().fetchCategory();
  //       await box.clear();
  //       await box.put('categories_data', categories);
  //       return categories;
  //     } catch (e) {
  //       debugPrint("Error fetching categories from API, fallback to local: $e");
  //     }
  //   }
  //
  //   var localData = box.get('categories_data');
  //   if (localData != null) {
  //     return List<dynamic>.from(localData);
  //   }
  //   return [];
  // }


// 📂 Categories Offline Aware (For older connectivity_plus version)
  Future<List<CategoryModel>> _fetchCategoriesOfflineAware() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    var box = Hive.box('offline_categories');
    if (connectivityResult != ConnectivityResult.none) {
      try {
        List<CategoryModel> categories = await ApiCategory().fetchCategory();

        await box.clear();
        List<Map<String, dynamic>> jsonList = categories.map((cat) => cat.toJson()).toList();
        await box.put('categories_data', jsonList);

        return categories;
      } catch (e) {
        debugPrint("Error fetching categories from API, fallback to local: $e");
      }
    }

    var localData = box.get('categories_data');
    if (localData != null) {
      List<dynamic> rawList = List<dynamic>.from(localData);
      return rawList.map((json) {
        return CategoryModel.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    }

    return [];
  }

  // 📂 2. Brands Offline Aware
  Future<List<dynamic>> _fetchBrandsOfflineAware() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    var box = Hive.box('offline_brands');

    if (connectivityResult != ConnectivityResult.none) {
      try {
        List<dynamic> brands = await ApiBrand().fetchBrands();
        await box.clear();
        List<Map<String, dynamic>> brandMaps = brands
            .map((b) => {'id': b.id, 'name': b.name})
            .toList();
        await box.put('brands_data', brandMaps);
        return brands;
      } catch (e) {
        debugPrint("Error fetching brands from API, fallback to local: $e");
      }
    }

    var localData = box.get('brands_data');
    if (localData != null) {
      return List<dynamic>.from(localData);
    }
    return [];
  }

  // 📂 3. Units Offline Aware
  Future<List<dynamic>> _fetchUnitsOfflineAware() async {
    var box = Hive.box('offline_units');
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      try {
        List<dynamic> units = await ApiProduct().fetchUnits();
        if (units.isNotEmpty) {
          await box.clear();
          List<Map<String, dynamic>> unitMaps = units
              .map(
                (u) => {
                  'id': u is Map ? u['id'] : u.id,
                  'name': u is Map ? u['name'] : u.name,
                  'short_name': u is Map
                      ? (u['short_name'] ?? '')
                      : (u.shortName ?? ''),
                },
              )
              .toList();

          await box.put('units_data', unitMaps);
          return unitMaps;
        }
      } catch (e) {
        debugPrint("API Error fetching units: $e");
      }
    }

    var localData = box.get('units_data');
    if (localData != null) {
      return List<dynamic>.from(localData);
    }
    return [];
  }

  void _scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _barcodeController.text = scannedCode;
      });

      if (mounted) {
        AppSnackBar.showSuccess(context, '✨ បានស្កេន Barcode ជោគជ័យ!');
      }
    }
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
        'alert_quantity': _alertQuantityController.text.isNotEmpty
            ? _alertQuantityController.text
            : '5',
        'description': _descriptionController.text,
        'image': _selectedImages.isNotEmpty ? _selectedImages[0].path : null,
      };
      var connectivityResult = await Connectivity().checkConnectivity();
      bool isOffline = (connectivityResult == ConnectivityResult.none);

      if (isOffline) {
        try {
          var offlineBox = Hive.box('offline_pending_products');
          String key = _barcodeController.text.isNotEmpty
              ? _barcodeController.text
              : _skuController.text;
          await offlineBox.put(key, productData);

          if (mounted) Navigator.pop(context);

          if (mounted) {
            _showSuccessDialog(
              '⚠️ គ្មានអ៉ីនធឺណិត! ផលិតផលត្រូវបានរក្សាទុកក្នុង Offline ជោគជ័យ។',
              onClose: () {
                Navigator.pop(context, true);
              },
            );
          }
        } catch (e) {
          if (mounted) Navigator.pop(context);
          debugPrint("Error saving offline product to Hive: $e");
        }
      } else {
        Map<String, dynamic> result = await apiProduct.createProduct(
          productData,
        );

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
                  color: Colors.green.withOpacity(0.1),
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
              // 🌟 Image Banner Section
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
                      "Product Image (Optional)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showImageSourceActionSheet,
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
                                            ).withOpacity(0.08),
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
                                color: Colors.black.withOpacity(0.25),
                              ),
                            if (_selectedImages.isNotEmpty)
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
              const SizedBox(height: 16),

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
                      decoration: InputDecoration(
                        labelText: 'Barcode (Optional)',
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.qr_code,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _scanBarcode,
                              icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Color(0xFF2563EB),
                                size: 22,
                              ),
                              tooltip: 'Scan Barcode',
                            ),
                            Container(
                              height: 20,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            // ✨ ប៊ូតុង Generate ដើម
                            TextButton.icon(
                              onPressed: _generateBarcode,
                              icon: const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: Color(0xFF2563EB),
                              ),
                              label: const Text(
                                'Generate',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
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
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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


              // 🗂️ 3. Organization Card (គាំទ្រ Offline Mode ຜ່ານ Hive)
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

                    FutureBuilder<List<CategoryModel>>(
                      future: _fetchCategoriesOfflineAware(),
                      builder: (context, snapshot) {
                        final categoryList = snapshot.data ?? [];
                        return DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: _inputDecoration(
                            "Select Category",
                            Icons.category_outlined,
                          ),
                          items: categoryList.map((category) {
                            return DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
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

                    FutureBuilder<List<dynamic>>(
                      future: _fetchBrandsOfflineAware(),
                      builder: (context, snapshot) {
                        final brandList = snapshot.data ?? [];
                        return DropdownButtonFormField<int>(
                          value: _selectedBrandId,
                          decoration: _inputDecoration(
                            "Select Brand",
                            Icons.branding_watermark_outlined,
                          ),
                          items: brandList.map((brand) {
                            var id = brand is Map ? brand['id'] : brand.id;
                            var name = brand is Map
                                ? brand['name']
                                : brand.name;
                            return DropdownMenuItem<int>(
                              value: id is int ? id : int.parse(id.toString()),
                              child: Text(name.toString()),
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
                      future: _fetchUnitsOfflineAware(),
                      builder: (context, snapshot) {
                        final unitList = snapshot.data ?? [];
                        return DropdownButtonFormField<int>(
                          value: _selectedUnitId,
                          decoration: _inputDecoration(
                            "Select Unit",
                            Icons.straighten,
                          ),
                          items: unitList.map((unit) {
                            var id = unit is Map ? unit['id'] : unit.id;
                            var name = unit is Map ? unit['name'] : unit.name;
                            var shortName = unit is Map
                                ? (unit['short_name'] ?? '')
                                : (unit.shortName ?? '');

                            return DropdownMenuItem<int>(
                              value: id is int ? id : int.parse(id.toString()),
                              child: Text("$name"),
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

              // 📝 4. Additional Details Card (រួមបញ្ចូលទាំង Alert Quantity និង Description)
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
                      "Inventory Alerts & Details",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🟢 ô បញ្ចូលចំនួន Alert Quantity
                    _buildTextField(
                      controller: _alertQuantityController,
                      label: "Alert Quantity (e.g. Low stock warning)",
                      icon: Icons.notifications_active_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      isRequired: false,
                    ),
                    const SizedBox(height: 14),

                    // Description Field ដើម
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
                      color: const Color(0xFF2563EB).withOpacity(0.35),
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

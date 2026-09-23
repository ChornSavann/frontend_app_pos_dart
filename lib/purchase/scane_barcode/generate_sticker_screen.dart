import 'package:flutter/material.dart';
import 'package:barcode/barcode.dart' as bc;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_inventory/api/api_product.dart';
import 'package:printing/printing.dart';
import 'package:pos_inventory/models/Product.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';

class GenerateStickerScreen extends StatefulWidget {
  final List<dynamic>? products;
  const GenerateStickerScreen({super.key, this.products});

  @override
  State<GenerateStickerScreen> createState() => _GenerateStickerScreenState();
}

class _GenerateStickerScreenState extends State<GenerateStickerScreen> {
  final Map<String, int> _selectedProductsToPrint = {};
  List<dynamic> _productList = [];
  List<dynamic> _filteredProductList = [];
  bool _isLoading = true;

  double _stickerWidth = 40;
  double _stickerHeight = 30;

  final TextEditingController _searchController = TextEditingController();
  final ApiProduct _apiProduct = ApiProduct();

  @override
  void initState() {
    super.initState();
    if (widget.products == null || widget.products!.isEmpty) {
      _fetchProductsFromApi();
    } else {
      _productList = widget.products!;
      _filteredProductList = _productList;
      _isLoading = false;
    }
  }

  Future<void> _fetchProductsFromApi() async {
    try {
      List<Product> productsList = await _apiProduct.fetchProducts();
      setState(() {
        _productList = productsList
            .map(
              (p) => {
                'id': p.id.toString(),
                'name': p.name,
                'price': p.sellingPrice ?? 0.0,
                'barcode': p.barcode ?? '12345678',
                'image_url': p.imageUrl,
              },
            )
            .toList();
        _filteredProductList = _productList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackBar.showError(context, 'Error loading products: $e');
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProductList = _productList;
      } else {
        _filteredProductList = _productList.where((product) {
          final name = product['name'].toString().toLowerCase();
          final barcode = product['barcode'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || barcode.contains(searchLower);
        }).toList();
      }
    });
  }


  void _clearAllSelections() {
    setState(() {
      _selectedProductsToPrint.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalSelectedCount = _selectedProductsToPrint.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Generate Barcode Stickers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (totalSelectedCount > 0)
            TextButton.icon(
              onPressed: _clearAllSelections,
              icon: const Icon(
                Icons.clear_all_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              label: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sticker Size:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Small (40x30mm)'),
                        selected: _stickerWidth == 40,
                        selectedColor: Colors.indigo.shade100,
                        labelStyle: TextStyle(
                          color: _stickerWidth == 40
                              ? Colors.indigo.shade900
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _stickerWidth = 40;
                            _stickerHeight = 30;
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Medium (50x25mm)'),
                        selected: _stickerWidth == 50,
                        selectedColor: Colors.indigo.shade100,
                        labelStyle: TextStyle(
                          color: _stickerWidth == 50
                              ? Colors.indigo.shade900
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _stickerWidth = 50;
                            _stickerHeight = 25;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 🔍 Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _filterProducts,
                  decoration: InputDecoration(
                    hintText: 'Search by product name or barcode...',
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.indigo,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProductList.isEmpty
                ? const Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredProductList.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProductList[index];
                      String productId = product['id'].toString();
                      String productName = product['name'] ?? 'Unknown';
                      String price = product['price']?.toString() ?? '0.00';
                      String barcode = product['barcode'] ?? 'N/A';
                      String? imageUrl = product['image_url'];
                      int qty = _selectedProductsToPrint[productId] ?? 0;
                      bool isSelected = qty > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.indigo.shade300
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedProductsToPrint.remove(productId);
                              } else {
                                _selectedProductsToPrint[productId] = 1;
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // 🟢 Checkbox សម្រាប់ Select
                                Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.indigo,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedProductsToPrint[productId] = 1;
                                      } else {
                                        _selectedProductsToPrint.remove(
                                          productId,
                                        );
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),

                                // 🟢 រូបភាពផលិតផល
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.indigo.withValues(
                                      alpha: 0.08,
                                    ),
                                    child:
                                        imageUrl != null && imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.inventory_2_rounded,
                                                    color: Colors.indigo,
                                                    size: 22,
                                                  );
                                                },
                                          )
                                        : const Icon(
                                            Icons.inventory_2_rounded,
                                            color: Colors.indigo,
                                            size: 22,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 🟢 ឈ្មោះ និងព័ត៌មានផលិតផល
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Price: \$$price  |  Barcode: $barcode',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSelected)
                                  SizedBox(
                                    width: 75,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Copies',
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      controller: TextEditingController(
                                        text: qty.toString(),
                                      ),
                                      onChanged: (val) {
                                        int parsed = int.tryParse(val) ?? 1;
                                        _selectedProductsToPrint[productId] =
                                            parsed > 0 ? parsed : 1;
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 🖨️ ប៊ូតុងបញ្ជាព្រីនស្ទីគ័រ
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: totalSelectedCount > 0 ? 4 : 0,
                  shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.print_rounded, size: 22),
                label: Text(
                  totalSelectedCount > 0
                      ? 'Print Barcode Stickers ($totalSelectedCount)'
                      : 'Print Barcode Stickers',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                onPressed: totalSelectedCount == 0
                    ? null
                    : () => _printStickersPdf(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🖨️ មុខងារគូរ PDF Sticker និង Preview មុនពេលព្រីន
  Future<void> _printStickersPdf() async {
    final pdf = pw.Document();

    List<Map<String, dynamic>> itemsToPrint = [];
    _selectedProductsToPrint.forEach((productId, count) {
      var product = _productList.firstWhere(
        (p) => p['id'].toString() == productId,
      );
      for (int i = 0; i < count; i++) {
        itemsToPrint.add(product);
      }
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: itemsToPrint.map((item) {
              String barcodeVal = item['barcode'] ?? '12345678';
              return pw.Container(
                width: _stickerWidth * 2.83,
                height: _stickerHeight * 2.83,
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      item['name'],
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '\$${item['price']}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 4),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: barcodeVal,
                      height: 22,
                      width: 75,
                      textStyle: const pw.TextStyle(fontSize: 6),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}

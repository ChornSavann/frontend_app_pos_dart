import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/Productscreen/create_product_screen.dart';
import 'package:pos_inventory/Productscreen/product_update_screen.dart';
import 'package:pos_inventory/Productscreen/show_product_id_screen.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/homesccreeen/dashboard_screen.dart';
import 'package:pos_inventory/models/Product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../purchase/scane_barcode/generate_sticker_screen.dart';
import 'offline/0ffline_sync_screen.dart';

class ProductIndexScreen extends StatefulWidget {
  const ProductIndexScreen({super.key});

  @override
  State<ProductIndexScreen> createState() => _ProductIndexScreenState();
}

class _ProductIndexScreenState extends State<ProductIndexScreen> {
  final ApiProduct apiProduct = ApiProduct();
  late Future<List<Product>> _futureProducts;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshProductList();
  }

  void _refreshProductList() {
    setState(() {
      _futureProducts = apiProduct.fetchProducts();
    });
  }

  Future<void> _exportProductsAsPDF(List<Product> products) async {
    try {
      final pdf = pw.Document();

      final String currentDate =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),

          // 🦶 Footer សម្រាប់លេខទំព័រ
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            );
          },

          build: (pw.Context context) {
            return [
              // 🌟 Header Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PRODUCT INVENTORY REPORT',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Comprehensive stock status and pricing details',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: $currentDate',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.teal100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'Total Items: ${products.length}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.teal800, thickness: 1.2),
              pw.SizedBox(height: 10),

              // 📋 Data Table
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey900,
                ),
                headerHeight: 24,
                cellHeight: 22,

                // 🦓 Zebra Striping ពណ៌ឆ្លាស់គ្នាស្អាត
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.4),
                  ),
                ),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.4),
                  ),
                ),
                cellStyle: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),

                // 📐 កំណត់ Width ឱ្យសមាមាត្រគ្នាដើម្បីកុំឱ្យអក្សរធ្លាក់បន្ទាត់
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.6), // SKU (ឱ្យទទឹងធំបន្តិច)
                  1: const pw.FlexColumnWidth(2.0), // Product Name
                  2: const pw.FlexColumnWidth(1.0), // Category
                  3: const pw.FlexColumnWidth(1.2), // Brand
                  4: const pw.FlexColumnWidth(0.7), // Unit
                  5: const pw.FlexColumnWidth(0.9), // Cost Price
                  6: const pw.FlexColumnWidth(0.9), // Selling Price
                  7: const pw.FlexColumnWidth(0.7), // Stock
                  8: const pw.FlexColumnWidth(1.3), // Barcode
                },

                headers: [
                  'SKU',
                  'Product Name',
                  'Category',
                  'Brand',
                  'Unit',
                  'Cost Price',
                  'Selling Price',
                  'Stock',
                  'Barcode',
                ],

                data: products.map((product) {
                  // Format stock ឱ្យចេញជាចំនួនគត់ បើគ្មានទសភាគ
                  String stockStr = product.stockQuantity % 1 == 0
                      ? product.stockQuantity.toInt().toString()
                      : product.stockQuantity.toString();

                  return [
                    product.sku,
                    product.name,
                    product.categoryName ?? 'N/A',
                    product.brandName ?? 'N/A',
                    product.unitName ?? 'N/A',
                    '\$${product.costPrice.toStringAsFixed(2)}',
                    '\$${product.sellingPrice.toStringAsFixed(2)}',
                    stockStr,
                    product.barcode ?? '-',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Complete_Product_Inventory.pdf");
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: '📦 បញ្ជីស្តុកផលិតផលពេញលេញ (Product Inventory PDF)');
    } catch (e) {
      debugPrint("Error exporting products PDF: $e");
    }
  }


  Future<void> _exportProductsAsCSV(List<Product> products) async {
    try {
      List<String> csvRows = [];
      csvRows.add(
        "ID,SKU,Name,Category,Brand,Unit,Cost Price,Selling Price,Stock Quantity,Barcode,Created At",
      );

      for (var product in products) {
        String line =
            "${product.id},"
            "\"${product.sku}\","
            "\"${product.name}\","
            "\"${product.categoryName ?? ''}\","
            "\"${product.brandName ?? ''}\","
            "\"${product.unitName ?? ''}\","
            "${product.costPrice},"
            "${product.sellingPrice},"
            "${product.stockQuantity},"
            "\"${product.barcode ?? ''}\","
            "\"${product.createdAt ?? ''}\"";
        csvRows.add(line);
      }

      String csvData = csvRows.join("\n");

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Complete_Product_Inventory.csv");
      await file.writeAsString(csvData);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: '📈 បញ្ជីស្តុកផលិតផលពេញលេញ (Excel/CSV Format)');
    } catch (e) {
      debugPrint("Error exporting products CSV: $e");
    }
  }

  void _showExportOptions(BuildContext context, List<Product> products) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Export & Share Products'),
        message: const Text('ជ្រើសរើសទម្រង់ឯកសារដែលចង់ Export'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _exportProductsAsPDF(products);
            },
            child: const Text('Export as PDF Document'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _exportProductsAsCSV(products);
            },
            child: const Text('Export as Excel / CSV'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message, {VoidCallback? onDeleteOrClose}) {
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
                  color: Colors.black87,
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (onDeleteOrClose != null) {
                      onDeleteOrClose();
                    }
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


  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'លុបផលិតផល',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'តើអ្នកពិតជាចង់លុប "${product.name}" មែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => isLoading = true);

                          bool success = await apiProduct.deleteProduct(
                            product.id,
                          );

                          setState(() => isLoading = false);

                          if (!mounted) return;

                          if (success) {
                            _refreshProductList();
                            _showSuccessDialog('លុបផលិតផលជោគជ័យ!');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ការលុបបរាជ័យ!'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white, size: 22),
            tooltip: 'Dashboard',
            onPressed: () async {
              await Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
                    (route) => false,
              );
            },
          ),
          title: const Text(
            "List of Products",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          actions: [
            // 🔍 1. Search Button (បង្ហាញជានិច្ចព្រោះត្រូវប្រើញឹកញាប់)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
              tooltip: 'Search',
              onPressed: () async {
                List<Product> products = await _futureProducts;
                if (!context.mounted) return;

                showSearch(
                  context: context,
                  delegate: ProductSearchDelegate(
                    products,
                    _refreshProductList,
                        (product) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ShowProductIdScreen(productId: product.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // ➕ 2. Add Product Button (បង្ហាញជានិច្ច)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              tooltip: 'Add Product',
              onPressed: () async {
                final isChanged = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateProductScreen(),
                  ),
                );
                if (isChanged == true) {
                  _refreshProductList();
                }
              },
            ),

            // ⚙️ 3. More Menu (ប្រមូលផ្ដុំមុខងារផ្សេងៗដូចជា Sync, Export, Barcode ក្នុងនេះកុំឱ្យញេញ៉ៃ)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 4,
              onSelected: (value) async {
                if (value == 'sync') {
                  final isChanged = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OfflineSyncScreen(),
                    ),
                  );
                  if (isChanged == true) {
                    _refreshProductList();
                  }
                } else if (value == 'export') {
                  List<Product> products = await _futureProducts;
                  if (!context.mounted) return;
                  if (products.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('គ្មានទិន្នន័យផលិតផលសម្រាប់ Export ទេ។'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _showExportOptions(context, products);
                } else if (value == 'barcode') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GenerateStickerScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'sync',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_sync_rounded, color: Color(0xFF4F46E5), size: 20),
                      SizedBox(width: 12),
                      Text('Offline Sync', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.square_arrow_up, color: Color(0xFF4F46E5), size: 20),
                      SizedBox(width: 12),
                      Text('Export & Share', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'barcode',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, color: Color(0xFF4F46E5), size: 20),
                      SizedBox(width: 12),
                      Text('Barcode Stickers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Product>>(
            future: _futureProducts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No products found.",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                final products = snapshot.data!;

                return ListView.builder(
                  itemCount: products.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ShowProductIdScreen(productId: product.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    product.imageUrl != null &&
                                        product.imageUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: product.imageUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade100,
                                            child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Colors.blueAccent,
                                          size: 28,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "\$${product.sellingPrice.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            "SKU: ${product.sku}",
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: product.stockQuantity == 0
                                                ? Colors.red.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : product.stockQuantity <= 10
                                                ? Colors.orange.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.blue.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            "Stock: ${product.stockQuantity}",
                                            style: TextStyle(
                                              color: product.stockQuantity == 0
                                                  ? Colors.red
                                                  : product.stockQuantity <= 10
                                                  ? Colors.orange
                                                  : Colors.blueAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final isChanged = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductUpdateScreen(
                                                product: product,
                                              ),
                                        ),
                                      );
                                      if (isChanged == true) {
                                        _refreshProductList();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue.shade600,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => _confirmDelete(product),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade400,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// 🔎 Search Delegate (Responsive & Safe)
class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;
  final VoidCallback onRefresh;
  final Function(Product) onShowDetail;

  ProductSearchDelegate(this.products, this.onRefresh, this.onShowDetail);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildFilteredList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildFilteredList(context);
  }

  Widget _buildFilteredList(BuildContext context) {
    final filteredList = products.where((product) {
      final nameLower = product.name.toLowerCase();
      final skuLower = product.sku.toLowerCase();
      final searchLower = query.toLowerCase();
      return nameLower.contains(searchLower) || skuLower.contains(searchLower);
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          "រកមិនឃើញផលិតផលនេះទេ",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredList.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (context, index) {
        final product = filteredList[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              close(context, null);
              onShowDetail(product);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.image_not_supported),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.blue.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.blueAccent,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\$${product.sellingPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "SKU: ${product.sku}",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: product.stockQuantity == 0
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : product.stockQuantity <= 10
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Stock: ${product.stockQuantity}",
                                style: TextStyle(
                                  color: product.stockQuantity == 0
                                      ? Colors.red
                                      : product.stockQuantity <= 10
                                      ? Colors.orange
                                      : Colors.blueAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

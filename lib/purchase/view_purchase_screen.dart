import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api/api_purchase.dart';
import '../msg/appSnackBar.dart';

class ViewPurchaseScreen extends StatefulWidget {
  final int purchaseId;

  const ViewPurchaseScreen({super.key, required this.purchaseId});

  @override
  State<ViewPurchaseScreen> createState() => _ViewPurchaseScreenState();
}

class _ViewPurchaseScreenState extends State<ViewPurchaseScreen> {
  // 🌐 កំណត់ URL របស់ Backend Server របស់អ្នកនៅទីនេះ
  final String baseUrl = 'http://10.0.2.2:8000/api';

  bool _isLoading = true;
  Map<String, dynamic>? _purchaseData;
  final ApiPurchase _apiPurchase = ApiPurchase();

  @override
  void initState() {
    super.initState();
    _fetchPurchaseDetail();
  }

  Future<void> _fetchPurchaseDetail() async {
    setState(() => _isLoading = true);

    final responseData = await _apiPurchase.getPurchaseById(widget.purchaseId);

    if (responseData != null && responseData['success'] == true) {
      setState(() {
        _purchaseData = responseData['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      AppSnackBar.showError(context, 'Error: Failed to load purchase details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Purchase Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  color: Colors.black87,
                  onPressed: _fetchPurchaseDetail,
                  tooltip: 'Refresh',
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchaseData == null
          ? const Center(child: Text('No data found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Purchase Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (_purchaseData!['status'] ?? 'N/A')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Purchase Number',
                          (_purchaseData!['purchase_number'] ??
                                  _purchaseData!['purchaseNumber'] ??
                                  'N/A')
                              .toString(),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Supplier Name',
                          ((_purchaseData!['supplier'] is Map &&
                                      _purchaseData!['supplier']['name'] !=
                                          null)
                                  ? _purchaseData!['supplier']['name']
                                  : (_purchaseData!['supplier_name'] ??
                                        _purchaseData!['supplierName'] ??
                                        _purchaseData!['name'] ??
                                        'ID: ${_purchaseData!['supplier_id'] ?? _purchaseData!['supplierId'] ?? 'N/A'}'))
                              .toString(),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Date',
                          (_purchaseData!['date'] ??
                                  _purchaseData!['created_at'] ??
                                  'N/A')
                              .toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🛒 Items List Title
                  const Text(
                    'Purchase Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 📋 List of Items Card
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (_purchaseData!['items'] is List)
                        ? (_purchaseData!['items'] as List).length
                        : 0,
                    itemBuilder: (context, index) {
                      final List itemsList = _purchaseData!['items'] is List
                          ? _purchaseData!['items']
                          : [];
                      final item = itemsList[index];

                      final double qty =
                          double.tryParse((item['quantity'] ?? 0).toString()) ??
                          0.0;
                      final double price =
                          double.tryParse(
                            (item['unit_cost'] ?? 0).toString(),
                          ) ??
                          0.0;
                      final double total =
                          double.tryParse(
                            (item['total_price'] ?? (qty * price)).toString(),
                          ) ??
                          (qty * price);

                      // 🖼️ ទាញយក Link រូបភាព និងបញ្ចូល /storage/ ឱ្យបានត្រឹមត្រូវ
                      String? imageUrl;
                      if (item['product'] is Map) {
                        String? img =
                            item['product']['image'] ??
                            item['product']['image_url'];
                        if (img != null && img.isNotEmpty) {
                          // 🧹 បើ baseUrl មានពាក្យ /api គឺត្រូវកាត់ចេញ ព្រោះរូបភាពមិនស្ថិតក្នុង api route ទេ
                          String baseWithoutApi = baseUrl.endsWith('/api')
                              ? baseUrl.substring(0, baseUrl.length - 4)
                              : (baseUrl.endsWith('/api/')
                                    ? baseUrl.substring(0, baseUrl.length - 5)
                                    : baseUrl);

                          String cleanBaseUrl = baseWithoutApi.endsWith('/')
                              ? baseWithoutApi.substring(
                                  0,
                                  baseWithoutApi.length - 1,
                                )
                              : baseWithoutApi;
                          String cleanImg = img.startsWith('/')
                              ? img.substring(1)
                              : img;

                          imageUrl = cleanImg.startsWith('http')
                              ? cleanImg
                              : "$cleanBaseUrl/$cleanImg";

                          print('🔥 CORRECTED IMAGE URL: $imageUrl');
                        }
                      }
                      print('PRINT ITEM DEBUG: $item');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            // 🖼️ Product Image Container
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl.startsWith('http')
                                            ? imageUrl
                                            : "$baseUrl$imageUrl",
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.image_not_supported,
                                              size: 24,
                                              color: Colors.grey,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.inventory_2_rounded,
                                        color: Colors.indigo,
                                        size: 28,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (item['name'] ??
                                            item['product_name'] ??
                                            item['title'] ??
                                            'Item Name')
                                        .toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${qty % 1 == 0 ? qty.toInt() : qty}  |  Price: \$${price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

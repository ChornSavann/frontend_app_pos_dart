import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';

import '../api/api_purchase.dart';
import '../msg/appSnackBar.dart';

class ViewPurchaseScreen extends StatefulWidget {
  final int purchaseId;

  const ViewPurchaseScreen({super.key, required this.purchaseId});

  @override
  State<ViewPurchaseScreen> createState() => _ViewPurchaseScreenState();
}

class _ViewPurchaseScreenState extends State<ViewPurchaseScreen> {
  final String baseUrl = BaseUrlApi.baseurl;

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

  // Helper សម្រាប់កំណត់ពណ៌ Status Badge
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    // គណនាសរុបទឹកប្រាក់ទំនិញទាំងអស់
    double grandTotal = 0.0;
    if (_purchaseData != null && _purchaseData!['items'] is List) {
      for (var item in _purchaseData!['items']) {
        final double qty =
            double.tryParse((item['quantity'] ?? 0).toString()) ?? 0.0;
        final double price =
            double.tryParse((item['unit_cost'] ?? 0).toString()) ?? 0.0;
        grandTotal +=
            double.tryParse(
              (item['total_price'] ?? (qty * price)).toString(),
            ) ??
            (qty * price);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Purchase Details',
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
                  color: const Color(0xFF1E293B),
                  onPressed: _fetchPurchaseDetail,
                  tooltip: 'Refresh',
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _purchaseData == null
          ? const Center(child: Text('No data found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📄 Purchase Information Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Purchase Information',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  _purchaseData!['status'] ?? 'N/A',
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (_purchaseData!['status'] ?? 'N/A')
                                    .toString()
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(
                                    _purchaseData!['status'] ?? 'N/A',
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                        _buildInfoRow(
                          Icons.confirmation_number_outlined,
                          'Purchase Number',
                          (_purchaseData!['purchase_number'] ??
                                  _purchaseData!['purchaseNumber'] ??
                                  'N/A')
                              .toString(),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.storefront_outlined,
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
                          Icons.calendar_today_outlined,
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
                      color: Color(0xFF1E293B),
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

                      String? imageUrl;
                      if (item['product'] is Map) {
                        String? img =
                            item['product']['image'] ??
                            item['product']['image_url'];
                        if (img != null && img.isNotEmpty) {
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
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            // 🖼️ Product Image Container
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 24,
                                              color: Colors.grey,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.inventory_2_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 26,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
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
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Qty: ${qty % 1 == 0 ? qty.toInt() : qty}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Price: \$${price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 💰 Grand Total Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '\$${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

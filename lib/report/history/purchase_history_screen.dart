import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_purchase.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _purchasesList = [];
  final ApiPurchase _apiPurchase = ApiPurchase();

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiPurchase.getAllPurchaseHistory();
      setState(() {
        _purchasesList = response ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Error fetching purchases: $e");
    }
  }

  void _showPurchaseDetailDialog(Map<String, dynamic> rawData) {
    double totalAmount =
        double.tryParse(
          (rawData['total_amount'] ?? rawData['total'] ?? 0).toString(),
        ) ??
        0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Purchase Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reference: ${rawData['reference_no'] ?? rawData['purchase_no'] ?? 'N/A'}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Supplier: ${rawData['supplier_name'] ?? rawData['supplier']?['name'] ?? 'N/A'}',
                ),
                const SizedBox(height: 8),
                Text('Status: ${rawData['status'] ?? 'Received'}'),
                const SizedBox(height: 8),
                Text(
                  'Date: ${rawData['date'] ?? rawData['created_at'] ?? 'N/A'}',
                ),
                const Divider(height: 20),
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'ប្រវត្តិការទិញចូល (Purchase History)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _purchasesList.isEmpty
          ? const Center(
              child: Text(
                'គ្មានទិន្នន័យប្រវត្តិការទិញចូលទេ',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchPurchases,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _purchasesList.length,
                itemBuilder: (context, index) {
                  final purchase = _purchasesList[index];
                  String refNo =
                      purchase['reference_no'] ??
                      purchase['purchase_no'] ??
                      'PUR-N/A';
                  double amount =
                      double.tryParse(
                        (purchase['total_amount'] ?? purchase['total'] ?? 0)
                            .toString(),
                      ) ??
                      0.0;
                  List items = purchase['details'] ?? purchase['items'] ?? [];
                  String status = purchase['status'] ?? 'Received';
                  String supplierName =
                      purchase['supplier_name'] ??
                      purchase['supplier']?['name'] ??
                      refNo;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Supplier: $supplierName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Items: ${items.length}  •  ${purchase['date'] ?? purchase['created_at'] ?? ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11.5,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showPurchaseDetailDialog(purchase);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

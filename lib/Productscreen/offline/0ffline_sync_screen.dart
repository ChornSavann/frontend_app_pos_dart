import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';

class OfflineSyncScreen extends StatefulWidget {
  const OfflineSyncScreen({super.key});

  @override
  State<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends State<OfflineSyncScreen> {
  final ApiProduct _apiProduct = ApiProduct();
  bool isSyncing = false;
  List<Map<String, dynamic>> offlineProducts = [];

  @override
  void initState() {
    super.initState();
    _loadOfflineProducts();
  }

  void _loadOfflineProducts() {
    try {
      var box = Hive.box('offline_pending_products');
      debugPrint(
        "📦 Total items in offline_pending_products box: ${box.length}",
      );

      List<Map<String, dynamic>> loadedData = [];

      for (var key in box.keys) {
        var value = box.get(key);
        debugPrint("🔑 Key: $key => Value: $value");

        if (value != null) {
          loadedData.add({
            'key': key,
            'data': Map<String, dynamic>.from(value),
          });
        }
      }

      setState(() {
        offlineProducts = loadedData;
      });
    } catch (e) {
      debugPrint("❌ Error loading offline products: $e");
    }
  }

  // 🔄 មុខងារ Sync ផលិតផលក្នុង Pending Queue ឡើងទៅ MySQL
  Future<void> _syncProductsToMySQL() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          '⚠️ គ្មានអ៉ីនធឺណិតទេ! សូមភ្ជាប់ Wi-Fi ឬ Data សិនមុននឹង Sync។',
        );
      }
      return;
    }

    if (offlineProducts.isEmpty) {
      AppSnackBar.showError(context, 'គ្មានទិន្នន័យសម្រាប់ Sync ទេ។');
      return;
    }

    setState(() {
      isSyncing = true;
    });

    var box = Hive.box('offline_pending_products');
    int successCount = 0;
    List<dynamic> keysToRemove = [];

    for (var item in offlineProducts) {
      var key = item['key'];
      Map<String, dynamic> productData = item['data'];

      try {
        Map<String, dynamic> result = await _apiProduct.createProduct(
          productData,
        );

        if (result['success'] == true) {
          successCount++;
          keysToRemove.add(key);
        }
      } catch (e) {
        debugPrint("Failed to sync product key $key: $e");
      }
    }

    for (var key in keysToRemove) {
      await box.delete(key);
    }

    setState(() {
      isSyncing = false;
    });

    _loadOfflineProducts();

    if (mounted) {
      if (successCount > 0) {
        AppSnackBar.showSuccess(
          context,
          '✅ Sync បានជោគជ័យចំនួន $successCount ផលិតផលទៅ MySQL!',
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        AppSnackBar.showError(context, '❌ Sync បរាជ័យ! សូមព្យាយាមម្តងទៀត។');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          title: const Text(
            'Offline Products Sync',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
      ),
      body: Column(
        children: [
          // 📊 Modern Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Offline Items',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${offlineProducts.length} Products',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isSyncing || offlineProducts.isEmpty
                      ? null
                      : _syncProductsToMySQL,
                  icon: isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4F46E5),
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    isSyncing ? 'Syncing...' : 'Sync Now',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // 📋 List View
          Expanded(
            child: offlineProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4F46E5,
                            ).withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_done_rounded,
                            size: 60,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'គ្មានទិន្នន័យកត់ទុកពេល Offline ទេ',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'រាល់ទំនិញបង្កើតថ្មីពេលដាច់អ៉ីនធឺណិតនឹងបង្ហាញនៅទីនេះ',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: offlineProducts.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      var item = offlineProducts[index];
                      Map<String, dynamic> data = item['data'];

                      // 🛡️ Safe check រូបភាព (ការពាររឿង PathNotFoundException)
                      String? imagePath = data['image'];
                      bool isLocalFile =
                          imagePath != null &&
                          !imagePath.startsWith('http') &&
                          File(imagePath).existsSync();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: isLocalFile
                                  ? Image.file(
                                      File(imagePath!),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4F46E5,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_rounded,
                                        color: Color(0xFF4F46E5),
                                        size: 24,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'SKU: ${data['sku']} • Price: \$${data['selling_price']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

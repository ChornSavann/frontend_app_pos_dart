import 'package:flutter/material.dart';

import '../api/api_purchase.dart';
import '../msg/appSnackBar.dart';
import 'create_purchase_screen.dart';

import 'create_purchase_screen.dart';
import 'edit_purchase_screen.dart';
import 'view_purchase_screen.dart';

class IndexPurchaseScreen extends StatefulWidget {
  const IndexPurchaseScreen({super.key});

  @override
  State<IndexPurchaseScreen> createState() => _IndexPurchaseScreenState();
}

class _IndexPurchaseScreenState extends State<IndexPurchaseScreen> {
  bool _isLoading = true;
  List<dynamic> _purchases = []; // ប្តូរទៅជា List<PurchaseModel> តាម Model របស់អ្នក
   final ApiPurchase _apiPurchase = ApiPurchase();

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  // 🔄 មុខងារទាញយកទិន្នន័យពី API
  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);

    try {
      // ឧទាហរណ៍ការហៅ API៖
      final data = await _apiPurchase.getAllPurchases();
      setState(() {
        _purchases = data;
        _isLoading = false;
      });

      // Mock ទុកមើលសិន (ពេលភ្ជាប់ API ពិត លុបកូដ Mock នេះចេញ)
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      // AppSnackBar.showError(context, 'Error: Failed to load purchases');[cite: 1]
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Purchase List',
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
          child: Container(
            color: Colors.grey.shade200,
            height: 1.0,
          ),
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
                  onPressed: _fetchPurchases,
                  tooltip: 'Refresh',
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchases.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No purchases found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchPurchases,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _purchases.length,
          itemBuilder: (context, index) {
            final purchase = _purchases[index];

            // 🛒 ទាញយកឈ្មោះ Product ពី Items
            String productNames = 'No Product';
            if (purchase.items != null && purchase.items!.isNotEmpty) {
              productNames = purchase.items!
                  .map((item) => item['product_name'] ?? 'Product')
                  .join(', ');
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // 🔍 ចុចដើម្បីមើលព័ត៌មានលម្អិត
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewPurchaseScreen(
                          purchaseId: purchase.id,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Purchase Number & Status
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              purchase.purchaseNumber ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: purchase.status == 'completed'
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                purchase.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: purchase.status == 'completed'
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Supplier & User Name
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Supplier: ${purchase.supplierName ?? 'ID: ${purchase.supplierId}'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'By: ${purchase.userName ?? 'User ${purchase.userId}'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // 📦 Product Name
                        Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Products: $productNames',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Method & Total Amount
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Method: ${purchase.paymentMethod}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '\$ ${purchase.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        // ⚙️ Action Buttons (Update & Delete)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditPurchaseScreen(
                                          purchase: purchase,
                                        ),
                                  ),
                                );
                                if (updated == true) {
                                  _fetchPurchases();
                                }
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Colors.orange,
                              ),
                              label: const Text(
                                'Edit',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                            const SizedBox(width: 7),

                            // 🗑️ Delete Button
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      contentPadding:
                                      const EdgeInsets.fromLTRB(
                                        24,
                                        20,
                                        24,
                                        10,
                                      ),
                                      title: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(
                                              10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons
                                                  .warning_amber_rounded,
                                              color: Colors.red,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Delete Purchase',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                              FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Text(
                                        'តើអ្នកពិតជាចង់លុប Purchase លេខ ${purchase.purchaseNumber ?? 'N/A'} នេះមែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          height: 1.4,
                                        ),
                                      ),
                                      actionsPadding:
                                      const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      actions: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                      context,
                                                    ),
                                                style: OutlinedButton
                                                    .styleFrom(
                                                  padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                    vertical: 12,
                                                  ),
                                                  shape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                      12,
                                                    ),
                                                  ),
                                                  side: BorderSide(
                                                    color: Colors
                                                        .grey
                                                        .shade300,
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontWeight:
                                                    FontWeight
                                                        .bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.pop(
                                                    context,
                                                  );
                                                  bool success = await _apiPurchase.deletePurchase(purchase.id);
                                                  true;
                                                  if (success) {
                                                    if (mounted) {
                                                      AppSnackBar
                                                          .showSuccess(
                                                        context,
                                                        'Purchase deleted successfully!',
                                                      );
                                                      _fetchPurchases();
                                                    }
                                                  } else {
                                                    if (mounted) {
                                                      AppSnackBar.showError(
                                                        context,
                                                        'Error: Failed to delete purchase',
                                                      );
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                  Colors.red,
                                                  foregroundColor:
                                                  Colors.white,
                                                  elevation: 0,
                                                  padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                    vertical: 12,
                                                  ),
                                                  shape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                      12,
                                                    ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    fontWeight:
                                                    FontWeight
                                                        .bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePurchaseScreen(),
            ),
          );
          if (result == true) {
            _fetchPurchases();
          }
        },
        backgroundColor: Colors.blue.shade600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Purchase',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../api/api_purchase.dart';
import '../msg/appSnackBar.dart';
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
  List<dynamic> _purchases = [];
  final ApiPurchase _apiPurchase = ApiPurchase();

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiPurchase.getAllPurchases();
      setState(() {
        _purchases = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPurchasesCount = _purchases.length;
    int totalItemsListCount = 0;
    double totalProductsQuantity = 0;

    for (var purchase in _purchases) {
      if (purchase.items != null && purchase.items is List) {
        totalItemsListCount += (purchase.items as List).length;
        for (var item in purchase.items) {
          final double qty =
              double.tryParse((item['quantity'] ?? 0).toString()) ?? 0.0;
          totalProductsQuantity += qty;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Purchase Management',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  color: const Color(0xFF2563EB),
                  onPressed: _fetchPurchases,
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
          : _purchases.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No purchases found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF2563EB),
              onRefresh: _fetchPurchases,
              child: Column(
                children: [
                  // 🌟 Summary Header Card ដ៏ស្រស់ស្អាត
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Purchases',
                          totalPurchasesCount.toString(),
                          Icons.receipt_rounded,
                        ),
                        Container(
                          height: 35,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        _buildStatItem(
                          'Lists',
                          totalItemsListCount.toString(),
                          Icons.list_alt_rounded,
                        ),
                        Container(
                          height: 35,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        _buildStatItem(
                          'Total Qty',
                          totalProductsQuantity % 1 == 0
                              ? totalProductsQuantity.toInt().toString()
                              : totalProductsQuantity.toStringAsFixed(1),
                          Icons.inventory_2_rounded,
                        ),
                      ],
                    ),
                  ),

                  // 📋 ListView បញ្ជី Purchase
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: _purchases.length,
                      itemBuilder: (context, index) {
                        final purchase = _purchases[index];

                        String productNames = 'No Product';
                        if (purchase.items != null &&
                            purchase.items!.isNotEmpty) {
                          productNames = purchase.items!
                              .map((item) => item['product_name'] ?? 'Product')
                              .join(', ');
                        }

                        final bool isCompleted =
                            (purchase.status ?? '').toLowerCase() ==
                            'completed';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
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
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .confirmation_number_outlined,
                                              size: 16,
                                              color: Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              purchase.purchaseNumber ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? const Color(0xFFDCFCE7)
                                                : const Color(0xFFFFEDD5),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            (purchase.status ?? 'N/A')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isCompleted
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFFC2410C),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                    ),

                                    // Supplier & User Name
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.storefront_rounded,
                                                size: 14,
                                                color: Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '${purchase.supplierName ?? 'ID: ${purchase.supplierId}'}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF475569),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'By: ${purchase.userName ?? 'User ${purchase.userId}'}',
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // 📦 Product Name
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 16,
                                          color: Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            productNames,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Method & Total Amount
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'Method: ${purchase.paymentMethod ?? 'Cash'}',
                                            style: const TextStyle(
                                              color: Color(0xFF475569),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '\$${purchase.total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Padding(
                                      padding: EdgeInsets.only(
                                        top: 10,
                                        bottom: 4,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                    ),

                                    // ⚙️ Action Buttons (Edit & Delete)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Edit Button
                                        SizedBox(
                                          height: 32,
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              final updated =
                                                  await Navigator.push(
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
                                            style: TextButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFEFF6FF,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 14,
                                              color: Color(0xFF2563EB),
                                            ),
                                            label: const Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Delete Button
                                        SizedBox(
                                          height: 32,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              _showDeleteDialog(
                                                context,
                                                purchase,
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFFEF2F2,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 14,
                                              color: Color(0xFFDC2626),
                                            ),
                                            label: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Color(0xFFDC2626),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
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
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.4),
              blurRadius: 50,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
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
          backgroundColor: const Color(0xFF2563EB),
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  // 🌟 Widget Stat Item សម្រាប់ Header Card
  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 🗑️ Delete Dialog Helper
  void _showDeleteDialog(BuildContext context, dynamic purchase) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Purchase',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete purchase "${purchase.purchaseNumber ?? 'N/A'}"?',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      bool success = await _apiPurchase.deletePurchase(
                        purchase.id,
                      );
                      if (success) {
                        if (mounted) {
                          AppSnackBar.showSuccess(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

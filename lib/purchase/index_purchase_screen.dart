import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_purchase.dart';
import '../msg/appSnackBar.dart';
import 'create_purchase_screen.dart';
import 'edit_purchase_screen.dart';
import 'view_purchase_screen.dart';

class _C {
  static const bg = Color(0xFFF2F4F8);
  static const ink = Color(0xFF142033);
  static const muted = Color(0xFF6C7A8E);
  static const line = Color(0xFFE0E6EE);
  static const navy = Color(0xFF0E2A47);
  static const red = Color(0xFFD32F2F);
  static const green = Color(0xFF2E9E6B);
  static const orange = Color(0xFFEF6C00);
}

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _buildHero(
              context,
              totalPurchasesCount.toString(),
              totalItemsListCount.toString(),
              totalProductsQuantity % 1 == 0
                  ? totalProductsQuantity.toInt().toString()
                  : totalProductsQuantity.toStringAsFixed(2),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: _C.navy),
              )
                  : _purchases.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _C.navy.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        size: 52,
                        color: _C.navy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No purchases found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _C.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap "New purchase" to create one',
                      style: TextStyle(fontSize: 13, color: _C.muted),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                color: _C.navy,
                onRefresh: _fetchPurchases,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  itemCount: _purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = _purchases[index];

                    String productNames = 'No Product';
                    if (purchase.items != null &&
                        purchase.items!.isNotEmpty) {
                      productNames = purchase.items!
                          .map(
                            (item) => item['product_name'] ?? 'Product',
                      )
                          .join(', ');
                    }

                    final bool isCompleted =
                        (purchase.status ?? '').toLowerCase() ==
                            'completed';

                    final int itemCount = purchase.items != null
                        ? purchase.items!.length
                        : 0;

                    return _buildPurchaseCard(
                      context,
                      purchase,
                      productNames,
                      isCompleted,
                      itemCount,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
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
          backgroundColor: _C.navy,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: const CircleBorder(), // 👈 ធ្វើឱ្យប៊ូតុងមូល 50% (Circle)
          child: const Icon(Icons.add_rounded, size: 26),
        ),
      ),
    );
  }


  Widget _buildHero(
      BuildContext context,
      String purchases,
      String lists,
      String totalQty,
      ) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 6, 12, 22),
      decoration: const BoxDecoration(
        color: _C.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              const Expanded(
                child: Text(
                  'Purchase Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                  onPressed: _fetchPurchases,
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Purchases',
                    purchases,
                    Icons.receipt_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'Lists',
                    lists,
                    Icons.list_alt_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'Total Qty',
                    totalQty,
                    Icons.inventory_2_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(
      BuildContext context,
      dynamic purchase,
      String productNames,
      bool isCompleted,
      int itemCount,
      ) {
    final Color statusColor = isCompleted ? _C.green : _C.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ViewPurchaseScreen(purchaseId: purchase.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: number, supplier, status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _C.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: _C.navy,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            purchase.purchaseNumber ?? 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: _C.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                size: 14,
                                color: _C.muted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${purchase.supplierName ?? 'ID: ${purchase.supplierId}'}',
                                  style: const TextStyle(
                                    color: _C.muted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            (purchase.status ?? 'N/A').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 📦 Products
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: _C.navy,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          productNames,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _C.ink,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _C.navy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            color: _C.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Method, user and total
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _C.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Method: ${purchase.paymentMethod ?? 'Cash'}',
                              style: const TextStyle(
                                color: _C.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'By: ${purchase.userName ?? 'User ${purchase.userId}'}',
                            style: const TextStyle(
                              color: _C.muted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: _C.muted, fontSize: 11),
                        ),
                        Text(
                          '\$${purchase.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: _C.navy,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.only(top: 14, bottom: 12),
                  child: Divider(height: 1, color: _C.line),
                ),

                // ⚙️ Action Buttons (Edit & Delete)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextButton.icon(
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditPurchaseScreen(purchase: purchase),
                              ),
                            );
                            if (updated == true) {
                              _fetchPurchases();
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: _C.navy.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: _C.navy,
                          ),
                          label: const Text(
                            'Edit',
                            style: TextStyle(
                              color: _C.navy,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextButton.icon(
                          onPressed: () {
                            _showDeleteDialog(context, purchase);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: _C.red.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: _C.red,
                          ),
                          label: const Text(
                            'Delete',
                            style: TextStyle(
                              color: _C.red,
                              fontSize: 13,
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
      ),
    );
  }

  // 🌟 Widget Stat Item សម្រាប់ Header Card
  Widget _buildStatItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🗑️ Delete Dialog Helper
  void _showDeleteDialog(BuildContext context, dynamic purchase) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _C.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: _C.red,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delete Purchase',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _C.ink,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete purchase "${purchase.purchaseNumber ?? 'N/A'}"?',
            style: const TextStyle(fontSize: 14, color: _C.muted, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: _C.line),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: _C.ink,
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
                      backgroundColor: _C.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
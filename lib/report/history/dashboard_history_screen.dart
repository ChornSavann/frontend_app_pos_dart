import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/Productscreen/scanncheck/price_checker_screen.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/order/delivery/delivery_orders_screen.dart';
import 'package:pos_inventory/partail/app_bar_screen.dart';
import 'package:pos_inventory/report/invoice/list_invoice_screen.dart';
import '../../order/cart_screen.dart';
import '../../partail/button_screen.dart';
import 'sale_history_screen.dart';
import 'purchase_history_screen.dart';

class DashboardHistoryScreen extends StatelessWidget {
  const DashboardHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const AppBarScreen(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            TranslateConstants.transaction_history.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // 🟢 1. Card សម្រាប់ចូលទៅកាន់ Sales History
          _buildHistoryMenuCard(
            context,
            title: TranslateConstants.sales_history.tr,
            subtitle: TranslateConstants.review_sales.tr,
            icon: Icons.point_of_sale_rounded,
            iconColor: Colors.green,
            backgroundColor: Colors.green.shade50,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SaleHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 🟢 2. Card សម្រាប់ចូលទៅកាន់ Purchase History
          _buildHistoryMenuCard(
            context,
            title: TranslateConstants.purchase_history.tr,
            subtitle: TranslateConstants.review_purchase.tr,
            icon: Icons.local_shipping_rounded,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue.shade50,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PurchaseHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 🟢 3. Card សម្រាប់ចូលទៅកាន់ Scan Check Product
          _buildHistoryMenuCard(
            context,
            title: TranslateConstants.scan_check_product.tr,
            subtitle: TranslateConstants.manage_scan_check_product.tr,
            icon: Icons.document_scanner_rounded,
            iconColor: Colors.orange,
            backgroundColor: Colors.orange.shade50,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PriceCheckerScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 🟢 4. Card សម្រាប់ចូលទៅកាន់ Manage Delivery
          _buildHistoryMenuCard(
            context,
            title: TranslateConstants.delivery.tr,
            subtitle: TranslateConstants.manage_delivery.tr,
            icon: Icons.local_shipping_outlined,
            iconColor: Colors.purple,
            backgroundColor: Colors.purple.shade50,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeliveryOrdersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildHistoryMenuCard(
            context,
            title: TranslateConstants.invoice.tr,
            subtitle: TranslateConstants.manage_invoice.tr,
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF10B981),
            backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListInvoiceScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildPOSFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const ButtonScreen(currentIndex: 2),
    );
  }

  Widget _buildHistoryMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPOSFloatingActionButton(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 15),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CartScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.point_of_sale_rounded, size: 26),
      ),
    );
  }
}

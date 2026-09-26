import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/CategoryScreen/category_index_screen.dart';
import 'package:pos_inventory/CategoryScreen/create_categrory_screen.dart';
import 'package:pos_inventory/Productscreen/create_product_screen.dart';
import 'package:pos_inventory/Productscreen/product_index_screen.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/api/report/api_report.dart';
import 'package:pos_inventory/brand/brand_index_screen.dart';
import 'package:pos_inventory/brand/create_brand_screen.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/customer/customer_create_screen.dart';
import 'package:pos_inventory/customer/customer_index_screen.dart';
import 'package:pos_inventory/expenses/create_expense_screen.dart';
import 'package:pos_inventory/expenses/index_expense_screen.dart';
import 'package:pos_inventory/expensetype/index_expensetype_sreen.dart';
import 'package:pos_inventory/purchase/create_purchase_screen.dart';
import 'package:pos_inventory/purchase/index_purchase_screen.dart';
import 'package:pos_inventory/report/report_dashboard_screen.dart';
import 'package:pos_inventory/stores/create_store_screen.dart';
import 'package:pos_inventory/stores/index_store_screen.dart';
import 'package:pos_inventory/supplier/index_supplier_screen.dart';
import 'package:pos_inventory/unit/create_unit_screen.dart';
import 'package:pos_inventory/unit/unit_index_screen.dart';

import 'package:pos_inventory/supplier/create_supplier_screen.dart';
import 'package:pos_inventory/users/create_user_screen.dart';
import 'package:pos_inventory/users/user_index_screen.dart';

import '../banner/banner_screen.dart';
import '../expensetype/create_expens_type_screen.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  final ApiProduct apiProduct = ApiProduct();
  final ApiReport apiReport = ApiReport();

  double totalSalesValue = 0.0;
  bool isStatLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTotalSalesData();
  }

  Future<void> _loadTotalSalesData() async {
    try {
      final result = await apiReport.fetchTotalSalesReport();
      setState(() {
        totalSalesValue = result['total_sales'] ?? 0.0;
        isStatLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading sales data: $e');
      setState(() => isStatLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ Modern Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -25,
                    bottom: -25,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    top: -30,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // 📝 Content Section
                  Row(
                    children: [
                      // 📝 ផ្នែកអត្ថបទខាងឆ្វេង
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    TranslateConstants.hello.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "👋",
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              TranslateConstants.manage_inventory.tr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          'https://i.pinimg.com/1200x/f8/08/b4/f808b4bc1f3d6b03d8070994a3638d7f.jpg',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 52,
                              height: 52,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 52,
                                height: 52,
                                color: Colors.white.withOpacity(0.2),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const AutoPlayBanner(),
            // const BannerProductScreen(),
            const SizedBox(height: 24),

            // 📊 Quick Statistics Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslateConstants.overview.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  TranslateConstants.real_time.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildModernStatCard(
                    title: TranslateConstants.totalSale.tr,
                    value: isStatLoading
                        ? "Loading..."
                        : "\$${totalSalesValue.toStringAsFixed(2)}",
                    icon: Icons.trending_up_rounded,
                    primaryColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<int>(
                    future: apiProduct.fetchProductCount(),
                    builder: (context, snapshot) {
                      String displayValue = "...";
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData) {
                          displayValue =
                              "${snapshot.data} ${TranslateConstants.item.tr}";
                        } else {
                          displayValue = "0 Items";
                        }
                      }

                      return _buildModernStatCard(
                        title: TranslateConstants.totalProduct.tr,
                        value: displayValue,
                        icon: Icons.inventory_2_rounded,
                        primaryColor: const Color(0xFFF59E0B),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              TranslateConstants.quick_actions.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildQuickActionItem(
                    title: TranslateConstants.product.tr,
                    icon: Icons.add_box_rounded,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateProductScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionItem(
                    title: TranslateConstants.category.tr,
                    icon: Icons.create_new_folder_rounded,
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateCategoryScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionItem(
                    title: TranslateConstants.brand.tr,
                    icon: Icons.branding_watermark_rounded,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateBrandScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionItem(
                    title: TranslateConstants.unit.tr,
                    icon: Icons.straighten_rounded,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateUnitScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionItem(
                    title: TranslateConstants.supplier.tr,
                    icon: Icons.local_shipping_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateSupplierScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionItem(
                    title: TranslateConstants.purchase.tr,
                    icon: Icons.receipt_long_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePurchaseScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionItem(
                    title: TranslateConstants.user.tr,
                    icon: Icons.people_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateUserScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionItem(
                    title: TranslateConstants.store.tr,
                    icon: Icons.store_sharp,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateStoreScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionItem(
                    title: TranslateConstants.expense_type.tr,
                    icon: Icons.category_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateExpensTypeScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  _buildQuickActionItem(
                    title: TranslateConstants.expense.tr,
                    icon: Icons.payments_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateExpenseScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📂 Management Lists Section
            Text(
              TranslateConstants.management.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.7,
              children: [
                _buildModernActionCard(
                  title: TranslateConstants.product.tr,
                  subtitle: TranslateConstants.manageProduct.tr,
                  icon: Icons.inventory_rounded,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductIndexScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.category.tr,
                  subtitle: TranslateConstants.manageCategory.tr,
                  icon: Icons.list_alt_rounded,
                  color: Colors.pink,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryIndexScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.brand.tr,
                  subtitle: TranslateConstants.manageBrand.tr,
                  icon: Icons.storefront_rounded,
                  color: Colors.cyan,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrandIndexScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.unit.tr,
                  subtitle: TranslateConstants.manageUnit.tr,
                  icon: Icons.category_rounded,
                  color: Colors.deepOrange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UnitIndexScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.supplier.tr,
                  subtitle: TranslateConstants.manageSupplier.tr,
                  icon: Icons.local_shipping_rounded,
                  color: Colors.blueGrey,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IndexSupplierScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.store.tr,
                  subtitle: TranslateConstants.manageStore.tr,
                  icon: Icons.storefront_outlined,
                  color: Colors.blueGrey,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IndexStoreScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.purchase.tr,
                  subtitle: TranslateConstants.managePurchase.tr,
                  icon: Icons.receipt_long_rounded,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IndexPurchaseScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.user.tr,
                  subtitle: TranslateConstants.manageUser.tr,
                  icon: Icons.supervisor_account_sharp,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserIndexScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.customer.tr,
                  subtitle: TranslateConstants.manage_customer.tr,
                  icon: Icons.people_alt_rounded,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerIndexScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.expense_type.tr,
                  subtitle: TranslateConstants.manage_exp.tr,
                  icon: Icons.folder_open_rounded,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IndexExpensetypeSreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.expense.tr,
                  subtitle: TranslateConstants.manage_expense.tr,
                  icon: Icons.payments_rounded,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IndexExpenseScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.report.tr,
                  subtitle: TranslateConstants.manageReport.tr,
                  icon: Icons.bar_chart_rounded,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportDashboardScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              Icon(Icons.trending_up, size: 16, color: primaryColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Quick Action Vertical Item
  Widget _buildQuickActionItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 85,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📂 Management Card Widget (បានកែសម្រួលឱ្យតូចស្អាតល្មម)
  Widget _buildModernActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ), // 💡 កាត់បន្ថយ Padding ជុំវិញឱ្យតូច
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center, // 💡 ទាញមាតិកាឱ្យកណ្តាលស្អាត
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // 💡 រក្សាទុកតែមួយ និងត្រឹមត្រូវ
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey.shade400,
                    size: 12,
                  ),
                ],
              ),
              const SizedBox(height: 8), // 💡 បន្ថយគម្លាតកម្ពស់
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13, // 💡 បន្ថយអក្សរបន្តិចដើម្បីកុំឱ្យវែងពេក
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

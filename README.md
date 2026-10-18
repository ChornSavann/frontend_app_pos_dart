========Model User=========
class User {
int? id;
String? name;
String? email;
String? phone;
String?password;
int?roleid;
String? image;

User({
this.id,
this.name,
this.email,
this.phone,
this.password,
this.roleid,
this.image,
});

// 📥 แปลง JSON មកជា User Object
factory User.fromJson(Map<String, dynamic> json) {
return User(
id: json['id'],
name: json['name'],
email: json['email'],
phone: json['phone'],
password: json['password'],
roleid: json['role_id'],
image: json['image_url'],
);
}

// 📤 แปลง User Object ទៅជា JSON
Map<String, dynamic> toJson() {
return {
'id': id,
'name': name,
'email': email,
'phone': phone,
'password':password,
'image': image,
};
}
}
============Screen home=============
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
import 'package:pos_inventory/users/roles/manage_user_role_screen.dart';
import 'package:pos_inventory/users/roles/role_screen.dart';
import 'package:pos_inventory/users/user_index_screen.dart';

import '../banner/banner_screen.dart';
import '../expensetype/create_expens_type_screen.dart';
import '../login/authority/authority_screen.dart';

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
backgroundColor: const Color(0xFFF8FAFC), // 🎨 Modern soft background
body: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// 🏷️ Premium Modern Welcome Banner
Container(
width: double.infinity,
padding: const EdgeInsets.all(22),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [
Color(0xFF4F46E5),
Color(0xFF6366F1),
Color(0xFF3B82F6),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(24),
boxShadow: [
BoxShadow(
color: const Color(0xFF4F46E5).withOpacity(0.3),
blurRadius: 18,
offset: const Offset(0, 8),
),
],
),
child: Stack(
children: [
Positioned(
right: -30,
bottom: -30,
child: Container(
width: 120,
height: 120,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.08),
shape: BoxShape.circle,
),
),
),
Row(
children: [
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
fontSize: 19,
fontWeight: FontWeight.bold,
letterSpacing: 0.2,
),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
),
const SizedBox(width: 6),
const Text(
"👋",
style: TextStyle(fontSize: 16),
),
],
),
const SizedBox(height: 6),
Text(
TranslateConstants.manage_inventory.tr,
style: TextStyle(
color: Colors.white.withOpacity(0.9),
fontSize: 13,
height: 1.4,
),
maxLines: 2,
overflow: TextOverflow.ellipsis,
),
],
),
),
const SizedBox(width: 14),
Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: Colors.white.withOpacity(0.35),
width: 2,
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.1),
blurRadius: 8,
offset: const Offset(0, 4),
),
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(14),
child: Image.network(
'https://i.pinimg.com/1200x/f8/08/b4/f808b4bc1f3d6b03d8070994a3638d7f.jpg',
width: 56,
height: 56,
fit: BoxFit.cover,
errorBuilder: (context, error, stackTrace) =>
Container(
width: 56,
height: 56,
color: Colors.white.withOpacity(0.2),
child: const Icon(
Icons.storefront_rounded,
color: Colors.white,
size: 26,
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
const SizedBox(height: 24),
const AutoPlayBanner(),
const SizedBox(height: 24),

            // 📊 Quick Statistics Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslateConstants.overview.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    TranslateConstants.real_time.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildBeautifulStatCard(
                    title: TranslateConstants.totalSale.tr,
                    value: isStatLoading
                        ? "Loading..."
                        : "\$${totalSalesValue.toStringAsFixed(2)}",
                    icon: Icons.trending_up_rounded,
                    primaryColor: const Color(0xFF10B981),
                    gradientColors: [
                      const Color(0xFFECFDF5),
                      const Color(0xFFD1FAE5),
                    ],
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

                      return _buildBeautifulStatCard(
                        title: TranslateConstants.totalProduct.tr,
                        value: displayValue,
                        icon: Icons.inventory_2_rounded,
                        primaryColor: const Color(0xFFF59E0B),
                        gradientColors: [
                          const Color(0xFFFFFBEB),
                          const Color(0xFFFEF3C7),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ⚡ Quick Actions Section Header
            Text(
              TranslateConstants.quick_actions.tr,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 94,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildQuickActionItem(
                    title: TranslateConstants.product.tr,
                    icon: Icons.add_box_rounded,
                    color: const Color(0xFF3B82F6),
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
                    color: const Color(0xFF8B5CF6),
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
                    color: const Color(0xFFF97316),
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
                    color: const Color(0xFF14B8A6),
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
                    color: const Color(0xFF6366F1),
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
                    color: const Color(0xFF0EA5E9),
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
                    color: const Color(0xFFEC4899),
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
                    color: const Color(0xFF64748B),
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
                    color: const Color(0xFFEAB308),
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
                    color: const Color(0xFFEF4444),
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

            // 📂 Management Lists Section Header
            Text(
              TranslateConstants.management.tr,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // 📂 Management Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.63,
              children: [
                _buildModernActionCard(
                  title: TranslateConstants.product.tr,
                  subtitle: TranslateConstants.manageProduct.tr,
                  icon: Icons.inventory_rounded,
                  color: const Color(0xFF3B82F6),
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
                  color: const Color(0xFF8B5CF6),
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
                  color: const Color(0xFF06B6D4),
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
                  color: const Color(0xFFF97316),
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
                  color: const Color(0xFF64748B),
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
                  color: const Color(0xFF334155),
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
                  color: const Color(0xFF0EA5E9),
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
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserIndexScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.auth_logs.tr,
                  subtitle: TranslateConstants.manage_auth_logs.tr,
                  icon: Icons.admin_panel_settings_rounded,
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthorityScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: 'Role & Permissions',
                  subtitle: 'Manage roles and permissions',
                  icon: Icons.manage_accounts_sharp,
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageUserRoleScreen(),
                    ),
                  ),
                ),
                _buildModernActionCard(
                  title: TranslateConstants.customer.tr,
                  subtitle: TranslateConstants.manage_customer.tr,
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF10B981),
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
                  color: const Color(0xFFEAB308),
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
                  color: const Color(0xFFEF4444),
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
                  color: const Color(0xFF6366F1),
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

// ✨ Elegant & Clean Stat Card Widget
Widget _buildBeautifulStatCard({
required String title,
required String value,
required IconData icon,
required Color primaryColor,
required List<Color> gradientColors,
}) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: const Color(0xFF64748B).withOpacity(0.06),
blurRadius: 14,
offset: const Offset(0, 4),
),
],
border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
gradient: LinearGradient(
colors: gradientColors,
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(14),
),
child: Icon(icon, color: primaryColor, size: 22),
),
Container(
padding: const EdgeInsets.all(6),
decoration: BoxDecoration(
color: primaryColor.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(
Icons.trending_up_rounded,
size: 16,
color: primaryColor,
),
),
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
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Color(0xFF0F172A),
),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
],
),
);
}

// ✨ Sleek Quick Action Item
Widget _buildQuickActionItem({
required String title,
required IconData icon,
required Color color,
required VoidCallback onTap,
}) {
return SizedBox(
width: 86,
child: Material(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(18),
child: Container(
padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(18),
border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
boxShadow: [
BoxShadow(
color: const Color(0xFF64748B).withOpacity(0.04),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
padding: const EdgeInsets.all(9),
decoration: BoxDecoration(
color: color.withOpacity(0.12),
shape: BoxShape.circle,
),
child: Icon(icon, color: color, size: 20),
),
const SizedBox(height: 8),
Text(
title,
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.bold,
color: Color(0xFF0F172A),
),
textAlign: TextAlign.center,
overflow: TextOverflow.ellipsis,
maxLines: 1,
),
],
),
),
),
),
);
}

// 📂 Clean Management Card Widget
Widget _buildModernActionCard({
required String title,
required String subtitle,
required IconData icon,
required Color color,
required VoidCallback onTap,
}) {
return Material(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(18),
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(18),
boxShadow: [
BoxShadow(
color: const Color(0xFF64748B).withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisAlignment: MainAxisAlignment.center,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: color.withOpacity(0.12),
borderRadius: BorderRadius.circular(12),
),
child: Icon(icon, color: color, size: 18),
),
Container(
padding: const EdgeInsets.all(4),
decoration: BoxDecoration(
color: const Color(0xFFF1F5F9),
shape: BoxShape.circle,
),
child: Icon(
Icons.arrow_forward_ios_rounded,
color: Colors.grey.shade400,
size: 9,
),
),
],
),
const SizedBox(height: 10),
Text(
title,
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.bold,
color: Color(0xFF0F172A),
),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
const SizedBox(height: 1),
Text(
subtitle,
style: TextStyle(
fontSize: 10,
color: Colors.grey.shade500,
fontWeight: FontWeight.w500,
),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
],
),
),
),
);
}
}

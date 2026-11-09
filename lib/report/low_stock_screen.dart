import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/api/report/api_report.dart';
import 'package:pos_inventory/purchase/create_purchase_screen.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  bool isLoading = false;
  final ApiReport apiReport = ApiReport();

  List<Map<String, dynamic>> lowStockItems = [];

  @override
  void initState() {
    super.initState();

    _loadLowStockData();
  }


  Future<void> _loadLowStockData() async {
    setState(() => isLoading = true);
    try {
      final data = await apiReport.fetchLowStockProducts();
      setState(() {
        lowStockItems = data;
      });
    } catch (e) {
      debugPrint('Error loading low stock: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌙 Light / dark colors
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF4F6F9);
    final Color card = isDark ? const Color(0xFF151C2E) : Colors.white;
    final Color textMain = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF1E293B);
    final Color textSub = isDark ? const Color(0xFF94A3B8) : Colors.grey[600]!;
    final Color border = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.transparent;
    final Color track = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE2E8F0);

    int lowStockCount = lowStockItems.length;
    int criticalCount = lowStockItems
        .where((item) => item['status'] == 'Critical')
        .length;

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: card,
          iconTheme: IconThemeData(color: textMain),
          title: Text(
            'Low Stock Alerts',
            style: TextStyle(
              color: textMain,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textMain),
              onPressed: _loadLowStockData,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFEF4444)),
      )
          : RefreshIndicator(
        color: const Color(0xFFEF4444),
        onRefresh: _loadLowStockData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 Summary Alert Banner Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFFDC2626), Color(0xFF991B1B)]
                        : const [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.08 : 0.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFEF4444,
                      ).withOpacity(isDark ? 0.22 : 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // ✨ Decorative shapes
                      Positioned(
                        right: -30,
                        bottom: -36,
                        child: Icon(
                          Icons.inventory_2_rounded,
                          size: 130,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      Positioned(
                        left: -40,
                        top: -50,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Inventory Warning',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(
                                      20,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                        0.25,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Action Required',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$lowStockCount Items Need Refill',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSubMetric(
                                  'Critical Low',
                                  '$criticalCount Item',
                                  CupertinoIcons
                                      .exclamationmark_triangle_fill,
                                ),
                                _buildSubMetric(
                                  'Monitored',
                                  '$lowStockCount Products',
                                  CupertinoIcons.cube_box_fill,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🏷️ Section Title
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Items Requiring Restock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFEF4444,
                      ).withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$lowStockCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 📋 Low Stock Items List
              lowStockItems.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No low stock items found 🎉',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
                  : // 📋 Low Stock Items List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lowStockItems.length,
                itemBuilder: (context, index) {
                  final item = lowStockItems[index];
                  bool isCritical = item['status'] == 'Critical';
                  final productImage = item['image_url'].toString();

                  // 🎨 UI only: stock level vs minimum alert
                  final double stockLeft =
                      double.tryParse(item['stock_left'].toString()) ??
                          0.0;
                  final double minAlert =
                      double.tryParse(item['min_alert'].toString()) ??
                          0.0;
                  final double ratio = minAlert > 0
                      ? (stockLeft / minAlert).clamp(0.0, 1.0)
                      : 0.0;
                  final Color statusColor = isCritical
                      ? const Color(0xFFEF4444)
                      : (isDark
                      ? Colors.orange[400]!
                      : Colors.orange[800]!);

                  return GestureDetector(
                    onTap: () {
                      print('Item data from LowStock: $item');
                      // 🚀 បញ្ជូនទៅកាន់ Purchase Screen (សូមប្ដូរ AddPurchaseScreen ទៅតាមឈ្មោះ Screen ពិតប្រាកដរបស់អ្នក)
                      Navigator.push(
                        context,
                        MaterialPageRoute(

                          builder: (context) => CreatePurchaseScreen(
                            productId: item['product_id'] ?? item['id'], // 🟢 ឆែកទប់ទា
                            productName: item['name'],
                          ),
                        ),
                      );
                    },

                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.30 : 0.04,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              // 🔴 Status accent bar
                              Container(
                                width: 4,
                                color: isCritical
                                    ? const Color(0xFFEF4444)
                                    : Colors.orange,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          // 📦 Product Image Box
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withOpacity(
                                                isDark ? 0.18 : 0.1,
                                              ),
                                              borderRadius:
                                              BorderRadius.circular(
                                                14,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                              BorderRadius.circular(
                                                14,
                                              ),
                                              child: productImage
                                                  .isNotEmpty
                                                  ? Image.network(
                                                productImage,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                    ) {
                                                  return const Center(
                                                    child: Text(
                                                      '📦',
                                                      style: TextStyle(
                                                        fontSize:
                                                        20,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                                  : const Center(
                                                child: Text(
                                                  '📦',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Item Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(
                                                  item['name'],
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                  style: TextStyle(
                                                    fontWeight:
                                                    FontWeight.bold,
                                                    fontSize: 15,
                                                    color: textMain,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ),
                                                Text(
                                                  'Category: ${item['category']} • Min: ${item['min_alert']}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                  style: TextStyle(
                                                    color: textSub,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Stock Count & Status Badge
                                          Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${item['stock_left']} left',
                                                style: TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  fontSize: 15,
                                                  color: statusColor,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isCritical
                                                      ? const Color(
                                                    0xFFEF4444,
                                                  ).withOpacity(
                                                    isDark
                                                        ? 0.2
                                                        : 0.1,
                                                  )
                                                      : Colors.orange
                                                      .withOpacity(
                                                    isDark
                                                        ? 0.2
                                                        : 0.1,
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                    6,
                                                  ),
                                                ),
                                                child: Text(
                                                  item['status'],
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // 📊 Stock level bar (stock left vs min alert)
                                      ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: ratio,
                                          minHeight: 5,
                                          backgroundColor: track,
                                          valueColor:
                                          AlwaysStoppedAnimation<
                                              Color
                                          >(
                                            isCritical
                                                ? const Color(
                                              0xFFEF4444,
                                            )
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
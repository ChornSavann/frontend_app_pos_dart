import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/api/report/api_report.dart'; // 🟢 Import ApiReport របស់អ្នក
import 'package:pos_inventory/report/customer_report_screen.dart';
import 'package:pos_inventory/report/daily_report_screen.dart';
import 'package:pos_inventory/report/low_stock_screen.dart';
import 'package:pos_inventory/report/purchase_report_screen.dart';
import 'package:pos_inventory/report/top_selling_screen.dart';

class ReportDashboardScreen extends StatefulWidget {
  const ReportDashboardScreen({super.key});

  @override
  State<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends State<ReportDashboardScreen> {
  bool isLoading = false;
  final ApiReport apiReport = ApiReport();

  List<Map<String, dynamic>> weeklyOrders = [];
  bool isChartLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      isChartLoading = true;
    });

    try {
      final data = await apiReport.fetchWeeklyReport();
      setState(() {
        weeklyOrders = data;
      });
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      setState(() {
        isLoading = false;
        isChartLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
          title: const Text(
            'Analytics & Reports',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
              onPressed: fetchDashboardData,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : RefreshIndicator(
              color: const Color(0xFF4F46E5),
              onRefresh: fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChartCard(),
                    const SizedBox(height: 24),

                    const Text(
                      'Report Modules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildReportCard(
                      title: 'Daily Sales Report',
                      subtitle: 'View today total orders, revenue & cash flow',
                      icon: Icons.today_rounded,
                      color: const Color(0xFFF97316),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DailyReportScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildReportCard(
                      title: 'Top-Selling Products',
                      subtitle:
                          'Most popular items sold based on quantity & revenue',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopSellingScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildReportCard(
                      title: 'Purchase History',
                      subtitle:
                          'Track supplier expenses, stock imports and orders',
                      icon: Icons.shopping_bag_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PurchaseReportScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 👥 6. Low Stock & Customer Cards (Side by Side)
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallCard(
                            title: 'Low Stock',
                            subtitle: 'Items need refill',
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFEF4444),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LowStockScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSmallCard(
                            title: 'Customers',
                            subtitle: 'Points & history',
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFF8B5CF6),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerReportScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // 📊 Chart Card UI Design (Dynamic API Integration)
  Widget _buildChartCard() {
    // 🟢 គណនាតម្លៃទឹកប្រាក់តាមថ្ងៃនីមួយៗក្នុងសប្តាហ៍ (0 = Mon, ..., 6 = Sun)
    List<double> dailyRevenue = List.filled(7, 0.0);
    for (var order in weeklyOrders) {
      try {
        DateTime date = DateTime.parse(order['date']);
        int dayIndex = date.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyRevenue[dayIndex] += order['total'] as double;
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    // 🟢 រកមើលតម្លៃទឹកប្រាក់ច្រើនជាងគេដើម្បីធ្វើ Scale ឱ្យ Chart
    double maxRevenue = dailyRevenue.isNotEmpty
        ? dailyRevenue.reduce((a, b) => a > b ? a : b)
        : 1.0;
    if (maxRevenue == 0) maxRevenue = 1.0;

    List<double> chartHeights = dailyRevenue
        .map((val) => val / maxRevenue)
        .toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Revenue',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Real-time API Data',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 12,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: isChartLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildChartBar(
                        'Mon',
                        chartHeights[0],
                        const Color(0xFF3B82F6),
                      ),
                      _buildChartBar(
                        'Tue',
                        chartHeights[1],
                        const Color(0xFF3B82F6),
                      ),
                      _buildChartBar(
                        'Wed',
                        chartHeights[2],
                        const Color(0xFF3B82F6),
                      ),
                      _buildChartBar(
                        'Thu',
                        chartHeights[3],
                        const Color(0xFF3B82F6),
                      ),
                      _buildChartBar(
                        'Fri',
                        chartHeights[4],
                        const Color(0xFF3B82F6),
                      ),
                      _buildChartBar(
                        'Sat',
                        chartHeights[5],
                        const Color(0xFFF97316),
                      ),
                      _buildChartBar(
                        'Sun',
                        chartHeights[6],
                        const Color(0xFFF97316),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, double heightFactor, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: 75 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 🧱 Modern Report Card Widget
  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
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
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🧱 Modern Small Card Widget
  Widget _buildSmallCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
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
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

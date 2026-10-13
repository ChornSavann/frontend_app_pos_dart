import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos_inventory/api/report/api_report.dart';
import 'package:pos_inventory/constants/baseurl/base_image_url.dart'; // 📥 នាំចូល BaseImageUrl

class TopSellingScreen extends StatefulWidget {
  const TopSellingScreen({super.key});

  @override
  State<TopSellingScreen> createState() => _TopSellingScreenState();
}

class _TopSellingScreenState extends State<TopSellingScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  final ApiReport apiReport = ApiReport();

  List<Map<String, dynamic>> topProducts = [];

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _loadTopSellingData();
  }

  Future<void> _loadTopSellingData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedData = await apiReport.fetchTopSellingProducts();
      debugPrint('📦 FETCHED PRODUCTS DATA: $fetchedData');

      setState(() {
        topProducts = fetchedData;
      });
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      debugPrint('Error loading top selling screen: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
          title: const Text(
            'Top-Selling Products',
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
              onPressed: _loadTopSellingData,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : RefreshIndicator(
              color: const Color(0xFF10B981),
              onRefresh: _loadTopSellingData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Distribution Analytics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 🥧 Pie Chart Card
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _animation.value,
                          child: Opacity(
                            opacity: _animation.value,
                            child: _buildPieChartCard(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Best Performers List',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 📋 Products List
                    topProducts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Text(
                                'No top-selling products found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topProducts.length,
                            itemBuilder: (context, index) {
                              final product = topProducts[index];

                              // 🖼️ ដំណើរការបង្កើត Link រូបភាពឱ្យបានត្រឹមត្រូវជាមួយ BaseImageUrl
                              final rawImage = product['image_url'];
                              String? finalImageUrl;

                              if (rawImage != null &&
                                  rawImage.toString().trim().isNotEmpty) {
                                String imageStr = rawImage.toString();
                                if (imageStr.startsWith('http://') ||
                                    imageStr.startsWith('https://')) {
                                  finalImageUrl = imageStr;
                                } else {
                                  String cleanPath = imageStr.startsWith('/')
                                      ? imageStr.substring(1)
                                      : imageStr;
                                  String baseUrlFormatted =
                                      BaseImageUrl.BaseimageUrl;
                                  if (!baseUrlFormatted.startsWith('http://') &&
                                      !baseUrlFormatted.startsWith(
                                        'https://',
                                      )) {
                                    baseUrlFormatted =
                                        'http://$baseUrlFormatted';
                                  }
                                  finalImageUrl =
                                      '$baseUrlFormatted/$cleanPath';
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: index == 0
                                              ? Colors.amber.withOpacity(0.2)
                                              : const Color(
                                                  0xFF10B981,
                                                ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '#${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: index == 0
                                                ? Colors.amber[800]
                                                : const Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F6F9),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: finalImageUrl != null
                                              ? Image.network(
                                                  finalImageUrl,
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
                                                              fontSize: 20,
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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Qty: ${product['sold_qty']} units',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${(product['revenue'] as double).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Revenue',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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

// 🥧 Modern Styled Pie Chart Widget
  Widget _buildPieChartCard() {
    final List<Color> chartColors = [
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
    ];

    // គណនាយកចំនួនសរុប (Total Qty) ដើម្បីយកមកគណនាភាគរយ ឬបង្ហាញនៅកណ្តាលរង្វង់
    int totalSold = 0;
    final displayLength = topProducts.length > 4 ? 4 : topProducts.length;
    for (int i = 0; i < displayLength; i++) {
      totalSold += (topProducts[i]['sold_qty'] as int);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: topProducts.isEmpty
          ? const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No data for chart',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      )
          : Row(
        children: [
          // 📊 Pie Chart with Center Text
          SizedBox(
            height: 160,
            width: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 45, // ទំហំរង្វង់មូល හිස්កណ្តាល
                      sections: List.generate(
                        displayLength,
                            (index) {
                          final item = topProducts[index];
                          final color = chartColors[index % chartColors.length];
                          return PieChartSectionData(
                            color: color,
                            value: (item['sold_qty'] as int).toDouble(),
                            title: '', // រក្សាទុកទទេ ដើម្បីឱ្យស្អាត មិនបាច់មានអត្ថបទជាន់គ្នាក្នុងរង្វង់
                            radius: 35,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // ✨ អត្ថបទបង្ហាញនៅចំកណ្តាលរង្វង់ Donut Chart
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalSold',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 📋 Legend / Labels ខាងស្តាំ (បង្ហាញទាំងឈ្មោះ ចំនួនលក់ និងភាគរយ)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                displayLength,
                    (index) {
                  final item = topProducts[index];
                  final color = chartColors[index % chartColors.length];
                  final qty = item['sold_qty'] as int;

                  // គណនាជាភាគរយ (%)
                  double percentage = totalSold > 0 ? (qty / totalSold) * 100 : 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // បង្ហាញទាំងចំនួន (qty) និងភាគរយ (%)
                        Text(
                          '$qty (${percentage.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos_inventory/constants/baseurl/base_image_url.dart';
import '../../api/report/api_report.dart';

class FinancialChartScreen extends StatefulWidget {
  const FinancialChartScreen({super.key});

  @override
  State<FinancialChartScreen> createState() => _FinancialChartScreenState();
}

class _FinancialChartScreenState extends State<FinancialChartScreen> {
  final ApiReport _apiReport = ApiReport();
  bool isLoading = true;

  // 🔄 0: ចំណូល, 1: ចំណាយទូទៅ, 2: ចំណាយស្តុក, 3: ចំណាយសរុប
  int selectedTab = 0;

  String? startDate;
  String? endDate;

  Map<String, dynamic> reportData = {
    'total_income': 0.0,
    'total_expense': 0.0,
    'general_expenses': 0.0,
    'purchase_expenses': 0.0,
    'income_breakdown': [],
    'expense_breakdown': [],
    'expense_by_category': [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final data = await _apiReport.fetchFinancialReport(
      startDate: startDate,
      endDate: endDate,
    );
    setState(() {
      reportData = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List items = [];
    String titleLabel = '';
    double currentTotal = 1.0;
    Color themeColor = Colors.green;

    if (selectedTab == 0) {
      items = reportData['income_breakdown'];
      titleLabel = 'ប្រាក់ចំណូលតាមប្រភេទ';
      currentTotal =
          double.tryParse(reportData['total_income'].toString()) ?? 1.0;
      themeColor = Colors.green;
    } else if (selectedTab == 1) {
      items = reportData['expense_breakdown'];
      titleLabel = 'ការចំណាយទូទៅតាមប្រភេទ';
      currentTotal =
          double.tryParse(reportData['general_expenses'].toString()) ?? 1.0;
      themeColor = Colors.orange.shade700;
    } else if (selectedTab == 2) {
      items = reportData['expense_by_category'];
      titleLabel = 'ការចំណាយតាម Category ផលិតផល';
      currentTotal =
          double.tryParse(reportData['purchase_expenses'].toString()) ?? 1.0;
      themeColor = Colors.red;
    } else {
      items = [
        {
          'category_name': 'ចំណាយទូទៅ',
          'total_amount': reportData['general_expenses'],
        },
        {
          'category_name': 'ចំណាយស្តុក',
          'total_amount': reportData['purchase_expenses'],
        },
      ];
      titleLabel = 'សង្ខេបការចំណាយសរុប';
      currentTotal =
          double.tryParse(reportData['total_expense'].toString()) ?? 1.0;
      themeColor = Colors.deepOrange;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'ក្រាហ្វិកវិភាគហិរញ្ញវត្ថុ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 🔘 Segmented Tabs ទាំង ៤ (រៀបចំឱ្យរអិលមើលបាន ឬធំទូលាយស្អាត)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabButton('ចំណូល', 0, Colors.green),
                        const SizedBox(width: 8),
                        _buildTabButton('ចំណាយទូទៅ', 1, Colors.orange.shade700),
                        const SizedBox(width: 8),
                        _buildTabButton('ចំណាយស្តុក', 2, Colors.red),
                        const SizedBox(width: 8),
                        _buildTabButton('ចំណាយសរុប', 3, Colors.deepOrange),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 📊 ផ្នែក Donut Chart Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 240,
                        child: items.isEmpty
                            ? const Center(
                                child: Text(
                                  'មិនមានទិន្នន័យសម្រាប់បង្ហាញក្រាហ្វិកទេ',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sectionsSpace: 3,
                                      centerSpaceRadius: 60,
                                      sections: _generateChartSections(
                                        items,
                                        currentTotal,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedTab == 0
                                            ? 'ចំណូលសរុប'
                                            : 'ចំណាយសរុប',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "\$${currentTotal.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      if (items.isNotEmpty)
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(items.length, (index) {
                            final item = items[index];
                            String name = selectedTab == 1
                                ? (item['expense_type']?['name'] ?? 'ផ្សេងៗ')
                                : (item['category_name'] ?? 'ផ្សេងៗ');
                            Color color = _getColor(index);

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 📝 បញ្ជីរាយមុខទំនិញលម្អិត
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      titleLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                items.isEmpty
                    ? const SizedBox()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final double amount =
                              double.tryParse(
                                item['total_amount'].toString(),
                              ) ??
                              0.0;

                          String name = '';
                          String? imageUrl;
                          if (selectedTab == 0) {
                            name = item['category_name'] ?? 'ផ្សេងៗ';
                            imageUrl = item['image'];
                          } else if (selectedTab == 1) {
                            name = item['expense_type']?['name'] ?? 'ផ្សេងៗ';
                            imageUrl = item['expense_type']?['image'];
                          } else if (selectedTab == 2) {
                            name = item['category_name'] ?? 'ផ្សេងៗ';
                            imageUrl = item['image'];
                          } else {
                            name = item['category_name'] ?? '';
                          }

                          const String baseServerUrl =
                              BaseImageUrl.BaseimageUrl;
                          String? finalImageUrl;
                          if (imageUrl != null && imageUrl.trim().isNotEmpty) {
                            if (imageUrl.startsWith('http://') ||
                                imageUrl.startsWith('https://')) {
                              finalImageUrl = imageUrl;
                            } else {
                              String cleanPath = imageUrl.startsWith('/')
                                  ? imageUrl.substring(1)
                                  : imageUrl;
                              finalImageUrl = '$baseServerUrl/$cleanPath';
                            }
                          }

                          double percentage = currentTotal > 0
                              ? (amount / currentTotal) * 100
                              : 0;
                          Color itemColor = _getColor(index);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: itemColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: (finalImageUrl != null)
                                            ? Image.network(
                                                finalImageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Center(
                                                        child: Icon(
                                                          selectedTab == 0
                                                              ? Icons
                                                                    .arrow_upward_rounded
                                                              : Icons
                                                                    .receipt_long_rounded,
                                                          color: itemColor,
                                                          size: 20,
                                                        ),
                                                      );
                                                    },
                                              )
                                            : Center(
                                                child: Icon(
                                                  selectedTab == 0
                                                      ? Icons
                                                            .arrow_upward_rounded
                                                      : Icons
                                                            .receipt_long_rounded,
                                                  color: itemColor,
                                                  size: 20,
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
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}% នៃទឹកប្រាក់សរុប',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      selectedTab == 0
                                          ? "+\$${amount.toStringAsFixed(2)}"
                                          : "-\$${amount.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: itemColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: currentTotal > 0
                                        ? amount / currentTotal
                                        : 0,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      itemColor,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }

  Widget _buildTabButton(String title, int index, Color activeColor) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 85,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateChartSections(List items, double total) {
    return List.generate(items.length, (index) {
      final item = items[index];
      final double amount =
          double.tryParse(item['total_amount'].toString()) ?? 0.0;
      double percentage = total > 0 ? (amount / total) * 100 : 0;

      return PieChartSectionData(
        color: _getColor(index),
        value: amount,
        title: percentage > 4 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 45,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
    ];
    return colors[index % colors.length];
  }
}

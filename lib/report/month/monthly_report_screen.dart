import 'package:flutter/material.dart';
import 'package:pos_inventory/api/report/api_report.dart';
import 'monthly_products_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final ApiReport _apiMonthlyReport = ApiReport();
  List<Map<String, dynamic>> _monthlyData = [];
  bool _isLoading = true;
  int _selectedYear = 2025;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _loadData(_selectedYear);
  }

  Future<void> _loadData(int year) async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> data = await _apiMonthlyReport
        .fetchMonthlyReport(year: year);

    if (data.isEmpty) {
      data = [
        {'month': 1, 'name': 'Jan', 'orders': 45, 'revenue': 1250.00},
        {'month': 2, 'name': 'Feb', 'orders': 60, 'revenue': 1890.50},
        {'month': 3, 'name': 'Mar', 'orders': 35, 'revenue': 980.00},
        {'month': 4, 'name': 'Apr', 'orders': 80, 'revenue': 2450.00},
        {'month': 5, 'name': 'May', 'orders': 95, 'revenue': 3120.00},
        {'month': 6, 'name': 'Jun', 'orders': 50, 'revenue': 1550.00},
        {'month': 10, 'name': 'Oct', 'orders': 2, 'revenue': 11.50},
      ];
    }

    setState(() {
      _monthlyData = data;
      _isLoading = false;
    });
  }

  Color _getMonthColor(int month) {
    const colors = [
      Color(0xFF4F46E5), // Jan
      Color(0xFF0EA5E9), // Feb
      Color(0xFF10B981), // Mar
      Color(0xFFF59E0B), // Apr
      Color(0xFFEC4899), // May
      Color(0xFF8B5CF6), // Jun
      Color(0xFF06B6D4), // Jul
      Color(0xFF84CC16), // Aug
      Color(0xFFF97316), // Sep
      Color(0xFF6366F1), // Oct
      Color(0xFF14B8A6), // Nov
      Color(0xFFE11D48), // Dec
    ];
    if (month >= 1 && month <= 12) {
      return colors[month - 1];
    }
    return const Color(0xFF4F46E5);
  }

  @override
  Widget build(BuildContext context) {
    double totalYearRevenue = _foldTotal(_monthlyData, 'revenue');
    int totalYearOrders = _foldTotal(_monthlyData, 'orders').toInt();
    double avgMonthly = _monthlyData.isEmpty
        ? 0
        : totalYearRevenue / _monthlyData.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'របាយការណ៍ប្រចាំខែ',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
              ),
            ),
            child: DropdownButton<int>(
              value: _selectedYear,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF4F46E5),
                size: 18,
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              items: [2024, 2025, 2026].map((int year) {
                return DropdownMenuItem<int>(value: year, child: Text('$year'));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedYear = value);
                  _loadData(value);
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF4F46E5),
              onRefresh: () => _loadData(_selectedYear),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌟 Premium Analytics Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4F46E5),
                            Color(0xFF6366F1),
                            Color(0xFF818CF8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4F46E5,
                            ).withValues(alpha: 0.35),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ប្រាក់ចំណូលសរុបឆ្នាំ $_selectedYear',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_graph_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Live Report',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${totalYearRevenue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildInteractiveBarChart(),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildHeaderStatItem(
                                  icon: Icons.receipt_long_rounded,
                                  title: 'ចំនួនបញ្ជាទិញសរុប',
                                  value: '$totalYearOrders ដង',
                                ),
                                Container(
                                  height: 32,
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                _buildHeaderStatItem(
                                  icon: Icons.trending_up_rounded,
                                  title: 'ជាមធ្យមប្រចាំខែ',
                                  value: '\$${avgMonthly.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 📋 Section Title (Fixed with Expanded to prevent overflow)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'ព័ត៌មានលម្អិតតាមខែ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_monthlyData.length} ខែមានទិន្នន័យ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 📦 List of Months with Click Action
                    _monthlyData.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _monthlyData.length,
                            itemBuilder: (context, index) {
                              final item = _monthlyData[index];
                              return _buildMonthlyCardWithProgress(item);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  double _foldTotal(List<Map<String, dynamic>> list, String key) {
    double sum = 0.0;
    for (var element in list) {
      sum += (element[key] ?? 0.0);
    }
    return sum;
  }

  Widget _buildInteractiveBarChart() {
    double maxRev = 0;
    for (var item in _monthlyData) {
      double rev = (item['revenue'] ?? 0.0).toDouble();
      if (rev > maxRev) maxRev = rev;
    }

    return SizedBox(
      height: 75,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _monthlyData.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          int monthNum = item['month'] ?? (index + 1);
          double currentRev = (item['revenue'] ?? 0.0).toDouble();
          double heightPerc = maxRev == 0 ? 0 : (currentRev / maxRev) * 55;
          bool isHovered = _hoveredIndex == index;
          Color monthColor = _getMonthColor(monthNum);

          return GestureDetector(
            onTap: () {
              setState(() => _hoveredIndex = isHovered ? null : index);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isHovered)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '\$${currentRev.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: monthColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  width: 14,
                  height: heightPerc.clamp(6, 55),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? Colors.white
                        : Colors.white.withValues(
                            alpha: currentRev == 0 ? 0.2 : 0.8,
                          ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['name'] ?? '',
                  style: TextStyle(
                    color: isHovered
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Card Item with InkWell & Flexible Layout (No Overflow)
  Widget _buildMonthlyCardWithProgress(Map<String, dynamic> item) {
    int monthNum = item['month'] ?? 1;
    String monthName = item['name'] ?? '';
    Color monthColor = _getMonthColor(monthNum);
    double totalYearRevenue = _foldTotal(_monthlyData, 'revenue');
    double currentRev = (item['revenue'] ?? 0.0).toDouble();
    double percentage = totalYearRevenue == 0
        ? 0
        : (currentRev / totalYearRevenue);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
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
                builder: (context) => MonthlyProductsScreen(
                  year: _selectedYear,
                  month: monthNum,
                  monthName: monthName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    // 📅 Month Badge
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: monthColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          monthName,
                          style: TextStyle(
                            color: monthColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 📝 Details
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ខែទី $monthNum ($monthName)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'ចំនួនបញ្ជាទិញ៖ ${item['orders']} ដង',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
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

                    // 💰 Revenue Amount & Arrow Icon
                    Flexible(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '\$${currentRev.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.5,
                                    color: monthColor,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}% នៃឆ្នាំ',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 📉 Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(monthColor),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'មិនមានទិន្នន័យសម្រាប់ឆ្នាំនេះទេ',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

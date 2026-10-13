import 'package:flutter/material.dart';
import 'package:pos_inventory/api/report/api_report.dart';

class YearlyReportScreen extends StatefulWidget {
  const YearlyReportScreen({super.key});

  @override
  State<YearlyReportScreen> createState() => _YearlyReportScreenState();
}

class _YearlyReportScreenState extends State<YearlyReportScreen> {
  final ApiReport _apiReport = ApiReport();
  List<Map<String, dynamic>> _yearlyData = [];
  bool _isLoading = true;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _loadYearlyData();
  }

  Future<void> _loadYearlyData() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> data = await _apiReport.fetchYearlyReport();

      setState(() {
        _yearlyData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading yearly report: $e");
    }
  }

  double _foldTotal(List<Map<String, dynamic>> list, String key) {
    double sum = 0.0;
    for (var element in list) {
      sum += (element[key] ?? 0.0);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    double grandTotalRevenue = _foldTotal(_yearlyData, 'revenue');
    int grandTotalOrders = _foldTotal(_yearlyData, 'orders').toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'របាយការណ៍ប្រចាំឆ្នាំ',
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF059669),
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF059669),
              onRefresh: _loadYearlyData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF065F46), // Emerald Dark
                            Color(0xFF059669), // Emerald Mid
                            Color(0xFF10B981), // Emerald Light
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.3),
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
                              const Text(
                                'ប្រាក់ចំណូលសរុបគ្រប់ឆ្នាំ',
                                style: TextStyle(
                                  color: Colors.white70,
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
                                      Icons.insights_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'All-Time',
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
                            '\$${grandTotalRevenue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildYearlyBarChart(),
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
                                  title: 'បញ្ជាទិញសរុប',
                                  value: '$grandTotalOrders ដង',
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
                                  icon: Icons.calendar_today_rounded,
                                  title: 'ចំនួនឆ្នាំសរុប',
                                  value: '${_yearlyData.length} ឆ្នាំ',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 📋 Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'ព័ត៌មានលម្អិតតាមឆ្នាំ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                            '${_yearlyData.length} ឆ្នាំ',
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

                    // 📦 Yearly Cards List
                    _yearlyData.isEmpty
                        ? const Center(child: Text('មិនមានទិន្នន័យ'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _yearlyData.length,
                            itemBuilder: (context, index) {
                              final item = _yearlyData[index];
                              return _buildYearlyCard(item, index);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildYearlyBarChart() {
    double maxRev = 0;
    for (var item in _yearlyData) {
      double rev = (item['revenue'] ?? 0.0).toDouble();
      if (rev > maxRev) maxRev = rev;
    }

    return SizedBox(
      height: 75,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _yearlyData.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          double currentRev = (item['revenue'] ?? 0.0).toDouble();
          double heightPerc = maxRev == 0 ? 0 : (currentRev / maxRev) * 55;
          bool isHovered = _hoveredIndex == index;

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
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  width: 22,
                  height: heightPerc.clamp(8, 55),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? Colors.white
                        : Colors.white.withValues(
                            alpha: currentRev == 0 ? 0.2 : 0.8,
                          ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item['year']}',
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

  Widget _buildYearlyCard(Map<String, dynamic> item, int index) {
    int year = item['year'];
    double revenue = (item['revenue'] ?? 0.0).toDouble();
    int orders = item['orders'] ?? 0;
    double grandTotalRevenue = _foldTotal(_yearlyData, 'revenue');
    double percentage = grandTotalRevenue == 0
        ? 0
        : (revenue / grandTotalRevenue);

    const cardColor = Color(0xFF059669);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$year',
                    style: const TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ឆ្នាំរបាយការណ៍ $year',
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
                            'ចំនួនបញ្ជាទិញ៖ $orders ដង',
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
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${revenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        color: cardColor,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}% នៃសរុប',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(cardColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

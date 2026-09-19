import 'package:flutter/material.dart';
import '../../api/report/api_report.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final ApiReport _apiReport = ApiReport();
  bool isLoading = true;

  // 📅 កាលបរិច្ឆេទសម្រាប់ Filter
  String? startDate;
  String? endDate;

  Map<String, dynamic> reportData = {
    'total_income': 0.0,
    'total_expense': 0.0,
    'general_expenses': 0.0,
    'purchase_expenses': 0.0,
    'net_profit': 0.0,
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

  // 🗓️ មុខងារជ្រើសរើសកាលបរិច្ឆេទ
  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      currentDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start.toIso8601String().split('T')[0];
        endDate = picked.end.toIso8601String().split('T')[0];
      });
      _loadData();
    }
  }

  void _clearFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Background ពណ៌ប្រផេះខ្ចីទន់ៗស្អាត
      appBar: AppBar(
        title: const Text(
          'របាយការណ៍ហិរញ្ញវត្ថុ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, color: Color(0xFF2563EB)),
            onPressed: _selectDateRange,
            tooltip: 'ជ្រើសរើសខែ/ឆ្នាំ',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : RefreshIndicator(
        color: const Color(0xFF2563EB),
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🌟 1. ផ្នែកបង្ហាញសង្ខេបទឹកប្រាក់បែប Gradient Dashboard Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Net Profit (ប្រាក់សល់ធំជាងគេនៅចំកណ្តាលខាងលើ)
                  const Text(
                    'ប្រាក់ចំណេញសុទ្ធ (Net Profit)',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "\$${reportData['net_profit']}",
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white24, height: 1),
                  ),
                  // Total Income & Total Expense ខាងក្រោម
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderSummaryItem(
                        title: 'ចំណូលសរុប',
                        amount: "\$${reportData['total_income']}",
                        color: Colors.greenAccent.shade200,
                        icon: Icons.arrow_downward_rounded,
                      ),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildHeaderSummaryItem(
                        title: 'ចំណាយសរុប',
                        amount: "\$${reportData['total_expense']}",
                        color: Colors.redAccent.shade100,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 📅 បង្ហាញស្ថានភាព Filter កាលបរិច្ឆេទ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        startDate != null && endDate != null
                            ? '$startDate ដល់ $endDate'
                            : 'បង្ហាញទិន្នន័យសរុបទាំងអស់ (All Time)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  if (startDate != null && endDate != null)
                    TextButton.icon(
                      onPressed: _clearFilter,
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      label: const Text('សម្អាត', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 💡 2. ប្រអប់រំលេចប្រភេទការចំណាយ (General & Purchase)
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    title: 'ចំណាយទូទៅ',
                    subtitle: '(General)',
                    amount: "\$${reportData['general_expenses']}",
                    icon: Icons.receipt_long_rounded,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    title: 'ចំណាយទិញស្តុក',
                    subtitle: '(Purchase)',
                    amount: "\$${reportData['purchase_expenses']}",
                    icon: Icons.shopping_bag_rounded,
                    color: Colors.purple.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🟢 3. ចំណូលតាមប្រភេទ (Income Breakdown)
            _buildSectionHeader('ចំណូលតាមប្រភេទ (Income Breakdown)', Icons.trending_up_rounded, Colors.green),
            const SizedBox(height: 10),
            reportData['income_breakdown'].isEmpty
                ? _buildEmptyBox('មិនមានទិន្នន័យចំណូលតាមប្រភេទទេ')
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reportData['income_breakdown'].length,
              itemBuilder: (context, index) {
                final item = reportData['income_breakdown'][index];
                return _buildBreakdownTile(
                  title: item['category_name'] ?? 'General Income',
                  subtitle: 'ចំណូលតាមប្រភេទ',
                  amount: "+\$${item['total_amount']}",
                  color: Colors.green.shade600,
                  fallbackIcon: Icons.arrow_upward_rounded,
                  bgColor: Colors.green.shade50,
                  imageUrl: item['image'],
                );
              },
            ),
            const SizedBox(height: 24),

            // 🔴 4. ការចំណាយលម្អិតតាមប្រភេទ (Expense Breakdown)
            _buildSectionHeader('ការចំណាយតាមប្រភេទ (Expense Breakdown)', Icons.trending_down_rounded, Colors.red),
            const SizedBox(height: 10),
            reportData['expense_breakdown'].isEmpty
                ? _buildEmptyBox('មិនមានទិន្នន័យចំណាយតាមប្រភេទទេ')
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reportData['expense_breakdown'].length,
              itemBuilder: (context, index) {
                final item = reportData['expense_breakdown'][index];
                return _buildBreakdownTile(
                  title: item['expense_type']?['name'] ?? 'General Expense',
                  subtitle: 'ប្រភេទចំណាយ',
                  amount: "-\$${item['total_amount']}",
                  color: Colors.red.shade600,
                  fallbackIcon: Icons.receipt_rounded,
                  bgColor: Colors.red.shade50,
                  imageUrl: item['expense_type']?['image'],
                );
              },
            ),
            const SizedBox(height: 24),

            // 🟣 5. ចំណាយតាម Category ផលិតផល (Expense by Category)
            _buildSectionHeader('ការចំណាយតាម Category ផលិតផល', Icons.category_rounded, Colors.purple),
            const SizedBox(height: 10),
            reportData['expense_by_category'].isEmpty
                ? _buildEmptyBox('មិនមានទិន្នន័យចំណាយតាម Category ទេ')
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reportData['expense_by_category'].length,
              itemBuilder: (context, index) {
                final item = reportData['expense_by_category'][index];
                return _buildBreakdownTile(
                  title: item['category_name'] ?? 'Product Category',
                  subtitle: 'ចំណាយទិញស្តុកតាម Category',
                  amount: "-\$${item['total_amount']}",
                  color: Colors.purple.shade600,
                  fallbackIcon: Icons.shopping_cart_rounded,
                  bgColor: Colors.purple.shade50,
                  imageUrl: item['image'],
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🔹 Widget សម្រាប់ក្បាលផ្នែកនីមួយៗ (Section Header)
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildHeaderSummaryItem({required String title, required String amount, required Color color, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(amount, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard({required String title, required String subtitle, required String amount, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                const SizedBox(height: 6),
                Text(amount, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownTile({
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
    required IconData fallbackIcon,
    required Color bgColor,
    String? imageUrl,
  }) {
    const String baseServerUrl = "http://10.0.2.2:8000/";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🖼️ Rounded Avatar Image or Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              image: (imageUrl != null && imageUrl.isNotEmpty)
                  ? DecorationImage(
                image: NetworkImage(imageUrl.startsWith('http') ? imageUrl : '$baseServerUrl$imageUrl'),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: (imageUrl == null || imageUrl.isEmpty)
                ? Icon(fallbackIcon, color: color, size: 22)
                : null,
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(message, style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}
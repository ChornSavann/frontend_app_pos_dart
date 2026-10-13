import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_purchase.dart';
import 'package:pos_inventory/report/history/purchase_detail_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _purchasesList = [];
  List<dynamic> _filteredPurchasesList = [];
  final ApiPurchase _apiPurchase = ApiPurchase();

  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiPurchase.getAllPurchaseHistory();
      setState(() {
        _purchasesList = response ?? [];
        _filteredPurchasesList = _purchasesList;
        _isLoading = false;
      });
      _filterData();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Error fetching purchases: $e");
    }
  }

  // 🛠️ មុខងារសម្រាប់កាត់តម្រឹមយកតែ ថ្ងៃខែឆ្នាំ (YYYY-MM-DD)
  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      DateTime? parsedDate = DateTime.tryParse(rawDate);
      if (parsedDate != null) {
        return parsedDate.toLocal().toString().split(
          ' ',
        )[0];
      }

      return rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    } catch (e) {
      return rawDate;
    }
  }

  void _filterData() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredPurchasesList = _purchasesList.where((purchase) {
        String refNo =
            (purchase['reference_no'] ?? purchase['purchase_no'] ?? '')
                .toString()
                .toLowerCase();
        String supplierName =
            (purchase['supplier_name'] ?? purchase['supplier']?['name'] ?? '')
                .toString()
                .toLowerCase();

        bool matchesSearch =
            refNo.contains(query) || supplierName.contains(query);

        bool matchesDate = true;
        String dateStr = purchase['date'] ?? purchase['created_at'] ?? '';
        if (dateStr.isNotEmpty) {
          DateTime? purchaseDate = DateTime.tryParse(dateStr);
          if (purchaseDate != null) {
            if (_startDate != null) {
              DateTime start = DateTime(
                _startDate!.year,
                _startDate!.month,
                _startDate!.day,
              );
              if (purchaseDate.isBefore(start)) {
                matchesDate = false;
              }
            }
            if (_endDate != null) {
              DateTime end = DateTime(
                _endDate!.year,
                _endDate!.month,
                _endDate!.day,
                23,
                59,
                59,
              );
              if (purchaseDate.isAfter(end)) {
                matchesDate = false;
              }
            }
          }
        }

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF4F46E5),
            colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filterData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _filterData();
  }

  @override
  Widget build(BuildContext context) {
    bool isFiltered = _startDate != null && _endDate != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'ប្រវត្តិការទិញចូល (Purchase History)',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'ស្វែងរកតាម Supplier ឬ Ref No...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.grey.shade500,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterData();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: isFiltered
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _selectDateRange,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.date_range_rounded,
                            color: isFiltered
                                ? Colors.white
                                : const Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isFiltered) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list_rounded,
                          size: 16,
                          color: Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_startDate!.toLocal().toString().split(' ')[0]} ➔ ${_endDate!.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _clearDateFilter,
                          child: const Text(
                            'លុបតម្រង',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  )
                : _filteredPurchasesList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'រកមិនឃើញទិន្នន័យប្រវត្តិការទិញចូលទេ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF4F46E5),
                    onRefresh: _fetchPurchases,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPurchasesList.length,
                      itemBuilder: (context, index) {
                        final purchase = _filteredPurchasesList[index];
                        String refNo =
                            purchase['reference_no'] ??
                            purchase['purchase_no'] ??
                            'PUR-N/A';
                        double amount =
                            double.tryParse(
                              (purchase['total_amount'] ??
                                      purchase['total'] ??
                                      0)
                                  .toString(),
                            ) ??
                            0.0;
                        List items =
                            purchase['details'] ?? purchase['items'] ?? [];
                        String status = purchase['status'] ?? 'Received';
                        String supplierName =
                            purchase['supplier_name'] ??
                            purchase['supplier']?['name'] ??
                            refNo;

                        // 📅 កោះហៅប្រើប្រាស់ Function Format ថ្ងៃខែ
                        String formattedDate = _formatDate(
                          purchase['date'] ?? purchase['created_at'],
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PurchaseDetailScreen(purchase: purchase),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping_rounded,
                                      color: Color(0xFF4F46E5),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          supplierName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Items: ${items.length}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                formattedDate, // 👈 បង្ហាញថ្ងៃខែឆ្នាំដែលបាន Format រួច
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 11.5,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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

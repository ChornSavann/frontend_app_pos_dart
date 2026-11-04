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
        (purchase['reference_no'] ?? purchase['purchase_number'] ?? '')
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

  // ───────────────────────── UI ONLY (no logic changes) ─────────────────────────

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _bg = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    bool isFiltered = _startDate != null && _endDate != null;

    // សរុបសម្រាប់បង្ហាញលើ Hero Card (អានពីទិន្នន័យដែលមានស្រាប់ មិនប៉ះពាល់ Logic)
    double grandTotal = 0;
    for (final p in _filteredPurchasesList) {
      grandTotal +=
          double.tryParse((p['total_amount'] ?? p['total'] ?? 0).toString()) ??
              0.0;
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _ink),
        title: const Text(
          'ប្រវត្តិការទិញចូល (Purchase History)',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      body: Column(
        children: [
          // ───────── Search + Date filter ─────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EBF3)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: _ink),
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
                          icon: Icon(
                            Icons.cancel_rounded,
                            size: 19,
                            color: Colors.grey.shade400,
                          ),
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
                  color: isFiltered ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFiltered
                              ? _primary
                              : const Color(0xFFE8EBF3),
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: isFiltered ? Colors.white : _primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isFiltered)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_rounded,
                      size: 16,
                      color: _primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_startDate!.toLocal().toString().split(' ')[0]} ➔ ${_endDate!.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primary,
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
                          color: Color(0xFFE11D48),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ───────── Hero summary card ─────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -40,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.09),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 50,
                      bottom: -50,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'សរុបទឹកប្រាក់ទិញចូល',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '\$${grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_filteredPurchasesList.length}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'វិក្កយបត្រ',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ───────── List ─────────
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
                : _filteredPurchasesList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 46,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'រកមិនឃើញទិន្នន័យប្រវត្តិការទិញចូលទេ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: _primary,
              onRefresh: _fetchPurchases,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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

                  // UI only: អក្សរដំបូងសម្រាប់ Avatar, ពណ៌ស្ថានភាព
                  final String initial = supplierName.trim().isEmpty
                      ? '?'
                      : String.fromCharCode(
                    supplierName.trim().runes.first,
                  ).toUpperCase();
                  final bool hasRef =
                      purchase['reference_no'] != null ||
                          purchase['purchase_no'] != null;
                  final bool isDone = [
                    'received',
                    'completed',
                    'paid',
                  ].contains(status.toLowerCase());
                  final Color statusColor = isDone
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706);
                  final Color statusBg = isDone
                      ? const Color(0xFFE7F8F0)
                      : const Color(0xFFFFF4DB);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEEF0F6)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E293B).withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PurchaseDetailScreen(
                                purchase: purchase,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              // Avatar (អក្សរដំបូងរបស់ Supplier)
                              Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: _primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      supplierName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: _ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (hasRef) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        refNo,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: _muted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 12,
                                          color: _muted,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            formattedDate, // 👈 បង្ហាញថ្ងៃខែឆ្នាំដែលបាន Format រួច
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 11.5,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 12,
                                          color: _muted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Items: ${items.length}',
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      color: _ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
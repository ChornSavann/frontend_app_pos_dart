import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/api/report/api_report.dart';
import 'package:pos_inventory/models/reports/report_daily.dart';
import 'package:pos_inventory/report/invoice/invoice_print_screen.dart';

class ListInvoiceScreen extends StatefulWidget {
  const ListInvoiceScreen({super.key});

  @override
  State<ListInvoiceScreen> createState() => _ListInvoiceScreenState();
}

class _ListInvoiceScreenState extends State<ListInvoiceScreen> {
  final ApiReport _apiReport = ApiReport();
  late final Future<List<ReportDaily>> _ordersFuture = _apiReport
      .getAllOrders();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Completed, Pending

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'ប្រវត្តិការលក់',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFF1E293B),
            fontFamily: 'KantumruyPro',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar & Filter Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Pill-shaped Search Input
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by Order number or Name Customer..',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 🎛️ Filter Buttons (Theme ពណ៌បៃតង)
                Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 📋 Invoices List
          Expanded(
            child: FutureBuilder<List<ReportDaily>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'មានបញ្ហាក្នុងការទាញយកទិន្នន័យ: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  );
                }

                List<ReportDaily> invoices = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  invoices = invoices.where((inv) {
                    final orderNo = inv.orderNumber.toLowerCase();
                    final custName = (inv.customer?.name ?? '').toLowerCase();
                    return orderNo.contains(_searchQuery.toLowerCase()) ||
                        custName.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (_selectedFilter != 'All') {
                  invoices = invoices.where((inv) {
                    return inv.status.toLowerCase() ==
                        _selectedFilter.toLowerCase();
                  }).toList();
                }

                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'មិនមានទិន្នន័យវិក្កយបត្រទេ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadOrders(),
                  color: const Color(0xFF10B981),
                  child: ListView.builder(
                    itemCount: invoices.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      final statusLower = invoice.status.toLowerCase();

                      // 🟢 Status Color & Text style matching reference image
                      bool isCompleted =
                          statusLower == 'completed' ||
                          statusLower == 'success' ||
                          statusLower == 'paid';
                      Color statusColor = isCompleted
                          ? const Color(0xFF10B981)
                          : Colors.orange;

                      String formattedDate = invoice.createdAt;
                      try {
                        DateTime parsedDate = DateTime.parse(
                          invoice.createdAt,
                        ).toLocal();
                        formattedDate =
                            "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
                      } catch (_) {
                        formattedDate = invoice.createdAt.contains('T')
                            ? invoice.createdAt.split('T').first
                            : invoice.createdAt;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InvoicePrintScreen(order: invoice),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // 🟢 Icon ម៉ាស៊ីនគិតលុយក្នុង Circle ពណ៌បៃតងខ្ចី ដូចក្នុងរូប Sample
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.point_of_sale_rounded,
                                      color: Color(0xFF10B981),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invoice.orderNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'អតិថិជន: ${invoice.customer?.name ?? 'Guest'}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          '📅 $formattedDate',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // 🟢 តម្លៃពណ៌បៃតងស្អាត
                                      Text(
                                        '\$${invoice.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // 🟢 Status Text ពណ៌បៃតង (COMPLETED)
                                      Text(
                                        invoice.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Filter Chip Widget with Green Theme
  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

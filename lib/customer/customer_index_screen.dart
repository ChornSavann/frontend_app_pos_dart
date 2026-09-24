import 'dart:core';
import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_customer.dart';
import 'package:pos_inventory/customer/customer_create_screen.dart';
import 'package:pos_inventory/customer/customer_update_screen.dart';
import 'package:pos_inventory/customer/customer_detail_screen.dart';
import 'package:pos_inventory/models/customer.dart';

class CustomerIndexScreen extends StatefulWidget {
  const CustomerIndexScreen({super.key});

  @override
  State<CustomerIndexScreen> createState() => _CustomerIndexScreenState();
}

class _CustomerIndexScreenState extends State<CustomerIndexScreen> {
  final ApiCustomer apiCustomer = ApiCustomer();

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    apiCustomer.getAllCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'KhmerOSBattambang',
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(String message, {VoidCallback? onDeleteOrClose}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ជោគជ័យ!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'KhmerOSBattambang',
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'KhmerOSBattambang',
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (onDeleteOrClose != null) {
                      onDeleteOrClose();
                    }
                  },
                  child: const Text(
                    "យល់ព្រម",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'KhmerOSBattambang',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(int customerId, String customerName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "បញ្ជាក់ការលុប",
            style: TextStyle(
              fontFamily: 'KhmerOSBattambang',
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "តើអ្នកពិតជាចង់លុបអតិថិជនឈ្មោះ \"$customerName\" នេះមែនទេ?",
            style: TextStyle(
              fontFamily: 'KhmerOSBattambang',
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "បោះបង់",
                style: TextStyle(
                  fontFamily: 'KhmerOSBattambang',
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                bool success = await ApiCustomer().deleteCustomer(customerId);
                if (!mounted) return;

                if (success) {
                  _showSuccessDialog(
                    "បានលុបអតិថិជនចេញពីប្រព័ន្ធដោយជោគជ័យ!",
                    onDeleteOrClose: () {
                      setState(() {});
                    },
                  );
                } else {
                  _showSnackBar("មានបញ្ហាក្នុងការលុបអតិថិជន!", isError: true);
                }
              },
              child: const Text(
                "លុប",
                style: TextStyle(
                  fontFamily: 'KhmerOSBattambang',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'KhmerOSBattambang',
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: "ស្វែងរកឈ្មោះ ឬអ៊ីម៉ែល...",
                  hintStyle: TextStyle(
                    fontFamily: 'KhmerOSBattambang',
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text(
                "បញ្ជីអតិថិជន (Customers)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'KhmerOSBattambang',
                ),
              ),
        centerTitle: !_isSearching,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                size: 22,
              ),
              color: Colors.blueAccent,
              tooltip: _isSearching ? 'បិទការស្វែងរក' : 'ស្វែងរកអតិថិជន',
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = "";
                  }
                });
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              color: Colors.blueAccent,
              tooltip: 'ផ្ទុកទិន្នន័យឡើងវិញ',
              onPressed: () {
                setState(() {
                  apiCustomer.getAllCustomers();
                });
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Customer>>(
        future: apiCustomer.getAllCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "មានបញ្ហា៖ ${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'KhmerOSBattambang',
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "ព្យាយាមម្តងទៀត",
                        style: TextStyle(fontFamily: 'KhmerOSBattambang'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "មិនមានទិន្នន័យអតិថិជនទេ",
                    style: TextStyle(
                      fontFamily: 'KhmerOSBattambang',
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final allCustomers = snapshot.data!;
          final customers = allCustomers.where((cust) {
            final nameLower = (cust.name ?? '').toLowerCase();
            final emailLower = (cust.email ?? '').toLowerCase();
            return nameLower.contains(_searchQuery) ||
                emailLower.contains(_searchQuery);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ចំនួនអតិថិជនសរុប៖",
                      style: TextStyle(
                        fontFamily: 'KhmerOSBattambang',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Text(
                      "${customers.length} នាក់",
                      style: const TextStyle(
                        fontFamily: 'KhmerOSBattambang',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "រកមិនឃើញអតិថិជនដែលស្វែងរកទេ",
                              style: TextStyle(
                                fontFamily: 'KhmerOSBattambang',
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final cust = customers[index];
                          final customerName = cust.name ?? 'គ្មានឈ្មោះ';
                          final customerEmail = cust.email ?? '';
                          final int invoiceCount = cust.ordersCount ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDarkMode ? 0.3 : 0.04,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerDetailScreen(
                                      customerId: cust.id,
                                      customerName: customerName,
                                    ),
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(
                                  customerName.isNotEmpty
                                      ? customerName[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'KhmerOSBattambang',
                                  ),
                                ),
                              ),
                              title: Text(
                                customerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  fontFamily: 'KhmerOSBattambang',
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (customerEmail.isNotEmpty)
                                    Text(
                                      customerEmail,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'KhmerOSBattambang',
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  if (cust.phone != null &&
                                      cust.phone!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "ទូរស័ព្ទ៖ ${cust.phone}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'KhmerOSBattambang',
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  // 🧾 បង្ហាញចំនួន Invoice របស់អតិថិជនម្នាក់ៗ
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "វិក្កយបត្រ (Invoice): $invoiceCount",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                        fontFamily: 'KhmerOSBattambang',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: SizedBox(
                                width: 130,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "${cust.points}ពិន្ទុ",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            fontFamily: 'KhmerOSBattambang',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.grey,
                                      ),
                                      onSelected: (String value) async {
                                        if (value == 'edit') {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CustomerUpdateScreen(
                                                    customerId: cust.id,
                                                  ),
                                            ),
                                          );

                                          if (result == true) {
                                            _showSnackBar(
                                              "បានអាប់ដេតព័ត៌មានអតិថិជនដោយជោគជ័យ!",
                                            );
                                            setState(() {});
                                          }
                                        } else if (value == 'delete') {
                                          _showDeleteConfirmDialog(
                                            cust.id,
                                            customerName,
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit_rounded,
                                                    color: Colors.blueAccent,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'កែសម្រួល',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'KhmerOSBattambang',
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_rounded,
                                                    color: Colors.redAccent,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'លុប',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'KhmerOSBattambang',
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
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
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerCreateScreen(),
            ),
          );

          if (result == true) {
            _showSnackBar("បានអាប់ដេតបញ្ជីអតិថិជនថ្មី!");
            setState(() {});
          }
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "បន្ថែមអតិថិជន",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'KhmerOSBattambang',
          ),
        ),
      ),
    );
  }
}

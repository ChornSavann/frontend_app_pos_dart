import 'package:flutter/material.dart';
import 'package:pos_inventory/api/expensetype/api_expensetype.dart';
import 'package:pos_inventory/expensetype/create_expens_type_screen.dart';
import 'package:pos_inventory/expensetype/update_expense_type_screen.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';

import 'models/expense_type.dart';

class IndexExpensetypeSreen extends StatefulWidget {
  const IndexExpensetypeSreen({super.key});

  @override
  State<IndexExpensetypeSreen> createState() => _IndexExpensetypeSreenState();
}

class _IndexExpensetypeSreenState extends State<IndexExpensetypeSreen> {
  final ApiExpensetype apiExpensetype = ApiExpensetype();
  late Future<List<ExpenseType>> _futureExpenseTypes;

  @override
  void initState() {
    super.initState();
    _loadExpenseTypes();
  }

  void _loadExpenseTypes() {
    setState(() {
      _futureExpenseTypes = apiExpensetype.fetchExpenseType();
    });
  }

  // 🗑️ Function សម្រាប់លុបទិន្នន័យពិតប្រាកដតាមរយៈ API
  void _deleteExpenseType(int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Expense Type",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'KantumruyPro'),
        ),
        content: const Text(
          "Are you sure you want to delete this item?",
          style: TextStyle(fontFamily: 'KantumruyPro'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              bool success = await apiExpensetype.deleteExpenseType(id);
              if (!mounted) return;

              if (success) {
                _loadExpenseTypes();
                AppSnackBar.showSuccess(context, "Deleted successfully! 🗑️");
              } else {
                AppSnackBar.showError(context, "Failed to delete item! ❌");
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // ផ្លាស់ប្ដូរពណ៌ផ្ទៃខាងក្រោយឱ្យទន់ស្អាតជាងមុន
      appBar: AppBar(
        title: const Text(
          "Expense Types",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontFamily: 'KantumruyPro',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: FutureBuilder<List<ExpenseType>>(
        future: _futureExpenseTypes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    "No expense types found.",
                    style: TextStyle(color: Colors.grey, fontSize: 15, fontFamily: 'KantumruyPro'),
                  ),
                ],
              ),
            );
          }

          final expenseTypes = snapshot.data!;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: expenseTypes.length,
            itemBuilder: (context, index) {
              final item = expenseTypes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      // 🟢 Icon ខាងមុខ
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // 🟢 Name & Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name ?? 'No Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                                fontFamily: 'KantumruyPro',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description ?? 'No description',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'KantumruyPro',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 🟢 Edit & Delete Action Buttons (មាន Background ស្រទន់ស្អាត)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✏️ Edit Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateExpenseTypeScreen(
                                      expenseTypeId: item.id ?? 0,
                                      initialName: item.name ?? '',
                                      initialDescription: item.description ?? '',
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadExpenseTypes();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 🗑️ Delete Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.delete_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              onPressed: () {
                                if (item.id != null) {
                                  _deleteExpenseType(item.id ?? 0);
                                } else {
                                  AppSnackBar.showError(
                                    context,
                                    "Error: Item ID is null! ❌",
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateExpensTypeScreen(),
              ),
            );

            if (result == true) {
              _loadExpenseTypes();
            }
          },
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            "Add New",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              fontFamily: 'KantumruyPro',
            ),
          ),
        ),
      ),
    );
  }
}
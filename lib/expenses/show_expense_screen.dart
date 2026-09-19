import 'package:flutter/material.dart';
import 'package:pos_inventory/api/expense/api_expense.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';
import 'package:pos_inventory/expenses/update_expense_screen.dart';
import 'models/expense.dart';

class ShowExpenseScreen extends StatefulWidget {
  final int expenseId;

  const ShowExpenseScreen({super.key, required this.expenseId});

  @override
  State<ShowExpenseScreen> createState() => _ShowExpenseScreenState();
}

class _ShowExpenseScreenState extends State<ShowExpenseScreen> {
  final ApiExpense apiExpense = ApiExpense();
  Expense? _expense;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenseDetail();
  }

  Future<void> _loadExpenseDetail() async {
    setState(() {
      _isLoading = true;
    });

    final expense = await apiExpense.fetchExpenseById(widget.expenseId);

    setState(() {
      _expense = expense;
      _isLoading = false;
    });

    if (expense == null && mounted) {
      AppSnackBar.showError(context, "Failed to load expense details! ❌");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Expense Details",
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
        actions: [
          if (_expense != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.green),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UpdateExpenseScreen(expenseId: widget.expenseId),
                  ),
                );

                if (result == true) {
                  _loadExpenseDetail();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _expense == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "No expense data found!",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Total Expense Amount",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "\$${_expense!.amount ?? '0.00'}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _expense!.paymentMethod ?? 'Cash',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 📋 Details Card (ព័ត៌មានលម្អិត)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.category_rounded,
                          label: "Expense Type",
                          value: _expense!.expenseType ?? 'N/A',
                        ),
                        const Divider(height: 28, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.tag_rounded,
                          label: "Reference No",
                          value:
                              (_expense!.referenceNo == null ||
                                  _expense!.referenceNo!.isEmpty)
                              ? 'N/A'
                              : _expense!.referenceNo!,
                        ),
                        const Divider(height: 28, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: "Expense Date",
                          value: _expense!.expenseDate ?? 'N/A',
                        ),
                        const Divider(height: 28, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.note_rounded,
                          label: "Note / Description",
                          value:
                              (_expense!.note == null ||
                                  _expense!.note!.isEmpty)
                              ? 'No additional notes'
                              : _expense!.note!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),


                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.styleFrom != null
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpdateExpenseScreen(
                                    expenseId: widget.expenseId,
                                  ),
                                ),
                              );

                              if (result == true) {
                                _loadExpenseDetail();
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Edit Expense",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget សម្រាប់បង្ហាញជួរព័ត៌មាននីមួយៗឱ្យមានលក្ខណៈស្អាតដាច់ដោយឡែក
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.green, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pos_inventory/api/expense/api_expense.dart';
import 'package:pos_inventory/api/expensetype/api_expensetype.dart';

import 'package:pos_inventory/msg/appSnackBar.dart';

import '../expensetype/models/expense_type.dart';
import 'models/expense.dart';

class UpdateExpenseScreen extends StatefulWidget {
  final int expenseId;
  const UpdateExpenseScreen({super.key, required this.expenseId});

  @override
  State<UpdateExpenseScreen> createState() => _UpdateExpenseScreenState();
}

class _UpdateExpenseScreenState extends State<UpdateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiExpense apiExpense = ApiExpense();
  final ApiExpensetype apiExpensetype = ApiExpensetype();

  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  int? _selectedExpenseTypeId;
  String _selectedPaymentMethod = 'Cash';
  final List<String> _paymentMethods = ['Cash', 'ABA', 'Wing', 'Bank Transfer'];

  List<ExpenseType> _expenseTypes = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final types = await apiExpensetype.fetchExpenseType();
      final expenses = await apiExpense.fetchExpenses();
      final currentExpense = expenses.firstWhere(
        (e) => e.id == widget.expenseId,
        orElse: () => Expense(),
      );

      setState(() {
        _expenseTypes = types;
        _amountController.text = currentExpense.amount ?? '';
        _referenceController.text = currentExpense.referenceNo ?? '';
        _dateController.text =
            currentExpense.expenseDate ??
            DateTime.now().toIso8601String().split('T')[0];
        _noteController.text = currentExpense.note ?? '';

        _selectedExpenseTypeId =
            currentExpense.expenseTypeId ??
            (types.isNotEmpty ? types.first.id : null);

        if (currentExpense.paymentMethod != null &&
            _paymentMethods.contains(currentExpense.paymentMethod)) {
          _selectedPaymentMethod = currentExpense.paymentMethod!;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppSnackBar.showError(context, "Failed to load expense details! ❌");
    }
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExpenseTypeId == null) {
      AppSnackBar.showError(context, "Please select an expense type! ⚠️");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    Expense updatedExpense = Expense(
      id: widget.expenseId,
      expenseTypeId: _selectedExpenseTypeId,
      amount: _amountController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      referenceNo: _referenceController.text.trim(),
      expenseDate: _dateController.text.trim(),
      note: _noteController.text.trim(),
    );

    bool success = await apiExpense.updateExpense(
      widget.expenseId,
      updatedExpense,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      AppSnackBar.showSuccess(context, "Expense updated successfully! 🎉");
      Navigator.pop(context, true);
    } else {
      AppSnackBar.showError(context, "Failed to update expense! ❌");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          "Update Expense",
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📋 Main Form Card Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 💰 1. Amount Field
                          const Text(
                            "Amount (\$)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: "0.00",
                              prefixIcon: const Icon(
                                Icons.attach_money_rounded,
                                color: Color(0xFF2563EB),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter amount'
                                : null,
                          ),
                          const SizedBox(height: 18),

                          // 📂 2. Expense Type Dropdown
                          const Text(
                            "Expense Type",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedExpenseTypeId,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                items: _expenseTypes.map((type) {
                                  return DropdownMenuItem<int>(
                                    value: type.id,
                                    child: Text(type.name ?? 'Unnamed'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedExpenseTypeId = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 💳 3. Payment Method Dropdown
                          const Text(
                            "Payment Method",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPaymentMethod,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                items: _paymentMethods.map((method) {
                                  return DropdownMenuItem<String>(
                                    value: method,
                                    child: Row(
                                      children: [
                                        Icon(
                                          method == 'Cash'
                                              ? Icons.money_rounded
                                              : Icons
                                                    .account_balance_wallet_rounded,
                                          size: 20,
                                          color: const Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(method),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 🔖 4. Reference Number
                          const Text(
                            "Reference No (Optional)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _referenceController,
                            decoration: InputDecoration(
                              hintText: "Enter ref number (e.g., REF-001)",
                              prefixIcon: const Icon(
                                Icons.tag_rounded,
                                color: Color(0xFF2563EB),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 📅 5. Expense Date
                          const Text(
                            "Expense Date",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.tryParse(_dateController.text) ??
                                    DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _dateController.text = pickedDate
                                      .toIso8601String()
                                      .split('T')[0];
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: "Select date",
                              prefixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF2563EB),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 📝 6. Note / Description
                          const Text(
                            "Note (Optional)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _noteController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "Add any additional details...",
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 💾 Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _updateExpense,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Update Expense",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  fontFamily: 'KantumruyPro',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

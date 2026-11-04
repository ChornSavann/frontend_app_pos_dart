import 'package:flutter/material.dart';
import 'package:pos_inventory/api/expense/api_expense.dart';
import 'package:pos_inventory/api/expensetype/api_expensetype.dart';

import 'package:pos_inventory/msg/appSnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../expensetype/models/expense_type.dart';
import 'models/expense.dart';

class CreateExpenseScreen extends StatefulWidget {
  const CreateExpenseScreen({super.key});

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiExpense apiExpense = ApiExpense();
  final ApiExpensetype apiExpensetype = ApiExpensetype();

  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Dropdown & Selection values
  int? _selectedExpenseTypeId;
  String _selectedPaymentMethod = 'Cash';
  final List<String> _paymentMethods = ['Cash', 'ABA', 'Wing', 'Bank Transfer'];

  List<ExpenseType> _expenseTypes = [];
  bool _isLoadingTypes = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toIso8601String().split('T')[0];
    _loadExpenseTypes();
  }

  // ទាញយកប្រភេទចំណាយសម្រាប់ធ្វើ Dropdown
  Future<void> _loadExpenseTypes() async {
    try {
      final types = await apiExpensetype.fetchExpenseType();
      setState(() {
        _expenseTypes = types;
        if (types.isNotEmpty) {
          _selectedExpenseTypeId = types.first.id;
        }
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTypes = false;
      });
      AppSnackBar.showError(context, "Failed to load expense types! ❌");
    }
  }

  // Function សម្រាប់បញ្ជូនទិន្នន័យរក្សាទុក
  // 🔄 ក្នុងកន្លែង _submitExpense របស់អ្នក
  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExpenseTypeId == null) {
      AppSnackBar.showError(context, "Please select an expense type! ⚠️");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 🟢 1. ទាញយក user_id ពី SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // (អាស្រ័យលើកូដ Login របស់អ្នកថាដាក់ Key ឈ្មោះអ្វី ឧ. 'user_id' ឬ 'id')
    int? currentUserId = prefs.getInt('user_id') ?? prefs.getInt('id');

    // បើរកមិនឃើញក្នុង int ទេ អាចសាកល្បងទាញយកបែប String ហើយ cast ទៅ int
    if (currentUserId == null) {
      String? strId = prefs.getString('user_id') ?? prefs.getString('id');
      if (strId != null) {
        currentUserId = int.tryParse(strId);
      }
    }

    // 🟢 2. បញ្ចូល user_id ទៅក្នុង Model Expense
    Expense newExpense = Expense(
      userId: currentUserId, // 👈 ដាក់ user_id របស់ User ដែលកំពុង Login ទីនេះ
      expenseTypeId: _selectedExpenseTypeId,
      amount: _amountController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      referenceNo: _referenceController.text.trim(),
      expenseDate: _dateController.text.trim(),
      note: _noteController.text.trim(),
    );

    bool success = await apiExpense.createExpense(newExpense);

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      AppSnackBar.showSuccess(context, "Expense created successfully! 🎉");
      Navigator.pop(context, true);
    } else {
      AppSnackBar.showError(context, "Failed to create expense! ❌");
    }
  }

  // ───────────────────────── UI ONLY (no logic changes) ─────────────────────────

  static const Color _primary = Color(0xFF2563EB);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _bg = Color(0xFFF6F7FB);

  Widget _label(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, {IconData? icon}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
      prefixIcon: icon != null ? Icon(icon, color: _muted, size: 20) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(const Color(0xFFE8EDF3)),
      enabledBorder: border(const Color(0xFFE8EDF3)),
      focusedBorder: border(_primary, 1.6),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent, 1.6),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEF1F6)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          "Add New Expense",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _ink,
            fontSize: 18,
            fontFamily: 'KantumruyPro',
          ),
        ),
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _ink),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💰 1. Amount (Hero input)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.3),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Amount (\$)",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: "0.00",
                        hintStyle: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        prefixText: "\$ ",
                        prefixStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        errorStyle: const TextStyle(
                          color: Color(0xFFFFE4E6),
                          fontWeight: FontWeight.w600,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        errorBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFFE4E6)),
                        ),
                        focusedErrorBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFFFE4E6),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter amount'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 📂 2. Type + 💳 3. Payment
              _sectionCard(
                children: [
                  _label("Expense Type", Icons.category_rounded),
                  _isLoadingTypes
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _primary,
                        ),
                      ),
                    ),
                  )
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EDF3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedExpenseTypeId,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _ink,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _muted,
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

                  _label("Payment Method", Icons.credit_card_rounded),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paymentMethods.map((method) {
                      final bool selected = _selectedPaymentMethod == method;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = method;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? _primary : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? _primary
                                  : const Color(0xFFE8EDF3),
                            ),
                            boxShadow: selected
                                ? [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                method == 'Cash'
                                    ? Icons.payments_rounded
                                    : Icons.account_balance_wallet_rounded,
                                size: 17,
                                color: selected ? Colors.white : _muted,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                method,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : _ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔖 4. Reference + 📅 5. Date + 📝 6. Note
              _sectionCard(
                children: [
                  _label("Reference No (Optional)", Icons.tag_rounded),
                  TextFormField(
                    controller: _referenceController,
                    decoration: _decoration(
                      "Enter ref number (e.g., REF-001)",
                      icon: Icons.tag_rounded,
                    ),
                  ),
                  const SizedBox(height: 18),

                  _label("Expense Date", Icons.event_rounded),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
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
                    decoration: _decoration(
                      "Select date",
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(height: 18),

                  _label("Note (Optional)", Icons.notes_rounded),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: _decoration("Add any additional details..."),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // 💾 Submit Button (ជាប់នៅខាងក្រោម)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primary.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSubmitting ? null : _submitExpense,

              child: _isSubmitting
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Save Expense",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      fontFamily: 'KantumruyPro',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
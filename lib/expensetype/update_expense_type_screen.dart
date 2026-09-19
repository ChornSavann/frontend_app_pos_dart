import 'package:flutter/material.dart';
import 'package:pos_inventory/api/expensetype/api_expensetype.dart';
import '../msg/appSnackBar.dart';
class UpdateExpenseTypeScreen extends StatefulWidget {
  final int expenseTypeId;
  final String initialName;
  final String initialDescription;

  const UpdateExpenseTypeScreen({
    super.key,
    required this.expenseTypeId,
    required this.initialName,
    required this.initialDescription,
  });

  @override
  State<UpdateExpenseTypeScreen> createState() => _UpdateExpenseTypeScreenState();
}

class _UpdateExpenseTypeScreenState extends State<UpdateExpenseTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiExpensetype apiExpensetype = ApiExpensetype();

  bool isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // 🟢 កំណត់តម្លៃចាស់ចូលទៅក្នុង TextField ស្រាប់
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 🚀 មុខងារបញ្ជូនទិន្នន័យ Update ទៅ API
  Future<void> _updateExpenseType() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await apiExpensetype.updateExpenseType(
        id: widget.expenseTypeId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      setState(() => isLoading = false);

      bool success = response['success'] ?? false;
      String serverMessage = response['message'] ?? response['msg'] ?? 'Operation completed';

      if (success) {
        AppSnackBar.showSuccess(context, serverMessage.isNotEmpty ? serverMessage : 'Expense Type updated successfully! 🎉');
        Navigator.pop(context, true);
      } else {
        AppSnackBar.showError(
          context,
          serverMessage.isNotEmpty ? serverMessage : 'Failed to update expense type. Please try again! ❌',
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      AppSnackBar.showError(context, "An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Edit Expense Type',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏷️ Input Container Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 🔹 Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Expense Type Name *',
                        prefixIcon: const Icon(Icons.category_rounded, color: Colors.blueAccent),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter expense type name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // 🔹 Description Field
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.description_rounded, color: Colors.blueAccent),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 🚀 Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : _updateExpenseType,
                  child: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Update Expense Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
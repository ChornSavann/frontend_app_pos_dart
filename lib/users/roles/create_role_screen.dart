import 'package:flutter/material.dart';
import '../../api/roles/api_role.dart';
import '../../msg/appSnackBar.dart';

class CreateRoleScreen extends StatefulWidget {
  const CreateRoleScreen({super.key});

  @override
  State<CreateRoleScreen> createState() => _CreateRoleScreenState();
}

class _CreateRoleScreenState extends State<CreateRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ApiRole _apiRole = ApiRole();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRole() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiRole.createRole(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showSuccess(context, 'បានបង្កើត Role ថ្មីដោយជោគជ័យ!');

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'មានបញ្ហា៖ $e');
      }
    }
  }

  // 🎨 กำหนด Input Decoration ស្ដង់ដាររួមគ្នា
  InputDecoration _inputDecoration(BuildContext context, {required String label, required String hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50, // ដាក់ Background ស្រាលៗ
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), // 🟢 ប្រើ Radius 16 ទាំងអស់គ្នា
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // ពណ៌ផ្ទៃខាងក្រោយធូរភ្នែក
      appBar: AppBar(
        title: const Text(
          'បង្កើតតួនាទីថ្មី',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5, // ដាក់ Shadow តិចៗឱ្យ AppBar មើលដាច់
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 Top Banner Card (កែសម្រួលគម្លាត និង Shadow ឱ្យស្អាត)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // ប្រើពណ៌សជំនួស Gradient ដើម្បីឱ្យមើលទៅស្អាតជាងមុន
                  borderRadius: BorderRadius.circular(16), // 🟢 Radius 16
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Color(0xFF2563EB),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'កំណត់សិទ្ធិនិងតួនាទី',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'បន្ថែមតួនាទីថ្មីសម្រាប់បុគ្គលិកក្នុងប្រព័ន្ធ POS របស់អ្នក។',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // 🟢 គម្លាតមធ្យម

              // 📝 Form Card Container (សម្រួល Padding ក្នុង Card)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16), // សម្រួល Padding ខាងលើបន្តិច
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // 🟢 Radius 16
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label តូចសម្រាប់ Form
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: const Text(
                        'Information Roles',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),

                    // Role Name Input
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                      decoration: _inputDecoration(
                        context,
                        label: 'Role Name',
                        hint: 'ឧ. Cashier, Admin',
                        icon: Icons.badge_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'សូមបញ្ចូលឈ្មោះ Role ជាមុនសិន!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16), // 🟢 គម្លាតតូចរវាង Input

                    // Description Input
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                      decoration: _inputDecoration(
                        context,
                        label: 'Description for Role',
                        hint: 'សរសេរការពិពណ៌នាអំពីសិទ្ធិ...',
                        icon: Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 12), // គម្លាតបន្តិចមុនចប់ Form Card
                  ],
                ),
              ),
              const SizedBox(height: 32), // 🟢 គម្លាតធំមុនប៊ូតុង

              // 🚀 Save Button (កែប្រែឱ្យ giống Design)
              SizedBox(
                width: double.infinity,
                height: 52, // កម្ពស់ស្ដង់ដារ
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // ពណ៌ខៀវស្ដង់ដារ
                    foregroundColor: Colors.white,
                    elevation: 0, // យក Shadow ចេញពីប៊ូតុង ទុកឱ្យ Card ជាអ្នកកាន់ Shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // 🟢 Radius 16 ដូច Card
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Save Role',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
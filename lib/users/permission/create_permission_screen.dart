import 'package:flutter/material.dart';
import '../../api/permission/api_permission.dart';
import '../../msg/appSnackBar.dart';

class CreatePermissionScreen extends StatefulWidget {
  const CreatePermissionScreen({super.key});

  @override
  State<CreatePermissionScreen> createState() => _CreatePermissionScreenState();
}

class _CreatePermissionScreenState extends State<CreatePermissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ApiPermission _apiPermission = ApiPermission();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createPermission() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiPermission.createPermission(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // 🟢 ប្រើប្រាស់ AppSnackBar សម្រាប់ Success Message
        AppSnackBar.showSuccess(context, 'បានបង្កើត Permission ថ្មីដោយជោគជ័យ!');

        Navigator.pop(context, true); // ត្រឡប់ក្រោយ និងផ្ដល់សញ្ញា true ដើម្បី Refresh
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        // 🟢 ប្រើប្រាស់ AppSnackBar សម្រាប់ Error Message
        AppSnackBar.showError(context, 'មានបញ្ហា៖ $e');
      }
    }
  }

  // 🎨 Input Decoration ស្តង់ដាររួមគ្នា
  InputDecoration _inputDecoration(BuildContext context, {required String label, required String hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
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
          'បង្កើតសិទ្ធិថ្មី (Create Permission)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
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
              // 🌟 Top Banner Card ឱ្យមើលទៅលេចធ្លោ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        Icons.security_rounded,
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
                            'ការគ្រប់គ្រងសិទ្ធិ (Permissions)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'បន្ថែមសិទ្ធិថ្មីសម្រាប់កំណត់កម្រិតមុខងារក្នុងប្រព័ន្ធ POS។',
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
              const SizedBox(height: 24),

              // 📝 Form Card Container
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: const Text(
                        'ព័ត៌មានលម្អិត',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),

                    // Permission Name Input
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                      decoration: _inputDecoration(
                        context,
                        label: 'ឈ្មោះសិទ្ធិ (Permission Name)',
                        hint: 'ឧ. view-products, create-order',
                        icon: Icons.vpn_key_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'សូមបញ្ចូលឈ្មោះ Permission ជាមុនសិន!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Input
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                      decoration: _inputDecoration(
                        context,
                        label: 'ការពិពណ៌នា (Description)',
                        hint: 'សរសេរការពិពណ៌នាអំពីមុខងារសិទ្ធិនេះ...',
                        icon: Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 🚀 Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                    'រក្សាទុក (Save Permission)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
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
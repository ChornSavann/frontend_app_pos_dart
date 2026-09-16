import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustomerCreateScreen extends StatefulWidget {
  const CustomerCreateScreen({super.key});

  @override
  State<CustomerCreateScreen> createState() => _CustomerCreateScreenState();
}

class _CustomerCreateScreenState extends State<CustomerCreateScreen> {
  // 🔑 Key សម្រាប់គ្រប់គ្រង Form Validation
  final _formKey = GlobalKey<FormState>();

  // 📝 Controllers សម្រាប់យកតម្លៃពី TextField នីមួយៗ
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;

  // 🌐 API Base URL (ប្រសិនបើប្រើ Emulator ប្រើ 10.0.2.2, ប្រសិនបើទូរស័ព្ទពិត ប្រើ IP កុំព្យូទ័រ)
  final String baseUrl = "http://10.0.2.2:8000/api";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pointsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // 🟢 មុខងារបង្ហាញ Dialog ជូនដំណឹង (ជោគជ័យ ឬបរាជ័យ)
  void _showMyDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // មិនឱ្យចុចបិទខាងក្រៅបានទេ
      builder: (BuildContext context) {
        return AlertDialog(
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
                  color: (isSuccess ? Colors.green : Colors.red).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: isSuccess ? Colors.green : Colors.redAccent,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'KhmerOSBattambang',
                  color: isSuccess ? Colors.green : Colors.redAccent,
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
                    backgroundColor: isSuccess
                        ? Colors.green
                        : Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // បិទ Dialog សិន
                    if (isSuccess) {
                      Navigator.pop(
                        context,
                        true,
                      ); // ត្រឡប់ក្រោយ និង Refresh ទិន្នន័យ
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

  // 🚀 Function បញ្ជូនទិន្នន័យទៅកាន់ Laravel API (Store)
  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'points': int.tryParse(_pointsController.text) ?? 0,
          'address': _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        }),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 201 && jsonResponse['success'] == true) {
        // 🎉 បង្ហាញ Dialog ជោគជ័យ
        _showMyDialog(
          title: "ជោគជ័យ!",
          message: "បានបង្កើតអតិថិជនថ្មីដោយជោគជ័យ!",
          isSuccess: true,
        );
      } else {
        String message =
            jsonResponse['message'] ?? 'មានបញ្ហាក្នុងការបង្កើតទិន្នន័យ';
        if (jsonResponse['errors'] != null) {
          final errors = jsonResponse['errors'] as Map<String, dynamic>;
          message = errors.values.first.first; // យក Error ទី១ មកបង្ហាញ
        }
        _showErrorSnackBar(message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('កំហុសប្រព័ន្ធ: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'KhmerOSBattambang',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
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
        title: const Text(
          "បង្កើតអតិថិជនថ្មី",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'KhmerOSBattambang',
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📦 Form Card Wrapper
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDarkMode ? 0.3 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 👤 Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: "ឈ្មោះអតិថិជន (Name)",
                      icon: Icons.person_rounded,
                      isDarkMode: isDarkMode,
                      validator: (value) => value == null || value.isEmpty
                          ? 'សូមបញ្ចូលឈ្មោះអតិថិជន'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 📧 Email Field
                    _buildTextField(
                      controller: _emailController,
                      label: "អ៊ីម៉ែល (Email)",
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      isDarkMode: isDarkMode,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'សូមបញ្ចូលអ៊ីម៉ែល';
                        if (!value.contains('@'))
                          return 'ទម្រង់អ៊ីម៉ែលមិនត្រឹមត្រូវ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 📱 Phone Field
                    _buildTextField(
                      controller: _phoneController,
                      label: "លេខទូរស័ព្ទ (Phone)",
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),

                    // ⭐ Points Field
                    _buildTextField(
                      controller: _pointsController,
                      label: "ពិន្ទុ (Points)",
                      icon: Icons.stars_rounded,
                      keyboardType: TextInputType.number,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),

                    // 📍 Address Field
                    _buildTextField(
                      controller: _addressController,
                      label: "អាសយដ្ឋាន (Address)",
                      icon: Icons.location_on_rounded,
                      maxLines: 3,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🚀 Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "រក្សាទុក (Save Customer)",
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
        ),
      ),
    );
  }

  // Widget ជំនួយសម្រាប់រៀបចំ Input TextField ឱ្យស្អាតដាច់គេ
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required bool isDarkMode,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontFamily: 'KhmerOSBattambang',
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}

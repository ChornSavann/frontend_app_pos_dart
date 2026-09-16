import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/api/api_customer.dart';

class CustomerUpdateScreen extends StatefulWidget {
  final int customerId;

  const CustomerUpdateScreen({super.key, required this.customerId});

  @override
  State<CustomerUpdateScreen> createState() => _CustomerUpdateScreenState();
}

class _CustomerUpdateScreenState extends State<CustomerUpdateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;
  final ApiCustomer apiCustomer = ApiCustomer();

  final String baseUrl = "http://10.0.2.2:8000/api";

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pointsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // 📥 មុខងារទាញយកទិន្នន័យអតិថិជនតាម ID មកដាក់បង្ហាញក្នុង Form
  Future<void> _fetchCustomerDetail() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/${widget.customerId}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final customer = jsonResponse['data'] ?? jsonResponse;

        setState(() {
          _nameController.text = customer['name'] ?? '';
          _emailController.text = customer['email'] ?? '';
          _phoneController.text = customer['phone'] ?? '';
          _pointsController.text = customer['points']?.toString() ?? '0';
          _addressController.text = customer['address'] ?? '';
          _isFetching = false;
        });
      } else {
        throw Exception('មិនអាចទាញយកទិន្នន័យអតិថិជនបានទេ');
      }
    } catch (e) {
      setState(() => _isFetching = false);
      _showErrorSnackBar('កំហុសប្រព័ន្ធ: $e');
    }
  }

  // 🟢 មុខងារបង្ហាញ Dialog ជូនដំណឹងជោគជ័យ
  void _showMyDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                    Navigator.pop(context); // បិទ Dialog
                    if (isSuccess) {
                      Navigator.pop(
                        context,
                        true,
                      ); // ត្រឡប់ក្រោយនិង Refresh ទិន្នន័យ
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


  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // រៀបចំទិន្នន័យជា Map សម្រាប់ផ្ញើទៅកាន់ API
    Map<String, dynamic> customerData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'points': int.tryParse(_pointsController.text) ?? 0,
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    };


    bool success = await apiCustomer.updateCustomer(
      widget.customerId,
      customerData,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showMyDialog(
        title: "ជោគជ័យ!",
        message: "បានកែប្រែព័ត៌មានអតិថិជនដោយជោគជ័យ!",
        isSuccess: true,
      );
    } else {
      _showErrorSnackBar('មានបញ្ហាក្នុងការកែប្រែទិន្នន័យអតិថិជន!');
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
          "កែប្រែព័ត៌មានអតិថិជន",
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
      body: _isFetching
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
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
                          _buildTextField(
                            controller: _phoneController,
                            label: "លេខទូរស័ព្ទ (Phone)",
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _pointsController,
                            label: "ពិន្ទុ (Points)",
                            icon: Icons.stars_rounded,
                            keyboardType: TextInputType.number,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),
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
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _updateCustomer, // 👈 ហៅមុខងារ _updateCustomer ត្រឹមត្រូវ
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
                                "កែប្រែព័ត៌មាន (Update Customer)",
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

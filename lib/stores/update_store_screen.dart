import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_inventory/api/stores/api_store.dart';
import '../msg/appSnackBar.dart';

class UpdateStoreScreen extends StatefulWidget {
  final int storeId; // 🟢 ត្រូវស្គាល់ ID របស់ Store ដើម្បី Update
  final Map<String, dynamic>? storeData;
  const UpdateStoreScreen({
    super.key,
    required this.storeId,
    this.storeData,
  });

  @override
  State<UpdateStoreScreen> createState() => _UpdateStoreScreenState();
}

class _UpdateStoreScreenState extends State<UpdateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiStore apiStore = ApiStore();

  bool isLoading = false;
  bool isFetching = true;
  File? _selectedLogo;
  String? existingLogoUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoreDetails();
  }


  Future<void> _loadStoreDetails() async {
    setState(() => isFetching = true);
    try {
      final storeData = await apiStore.fetchStoreDetails(widget.storeId);
      if (storeData != null) {
        _nameController.text = storeData['name'] ?? '';
        _phoneController.text = storeData['phone'] ?? '';
        _emailController.text = storeData['email'] ?? '';
        _websiteController.text = storeData['website'] ?? '';
        _addressController.text = storeData['address'] ?? '';
        _descriptionController.text = storeData['description'] ?? '';
        existingLogoUrl = storeData['logo'];
      }
    } catch (e) {
      debugPrint('Error loading store details: $e');
      AppSnackBar.showError(context, 'Failed to load store details! ❌');
    } finally {
      setState(() => isFetching = false);
    }
  }

  // 🖼️ ជ្រើសរើស Logo ថ្មី
  Future<void> _pickLogo() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedLogo = File(pickedFile.path);
      });
    }
  }

  // 🚀 Function Update Store ទៅកាន់ API
  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    bool success = await apiStore.updateStore(
      storeId: widget.storeId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      logoPath: _selectedLogo?.path,
    );

    setState(() => isLoading = false);

    if (success) {
      AppSnackBar.showSuccess(context, 'Store updated successfully! 🎉');
      Navigator.pop(context, true);
    } else {
      AppSnackBar.showError(
        context,
        'Failed to update store. Please try again! ❌',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Update Store',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: isFetching
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼️ Logo Picker Section
                    Center(
                      child: GestureDetector(
                        onTap: _pickLogo,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1.5,
                                ),
                                image: _selectedLogo != null
                                    ? DecorationImage(
                                        image: FileImage(_selectedLogo!),
                                        fit: BoxFit.cover,
                                      )
                                    : (existingLogoUrl != null &&
                                              existingLogoUrl!.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                "http://10.0.2.2:8000/$existingLogoUrl",
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null),
                              ),
                              child:
                                  (_selectedLogo == null &&
                                      (existingLogoUrl == null ||
                                          existingLogoUrl!.isEmpty))
                                  ? const Icon(
                                      Icons.storefront_rounded,
                                      size: 45,
                                      color: Color(0xFF2563EB),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🏷️ Input Fields Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Store Name',
                            icon: Icons.store_rounded,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          // 🟢 Email Field with Validator
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              bool isValidEmail =
                                  value.contains('@') && value.contains('.');
                              if (!isValidEmail) {
                                return 'Please enter a valid email address (e.g., example@gmail.com)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // 🟢 Website Field with Validator
                          _buildTextField(
                            controller: _websiteController,
                            label: 'Website',
                            icon: Icons.language_rounded,
                            keyboardType: TextInputType.url,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final uri = Uri.tryParse(value.trim());
                              bool isValidUrl =
                                  (uri != null &&
                                      uri.hasScheme &&
                                      (uri.isScheme('http') ||
                                          uri.isScheme('https'))) ||
                                  value.contains('.');
                              if (!isValidUrl) {
                                return 'Please enter a valid website link (e.g., https://example.com)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.location_on_rounded,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            icon: Icons.description_rounded,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),


                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: isLoading ? null : _submitUpdate,
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
                                'Update Store',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

  // 🛠️ Helper Method សម្រាប់ TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
      validator:
          validator ??
          (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'Please enter $label';
            }
            return null;
          },
    );
  }
}

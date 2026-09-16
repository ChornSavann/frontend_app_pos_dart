import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_inventory/api/api_user.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final ApiUser _apiUser = ApiUser();
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Variables for Live Password Validation
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  // Variables for Email Validation
  bool _isEmailValid = false;
  bool _isEmailTouched = false;

  // 🖼️ មុខងារជ្រើសរើសរូបភាពពី Gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 🚀 មុខងារបញ្ជូនទិន្នន័យទៅកាន់ Laravel API
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var result = await _apiUser.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        image: _imageFile,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        AppSnackBar.showSuccess(
          context,
          result['message'] ?? 'User created successfully!',
        );
        // 🟢 សំខាន់ខ្លាំង៖ ផ្ញើ true ត្រឡប់ទៅ UserIndexScreen វិញ ដើម្បីឱ្យវា Refresh
        Navigator.pop(context, true);
      } else {
        AppSnackBar.showError(
          context,
          result['message'] ?? 'Failed to create user',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppSnackBar.showError(context, 'Error: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isMet ? Colors.green : Colors.grey[600],
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New User'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🖼️ Profile Image Picker Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF4F46E5),
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 📝 Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 16),

              // 📧 Email Field (Live Tick & Red Error)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  setState(() {
                    _isEmailTouched = true;
                    _isEmailValid = value.contains('@') && value.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: _isEmailTouched
                      ? Icon(
                    _isEmailValid ? Icons.check_circle : Icons.error,
                    color: _isEmailValid ? Colors.green : Colors.red,
                  )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isEmailTouched
                          ? (_isEmailValid ? Colors.green : Colors.red)
                          : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _isEmailTouched
                          ? (_isEmailValid ? Colors.green : Colors.red)
                          : Colors.blue,
                      width: 2,
                    ),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorStyle: const TextStyle(color: Colors.red),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email format (Must contain @)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 📞 Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter phone number' : null,
              ),
              const SizedBox(height: 16),

              // 🔒 Password Field (Strong Password with Checklist)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {
                        _hasMinLength = value.length >= 8;
                        _hasUppercase = value.contains(RegExp(r'[A-Z]'));
                        _hasNumber = value.contains(RegExp(r'[0-9]'));
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Password (Strong)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (!_hasMinLength || !_hasUppercase || !_hasNumber) {
                        return 'Please meet all password requirements below';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRequirementRow('At least 8 characters', _hasMinLength),
                        const SizedBox(height: 4),
                        _buildRequirementRow('At least one uppercase letter (A-Z)', _hasUppercase),
                        const SizedBox(height: 4),
                        _buildRequirementRow('At least one number (0-9)', _hasNumber),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔒 Confirm Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: _confirmPasswordController.text.isNotEmpty
                          ? Icon(
                        _confirmPasswordController.text == _passwordController.text
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _confirmPasswordController.text == _passwordController.text
                            ? Colors.green
                            : Colors.red,
                      )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  if (_confirmPasswordController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            _confirmPasswordController.text == _passwordController.text
                                ? Icons.check_circle
                                : Icons.error_outline,
                            size: 16,
                            color: _confirmPasswordController.text == _passwordController.text
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _confirmPasswordController.text == _passwordController.text
                                ? 'Passwords match'
                                : 'Passwords do not match',
                            style: TextStyle(
                              fontSize: 13,
                              color: _confirmPasswordController.text == _passwordController.text
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),

              // 🚀 Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submitData,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Create User',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
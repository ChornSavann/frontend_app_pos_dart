import 'package:flutter/material.dart';
import '../../api/api_customer.dart';

class AddCustomerDialog extends StatefulWidget {
  final String initialName;
  final Function(int) onCustomerCreated;

  const AddCustomerDialog({
    super.key,
    required this.initialName,
    required this.onCustomerCreated,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  late final TextEditingController nameController;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pointController = TextEditingController(
    text: '1',
  );

  bool _isLoading = false;
  bool _isEmailManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);

    if (widget.initialName.isNotEmpty) {
      _generateEmailFromName(widget.initialName);
    }
  }


  void _generateEmailFromName(String name) {
    if (!_isEmailManuallyEdited) {
      String sanitized = name.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      if (sanitized.isNotEmpty) {
        emailController.text = "$sanitized@gmail.com";
      } else {
        emailController.text = "";
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    pointController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "សូមបំពេញឈ្មោះ លេខទូរស័ព្ទ និងអ៊ីមែលឱ្យបានគ្រប់គ្រាន់!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int? newCustomerId = await ApiCustomer().postCustomer({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
        'points': int.tryParse(pointController.text.trim()) ?? 1,
      });

      if (newCustomerId != null) {
        widget.onCustomerCreated(newCustomerId);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("បានបង្កើតអតិថិជនថ្មីជោគជ័យ!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("បរាជ័យក្នុងការបង្កើតអតិថិជន!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "បន្ថែមអតិថិជនថ្មី (Add Customer)",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              onChanged: (value) {
                _generateEmailFromName(value);
              },
              decoration: const InputDecoration(
                labelText: "ឈ្មោះអតិថិជន (Name)*",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "លេខទូរស័ព្ទ (Phone)*",
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                setState(() {
                  _isEmailManuallyEdited = value.isNotEmpty;
                });
              },
              decoration: const InputDecoration(
                labelText: "អ៊ីមែល (Email)*",
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "អាសយដ្ឋាន (Address)",
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pointController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ពិន្ទុ (Points)",
                prefixIcon: Icon(Icons.stars),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("បោះបង់", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _saveCustomer,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("រក្សាទុក"),
        ),
      ],
    );
  }
}

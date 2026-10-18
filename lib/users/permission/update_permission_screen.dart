import 'package:flutter/material.dart';
import 'package:pos_inventory/users/permission/models/permission.dart';
import '../../api/permission/api_permission.dart';
import '../../msg/appSnackBar.dart';

class UpdatePermissionScreen extends StatefulWidget {
  final Permission permission;
  const UpdatePermissionScreen({super.key, required this.permission});

  @override
  State<UpdatePermissionScreen> createState() => _UpdatePermissionScreenState();
}

class _UpdatePermissionScreenState extends State<UpdatePermissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiPermission _apiPermission = ApiPermission();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _fetchPermissionDetail();
  }

  Future<void> _fetchPermissionDetail() async {
    try {
      // 1. ដាក់តម្លៃពី widget.permission មកជាមុនសិនភ្លាមៗ
      _nameController.text = widget.permission.name ?? '';
      _descriptionController.text = widget.permission.description ?? '';

      setState(() {
        _isLoading = false;
      });

      // 2. ទាញយកទិន្នន័យថ្មីពី Server បន្ថែមតាមរយៈ API
      final data = await _apiPermission.getPermissionById(
        widget.permission.id.toString(),
      );

      if (mounted) {
        setState(() {
          _nameController.text = data.name ?? widget.permission.name ?? '';
          _descriptionController.text = data.description ?? widget.permission.description ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _nameController.text = widget.permission.name ?? '';
          _descriptionController.text = widget.permission.description ?? '';
        });
      }
      debugPrint("⚠️ Error fetching permission detail: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updatePermission() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      await _apiPermission.updatePermission(
        widget.permission.id.toString(),
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (mounted) {
        AppSnackBar.showSuccess(context, 'បានកែប្រែ Permission ជោគជ័យ!');
        Navigator.pop(context, true); // ត្រឡប់ក្រោយនិង Refresh ទិន្នន័យ
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error updating permission: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Update Permission',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _isLoading
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
              // 🌟 Top Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Editing Permission',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: #${widget.permission.id} - ${_nameController.text}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    // 📝 ឈ្មោះ Permission (Floating Label)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Permission Name',
                        hintText: 'ឧ. view-products',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(
                          Icons.vpn_key_rounded,
                          color: Color(0xFF2563EB),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'សូមបញ្ចូលឈ្មោះ Permission';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'សរសេរការពិពណ៌នាអំពីសិទ្ធិស្ដីពី...',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 8, bottom: 56),
                          child: Icon(
                            Icons.description_rounded,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 🚀 ប៊ូតុង Update Changes
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: (_isLoading || _isUpdating) ? null : _updatePermission,
                        child: _isUpdating
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Update Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
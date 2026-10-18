import 'package:flutter/material.dart';
import 'package:pos_inventory/users/roles/models/role.dart';
import 'package:pos_inventory/users/permission/models/permission.dart';
import '../../api/permission/api_permission.dart';
import '../../api/roles/api_role.dart';
import '../../msg/appSnackBar.dart';

class AssignPermissionToRoleScreen extends StatefulWidget {
  const AssignPermissionToRoleScreen({super.key});

  @override
  State<AssignPermissionToRoleScreen> createState() => _AssignPermissionToRoleScreenState();
}

class _AssignPermissionToRoleScreenState extends State<AssignPermissionToRoleScreen> {
  final ApiRole _apiRole = ApiRole();
  final ApiPermission _apiPermission = ApiPermission();

  List<Role> _roles = [];
  List<Permission> _permissions = [];

  Role? _selectedRole;
  List<int> _selectedPermissionIds = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 1. ទាញយកបញ្ជី Role និង Permissions ទាំងអស់ពី Backend
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rolesData = await _apiRole.fetchRoles();
      final rolesList = rolesData.map((json) => Role.fromJson(json)).toList();

      final permissionsList = await _apiPermission.fetchPermissions();

      setState(() {
        _roles = rolesList;
        _permissions = permissionsList;
        if (_roles.isNotEmpty) {
          _selectedRole = _roles.first;
          _fetchRolePermissions(_selectedRole!.id.toString());
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackBar.showError(context, 'មានបញ្ហាក្នុងការទាញយកទិន្នន័យ: $e');
      }
    }
  }

  // 2. ទាញយកសិទ្ធិដែលមានស្រាប់របស់ Role ដែលបានជ្រើសរើស
  Future<void> _fetchRolePermissions(String roleId) async {
    try {
      final roleData = await _apiRole.getRoleWithPermissions(roleId);
      List<int> assignedIds = [];
      if (roleData['permissions'] != null) {
        assignedIds = (roleData['permissions'] as List)
            .map<int>((p) => int.parse(p['id'].toString()))
            .toList();
      }

      setState(() {
        _selectedPermissionIds = assignedIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackBar.showError(context, 'មិនអាចទាញយកសិទ្ធិរបស់ Role នេះបានទេ: $e');
      }
    }
  }

  // 3. រក្សាទុកការកំណត់សិទ្ធិ (Assign/Sync Permissions)
  Future<void> _savePermissions() async {
    if (_selectedRole == null) return;

    setState(() => _isSaving = true);

    final result = await _apiPermission.assignPermissionsToRole(
      _selectedRole!.id.toString(),
      _selectedPermissionIds,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (result['success'] == true) {
        AppSnackBar.showSuccess(context, result['message']);
      } else {
        AppSnackBar.showError(context, result['message']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'កំណត់សិទ្ធិជូនតួនាទី (Assign Permissions)',
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _roles.isEmpty
          ? const Center(child: Text('មិនមានទិន្នន័យ Role ទេ'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Dropdown សម្រាប់ជ្រើសរើស Role
            const Text(
              'ជ្រើសរើសតួនាទី (Select Role)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Role>(
                  value: _selectedRole,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB)),
                  items: _roles.map((Role role) {
                    return DropdownMenuItem<Role>(
                      value: role,
                      child: Text(
                        role.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (Role? newRole) {
                    if (newRole != null) {
                      setState(() {
                        _selectedRole = newRole;
                        _isLoading = true;
                      });
                      _fetchRolePermissions(newRole.id.toString());
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📋 បញ្ជី Permissions សម្រាប់ Check ជ្រើសរើស
            const Text(
              'កំណត់សិទ្ធិអនុញ្ញាត (Permissions List)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _permissions.isEmpty
                  ? const Center(child: Text('មិនមានទិន្នន័យ Permissions ទេ'))
                  : ListView.builder(
                itemCount: _permissions.length,
                itemBuilder: (context, index) {
                  final permission = _permissions[index];
                  final permissionId = permission.id ?? 0;
                  final isSelected = _selectedPermissionIds.contains(permissionId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        permission.name ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      subtitle: Text(
                        permission.description ?? 'គ្មានការពិពណ៌នា',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      value: isSelected,
                      activeColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedPermissionIds.add(permissionId);
                          } else {
                            _selectedPermissionIds.remove(permissionId);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
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
            onPressed: _isSaving ? null : _savePermissions,
            child: _isSaving
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : const Text(
              'រក្សាទុកការកំណត់សិទ្ធិ (Save Permissions)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
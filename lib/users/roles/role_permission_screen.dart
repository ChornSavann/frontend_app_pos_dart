import 'package:flutter/material.dart';
import 'package:pos_inventory/users/roles/models/role.dart';
import 'package:pos_inventory/users/permission/models/permission.dart';
import '../../api/permission/api_permission.dart';
import '../../api/roles/api_role.dart';
import '../../msg/appSnackBar.dart';

class RolePermissionScreen extends StatefulWidget {
  final Role role;
  const RolePermissionScreen({super.key, required this.role});

  @override
  State<RolePermissionScreen> createState() => _RolePermissionScreenState();
}

class _RolePermissionScreenState extends State<RolePermissionScreen> {
  final ApiRole _apiRole = ApiRole();
  final ApiPermission _apiPermission = ApiPermission();

  List<Permission> _allPermissions = [];
  List<int> _selectedPermissionIds = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final permissionsList = await _apiPermission.fetchPermissions();
      final roleData = await _apiRole.getRoleWithPermissions(
        widget.role.id.toString(),
      );

      debugPrint("🔍 Role Data Received: $roleData");

      List<int> assignedIds = [];
      dynamic permissionsRaw;
      if (roleData is Map) {
        if (roleData.containsKey('permissions')) {
          permissionsRaw = roleData['permissions'];
        } else if (roleData.containsKey('data') &&
            roleData['data'] is Map &&
            roleData['data'].containsKey('permissions')) {
          permissionsRaw = roleData['data']['permissions'];
        }
      }

      if (permissionsRaw != null && permissionsRaw is List) {
        assignedIds = permissionsRaw
            .map<int>((p) => int.parse(p['id'].toString()))
            .toList();
      }

      debugPrint("✅ Assigned Permission IDs: $assignedIds");

      setState(() {
        _allPermissions = permissionsList;
        _selectedPermissionIds = assignedIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Error loading permissions: $e");
      if (mounted) {
        AppSnackBar.showError(context, 'Error loading permissions: $e');
      }
    }
  }


  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedPermissionIds = _allPermissions
            .map((p) => p.id ?? 0)
            .where((id) => id != 0)
            .toList();
      } else {
        _selectedPermissionIds.clear();
      }
    });
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    final result = await _apiPermission.assignPermissionsToRole(
      widget.role.id.toString(),
      _selectedPermissionIds,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (result['success'] == true) {
        AppSnackBar.showSuccess(context, result['message']);
        Navigator.pop(context, true);
      } else {
        AppSnackBar.showError(context, result['message']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllSelected = _allPermissions.isNotEmpty &&
        _selectedPermissionIds.length == _allPermissions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'កំណត់សិទ្ធិ៖ ${widget.role.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
          : _allPermissions.isEmpty
          ? const Center(child: Text('មិនមានទិន្នន័យ Permissions ទេ'))
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'បានជ្រើសរើស៖ ${_selectedPermissionIds.length}/${_allPermissions.length}',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _toggleSelectAll(!isAllSelected),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          isAllSelected ? 'ដកចេញទាំងអស់' : 'ជ្រើសរើសទាំងអស់',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Checkbox(
                          value: isAllSelected,
                          activeColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: _toggleSelectAll,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 📋 ListView of Permissions with Modern Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allPermissions.length,
              itemBuilder: (context, index) {
                final permission = _allPermissions[index];
                final permissionId = permission.id ?? 0;
                final isSelected = _selectedPermissionIds.contains(permissionId);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2563EB).withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPermissionIds.remove(permissionId);
                          } else {
                            _selectedPermissionIds.add(permissionId);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 🎨 Icon មុខកាត
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.vpn_key_rounded,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade500,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // 📝 Title & Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    permission.name ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF1E293B),
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    permission.description ?? 'គ្មានការពិពណ៌នា',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // ☑️ Custom Checkbox (អាចចុចលើកាតទាំងមូល ឬលើប្រអប់ក៏បាន)
                            Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
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
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'រក្សាទុកសិទ្ធិ (Save Permissions)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
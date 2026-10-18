import 'package:flutter/material.dart';
import 'package:pos_inventory/users/permission/models/permission.dart';
import 'package:pos_inventory/users/permission/create_permission_screen.dart';
import 'package:pos_inventory/users/permission/update_permission_screen.dart';
import '../../api/permission/api_permission.dart';
import '../../msg/appSnackBar.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final ApiPermission _apiPermission = ApiPermission();
  List<Permission> _permissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    try {
      final List<Permission> list = await _apiPermission.fetchPermissions();
      setState(() {
        _permissions = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackBar.showError(
          context,
          'មិនអាចទាញយកទិន្នន័យ Permissions បានទេ: $e',
        );
      }
    }
  }

  Future<void> _deletePermission(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('បញ្ជាក់ការលុប'),
        content: const Text('តើអ្នកពិតជាចង់លុប Permission នេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('បោះបង់', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('លុប'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await _apiPermission.deletePermission(id);

        if (result['success'] == true) {
          AppSnackBar.showSuccess(
            context,
            result['message'] ?? 'លុប Permission បានជោគជ័យ',
          );
          _loadPermissions();
        } else {
          AppSnackBar.showError(
            context,
            result['message'] ?? 'មានបញ្ហាក្នុងការលុប',
          );
        }
      } catch (e) {
        AppSnackBar.showError(context, 'Error deleting permission: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Permissions',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Refresh',
            onPressed: _loadPermissions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _permissions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'មិនមានទិន្នន័យ Permissions ទេ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPermissions,
              color: const Color(0xFF2563EB),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _permissions.length,
                itemBuilder: (context, index) {
                  final Permission permission = _permissions[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        permission.name ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          permission.description != null &&
                                  permission.description!.isNotEmpty
                              ? permission.description!
                              : 'គ្មានការពិពណ៌នា',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.grey,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            debugPrint(
                              "🚀 Sending Permission to Update -> ID: ${permission.id}, Name: ${permission.name}, Desc: ${permission.description}",
                            );
                            final bool? isUpdated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdatePermissionScreen(
                                  permission: permission,
                                ),
                              ),
                            );

                            if (isUpdated == true) {
                              _loadPermissions();
                            }
                          } else if (value == 'delete') {
                            _deletePermission(permission.id.toString());
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'កែប្រែ (Edit)',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'លុប (Delete)',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bool? isCreated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePermissionScreen(),
            ),
          );

          if (isCreated == true) {
            _loadPermissions();
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

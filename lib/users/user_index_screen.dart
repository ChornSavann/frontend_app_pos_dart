import 'package:flutter/material.dart';
import 'package:pos_inventory/models/user.dart';
import 'package:pos_inventory/api/api_user.dart';
import 'package:pos_inventory/users/roles/models/role.dart';
import 'package:pos_inventory/users/user_detail_sreen.dart';
import '../../api/roles/api_role.dart';


import '../msg/appSnackBar.dart';
import 'create_user_screen.dart';
import 'edit_user_sreen.dart';

class UserIndexScreen extends StatefulWidget {
  const UserIndexScreen({super.key});

  @override
  State<UserIndexScreen> createState() => _UserIndexScreenState();
}

class _UserIndexScreenState extends State<UserIndexScreen> {
  final ApiUser _apiUser = ApiUser();
  final ApiRole _apiRole = ApiRole();

  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  List<Role> _roles = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _apiUser.getAllUsers(),
        _apiRole.fetchRoles(),
      ]);

      List<User> users = results[0] as List<User>;
      List dynamicRoles = results[1] as List;
      List<Role> rolesList = dynamicRoles.map((json) => Role.fromJson(json)).toList();

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _roles = rolesList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppSnackBar.showError(context, 'Error loading data: $e');
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers
            .where(
              (user) =>
          (user.name?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
              (user.email?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
            .toList();
      }
    });
  }

  // 🟢 Modal BottomSheet សម្រាប់ជ្រើសរើស និង Assign Role ឱ្យ User
  void _showAssignRoleDialog(User user) {
    String? selectedRoleId = user.roleid?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'កំណត់សិទ្ធិនិងតួនាទី',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ជូនអ្នកប្រើប្រាស់: ${user.name ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // បញ្ជី Role សម្រាប់ជ្រើសរើស
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      itemCount: _roles.length,
                      itemBuilder: (context, index) {
                        final role = _roles[index];
                        final isSelected = selectedRoleId == role.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF4F46E5).withValues(alpha: 0.04) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200,
                            ),
                          ),
                          child: RadioListTile<String>(
                            title: Text(
                              role.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            subtitle: Text(
                              role.description.isNotEmpty ? role.description : 'គ្មានការពិពណ៌នា',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            value: role.id,
                            groupValue: selectedRoleId,
                            activeColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onChanged: (value) {
                              setModalState(() {
                                selectedRoleId = value;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ប៊ូតុងរក្សាទុក Role ថ្មី
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (selectedRoleId == null || user.id == null) return;

                        Navigator.pop(context);

                        // ហៅ API ប្ដូរ Role
                        final result = await _apiRole.assignRoleToEmployee(user.id.toString(), selectedRoleId!);

                        if (mounted) {
                          if (result['success'] == true) {
                            AppSnackBar.showSuccess(context, result['message'] ?? 'បានកំណត់ Role ជោគជ័យ!');
                            _loadData(); // Refresh ទិន្នន័យឡើងវិញ
                          } else {
                            AppSnackBar.showError(context, result['message'] ?? 'មានបញ្ហាក្នុងការកំណត់ Role');
                          }
                        }
                      },
                      child: const Text(
                        'រក្សាទុក (Save Role)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmAndDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Confirm Delete', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Text('Are you sure you want to delete "${user.name}"?'),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                var result = await _apiUser.deleteUser(user.id!);
                if (!mounted) return;

                if (result['success'] == true) {
                  AppSnackBar.showSuccess(
                    context,
                    result['message'] ?? 'User deleted successfully!',
                  );
                  setState(() {
                    _searchController.clear();
                    _loadData();
                  });
                } else {
                  AppSnackBar.showError(
                    context,
                    result['message'] ?? 'Failed to delete user',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Users Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4F46E5)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 📋 List of Users
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
                : _filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_off_outlined,
                      size: 50,
                      color: Colors.indigo.shade300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];

                // 🔍 ស្វែងរកឈ្មោះ Role ផ្អែកលើ user.roleid
                String roleName = 'គ្មាន Role';
                if (user.roleid != null) {
                  final matchedRole = _roles.firstWhere(
                        (r) => r.id.toString() == user.roleid.toString(),
                    orElse: () => Role(id: '', name: 'គ្មាន Role', description: ''),
                  );
                  roleName = matchedRole.name;
                }
                final bool hasRole = roleName != 'គ្មាន Role';

                return InkWell(
                  onTap: () async {
                    bool? updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserDetailScreen(user: user),
                      ),
                    );
                    if (updated == true) {
                      _searchController.clear();
                      _loadData();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // 🖼️ User Avatar with border
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xFF4F46E5,
                                ).withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(
                                0xFF4F46E5,
                              ).withValues(alpha: 0.1),
                              backgroundImage:
                              (user.image != null &&
                                  user.image!.isNotEmpty)
                                  ? NetworkImage(user.image!)
                                  : null,
                              child:
                              (user.image == null ||
                                  user.image!.isEmpty)
                                  ? const Icon(
                                Icons.person,
                                color: Color(0xFF4F46E5),
                                size: 28,
                              )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // 📝 User Details info & Role Badge
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name ?? 'No Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 13,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        user.email ?? 'No Email',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // 🏷️ Role Badge  hiển thịនៅលើ User Card ផ្ទាល់
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasRole
                                        ? Colors.blue.withValues(alpha: 0.08)
                                        : Colors.orange.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: hasRole
                                          ? Colors.blue.withValues(alpha: 0.2)
                                          : Colors.orange.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    'Role: $roleName',
                                    style: TextStyle(
                                      color: hasRole ? const Color(0xFF4F46E5) : Colors.orange.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ⚙ Action Buttons (Assign Role, Edit & Delete)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 🟢 ប៊ូតុងសម្រាប់កំណត់ Role (Manage Role Button)
                              InkWell(
                                onTap: () => _showAssignRoleDialog(user),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: Colors.purple,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Edit Button
                              InkWell(
                                onTap: () async {
                                  bool? updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditUserScreen(user: user),
                                    ),
                                  );
                                  if (updated == true) {
                                    _searchController.clear();
                                    _loadData();
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(
                                      8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Delete Button
                              InkWell(
                                onTap: () {
                                  if (user.id != null) {
                                    _confirmAndDeleteUser(user);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(
                                      8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          bool? created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserScreen()),
          );

          if (created == true) {
            _searchController.clear();
            _loadData();
          }
        },
      ),
    );
  }
}
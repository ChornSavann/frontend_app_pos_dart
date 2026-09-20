import 'package:flutter/material.dart';
import 'package:pos_inventory/models/user.dart';
import 'package:pos_inventory/api/api_user.dart';

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

  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // 🔄 មុខងារទាញយកទិន្នន័យ User ទាំងអស់មកដាក់ក្នុង List ផ្ទាល់
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<User> users = await _apiUser.getAllUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppSnackBar.showError(context, 'Error loading users: $e');
    }
  }

  // 🔍 មុខងារស្វែងរក User
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

// 🗑️ មុខងារបង្ហាញប្រអប់សួរបញ្ជាក់និងលុប (កែសម្រួលរួចរាល់ មិនមាន Error Context)
  void _confirmAndDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Delete'),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                var result = await _apiUser.deleteUser(user.id!);
                if (!mounted) return;

                if (result['success'] == true) {
                  AppSnackBar.showSuccess(
                    context,
                    result['message'] ?? 'User deleted successfully!',
                  );

                  // Refresh មុខងារបង្ហាញបញ្ជីថ្មី
                  setState(() {
                    _searchController.clear();
                    _loadUsers();
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
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔎 Search Bar Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF4F46E5),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No users found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),

                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                      backgroundImage: (user.image != null && user.image!.isNotEmpty)
                          ? NetworkImage(user.image!)
                          : null,
                      child: (user.image == null || user.image!.isEmpty)
                          ? const Icon(
                        Icons.person,
                        color: Color(0xFF4F46E5),
                        size: 28,
                      )
                          : null,
                    ),
                    title: Text(
                      user.name ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.email ?? 'No Email',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.phone ?? 'No Phone',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          onPressed: () async {
                            bool? updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditUserScreen(user: user), // 👈 ផ្ញើ user ទៅជាមួយ
                              ),
                            );

                            // 🔄 Refresh បញ្ជីទិន្នន័យឡើងវិញប្រសិនបើ Update ជោគជ័យ
                            if (updated == true) {
                              _searchController.clear();
                              _loadUsers();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            if (user.id != null) {
                              _confirmAndDeleteUser(user);
                            }
                          },
                        ),
                      ],
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
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          bool? created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserScreen()),
          );

          if (created == true) {
            _searchController.clear();
            _loadUsers();
          }
        },
      ),
    );
  }
}
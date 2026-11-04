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
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _primaryDark = Color(0xFF3730A3);
  static const Color _ink = Color(0xFF1E293B);
  static const String _noRole = 'គ្មាន Role';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────── LOGIC (មិនប្តូរ) ───────────────────────────

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
      List<Role> rolesList =
      dynamicRoles.map((json) => Role.fromJson(json)).toList();

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
      if (!mounted) return;
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

  String _roleNameOf(User user) {
    if (user.roleid == null) return _noRole;
    final matchedRole = _roles.firstWhere(
          (r) => r.id.toString() == user.roleid.toString(),
      orElse: () => Role(id: '', name: _noRole, description: ''),
    );
    return matchedRole.name;
  }

  Future<void> _openDetail(User user) async {
    bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
    );
    if (updated == true) {
      _searchController.clear();
      _loadData();
    }
  }

  Future<void> _openEdit(User user) async {
    bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditUserScreen(user: user)),
    );
    if (updated == true) {
      _searchController.clear();
      _loadData();
    }
  }

  Future<void> _openCreate() async {
    bool? created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateUserScreen()),
    );
    if (created == true) {
      _searchController.clear();
      _loadData();
    }
  }

  // ─────────────────────────── ASSIGN ROLE SHEET ───────────────────────────

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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.of(context).viewPadding.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), _primary],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'កំណត់សិទ្ធិនិងតួនាទី',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ជូនអ្នកប្រើប្រាស់: ${user.name ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // បញ្ជី Role
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _roles.length,
                      itemBuilder: (context, index) {
                        final role = _roles[index];
                        final isSelected = selectedRoleId == role.id;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primary.withValues(alpha: 0.06)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? _primary
                                  : Colors.grey.shade200,
                              width: isSelected ? 1.6 : 1,
                            ),
                          ),
                          child: RadioListTile<String>(
                            title: Text(
                              role.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                            subtitle: Text(
                              role.description.isNotEmpty
                                  ? role.description
                                  : 'គ្មានការពិពណ៌នា',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            value: role.id,
                            groupValue: selectedRoleId,
                            activeColor: _primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                  const SizedBox(height: 12),

                  // ប៊ូតុងរក្សាទុក
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text(
                        'រក្សាទុក (Save Role)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () async {
                        if (selectedRoleId == null || user.id == null) return;

                        Navigator.pop(context);

                        final result = await _apiRole.assignRoleToEmployee(
                          user.id.toString(),
                          selectedRoleId!,
                        );

                        if (mounted) {
                          if (result['success'] == true) {
                            AppSnackBar.showSuccess(
                              this.context,
                              result['message'] ?? 'បានកំណត់ Role ជោគជ័យ!',
                            );
                            _loadData();
                          } else {
                            AppSnackBar.showError(
                              this.context,
                              result['message'] ??
                                  'មានបញ្ហាក្នុងការកំណត់ Role',
                            );
                          }
                        }
                      },
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

  // ─────────────────────────── DELETE DIALOG ───────────────────────────

  void _confirmAndDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Confirm Delete',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${user.name}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────── UI ───────────────────────────

  Widget _buildHeader() {
    final withRole = _allUsers.where((u) => u.roleid != null).length;
    final withoutRole = _allUsers.length - withRole;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          child: Column(
            children: [
              Row(
                children: [
                  if (Navigator.canPop(context))
                    _HeaderIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 40),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Users Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'គ្រប់គ្រងអ្នកប្រើប្រាស់',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _HeaderIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: _loadData,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Stats
              Row(
                children: [
                  _StatTile(
                    icon: Icons.people_alt_rounded,
                    label: 'សរុប',
                    value: _allUsers.length,
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    icon: Icons.verified_user_rounded,
                    label: 'មាន Role',
                    value: withRole,
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    icon: Icons.person_outline_rounded,
                    label: 'គ្មាន Role',
                    value: withoutRole,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search
              TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                style: const TextStyle(fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: _primary),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: Colors.grey,
                    onPressed: () {
                      _searchController.clear();
                      _filterUsers('');
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_search_rounded,
                    size: 56,
                    color: _primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'សូមព្យាយាមស្វែងរកដោយពាក្យផ្សេង',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(User user) {
    final roleName = _roleNameOf(user);
    final hasRole = roleName != _noRole;
    final hasImage = user.image != null && user.image!.isNotEmpty;
    final initial = (user.name != null && user.name!.trim().isNotEmpty)
        ? user.name!.trim().characters.first.toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openDetail(user),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), _primary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage:
                    hasImage ? NetworkImage(user.image!) : null,
                    child: hasImage
                        ? null
                        : Text(
                      initial,
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: _ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.alternate_email_rounded,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              user.email ?? 'No Email',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hasRole
                              ? _primary.withValues(alpha: 0.08)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasRole
                                  ? Icons.shield_rounded
                                  : Icons.shield_outlined,
                              size: 12,
                              color: hasRole
                                  ? _primary
                                  : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                roleName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasRole
                                      ? _primary
                                      : Colors.orange.shade800,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'role':
                        _showAssignRoleDialog(user);
                        break;
                      case 'edit':
                        _openEdit(user);
                        break;
                      case 'delete':
                        if (user.id != null) _confirmAndDeleteUser(user);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'role',
                      child: _MenuRow(
                        icon: Icons.admin_panel_settings_outlined,
                        color: Colors.purple,
                        text: 'កំណត់ Role',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: _MenuRow(
                        icon: Icons.edit_outlined,
                        color: Colors.blue,
                        text: 'កែប្រែ',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.red,
                        text: 'លុប',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
                : RefreshIndicator(
              color: _primary,
              onRefresh: _loadData,
              child: _filteredUsers.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) =>
                    _buildUserCard(_filteredUsers[index]),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'បន្ថែមអ្នកប្រើ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _openCreate,
      ),
    );
  }
}

// ─────────────────────────── Small reusable widgets ───────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _MenuRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
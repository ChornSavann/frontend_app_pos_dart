import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_user.dart';
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';
import 'package:pos_inventory/models/user.dart';
import 'package:pos_inventory/users/roles/role_screen.dart';
import '../../api/roles/api_role.dart';
import '../../msg/appSnackBar.dart';
import 'models/role.dart';

class ManageUserRoleScreen extends StatefulWidget {
  const ManageUserRoleScreen({super.key});

  @override
  State<ManageUserRoleScreen> createState() => _ManageUserRoleScreenState();
}

class _ManageUserRoleScreenState extends State<ManageUserRoleScreen> {
  final ApiRole _apiRole = ApiRole();
  final ApiUser _apiUser = ApiUser();
  final String baseUrl = BaseUrlApi.baseurl;

  List<User> _users = [];
  List<Role> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_fetchUsers(), _fetchRolesList()]);
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final List<User> usersList = await _apiUser.getAllUsers();
      setState(() {
        _users = usersList;
      });
    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មិនអាចទាញយកទិន្នន័យ User បានទេ: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _fetchRolesList() async {
    try {
      final data = await _apiRole.fetchRoles();
      setState(() {
        _roles = data.map((json) => Role.fromJson(json)).toList();
      });
    } catch (e) {
      debugPrint("Error fetching roles: $e");
    }
  }

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

                  // បញ្ជី Role សម្រាប់ជ្រើសរើសក្នុង Modal
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
                            color: isSelected
                                ? const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.04)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey.shade200,
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
                            activeColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 16),

                  // ប៊ូតុងបញ្ជាក់ការរក្សាទុក
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
                      onPressed: () async {
                        if (selectedRoleId == null || user.id == null) return;

                        Navigator.pop(context);
                        bool success = await _updateUserRole(
                          user.id.toString(),
                          selectedRoleId!,
                        );
                        if (success) {
                          _loadData();
                        }
                      },
                      child: const Text(
                        'រក្សាទុក (Save Changes)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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

  Future<bool> _updateUserRole(String userId, String roleId) async {
    setState(() => _isLoading = true);
    final result = await _apiRole.assignRoleToEmployee(userId, roleId);
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        AppSnackBar.showSuccess(
          context,
          result['message'] ?? 'បានកំណត់ Role ជោគជ័យ!',
        );
      } else {
        AppSnackBar.showError(
          context,
          result['message'] ?? 'មានបញ្ហាក្នុងការកំណត់ Role',
        );
      }
    }
    return result['success'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manage User Roles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Material(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoleScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.list_alt_rounded,
                          color: Color(0xFF2563EB),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Roles List',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey.shade200,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'មិនមានទិន្នន័យអ្នកប្រើប្រាស់ទេ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2563EB),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 📊 Top Info Widget (បង្ហាញចំនួនសរុบ)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ចំនួនអ្នកប្រើប្រាស់សរុប: ${_users.length} នាក់',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List of Users
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final User user = _users[index];
                      String roleName = 'គ្មាន Role';
                      if (user.roleid != null) {
                        final matchedRole = _roles.firstWhere(
                          (r) => r.id.toString() == user.roleid.toString(),
                          orElse: () =>
                              Role(id: '', name: 'គ្មាន Role', description: ''),
                        );
                        roleName = matchedRole.name;
                      }

                      final String userName = user.name ?? 'Unknown';
                      final String userInitial = userName.isNotEmpty
                          ? userName.substring(0, 1).toUpperCase()
                          : 'U';

                      final bool hasRole = roleName != 'គ្មាន Role';
                      final String? userImage = user.image;
                      final String imageUrl =
                          (userImage != null && userImage.isNotEmpty)
                          ? (userImage.startsWith('http')
                                ? userImage
                                : '$baseUrl/storage/$userImage')
                          : '';

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
                            vertical: 10,
                          ),
                          leading: ClipOval(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                userInitial,
                                                style: const TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            );
                                          },
                                    )
                                  : Center(
                                      child: Text(
                                        userInitial,
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: hasRole
                                      ? Colors.blue.withValues(alpha: 0.08)
                                      : Colors.orange.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: hasRole
                                        ? Colors.blue.withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasRole
                                          ? Icons.verified_user_rounded
                                          : Icons.warning_amber_rounded,
                                      size: 14,
                                      color: hasRole
                                          ? const Color(0xFF2563EB)
                                          : Colors.orange.shade800,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Role: $roleName',
                                      style: TextStyle(
                                        color: hasRole
                                            ? const Color(0xFF2563EB)
                                            : Colors.orange.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                            ),
                            onPressed: () => _showAssignRoleDialog(user),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

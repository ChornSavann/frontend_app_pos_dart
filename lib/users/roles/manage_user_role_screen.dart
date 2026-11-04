import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_user.dart';
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';
import 'package:pos_inventory/models/user.dart';
import 'package:pos_inventory/users/roles/role_screen.dart';
import '../../api/roles/api_role.dart';
import '../../msg/appSnackBar.dart';
import 'models/role.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens (same family as the promotion screens)
// ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF0F4F4);
  static const ink = Color(0xFF0F1F1D);
  static const muted = Color(0xFF5E7476);
  static const line = Color(0xFFE3EBEA);
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
  static const warn = Color(0xFFC2570C);
  static const hot = Color(0xFFEF5B16);
  static const hotB = Color(0xFFFF8A3D);

  /// Colours handed out to roles so each role is easy to tell apart.
  static const roleColors = <Color>[
    Color(0xFF0F766E),
    Color(0xFF3B6FD4),
    Color(0xFF7C4DCC),
    Color(0xFFD6457A),
    Color(0xFFB7791F),
    Color(0xFF0E7490),
  ];
}

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

enum _Filter { all, assigned, unassigned }

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class ManageUserRoleScreen extends StatefulWidget {
  const ManageUserRoleScreen({super.key});

  @override
  State<ManageUserRoleScreen> createState() => _ManageUserRoleScreenState();
}

class _ManageUserRoleScreenState extends State<ManageUserRoleScreen> {
  final ApiRole _apiRole = ApiRole();
  final ApiUser _apiUser = ApiUser();
  final String baseUrl = BaseUrlApi.baseurl;
  final TextEditingController _searchCtrl = TextEditingController();

  List<User> _users = [];
  List<Role> _roles = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _updatingUserId;

  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────
  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final results = await Future.wait([_apiUser.getAllUsers(), _apiRole.fetchRoles()]);
      final users = results[0] as List<User>;
      final rolesJson = results[1] as List;
      if (!mounted) return;
      setState(() {
        _users = users;
        _roles = rolesJson.map((json) => Role.fromJson(json)).toList();
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (!mounted) return;
      setState(() => _hasError = true);
      if (silent) AppSnackBar.showError(context, 'មិនអាចទាញយកទិន្នន័យបានទេ');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Role? _roleOf(User user) {
    if (user.roleid == null) return null;
    final id = user.roleid.toString();
    for (final r in _roles) {
      if (r.id.toString() == id) return r;
    }
    return null;
  }

  Color _colorOfRole(Role? role) {
    if (role == null) return _C.warn;
    final i = _roles.indexWhere((r) => r.id == role.id);
    return _C.roleColors[(i < 0 ? 0 : i) % _C.roleColors.length];
  }

  String _imageUrl(User user) {
    final img = user.image;
    if (img == null || img.isEmpty) return '';
    return img.startsWith('http') ? img : '$baseUrl/storage/$img';
  }

  Future<void> _openAssignSheet(User user) async {
    if (user.id == null) return;
    HapticFeedback.selectionClick();

    final current = _roleOf(user);
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignSheet(
        user: user,
        imageUrl: _imageUrl(user),
        roles: _roles,
        currentRoleId: current?.id.toString(),
        colorOf: (r) => _colorOfRole(r),
      ),
    );

    if (picked == null || !mounted) return;
    await _updateUserRole(user.id.toString(), picked);
  }

  Future<void> _updateUserRole(String userId, String roleId) async {
    setState(() => _updatingUserId = userId);
    final result = await _apiRole.assignRoleToEmployee(userId, roleId);
    if (!mounted) return;

    final ok = result['success'] == true;
    if (ok) {
      HapticFeedback.lightImpact();
      AppSnackBar.showSuccess(context, result['message'] ?? 'បានកំណត់ Role ជោគជ័យ!');
      await _loadData(silent: true);
    } else {
      AppSnackBar.showError(context, result['message'] ?? 'មានបញ្ហាក្នុងការកំណត់ Role');
    }
    if (mounted) setState(() => _updatingUserId = null);
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final assigned = _users.where((u) => _roleOf(u) != null).length;
    final unassigned = _users.length - assigned;
    final q = _query.trim().toLowerCase();

    final visible = _users.where((u) {
      final has = _roleOf(u) != null;
      final okFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.assigned => has,
        _Filter.unassigned => !has,
      };
      if (!okFilter) return false;
      if (q.isEmpty) return true;
      return '${u.name ?? ''} ${u.email ?? ''}'.toLowerCase().contains(q);
    }).toList();

    final hasData = !_isLoading && !_hasError && _users.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadData(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  total: _users.length,
                  unassigned: unassigned,
                  showSearch: hasData,
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  onRoles: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleScreen()),
                  ),
                ),
              ),
              if (hasData)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedBar(
                    child: _FilterBar(
                      selected: _filter,
                      counts: {
                        _Filter.all: _users.length,
                        _Filter.assigned: assigned,
                        _Filter.unassigned: unassigned,
                      },
                      onSelect: (f) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f);
                      },
                    ),
                  ),
                ),
              if (_isLoading)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverToBoxAdapter(child: _SkeletonList()),
                )
              else if (_hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.cloud_off_rounded,
                    color: _C.muted,
                    title: 'មិនអាចទាញយកទិន្នន័យបានទេ',
                    actionLabel: 'សាកល្បងម្តងទៀត',
                    onAction: _loadData,
                  ),
                )
              else if (_users.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.group_off_rounded,
                      color: _C.brand,
                      title: 'មិនមានទិន្នន័យអ្នកប្រើប្រាស់ទេ',
                    ),
                  )
                else if (visible.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MessageState(
                        icon: Icons.search_off_rounded,
                        color: _C.muted,
                        title: 'រកមិនឃើញអ្នកប្រើប្រាស់',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final user = visible[i];
                          final role = _roleOf(user);
                          return _FadeSlide(
                            index: i,
                            child: _UserCard(
                              user: user,
                              imageUrl: _imageUrl(user),
                              role: role,
                              color: _colorOfRole(role),
                              updating: _updatingUserId == user.id?.toString(),
                              onTap: () => _openAssignSheet(user),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
class _FadeSlide extends StatelessWidget {
  final int index;
  final Widget child;
  const _FadeSlide({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index > 6 ? 6 : index) * 50;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: c),
      ),
      child: child,
    );
  }
}

class _PinnedBar extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PinnedBar({required this.child});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      Container(color: _C.bg, alignment: Alignment.centerLeft, child: child);

  @override
  bool shouldRebuild(covariant _PinnedBar old) => true;
}

// ─────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final int total;
  final int unassigned;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onRoles;

  const _Hero({
    required this.total,
    required this.unassigned,
    required this.showSearch,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onRoles,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_C.heroA, _C.heroB],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, top + 6, 16, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Manage User Roles',
                                style: _t(20, FontWeight.w800, Colors.white, spacing: -0.3)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.people_alt_rounded,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 5),
                                Text('$total នាក់',
                                    style: _t(12.5, FontWeight.w600,
                                        Colors.white.withValues(alpha: 0.9))),
                                if (unassigned > 0) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: _C.hotB.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('$unassigned គ្មាន Role',
                                        style: _t(10.5, FontWeight.w800, Colors.white)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onRoles,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.list_alt_rounded,
                                    color: Colors.white, size: 17),
                                const SizedBox(width: 6),
                                Text('Roles',
                                    style: _t(12.5, FontWeight.w800, Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showSearch) ...[
                    const SizedBox(height: 14),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        cursorColor: _C.brand,
                        style: _t(14, FontWeight.w500, _C.ink),
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកឈ្មោះ ឬអ៊ីមែល',
                          hintStyle: _t(13.5, FontWeight.w400, _C.muted),
                          prefixIcon: const Icon(Icons.search_rounded, color: _C.muted),
                          suffixIcon: controller.text.isEmpty
                              ? null
                              : IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 20, color: _C.muted),
                            onPressed: onClear,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final _Filter selected;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onSelect;
  const _FilterBar({required this.selected, required this.counts, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const items = <(_Filter, String)>[
      (_Filter.all, 'ទាំងអស់'),
      (_Filter.assigned, 'មាន Role'),
      (_Filter.unassigned, 'គ្មាន Role'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final it = items[i];
          final sel = selected == it.$1;
          return GestureDetector(
            onTap: () => onSelect(it.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? _C.brand : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _C.brand : _C.line),
              ),
              child: Row(
                children: [
                  Text(it.$2,
                      style: _t(13, FontWeight.w700, sel ? Colors.white : _C.ink)),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white.withValues(alpha: 0.22) : _C.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${counts[it.$1] ?? 0}',
                        style: _t(11.5, FontWeight.w800, sel ? Colors.white : _C.muted)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final Color color;
  final double size;
  const _Avatar({
    required this.name,
    required this.imageUrl,
    required this.color,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'U';
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(initial, style: _t(size * 0.38, FontWeight.w800, Colors.white)),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? fallback
            : Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// User card
// ─────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final User user;
  final String imageUrl;
  final Role? role;
  final Color color;
  final bool updating;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.imageUrl,
    required this.role,
    required this.color,
    required this.updating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.name ?? 'Unknown';
    final has = role != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.heroA.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: updating ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              children: [
                _Avatar(name: name, imageUrl: imageUrl, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(15, FontWeight.w800, _C.ink)),
                      const SizedBox(height: 2),
                      Text(user.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(12.5, FontWeight.w500, _C.muted)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              has ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                              size: 13,
                              color: color,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                has ? role!.name : 'គ្មាន Role',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(11.5, FontWeight.w800, color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: updating
                      ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.brand),
                  )
                      : Container(
                    decoration: BoxDecoration(
                      color: _C.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      has ? Icons.swap_horiz_rounded : Icons.person_add_alt_1_rounded,
                      size: 20,
                      color: _C.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Assign role bottom sheet
// ─────────────────────────────────────────────────────────────
class _AssignSheet extends StatefulWidget {
  final User user;
  final String imageUrl;
  final List<Role> roles;
  final String? currentRoleId;
  final Color Function(Role) colorOf;

  const _AssignSheet({
    required this.user,
    required this.imageUrl,
    required this.roles,
    required this.currentRoleId,
    required this.colorOf,
  });

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentRoleId;
  }

  bool get _changed => _selected != null && _selected != widget.currentRoleId;

  @override
  Widget build(BuildContext context) {
    final name = widget.user.name ?? 'Unknown';
    final maxH = MediaQuery.of(context).size.height * 0.78;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: _C.line, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 6),
              child: Row(
                children: [
                  _Avatar(name: name, imageUrl: widget.imageUrl, color: _C.brand, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('កំណត់សិទ្ធិនិងតួនាទី', style: _t(17, FontWeight.w800, _C.ink)),
                        const SizedBox(height: 2),
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(13, FontWeight.w500, _C.muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _C.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: widget.roles.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(32),
                child: Text('មិនទាន់មាន Role',
                    style: _t(14, FontWeight.w600, _C.muted)),
              )
                  : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: widget.roles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final role = widget.roles[i];
                  final id = role.id.toString();
                  final sel = _selected == id;
                  final isCurrent = widget.currentRoleId == id;
                  final c = widget.colorOf(role);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sel ? c.withValues(alpha: 0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: sel ? c : _C.line,
                          width: sel ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(Icons.shield_outlined, color: c, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(role.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _t(14.5, FontWeight.w800, _C.ink)),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _C.bg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('បច្ចុប្បន្ន',
                                            style: _t(10, FontWeight.w800, _C.muted)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  role.description.isNotEmpty
                                      ? role.description
                                      : 'គ្មានការពិពណ៌នា',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(12, FontWeight.w500, _C.muted, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: sel ? c : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: sel ? c : _C.line, width: 2),
                            ),
                            child: sel
                                ? const Icon(Icons.check_rounded,
                                size: 15, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _changed ? 1 : 0.45,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_C.heroA, _C.brand, _C.heroB]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _changed
                          ? [
                        BoxShadow(
                          color: _C.brand.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _changed ? () => Navigator.pop(context, _selected) : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text('រក្សាទុក (Save Changes)',
                                style: _t(15.5, FontWeight.w800, Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Skeleton + empty / error
// ─────────────────────────────────────────────────────────────
class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bar(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: _C.line, borderRadius: BorderRadius.circular(6)),
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_ctrl),
      child: Column(
        children: List.generate(
          6,
              (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(color: _C.line, shape: BoxShape.circle),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(130, 14),
                      const SizedBox(height: 8),
                      _bar(170, 11),
                      const SizedBox(height: 10),
                      _bar(80, 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.color,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: _t(15, FontWeight.w800, _C.ink, height: 1.4)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _C.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: Text(actionLabel!, style: _t(13, FontWeight.bold, Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
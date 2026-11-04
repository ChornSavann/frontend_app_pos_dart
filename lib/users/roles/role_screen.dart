import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/users/roles/create_role_screen.dart';
import 'package:pos_inventory/users/roles/update_role_screen.dart';
import '../../api/roles/api_role.dart';
import '../../msg/appSnackBar.dart';
import '../permission/permission_screen.dart';
import 'role_permission_screen.dart';
import 'models/role.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF0F4F4);
  static const ink = Color(0xFF0F1F1D);
  static const muted = Color(0xFF5E7476);
  static const line = Color(0xFFE3EBEA);
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
  static const danger = Color(0xFFD32F2F);
  static const hot = Color(0xFFEF5B16);
  static const hotB = Color(0xFFFF8A3D);

  // Same palette as the Manage User Roles screen, so a role keeps its colour
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

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  final ApiRole _apiRole = ApiRole();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Role> _roles = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _deletingId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoles({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final data = await _apiRole.fetchRoles();
      if (!mounted) return;
      setState(() {
        _roles = data.map((json) => Role.fromJson(json)).toList();
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading roles: $e');
      if (!mounted) return;
      setState(() => _hasError = true);
      if (silent) AppSnackBar.showError(context, 'មិនអាចទាញយកទិន្នន័យ Role បានទេ');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRole(Role role) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: _C.danger, size: 34),
              ),
              const SizedBox(height: 16),
              Text('លុបតួនាទី (Delete Role)', style: _t(18, FontWeight.w800, _C.ink)),
              const SizedBox(height: 8),
              Text(
                'តើអ្នកពិតជាចង់លុប Role "${role.name}" នេះមែនទេ?',
                textAlign: TextAlign.center,
                style: _t(13.5, FontWeight.w400, _C.muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.ink,
                        side: const BorderSide(color: _C.line),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('បោះបង់', style: _t(14, FontWeight.w800, _C.ink)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('លុប', style: _t(14, FontWeight.w800, Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deletingId = role.id.toString());
    try {
      final result = await _apiRole.deleteRole(role.id.toString());
      if (!mounted) return;
      if (result['success'] == true) {
        AppSnackBar.showSuccess(context, 'បានលុប Role ជោគជ័យ!');
        await _loadRoles(silent: true);
      } else {
        AppSnackBar.showError(context, result['message'] ?? 'មិនអាចលុប Role នេះបានទេ');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error deleting role: $e');
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _openPermissions(Role role) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RolePermissionScreen(role: role)),
    );
    if (result == true) _loadRoles(silent: true);
  }

  Future<void> _editRole(Role role) async {
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UpdateRoleScreen(role: role)),
    );
    if (updated == true) _loadRoles(silent: true);
  }

  Future<void> _createRole() async {
    final bool? created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRoleScreen()),
    );
    if (created == true) _loadRoles(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = <(int, Role)>[
      for (var i = 0; i < _roles.length; i++)
        if (q.isEmpty ||
            '${_roles[i].name} ${_roles[i].description}'.toLowerCase().contains(q))
          (i, _roles[i]),
    ];

    final hasData = !_isLoading && !_hasError && _roles.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadRoles(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  count: _roles.length,
                  showSearch: hasData,
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  onPermissions: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PermissionScreen()),
                  ),
                ),
              ),
              if (_isLoading)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 110),
                  sliver: SliverToBoxAdapter(child: _SkeletonList()),
                )
              else if (_hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.cloud_off_rounded,
                    color: _C.muted,
                    title: 'មិនអាចទាញយកទិន្នន័យ Role បានទេ',
                    actionLabel: 'សាកល្បងម្តងទៀត',
                    onAction: _loadRoles,
                  ),
                )
              else if (_roles.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.admin_panel_settings_outlined,
                      color: _C.brand,
                      title: 'មិនមានទិន្នន័យ Role ទេ',
                      subtitle: 'បង្កើត Role ដំបូងរបស់អ្នក ដើម្បីកំណត់សិទ្ធិ',
                      actionLabel: 'បង្កើត Role',
                      onAction: _createRole,
                    ),
                  )
                else if (visible.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MessageState(
                        icon: Icons.search_off_rounded,
                        color: _C.muted,
                        title: 'រកមិនឃើញ Role',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                      sliver: SliverList.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final (index, role) = visible[i];
                          return _FadeSlide(
                            index: i,
                            child: _RoleCard(
                              role: role,
                              color: _C.roleColors[index % _C.roleColors.length],
                              deleting: _deletingId == role.id.toString(),
                              onOpen: () => _openPermissions(role),
                              onEdit: () => _editRole(role),
                              onDelete: () => _deleteRole(role),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
        floatingActionButton: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.hot, _C.hotB]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _C.hot.withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _createRole,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 6),
                    Text('New role', style: _t(14, FontWeight.w800, Colors.white)),
                  ],
                ),
              ),
            ),
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

// ─────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final int count;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onPermissions;

  const _Hero({
    required this.count,
    required this.showSearch,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onPermissions,
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
                            Text('Management Roles',
                                style: _t(20, FontWeight.w800, Colors.white, spacing: -0.3)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 5),
                                Text('$count Roles',
                                    style: _t(12.5, FontWeight.w600,
                                        Colors.white.withValues(alpha: 0.9))),
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
                          onTap: onPermissions,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.admin_panel_settings_rounded,
                                    color: Colors.white, size: 17),
                                const SizedBox(width: 6),
                                Text('Permissions',
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
                          hintText: 'ស្វែងរក Role',
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
// Role card
// ─────────────────────────────────────────────────────────────
enum _Action { edit, delete }

class _RoleCard extends StatelessWidget {
  final Role role;
  final Color color;
  final bool deleting;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
    required this.color,
    required this.deleting,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDesc = role.description.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.heroA.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: deleting ? null : onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.85), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(16, FontWeight.w800, _C.ink)),
                      const SizedBox(height: 3),
                      Text(
                        hasDesc ? role.description : 'គ្មានការពិពណ៌នា',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _t(12.5, hasDesc ? FontWeight.w500 : FontWeight.w400, _C.muted,
                            height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.lock_open_rounded, size: 13, color: color),
                          const SizedBox(width: 5),
                          Text('Manage permissions',
                              style: _t(11.5, FontWeight.w800, color)),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 16, color: color),
                        ],
                      ),
                    ],
                  ),
                ),
                if (deleting)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.danger),
                    ),
                  )
                else
                  PopupMenuButton<_Action>(
                    tooltip: 'More',
                    icon: const Icon(Icons.more_vert_rounded, color: _C.muted),
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (a) {
                      switch (a) {
                        case _Action.edit:
                          onEdit();
                        case _Action.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _Action.edit,
                        child: Row(
                          children: [
                            const Icon(Icons.edit_rounded, size: 18, color: _C.brand),
                            const SizedBox(width: 10),
                            Text('Edit Role', style: _t(13.5, FontWeight.w700, _C.ink)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded, size: 18, color: _C.danger),
                            const SizedBox(width: 10),
                            Text('Delete Role', style: _t(13.5, FontWeight.w700, _C.danger)),
                          ],
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
          5,
              (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _C.line,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(120, 15),
                      const SizedBox(height: 8),
                      _bar(double.infinity, 11),
                      const SizedBox(height: 10),
                      _bar(110, 11),
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
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
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
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: _t(13, FontWeight.w400, _C.muted, height: 1.5)),
          ],
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
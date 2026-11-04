import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';

import '../../api/authority/api_authority.dart';
import 'models/authority_log_model.dart';
import 'user_log_detail_screen.dart';

class _C {
  static const bg = Color(0xFFF0F4F4);
  static const ink = Color(0xFF0F1F1D);
  static const muted = Color(0xFF5E7476);
  static const line = Color(0xFFE3EBEA);
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
  static const login = Color(0xFF059669);
  static const loginBg = Color(0xFFE7F7EF);
  static const logout = Color(0xFFDC2626);
  static const logoutBg = Color(0xFFFDECEC);
}

TextStyle _t(
  double size,
  FontWeight w,
  Color c, {
  double? height,
  double? spacing,
}) => TextStyle(
  fontSize: size,
  fontWeight: w,
  color: c,
  height: height,
  letterSpacing: spacing,
);

enum _Filter { all, login, logout }

const _khMonths = [
  'មករា',
  'កុម្ភៈ',
  'មីនា',
  'មេសា',
  'ឧសភា',
  'មិថុនា',
  'កក្កដា',
  'សីហា',
  'កញ្ញា',
  'តុលា',
  'វិច្ឆិកា',
  'ធ្នូ',
];

class AuthorityScreen extends StatefulWidget {
  const AuthorityScreen({super.key});

  @override
  State<AuthorityScreen> createState() => _AuthorityScreenState();
}

class _AuthorityScreenState extends State<AuthorityScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  bool _hasError = false;
  List<AuthLogModel> _logs = [];

  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLogs({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final rawData = await AuthorityApiService.fetchAuthLogs();
      final logs = rawData.map((item) => AuthLogModel.fromJson(item)).toList();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading logs: $e');
      if (!mounted) return;
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Date helpers ───────────────────────────────────────────
  List<String> _split(String ts) => ts.trim().replaceFirst('T', ' ').split(' ');

  String _timeOf(String ts) {
    final p = _split(ts);
    if (p.length < 2) return ts;
    return p[1].length >= 5 ? p[1].substring(0, 5) : p[1];
  }

  String _dateOf(String ts) {
    final p = _split(ts);
    return p.length < 2 ? '' : p[0];
  }

  String _dateLabel(String key) {
    if (key.isEmpty) return 'មិនស្គាល់កាលបរិច្ឆេទ';
    String f(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    if (key == f(now)) return 'ថ្ងៃនេះ';
    if (key == f(now.subtract(const Duration(days: 1)))) return 'ម្សិលមិញ';
    final p = key.split('-');
    if (p.length == 3) {
      final m = int.tryParse(p[1]);
      final d = int.tryParse(p[2]);
      if (m != null && d != null && m >= 1 && m <= 12) {
        return '$d ${_khMonths[m - 1]} ${p[0]}';
      }
    }
    return key;
  }

  Future<bool> _confirm({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    HapticFeedback.mediumImpact();
    final res = await showDialog<bool>(
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
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 34),
              ),
              const SizedBox(height: 16),
              Text(title, style: _t(18, FontWeight.w800, _C.ink)),
              const SizedBox(height: 8),
              Text(
                message,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'បោះបង់',
                        style: _t(14, FontWeight.w800, _C.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: _t(14, FontWeight.w800, Colors.white),
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
    return res == true;
  }

  Future<void> _forceLogout(int userId, String userName) async {
    final ok = await _confirm(
      icon: Icons.power_settings_new_rounded,
      color: _C.logout,
      title: 'បណ្តេញចេញពីប្រព័ន្ធ',
      message:
          "តើអ្នកពិតជាចង់ Force Logout ឱ្យ '$userName' ចេញពីប្រព័ន្ធមែនទេ?",
      confirmLabel: 'យល់ព្រម',
    );
    if (!ok || !mounted) return;

    final success = await AuthorityApiService.forceLogoutUser(userId);
    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(
        context,
        'បានបណ្តេញ User នោះចេញពីប្រព័ន្ធដោយជោគជ័យ',
      );
      _loadLogs(silent: true);
    } else {
      AppSnackBar.showError(context, 'បរាជ័យក្នុងការ Force Logout');
    }
  }

  Future<void> _deleteLog(int logId) async {
    final ok = await _confirm(
      icon: Icons.delete_outline_rounded,
      color: _C.logout,
      title: 'លុបកំណត់ត្រា Log',
      message: 'តើអ្នកពិតជាចង់លុបកំណត់ត្រា Log នេះចេញពីប្រព័ន្ធមែនទេ?',
      confirmLabel: 'លុប',
    );
    if (!ok || !mounted) return;

    final success = await AuthorityApiService.deleteAuthLog(logId);
    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(context, 'បានលុបកំណត់ត្រា Log ដោយជោគជ័យ');
      _loadLogs(silent: true);
    } else {
      AppSnackBar.showError(context, 'បរាជ័យក្នុងការលុប Log');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _logs.length;
    final loginCount = _logs.where((l) => l.action == 'LOGIN').length;
    final logoutCount = total - loginCount;
    final q = _query.trim().toLowerCase();

    final visible = _logs.where((l) {
      final okFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.login => l.action == 'LOGIN',
        _Filter.logout => l.action != 'LOGIN',
      };
      if (!okFilter) return false;
      if (q.isEmpty) return true;
      return '${l.user?.name ?? ''} ${l.userId}'.toLowerCase().contains(q);
    }).toList();

    final groups = <String, List<AuthLogModel>>{};
    for (final log in visible) {
      groups.putIfAbsent(_dateOf(log.timestamp), () => []).add(log);
    }

    final hasData = !_isLoading && !_hasError && _logs.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadLogs(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  total: total,
                  login: loginCount,
                  logout: logoutCount,
                  showStats: hasData,
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  onRefresh: _loadLogs,
                ),
              ),
              if (hasData)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedBar(
                    child: _FilterBar(
                      selected: _filter,
                      counts: {
                        _Filter.all: total,
                        _Filter.login: loginCount,
                        _Filter.logout: logoutCount,
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
                    onAction: _loadLogs,
                  ),
                )
              else if (_logs.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.security_rounded,
                    color: _C.brand,
                    title: 'មិនមានទិន្នន័យសកម្មភាពឡើយ',
                  ),
                )
              else if (visible.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.search_off_rounded,
                    color: _C.muted,
                    title: 'រកមិនឃើញកំណត់ត្រា',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      for (final e in groups.entries)
                        _Group(
                          label: _dateLabel(e.key),
                          count: e.value.length,
                          children: [
                            for (var i = 0; i < e.value.length; i++) ...[
                              _LogRow(
                                log: e.value[i],
                                time: _timeOf(e.value[i].timestamp),
                                onOpen: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UserLogDetailScreen(log: e.value[i]),
                                  ),
                                ),
                                onDelete: () {
                                  final id =
                                      int.tryParse(e.value[i].id.toString()) ??
                                      0;
                                  if (id > 0) _deleteLog(id);
                                },
                                onForceLogout: () {
                                  final uid =
                                      int.tryParse(
                                        e.value[i].userId.toString(),
                                      ) ??
                                      0;
                                  _forceLogout(
                                    uid,
                                    e.value[i].user?.name ?? 'User',
                                  );
                                },
                              ),
                              if (i != e.value.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: 72,
                                  endIndent: 14,
                                  color: _C.line,
                                ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.touch_app_outlined,
                            size: 14,
                            color: _C.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ចុចឱ្យយូរលើកំណត់ត្រា ដើម្បីលុប',
                            style: _t(11.5, FontWeight.w500, _C.muted),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
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

class _FilterBar extends StatelessWidget {
  final _Filter selected;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onSelect;
  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const items = <(_Filter, String, Color)>[
      (_Filter.all, 'ទាំងអស់', _C.brand),
      (_Filter.login, 'LOGIN', _C.login),
      (_Filter.logout, 'LOGOUT', _C.logout),
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
                color: sel ? it.$3 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? it.$3 : _C.line),
              ),
              child: Row(
                children: [
                  Text(
                    it.$2,
                    style: _t(13, FontWeight.w700, sel ? Colors.white : _C.ink),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white.withValues(alpha: 0.22) : _C.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${counts[it.$1] ?? 0}',
                      style: _t(
                        11.5,
                        FontWeight.w800,
                        sel ? Colors.white : _C.muted,
                      ),
                    ),
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
// Hero with stats + search
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final int total;
  final int login;
  final int logout;
  final bool showStats;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  const _Hero({
    required this.total,
    required this.login,
    required this.logout,
    required this.showStats,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onRefresh,
  });

  Widget _stat(String label, int value, Color dot) {
    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${v.round()}',
              style: _t(24, FontWeight.w800, Colors.white, height: 1.1),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: _t(
                  11.5,
                  FontWeight.w700,
                  Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
              padding: EdgeInsets.fromLTRB(16, top + 6, 12, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security Logs',
                              style: _t(
                                21,
                                FontWeight.w800,
                                Colors.white,
                                spacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'កំណត់ត្រាសកម្មភាពចូល-ចេញប្រព័ន្ធ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(
                                12.5,
                                FontWeight.w500,
                                Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: 'Refresh',
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                          onPressed: onRefresh,
                        ),
                      ),
                    ],
                  ),
                  if (showStats) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _stat('សរុប', total, Colors.white),
                                _stat('LOGIN', login, const Color(0xFF7CFFB2)),
                                _stat(
                                  'LOGOUT',
                                  logout,
                                  const Color(0xFFFF9B9B),
                                ),
                              ],
                            ),
                            if (total > 0) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 5,
                                  child: Row(
                                    children: [
                                      if (login > 0)
                                        Expanded(
                                          flex: login,
                                          child: Container(
                                            color: const Color(0xFF7CFFB2),
                                          ),
                                        ),
                                      if (login > 0 && logout > 0)
                                        const SizedBox(width: 2),
                                      if (logout > 0)
                                        Expanded(
                                          flex: logout,
                                          child: Container(
                                            color: const Color(0xFFFF9B9B),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
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
                            hintText: 'ស្វែងរកឈ្មោះ ឬ User ID',
                            hintStyle: _t(13.5, FontWeight.w400, _C.muted),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: _C.muted,
                            ),
                            suffixIcon: controller.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: _C.muted,
                                    ),
                                    onPressed: onClear,
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
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
// Date group + log row
// ─────────────────────────────────────────────────────────────
class _Group extends StatelessWidget {
  final String label;
  final int count;
  final List<Widget> children;
  const _Group({
    required this.label,
    required this.count,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Row(
            children: [
              Text(label, style: _t(13.5, FontWeight.w800, _C.muted)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.line),
                ),
                child: Text(
                  '$count',
                  style: _t(10.5, FontWeight.w800, _C.muted),
                ),
              ),
            ],
          ),
        ),
        Container(
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
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  final AuthLogModel log;
  final String time;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onForceLogout;

  const _LogRow({
    required this.log,
    required this.time,
    required this.onOpen,
    required this.onDelete,
    required this.onForceLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = log.action == 'LOGIN';
    final color = isLogin ? _C.login : _C.logout;
    final bg = isLogin ? _C.loginBg : _C.logoutBg;
    final name = log.user?.name ?? 'Unknown User';
    final image = log.user?.image;

    return InkWell(
      onTap: onOpen,
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            _Avatar(name: name, imageUrl: image, ring: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(14.5, FontWeight.w800, _C.ink),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLogin
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              size: 11,
                              color: color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              log.action,
                              style: _t(10.5, FontWeight.w800, color),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${log.userId}',
                        style: _t(11.5, FontWeight.w500, _C.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(time, style: _t(13, FontWeight.w800, _C.ink)),
            const SizedBox(width: 6),
            if (isLogin)
              Tooltip(
                message: 'Force Logout',
                child: InkWell(
                  onTap: onForceLogout,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _C.logoutBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.power_settings_new_rounded,
                      size: 19,
                      color: _C.logout,
                    ),
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _C.muted,
              ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final Color ring;
  const _Avatar({
    required this.name,
    required this.imageUrl,
    required this.ring,
  });

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'U';
    final fallback = Container(
      color: _C.brand.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(initial, style: _t(17, FontWeight.w800, _C.brand)),
    );
    final has = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring.withValues(alpha: 0.45), width: 2),
      ),
      child: ClipOval(
        child: has
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
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

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
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
    decoration: BoxDecoration(
      color: _C.line,
      borderRadius: BorderRadius.circular(6),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_ctrl),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: List.generate(
            6,
            (i) => Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: _C.line,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(120, 14),
                        const SizedBox(height: 8),
                        _bar(90, 12),
                      ],
                    ),
                  ),
                  _bar(40, 14),
                ],
              ),
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: _t(15, FontWeight.w800, _C.ink, height: 1.4),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _C.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
              child: Text(
                actionLabel!,
                style: _t(13, FontWeight.bold, Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

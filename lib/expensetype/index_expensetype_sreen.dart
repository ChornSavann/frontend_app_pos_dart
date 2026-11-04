import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/expensetype/api_expensetype.dart';
import 'package:pos_inventory/expensetype/create_expens_type_screen.dart';
import 'package:pos_inventory/expensetype/update_expense_type_screen.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';

import 'models/expense_type.dart';

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

  static const itemColors = <Color>[
    Color(0xFF0F766E),
    Color(0xFF3B6FD4),
    Color(0xFF7C4DCC),
    Color(0xFFD6457A),
    Color(0xFFB7791F),
    Color(0xFF0E7490),
  ];
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

class IndexExpensetypeSreen extends StatefulWidget {
  const IndexExpensetypeSreen({super.key});

  @override
  State<IndexExpensetypeSreen> createState() => _IndexExpensetypeSreenState();
}

class _IndexExpensetypeSreenState extends State<IndexExpensetypeSreen> {
  final ApiExpensetype apiExpensetype = ApiExpensetype();
  final TextEditingController _searchCtrl = TextEditingController();

  List<ExpenseType> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  int? _deletingId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadExpenseTypes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExpenseTypes({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final list = await apiExpensetype.fetchExpenseType();
      if (!mounted) return;
      setState(() {
        _items = list;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading expense types: $e');
      if (!mounted) return;
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpenseType(ExpenseType item) async {
    final id = item.id;
    if (id == null) {
      AppSnackBar.showError(context, 'Error: Item ID is null! ❌');
      return;
    }

    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
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
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _C.danger,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete expense type',
                style: _t(18, FontWeight.w800, _C.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${item.name ?? 'this item'}"?',
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
                        'Cancel',
                        style: _t(14, FontWeight.w800, _C.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Delete',
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

    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = id);
    final success = await apiExpensetype.deleteExpenseType(id);
    if (!mounted) return;

    if (success) {
      AppSnackBar.showSuccess(context, 'Deleted successfully! 🗑️');
      await _loadExpenseTypes(silent: true);
    } else {
      AppSnackBar.showError(context, 'Failed to delete item! ❌');
    }
    if (mounted) setState(() => _deletingId = null);
  }

  Future<void> _edit(ExpenseType item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateExpenseTypeScreen(
          expenseTypeId: item.id ?? 0,
          initialName: item.name ?? '',
          initialDescription: item.description ?? '',
        ),
      ),
    );
    if (result == true) _loadExpenseTypes(silent: true);
  }

  Future<void> _create() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateExpensTypeScreen()),
    );
    if (result == true) _loadExpenseTypes(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = <(int, ExpenseType)>[
      for (var i = 0; i < _items.length; i++)
        if (q.isEmpty ||
            '${_items[i].name ?? ''} ${_items[i].description ?? ''}'
                .toLowerCase()
                .contains(q))
          (i, _items[i]),
    ];

    final hasData = !_isLoading && !_hasError && _items.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadExpenseTypes(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  count: _items.length,
                  shown: visible.length,
                  filtering: q.isNotEmpty,
                  showSearch: hasData,
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  onRefresh: _loadExpenseTypes,
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
                    title: 'Could not load expense types',
                    actionLabel: 'Try again',
                    onAction: _loadExpenseTypes,
                  ),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.category_outlined,
                    color: _C.brand,
                    title: 'No expense types found.',
                    subtitle: 'Create your first expense type.',
                    actionLabel: 'Add new',
                    onAction: _create,
                  ),
                )
              else if (visible.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.search_off_rounded,
                    color: _C.muted,
                    title: 'No expense types match your search',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final (index, item) = visible[i];
                      return _FadeSlide(
                        index: i,
                        child: _ExpenseTypeCard(
                          item: item,
                          color: _C.itemColors[index % _C.itemColors.length],
                          deleting:
                              _deletingId != null && _deletingId == item.id,
                          onEdit: () => _edit(item),
                          onDelete: () => _deleteExpenseType(item),
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
            shape: BoxShape.circle,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              containedInkWell: true,
              highlightShape: BoxShape.circle,
              onTap: _create,
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
  final int shown;
  final bool filtering;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  const _Hero({
    required this.count,
    required this.shown,
    required this.filtering,
    required this.showSearch,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onRefresh,
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
                              'Expense Types',
                              style: _t(
                                21,
                                FontWeight.w800,
                                Colors.white,
                                spacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  filtering
                                      ? '$shown / $count types'
                                      : '$count types',
                                  style: _t(
                                    12.5,
                                    FontWeight.w600,
                                    Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
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
                  if (showSearch) ...[
                    const SizedBox(height: 14),
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
                            hintText: 'Search expense type',
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
// Card
// ─────────────────────────────────────────────────────────────
enum _Action { edit, delete }

class _ExpenseTypeCard extends StatelessWidget {
  final ExpenseType item;
  final Color color;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTypeCard({
    required this.item,
    required this.color,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final desc = item.description?.trim() ?? '';
    final hasDesc = desc.isNotEmpty;

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
          onTap: deleting ? null : onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.85), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? 'No Name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(16, FontWeight.w800, _C.ink),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasDesc ? desc : 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _t(
                          12.5,
                          hasDesc ? FontWeight.w500 : FontWeight.w400,
                          _C.muted,
                          height: 1.4,
                        ),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _C.danger,
                      ),
                    ),
                  )
                else
                  PopupMenuButton<_Action>(
                    tooltip: 'More',
                    icon: const Icon(Icons.more_vert_rounded, color: _C.muted),
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                            const Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: _C.brand,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Edit',
                              style: _t(13.5, FontWeight.w700, _C.ink),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: _C.danger,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Delete',
                              style: _t(13.5, FontWeight.w700, _C.danger),
                            ),
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
                  width: 50,
                  height: 50,
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: _t(15, FontWeight.w800, _C.ink, height: 1.4),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: _t(13, FontWeight.w400, _C.muted, height: 1.5),
            ),
          ],
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

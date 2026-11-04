import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/expenses/show_expense_screen.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';

import '../api/expense/api_expense.dart';
import 'create_expense_screen.dart';
import 'models/expense.dart';

class _C {
  static const bg = Color(0xFFF0F4F4);
  static const ink = Color(0xFF0F1F1D);
  static const muted = Color(0xFF5E7476);
  static const line = Color(0xFFE3EBEA);
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
  static const danger = Color(0xFFD32F2F);
  static const card = Color(0xFF3B6FD4);
  static const hot = Color(0xFFEF5B16);
  static const hotB = Color(0xFFFF8A3D);
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

enum _Filter { all, cash, other }

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

double _amountOf(Expense e) =>
    e.amount == null ? 0.0 : (double.tryParse(e.amount.toString()) ?? 0.0);

bool _isCash(Expense e) =>
    (e.paymentMethod ?? 'Cash').toLowerCase().contains('cash');

String _money(double v) => '\$${v.toStringAsFixed(2)}';

class IndexExpenseScreen extends StatefulWidget {
  const IndexExpenseScreen({super.key});

  @override
  State<IndexExpenseScreen> createState() => _IndexExpenseScreenState();
}

class _IndexExpenseScreenState extends State<IndexExpenseScreen> {
  final ApiExpense apiExpense = ApiExpense();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Expense> _expenses = [];
  bool _isLoading = true;
  bool _hasError = false;

  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final list = await apiExpense.fetchExpenses();
      if (!mounted) return;
      setState(() {
        _expenses = list;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      if (!mounted) return;
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpense(int id) async {
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
              Text('Delete expense', style: _t(18, FontWeight.w800, _C.ink)),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete this expense record?',
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

    final success = await apiExpense.deleteExpense(id);
    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(context, 'Deleted successfully! 🗑️');
      _loadExpenses(silent: true);
    } else {
      AppSnackBar.showError(context, 'Failed to delete item! ❌');
    }
  }

  Future<void> _open(Expense item) async {
    if (item.id == null) {
      AppSnackBar.showError(context, 'Error: Expense ID is null! ❌');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShowExpenseScreen(expenseId: item.id!)),
    );
    if (mounted) _loadExpenses(silent: true);
  }

  Future<void> _create() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateExpenseScreen()),
    );
    if (result == true) _loadExpenses(silent: true);
  }

  // ── Date grouping ──────────────────────────────────────────
  String _dateKey(String? s) {
    if (s == null || s.trim().isEmpty) return '';
    return s.trim().replaceFirst('T', ' ').split(' ').first;
  }

  String _dateLabel(String key) {
    if (key.isEmpty) return 'No date';
    String f(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    if (key == f(now)) return 'Today';
    if (key == f(now.subtract(const Duration(days: 1)))) return 'Yesterday';
    final p = key.split('-');
    if (p.length == 3) {
      final m = int.tryParse(p[1]);
      final d = int.tryParse(p[2]);
      if (m != null && d != null && m >= 1 && m <= 12)
        return '$d ${_months[m - 1]} ${p[0]}';
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final cashCount = _expenses.where(_isCash).length;
    final otherCount = _expenses.length - cashCount;

    final visible = _expenses.where((e) {
      final okFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.cash => _isCash(e),
        _Filter.other => !_isCash(e),
      };
      if (!okFilter) return false;
      if (q.isEmpty) return true;
      return '${e.expenseType ?? ''} ${e.referenceNo ?? ''} ${e.paymentMethod ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();

    final total = visible.fold<double>(0, (sum, e) => sum + _amountOf(e));
    final filtering = _filter != _Filter.all || q.isNotEmpty;

    final groups = <String, List<Expense>>{};
    for (final e in visible) {
      groups.putIfAbsent(_dateKey(e.expenseDate), () => []).add(e);
    }

    final hasData = !_isLoading && !_hasError && _expenses.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadExpenses(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  total: total,
                  records: visible.length,
                  filtering: filtering,
                  showSummary: hasData,
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  onRefresh: _loadExpenses,
                ),
              ),
              if (hasData)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedBar(
                    child: _FilterBar(
                      selected: _filter,
                      counts: {
                        _Filter.all: _expenses.length,
                        _Filter.cash: cashCount,
                        _Filter.other: otherCount,
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
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 110),
                  sliver: SliverToBoxAdapter(child: _SkeletonList()),
                )
              else if (_hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.cloud_off_rounded,
                    color: _C.muted,
                    title: 'Could not load expenses',
                    actionLabel: 'Try again',
                    onAction: _loadExpenses,
                  ),
                )
              else if (_expenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.receipt_long_outlined,
                    color: _C.brand,
                    title: 'No expense records found.',
                    subtitle: 'Record your first expense.',
                    actionLabel: 'Add expense',
                    onAction: _create,
                  ),
                )
              else if (visible.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.search_off_rounded,
                    color: _C.muted,
                    title: 'No expenses match your search',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      for (final e in groups.entries)
                        _Group(
                          label: _dateLabel(e.key),
                          subtotal: e.value.fold<double>(
                            0,
                            (s, x) => s + _amountOf(x),
                          ),
                          children: [
                            for (var i = 0; i < e.value.length; i++) ...[
                              _ExpenseRow(
                                item: e.value[i],
                                onOpen: () => _open(e.value[i]),
                                onDelete: () {
                                  final id = e.value[i].id;
                                  if (id == null) {
                                    AppSnackBar.showError(
                                      context,
                                      'Error: Expense ID is null! ❌',
                                    );
                                  } else {
                                    _deleteExpense(id);
                                  }
                                },
                              ),
                              if (i != e.value.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: 70,
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
                            'Long-press a record to delete',
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
        floatingActionButton: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.hot, _C.hotB]),
            shape: BoxShape.circle,
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
            child: InkResponse(
              containedInkWell: true,
              highlightShape: BoxShape.circle,
              onTap: _create,
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
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
    const items = <(_Filter, String, IconData)>[
      (_Filter.all, 'All', Icons.apps_rounded),
      (_Filter.cash, 'Cash', Icons.payments_outlined),
      (_Filter.other, 'Card / Other', Icons.credit_card_rounded),
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
                  Icon(it.$3, size: 15, color: sel ? Colors.white : _C.muted),
                  const SizedBox(width: 6),
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

class _Hero extends StatelessWidget {
  final double total;
  final int records;
  final bool filtering;
  final bool showSummary;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  const _Hero({
    required this.total,
    required this.records,
    required this.filtering,
    required this.showSummary,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: Text(
                          'Expenses',
                          style: _t(
                            21,
                            FontWeight.w800,
                            Colors.white,
                            spacing: -0.3,
                          ),
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
                  if (showSummary) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filtering
                                      ? 'Filtered total'
                                      : 'Total expenses',
                                  style: _t(
                                    12.5,
                                    FontWeight.w600,
                                    Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TweenAnimationBuilder<double>(
                                  key: ValueKey(total),
                                  tween: Tween(begin: 0, end: total),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, __) => FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _money(v),
                                      style: _t(
                                        38,
                                        FontWeight.w800,
                                        Colors.white,
                                        height: 1.05,
                                        spacing: -1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$records',
                                  style: _t(
                                    20,
                                    FontWeight.w800,
                                    Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'Records',
                                  style: _t(
                                    10.5,
                                    FontWeight.w600,
                                    Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            hintText: 'Search type, reference or payment',
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
// Date group + row
// ─────────────────────────────────────────────────────────────
class _Group extends StatelessWidget {
  final String label;
  final double subtotal;
  final List<Widget> children;
  const _Group({
    required this.label,
    required this.subtotal,
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
              Expanded(
                child: Text(label, style: _t(13.5, FontWeight.w800, _C.muted)),
              ),
              Text(_money(subtotal), style: _t(13, FontWeight.w800, _C.ink)),
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

class _ExpenseRow extends StatelessWidget {
  final Expense item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  const _ExpenseRow({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasType = item.expenseType != null && item.expenseType!.isNotEmpty;
    final cash = _isCash(item);
    final color = cash ? _C.brand : _C.card;
    final amount = item.amount?.toString() ?? '0.00';

    return InkWell(
      onTap: onOpen,
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                cash ? Icons.payments_outlined : Icons.credit_card_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasType ? item.expenseType! : 'Expense',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(14.5, FontWeight.w800, _C.ink),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          item.paymentMethod ?? 'Cash',
                          style: _t(10.5, FontWeight.w800, color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ref: ${item.referenceNo ?? 'N/A'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(11.5, FontWeight.w500, _C.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('\$$amount', style: _t(16, FontWeight.w800, _C.ink)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _C.muted),
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
                    decoration: BoxDecoration(
                      color: _C.line,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(110, 14),
                        const SizedBox(height: 8),
                        _bar(150, 11),
                      ],
                    ),
                  ),
                  _bar(50, 16),
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

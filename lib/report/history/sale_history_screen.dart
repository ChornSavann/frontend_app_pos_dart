import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/api/api_order.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/report/history/view_order_screen.dart';

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
  static const pending = Color(0xFFC2570C);
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

String _money(double v) => '\$${v.toStringAsFixed(2)}';

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

enum _Filter { all, completed, other }


class _Order {
  final dynamic id;
  final String number;
  final double amount;
  final int items;
  final String status;
  final String rawDate;

  const _Order(
    this.id,
    this.number,
    this.amount,
    this.items,
    this.status,
    this.rawDate,
  );

  factory _Order.from(dynamic o) {
    final details = o['details'];
    return _Order(
      o['id'],
      '${o['order_number'] ?? o['invoice_number'] ?? 'INV-N/A'}',
      double.tryParse('${o['total_amount'] ?? o['total'] ?? 0}') ?? 0.0,
      details is List ? details.length : 0,
      '${o['status'] ?? 'Completed'}',
      '${o['created_at'] ?? o['date'] ?? ''}',
    );
  }

  bool get completed {
    final s = status.toLowerCase();
    return s == 'completed' || s == 'paid';
  }

  // យកថ្ងៃខែឆ្នាំសម្រាប់ Group តាម Date
  String get dateKey {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) {
      final local = parsed.toLocal(); // បម្លែងជា Local Time
      String two(int n) => n.toString().padLeft(2, '0');
      return '${local.year}-${two(local.month)}-${two(local.day)}';
    }
    return rawDate.trim().replaceFirst('T', ' ').split(' ').first;
  }

  String get time {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      final cleanDate = rawDate.trim().replaceFirst('T', ' ');
      final p = cleanDate.split(' ');
      if (p.length < 2) return '';
      return p[1].length >= 5 ? p[1].substring(0, 5) : p[1];
    }

    final localTime = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(localTime.hour)}:${two(localTime.minute)}';
  }
}


class SaleHistoryScreen extends StatefulWidget {
  const SaleHistoryScreen({super.key});

  @override
  State<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends State<SaleHistoryScreen> {
  final ApiOrder _apiOrder = ApiOrder();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _ordersList = [];

  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final response = await _apiOrder.getAllOrders();
      if (!mounted) return;
      if (response != null && response['success'] == true) {
        setState(() {
          _ordersList = response['data'] ?? [];
          _hasError = false;
        });
      } else {
        setState(() => _hasError = response == null);
      }
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _groupLabel(String key) {
    final dt = DateTime.tryParse(key);
    if (dt == null) return key.isEmpty ? '—' : key;
    final now = DateTime.now();
    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (same(dt, now)) return 'ថ្ងៃនេះ';
    if (same(dt, now.subtract(const Duration(days: 1)))) return 'ម្សិលមិញ';
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final orders = _ordersList.map(_Order.from).toList();
    final completedCount = orders.where((o) => o.completed).length;
    final otherCount = orders.length - completedCount;

    final q = _query.trim().toLowerCase();
    final visible = orders.where((o) {
      final okFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.completed => o.completed,
        _Filter.other => !o.completed,
      };
      if (!okFilter) return false;
      return q.isEmpty || o.number.toLowerCase().contains(q);
    }).toList();

    final total = visible.fold<double>(0, (s, o) => s + o.amount);
    final filtering = _filter != _Filter.all || q.isNotEmpty;

    final groups = <String, List<_Order>>{};
    for (final o in visible) {
      groups.putIfAbsent(o.dateKey, () => []).add(o);
    }

    final hasData = !_isLoading && !_hasError && orders.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _Hero(
              title: TranslateConstants.sales_history.tr,
              loading: _isLoading,
              total: total,
              count: visible.length,
              filtering: filtering,
              showSearch: hasData,
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              onRefresh: _fetchOrders,
            ),
            if (hasData)
              Container(
                height: 56,
                alignment: Alignment.centerLeft,
                child: _FilterBar(
                  selected: _filter,
                  counts: {
                    _Filter.all: orders.length,
                    _Filter.completed: completedCount,
                    _Filter.other: otherCount,
                  },
                  onSelect: (f) {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = f);
                  },
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: _C.brand,
                onRefresh: () => _fetchOrders(silent: true),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
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
                          onAction: _fetchOrders,
                        ),
                      )
                    else if (orders.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _MessageState(
                          icon: Icons.receipt_long_outlined,
                          color: _C.brand,
                          title: 'គ្មានទិន្នន័យប្រវត្តិការលក់ទេ',
                        ),
                      )
                    else if (visible.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _MessageState(
                          icon: Icons.search_off_rounded,
                          color: _C.muted,
                          title: 'រកមិនឃើញការលក់',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            for (final e in groups.entries)
                              _Group(
                                label: _groupLabel(e.key),
                                count: e.value.length,
                                subtotal: e.value.fold<double>(
                                  0,
                                  (s, o) => s + o.amount,
                                ),
                                children: [
                                  for (var i = 0; i < e.value.length; i++) ...[
                                    _OrderRow(
                                      order: e.value[i],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ViewOrderScreen(
                                            orderId: e.value[i].id,
                                          ),
                                        ),
                                      ),
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
                          ]),
                        ),
                      ),
                  ],
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
// Filter chips
// ─────────────────────────────────────────────────────────────
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
      (_Filter.all, 'All', _C.brand),
      (_Filter.completed, 'Completed', _C.brand),
      (_Filter.other, 'Other', _C.pending),
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
// Hero
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final String title;
  final bool loading;
  final double total;
  final int count;
  final bool filtering;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  const _Hero({
    required this.title,
    required this.loading,
    required this.total,
    required this.count,
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
              padding: EdgeInsets.fromLTRB(16, top + 6, 12, 16),
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 10),
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
                                filtering ? 'Filtered total' : 'Total sales',
                                style: _t(
                                  12.5,
                                  FontWeight.w600,
                                  Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              loading
                                  ? Container(
                                      width: 150,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    )
                                  : TweenAnimationBuilder<double>(
                                      key: ValueKey(total),
                                      tween: Tween(begin: 0, end: total),
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder: (_, v, __) => FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _money(v),
                                          style: _t(
                                            34,
                                            FontWeight.w800,
                                            Colors.white,
                                            height: 1.05,
                                            spacing: -0.8,
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
                            vertical: 8,
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
                                '$count',
                                style: _t(
                                  19,
                                  FontWeight.w800,
                                  Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Orders',
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
                  if (showSearch) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        height: 42,
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
                            hintText: 'Search order number',
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
                              vertical: 11,
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
// Date group + order row (compact)
// ─────────────────────────────────────────────────────────────
class _Group extends StatelessWidget {
  final String label;
  final int count;
  final double subtotal;
  final List<Widget> children;
  const _Group({
    required this.label,
    required this.count,
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
              const Spacer(),
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

class _OrderRow extends StatelessWidget {
  final _Order order;
  final VoidCallback onTap;
  const _OrderRow({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = order.completed ? _C.brand : _C.pending;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.point_of_sale_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.number,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(14.5, FontWeight.w800, _C.ink),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 13,
                        color: _C.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${order.items} items',
                        style: _t(12, FontWeight.w600, _C.muted),
                      ),
                      if (order.time.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: _C.muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          order.time,
                          style: _t(11.5, FontWeight.w500, _C.muted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(order.amount),
                  style: _t(15, FontWeight.w800, _C.ink),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: _t(9.5, FontWeight.w800, color, spacing: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 2),
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
            (_) => Padding(
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
                        _bar(120, 14),
                        const SizedBox(height: 8),
                        _bar(90, 11),
                      ],
                    ),
                  ),
                  _bar(50, 15),
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

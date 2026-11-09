import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_purchase.dart';
import 'package:pos_inventory/report/history/purchase_detail_screen.dart';

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
  static const danger = Color(0xFFD32F2F);

  static const avatars = <Color>[
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

String _money(double v) => '\$${v.toStringAsFixed(2)}';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _d(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

// ─────────────────────────────────────────────────────────────
// Parsed purchase
// ─────────────────────────────────────────────────────────────
class _Purchase {
  final dynamic raw;
  final String supplier;
  final String ref;
  final bool hasRef;
  final double amount;
  final int items;
  final String status;
  final String dateKey; // YYYY-MM-DD
  final DateTime? date;

  const _Purchase(
      this.raw,
      this.supplier,
      this.ref,
      this.hasRef,
      this.amount,
      this.items,
      this.status,
      this.dateKey,
      this.date,
      );

  factory _Purchase.from(dynamic p) {
    final ref = '${p['reference_no'] ?? p['purchase_no'] ?? p['purchase_number'] ?? 'PUR-N/A'}';
    final hasRef =
        p['reference_no'] != null || p['purchase_no'] != null || p['purchase_number'] != null;
    final supplierRaw = p['supplier_name'] ?? (p['supplier'] is Map ? p['supplier']['name'] : null);
    final details = p['details'] ?? p['items'];
    final rawDate = '${p['date'] ?? p['created_at'] ?? ''}';
    final parsed = DateTime.tryParse(rawDate);

    String key = '';
    if (parsed != null) {
      key = parsed.toLocal().toString().split(' ').first;
    } else if (rawDate.length >= 10) {
      key = rawDate.substring(0, 10);
    } else {
      key = rawDate;
    }

    return _Purchase(
      p,
      '${supplierRaw ?? ref}',
      ref,
      hasRef,
      double.tryParse('${p['total_amount'] ?? p['total'] ?? 0}') ?? 0.0,
      details is List ? details.length : 0,
      '${p['status'] ?? 'Received'}',
      key,
      parsed,
    );
  }

  bool get done => const ['received', 'completed', 'paid'].contains(status.toLowerCase());
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final ApiPurchase _apiPurchase = ApiPurchase();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _purchasesList = [];

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPurchases({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final response = await _apiPurchase.getAllPurchaseHistory();
      if (!mounted) return;
      setState(() {
        _purchasesList = response ?? [];
        _hasError = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching purchases: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.brand,
            onPrimary: Colors.white,
            onSurface: _C.ink,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    HapticFeedback.selectionClick();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  bool _matches(_Purchase p, String query) {
    final matchesSearch = query.isEmpty ||
        p.ref.toLowerCase().contains(query) ||
        p.supplier.toLowerCase().contains(query);
    if (!matchesSearch) return false;

    final d = p.date;
    if (d != null) {
      if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (d.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (d.isAfter(end)) return false;
      }
    }
    return true;
  }

  String _groupLabel(String key) {
    final dt = DateTime.tryParse(key);
    if (dt == null) return key.isEmpty ? '—' : key;
    final now = DateTime.now();
    bool same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    if (same(dt, now)) return 'ថ្ងៃនេះ';
    if (same(dt, now.subtract(const Duration(days: 1)))) return 'ម្សិលមិញ';
    return _d(dt);
  }

  @override
  Widget build(BuildContext context) {
    final all = _purchasesList.map(_Purchase.from).toList();
    final query = _searchController.text.trim().toLowerCase();
    final visible = all.where((p) => _matches(p, query)).toList();

    final grandTotal = visible.fold<double>(0, (s, p) => s + p.amount);
    final isFiltered = _startDate != null && _endDate != null;
    final filtering = isFiltered || query.isNotEmpty;

    final groups = <String, List<_Purchase>>{};
    for (final p in visible) {
      groups.putIfAbsent(p.dateKey, () => []).add(p);
    }

    final hasData = !_isLoading && !_hasError && all.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            // 📌 Sticky header: stays on screen, only the list scrolls
            _Hero(
              loading: _isLoading,
              total: grandTotal,
              count: visible.length,
              filtering: filtering,
              showSearch: hasData,
              controller: _searchController,
              isFiltered: isFiltered,
              rangeText: isFiltered ? '${_d(_startDate!)} – ${_d(_endDate!)}' : '',
              onPickRange: _selectDateRange,
              onClearRange: _clearDateFilter,
              onClearSearch: () => _searchController.clear(),
              onRefresh: _fetchPurchases,
            ),
            Expanded(
              child: RefreshIndicator(
                color: _C.brand,
                onRefresh: () => _fetchPurchases(silent: true),
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
                          onAction: _fetchPurchases,
                        ),
                      )
                    else if (all.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _MessageState(
                            icon: Icons.local_shipping_outlined,
                            color: _C.brand,
                            title: 'រកមិនឃើញទិន្នន័យប្រវត្តិការទិញចូលទេ',
                          ),
                        )
                      else if (visible.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _MessageState(
                              icon: Icons.search_off_rounded,
                              color: _C.muted,
                              title: 'រកមិនឃើញទិន្នន័យតាមការស្វែងរក',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                for (final e in groups.entries)
                                  _Group(
                                    label: _groupLabel(e.key),
                                    count: e.value.length,
                                    subtotal: e.value.fold<double>(0, (s, p) => s + p.amount),
                                    children: [
                                      for (var i = 0; i < e.value.length; i++) ...[
                                        _PurchaseRow(
                                          purchase: e.value[i],
                                          color: _C.avatars[
                                          e.value[i].supplier.hashCode.abs() % _C.avatars.length],
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PurchaseDetailScreen(
                                                purchase: e.value[i].raw,
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
// Hero (sticky)
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final bool loading;
  final double total;
  final int count;
  final bool filtering;
  final bool showSearch;
  final TextEditingController controller;
  final bool isFiltered;
  final String rangeText;
  final VoidCallback onPickRange;
  final VoidCallback onClearRange;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;

  const _Hero({
    required this.loading,
    required this.total,
    required this.count,
    required this.filtering,
    required this.showSearch,
    required this.controller,
    required this.isFiltered,
    required this.rangeText,
    required this.onPickRange,
    required this.onClearRange,
    required this.onClearSearch,
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
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('ប្រវត្តិការទិញចូល',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(21, FontWeight.w800, Colors.white, spacing: -0.3)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: 'Refresh',
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 21),
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
                              Text(filtering ? 'សរុបតាមតម្រង' : 'សរុបទឹកប្រាក់ទិញចូល',
                                  style: _t(12.5, FontWeight.w600,
                                      Colors.white.withValues(alpha: 0.85))),
                              const SizedBox(height: 4),
                              loading
                                  ? Container(
                                width: 150,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              )
                                  : TweenAnimationBuilder<double>(
                                key: ValueKey(total),
                                tween: Tween(begin: 0, end: total),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(_money(v),
                                      style: _t(34, FontWeight.w800, Colors.white,
                                          height: 1.05, spacing: -0.8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Column(
                            children: [
                              Text('$count',
                                  style: _t(19, FontWeight.w800, Colors.white, height: 1.1)),
                              Text('វិក្កយបត្រ',
                                  style: _t(10.5, FontWeight.w600,
                                      Colors.white.withValues(alpha: 0.85))),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextField(
                                controller: controller,
                                cursorColor: _C.brand,
                                style: _t(14, FontWeight.w500, _C.ink),
                                decoration: InputDecoration(
                                  hintText: 'ស្វែងរកតាម Supplier ឬ Ref No',
                                  hintStyle: _t(13.5, FontWeight.w400, _C.muted),
                                  prefixIcon:
                                  const Icon(Icons.search_rounded, color: _C.muted),
                                  suffixIcon: controller.text.isEmpty
                                      ? null
                                      : IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 20, color: _C.muted),
                                    onPressed: onClearSearch,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: isFiltered ? Colors.white : Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: onPickRange,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isFiltered
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  size: 21,
                                  color: isFiltered ? _C.brand : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFiltered) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded, size: 15, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(rangeText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _t(12.5, FontWeight.w800, Colors.white)),
                              ),
                              InkWell(
                                onTap: onClearRange,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.close_rounded,
                                          size: 14, color: Colors.white),
                                      const SizedBox(width: 3),
                                      Text('លុបតម្រង',
                                          style: _t(11.5, FontWeight.w800, Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
// Date group + purchase row (compact)
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
                child: Text('$count', style: _t(10.5, FontWeight.w800, _C.muted)),
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

class _PurchaseRow extends StatelessWidget {
  final _Purchase purchase;
  final Color color;
  final VoidCallback onTap;
  const _PurchaseRow({required this.purchase, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = purchase;
    final statusColor = p.done ? _C.brand : _C.pending;
    final name = p.supplier.trim();
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.85), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(initial, style: _t(19, FontWeight.w800, Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.supplier,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(14.5, FontWeight.w800, _C.ink)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (p.hasRef) ...[
                        Flexible(
                          child: Text(p.ref,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(11.5, FontWeight.w600, _C.muted)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.inventory_2_outlined, size: 12, color: _C.muted),
                      const SizedBox(width: 3),
                      Text('${p.items} items', style: _t(11.5, FontWeight.w500, _C.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_money(p.amount), style: _t(15, FontWeight.w800, _C.ink)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(p.status.toUpperCase(),
                      style: _t(9.5, FontWeight.w800, statusColor, spacing: 0.3)),
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: List.generate(
            5,
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
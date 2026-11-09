import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/report/api_report.dart';
import 'package:pos_inventory/report/purchase_history_screen.dart';

class _C {
  static const bg = Color(0xFFF0F4F4);
  static const ink = Color(0xFF0F1F1D);
  static const muted = Color(0xFF5E7476);
  static const line = Color(0xFFE3EBEA);
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
  static const pending = Color(0xFFC2570C);
  static const hot = Color(0xFFEF5B16);
  static const blue = Color(0xFF3B6FD4);
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

enum _Filter { all, received, pending }

double _totalOf(Map<String, dynamic> po) =>
    double.tryParse('${po['total'] ?? 0}') ?? 0.0;
String _statusOf(Map<String, dynamic> po) =>
    '${po['status'] ?? ''}'.toLowerCase();

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  final ApiReport apiReport = ApiReport();
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = true;
  bool hasError = false;

  List<Map<String, dynamic>> purchaseOrders = [];
  double totalExpense = 0.0;
  int totalImports = 0;
  double totalPendingPayment = 0.0;

  _Filter _filter = _Filter.all;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPurchaseData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPurchaseData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }
    try {
      final data = await apiReport.fetchPurchaseReport();

      var expense = 0.0;
      var pending = 0.0;
      for (final po in data) {
        final total = _totalOf(po);
        expense += total;
        if (_statusOf(po) == 'pending') pending += total;
      }

      if (!mounted) return;
      setState(() {
        purchaseOrders = data;
        totalExpense = expense;
        totalImports = data.length;
        totalPendingPayment = pending;
        hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading purchase report: $e');
      if (mounted) setState(() => hasError = true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _open(Map<String, dynamic> po) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseHistoryScreen(
          purchaseId: po['id'],
          referenceNo: '${po['reference_no']}',
          supplierName: '${po['supplier_name']}',
          supplierPhone: po['supplier_phone']?.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.trim().toLowerCase();
    final receivedCount = purchaseOrders
        .where((p) => _statusOf(p) == 'received')
        .length;
    final pendingCount = purchaseOrders
        .where((p) => _statusOf(p) == 'pending')
        .length;

    final filteredOrders = purchaseOrders.where((po) {
      final s = _statusOf(po);
      final okFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.received => s == 'received',
        _Filter.pending => s == 'pending',
      };
      if (!okFilter) return false;
      if (q.isEmpty) return true;
      final refNo = '${po['reference_no']}'.toLowerCase();
      final supplier = '${po['supplier_name']}'.toLowerCase();
      return refNo.contains(q) || supplier.contains(q);
    }).toList();

    final hasData = !isLoading && !hasError && purchaseOrders.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadPurchaseData(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  loading: isLoading,
                  total: totalExpense,
                  imports: totalImports,
                  pending: totalPendingPayment,
                  received: receivedCount,
                  showSearch: hasData,
                  controller: _searchController,
                  onChanged: (v) => setState(() => searchQuery = v),
                  onClear: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                  onRefresh: _loadPurchaseData,
                ),
              ),
              if (hasData)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedBar(
                    child: _FilterBar(
                      selected: _filter,
                      counts: {
                        _Filter.all: purchaseOrders.length,
                        _Filter.received: receivedCount,
                        _Filter.pending: pendingCount,
                      },
                      onSelect: (f) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f);
                      },
                    ),
                  ),
                ),
              if (isLoading)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverToBoxAdapter(child: _SkeletonList()),
                )
              else if (hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.cloud_off_rounded,
                    color: _C.muted,
                    title: 'Could not load purchase history',
                    actionLabel: 'Try again',
                    onAction: _loadPurchaseData,
                  ),
                )
              else if (purchaseOrders.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.local_shipping_outlined,
                    color: _C.brand,
                    title: 'No purchase orders yet',
                    subtitle: 'Supplier purchases will appear here.',
                  ),
                )
              else if (filteredOrders.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.search_off_rounded,
                    color: _C.muted,
                    title: 'No matching purchase history found',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  sliver: SliverList.separated(
                    itemCount: filteredOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _FadeSlide(
                      index: i,
                      child: _PurchaseCard(
                        po: filteredOrders[i],
                        onTap: () => _open(filteredOrders[i]),
                      ),
                    ),
                  ),
                ),
            ],
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
      (_Filter.all, 'All', _C.brand),
      (_Filter.received, 'Received', _C.brand),
      (_Filter.pending, 'Pending', _C.pending),
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


class _Hero extends StatelessWidget {
  final bool loading;
  final double total;
  final int imports;
  final double pending;
  final int received;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  const _Hero({
    required this.loading,
    required this.total,
    required this.imports,
    required this.pending,
    required this.received,
    required this.showSearch,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onRefresh,
  });

  Widget _stat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(
                    11,
                    FontWeight.w600,
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: _t(16, FontWeight.w800, Colors.white)),
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
                          'Purchase History',
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
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Total supplier expenses',
                              style: _t(
                                12.5,
                                FontWeight.w600,
                                Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF7CFFB2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Live',
                                    style: _t(
                                      10.5,
                                      FontWeight.w800,
                                      Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        loading
                            ? Container(
                                width: 170,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              )
                            : TweenAnimationBuilder<double>(
                                key: ValueKey(total),
                                tween: Tween(begin: 0, end: total),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _money(v),
                                    style: _t(
                                      40,
                                      FontWeight.w800,
                                      Colors.white,
                                      height: 1.05,
                                      spacing: -1,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              _stat(
                                Icons.local_shipping_outlined,
                                'Imports',
                                '$imports shipments',
                              ),
                              _stat(
                                Icons.check_circle_outline_rounded,
                                'Received',
                                '$received',
                              ),
                              _stat(
                                Icons.schedule_rounded,
                                'Pending',
                                _money(pending),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                            hintText: 'Search by PO No. or Supplier Name',
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

class _PurchaseCard extends StatelessWidget {
  final Map<String, dynamic> po;
  final VoidCallback onTap;
  const _PurchaseCard({required this.po, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(po);
    final isReceived = status == 'received';
    final isPending = status == 'pending';
    final color = isReceived ? _C.brand : (isPending ? _C.pending : _C.blue);
    final supplier = '${po['supplier_name'] ?? ''}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
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
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                    Icons.shopping_cart_checkout_rounded,
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
                        '${po['reference_no']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(15, FontWeight.w800, _C.ink),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 13,
                            color: _C.muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              supplier,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(12, FontWeight.w600, _C.muted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            size: 13,
                            color: _C.muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${po['date'] ?? ''}',
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
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(_totalOf(po)),
                      style: _t(15.5, FontWeight.w800, _C.ink),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isReceived
                                ? Icons.check_circle_rounded
                                : Icons.access_time_rounded,
                            size: 12,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${po['status']}'.toUpperCase(),
                            style: _t(10, FontWeight.w800, color),
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
          (_) => Container(
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
                      _bar(110, 14),
                      const SizedBox(height: 8),
                      _bar(150, 11),
                    ],
                  ),
                ),
                _bar(55, 15),
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

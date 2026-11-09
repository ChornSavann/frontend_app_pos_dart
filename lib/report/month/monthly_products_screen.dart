import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/report/api_report.dart';

class _C {
  static const bg = Color(0xFFF0F4F4);
  static const ink = Color(0xFF0F1F1D);
  static const muted = Color(0xFF5E7476);
  static const line = Color(0xFFE3EBEA);
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
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

class _Row {
  final String name;
  final int qty;
  final double price;
  final double total;
  final String? image;
  const _Row(this.name, this.qty, this.price, this.total, this.image);
}

class MonthlyProductsScreen extends StatefulWidget {
  final int year;
  final int month;
  final String monthName;

  const MonthlyProductsScreen({
    super.key,
    required this.year,
    required this.month,
    required this.monthName,
  });

  @override
  State<MonthlyProductsScreen> createState() => _MonthlyProductsScreenState();
}

class _MonthlyProductsScreenState extends State<MonthlyProductsScreen> {
  final ApiReport _apiReport = ApiReport();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _soldProducts = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadMonthlyProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyProducts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final products = await _apiReport.fetchProductsByMonth(
        year: widget.year,
        month: widget.month,
      );
      if (!mounted) return;
      setState(() {
        _soldProducts = products;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading monthly products: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_Row> get _rows {
    final list = _soldProducts.map((p) {
      final img = p['image']?.toString();
      return _Row(
        '${p['name'] ?? ''}',
        int.tryParse('${p['qty']}') ??
            (double.tryParse('${p['qty']}')?.toInt() ?? 0),
        double.tryParse('${p['price']}') ?? 0.0,
        double.tryParse('${p['total']}') ?? 0.0,
        (img == null || img.isEmpty || img == 'null') ? null : img,
      );
    }).toList();
    // best revenue first, so the ranking makes sense
    list.sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final all = _rows;
    final totalRevenue = all.fold<double>(0, (s, e) => s + e.total);
    final totalQty = all.fold<int>(0, (s, e) => s + e.qty);
    final maxTotal = all.isEmpty
        ? 1.0
        : (all.first.total <= 0 ? 1.0 : all.first.total);

    final q = _query.trim().toLowerCase();
    // keep the original rank even while searching
    final visible = <(int, _Row)>[
      for (var i = 0; i < all.length; i++)
        if (q.isEmpty || all[i].name.toLowerCase().contains(q)) (i + 1, all[i]),
    ];

    final hasData = !_isLoading && !_hasError && all.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadMonthlyProducts(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  monthName: widget.monthName,
                  year: widget.year,
                  loading: _isLoading,
                  revenue: totalRevenue,
                  products: all.length,
                  qty: totalQty,
                  topName: all.isEmpty ? '—' : all.first.name,
                  showSearch: hasData,
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
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
                    onAction: _loadMonthlyProducts,
                  ),
                )
              else if (all.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.inventory_2_outlined,
                    color: _C.brand,
                    title: 'មិនមានទិន្នន័យផលិតផលក្នុងខែនេះទេ',
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          size: 18,
                          color: _C.brand,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'បញ្ជីផលិតផលដែលបានលក់',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(16, FontWeight.w800, _C.ink),
                          ),
                        ),
                        Text(
                          'សរុបលក់: $totalQty ដង',
                          style: _t(11.5, FontWeight.w700, _C.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.search_off_rounded,
                      color: _C.muted,
                      title: 'រកមិនឃើញផលិតផល',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverToBoxAdapter(
                      child: _FadeSlide(
                        index: 0,
                        child: _ListCard(
                          children: [
                            for (var i = 0; i < visible.length; i++)
                              _ProductRow(
                                rank: visible[i].$1,
                                row: visible[i].$2,
                                share: totalRevenue > 0
                                    ? visible[i].$2.total / totalRevenue
                                    : 0,
                                barFactor: visible[i].$2.total / maxTotal,
                                last: i == visible.length - 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
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

class _Hero extends StatelessWidget {
  final String monthName;
  final int year;
  final bool loading;
  final double revenue;
  final int products;
  final int qty;
  final String topName;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _Hero({
    required this.monthName,
    required this.year,
    required this.loading,
    required this.revenue,
    required this.products,
    required this.qty,
    required this.topName,
    required this.showSearch,
    required this.controller,
    required this.onChanged,
    required this.onClear,
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
                    10.5,
                    FontWeight.w600,
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _t(15, FontWeight.w800, Colors.white),
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
              padding: EdgeInsets.fromLTRB(16, top + 4, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                              'ផលិតផលខែ $monthName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(
                                21,
                                FontWeight.w800,
                                Colors.white,
                                spacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$year',
                                  style: _t(
                                    12.5,
                                    FontWeight.w600,
                                    Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ចំណូលសរុប',
                          style: _t(
                            12.5,
                            FontWeight.w600,
                            Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        loading
                            ? Container(
                                width: 170,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              )
                            : TweenAnimationBuilder<double>(
                                key: ValueKey(revenue),
                                tween: Tween(begin: 0, end: revenue),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _money(v),
                                    style: _t(
                                      32,
                                      FontWeight.w800,
                                      Colors.white,
                                      height: 1.05,
                                      spacing: -0.8,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
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
                                Icons.category_outlined,
                                'មុខទំនិញ',
                                '$products',
                              ),
                              _stat(
                                Icons.shopping_bag_outlined,
                                'លក់សរុប',
                                '$qty ដង',
                              ),
                              _stat(
                                Icons.emoji_events_outlined,
                                'លក់ដាច់បំផុត',
                                topName,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showSearch) ...[
                    const SizedBox(height: 10),
                    Container(
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
                          hintText: 'ស្វែងរកផលិតផល',
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

class _ListCard extends StatelessWidget {
  final List<Widget> children;
  const _ListCard({required this.children});

  @override
  Widget build(BuildContext context) {
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
        child: Column(children: children),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final int rank;
  final _Row row;
  final double share; // of month revenue
  final double barFactor; // relative to best product
  final bool last;

  const _ProductRow({
    required this.rank,
    required this.row,
    required this.share,
    required this.barFactor,
    required this.last,
  });

  List<Color>? get _medal => switch (rank) {
    1 => const [Color(0xFFFFD34D), Color(0xFFF59E0B)],
    2 => const [Color(0xFFCBD5DC), Color(0xFF94A3B0)],
    3 => const [Color(0xFFE0A370), Color(0xFFB9743A)],
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final medal = _medal;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 0),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: medal == null
                      ? null
                      : LinearGradient(
                          colors: medal,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: medal == null ? _C.bg : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$rank',
                  style: _t(
                    12,
                    FontWeight.w800,
                    medal == null ? _C.muted : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _C.line),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: row.image != null
                      ? Image.network(
                          row.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _ImageFallback(),
                        )
                      : const _ImageFallback(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(14, FontWeight.w800, _C.ink),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: _t(11.5, FontWeight.w500, _C.muted),
                        children: [
                          TextSpan(
                            text: 'qty ${row.qty}',
                            style: _t(11.5, FontWeight.w800, _C.brand),
                          ),
                          TextSpan(text: '  ·  ${_money(row.price)} / ឯកតា'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(row.total),
                    style: _t(14.5, FontWeight.w800, _C.ink),
                  ),
                  Text(
                    '${(share * 100).toStringAsFixed(1)}%',
                    style: _t(10.5, FontWeight.w700, _C.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        // thin share bar
        Padding(
          padding: const EdgeInsets.fromLTRB(60, 8, 14, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 4, color: _C.line),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: barFactor.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: medal ?? const [_C.heroB, _C.brand],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!last)
          const Divider(height: 1, indent: 12, endIndent: 12, color: _C.line),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(Icons.inventory_2_outlined, color: _C.brand, size: 24),
  );
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _C.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _C.line,
                    borderRadius: BorderRadius.circular(16),
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

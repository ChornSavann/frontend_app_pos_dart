import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/report/api_report.dart';
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';

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

  static const chart = <Color>[
    Color(0xFF0F766E),
    Color(0xFF3B6FD4),
    Color(0xFF7C4DCC),
    Color(0xFFD6457A),
    Color(0xFFF59E0B),
  ];
  static const others = Color(0xFFB8C4C6);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

String _money(double v) => '\$${v.toStringAsFixed(2)}';

// ─────────────────────────────────────────────────────────────
// Parsed row
// ─────────────────────────────────────────────────────────────
class _Item {
  final String name;
  final int qty;
  final double revenue;
  final String? imageUrl;
  const _Item(this.name, this.qty, this.revenue, this.imageUrl);
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class TopSellingScreen extends StatefulWidget {
  const TopSellingScreen({super.key});

  @override
  State<TopSellingScreen> createState() => _TopSellingScreenState();
}

class _TopSellingScreenState extends State<TopSellingScreen>
    with SingleTickerProviderStateMixin {
  final ApiReport apiReport = ApiReport();

  bool isLoading = true;
  bool hasError = false;
  List<Map<String, dynamic>> topProducts = [];
  int _touched = -1;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _loadTopSellingData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTopSellingData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }
    try {
      final fetchedData = await apiReport.fetchTopSellingProducts();
      debugPrint('📦 FETCHED PRODUCTS DATA: $fetchedData');
      if (!mounted) return;
      setState(() {
        topProducts = fetchedData;
        hasError = false;
        _touched = -1;
      });
      _animationController
        ..reset()
        ..forward();
    } catch (e) {
      debugPrint('Error loading top selling screen: $e');
      if (mounted) setState(() => hasError = true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Build a full image URL (same logic as before)
  String? _buildImageUrl(dynamic rawImage) {
    if (rawImage == null || rawImage.toString().trim().isEmpty) return null;
    final imageStr = rawImage.toString();
    if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      return imageStr;
    }
    final cleanPath = imageStr.startsWith('/') ? imageStr.substring(1) : imageStr;
    var base = BaseUrlApi.baseimageUrl;
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'http://$base';
    }
    return '$base/$cleanPath';
  }

  List<_Item> get _items => topProducts.map((p) {
    return _Item(
      '${p['name'] ?? 'Unknown'}',
      int.tryParse('${p['sold_qty'] ?? 0}') ?? (double.tryParse('${p['sold_qty']}')?.toInt() ?? 0),
      double.tryParse('${p['revenue'] ?? 0}') ?? 0.0,
      _buildImageUrl(p['image_url']),
    );
  }).toList();

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final totalQty = items.fold<int>(0, (s, e) => s + e.qty);
    final totalRevenue = items.fold<double>(0, (s, e) => s + e.revenue);
    final maxQty = items.isEmpty ? 1 : items.map((e) => e.qty).reduce((a, b) => a > b ? a : b);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadTopSellingData(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  loading: isLoading,
                  units: totalQty,
                  revenue: totalRevenue,
                  products: items.length,
                  onRefresh: _loadTopSellingData,
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
                    title: 'Could not load top-selling products',
                    actionLabel: 'Try again',
                    onAction: _loadTopSellingData,
                  ),
                )
              else if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.trending_up_rounded,
                      color: _C.brand,
                      title: 'No top-selling products found',
                      subtitle: 'Products will appear here after your first sales.',
                    ),
                  )
                else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, _) {
                            final v = Curves.easeOutCubic.transform(_animationController.value);
                            return Opacity(
                              opacity: v,
                              child: Transform.translate(
                                offset: Offset(0, (1 - v) * 20),
                                child: _DistributionCard(
                                  items: items,
                                  totalQty: totalQty,
                                  touched: _touched,
                                  progress: v,
                                  onTouch: (i) {
                                    if (i != _touched) {
                                      if (i >= 0) HapticFeedback.selectionClick();
                                      setState(() => _touched = i);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events_outlined, size: 18, color: _C.brand),
                            const SizedBox(width: 8),
                            Text('Best performers', style: _t(16, FontWeight.w800, _C.ink)),
                            const Spacer(),
                            Text('${items.length} products',
                                style: _t(12, FontWeight.w700, _C.muted)),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _FadeSlide(
                          index: i,
                          child: _ProductCard(
                            rank: i + 1,
                            item: items[i],
                            maxQty: maxQty,
                            highlighted: _touched == i,
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
  final bool loading;
  final int units;
  final double revenue;
  final int products;
  final VoidCallback onRefresh;

  const _Hero({
    required this.loading,
    required this.units,
    required this.revenue,
    required this.products,
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
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(11, FontWeight.w600, Colors.white.withValues(alpha: 0.8))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: _t(17, FontWeight.w800, Colors.white)),
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
              padding: EdgeInsets.fromLTRB(16, top + 6, 12, 20),
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
                            Text('Top-Selling Products',
                                style: _t(21, FontWeight.w800, Colors.white, spacing: -0.3)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.trending_up_rounded,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 5),
                                Text('Sales distribution & best performers',
                                    style: _t(12.5, FontWeight.w500,
                                        Colors.white.withValues(alpha: 0.88))),
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
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 21),
                          onPressed: onRefresh,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      child: loading
                          ? Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                          : Row(
                        children: [
                          _stat(Icons.inventory_2_outlined, 'Units sold', '$units'),
                          _stat(Icons.attach_money_rounded, 'Revenue', _money(revenue)),
                          _stat(Icons.category_outlined, 'Products', '$products'),
                        ],
                      ),
                    ),
                  ),
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
// Distribution card (donut + legend)
// ─────────────────────────────────────────────────────────────
class _DistributionCard extends StatelessWidget {
  final List<_Item> items;
  final int totalQty;
  final int touched;
  final double progress;
  final ValueChanged<int> onTouch;

  const _DistributionCard({
    required this.items,
    required this.totalQty,
    required this.touched,
    required this.progress,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    // top 5 + "Others"
    final shown = items.take(5).toList();
    final othersQty = items.skip(5).fold<int>(0, (s, e) => s + e.qty);

    final slices = <(String, int, Color)>[
      for (var i = 0; i < shown.length; i++)
        (shown[i].name, shown[i].qty, _C.chart[i % _C.chart.length]),
      if (othersQty > 0) ('Others', othersQty, _C.others),
    ];

    final hasTouch = touched >= 0 && touched < slices.length;
    final centerLabel = hasTouch ? slices[touched].$1 : 'TOTAL';
    final centerValue = hasTouch ? '${slices[touched].$2}' : '$totalQty';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _C.heroA.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large_rounded, size: 18, color: _C.brand),
              const SizedBox(width: 8),
              Text('Sales distribution', style: _t(15.5, FontWeight.w800, _C.ink)),
              const Spacer(),
              Text('by units', style: _t(11.5, FontWeight.w600, _C.muted)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 46,
                        startDegreeOffset: -90 + (1 - progress) * 120,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              onTouch(-1);
                              return;
                            }
                            onTouch(response.touchedSection!.touchedSectionIndex);
                          },
                        ),
                        sections: [
                          for (var i = 0; i < slices.length; i++)
                            PieChartSectionData(
                              color: slices[i].$3,
                              value: slices[i].$2.toDouble() * (progress <= 0 ? 0.0001 : progress),
                              title: '',
                              radius: touched == i ? 34 : 28,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            centerLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: _t(hasTouch ? 11 : 10, FontWeight.w800, _C.muted,
                                spacing: hasTouch ? 0 : 0.6),
                          ),
                          const SizedBox(height: 2),
                          Text(centerValue, style: _t(20, FontWeight.w800, _C.ink)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < slices.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i == slices.length - 1 ? 0 : 9),
                        child: _LegendRow(
                          color: slices[i].$3,
                          name: slices[i].$1,
                          qty: slices[i].$2,
                          percent: totalQty > 0 ? slices[i].$2 / totalQty * 100 : 0,
                          active: touched == i,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String name;
  final int qty;
  final double percent;
  final bool active;
  const _LegendRow({
    required this.color,
    required this.name,
    required this.qty,
    required this.percent,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(12, FontWeight.w700, _C.ink)),
          ),
          const SizedBox(width: 4),
          Text('${percent.toStringAsFixed(0)}%',
              style: _t(11.5, FontWeight.w800, _C.muted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Product card
// ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final int rank;
  final _Item item;
  final int maxQty;
  final bool highlighted;

  const _ProductCard({
    required this.rank,
    required this.item,
    required this.maxQty,
    required this.highlighted,
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
    final share = maxQty > 0 ? item.qty / maxQty : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: highlighted ? Border.all(color: _C.brand, width: 1.6) : null,
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // rank
              Container(
                width: 34,
                height: 34,
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
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: medal == null
                      ? null
                      : [
                    BoxShadow(
                      color: medal.last.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: medal != null && rank == 1
                    ? const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18)
                    : Text('$rank',
                    style: _t(14, FontWeight.w800, medal == null ? _C.muted : Colors.white)),
              ),
              const SizedBox(width: 12),
              // image
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.line),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: item.imageUrl != null
                      ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ImageFallback(),
                  )
                      : const _ImageFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(14.5, FontWeight.w800, _C.ink)),
                    const SizedBox(height: 3),
                    Text('${item.qty} units sold', style: _t(12, FontWeight.w500, _C.muted)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(height: 6, color: _C.line),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: share),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => FractionallySizedBox(
                              widthFactor: v.clamp(0.0, 1.0),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: medal ?? const [_C.heroB, _C.brand],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_money(item.revenue), style: _t(15, FontWeight.w800, _C.brand)),
                  const SizedBox(height: 2),
                  Text('Revenue', style: _t(10.5, FontWeight.w600, _C.muted)),
                ],
              ),
            ],
          ),
        ),
      ),
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
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            4,
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
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _C.line,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        _bar(80, 11),
                      ],
                    ),
                  ),
                  _bar(50, 15),
                ],
              ),
            ),
          ),
        ],
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
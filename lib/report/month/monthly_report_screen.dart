import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/report/api_report.dart';
import 'monthly_products_screen.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens (light + dark)
// ─────────────────────────────────────────────────────────────
class _Pal {
  final bool dark;
  const _Pal(this.dark);

  Color get bg => dark ? const Color(0xFF0B1120) : const Color(0xFFF0F4F4);
  Color get surface => dark ? const Color(0xFF151C2E) : Colors.white;
  Color get ink => dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1F1D);
  Color get muted => dark ? const Color(0xFF94A3B8) : const Color(0xFF5E7476);
  Color get line => dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3EBEA);
  Color get chip => dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F4F4);
  Color get shadow =>
      dark ? Colors.black.withValues(alpha: 0.30) : const Color(0xFF063B37).withValues(alpha: 0.07);
  Color get accent => dark ? const Color(0xFF3FD0BF) : _K.brand;
}

class _K {
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
  static const hot = Color(0xFFEF5B16);
  static const hotB = Color(0xFFFF8A3D);

  static const monthColors = <Color>[
    Color(0xFF4F46E5),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
    Color(0xFFF97316),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFE11D48),
  ];
}

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

String _money(double v) => '\$${v.toStringAsFixed(2)}';

const _short = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

Color _monthColor(int m) => (m >= 1 && m <= 12) ? _K.monthColors[m - 1] : _K.monthColors[0];

double _num(dynamic v) => double.tryParse('${v ?? 0}') ?? 0.0;

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final ApiReport _apiMonthlyReport = ApiReport();

  List<Map<String, dynamic>> _monthlyData = [];
  bool _isLoading = true;
  bool _hasError = false;
  late int _selectedYear = DateTime.now().year;
  int? _selectedMonth; // tapped bar

  _Pal get _p => _Pal(Theme.of(context).brightness == Brightness.dark);

  List<int> get _years {
    final y = DateTime.now().year;
    return [for (var i = 0; i < 5; i++) y - i];
  }

  @override
  void initState() {
    super.initState();
    _loadData(_selectedYear);
  }

  Future<void> _loadData(int year, {bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _selectedMonth = null;
      });
    }
    try {
      final data = await _apiMonthlyReport.fetchMonthlyReport(year: year);
      if (!mounted) return;
      setState(() {
        _monthlyData = data;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading monthly report: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _monthOf(Map<String, dynamic> item, int index) =>
      int.tryParse('${item['month'] ?? (index + 1)}') ?? (index + 1);

  @override
  Widget build(BuildContext context) {
    final p = _p;

    final totalRevenue = _monthlyData.fold<double>(0, (s, e) => s + _num(e['revenue']));
    final totalOrders = _monthlyData.fold<double>(0, (s, e) => s + _num(e['orders'])).toInt();
    final avgMonthly = _monthlyData.isEmpty ? 0.0 : totalRevenue / _monthlyData.length;

    // revenue per month 1..12
    final byMonth = List<double>.filled(12, 0);
    for (var i = 0; i < _monthlyData.length; i++) {
      final m = _monthOf(_monthlyData[i], i);
      if (m >= 1 && m <= 12) byMonth[m - 1] += _num(_monthlyData[i]['revenue']);
    }
    var bestIdx = 0;
    for (var i = 1; i < 12; i++) {
      if (byMonth[i] > byMonth[bestIdx]) bestIdx = i;
    }
    final hasRevenue = totalRevenue > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.bg,
        body: RefreshIndicator(
          color: _K.brand,
          edgeOffset: 120,
          onRefresh: () => _loadData(_selectedYear, silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  year: _selectedYear,
                  years: _years,
                  loading: _isLoading,
                  revenue: totalRevenue,
                  orders: totalOrders,
                  average: avgMonthly,
                  bestMonth: hasRevenue ? _short[bestIdx] : '—',
                  onYear: (y) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedYear = y);
                    _loadData(y);
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
                    pal: p,
                    icon: Icons.cloud_off_rounded,
                    color: p.muted,
                    title: 'មិនអាចទាញយកទិន្នន័យបានទេ',
                    actionLabel: 'សាកល្បងម្តងទៀត',
                    onAction: () => _loadData(_selectedYear),
                  ),
                )
              else if (_monthlyData.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      pal: p,
                      icon: Icons.bar_chart_rounded,
                      color: p.accent,
                      title: 'មិនមានទិន្នន័យសម្រាប់ឆ្នាំនេះទេ',
                      subtitle: 'សាកល្បងជ្រើសរើសឆ្នាំផ្សេង',
                    ),
                  )
                else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ChartCard(
                          pal: p,
                          year: _selectedYear,
                          byMonth: byMonth,
                          bestIdx: bestIdx,
                          selected: _selectedMonth,
                          total: totalRevenue,
                          onSelect: (m) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedMonth = _selectedMonth == m ? null : m);
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Icon(Icons.calendar_view_month_rounded, size: 18, color: p.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('ព័ត៌មានលម្អិតតាមខែ',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(16, FontWeight.w800, p.ink)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.chip,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_monthlyData.length} ខែមានទិន្នន័យ',
                                  style: _t(11, FontWeight.w800, p.muted)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: _monthlyData.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = _monthlyData[i];
                          final m = _monthOf(item, i);
                          final rev = _num(item['revenue']);
                          return _FadeSlide(
                            index: i,
                            child: _MonthCard(
                              pal: p,
                              month: m,
                              name: '${item['name'] ?? (m >= 1 && m <= 12 ? _short[m - 1] : '')}',
                              orders: _num(item['orders']).toInt(),
                              revenue: rev,
                              share: totalRevenue == 0 ? 0 : rev / totalRevenue,
                              isBest: hasRevenue && m - 1 == bestIdx,
                              highlighted: _selectedMonth == m,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MonthlyProductsScreen(
                                    year: _selectedYear,
                                    month: m,
                                    monthName: '${item['name'] ?? ''}',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
  final int year;
  final List<int> years;
  final bool loading;
  final double revenue;
  final int orders;
  final double average;
  final String bestMonth;
  final ValueChanged<int> onYear;

  const _Hero({
    required this.year,
    required this.years,
    required this.loading,
    required this.revenue,
    required this.orders,
    required this.average,
    required this.bestMonth,
    required this.onYear,
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
                    style: _t(10.5, FontWeight.w600, Colors.white.withValues(alpha: 0.8))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: _t(15.5, FontWeight.w800, Colors.white)),
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
            colors: [_K.heroA, _K.heroB],
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
              padding: EdgeInsets.fromLTRB(16, top + 6, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('របាយការណ៍ប្រចាំខែ',
                            style: _t(21, FontWeight.w800, Colors.white, spacing: -0.3)),
                      ),
                      PopupMenuButton<int>(
                        tooltip: 'Year',
                        color: Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: onYear,
                        itemBuilder: (_) => [
                          for (final y in years)
                            PopupMenuItem(
                              value: y,
                              child: Row(
                                children: [
                                  Text('$y',
                                      style: _t(14, FontWeight.w800,
                                          y == year ? _K.brand : const Color(0xFF0F1F1D))),
                                  if (y == year) ...[
                                    const Spacer(),
                                    const Icon(Icons.check_rounded, size: 18, color: _K.brand),
                                  ],
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 7),
                              Text('$year', style: _t(13.5, FontWeight.w800, Colors.white)),
                              const SizedBox(width: 3),
                              const Icon(Icons.expand_more_rounded,
                                  size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ប្រាក់ចំណូលសរុបឆ្នាំ $year',
                            style: _t(12.5, FontWeight.w600,
                                Colors.white.withValues(alpha: 0.85))),
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
                          key: ValueKey('$year-$revenue'),
                          tween: Tween(begin: 0, end: revenue),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(_money(v),
                                style: _t(40, FontWeight.w800, Colors.white,
                                    height: 1.05, spacing: -1)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Row(
                            children: [
                              _stat(Icons.receipt_long_rounded, 'បញ្ជាទិញសរុប', '$orders ដង'),
                              _stat(Icons.trending_up_rounded, 'មធ្យម/ខែ', _money(average)),
                              _stat(Icons.emoji_events_outlined, 'ខែល្អបំផុត', bestMonth),
                            ],
                          ),
                        ),
                      ],
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
// Chart card (12 months)
// ─────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final _Pal pal;
  final int year;
  final List<double> byMonth;
  final int bestIdx;
  final int? selected; // month number 1..12
  final double total;
  final ValueChanged<int> onSelect;

  const _ChartCard({
    required this.pal,
    required this.year,
    required this.byMonth,
    required this.bestIdx,
    required this.selected,
    required this.total,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    var maxRev = byMonth.reduce((a, b) => a > b ? a : b);
    if (maxRev == 0) maxRev = 1;

    final sel = selected;
    final headerLabel = sel == null ? 'Monthly revenue · $year' : '${_short[sel - 1]} $year';
    final headerValue = sel == null ? _money(total) : _money(byMonth[sel - 1]);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(24),
        border: pal.dark ? Border.all(color: pal.line) : null,
        boxShadow: [BoxShadow(color: pal.shadow, blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headerLabel, style: _t(12.5, FontWeight.w700, pal.muted)),
                      const SizedBox(height: 2),
                      Text(headerValue,
                          style: _t(22, FontWeight.w800, pal.ink, spacing: -0.4)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: pal.chip,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Tap a bar', style: _t(11, FontWeight.w700, pal.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (_) => Container(height: 1, color: pal.line)),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(12, (i) {
                    final m = i + 1;
                    final v = byMonth[i];
                    final factor = v / maxRev;
                    final isSel = sel == m;
                    final isBest = v > 0 && i == bestIdx;
                    final color = _monthColor(m);

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: v > 0 ? () => onSelect(m) : null,
                        child: Column(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: TweenAnimationBuilder<double>(
                                  key: ValueKey('${year}_${m}_$v'),
                                  tween: Tween(begin: 0, end: factor),
                                  duration: Duration(milliseconds: 450 + i * 45),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, f, __) => Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isSel)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 3),
                                          child: Text('\$${v.toStringAsFixed(0)}',
                                              style: _t(9, FontWeight.w800, color)),
                                        ),
                                      Flexible(
                                        child: FractionallySizedBox(
                                          heightFactor: v <= 0 ? 0.03 : (f < 0.05 ? 0.05 : f),
                                          child: Container(
                                            width: 15,
                                            decoration: BoxDecoration(
                                              gradient: v <= 0
                                                  ? null
                                                  : LinearGradient(
                                                colors: isSel || isBest
                                                    ? [color, color.withValues(alpha: 0.75)]
                                                    : [
                                                  color.withValues(alpha: 0.6),
                                                  color.withValues(alpha: 0.35),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              color: v <= 0 ? pal.line : null,
                                              borderRadius: BorderRadius.circular(6),
                                              boxShadow: isSel
                                                  ? [
                                                BoxShadow(
                                                  color: color.withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _short[i].substring(0, 1),
                              style: _t(
                                11,
                                isSel || isBest ? FontWeight.w800 : FontWeight.w600,
                                isSel ? color : pal.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Month card
// ─────────────────────────────────────────────────────────────
class _MonthCard extends StatelessWidget {
  final _Pal pal;
  final int month;
  final String name;
  final int orders;
  final double revenue;
  final double share;
  final bool isBest;
  final bool highlighted;
  final VoidCallback onTap;

  const _MonthCard({
    required this.pal,
    required this.month,
    required this.name,
    required this.orders,
    required this.revenue,
    required this.share,
    required this.isBest,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _monthColor(month);
    final textColor = pal.dark ? Color.lerp(color, Colors.white, 0.25)! : color;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: highlighted
            ? Border.all(color: color, width: 1.6)
            : (pal.dark ? Border.all(color: pal.line) : null),
        boxShadow: [BoxShadow(color: pal.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: pal.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
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
                      child: Text(name,
                          style: _t(14.5, FontWeight.w800, Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text('ខែទី $month ($name)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _t(14.5, FontWeight.w800, pal.ink)),
                              ),
                              if (isBest) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [Color(0xFFFFD34D), Color(0xFFF59E0B)]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 11, color: Colors.white),
                                      const SizedBox(width: 2),
                                      Text('Best',
                                          style: _t(9.5, FontWeight.w800, Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 13, color: pal.muted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('ចំនួនបញ្ជាទិញ៖ $orders ដង',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _t(11.5, FontWeight.w500, pal.muted)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(_money(revenue),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _t(15.5, FontWeight.w800, textColor, spacing: -0.3)),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 18, color: pal.muted),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${(share * 100).toStringAsFixed(1)}% នៃឆ្នាំ',
                              style: _t(10.5, FontWeight.w700, pal.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(height: 6, color: pal.chip),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: share.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => FractionallySizedBox(
                          widthFactor: v,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [color.withValues(alpha: 0.6), color]),
                              borderRadius: BorderRadius.circular(8),
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF151C2E) : Colors.white;
    final line = dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE3EBEA);

    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(6)),
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_ctrl),
      child: Column(
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
                (_) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: line,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(120, 14),
                        const SizedBox(height: 8),
                        bar(90, 11),
                      ],
                    ),
                  ),
                  bar(60, 15),
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
  final _Pal pal;
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.pal,
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
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: _t(15, FontWeight.w800, pal.ink, height: 1.4)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: _t(13, FontWeight.w400, pal.muted, height: 1.5)),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _K.brand,
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
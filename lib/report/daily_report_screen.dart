import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_inventory/api/report/api_report.dart';
import 'package:pos_inventory/models/reports/report_daily.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';
import 'package:share_plus/share_plus.dart';

import 'invoice_detail_screen.dart';

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

String _d(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) => _day(a) == _day(b);

enum _Filter { all, completed, other }

bool _isCompleted(ReportDaily o) {
  final s = o.status.toLowerCase();
  return s == 'completed' || s == 'paid';
}

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final ApiReport _apiReport = ApiReport();
  final TextEditingController _searchCtrl = TextEditingController();

  bool isLoading = true;
  bool hasError = false;

  List<ReportDaily> dailyOrders = [];
  double totalRevenue = 0.0;
  int totalOrdersCount = 0;

  DateTime? _startDate;
  DateTime? _endDate;

  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    _loadDailyReports();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String? _fmt(DateTime? d) => d == null
      ? null
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadDailyReports({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }
    try {
      final fetched = await _apiReport.fetchDailyReports(
        startDate: _fmt(_startDate),
        endDate: _fmt(_endDate),
      );

      var revenue = 0.0;
      for (final order in fetched) {
        revenue += order.totalAmount;
      }

      if (!mounted) return;
      setState(() {
        dailyOrders = fetched;
        totalRevenue = revenue;
        totalOrdersCount = fetched.length;
        hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading reports: $e');
      if (mounted) setState(() => hasError = true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _setRange(DateTime start, DateTime end) {
    HapticFeedback.selectionClick();
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _loadDailyReports();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: DateTime.now(), end: DateTime.now()),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.brand,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _C.ink,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) _setRange(picked.start, picked.end);
  }

  // ── Export ─────────────────────────────────────────────────
  // 📄 Export របាយការណ៍សរុបជា PDF
  Future<void> _exportReportAsPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SALES REPORT',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Total Revenue: \$${totalRevenue.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Total Orders: $totalOrdersCount',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 11,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey800,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200),
                  ),
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Order No', 'Customer', 'Date', 'Status', 'Amount'],
                data: dailyOrders.map((order) {
                  return [
                    order.orderNumber,
                    order.customer?.name ?? 'Guest',
                    order.createdAt.contains('T')
                        ? order.createdAt.split('T').first
                        : order.createdAt,
                    order.status.toUpperCase(),
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Sales_Report.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: '📊 របាយការណ៍លក់សរុប (Sales Report PDF)');
    } catch (e) {
      debugPrint('Error exporting PDF report: $e');
      if (mounted) AppSnackBar.showError(context, 'Failed to export PDF');
    }
  }

  String _csv(Object? v) => '"${'$v'.replaceAll('"', '""')}"';

  // 📊 Export របាយការណ៍ជា CSV (Excel Compatible)
  Future<void> _exportReportAsCSV() async {
    try {
      final csvRows = <String>[
        'Order ID,Order Number,Customer Name,Payment Method,Status,Total Amount,Date',
      ];

      for (final order in dailyOrders) {
        csvRows.add(
          [
            '${order.id}',
            _csv(order.orderNumber),
            _csv(order.customer?.name ?? 'Guest'),
            _csv(order.payment?.paymentMethod ?? 'Cash'),
            _csv(order.status),
            '${order.totalAmount}',
            _csv(order.createdAt),
          ].join(','),
        );
      }

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Sales_Report.csv');
      await file.writeAsString(csvRows.join('\n'));

      await Share.shareXFiles([
        XFile(file.path),
      ], text: '📈 របាយការណ៍លក់ (Excel/CSV Format)');
    } catch (e) {
      debugPrint('Error exporting CSV report: $e');
      if (mounted) AppSnackBar.showError(context, 'Failed to export CSV');
    }
  }

  void _showExportOptions() {
    if (dailyOrders.isEmpty) {
      AppSnackBar.showError(context, 'No transactions to export');
      return;
    }
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _C.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Export & Share Report',
                style: _t(18, FontWeight.w800, _C.ink),
              ),
              const SizedBox(height: 3),
              Text(
                'ជ្រើសរើសទម្រង់ឯកសារដែលចង់ Export',
                style: _t(13, FontWeight.w500, _C.muted),
              ),
              const SizedBox(height: 16),
              _ExportOption(
                icon: Icons.picture_as_pdf_rounded,
                color: _C.danger,
                title: 'Export as PDF Document',
                subtitle: '${dailyOrders.length} transactions · ready to print',
                onTap: () {
                  Navigator.pop(ctx);
                  _exportReportAsPDF();
                },
              ),
              const SizedBox(height: 10),
              _ExportOption(
                icon: Icons.table_chart_rounded,
                color: _C.brand,
                title: 'Export as Excel / CSV',
                subtitle: 'Open in Excel or Google Sheets',
                onTap: () {
                  Navigator.pop(ctx);
                  _exportReportAsCSV();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rangeText() {
    if (_startDate == null || _endDate == null) return 'ជ្រើសរើសកាលបរិច្ឆេទ';
    if (_sameDay(_startDate!, _endDate!)) {
      return _sameDay(_startDate!, DateTime.now())
          ? 'Today · ${_d(_startDate!)}'
          : _d(_startDate!);
    }
    return '${_d(_startDate!)} – ${_d(_endDate!)}';
  }

  String _dateKey(String ts) =>
      ts.trim().replaceFirst('T', ' ').split(' ').first;

  String _timeOf(String ts) {
    final p = ts.trim().replaceFirst('T', ' ').split(' ');
    if (p.length < 2) return '';
    return p[1].length >= 5 ? p[1].substring(0, 5) : p[1];
  }

  String _groupLabel(String key) {
    final dt = DateTime.tryParse(key);
    if (dt == null) return key.isEmpty ? 'Unknown date' : key;
    final now = DateTime.now();
    if (_sameDay(dt, now)) return 'Today';
    if (_sameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return _d(dt);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final completedCount = dailyOrders.where(_isCompleted).length;
    final otherCount = dailyOrders.length - completedCount;
    final avgOrder = totalOrdersCount > 0
        ? totalRevenue / totalOrdersCount
        : 0.0;

    final visible = dailyOrders.where((o) {
      final okFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.completed => _isCompleted(o),
        _Filter.other => !_isCompleted(o),
      };
      if (!okFilter) return false;
      if (q.isEmpty) return true;
      return '${o.orderNumber} ${o.customer?.name ?? 'Guest'}'
          .toLowerCase()
          .contains(q);
    }).toList();

    final groups = <String, List<ReportDaily>>{};
    for (final o in visible) {
      groups.putIfAbsent(_dateKey(o.createdAt), () => []).add(o);
    }

    final now = DateTime.now();
    final today = _day(now);

    final hasData = !isLoading && !hasError && dailyOrders.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadDailyReports(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  loading: isLoading,
                  revenue: totalRevenue,
                  orders: totalOrdersCount,
                  average: avgOrder,
                  completed: completedCount,
                  rangeText: _rangeText(),
                  onPickRange: _selectDateRange,
                  presets: [
                    _Preset(
                      'Today',
                      _startDate != null &&
                          _endDate != null &&
                          _sameDay(_startDate!, today) &&
                          _sameDay(_endDate!, today),
                      () => _setRange(today, today),
                    ),
                    _Preset(
                      'Yesterday',
                      _startDate != null &&
                          _endDate != null &&
                          _sameDay(
                            _startDate!,
                            today.subtract(const Duration(days: 1)),
                          ) &&
                          _sameDay(
                            _endDate!,
                            today.subtract(const Duration(days: 1)),
                          ),
                      () => _setRange(
                        today.subtract(const Duration(days: 1)),
                        today.subtract(const Duration(days: 1)),
                      ),
                    ),
                    _Preset(
                      '7 days',
                      _startDate != null &&
                          _endDate != null &&
                          _sameDay(
                            _startDate!,
                            today.subtract(const Duration(days: 6)),
                          ) &&
                          _sameDay(_endDate!, today),
                      () => _setRange(
                        today.subtract(const Duration(days: 6)),
                        today,
                      ),
                    ),
                    _Preset(
                      'This month',
                      _startDate != null &&
                          _endDate != null &&
                          _sameDay(
                            _startDate!,
                            DateTime(today.year, today.month, 1),
                          ) &&
                          _sameDay(_endDate!, today),
                      () => _setRange(
                        DateTime(today.year, today.month, 1),
                        today,
                      ),
                    ),
                  ],
                  onExport: _showExportOptions,
                  onRefresh: _loadDailyReports,
                ),
              ),
              if (hasData)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _C.heroA.withValues(alpha: 0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        cursorColor: _C.brand,
                        style: _t(14, FontWeight.w500, _C.ink),
                        decoration: InputDecoration(
                          hintText: 'Search order no. or customer',
                          hintStyle: _t(13.5, FontWeight.w400, _C.muted),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _C.muted,
                          ),
                          suffixIcon: _searchCtrl.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: _C.muted,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (hasData)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedBar(
                    child: _FilterBar(
                      selected: _filter,
                      counts: {
                        _Filter.all: dailyOrders.length,
                        _Filter.completed: completedCount,
                        _Filter.other: otherCount,
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
                    title: 'Could not load the sales report',
                    actionLabel: 'Try again',
                    onAction: _loadDailyReports,
                  ),
                )
              else if (dailyOrders.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.receipt_long_outlined,
                    color: _C.brand,
                    title: 'No transactions found in this range',
                    subtitle: 'Try another date range.',
                  ),
                )
              else if (visible.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.search_off_rounded,
                    color: _C.muted,
                    title: 'No matching transactions',
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
                            (s, o) => s + o.totalAmount,
                          ),
                          children: [
                            for (var i = 0; i < e.value.length; i++) ...[
                              _OrderRow(
                                order: e.value[i],
                                time: _timeOf(e.value[i].createdAt),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        InvoiceDetailScreen(order: e.value[i]),
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

class _Preset {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Preset(this.label, this.selected, this.onTap);
}

class _Hero extends StatelessWidget {
  final bool loading;
  final double revenue;
  final int orders;
  final double average;
  final int completed;
  final String rangeText;
  final VoidCallback onPickRange;
  final List<_Preset> presets;
  final VoidCallback onExport;
  final VoidCallback onRefresh;

  const _Hero({
    required this.loading,
    required this.revenue,
    required this.orders,
    required this.average,
    required this.completed,
    required this.rangeText,
    required this.onPickRange,
    required this.presets,
    required this.onExport,
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

  Widget _glassIcon(IconData icon, String tip, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(left: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      shape: BoxShape.circle,
    ),
    child: IconButton(
      tooltip: tip,
      icon: Icon(icon, color: Colors.white, size: 21),
      onPressed: onTap,
    ),
  );

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
                          'Sales Report',
                          style: _t(
                            21,
                            FontWeight.w800,
                            Colors.white,
                            spacing: -0.3,
                          ),
                        ),
                      ),
                      _glassIcon(Icons.ios_share_rounded, 'Export', onExport),
                      _glassIcon(Icons.refresh_rounded, 'Refresh', onRefresh),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // date range
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onPickRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  rangeText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(14, FontWeight.w800, Colors.white),
                                ),
                              ),
                              const Icon(
                                Icons.expand_more_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 12),
                      itemCount: presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final p = presets[i];
                        return GestureDetector(
                          onTap: p.onTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: p.selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              p.label,
                              style: _t(
                                12.5,
                                FontWeight.w800,
                                p.selected ? _C.brand : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total revenue',
                          style: _t(
                            12.5,
                            FontWeight.w600,
                            Colors.white.withValues(alpha: 0.85),
                          ),
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
                                Icons.shopping_cart_outlined,
                                'Orders',
                                '$orders',
                              ),
                              _stat(
                                Icons.show_chart_rounded,
                                'Avg order',
                                _money(average),
                              ),
                              _stat(
                                Icons.check_circle_outline_rounded,
                                'Completed',
                                '$completed',
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Date group + order row
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
  final ReportDaily order;
  final String time;
  final VoidCallback onTap;
  const _OrderRow({
    required this.order,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = _isCompleted(order);
    final color = done ? _C.brand : _C.pending;

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
              child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(14.5, FontWeight.w800, _C.ink),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: _C.muted,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          order.customer?.name ?? 'Guest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(12, FontWeight.w600, _C.muted),
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: _C.muted,
                        ),
                        const SizedBox(width: 3),
                        Text(time, style: _t(11.5, FontWeight.w500, _C.muted)),
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
                  _money(order.totalAmount),
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
// Export option tile
// ─────────────────────────────────────────────────────────────
class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ExportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.line),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _t(14.5, FontWeight.w800, _C.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _t(12, FontWeight.w500, _C.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.muted),
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
                        _bar(110, 14),
                        const SizedBox(height: 8),
                        _bar(140, 11),
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

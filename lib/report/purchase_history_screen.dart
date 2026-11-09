import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/report/api_report.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';

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
  static const hot = Color(0xFFEF5B16);
  static const blue = Color(0xFF3B6FD4);
  static const danger = Color(0xFFD32F2F);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

String _money(double v) => '\$${v.toStringAsFixed(2)}';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _prettyDate(String raw) {
  if (raw.trim().isEmpty) return '—';
  final d = DateTime.tryParse(raw.trim());
  if (d == null) return raw;
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class PurchaseHistoryScreen extends StatefulWidget {
  final dynamic purchaseId;
  final String referenceNo;
  final String supplierName;
  final String? supplierPhone;

  const PurchaseHistoryScreen({
    super.key,
    required this.purchaseId,
    required this.referenceNo,
    required this.supplierName,
    this.supplierPhone,
  });

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  bool isLoading = true;
  bool hasError = false;
  final ApiReport apiReport = ApiReport();

  Map<String, dynamic>? purchaseDetail;
  List<dynamic> purchaseItems = [];

  @override
  void initState() {
    super.initState();
    _loadPurchaseDetail();
  }

  // 🟢 ហៅ API ទាញយកព័ត៌មានលម្អិតនៃការបញ្ជាទិញតាម purchaseId
  Future<void> _loadPurchaseDetail({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }
    try {
      final data = await apiReport.fetchPurchaseDetail(widget.purchaseId);
      if (!mounted) return;
      setState(() {
        purchaseDetail = data;
        purchaseItems = data['items'] ?? [];
        hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading purchase detail: $e');
      if (mounted) setState(() => hasError = true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _copyPhone() {
    final phone = widget.supplierPhone;
    if (phone == null || phone.isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: phone));
    AppSnackBar.showSuccess(context, 'Phone copied');
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = double.tryParse(purchaseDetail?['total']?.toString() ?? '0') ?? 0.0;
    final status = (purchaseDetail?['status'] ?? 'Received').toString();
    final date = (purchaseDetail?['date'] ?? '').toString();

    // Items summary
    var totalUnits = 0.0;
    for (final p in purchaseItems) {
      totalUnits += double.tryParse(p['quantity']?.toString() ?? '0') ?? 0.0;
    }
    final avgCost = totalUnits > 0 ? totalAmount / totalUnits : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadPurchaseDetail(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  referenceNo: widget.referenceNo,
                  supplierName: widget.supplierName,
                  supplierPhone: widget.supplierPhone,
                  status: status,
                  date: date,
                  total: totalAmount,
                  itemCount: purchaseItems.length,
                  units: totalUnits,
                  avgCost: avgCost,
                  loading: isLoading,
                  onCopyPhone: _copyPhone,
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
                    title: 'Could not load purchase details',
                    actionLabel: 'Try again',
                    onAction: _loadPurchaseDetail,
                  ),
                )
              else if (purchaseItems.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.inbox_outlined,
                      color: _C.brand,
                      title: 'No items found in this purchase',
                    ),
                  )
                else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 18, color: _C.brand),
                            const SizedBox(width: 8),
                            Text('Imported products', style: _t(16, FontWeight.w800, _C.ink)),
                            const Spacer(),
                            Text('${purchaseItems.length} items',
                                style: _t(12, FontWeight.w700, _C.muted)),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      sliver: SliverList.separated(
                        itemCount: purchaseItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _FadeSlide(
                          index: index,
                          child: _ItemCard(prod: purchaseItems[index]),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                      sliver: SliverToBoxAdapter(
                        child: _TotalBar(total: totalAmount, units: totalUnits),
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
  final String referenceNo;
  final String supplierName;
  final String? supplierPhone;
  final String status;
  final String date;
  final double total;
  final int itemCount;
  final double units;
  final double avgCost;
  final bool loading;
  final VoidCallback onCopyPhone;

  const _Hero({
    required this.referenceNo,
    required this.supplierName,
    required this.supplierPhone,
    required this.status,
    required this.date,
    required this.total,
    required this.itemCount,
    required this.units,
    required this.avgCost,
    required this.loading,
    required this.onCopyPhone,
  });

  Color get _statusColor {
    final s = status.toLowerCase();
    if (s.contains('pend')) return _C.hot;
    if (s.contains('cancel') || s.contains('reject')) return _C.danger;
    return _C.brand;
  }

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
            child: Text(value, style: _t(16, FontWeight.w800, Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final hasPhone = supplierPhone != null && supplierPhone!.isNotEmpty;

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Purchase',
                                style: _t(12, FontWeight.w600,
                                    Colors.white.withValues(alpha: 0.85))),
                            Text(referenceNo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(20, FontWeight.w800, Colors.white, spacing: -0.3)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: _statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(status.toUpperCase(),
                                style: _t(10.5, FontWeight.w800, _statusColor, spacing: 0.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // supplier
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            supplierName.isNotEmpty
                                ? supplierName.characters.first.toUpperCase()
                                : 'S',
                            style: _t(20, FontWeight.w800, _C.brand),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(supplierName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(16, FontWeight.w800, Colors.white)),
                              const SizedBox(height: 3),
                              InkWell(
                                onTap: hasPhone ? onCopyPhone : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.phone_outlined,
                                        size: 13,
                                        color: Colors.white.withValues(alpha: 0.85)),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        hasPhone ? supplierPhone! : 'No Phone Number',
                                        style: _t(12.5, FontWeight.w500,
                                            Colors.white.withValues(alpha: 0.88)),
                                      ),
                                    ),
                                    if (hasPhone) ...[
                                      const SizedBox(width: 5),
                                      Icon(Icons.copy_rounded,
                                          size: 12,
                                          color: Colors.white.withValues(alpha: 0.7)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // total + date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total cost',
                                  style: _t(12.5, FontWeight.w600,
                                      Colors.white.withValues(alpha: 0.85))),
                              const SizedBox(height: 4),
                              loading
                                  ? Container(
                                width: 150,
                                height: 38,
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
                                  child: Text(_money(v),
                                      style: _t(36, FontWeight.w800, Colors.white,
                                          height: 1.05, spacing: -1)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_rounded,
                                      size: 12,
                                      color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text('Order date',
                                      style: _t(10.5, FontWeight.w600,
                                          Colors.white.withValues(alpha: 0.8))),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(_prettyDate(date),
                                  style: _t(13, FontWeight.w800, Colors.white)),
                            ],
                          ),
                        ),
                      ],
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
                        _stat(Icons.category_outlined, 'Products', '$itemCount'),
                        _stat(Icons.inventory_2_outlined, 'Total units',
                            units.toStringAsFixed(units == units.roundToDouble() ? 0 : 1)),
                        _stat(Icons.sell_outlined, 'Avg cost', _money(avgCost)),
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
// Item card
// ─────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final dynamic prod;
  const _ItemCard({required this.prod});

  @override
  Widget build(BuildContext context) {
    final imageUrl = prod['image_url']?.toString() ?? '';
    final qty = double.tryParse(prod['quantity']?.toString() ?? '0') ?? 0.0;
    final costPrice = double.tryParse(prod['cost_price']?.toString() ?? '0') ?? 0.0;
    final name = (prod['product_name'] ?? 'Unknown').toString();

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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.line),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
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
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(14.5, FontWeight.w800, _C.ink)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          icon: Icons.sell_outlined,
                          label: '${_money(costPrice)} / unit',
                          color: _C.muted,
                        ),
                        _Chip(
                          icon: Icons.inventory_2_outlined,
                          label: 'Qty ${qty.toInt()}',
                          color: _C.blue,
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
                  Text(_money(costPrice * qty), style: _t(15.5, FontWeight.w800, _C.brand)),
                  const SizedBox(height: 2),
                  Text('Subtotal', style: _t(10.5, FontWeight.w600, _C.muted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: _t(10.5, FontWeight.w800, color)),
        ],
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
// Total bar at the end of the list
// ─────────────────────────────────────────────────────────────
class _TotalBar extends StatelessWidget {
  final double total;
  final double units;
  const _TotalBar({required this.total, required this.units});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.heroA, _C.brand, _C.heroB]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.brand.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total purchase cost',
                    style: _t(12, FontWeight.w600, Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 2),
                Text('${units.toStringAsFixed(units == units.roundToDouble() ? 0 : 1)} units',
                    style: _t(11.5, FontWeight.w500, Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          Text(_money(total), style: _t(22, FontWeight.w800, Colors.white, spacing: -0.4)),
        ],
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
      child: Column(
        children: List.generate(
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
                  width: 54,
                  height: 54,
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
                      _bar(130, 14),
                      const SizedBox(height: 10),
                      _bar(100, 16),
                    ],
                  ),
                ),
                _bar(50, 15),
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
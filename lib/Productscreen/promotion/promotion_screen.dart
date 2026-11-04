import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/Productscreen/models/product_promotion_model.dart';
import 'package:pos_inventory/Productscreen/promotion/create_promotion_screen.dart';
import 'package:pos_inventory/Productscreen/promotion/detail_promotion_screen.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';
import '../../api/promotion/api_promotion.dart';

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
  static const inactive = Color(0xFF7B8794);
  static const expired = Color(0xFFD32F2F);
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

enum PromoStatus { active, inactive, expired }

enum PromoFilter { all, active, inactive, expired }

Color _statusColor(PromoStatus s) => switch (s) {
  PromoStatus.active => _C.brand,
  PromoStatus.inactive => _C.inactive,
  PromoStatus.expired => _C.expired,
};

String _statusLabel(PromoStatus s) => switch (s) {
  PromoStatus.active => 'Active',
  PromoStatus.inactive => 'Inactive',
  PromoStatus.expired => 'Expired',
};

String _num(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

String _days(int d) => '$d ${d == 1 ? 'day' : 'days'}';

DateTime? _dateOnly(String? s) {
  if (s == null || s.isEmpty) return null;
  final p = DateTime.tryParse(s);
  return p == null ? null : DateTime(p.year, p.month, p.day);
}

const ColorFilter _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  List<ProductPromotionModel> _promotions = [];
  bool _isLoading = true;
  bool _hasError = false;
  final ApiPromotion _apiPromotion = ApiPromotion();
  final TextEditingController _searchCtrl = TextEditingController();

  PromoFilter _filter = PromoFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final promotions = await _apiPromotion.fetchPromotions();
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isExpired(String? endDateStr) {
    final end = _dateOnly(endDateStr);
    if (end == null) return false;
    final now = DateTime.now();
    return end.isBefore(DateTime(now.year, now.month, now.day));
  }

  PromoStatus _statusOf(ProductPromotionModel p) {
    if (_isExpired(p.endDate)) return PromoStatus.expired;
    return p.isActive ? PromoStatus.active : PromoStatus.inactive;
  }

  Future<void> _togglePromotionStatus(
      ProductPromotionModel promo,
      bool newStatus,
      ) async {
    HapticFeedback.lightImpact();
    final success = await _apiPromotion.updateStatus(promo.id, {
      'is_active': newStatus ? 1 : 0,
    });
    if (!mounted) return;
    if (success) {
      _loadPromotions(silent: true);
      AppSnackBar.showSuccess(
        context,
        newStatus
            ? 'Promotion activated successfully!'
            : 'Promotion deactivated successfully!',
      );
    } else {
      AppSnackBar.showError(context, 'Failed to update status.');
    }
  }

  Future<void> _confirmDelete(ProductPromotionModel promo) async {
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
                  color: _C.expired.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _C.expired,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text('Delete promotion', style: _t(18, FontWeight.bold, _C.ink)),
              const SizedBox(height: 8),
              Text(
                '"${promo.title}" will be removed. Remaining stock will be returned to the product.',
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
                        style: _t(14, FontWeight.bold, _C.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.expired,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: _t(14, FontWeight.bold, Colors.white),
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

    setState(() => _isLoading = true);
    final success = await _apiPromotion.deletePromotion(promo.id);
    if (!mounted) return;
    if (success) {
      await _loadPromotions();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Promotion deleted successfully!');
    } else {
      setState(() => _isLoading = false);
      AppSnackBar.showError(context, 'Failed to delete promotion.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _promotions.map(_statusOf).toList();
    final q = _query.trim().toLowerCase();

    final visible = _promotions.where((p) {
      final s = _statusOf(p);
      final okFilter = switch (_filter) {
        PromoFilter.all => true,
        PromoFilter.active => s == PromoStatus.active,
        PromoFilter.inactive => s == PromoStatus.inactive,
        PromoFilter.expired => s == PromoStatus.expired,
      };
      if (!okFilter) return false;
      if (q.isEmpty) return true;
      final hay = '${p.title} ${p.promotionCode} ${p.product?.name ?? ''}'
          .toLowerCase();
      return hay.contains(q);
    }).toList();

    final hasData = !_isLoading && !_hasError && _promotions.isNotEmpty;
    final activeCount = statuses.where((s) => s == PromoStatus.active).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadPromotions(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  activeCount: activeCount,
                  showSearch: hasData,
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  onRefresh: _loadPromotions,
                ),
              ),
              if (hasData)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedBar(
                    child: _FilterBar(
                      statuses: statuses,
                      selected: _filter,
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
                    title: 'Could not load promotions',
                    actionLabel: 'Try again',
                    onAction: _loadPromotions,
                  ),
                )
              else if (_promotions.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.local_offer_outlined,
                      color: _C.brand,
                      title: 'No promotions yet',
                      subtitle: 'Tap "New promotion" to create your first one.',
                    ),
                  )
                else if (visible.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MessageState(
                        icon: Icons.search_off_rounded,
                        color: _C.muted,
                        title: 'No promotions match your search',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      sliver: SliverList.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final promo = visible[i];
                          return _FadeSlide(
                            index: i,
                            child: _PromoCard(
                              promo: promo,
                              status: _statusOf(promo),
                              onOpen: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailPromotionScreen(promotion: promo),
                                ),
                              ),
                              onLongPress: () => _confirmDelete(promo),
                              onToggle: (v) => _togglePromotionStatus(promo, v),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
        floatingActionButton: _NewPromoButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePromotionScreen()),
            );
            if (result == true) _loadPromotions(silent: true);
          },
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

class _PinnedBar extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PinnedBar({required this.child});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: _C.bg,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBar old) => true;
}

class _NewPromoButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NewPromoButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.hot, _C.hotB]),
        borderRadius: BorderRadius.circular(18),
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
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                Text('New', style: _t(14, FontWeight.w800, Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Compact hero (title + running count + search)
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final int activeCount;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  const _Hero({
    required this.activeCount,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Promotions',
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
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7CFFB2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$activeCount running now',
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
                      child: _SearchField(
                        controller: controller,
                        onChanged: onChanged,
                        onClear: onClear,
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          hintText: 'Search title, code or product',
          hintStyle: _t(13.5, FontWeight.w400, _C.muted),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.muted),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter chips (pinned)
// ─────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final List<PromoStatus> statuses;
  final PromoFilter selected;
  final ValueChanged<PromoFilter> onSelect;

  const _FilterBar({
    required this.statuses,
    required this.selected,
    required this.onSelect,
  });

  int _c(PromoStatus s) => statuses.where((x) => x == s).length;

  @override
  Widget build(BuildContext context) {
    final items = <(PromoFilter, String, int)>[
      (PromoFilter.all, 'All', statuses.length),
      (PromoFilter.active, 'Active', _c(PromoStatus.active)),
      (PromoFilter.inactive, 'Inactive', _c(PromoStatus.inactive)),
      (PromoFilter.expired, 'Expired', _c(PromoStatus.expired)),
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
                  Text(
                    it.$2,
                    style: _t(
                      13,
                      FontWeight.w700,
                      sel ? Colors.white : _C.ink,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? Colors.white.withValues(alpha: 0.22)
                          : _C.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${it.$3}',
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
// Compact promotion card (~120px tall)
// ─────────────────────────────────────────────────────────────
class _PromoCard extends StatelessWidget {
  final ProductPromotionModel promo;
  final PromoStatus status;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onToggle;

  const _PromoCard({
    required this.promo,
    required this.status,
    required this.onOpen,
    required this.onLongPress,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final expired = status == PromoStatus.expired;
    final dimmed = status != PromoStatus.active;
    final isPercent = promo.discountType == 'percentage';

    final original = (promo.product?.sellingPrice ?? 0.0).toDouble();
    final dv = promo.discountValue.toDouble();
    final discountAmount = isPercent ? (original * dv) / 100 : dv;
    final finalPrice = (original - discountAmount)
        .clamp(0.0, double.infinity)
        .toDouble();

    // Timeline
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = _dateOnly(promo.startDate);
    final end = _dateOnly(promo.endDate);

    String timeLabel;
    if (expired) {
      final d = end == null ? 0 : today.difference(end).inDays;
      timeLabel = d <= 0 ? 'Ended' : 'Ended ${_days(d)} ago';
    } else if (start != null && start.isAfter(today)) {
      timeLabel = 'Starts in ${_days(start.difference(today).inDays)}';
    } else if (end == null) {
      timeLabel = 'No end date';
    } else {
      final d = end.difference(today).inDays;
      timeLabel = d == 0 ? 'Ends today' : '${_days(d)} left';
    }

    double? progress;
    if (start != null && end != null) {
      final total = end.difference(start).inDays;
      if (total > 0) {
        progress = (today.difference(start).inDays / total)
            .clamp(0.0, 1.0)
            .toDouble();
      }
    }

    final endingSoon =
        status == PromoStatus.active &&
            end != null &&
            end.difference(today).inDays <= 3;
    final timeColor = expired
        ? _C.expired
        : endingSoon
        ? _C.hot
        : status == PromoStatus.inactive
        ? _C.inactive
        : _C.brand;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.heroA.withValues(alpha: dimmed ? 0.04 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          onLongPress: onLongPress,
          child: Column(
            children: [
              // ── Main row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 6, 10),
                child: Row(
                  children: [
                    _ProductImage(
                      url: promo.product?.imageUrl,
                      grayscale: dimmed,
                      dimmed: dimmed,
                      badge: isPercent ? '-${_num(dv)}%' : '-\$${_num(dv)}',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  promo.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(14.5, FontWeight.w800, _C.ink),
                                ),
                              ),
                              if (dimmed) ...[
                                const SizedBox(width: 6),
                                _StatusPill(status: status),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            promo.product?.name ?? '${promo.productId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(12, FontWeight.w500, _C.muted),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${finalPrice.toStringAsFixed(2)}',
                                style: _t(
                                  19,
                                  FontWeight.w800,
                                  dimmed ? _C.muted : _C.hot,
                                  height: 1.1,
                                  spacing: -0.3,
                                ),
                              ),
                              if (original > 0) ...[
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 1),
                                  child: Text(
                                    '\$${original.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _C.muted,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: status == PromoStatus.active,
                        activeThumbColor: Colors.white,
                        activeTrackColor: _C.brand,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFCBD5D8),
                        // Disabled when expired
                        onChanged: expired ? null : onToggle,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Meta row ──
              Container(height: 1, color: _C.line),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                child: Row(
                  children: [
                    Icon(
                      expired
                          ? Icons.event_busy_rounded
                          : Icons.schedule_rounded,
                      size: 14,
                      color: timeColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        timeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(11.5, FontWeight.w800, timeColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 13,
                      color: _C.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${promo.quantity ?? '∞'}',
                      style: _t(11.5, FontWeight.w700, _C.ink),
                    ),
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 104),
                      child: _CodeChip(
                        code: promo.promotionCode,
                        color: dimmed ? _C.inactive : _C.brand,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(
                            ClipboardData(text: promo.promotionCode),
                          );
                          AppSnackBar.showSuccess(context, 'Code copied');
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Thin progress line ──
              if (progress != null)
                Stack(
                  children: [
                    Container(height: 3, color: timeColor.withValues(alpha: 0.14)),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(height: 3, color: timeColor),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  final bool grayscale;
  final bool dimmed;
  final String badge;

  const _ProductImage({
    required this.url,
    required this.grayscale,
    required this.dimmed,
    required this.badge,
  });

  static const double _size = 68;

  @override
  Widget build(BuildContext context) {
    Widget img = (url != null && url!.isNotEmpty)
        ? Image.network(
      url!,
      fit: BoxFit.cover,
      width: _size,
      height: _size,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: _C.muted,
          size: 24,
        ),
      ),
    )
        : const Center(
      child: Icon(Icons.shopping_bag_outlined, color: _C.brand, size: 26),
    );

    if (grayscale) {
      img = ColorFiltered(colorFilter: _grayscale, child: img);
    }

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.line),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: img,
              ),
            ),
          ),
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dimmed
                      ? const [Color(0xFF8D98A5), _C.inactive]
                      : const [_C.hot, _C.hotB],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge, style: _t(10.5, FontWeight.w800, Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final PromoStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_statusLabel(status), style: _t(10, FontWeight.w800, c)),
    );
  }
}

class _CodeChip extends StatelessWidget {
  final String code;
  final Color color;
  final VoidCallback onTap;

  const _CodeChip({
    required this.code,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(11, FontWeight.w800, color, spacing: 0.6),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.copy_rounded,
              size: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Skeleton loading
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
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
                      _bar(140, 14),
                      const SizedBox(height: 8),
                      _bar(90, 11),
                      const SizedBox(height: 10),
                      _bar(80, 18),
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
// Empty / error state
// ─────────────────────────────────────────────────────────────
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
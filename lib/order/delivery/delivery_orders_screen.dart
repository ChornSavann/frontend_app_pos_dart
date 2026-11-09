import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_order.dart';
import '../../msg/appSnackBar.dart';
import 'order_tracking_screen.dart';

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
  static const onTheWay = Color(0xFF3B6FD4);
  static const done = Color(0xFF0F766E);
  static const danger = Color(0xFFD32F2F);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

class _Tab {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _Tab(this.key, this.label, this.icon, this.color);
}

const _tabs = <_Tab>[
  _Tab('pending', 'រង់ចាំ', Icons.schedule_rounded, _C.pending),
  _Tab('on_the_way', 'កំពុងដឹក', Icons.delivery_dining_rounded, _C.onTheWay),
  _Tab('completed', 'បានបញ្ចប់', Icons.check_circle_rounded, _C.done),
  _Tab('cancelled', 'បានបោះបង់', Icons.cancel_rounded, _C.danger),
];

_Tab _tabOf(String status) =>
    _tabs.firstWhere((t) => t.key == status, orElse: () => _tabs.first);

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _deliveryOrders = [];

  final ApiOrder apiOrder = ApiOrder();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchDeliveryOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeliveryOrders({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final data = await apiOrder.getDeliveryOrders();
      if (!mounted) return;
      setState(() {
        _deliveryOrders = data;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _updateStatusWithoutReload(int deliveryId, String newStatus) async {
    try {
      final ok = await apiOrder.updateDeliveryStatus(deliveryId, newStatus);
      if (ok) await _fetchDeliveryOrders(silent: true);
      return ok;
    } catch (e) {
      debugPrint('Error: $e');
      return false;
    }
  }

  Future<void> _takeToDeliver(dynamic order, dynamic delivery) async {
    HapticFeedback.mediumImpact();
    final ok = await _updateStatusWithoutReload(delivery['id'], 'on_the_way');
    if (!mounted) return;
    if (!ok) {
      AppSnackBar.showError(context, 'បរាជ័យក្នុងការធ្វើបច្ចុប្បន្នភាពទិន្នន័យ!');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(
          orderId: order['order_number'] ?? '#GRX123456',
          deliveryData: {
            'order_id': order['id'],
            'estimated_minutes': 1,
            'grand_total': double.tryParse(order['total_amount'].toString()) ?? 0.0,
            'name': delivery['receiver_name'] ?? 'Driver',
            'phone': delivery['receiver_phone'] ?? '',
            'delivery_partner': delivery['delivery_partner'] ?? 'POS Express',

            // 🗺️ បញ្ជូន Lat និង Lng ពី Database ទៅកាន់ OrderTrackingScreen
            'store_lat': delivery['store_lat'],
            'store_lng': delivery['store_lng'],
            'customer_lat': delivery['customer_lat'],
            'customer_lng': delivery['customer_lng'],
          },
        ),
      ),
    );
    if (mounted) _fetchDeliveryOrders(silent: true);
  }

  Future<void> _updateStatus(
      int deliveryId,
      String newStatus, {
        bool isCancel = false,
        required dynamic orderId,
      }) async {
    if (isCancel) {
      HapticFeedback.mediumImpact();
      final confirmCancel = await showDialog<bool>(
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
                  child: const Icon(Icons.warning_amber_rounded, color: _C.danger, size: 34),
                ),
                const SizedBox(height: 16),
                Text('បញ្ជាក់ការបោះបង់', style: _t(18, FontWeight.w800, _C.ink)),
                const SizedBox(height: 8),
                Text(
                  'តើអ្នកពិតជាចង់បោះបង់ការបញ្ជាទិញនេះមែនទេ? ទិន្នន័យទឹកប្រាក់នឹងត្រូវកែសម្រួលមកជា 0 និងសងស្តុកទំនិញវិញ។',
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('ទេ (No)', style: _t(14, FontWeight.w800, _C.ink)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _C.danger,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('បោះបង់ (Yes)', style: _t(14, FontWeight.w800, Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmCancel != true || !mounted) return;
    }

    // Blocking progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: _C.brand),
          ),
        ),
      ),
    );

    try {
      bool success = false;

      if (isCancel) {
        success = await apiOrder.updateDeliveryPaymentAndStatusCancel(
          deliveryId: deliveryId,
          status: 'cancelled',
          paymentMethod: 'cancelled',
        );
      } else {
        success = await apiOrder.updateDeliveryStatus(deliveryId, newStatus);
      }

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          HapticFeedback.lightImpact();
          _fetchDeliveryOrders(silent: true);
          AppSnackBar.showSuccess(
            context,
            isCancel
                ? 'បានបោះបង់ និងកែប្រែទឹកប្រាក់មកជា 0 ជោគជ័យ!'
                : 'បានធ្វើបច្ចុប្បន្នភាពស្ថានភាពជោគជ័យ!',
          );
        } else {
          AppSnackBar.showError(context, 'បរាជ័យក្នុងការធ្វើបច្ចុប្បន្នភាពទិន្នន័យ!');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showError(context, 'Error: $e');
      }
    }
  }

  List<dynamic> _listOf(String status) => _deliveryOrders
      .where((o) => o['delivery'] != null && o['delivery']['status'] == status)
      .toList();

  @override
  Widget build(BuildContext context) {
    final counts = {for (final t in _tabs) t.key: _listOf(t.key).length};

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            // 📌 Sticky header with tabs
            _Hero(
              controller: _tabController,
              counts: counts,
              loading: _isLoading,
              onRefresh: _fetchDeliveryOrders,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final t in _tabs) _buildOrderList(t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(_Tab tab) {
    final list = _listOf(tab.key);

    Widget content;
    if (_isLoading) {
      content = const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: _SkeletonList(),
      );
    } else if (_hasError) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: _MessageState(
              icon: Icons.cloud_off_rounded,
              color: _C.muted,
              title: 'មិនអាចទាញយកទិន្នន័យបានទេ',
              actionLabel: 'សាកល្បងម្តងទៀត',
              onAction: _fetchDeliveryOrders,
            ),
          ),
        ],
      );
    } else if (list.isEmpty) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: _MessageState(
              icon: tab.icon,
              color: tab.color,
              title: 'គ្មានទិន្នន័យដឹកជញ្ជូន (${tab.label})',
            ),
          ),
        ],
      );
    } else {
      content = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = list[index];
          final delivery = order['delivery'];
          return _FadeSlide(
            index: index,
            child: _DeliveryCard(
              order: order,
              delivery: delivery,
              onTake: () => _takeToDeliver(order, delivery),
              onComplete: () => _updateStatus(
                delivery['id'],
                'completed',
                orderId: order['id'],
              ),
              onCancel: () => _updateStatus(
                delivery['id'],
                'cancelled',
                isCancel: true,
                orderId: order['id'],
              ),
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      color: _C.brand,
      onRefresh: () => _fetchDeliveryOrders(silent: true),
      child: content,
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
// Hero + tabs (sticky)
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final TabController controller;
  final Map<String, int> counts;
  final bool loading;
  final VoidCallback onRefresh;

  const _Hero({
    required this.controller,
    required this.counts,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final active = (counts['pending'] ?? 0) + (counts['on_the_way'] ?? 0);

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
              padding: EdgeInsets.fromLTRB(16, top + 6, 12, 14),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('គ្រប់គ្រងការដឹកជញ្ជូន',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(21, FontWeight.w800, Colors.white, spacing: -0.3)),
                            const SizedBox(height: 3),
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
                                Text(loading ? '...' : '$active កំពុងដំណើរការ',
                                    style: _t(12.5, FontWeight.w600,
                                        Colors.white.withValues(alpha: 0.9))),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: TabBar(
                      controller: controller,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelColor: _C.brand,
                      unselectedLabelColor: Colors.white,
                      labelPadding: const EdgeInsets.only(right: 8),
                      padding: EdgeInsets.zero,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      splashFactory: NoSplash.splashFactory,
                      tabs: [
                        for (var i = 0; i < _tabs.length; i++)
                          Tab(
                            height: 40,
                            child: AnimatedBuilder(
                              animation: controller.animation ?? controller,
                              builder: (context, _) {
                                final pos = controller.animation?.value ??
                                    controller.index.toDouble();
                                final selected = (pos - i).abs() < 0.5;
                                final t = _tabs[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(t.icon, size: 16),
                                      const SizedBox(width: 6),
                                      // no explicit colour: follows labelColor / unselectedLabelColor
                                      Text(
                                        t.label,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? t.color.withValues(alpha: 0.16)
                                              : Colors.white.withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('${counts[t.key] ?? 0}',
                                            style: _t(
                                              11.5,
                                              FontWeight.w800,
                                              selected ? t.color : Colors.white,
                                            )),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
// Delivery card
// ─────────────────────────────────────────────────────────────
class _DeliveryCard extends StatelessWidget {
  final dynamic order;
  final dynamic delivery;
  final VoidCallback onTake;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _DeliveryCard({
    required this.order,
    required this.delivery,
    required this.onTake,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = '${delivery['status']}';
    final tab = _tabOf(status);
    final color = tab.color;

    final receiver = '${delivery['receiver_name'] ?? ''}';
    final phone = '${delivery['receiver_phone'] ?? ''}';
    final address = '${delivery['delivery_address'] ?? ''}';
    final fee = '${delivery['delivery_fee'] ?? '0.00'}';
    final total = '${order['total_amount']}';

    final canAct = status == 'pending' || status == 'on_the_way';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.heroA.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── header: icon | order + receiver | total + fee ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.85), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(tab.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${order['order_number']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(14.5, FontWeight.w800, _C.ink)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(receiver,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(12.5, FontWeight.w700, _C.muted)),
                            ),
                          ],
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Clipboard.setData(ClipboardData(text: phone));
                              AppSnackBar.showSuccess(context, 'Phone copied');
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_rounded, size: 13, color: _C.brand),
                                const SizedBox(width: 5),
                                Text(phone, style: _t(12.5, FontWeight.w800, _C.brand)),
                                const SizedBox(width: 5),
                                Icon(Icons.copy_rounded,
                                    size: 11, color: _C.brand.withValues(alpha: 0.6)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$$total',
                          style: _t(20, FontWeight.w800, _C.ink, height: 1.1, spacing: -0.5)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _C.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 11, color: _C.brand),
                            const SizedBox(width: 4),
                            Text('\$$fee', style: _t(10.5, FontWeight.w800, _C.brand)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── address ──
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: Color(0xFFEF5B16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address.isEmpty ? '—' : address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _t(12, FontWeight.w600, _C.ink, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              // ── actions ──
              if (canAct) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: status == 'pending' ? 'យកទៅដឹក' : 'ទទួលបានរួចរាល់',
                        icon: status == 'pending'
                            ? Icons.delivery_dining_rounded
                            : Icons.check_circle_outline_rounded,
                        colors: status == 'pending'
                            ? const [_C.heroA, _C.brand, _C.heroB]
                            : const [Color(0xFF0B6B3F), Color(0xFF16A36A)],
                        onTap: status == 'pending' ? onTake : onComplete,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.danger,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          side: BorderSide(color: _C.danger.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text('បោះបង់', style: _t(13, FontWeight.w800, _C.danger)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(13, FontWeight.w800, Colors.white)),
              ),
            ],
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
          3,
              (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _C.line,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _bar(110, 14),
                    const Spacer(),
                    _bar(70, 22),
                  ],
                ),
                const SizedBox(height: 16),
                _bar(150, 14),
                const SizedBox(height: 12),
                _bar(double.infinity, 40),
                const SizedBox(height: 14),
                _bar(double.infinity, 46),
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
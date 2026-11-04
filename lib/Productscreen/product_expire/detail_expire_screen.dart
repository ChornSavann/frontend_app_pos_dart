import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/expire_product/api_expire_product.dart';
import 'models/expire_product_model.dart';
import '../../msg/appSnackBar.dart';
import 'update_expire_screen.dart';

class _C {
  static const bg = Color(0xFFF2F4F8);
  static const ink = Color(0xFF142033);
  static const muted = Color(0xFF6C7A8E);
  static const line = Color(0xFFE4E9F0);
  static const navy = Color(0xFF0E2A47);

  static const expired = Color(0xFFD32F2F);
  static const week = Color(0xFFEF6C00);
  static const month = Color(0xFFC79100);
  static const safe = Color(0xFF2E9E6B);
}

const _font = 'KhmerOSBattambang';

TextStyle _t(double size, FontWeight w, Color c, {double? height}) => TextStyle(
  fontSize: size,
  fontWeight: w,
  color: c,
  fontFamily: _font,
  height: height,
);

Color _tierColor(int days) {
  if (days < 0) return _C.expired;
  if (days <= 7) return _C.week;
  if (days <= 30) return _C.month;
  return _C.safe;
}

DateTime? _dateOnly(String s) {
  final p = DateTime.tryParse(s);
  return p == null ? null : DateTime(p.year, p.month, p.day);
}

String _fmtDate(DateTime? d, String fallback) {
  if (d == null) return fallback;
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

class DetailExpireScreen extends StatefulWidget {
  final int expireId;

  const DetailExpireScreen({super.key, required this.expireId});

  @override
  State<DetailExpireScreen> createState() => _DetailExpireScreenState();
}

class _DetailExpireScreenState extends State<DetailExpireScreen> {
  final ApiExpireProduct _apiService = ApiExpireProduct();

  bool _isLoading = true;
  bool _hasError = false;
  bool _isDeleting = false;
  ExpireProductModel? _expireDetail;

  @override
  void initState() {
    super.initState();
    _fetchDetailData();
  }

  Future<void> _fetchDetailData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _apiService.getExpireProductById(widget.expireId);
      if (!mounted) return;
      setState(() {
        _expireDetail = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateExpireScreen(expireId: widget.expireId),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmAndDelete() async {
    final name = _expireDetail?.productName ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text('លុបកំណត់ត្រា', style: _t(17, FontWeight.bold, _C.ink)),
              const SizedBox(height: 8),
              Text(
                name.isEmpty
                    ? 'តើអ្នកពិតជាចង់លុបថ្ងៃផុតកំណត់នេះមែនទេ?'
                    : 'តើអ្នកពិតជាចង់លុបថ្ងៃផុតកំណត់របស់\n"$name" មែនទេ?',
                textAlign: TextAlign.center,
                style: _t(13.5, FontWeight.w500, _C.muted, height: 1.6),
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'បោះបង់',
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'លុប',
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

    setState(() => _isDeleting = true);
    final success = await _apiService.deleteExpireProduct(widget.expireId);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      AppSnackBar.showSuccess(context, 'បានលុបជោគជ័យ!');
      Navigator.pop(context, true);
    } else {
      AppSnackBar.showError(context, 'បរាជ័យក្នុងការលុប!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Stack(
          children: [
            _buildBody(),
            if (_isDeleting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Column(
        children: [
          _TopBar(onEdit: null, onDelete: null),
          const Expanded(
            child: Center(child: CircularProgressIndicator(color: _C.navy)),
          ),
        ],
      );
    }

    if (_hasError || _expireDetail == null) {
      return Column(
        children: [
          const _TopBar(onEdit: null, onDelete: null),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _C.muted.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasError
                            ? Icons.cloud_off_rounded
                            : Icons.search_off_rounded,
                        size: 42,
                        color: _C.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasError
                          ? 'មិនអាចទាញទិន្នន័យបានទេ'
                          : 'រកមិនឃើញទិន្នន័យ!',
                      style: _t(14.5, FontWeight.bold, _C.muted),
                    ),
                    if (_hasError) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _fetchDetailData,
                        style: FilledButton.styleFrom(
                          backgroundColor: _C.navy,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'ព្យាយាមម្តងទៀត',
                          style: _t(13, FontWeight.bold, Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final d = _expireDetail!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expire = _dateOnly(d.expireDate);
    final start = _dateOnly(d.startDate);
    final days = expire == null ? 99999 : expire.difference(today).inDays;
    final color = _tierColor(days);

    double? used;
    if (start != null && expire != null) {
      final total = expire.difference(start).inDays;
      if (total > 0) {
        used = (today.difference(start).inDays / total)
            .clamp(0.0, 1.0)
            .toDouble();
      }
    }

    final status = days == 99999
        ? 'មិនស្គាល់កាលបរិច្ឆេទ'
        : days < 0
        ? 'ផុតកំណត់ ${days.abs()} ថ្ងៃមកហើយ'
        : days == 0
        ? 'ផុតកំណត់ថ្ងៃនេះ'
        : 'នៅសល់ $days ថ្ងៃ';

    return RefreshIndicator(
      color: _C.navy,
      onRefresh: _fetchDetailData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _TopBar(
              onEdit: _navigateToEdit,
              onDelete: _isDeleting ? null : _confirmAndDelete,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
                child: Row(
                  children: [
                    _BigRing(days: days, color: color),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.productName,
                            style: _t(
                              19,
                              FontWeight.bold,
                              Colors.white,
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU ${d.productSku ?? '-'}',
                            style: _t(
                              12,
                              FontWeight.w500,
                              Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: _t(12, FontWeight.bold, Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (used != null) ...[
                    _Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'អាយុកាលស្តុក',
                                    style: _t(14, FontWeight.bold, _C.ink),
                                  ),
                                ),
                                Text(
                                  'បានប្រើ ${(used * 100).round()}%',
                                  style: _t(12.5, FontWeight.bold, color),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 10,
                                    color: color.withValues(alpha: 0.15),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: used,
                                    child: Container(height: 10, color: color),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fmtDate(start, d.startDate),
                                  style: _t(11.5, FontWeight.w500, _C.muted),
                                ),
                                Text(
                                  _fmtDate(expire, d.expireDate),
                                  style: _t(11.5, FontWeight.w600, color),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'ព័ត៌មានឡូត៍ និងកាលបរិច្ឆេទ',
                      style: _t(13.5, FontWeight.bold, _C.muted),
                    ),
                  ),
                  _Card(
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.qr_code_2_rounded,
                          title: 'លេខឡូត៍ (Batch No)',
                          value: d.batchNumber ?? '-',
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          icon: Icons.inventory_2_outlined,
                          title: 'ស្តុកសរុបក្នុងហាង',
                          value: '${d.productStock} ឯកតា',
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          icon: Icons.login_rounded,
                          title: 'ថ្ងៃចូលស្តុក (Start Date)',
                          value: _fmtDate(start, d.startDate),
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          icon: Icons.event_busy_rounded,
                          title: 'ថ្ងៃផុតកំណត់ (Expire Date)',
                          value: _fmtDate(expire, d.expireDate),
                          accent: color,
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
// Top bar / hero container
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? child;
  const _TopBar({required this.onEdit, required this.onDelete, this.child});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: top + 4),
      decoration: const BoxDecoration(
        color: _C.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    'ព័ត៌មានលម្អិត',
                    textAlign: TextAlign.center,
                    style: _t(16, FontWeight.bold, Colors.white),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: onDelete,
                      ),
                    if (onEdit == null && onDelete == null)
                      const SizedBox(width: 48),
                  ],
                ),
              ],
            ),
          ),
          if (child != null) child! else const SizedBox(height: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Ring
// ─────────────────────────────────────────────────────────────
class _BigRing extends StatelessWidget {
  final int days;
  final Color color;
  const _BigRing({required this.days, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = days < 0
        ? 1.0
        : (1 - (days / 30)).clamp(0.08, 1.0).toDouble();
    final label = days == 99999 ? '?' : (days < 0 ? '-${days.abs()}' : '$days');

    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _t(28, FontWeight.bold, color, height: 1.1)),
              Text('ថ្ងៃ', style: _t(11, FontWeight.w600, color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final arcRect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.14),
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Shared pieces
// ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 66, endIndent: 16, color: _C.line);
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? accent;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? _C.navy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: c, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: _t(12.5, FontWeight.w500, _C.muted)),
          ),
          const SizedBox(width: 8),
          Text(value, style: _t(14, FontWeight.bold, accent ?? _C.ink)),
        ],
      ),
    );
  }
}

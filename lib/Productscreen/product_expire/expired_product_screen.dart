import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/expire_product/api_expire_product.dart';

import 'models/expire_product_model.dart';
import 'create_product_expire_screen.dart';
import 'detail_expire_screen.dart'; // 👈 នាំចូល DetailExpireScreen របស់បង

// ─────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// Urgency logic (FEFO: first expired, first out)
// ─────────────────────────────────────────────────────────────
enum ExpiryFilter { all, expired, week, month }

class _Tier {
  final Color color;
  final ExpiryFilter group;
  const _Tier(this.color, this.group);
}

_Tier _tierFor(int days) {
  if (days < 0) return const _Tier(_C.expired, ExpiryFilter.expired);
  if (days <= 7) return const _Tier(_C.week, ExpiryFilter.week);
  if (days <= 30) return const _Tier(_C.month, ExpiryFilter.month);
  return const _Tier(_C.safe, ExpiryFilter.all);
}

class _Entry {
  final ExpireProductModel item;
  final DateTime? date;
  final int days;
  _Entry(this.item, this.date, this.days);
}

List<_Entry> _buildEntries(List<ExpireProductModel> items) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final list = items.map((item) {
    final parsed = DateTime.tryParse(item.expireDate);
    final d = parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
    final days = d == null ? 99999 : d.difference(today).inDays;
    return _Entry(item, d, days);
  }).toList();

  list.sort((a, b) => a.days.compareTo(b.days));
  return list;
}

String _fmtDate(DateTime? d, String fallback) {
  if (d == null) return fallback;
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

int _count(List<_Entry> e, ExpiryFilter f) =>
    e.where((x) => _tierFor(x.days).group == f).length;

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class ExpiredProductScreen extends StatefulWidget {
  const ExpiredProductScreen({super.key});

  @override
  State<ExpiredProductScreen> createState() => _ExpiredProductScreenState();
}

class _ExpiredProductScreenState extends State<ExpiredProductScreen> {
  final ApiExpireProduct apiexpireproduct = ApiExpireProduct();
  late Future<List<ExpireProductModel>> _futureExpiringProducts;
  final TextEditingController _searchCtrl = TextEditingController();

  ExpiryFilter _filter = ExpiryFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _futureExpiringProducts = apiexpireproduct.getAllExpireProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _futureExpiringProducts = apiexpireproduct.getAllExpireProducts();
    });
  }

  Future<void> _refresh() async {
    final f = apiexpireproduct.getAllExpireProducts();
    setState(() => _futureExpiringProducts = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: FutureBuilder<List<ExpireProductModel>>(
          future: _futureExpiringProducts,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final hasError = snapshot.hasError;
            final entries = (loading || hasError)
                ? <_Entry>[]
                : _buildEntries(snapshot.data ?? []);

            final q = _query.trim().toLowerCase();
            final visible = entries.where((e) {
              final okFilter = _filter == ExpiryFilter.all ||
                  _tierFor(e.days).group == _filter;
              if (!okFilter) return false;
              if (q.isEmpty) return true;
              final hay =
              '${e.item.productName} ${e.item.batchNumber ?? ''} ${e.item.productSku ?? ''}'
                  .toLowerCase();
              return hay.contains(q);
            }).toList();

            return RefreshIndicator(
              color: _C.navy,
              edgeOffset: 120,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _Hero(entries: entries)),

                  if (!loading && !hasError && entries.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Column(
                          children: [
                            _SearchField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _query = v),
                              onClear: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                            const SizedBox(height: 12),
                            _FilterRow(
                              selected: _filter,
                              entries: entries,
                              onSelect: (f) => setState(() => _filter = f),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: _C.navy),
                      ),
                    )
                  else if (hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MessageState(
                        icon: Icons.cloud_off_rounded,
                        color: _C.muted,
                        title: 'មិនអាចទាញទិន្នន័យបានទេ',
                        actionLabel: 'ព្យាយាមម្តងទៀត',
                        onAction: _loadData,
                      ),
                    )
                  else if (entries.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _MessageState(
                          icon: Icons.verified_rounded,
                          color: _C.safe,
                          title: 'ស្តុកទាំងអស់ល្អ មិនមានទំនិញជិតផុតកំណត់ទេ',
                        ),
                      )
                    else if (visible.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _MessageState(
                            icon: Icons.search_off_rounded,
                            color: _C.muted,
                            title: 'រកមិនឃើញទំនិញដែលត្រូវនឹងលក្ខខណ្ឌនេះទេ',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          sliver: SliverList.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _ProductCard(
                              entry: visible[i],
                              onTap: () async {
                                // 🚀 ចុចលើ Product នីមួយៗដើម្បីលោតទៅកាន់ DetailExpireScreen ដោយផ្ញើ ID ទៅជាមួយ
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailExpireScreen(expireId: visible[i].item.id),
                                  ),
                                );
                                // ប្រសិនបើមានការលុប ឬកែប្រែរួច ឱ្យทำการ Load ទិន្នន័យឡើងវិញ
                                if (result == true) {
                                  _loadData();
                                }
                              },
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateProductExpireScreen()),
            );
            if (result == true) _loadData();
          },
          backgroundColor: _C.navy,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_rounded),
          label: Text('បន្ថែមទំនិញ', style: _t(14, FontWeight.bold, Colors.white)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero: urgent count + proportional stock-health bar
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final List<_Entry> entries;
  const _Hero({required this.entries});

  @override
  Widget build(BuildContext context) {
    final expired = _count(entries, ExpiryFilter.expired);
    final week = _count(entries, ExpiryFilter.week);
    final month = _count(entries, ExpiryFilter.month);
    final safe = entries.length - expired - week - month; // ជួសជុលសញ្ញាដក

    final urgent = expired + week;
    final top = MediaQuery.of(context).padding.top;

    final segments = <(int, Color)>[
      (expired, _C.expired),
      (week, _C.week),
      (month, _C.month),
      (safe, _C.safe),
    ].where((s) => s.$1 > 0).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 26),
      decoration: const BoxDecoration(
        color: _C.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop())
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              Expanded(
                child: Text(
                  'ស្តុកជិតផុតកំណត់',
                  style: _t(19, FontWeight.bold, Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'ទំនិញដែលផុតមុន ត្រូវលក់ចេញមុន',
            style: _t(12, FontWeight.w500, Colors.white.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$urgent',
                style: _t(52, FontWeight.bold, Colors.white, height: 1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    urgent == 0
                        ? 'មិនមានទំនិញគួរឲ្យបារម្ភទេ'
                        : 'ទំនិញត្រូវដោះស្រាយ\n(ផុតហើយ ឬនៅសល់ក្រោម ៧ ថ្ងៃ)',
                    style: _t(12.5, FontWeight.w500, Colors.white.withValues(alpha: 0.85),
                        height: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: segments.isEmpty
                  ? Container(color: Colors.white.withValues(alpha: 0.15))
                  : Row(
                children: [
                  for (var i = 0; i < segments.length; i++) ...[
                    Expanded(
                      flex: segments[i].$1,
                      child: Container(color: segments[i].$2),
                    ),
                    if (i != segments.length - 1) const SizedBox(width: 2), // ជួសជុលសញ្ញាដក
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'សរុប ${entries.length} ទំនិញ',
            style: _t(11, FontWeight.w500, Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Search + filters
// ─────────────────────────────────────────────────────────────
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.line),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: _t(14, FontWeight.w500, _C.ink),
        decoration: InputDecoration(
          hintText: 'ស្វែងរកឈ្មោះ ឡូត៍ ឬ SKU',
          hintStyle: _t(13.5, FontWeight.w400, _C.muted),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.muted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: _C.muted),
            onPressed: onClear,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final ExpiryFilter selected;
  final List<_Entry> entries;
  final ValueChanged<ExpiryFilter> onSelect;

  const _FilterRow({
    required this.selected,
    required this.entries,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <(ExpiryFilter, String, Color, int)>[
      (ExpiryFilter.all, 'ទាំងអស់', _C.navy, entries.length),
      (ExpiryFilter.expired, 'ផុតហើយ', _C.expired, _count(entries, ExpiryFilter.expired)),
      (ExpiryFilter.week, 'ក្នុង ៧ ថ្ងៃ', _C.week, _count(entries, ExpiryFilter.week)),
      (ExpiryFilter.month, 'ក្នុង ៣០ ថ្ងៃ', _C.month, _count(entries, ExpiryFilter.month)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips) ...[
            _FilterChip(
              label: c.$2,
              count: c.$4,
              color: c.$3,
              active: selected == c.$1,
              onTap: () => onSelect(c.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: active ? color : _C.line),
        ),
        child: Row(
          children: [
            Text(label, style: _t(12.5, FontWeight.w600, active ? Colors.white : _C.ink)),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: _t(11.5, FontWeight.bold, active ? Colors.white : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Product card with urgency ring
// ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final _Entry entry;
  final VoidCallback onTap; // 👈 បន្ថែម Callback សម្រាប់ពេលចុចលើកាត

  const _ProductCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final color = _tierFor(entry.days).color;
    final days = entry.days;

    final status = days == 99999
        ? 'មិនស្គាល់កាលបរិច្ឆេទ'
        : days < 0
        ? 'ផុតកំណត់ ${days.abs()} ថ្ងៃមកហើយ'
        : days == 0
        ? 'ផុតកំណត់ថ្ងៃនេះ'
        : 'នៅសល់ $days ថ្ងៃ';

    // Fuller ring = more urgent
    final progress = days < 0 ? 1.0 : (1 - (days / 30)).clamp(0.08, 1.0).toDouble(); // ជួសជុលសញ្ញាដក

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap, // 👈 ភ្ជាប់មុខងារពេល Click
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.line.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: _C.navy.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _Ring(
                progress: progress,
                color: color,
                label: days == 99999
                    ? '?'
                    : days < 0
                    ? '-${days.abs()}'
                    : '$days',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: _t(15, FontWeight.bold, _C.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(status, style: _t(12, FontWeight.w600, color)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(icon: Icons.layers_outlined, text: 'ឡូត៍ ${item.batchNumber ?? '-'}'),
                        _Tag(icon: Icons.qr_code_2_rounded, text: '${item.productSku ?? '-'}'),
                        _Tag(
                          icon: Icons.inventory_2_outlined,
                          text: '${item.productStock} ឯកតា',
                          strong: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.event_rounded, size: 14, color: _C.muted),
                        const SizedBox(width: 5),
                        Text(
                          'ផុតថ្ងៃទី ${_fmtDate(entry.date, item.expireDate)}',
                          style: _t(11.5, FontWeight.w500, _C.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool strong;
  const _Tag({required this.icon, required this.text, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: strong ? _C.navy.withValues(alpha: 0.08) : _C.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: strong ? _C.navy : _C.muted),
          const SizedBox(width: 4),
          Text(
            text,
            style: _t(11, strong ? FontWeight.bold : FontWeight.w500,
                strong ? _C.navy : _C.muted),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double progress;
  final Color color;
  final String label;
  const _Ring({required this.progress, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _t(17, FontWeight.bold, color, height: 1.1)),
              Text('ថ្ងៃ', style: _t(9.5, FontWeight.w600, color)),
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
    const stroke = 5.5;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withValues(alpha: 0.14);
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress, false, arc); // ជួសជុលសញ្ញាគុណ
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Empty / error state
// ─────────────────────────────────────────────────────────────
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 42, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _t(14.5, FontWeight.bold, _C.muted, height: 1.5),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _C.navy,
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
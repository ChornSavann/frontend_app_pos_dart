import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_supplier.dart';
import '../models/supplier.dart';
import '../msg/appSnackBar.dart';
import 'create_supplier_screen.dart';
import 'edit_supplier_screen.dart';
import 'detail_supplier_screen.dart';

class _C {
  static const bg = Color(0xFFF0F4F4);
  static const ink = Color(0xFF0F1F1D);
  static const muted = Color(0xFF5E7476);
  static const line = Color(0xFFE3EBEA);
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
  static const inactive = Color(0xFF7B8794);
  static const danger = Color(0xFFD32F2F);
  static const hot = Color(0xFFEF5B16);
  static const hotB = Color(0xFFFF8A3D);

  static const avatarColors = <Color>[
    Color(0xFF0F766E),
    Color(0xFF3B6FD4),
    Color(0xFF7C4DCC),
    Color(0xFFD6457A),
    Color(0xFFB7791F),
    Color(0xFF0E7490),
  ];
}

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

enum _Filter { all, active, inactive }

class IndexSupplierScreen extends StatefulWidget {
  const IndexSupplierScreen({super.key});

  @override
  State<IndexSupplierScreen> createState() => _IndexSupplierScreenState();
}

class _IndexSupplierScreenState extends State<IndexSupplierScreen> {
  final ApiSupplier _apiService = ApiSupplier();
  final TextEditingController _searchController = TextEditingController();

  List<Supplier> _suppliers = [];
  bool _isLoading = true;
  bool _hasError = false;
  int? _deletingId;

  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final list = await _apiService.getAllSuppliers();
      if (!mounted) return;
      setState(() {
        _suppliers = list;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
      if (!mounted) return;
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(Supplier supplier) async {
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
                  color: _C.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: _C.danger, size: 34),
              ),
              const SizedBox(height: 16),
              Text('Delete supplier', style: _t(18, FontWeight.w800, _C.ink)),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${supplier.name}"?',
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
                      child: Text('Cancel', style: _t(14, FontWeight.w800, _C.ink)),
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
                      child: Text('Delete', style: _t(14, FontWeight.w800, Colors.white)),
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

    setState(() => _deletingId = supplier.id);
    try {
      await _apiService.deleteSupplier(supplier.id!);
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Supplier deleted successfully!');
      await _loadSuppliers(silent: true);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _edit(Supplier supplier) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditSupplierScreen(supplier: supplier)),
    );
    if (result == true) _loadSuppliers(silent: true);
  }

  Future<void> _create() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSupplierScreen()),
    );
    if (result == true) _loadSuppliers(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final total = _suppliers.length;
    final activeCount = _suppliers.where((s) => s.isActive).length;
    final inactiveCount = total - activeCount;
    final q = _query.trim().toLowerCase();

    final visible = _suppliers.where((s) {
      final okFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.active => s.isActive,
        _Filter.inactive => !s.isActive,
      };
      if (!okFilter) return false;
      if (q.isEmpty) return true;
      return '${s.name} ${s.company ?? ''} ${s.phone ?? ''}'.toLowerCase().contains(q);
    }).toList();

    final hasData = !_isLoading && !_hasError && _suppliers.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: RefreshIndicator(
          color: _C.brand,
          edgeOffset: 120,
          onRefresh: () => _loadSuppliers(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  total: total,
                  active: activeCount,
                  showSearch: hasData,
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  onRefresh: _loadSuppliers,
                ),
              ),
              if (hasData)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedBar(
                    child: _FilterBar(
                      selected: _filter,
                      counts: {
                        _Filter.all: total,
                        _Filter.active: activeCount,
                        _Filter.inactive: inactiveCount,
                      },
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
                    title: 'Could not load suppliers',
                    actionLabel: 'Try again',
                    onAction: _loadSuppliers,
                  ),
                )
              else if (_suppliers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.local_shipping_outlined,
                      color: _C.brand,
                      title: 'No suppliers found',
                      subtitle: 'Add your first supplier to get started.',
                      actionLabel: 'Add supplier',
                      onAction: _create,
                    ),
                  )
                else if (visible.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MessageState(
                        icon: Icons.search_off_rounded,
                        color: _C.muted,
                        title: 'រកមិនឃើញ Supplier ដែលបានស្វែងរកទេ',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      sliver: SliverList.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final s = visible[i];
                          return _FadeSlide(
                            index: i,
                            child: _SupplierCard(
                              supplier: s,
                              color: _C.avatarColors[s.name.hashCode.abs() % _C.avatarColors.length],
                              deleting: _deletingId != null && _deletingId == s.id,
                              onOpen: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailSupplierScreen(supplier: s),
                                ),
                              ),
                              onEdit: () => _edit(s),
                              onDelete: () => _confirmDelete(s),
                              onCopyPhone: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: s.phone ?? ''));
                                AppSnackBar.showSuccess(context, 'Phone copied');
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
        floatingActionButton: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.hot, _C.hotB]),
            shape: BoxShape.circle,
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
            child: InkResponse(
              containedInkWell: true,
              highlightShape: BoxShape.circle,
              onTap: _create,
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
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
  const _FilterBar({required this.selected, required this.counts, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const items = <(_Filter, String)>[
      (_Filter.all, 'All'),
      (_Filter.active, 'Active'),
      (_Filter.inactive, 'Inactive'),
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
                  Text(it.$2,
                      style: _t(13, FontWeight.w700, sel ? Colors.white : _C.ink)),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white.withValues(alpha: 0.22) : _C.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${counts[it.$1] ?? 0}',
                        style: _t(11.5, FontWeight.w800, sel ? Colors.white : _C.muted)),
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
// Hero
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final int total;
  final int active;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  const _Hero({
    required this.total,
    required this.active,
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
                            Text('Suppliers',
                                style: _t(21, FontWeight.w800, Colors.white, spacing: -0.3)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.local_shipping_outlined,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 5),
                                Text('$total suppliers',
                                    style: _t(12.5, FontWeight.w600,
                                        Colors.white.withValues(alpha: 0.9))),
                                const SizedBox(width: 10),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7CFFB2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text('$active active',
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
                            hintText: 'ស្វែងរកឈ្មោះ ក្រុមហ៊ុន ឬលេខទូរស័ព្ទ',
                            hintStyle: _t(13.5, FontWeight.w400, _C.muted),
                            prefixIcon: const Icon(Icons.search_rounded, color: _C.muted),
                            suffixIcon: controller.text.isEmpty
                                ? null
                                : IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 20, color: _C.muted),
                              onPressed: onClear,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
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

// ─────────────────────────────────────────────────────────────
// Supplier card
// ─────────────────────────────────────────────────────────────
enum _Action { edit, delete }

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final Color color;
  final bool deleting;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopyPhone;

  const _SupplierCard({
    required this.supplier,
    required this.color,
    required this.deleting,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onCopyPhone,
  });

  @override
  Widget build(BuildContext context) {
    final active = supplier.isActive;
    final c = active ? color : _C.inactive;
    final name = supplier.name;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'S';
    final company = supplier.company?.trim() ?? '';
    final phone = supplier.phone?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.heroA.withValues(alpha: active ? 0.07 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: deleting ? null : onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.withValues(alpha: 0.85), c],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(initial, style: _t(21, FontWeight.w800, Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(15.5, FontWeight.w800, active ? _C.ink : _C.muted)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (active ? _C.brand : _C.inactive).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5.5,
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    color: active ? _C.brand : _C.inactive,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(active ? 'Active' : 'Inactive',
                                    style: _t(10, FontWeight.w800,
                                        active ? _C.brand : _C.inactive)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 14, color: _C.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(company,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(12.5, FontWeight.w500, _C.muted)),
                            ),
                          ],
                        ),
                      ],
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: onCopyPhone,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _C.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_outlined, size: 13, color: _C.brand),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(phone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _t(12, FontWeight.w700, _C.ink)),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy_rounded, size: 12, color: _C.muted),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (deleting)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.danger),
                    ),
                  )
                else
                  PopupMenuButton<_Action>(
                    tooltip: 'More',
                    icon: const Icon(Icons.more_vert_rounded, color: _C.muted),
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (a) {
                      switch (a) {
                        case _Action.edit:
                          onEdit();
                        case _Action.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _Action.edit,
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18, color: _C.brand),
                            const SizedBox(width: 10),
                            Text('Edit', style: _t(13.5, FontWeight.w700, _C.ink)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline_rounded, size: 18, color: _C.danger),
                            const SizedBox(width: 10),
                            Text('Delete', style: _t(13.5, FontWeight.w700, _C.danger)),
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
          5,
              (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
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
                      _bar(130, 15),
                      const SizedBox(height: 8),
                      _bar(100, 11),
                      const SizedBox(height: 8),
                      _bar(90, 18),
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
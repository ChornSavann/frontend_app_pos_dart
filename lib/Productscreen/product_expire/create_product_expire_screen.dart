
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/expire_product/api_expire_product.dart';
import '../../models/Product.dart';
import '../../msg/appSnackBar.dart';

class _C {
  static const bg = Color(0xFFF2F4F8);
  static const ink = Color(0xFF142033);
  static const muted = Color(0xFF6C7A8E);
  static const line = Color(0xFFE0E6EE);
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

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Adds months without overflowing into the next month (Jan 31 + 1 month = Feb 28/29).
DateTime _addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final year = d.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > lastDay ? lastDay : d.day);
}

class CreateProductExpireScreen extends StatefulWidget {
  const CreateProductExpireScreen({super.key});

  @override
  State<CreateProductExpireScreen> createState() =>
      _CreateProductExpireScreenState();
}

class _CreateProductExpireScreenState extends State<CreateProductExpireScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiExpireProduct _apiService = ApiExpireProduct();

  List<Product> _products = [];
  Product? _selectedProduct;

  int? get _selectedProductId => _selectedProduct?.id;
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _expireCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _expireDate;

  bool _isLoading = false;
  bool _isLoadingProducts = true;
  bool _productsError = false;

  @override
  void initState() {
    super.initState();
    _setStart(_dateOnly(DateTime.now()));
    _fetchProducts();
  }

  @override
  void dispose() {
    _batchController.dispose();
    _startCtrl.dispose();
    _expireCtrl.dispose();
    super.dispose();
  }

  void _setStart(DateTime? d) {
    _startDate = d;
    _startCtrl.text = d == null ? '' : _fmt(d);
  }

  void _setExpire(DateTime? d) {
    _expireDate = d;
    _expireCtrl.text = d == null ? '' : _fmt(d);
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = false;
    });

    try {
      final availableProducts = await _apiService.getAvailableProducts();

      if (!mounted) return;

      setState(() {
        _products = availableProducts;
        _isLoadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _productsError = true;
      });
    }
  }

  Future<DateTime?> _pickDate(DateTime? current, {DateTime? fallback}) {
    return showDatePicker(
      context: context,
      initialDate: current ?? fallback ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.navy,
            onPrimary: Colors.white,
            onSurface: _C.ink,
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _submitExpireProduct() async {
    FocusScope.of(context).unfocus();

    if (_selectedProductId == null) {
      AppSnackBar.showError(context, 'សូមជ្រើសរើសផលិតផលជាមុនសិន!');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final bool success = await _apiService.createExpireProductApi(
        productId: _selectedProductId!,
        startDate: _iso(_startDate!),
        expireDate: _iso(_expireDate!),
        batchNumber: _batchController.text.trim().isEmpty
            ? null
            : _batchController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        AppSnackBar.showSuccess(context, 'បានរក្សាទុកថ្ងៃផុតកំណត់ជោគជ័យ!');
        Navigator.pop(context, true);
      } else {
        AppSnackBar.showError(context, 'បរាជ័យក្នុងការរក្សាទុក!');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'មានបញ្ហាក្នុងការតភ្ជាប់: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration({
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: _t(13.5, FontWeight.w400, _C.muted),
      errorStyle: _t(11.5, FontWeight.w500, _C.expired),
      prefixIcon: Icon(icon, color: _C.navy, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _C.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(_C.line),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(_C.navy, 1.6),
      errorBorder: border(_C.expired),
      focusedErrorBorder: border(_C.expired, 1.6),
    );
  }


  @override
  Widget build(BuildContext context) {
    final showForm = !_isLoadingProducts && !_productsError;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _Header(
              product: _selectedProduct,
              enabled: showForm,
              onTap: _showProductPicker,
            ),
            Expanded(child: _buildContent()),
          ],
        ),
        bottomNavigationBar: !showForm
            ? null
            : Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: _C.navy.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _submitExpireProduct,
                    style: FilledButton.styleFrom(
                      backgroundColor: _C.navy,
                      disabledBackgroundColor: _C.navy.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                    label: Text(
                      _isLoading ? 'កំពុងរក្សាទុក...' : 'រក្សាទុក',
                      style: _t(15, FontWeight.bold, Colors.white),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator(color: _C.navy));
    }

    if (_productsError) {
      return Center(
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
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 42,
                  color: _C.muted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'មិនអាចទាញបញ្ជីផលិតផលបានទេ',
                style: _t(14.5, FontWeight.bold, _C.muted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _fetchProducts,
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
          ),
        ),
      );
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(text: 'លេខឡូត៍ (Batch Number)'),
                    TextFormField(
                      controller: _batchController,
                      style: _t(14, FontWeight.w600, _C.ink),
                      textInputAction: TextInputAction.done,
                      decoration: _decoration(
                        icon: Icons.qr_code_2_rounded,
                        hint: 'ឧ. BATCH-001 (ស្រេចចិត្ត)',
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel(
                      text: 'ថ្ងៃចូលស្តុក (Start Date)',
                      required: true,
                    ),
                    TextFormField(
                      controller: _startCtrl,
                      readOnly: true,
                      style: _t(14, FontWeight.w600, _C.ink),
                      decoration: _decoration(
                        icon: Icons.login_rounded,
                        hint: 'ជ្រើសរើសថ្ងៃចូលស្តុក',
                        suffix: const Icon(
                          Icons.expand_more_rounded,
                          color: _C.muted,
                        ),
                      ),
                      onTap: () async {
                        final picked = await _pickDate(_startDate);
                        if (picked != null && mounted) {
                          setState(() => _setStart(picked));
                        }
                      },
                      validator: (_) =>
                          _startDate == null ? 'សូមជ្រើសរើសថ្ងៃចូលស្តុក' : null,
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel(
                      text: 'ថ្ងៃផុតកំណត់ (Expire Date)',
                      required: true,
                    ),
                    TextFormField(
                      controller: _expireCtrl,
                      readOnly: true,
                      style: _t(14, FontWeight.w600, _C.ink),
                      decoration: _decoration(
                        icon: Icons.event_busy_rounded,
                        hint: 'ជ្រើសរើសថ្ងៃផុតកំណត់',
                        suffix: const Icon(
                          Icons.expand_more_rounded,
                          color: _C.muted,
                        ),
                      ),
                      onTap: () async {
                        final picked = await _pickDate(
                          _expireDate,
                          fallback: (_startDate ?? DateTime.now()).add(
                            const Duration(days: 30),
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() => _setExpire(picked));
                        }
                      },
                      validator: (_) {
                        if (_expireDate == null) {
                          return 'សូមជ្រើសរើសថ្ងៃផុតកំណត់';
                        }
                        if (_startDate != null &&
                            _expireDate!.isBefore(_startDate!)) {
                          return 'ថ្ងៃផុតកំណត់ត្រូវនៅក្រោយថ្ងៃចូលស្តុក';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _QuickPicks(
                      start: _startDate ?? _dateOnly(DateTime.now()),
                      selected: _expireDate,
                      onPick: (d) => setState(() => _setExpire(d)),
                    ),
                  ],
                ),
              ),
            ),
            if (_expireDate != null) ...[
              const SizedBox(height: 16),
              _Preview(start: _startDate, expire: _expireDate!),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────── Product picker sheet ─────────────────────
  void _showProductPicker() {
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final q = query.trim().toLowerCase();
            final filtered = _products.where((p) {
              if (q.isEmpty) return true;
              final name = p.name ?? '';
              final sku = p.sku ?? '';
              final hay = '$name $sku'.toLowerCase();
              return hay.contains(q);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _C.line,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 14, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'ជ្រើសរើសផលិតផល',
                              style: _t(17, FontWeight.bold, _C.ink),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(sheetContext),
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: _C.bg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: _C.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: TextField(
                        onChanged: (v) => setSheet(() => query = v),
                        style: _t(14, FontWeight.w500, _C.ink),
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកឈ្មោះ ឬ SKU',
                          hintStyle: _t(13.5, FontWeight.w400, _C.muted),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _C.muted,
                          ),
                          filled: true,
                          fillColor: _C.bg,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  q.isEmpty
                                      ? 'ផលិតផលទាំងអស់ត្រូវបានកត់ត្រារួចហើយ'
                                      : 'រកមិនឃើញផលិតផលទេ',
                                  textAlign: TextAlign.center,
                                  style: _t(
                                    14,
                                    FontWeight.bold,
                                    _C.muted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final prod = filtered[i];
                                final isSelected =
                                    _selectedProductId == prod.id;
                                final imageUrl = prod.imageUrl;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() => _selectedProduct = prod);
                                    Navigator.pop(sheetContext);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _C.navy.withValues(alpha: 0.07)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? _C.navy : _C.line,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            color: _C.bg,
                                            child:
                                                (imageUrl != null &&
                                                    imageUrl
                                                        .toString()
                                                        .isNotEmpty)
                                                ? Image.network(
                                                    imageUrl.toString(),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => const Icon(
                                                          Icons
                                                              .image_not_supported_outlined,
                                                          color: _C.muted,
                                                          size: 20,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.inventory_2_outlined,
                                                    color: _C.navy,
                                                    size: 22,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${prod.name ?? ''}',
                                                style: _t(
                                                  14,
                                                  FontWeight.bold,
                                                  _C.ink,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'SKU ${prod.sku ?? 'N/A'}   តម្លៃ \$${prod.sellingPrice}',
                                                style: _t(
                                                  11.5,
                                                  FontWeight.w500,
                                                  _C.muted,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color: isSelected ? _C.navy : _C.line,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header with the product selector
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Product? product;
  final bool enabled;
  final VoidCallback onTap;

  const _Header({
    required this.product,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final selected = product != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 4, 8, 22),
      decoration: const BoxDecoration(
        color: _C.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
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
                  'កត់ត្រាថ្ងៃផុតកំណត់',
                  textAlign: TextAlign.center,
                  style: _t(16, FontWeight.bold, Colors.white),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Material(
              color: Colors.white.withValues(alpha: selected ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: enabled ? onTap : null,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: selected ? 0.18 : 0.3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          selected
                              ? Icons.inventory_2_rounded
                              : Icons.add_box_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected
                                  ? '${product!.name ?? ''}'
                                  : 'ជ្រើសរើសផលិតផល',
                              style: _t(
                                15.5,
                                FontWeight.bold,
                                Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              selected
                                  ? 'SKU ${product!.sku ?? 'N/A'}   \$${product!.sellingPrice}'
                                  : 'ចុចដើម្បីជ្រើសរើសទំនិញដែលត្រូវកត់ត្រា',
                              style: _t(
                                11.5,
                                FontWeight.w500,
                                Colors.white.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.swap_horiz_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Quick expire-date presets
// ─────────────────────────────────────────────────────────────
class _QuickPicks extends StatelessWidget {
  final DateTime start;
  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  const _QuickPicks({
    required this.start,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final options = <(String, DateTime)>[
      ('+៧ ថ្ងៃ', start.add(const Duration(days: 7))),
      ('+៣០ ថ្ងៃ', start.add(const Duration(days: 30))),
      ('+៣ ខែ', _addMonths(start, 3)),
      ('+៦ ខែ', _addMonths(start, 6)),
      ('+១ ឆ្នាំ', _addMonths(start, 12)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('រហ័ស', style: _t(12, FontWeight.w600, _C.muted)),
        for (final o in options)
          Builder(
            builder: (context) {
              final active = selected != null && _dateOnly(selected!) == o.$2;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onPick(o.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active ? _C.navy : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? _C.navy : _C.line),
                  ),
                  child: Text(
                    o.$1,
                    style: _t(
                      12,
                      FontWeight.w600,
                      active ? Colors.white : _C.ink,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Live preview
// ─────────────────────────────────────────────────────────────
class _Preview extends StatelessWidget {
  final DateTime? start;
  final DateTime expire;
  const _Preview({required this.start, required this.expire});

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final days = expire.difference(today).inDays;
    final color = _tierColor(days);

    final text = days < 0
        ? 'ផុតកំណត់ ${days.abs()} ថ្ងៃមកហើយ'
        : days == 0
        ? 'ផុតកំណត់ថ្ងៃនេះ'
        : 'នឹងផុតកំណត់ក្នុង $days ថ្ងៃ';

    double? used;
    if (start != null) {
      final total = expire.difference(start!).inDays;
      if (total > 0) {
        used = (today.difference(start!).inDays / total)
            .clamp(0.0, 1.0)
            .toDouble();
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  days < 0 ? Icons.warning_rounded : Icons.timer_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ការមើលជាមុន',
                      style: _t(11.5, FontWeight.w500, _C.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(text, style: _t(15, FontWeight.bold, color)),
                  ],
                ),
              ),
            ],
          ),
          if (used != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 8, color: color.withValues(alpha: 0.18)),
                  FractionallySizedBox(
                    widthFactor: used,
                    child: Container(height: 8, color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(start!), style: _t(11, FontWeight.w500, _C.muted)),
                Text(_fmt(expire), style: _t(11, FontWeight.w600, color)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small shared widgets
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
        borderRadius: BorderRadius.circular(22),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel({required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: _t(13, FontWeight.bold, _C.ink),
          children: [
            if (required)
              TextSpan(text: '  *', style: _t(13, FontWeight.bold, _C.expired)),
          ],
        ),
      ),
    );
  }
}

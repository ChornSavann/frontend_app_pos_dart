import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/Productscreen/models/product_promotion_model.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/models/Product.dart';
import '../../api/promotion/api_promotion.dart';

class UpdatePromotionScreen extends StatefulWidget {
  final ProductPromotionModel promotion;

  const UpdatePromotionScreen({super.key, required this.promotion});

  @override
  State<UpdatePromotionScreen> createState() => _UpdatePromotionScreenState();
}

class _UpdatePromotionScreenState extends State<UpdatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productKey = GlobalKey<FormFieldState<int>>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _codeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _valueController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;

  late int _selectedProductId;
  late String _selectedDiscountType;
  late bool _isActive;
  bool _isLoading = false;
  bool _saved = false;

  List<Product> _products = [];
  bool _isLoadingProducts = true;

  late final Map<String, Object?> _initial;

  final ApiPromotion _apiPromotion = ApiPromotion();
  final ApiProduct _apiProduct = ApiProduct();

  bool get _isPercent => _selectedDiscountType == 'percentage';

  Product? get _selectedProduct {
    for (final p in _products) {
      if (p.id == _selectedProductId) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;

    _titleController = TextEditingController(text: p.title);
    _descriptionController = TextEditingController(text: p.description ?? '');
    _codeController = TextEditingController(text: p.promotionCode);
    _quantityController = TextEditingController(text: p.quantity?.toString() ?? '');
    _valueController = TextEditingController(text: pNum(p.discountValue));
    _startDateController = TextEditingController(text: p.startDate ?? '');
    _endDateController = TextEditingController(text: p.endDate ?? '');

    _selectedProductId = p.productId;
    _selectedDiscountType = p.discountType;
    _isActive = p.isActive;

    _initial = _snapshot();

    for (final c in [
      _titleController,
      _descriptionController,
      _codeController,
      _quantityController,
      _valueController,
      _startDateController,
      _endDateController,
    ]) {
      c.addListener(_onEdited);
    }

    _loadProducts();
  }

  void _onEdited() {
    if (mounted) setState(() {});
  }

  Map<String, Object?> _snapshot() => {
    'title': _titleController.text.trim(),
    'desc': _descriptionController.text.trim(),
    'code': _codeController.text.trim().toUpperCase(),
    'qty': _quantityController.text.trim(),
    'value': double.tryParse(_valueController.text.trim()),
    'start': _startDateController.text,
    'end': _endDateController.text,
    'product': _selectedProductId,
    'type': _selectedDiscountType,
    'active': _isActive,
  };

  bool get _hasChanges => !mapEquals(_initial, _snapshot());

  Future<void> _loadProducts() async {
    try {
      final products = await _apiProduct.fetchProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _quantityController.dispose();
    _valueController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────
  DateTime? _parse(TextEditingController c) => DateTime.tryParse(c.text);

  void _setText(TextEditingController c, DateTime d) {
    c.text = d.toString().substring(0, 19);
  }

  void _extendEnd(int days) {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final end = _parse(_endDateController);
    final base = (end != null && end.isAfter(now)) ? end : now;
    _setText(_endDateController, base.add(Duration(days: days)));
  }

  Future<void> _pickProduct() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PromoProductSheet(products: _products, selectedId: _selectedProductId),
    );
    if (picked != null) {
      setState(() => _selectedProductId = picked.id);
      _productKey.currentState?.didChange(picked.id);
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    var initial = _parse(controller) ?? DateTime.now();
    if (initial.isBefore(DateTime(2025)) || initial.isAfter(DateTime(2035))) {
      initial = DateTime.now();
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: PC.brand,
            onPrimary: Colors.white,
            onSurface: PC.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;

    _setText(
      controller,
      DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: PC.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _updatePromotion() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    final start = _parse(_startDateController);
    final end = _parse(_endDateController);
    if (start != null && end != null && end.isBefore(start)) {
      _showError('End date must be after the start date.');
      return;
    }

    setState(() => _isLoading = true);

    final updateData = {
      'product_id': _selectedProductId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'promotion_code': _codeController.text.trim().toUpperCase(),
      'quantity': _quantityController.text.isNotEmpty
          ? int.tryParse(_quantityController.text)
          : null,
      'discount_type': _selectedDiscountType,
      'discount_value': double.parse(_valueController.text.trim()),
      'start_date': _startDateController.text.isNotEmpty ? _startDateController.text : null,
      'end_date': _endDateController.text.isNotEmpty ? _endDateController.text : null,
      'is_active': _isActive,
    };

    final success = await _apiPromotion.updatePromotionStatus(widget.promotion.id, updateData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      HapticFeedback.lightImpact();
      _saved = true;
      _showSuccessDialog('Promotion updated and stock adjusted successfully!');
    } else {
      _showError('Failed to update promotion.');
    }
  }

  Future<bool> _confirmDiscard() async {
    final leave = await showDialog<bool>(
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
                  color: PC.hot.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_off_rounded, color: PC.hot, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Discard changes?', style: pt(18, FontWeight.w800, PC.ink)),
              const SizedBox(height: 8),
              Text(
                'You have unsaved changes. If you leave now they will be lost.',
                textAlign: TextAlign.center,
                style: pt(13.5, FontWeight.w400, PC.muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PC.ink,
                        side: const BorderSide(color: PC.line),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Keep editing', style: pt(13.5, FontWeight.w800, PC.ink)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: PC.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Discard', style: pt(13.5, FontWeight.w800, Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return leave == true;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: PC.brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: PC.brand, size: 52),
                ),
              ),
              const SizedBox(height: 18),
              Text('Promotion updated', style: pt(19, FontWeight.w800, PC.ink)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: pt(13.5, FontWeight.w400, PC.muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: PC.brand,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true); // back to list and refresh
                  },
                  child: Text('Done', style: pt(15, FontWeight.w800, Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final end = _parse(_endDateController);
    final today = DateTime.now();
    final expired =
        end != null && end.isBefore(DateTime(today.year, today.month, today.day));

    return PopScope(
      canPop: _saved || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave && mounted) {
          setState(() => _saved = true); // allow the pop
          Navigator.of(context).pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: PC.bg,
          body: Form(
            key: _formKey,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: PromoFormHero(
                      title: 'Edit promotion',
                      subtitle: widget.promotion.promotionCode,
                      preview: _buildPreview(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (expired) ...[
                          _banner(
                            icon: Icons.event_busy_rounded,
                            color: PC.error,
                            text: 'This promotion has expired. Extend the end date to run it again.',
                          ),
                          const SizedBox(height: 14),
                        ],
                        _buildInfoSection(),
                        const SizedBox(height: 14),
                        _buildDiscountSection(),
                        const SizedBox(height: 14),
                        _buildScheduleSection(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: PromoSaveBar(
            label: _hasChanges ? 'Save changes' : 'No changes yet',
            icon: _hasChanges ? Icons.check_rounded : Icons.edit_note_rounded,
            loading: _isLoading,
            enabled: _hasChanges,
            onTap: _updatePromotion,
          ),
        ),
      ),
    );
  }

  Widget _banner({required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: pt(12.5, FontWeight.w600, PC.ink, height: 1.45)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final v = double.tryParse(_valueController.text.trim());
    final badge = v == null ? '—' : (_isPercent ? '-${pNum(v)}%' : '-\$${pNum(v)}');
    return PromoPreviewCard(
      badge: badge,
      title: _titleController.text.trim(),
      productName: _selectedProduct?.name ??
          widget.promotion.product?.name ??
          'Product #$_selectedProductId',
      code: _codeController.text.trim().toUpperCase(),
    );
  }

  // ── Section 1 ──────────────────────────────────────────────
  Widget _buildInfoSection() {
    final product = _selectedProduct;
    return PromoSection(
      step: 1,
      title: 'Promotion information',
      icon: Icons.info_outline_rounded,
      children: [
        promoLabel('Product'),
        FormField<int>(
          key: _productKey,
          initialValue: _selectedProductId,
          validator: (_) => null,
          builder: (state) => _isLoadingProducts
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: LinearProgressIndicator(color: PC.brand, minHeight: 3),
          )
              : PromoProductTile(
            name: product?.name ?? widget.promotion.product?.name,
            stock: product == null ? null : '${product.stockQuantity}',
            hasError: state.hasError,
            onTap: _pickProduct,
          ),
        ),
        const SizedBox(height: 16),
        promoLabel('Title'),
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: promoInput('e.g. Summer Sale', Icons.title_rounded),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
        ),
        const SizedBox(height: 16),
        promoLabel('Promotion code'),
        TextFormField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          style: pt(14, FontWeight.w800, PC.ink, spacing: 1),
          decoration: promoInput('e.g. SUMMER2026', Icons.confirmation_number_outlined),
          validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Promotion code is required' : null,
        ),
        const SizedBox(height: 16),
        promoLabel('Description', optional: true),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: promoInput('Tell customers about this offer', Icons.notes_rounded),
        ),
      ],
    );
  }

  // ── Section 2 ──────────────────────────────────────────────
  Widget _buildDiscountSection() {
    const quick = [5, 10, 15, 20, 25, 50];
    final current = double.tryParse(_valueController.text.trim());
    return PromoSection(
      step: 2,
      title: 'Discount & stock',
      icon: Icons.local_offer_outlined,
      children: [
        promoLabel('Discount type'),
        PromoTypeToggle(
          isPercent: _isPercent,
          onChanged: (percent) {
            HapticFeedback.selectionClick();
            setState(() => _selectedDiscountType = percent ? 'percentage' : 'fixed');
          },
        ),
        const SizedBox(height: 16),
        promoLabel('Discount value'),
        TextFormField(
          controller: _valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: pt(16, FontWeight.w800, PC.ink),
          decoration: promoInput(
            _isPercent ? 'e.g. 15' : 'e.g. 0.50',
            _isPercent ? Icons.percent_rounded : Icons.attach_money_rounded,
          ),
          validator: (v) {
            final n = double.tryParse((v ?? '').trim());
            if (n == null || n <= 0) return 'Enter a valid discount value';
            if (_isPercent && n > 100) return 'Percentage cannot exceed 100';
            return null;
          },
        ),
        if (_isPercent) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in quick)
                PromoQuickChip(
                  label: '$q%',
                  selected: current == q.toDouble(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _valueController.text = '$q';
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        promoLabel('Promo stock', optional: true),
        TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: promoInput('Leave empty for unlimited', Icons.inventory_2_outlined),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.info_outline_rounded, size: 14, color: PC.muted),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Changing the promo stock also adjusts the product stock.',
                style: pt(11.5, FontWeight.w500, PC.muted, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Section 3 ──────────────────────────────────────────────
  Widget _buildScheduleSection() {
    return PromoSection(
      step: 3,
      title: 'Schedule & status',
      icon: Icons.calendar_today_outlined,
      children: [
        promoLabel('Extend end date by'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PromoQuickChip(label: '+7 days', onTap: () => _extendEnd(7)),
            PromoQuickChip(label: '+30 days', onTap: () => _extendEnd(30)),
            PromoQuickChip(label: '+90 days', onTap: () => _extendEnd(90)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PromoDateTile(
                label: 'Starts',
                value: _parse(_startDateController),
                onTap: () => _selectDateTime(_startDateController),
                onClear: _startDateController.clear,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PromoDateTile(
                label: 'Ends',
                value: _parse(_endDateController),
                onTap: () => _selectDateTime(_endDateController),
                onClear: _endDateController.clear,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          decoration: BoxDecoration(
            color: (_isActive ? PC.brand : PC.muted).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (_isActive ? PC.brand : PC.muted).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isActive ? Icons.bolt_rounded : Icons.pause_circle_outline_rounded,
                color: _isActive ? PC.brand : PC.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isActive ? 'Active' : 'Inactive',
                        style: pt(14, FontWeight.w800, PC.ink)),
                    Text(
                      _isActive ? 'Customers can use this promotion' : 'Promotion is paused',
                      style: pt(12, FontWeight.w500, PC.muted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isActive,
                activeThumbColor: Colors.white,
                activeTrackColor: PC.brand,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCBD5D8),
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tokens & helpers
// ─────────────────────────────────────────────────────────────
class PC {
  static const bg = Color(0xFFF0F4F4);
  static const ink = Color(0xFF0F1F1D);
  static const muted = Color(0xFF5E7476);
  static const line = Color(0xFFE0E9E8);
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
  static const hot = Color(0xFFEF5B16);
  static const hotB = Color(0xFFFF8A3D);
  static const error = Color(0xFFD32F2F);
}

TextStyle pt(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

String pNum(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String prettyDate(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${d.day} ${_months[d.month - 1]} ${d.year} · $h:$m $ap';
}

Widget promoLabel(String text, {bool optional = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 8, left: 2),
  child: Row(
    children: [
      Text(text, style: pt(12.5, FontWeight.w800, PC.ink)),
      if (optional) ...[
        const SizedBox(width: 6),
        Text('Optional', style: pt(11, FontWeight.w500, PC.muted)),
      ],
    ],
  ),
);

InputDecoration promoInput(String hint, IconData icon, {Widget? suffix}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: pt(13.5, FontWeight.w400, PC.muted.withValues(alpha: 0.8)),
    prefixIcon: Icon(icon, color: PC.brand, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: PC.bg.withValues(alpha: 0.6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: b(PC.line),
    enabledBorder: b(PC.line),
    focusedBorder: b(PC.brand, 1.6),
    errorBorder: b(PC.error),
    focusedErrorBorder: b(PC.error, 1.6),
    errorStyle: pt(12, FontWeight.w500, PC.error),
  );
}

// ─────────────────────────────────────────────────────────────
// Hero + live preview
// ─────────────────────────────────────────────────────────────
class PromoFormHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget preview;
  const PromoFormHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.preview,
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
            colors: [PC.heroA, PC.heroB],
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
                            Text(title,
                                style: pt(21, FontWeight.w800, Colors.white, spacing: -0.3)),
                            const SizedBox(height: 2),
                            Text(subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: pt(12.5, FontWeight.w500,
                                    Colors.white.withValues(alpha: 0.85))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  preview,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoPreviewCard extends StatelessWidget {
  final String badge;
  final String title;
  final String productName;
  final String code;
  const PromoPreviewCard({
    super.key,
    required this.badge,
    required this.title,
    required this.productName,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [PC.hot, PC.hotB],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: PC.hot.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(badge, style: pt(17, FontWeight.w800, Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Promotion title' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pt(15, FontWeight.w800,
                      title.isEmpty ? Colors.white.withValues(alpha: 0.6) : Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pt(12, FontWeight.w500, Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(code.isEmpty ? 'CODE' : code,
                          style: pt(11, FontWeight.w800, Colors.white, spacing: 0.8)),
                    ],
                  ),
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
// Section card, toggle, chips, date tile
// ─────────────────────────────────────────────────────────────
class PromoSection extends StatelessWidget {
  final int step;
  final String title;
  final IconData icon;
  final List<Widget> children;
  const PromoSection({
    super.key,
    required this.step,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PC.heroA.withValues(alpha: 0.07),
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
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [PC.brand, PC.heroB]),
                  shape: BoxShape.circle,
                ),
                child: Text('$step', style: pt(13, FontWeight.w800, Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: pt(16, FontWeight.w800, PC.ink))),
              Icon(icon, size: 20, color: PC.brand.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class PromoTypeToggle extends StatelessWidget {
  final bool isPercent;
  final ValueChanged<bool> onChanged;
  const PromoTypeToggle({super.key, required this.isPercent, required this.onChanged});

  Widget _opt(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? PC.brand : PC.muted),
              const SizedBox(width: 6),
              Text(label,
                  style: pt(13.5, FontWeight.w800, selected ? PC.brand : PC.muted)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: PC.bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _opt('Percentage', Icons.percent_rounded, isPercent, () => onChanged(true)),
          _opt('Fixed amount', Icons.attach_money_rounded, !isPercent, () => onChanged(false)),
        ],
      ),
    );
  }
}

class PromoQuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const PromoQuickChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PC.brand : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? PC.brand : PC.line),
        ),
        child: Text(label,
            style: pt(12.5, FontWeight.w700, selected ? Colors.white : PC.ink)),
      ),
    );
  }
}

class PromoDateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const PromoDateTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final has = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: has ? PC.brand.withValues(alpha: 0.06) : PC.bg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: has ? PC.brand.withValues(alpha: 0.35) : PC.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_rounded, size: 14, color: has ? PC.brand : PC.muted),
                      const SizedBox(width: 5),
                      Text(label,
                          style: pt(11.5, FontWeight.w800, has ? PC.brand : PC.muted)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    has ? prettyDate(value!) : 'Not set',
                    maxLines: 2,
                    style: pt(12, has ? FontWeight.w700 : FontWeight.w500,
                        has ? PC.ink : PC.muted, height: 1.3),
                  ),
                ],
              ),
            ),
            if (has)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.close_rounded, size: 16, color: PC.muted),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Product tile + picker sheet
// ─────────────────────────────────────────────────────────────
class PromoProductTile extends StatelessWidget {
  final String? name;
  final String? stock;
  final bool hasError;
  final VoidCallback onTap;
  const PromoProductTile({
    super.key,
    required this.name,
    required this.stock,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: PC.bg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasError ? PC.error : PC.line),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PC.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 18, color: PC.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: name == null
                  ? Text('Select a product', style: pt(14, FontWeight.w500, PC.muted))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pt(14, FontWeight.w700, PC.ink)),
                  if (stock != null) ...[
                    const SizedBox(height: 2),
                    Text('Stock: $stock', style: pt(12, FontWeight.w500, PC.muted)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.unfold_more_rounded, color: PC.muted),
          ],
        ),
      ),
    );
  }
}

class PromoProductSheet extends StatefulWidget {
  final List<Product> products;
  final int? selectedId;
  const PromoProductSheet({super.key, required this.products, required this.selectedId});

  @override
  State<PromoProductSheet> createState() => _PromoProductSheetState();
}

class _PromoProductSheetState extends State<PromoProductSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.products
        .where((p) => p.name.toLowerCase().contains(_q.trim().toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PC.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Expanded(child: Text('Select product', style: pt(18, FontWeight.w800, PC.ink))),
                  Text('${list.length}', style: pt(13, FontWeight.w700, PC.muted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: PC.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  cursorColor: PC.brand,
                  style: pt(14, FontWeight.w500, PC.ink),
                  decoration: InputDecoration(
                    hintText: 'Search product',
                    hintStyle: pt(13.5, FontWeight.w400, PC.muted),
                    prefixIcon: const Icon(Icons.search_rounded, color: PC.muted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                  child: Text('No products found',
                      style: pt(14, FontWeight.w600, PC.muted)))
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final p = list[i];
                  final sel = p.id == widget.selectedId;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? PC.brand.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: sel ? PC.brand.withValues(alpha: 0.4) : PC.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: PC.bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined,
                                size: 18, color: PC.brand),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: pt(14, FontWeight.w700, PC.ink)),
                                const SizedBox(height: 2),
                                Text('Stock: ${p.stockQuantity}',
                                    style: pt(12, FontWeight.w500, PC.muted)),
                              ],
                            ),
                          ),
                          if (sel) const Icon(Icons.check_circle_rounded, color: PC.brand),
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
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom save bar
// ─────────────────────────────────────────────────────────────
class PromoSaveBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  const PromoSaveBar({
    super.key,
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: PC.heroA.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1 : 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [PC.heroA, PC.brand, PC.heroB]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: enabled
                    ? [
                  BoxShadow(
                    color: PC.brand.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: active ? onTap : null,
                  child: Center(
                    child: loading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(label, style: pt(15.5, FontWeight.w800, Colors.white)),
                      ],
                    ),
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
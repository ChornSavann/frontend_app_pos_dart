import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/models/Product.dart';
import '../../api/promotion/api_promotion.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens (same as the promotion list screen)
// ─────────────────────────────────────────────────────────────
class _C {
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

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

String _num(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _pretty(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${d.day} ${_months[d.month - 1]} ${d.year} · $h:$m $ap';
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class CreatePromotionScreen extends StatefulWidget {
  const CreatePromotionScreen({super.key});

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productKey = GlobalKey<FormFieldState<int>>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _valueController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  int? _selectedProductId;
  Product? _selectedProduct;
  String _selectedDiscountType = 'percentage';
  bool _isActive = true;
  bool _isLoading = false;

  List<Product> _products = [];
  bool _isLoadingProducts = true;

  final ApiPromotion _apiPromotion = ApiPromotion();
  final ApiProduct _apiProduct = ApiProduct();

  bool get _isPercent => _selectedDiscountType == 'percentage';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

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
  void _generateCode() {
    HapticFeedback.selectionClick();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = math.Random();
    _codeController.text = List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _pickProduct() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductSheet(products: _products, selectedId: _selectedProductId),
    );
    if (picked != null) {
      setState(() {
        _selectedProduct = picked;
        _selectedProductId = picked.id;
      });
      _productKey.currentState?.didChange(picked.id);
    }
  }

  DateTime? _parse(TextEditingController c) => DateTime.tryParse(c.text);

  void _setText(TextEditingController c, DateTime d) {
    setState(() => c.text = d.toString().substring(0, 19));
  }

  void _applyPreset(int days) {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    _setText(_startDateController, now);
    _setText(_endDateController, now.add(Duration(days: days)));
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _parse(controller) ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.brand,
            onPrimary: Colors.white,
            onSurface: _C.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
        backgroundColor: _C.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _submitPromotion() async {
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

    final promotionData = {
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

    final result = await _apiPromotion.createPromotion(promotionData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      HapticFeedback.lightImpact();
      _showSuccessDialog(result['message'] ?? 'Promotion created successfully!');
    } else {
      _showError(result['message'] ?? 'Failed to create promotion');
    }
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
                    color: _C.brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: _C.brand, size: 52),
                ),
              ),
              const SizedBox(height: 18),
              Text('Promotion created', style: _t(19, FontWeight.w800, _C.ink)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: _t(13.5, FontWeight.w400, _C.muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.brand,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  child: Text('Done', style: _t(15, FontWeight.w800, Colors.white)),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Form(
          key: _formKey,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: _buildHero(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
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
        bottomNavigationBar: _buildSaveBar(),
      ),
    );
  }

  // ── Hero + live preview ────────────────────────────────────
  Widget _buildHero(BuildContext context) {
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
              padding: EdgeInsets.fromLTRB(16, top + 6, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('New promotion',
                                style: _t(21, FontWeight.w800, Colors.white, spacing: -0.3)),
                            const SizedBox(height: 2),
                            Text('Fill in the details below',
                                style: _t(12.5, FontWeight.w500, Colors.white.withValues(alpha: 0.85))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPreview(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return ListenableBuilder(
      listenable: Listenable.merge([_titleController, _codeController, _valueController]),
      builder: (_, __) {
        final v = double.tryParse(_valueController.text.trim());
        final badge = v == null ? '—' : (_isPercent ? '-${_num(v)}%' : '-\$${_num(v)}');
        final title = _titleController.text.trim();
        final code = _codeController.text.trim().toUpperCase();

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
                    colors: [_C.hot, _C.hotB],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _C.hot.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(badge, style: _t(17, FontWeight.w800, Colors.white)),
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
                      style: _t(15, FontWeight.w800,
                          title.isEmpty ? Colors.white.withValues(alpha: 0.6) : Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _selectedProduct?.name ?? 'No product selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(12, FontWeight.w500, Colors.white.withValues(alpha: 0.8)),
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
                          const Icon(Icons.confirmation_number_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            code.isEmpty ? 'CODE' : code,
                            style: _t(11, FontWeight.w800, Colors.white, spacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Section 1: info ────────────────────────────────────────
  Widget _buildInfoSection() {
    return _Section(
      step: 1,
      title: 'Promotion information',
      icon: Icons.info_outline_rounded,
      children: [
        _label('Product'),
        FormField<int>(
          key: _productKey,
          initialValue: _selectedProductId,
          validator: (_) => _selectedProductId == null ? 'Please select a product' : null,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isLoadingProducts
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: LinearProgressIndicator(color: _C.brand, minHeight: 3),
              )
                  : InkWell(
                onTap: _pickProduct,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: _C.bg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: state.hasError ? _C.error : _C.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _C.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, size: 18, color: _C.brand),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedProduct == null
                            ? Text('Select a product',
                            style: _t(14, FontWeight.w500, _C.muted))
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedProduct!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(14, FontWeight.w700, _C.ink)),
                            const SizedBox(height: 2),
                            Text('Stock: ${_selectedProduct!.stockQuantity}',
                                style: _t(12, FontWeight.w500, _C.muted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.unfold_more_rounded, color: _C.muted),
                    ],
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 6),
                  child: Text(state.errorText!, style: _t(12, FontWeight.w500, _C.error)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _label('Title'),
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration('e.g. Summer Sale', Icons.title_rounded),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
        ),
        const SizedBox(height: 16),
        _label('Promotion code'),
        TextFormField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          style: _t(14, FontWeight.w800, _C.ink, spacing: 1),
          decoration: _decoration(
            'e.g. SUMMER2026',
            Icons.confirmation_number_outlined,
            suffix: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton.icon(
                onPressed: _generateCode,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text('Generate', style: _t(12, FontWeight.w800, _C.brand)),
                style: TextButton.styleFrom(foregroundColor: _C.brand),
              ),
            ),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Promotion code is required' : null,
        ),
        const SizedBox(height: 16),
        _label('Description', optional: true),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration('Tell customers about this offer', Icons.notes_rounded),
        ),
      ],
    );
  }

  // ── Section 2: discount ────────────────────────────────────
  Widget _buildDiscountSection() {
    const quick = [5, 10, 15, 20, 25, 50];
    return _Section(
      step: 2,
      title: 'Discount & stock',
      icon: Icons.local_offer_outlined,
      children: [
        _label('Discount type'),
        _TypeToggle(
          isPercent: _isPercent,
          onChanged: (percent) {
            HapticFeedback.selectionClick();
            setState(() => _selectedDiscountType = percent ? 'percentage' : 'fixed');
          },
        ),
        const SizedBox(height: 16),
        _label('Discount value'),
        TextFormField(
          controller: _valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: _t(16, FontWeight.w800, _C.ink),
          decoration: _decoration(
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
          ListenableBuilder(
            listenable: _valueController,
            builder: (_, __) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in quick)
                  _QuickChip(
                    label: '$q%',
                    selected: double.tryParse(_valueController.text.trim()) == q.toDouble(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _valueController.text = '$q';
                    },
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _label('Promo stock', optional: true),
        TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration('Leave empty for unlimited', Icons.inventory_2_outlined),
        ),
      ],
    );
  }

  // ── Section 3: schedule ────────────────────────────────────
  Widget _buildScheduleSection() {
    return _Section(
      step: 3,
      title: 'Schedule & status',
      icon: Icons.calendar_today_outlined,
      children: [
        _label('Quick duration'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickChip(label: '7 days', onTap: () => _applyPreset(7)),
            _QuickChip(label: '14 days', onTap: () => _applyPreset(14)),
            _QuickChip(label: '30 days', onTap: () => _applyPreset(30)),
            _QuickChip(label: '90 days', onTap: () => _applyPreset(90)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DateTile(
                label: 'Starts',
                value: _parse(_startDateController),
                onTap: () => _selectDateTime(_startDateController),
                onClear: () => setState(_startDateController.clear),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateTile(
                label: 'Ends',
                value: _parse(_endDateController),
                onTap: () => _selectDateTime(_endDateController),
                onClear: () => setState(_endDateController.clear),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          decoration: BoxDecoration(
            color: (_isActive ? _C.brand : _C.muted).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (_isActive ? _C.brand : _C.muted).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(
                _isActive ? Icons.bolt_rounded : Icons.pause_circle_outline_rounded,
                color: _isActive ? _C.brand : _C.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isActive ? 'Active' : 'Inactive',
                        style: _t(14, FontWeight.w800, _C.ink)),
                    Text(
                      _isActive ? 'Goes live as soon as it is saved' : 'Saved as a draft',
                      style: _t(12, FontWeight.w500, _C.muted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isActive,
                activeThumbColor: Colors.white,
                activeTrackColor: _C.brand,
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

  // ── Save bar ───────────────────────────────────────────────
  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom * 0.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _C.heroA.withValues(alpha: 0.08),
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.heroA, _C.brand, _C.heroB]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _C.brand.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _isLoading ? null : _submitPromotion,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text('Save promotion', style: _t(15.5, FontWeight.w800, Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _label(String text, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Text(text, style: _t(12.5, FontWeight.w800, _C.ink)),
          if (optional) ...[
            const SizedBox(width: 6),
            Text('Optional', style: _t(11, FontWeight.w500, _C.muted)),
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: _t(13.5, FontWeight.w400, _C.muted.withValues(alpha: 0.8)),
      prefixIcon: Icon(icon, color: _C.brand, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _C.bg.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: b(_C.line),
      enabledBorder: b(_C.line),
      focusedBorder: b(_C.brand, 1.6),
      errorBorder: b(_C.error),
      focusedErrorBorder: b(_C.error, 1.6),
      errorStyle: _t(12, FontWeight.w500, _C.error),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable pieces
// ─────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final int step;
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
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
            color: _C.heroA.withValues(alpha: 0.07),
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
                  gradient: LinearGradient(colors: [_C.brand, _C.heroB]),
                  shape: BoxShape.circle,
                ),
                child: Text('$step', style: _t(13, FontWeight.w800, Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: _t(16, FontWeight.w800, _C.ink))),
              Icon(icon, size: 20, color: _C.brand.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final bool isPercent;
  final ValueChanged<bool> onChanged;
  const _TypeToggle({required this.isPercent, required this.onChanged});

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
              Icon(icon, size: 18, color: selected ? _C.brand : _C.muted),
              const SizedBox(width: 6),
              Text(label,
                  style: _t(13.5, FontWeight.w800, selected ? _C.brand : _C.muted)),
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
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _opt('Percentage', Icons.percent_rounded, isPercent, () => onChanged(true)),
          _opt('Fixed amount', Icons.attach_money_rounded, !isPercent, () => onChanged(false)),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _C.brand : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _C.brand : _C.line),
        ),
        child: Text(label,
            style: _t(12.5, FontWeight.w700, selected ? Colors.white : _C.ink)),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateTile({
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
          color: has ? _C.brand.withValues(alpha: 0.06) : _C.bg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: has ? _C.brand.withValues(alpha: 0.35) : _C.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_rounded, size: 14, color: has ? _C.brand : _C.muted),
                      const SizedBox(width: 5),
                      Text(label, style: _t(11.5, FontWeight.w800, has ? _C.brand : _C.muted)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    has ? _pretty(value!) : 'Not set',
                    maxLines: 2,
                    style: _t(12, has ? FontWeight.w700 : FontWeight.w500, has ? _C.ink : _C.muted, height: 1.3),
                  ),
                ],
              ),
            ),
            if (has)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.close_rounded, size: 16, color: _C.muted),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Product picker bottom sheet
// ─────────────────────────────────────────────────────────────
class _ProductSheet extends StatefulWidget {
  final List<Product> products;
  final int? selectedId;
  const _ProductSheet({required this.products, required this.selectedId});

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
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
                color: _C.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Expanded(child: Text('Select product', style: _t(18, FontWeight.w800, _C.ink))),
                  Text('${list.length}', style: _t(13, FontWeight.w700, _C.muted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  cursorColor: _C.brand,
                  style: _t(14, FontWeight.w500, _C.ink),
                  decoration: InputDecoration(
                    hintText: 'Search product',
                    hintStyle: _t(13.5, FontWeight.w400, _C.muted),
                    prefixIcon: const Icon(Icons.search_rounded, color: _C.muted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('No products found', style: _t(14, FontWeight.w600, _C.muted)))
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final p = list[i];
                  final sel = p.id == widget.selectedId;
                  final imageUrl = p.imageUrl;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? _C.brand.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: sel ? _C.brand.withValues(alpha: 0.4) : _C.line),
                      ),
                      child: Row(
                        children: [
                          // 🖼️ បدូរមកប្រើ Image ជំនួស Icon កាបូប
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _C.bg,
                                  child: const Icon(Icons.image_not_supported_outlined, size: 20, color: _C.muted),
                                ),
                              )
                                  : Container(
                                color: _C.bg,
                                child: const Icon(Icons.shopping_bag_outlined, size: 20, color: _C.brand),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _t(14, FontWeight.w700, _C.ink)),
                                const SizedBox(height: 2),
                                Text('Stock: ${p.stockQuantity}',
                                    style: _t(12, FontWeight.w500, _C.muted)),
                              ],
                            ),
                          ),
                          if (sel) const Icon(Icons.check_circle_rounded, color: _C.brand),
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/expire_product/api_expire_product.dart';
import 'models/expire_product_model.dart';
import '../../msg/appSnackBar.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens (same as the list and detail screens)
// ─────────────────────────────────────────────────────────────
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

DateTime? _parse(String? s) {
  if (s == null || s.isEmpty) return null;
  final p = DateTime.tryParse(s);
  return p == null ? null : DateTime(p.year, p.month, p.day);
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class UpdateExpireScreen extends StatefulWidget {
  final int expireId;

  const UpdateExpireScreen({super.key, required this.expireId});

  @override
  State<UpdateExpireScreen> createState() => _UpdateExpireScreenState();
}

class _UpdateExpireScreenState extends State<UpdateExpireScreen> {
  final ApiExpireProduct _apiService = ApiExpireProduct();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _expireCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _expireDate;

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSubmitting = false;

  String _productName = '';
  int? _productId;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
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

  // 📥 Load existing data into the form
  Future<void> _loadExistingData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final ExpireProductModel? item =
      await _apiService.getExpireProductById(widget.expireId);
      if (!mounted) return;
      if (item != null) {
        setState(() {
          _productId = item.productId;
          _productName = item.productName;
          _batchController.text = item.batchNumber ?? '';
          _setStart(_parse(item.startDate));
          _setExpire(_parse(item.expireDate));
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        AppSnackBar.showError(context, 'រកមិនឃើញទិន្នន័យឡើយ!');
      }
    } catch (e) {
      debugPrint('Error loading detail: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      // Wide range so an already-expired record can still be opened
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

  Future<void> _submitUpdate() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_productId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic> updateData = {
        'product_id': _productId,
        'batch_number': _batchController.text.trim().isEmpty
            ? null
            : _batchController.text.trim(),
        'quantity': 1,
        'start_date': _iso(_startDate!),
        'expire_date': _iso(_expireDate!),
      };

      final bool success =
      await _apiService.updateExpireProduct(widget.expireId, updateData);
      if (!mounted) return;

      if (success) {
        AppSnackBar.showSuccess(context, 'បានកែប្រែថ្ងៃផុតកំណត់ជោគជ័យ!');
        Navigator.pop(context, true);
      } else {
        AppSnackBar.showError(context, 'បរាជ័យក្នុងការកែប្រែទិន្នន័យ!');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'មានបញ្ហាក្នុងការតភ្ជាប់: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _Header(productName: _productName, loading: _isLoading),
            Expanded(child: _buildContent()),
          ],
        ),
        bottomNavigationBar: (_isLoading || _hasError)
            ? null
            : Container(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
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
              onPressed: _isSubmitting ? null : _submitUpdate,
              style: FilledButton.styleFrom(
                backgroundColor: _C.navy,
                disabledBackgroundColor: _C.navy.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Icon(Icons.check_rounded,
                  color: Colors.white, size: 22),
              label: Text(
                _isSubmitting ? 'កំពុងរក្សាទុក...' : 'រក្សាទុកការកែប្រែ',
                style: _t(15, FontWeight.bold, Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _C.navy));
    }

    if (_hasError) {
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
                child:
                const Icon(Icons.cloud_off_rounded, size: 42, color: _C.muted),
              ),
              const SizedBox(height: 16),
              Text('មិនអាចទាញទិន្នន័យបានទេ',
                  style: _t(14.5, FontWeight.bold, _C.muted)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadExistingData,
                style: FilledButton.styleFrom(
                  backgroundColor: _C.navy,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: Text('ព្យាយាមម្តងទៀត',
                    style: _t(13, FontWeight.bold, Colors.white)),
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
            // ── Form card ──
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
                    const _FieldLabel(text: 'ថ្ងៃចូលស្តុក (Start Date)', required: true),
                    TextFormField(
                      controller: _startCtrl,
                      readOnly: true,
                      style: _t(14, FontWeight.w600, _C.ink),
                      decoration: _decoration(
                        icon: Icons.login_rounded,
                        hint: 'ជ្រើសរើសថ្ងៃចូលស្តុក',
                        suffix: const Icon(Icons.expand_more_rounded,
                            color: _C.muted),
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
                        text: 'ថ្ងៃផុតកំណត់ (Expire Date)', required: true),
                    TextFormField(
                      controller: _expireCtrl,
                      readOnly: true,
                      style: _t(14, FontWeight.w600, _C.ink),
                      decoration: _decoration(
                        icon: Icons.event_busy_rounded,
                        hint: 'ជ្រើសរើសថ្ងៃផុតកំណត់',
                        suffix: const Icon(Icons.expand_more_rounded,
                            color: _C.muted),
                      ),
                      onTap: () async {
                        final picked = await _pickDate(_expireDate);
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
                  ],
                ),
              ),
            ),

            // ── Live preview ──
            if (_expireDate != null) ...[
              const SizedBox(height: 16),
              _Preview(start: _startDate, expire: _expireDate!),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header with the locked product
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String productName;
  final bool loading;
  const _Header({required this.productName, required this.loading});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

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
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  'កែប្រែថ្ងៃផុតកំណត់',
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loading ? 'កំពុងផ្ទុក...' : productName,
                          style: _t(15.5, FontWeight.bold, Colors.white,
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.65)),
                            const SizedBox(width: 4),
                            Text(
                              'មិនអាចប្តូរផលិតផលបានទេ',
                              style: _t(11, FontWeight.w500,
                                  Colors.white.withValues(alpha: 0.65)),
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Live preview of the result
// ─────────────────────────────────────────────────────────────
class _Preview extends StatelessWidget {
  final DateTime? start;
  final DateTime expire;
  const _Preview({required this.start, required this.expire});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = expire.difference(today).inDays;
    final color = _tierColor(days);

    final text = days < 0
        ? 'ផុតកំណត់ ${days.abs()} ថ្ងៃមកហើយ'
        : days == 0
        ? 'ផុតកំណត់ថ្ងៃនេះ'
        : 'នៅសល់ $days ថ្ងៃ';

    double? used;
    if (start != null) {
      final total = expire.difference(start!).inDays;
      if (total > 0) {
        used = (today.difference(start!).inDays / total).clamp(0.0, 1.0).toDouble();
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
                    Text('លទ្ធផលបន្ទាប់ពីកែប្រែ',
                        style: _t(11.5, FontWeight.w500, _C.muted)),
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
              TextSpan(
                text: '  *',
                style: _t(13, FontWeight.bold, _C.expired),
              ),
          ],
        ),
      ),
    );
  }
}
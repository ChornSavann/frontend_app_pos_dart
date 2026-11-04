import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_supplier.dart';
import '../models/supplier.dart';
import '../msg/appSnackBar.dart';
import 'edit_supplier_screen.dart';

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
  static const danger = Color(0xFFD32F2F);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class DetailSupplierScreen extends StatefulWidget {
  final Supplier supplier;

  const DetailSupplierScreen({super.key, required this.supplier});

  @override
  State<DetailSupplierScreen> createState() => _DetailSupplierScreenState();
}

class _DetailSupplierScreenState extends State<DetailSupplierScreen> {
  final ApiSupplier _apiService = ApiSupplier();
  late Supplier _currentSupplier;
  bool _changed = false; // true after an edit, so the list can refresh
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentSupplier = widget.supplier;
  }

  Future<void> _confirmDelete() async {
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
                'Are you sure you want to delete "${_currentSupplier.name}"?',
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

    setState(() => _isDeleting = true);
    try {
      await _apiService.deleteSupplier(_currentSupplier.id!);
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Supplier deleted successfully!');
      _changed = true;
      Navigator.pop(context, true); // tell the list to refresh
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppSnackBar.showError(context, 'Error: $e');
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditSupplierScreen(supplier: _currentSupplier)),
    );
    if (updated is Supplier && mounted) {
      setState(() {
        _currentSupplier = updated;
        _changed = true;
      });
    }
  }

  void _copy(String label, String value) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: value));
    AppSnackBar.showSuccess(context, '$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final s = _currentSupplier;
    final active = s.isActive;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _C.bg,
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                _Hero(
                  name: s.name,
                  company: s.company,
                  active: active,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Contact information',
                                  style: _t(15.5, FontWeight.w800, _C.ink)),
                            ),
                            Text('Tap to copy', style: _t(11.5, FontWeight.w600, _C.muted)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone number',
                          value: s.phone,
                          onCopy: () => _copy('Phone', s.phone!),
                        ),
                        const _Hair(),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: s.email,
                          onCopy: () => _copy('Email', s.email!),
                        ),
                        const _Hair(),
                        _InfoRow(
                          icon: Icons.language_rounded,
                          label: 'Website',
                          value: s.website,
                          onCopy: () => _copy('Website', s.website!),
                        ),
                        const _Hair(),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: s.address,
                          onCopy: () => _copy('Address', s.address!),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _ActionBar(
            deleting: _isDeleting,
            onDelete: _confirmDelete,
            onEdit: _edit,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final String name;
  final String? company;
  final bool active;
  final VoidCallback onBack;

  const _Hero({
    required this.name,
    required this.company,
    required this.active,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'S';
    final hasCompany = company != null && company!.trim().isNotEmpty;

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
            Positioned(
              left: -30,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, top + 8, 16, 26),
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onBack,
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 19, color: Colors.white),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text('Supplier details',
                          style: _t(14, FontWeight.w700, Colors.white.withValues(alpha: 0.9))),
                      const Spacer(),
                      const SizedBox(width: 42),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(initial, style: _t(36, FontWeight.w800, _C.brand)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _t(22, FontWeight.w800, Colors.white, height: 1.25, spacing: -0.3),
                  ),
                  if (hasCompany) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business_outlined,
                            size: 15, color: Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            company!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(13.5, FontWeight.w500, Colors.white.withValues(alpha: 0.9)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            color: active ? _C.brand : _C.inactive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(active ? 'Active' : 'Inactive',
                            style: _t(12, FontWeight.w800, active ? _C.brand : _C.inactive)),
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
// Building blocks
// ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onCopy;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.trim().isNotEmpty;

    return InkWell(
      onTap: has ? onCopy : null,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (has ? _C.brand : _C.inactive).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: has ? _C.brand : _C.inactive),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _t(12, FontWeight.w600, _C.muted)),
                const SizedBox(height: 2),
                Text(
                  has ? value! : 'N/A',
                  style: _t(
                    15,
                    has ? FontWeight.w700 : FontWeight.w500,
                    has ? _C.ink : _C.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (has)
            const Padding(
              padding: EdgeInsets.only(top: 10, left: 8),
              child: Icon(Icons.copy_rounded, size: 16, color: _C.muted),
            ),
        ],
      ),
    );
  }
}

class _Hair extends StatelessWidget {
  const _Hair();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Divider(height: 1, thickness: 1, color: _C.line),
  );
}

// ─────────────────────────────────────────────────────────────
// Bottom action bar
// ─────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final bool deleting;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _ActionBar({required this.deleting, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: OutlinedButton(
                onPressed: deleting ? null : onDelete,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: _C.danger,
                  side: BorderSide(color: _C.danger.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: deleting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: _C.danger),
                )
                    : const Icon(Icons.delete_outline_rounded, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
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
                      onTap: deleting ? null : onEdit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Edit supplier', style: _t(15.5, FontWeight.w800, Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
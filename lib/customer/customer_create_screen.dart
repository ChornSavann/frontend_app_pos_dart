import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_customer.dart';

class _C {
  static const navy = Color(0xFF0E2A47);
  static const red = Color(0xFFD32F2F);
  static const green = Color(0xFF2E9E6B);

  static const avatarColors = <Color>[
    Color(0xFF0E2A47),
    Color(0xFF0F766E),
    Color(0xFF6D28D9),
    Color(0xFFEF6C00),
    Color(0xFF2E9E6B),
    Color(0xFFBE185D),
  ];
}

class _P {
  final bool dark;
  const _P(this.dark);

  Color get bg => dark ? const Color(0xFF0F141B) : const Color(0xFFF2F4F8);
  Color get card => dark ? const Color(0xFF1B222C) : Colors.white;
  Color get field => dark ? const Color(0xFF252E3A) : const Color(0xFFF2F4F8);
  Color get ink => dark ? Colors.white : const Color(0xFF142033);
  Color get muted => dark ? const Color(0xFF9AA7B8) : const Color(0xFF6C7A8E);
  Color get line => dark ? const Color(0xFF2B3542) : const Color(0xFFE0E6EE);
  Color get hero => dark ? const Color(0xFF0B2038) : _C.navy;
  Color get accent => dark ? const Color(0xFF8DB8F0) : _C.navy;
}

const _font = 'KhmerOSBattambang';

TextStyle _t(double size, FontWeight w, Color c, {double? height}) => TextStyle(
  fontSize: size,
  fontWeight: w,
  color: c,
  fontFamily: _font,
  height: height,
);

class CustomerCreateScreen extends StatefulWidget {
  const CustomerCreateScreen({super.key});

  @override
  State<CustomerCreateScreen> createState() => _CustomerCreateScreenState();
}

class _CustomerCreateScreenState extends State<CustomerCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiCustomer _apiCustomer = ApiCustomer();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pointsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showMyDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isSuccess ? _C.green : _C.red).withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: isSuccess ? _C.green : _C.red,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: _t(20, FontWeight.bold, isSuccess ? _C.green : _C.red),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: _t(14, FontWeight.w400, p.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? _C.green : _C.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // បិទ Dialog សិន
                    if (isSuccess) {
                      Navigator.pop(
                        context,
                        true,
                      ); // ត្រឡប់ក្រោយ និង Refresh ទិន្នន័យ
                    }
                  },
                  child: const Text(
                    "យល់ព្រម",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'KhmerOSBattambang',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🚀 Function បញ្ជូនទិន្នន័យទៅកាន់ Laravel API (Store) តាមរយៈ ApiCustomer
  Future<void> _createCustomer() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dynamic result = await _apiCustomer.createCustomer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? ''
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        points: int.tryParse(_pointsController.text.trim()) ?? 0,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      bool isSuccess = false;
      String errorMessage = 'មានបញ្ហាក្នុងការបង្កើតទិន្នន័យ';

      if (result is bool) {
        isSuccess = result;
      } else if (result is Map<String, dynamic>) {
        isSuccess = result['success'] == true;
        if (!isSuccess) {
          errorMessage = result['message'] ?? errorMessage;
        }
      } else if (result != null) {
        isSuccess = true;
      }

      if (isSuccess) {
        _showMyDialog(
          title: "ជោគជ័យ!",
          message: "បានបង្កើតអតិថិជនថ្មីដោយជោគជ័យ!",
          isSuccess: true,
        );
      } else {
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('កំហុសប្រព័ន្ធ: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'KhmerOSBattambang',
            color: Colors.white,
          ),
        ),
        backgroundColor: _C.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildHero(BuildContext context, _P p) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 4, 8, 24),
      decoration: BoxDecoration(
        color: p.hero,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
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
                  "បង្កើតអតិថិជនថ្មី",
                  textAlign: TextAlign.center,
                  style: _t(17, FontWeight.bold, Colors.white),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameController,
              builder: (context, value, _) {
                final name = value.text.trim();
                final bool hasName = name.isNotEmpty;
                final Color avatarColor = hasName
                    ? _C.avatarColors[name.codeUnitAt(0) %
                          _C.avatarColors.length]
                    : _C.avatarColors[0];

                return Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: hasName
                          ? Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                color: avatarColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                fontFamily: 'KhmerOSBattambang',
                              ),
                            )
                          : Icon(
                              Icons.person_add_alt_1_rounded,
                              color: _C.navy.withValues(alpha: 0.6),
                              size: 30,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasName ? name : 'អតិថិជនថ្មី',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(
                              19,
                              FontWeight.bold,
                              hasName
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'បំពេញព័ត៌មានខាងក្រោម',
                            style: _t(
                              12,
                              FontWeight.w500,
                              Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    _P p, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: p.dark ? Border.all(color: p.line) : null,
        boxShadow: p.dark
            ? null
            : [
                BoxShadow(
                  color: _C.navy.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: p.accent),
              ),
              const SizedBox(width: 10),
              Text(title, style: _t(15, FontWeight.bold, p.ink)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, _P p) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: p.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.dark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        child: FilledButton(
          onPressed: _isLoading ? null : _createCustomer,
          style: FilledButton.styleFrom(
            backgroundColor: p.dark ? const Color(0xFF2F6DB5) : _C.navy,
            disabledBackgroundColor: _C.navy.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "រក្សាទុក (Save Customer)",
                      style: _t(15, FontWeight.bold, Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final p = _P(isDarkMode);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.bg,
        body: Column(
          children: [
            _buildHero(context, p),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 📦 Contact card
                      _card(
                        p,
                        icon: Icons.contact_page_rounded,
                        title: "ព័ត៌មានទំនាក់ទំនង",
                        child: Column(
                          children: [
                            // 👤 Name Field
                            _buildTextField(
                              controller: _nameController,
                              label: "ឈ្មោះអតិថិជន (Name)",
                              icon: Icons.person_rounded,
                              isDarkMode: isDarkMode,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'សូមបញ្ចូលឈ្មោះអតិថិជន'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // 📧 Email Field
                            _buildTextField(
                              controller: _emailController,
                              label: "អ៊ីម៉ែល (Email)",
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              isDarkMode: isDarkMode,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'សូមបញ្ចូលអ៊ីម៉ែល';
                                if (!value.contains('@'))
                                  return 'ទម្រង់អ៊ីម៉ែលមិនត្រឹមត្រូវ';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 📱 Phone Field
                            _buildTextField(
                              controller: _phoneController,
                              label: "លេខទូរស័ព្ទ (Phone)",
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ⭐ Points and address card
                      _card(
                        p,
                        icon: Icons.stars_rounded,
                        title: "ពិន្ទុ និងអាសយដ្ឋាន",
                        child: Column(
                          children: [
                            // ⭐ Points Field
                            _buildTextField(
                              controller: _pointsController,
                              label: "ពិន្ទុ (Points)",
                              icon: Icons.stars_rounded,
                              keyboardType: TextInputType.number,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 16),

                            // 📍 Address Field
                            _buildTextField(
                              controller: _addressController,
                              label: "អាសយដ្ឋាន (Address)",
                              icon: Icons.location_on_rounded,
                              maxLines: 3,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(context, p),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required bool isDarkMode,
    String? Function(String?)? validator,
  }) {
    final p = _P(isDarkMode);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: _t(14, FontWeight.w600, p.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _t(14, FontWeight.w400, p.muted),
        floatingLabelStyle: _t(13, FontWeight.w600, p.accent),
        errorStyle: _t(11.5, FontWeight.w500, _C.red),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 44 : 0),
          child: Icon(icon, color: p.accent, size: 20),
        ),
        filled: true,
        fillColor: p.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(p.line),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(p.accent, 1.6),
        errorBorder: border(_C.red),
        focusedErrorBorder: border(_C.red, 1.6),
      ),
    );
  }
}

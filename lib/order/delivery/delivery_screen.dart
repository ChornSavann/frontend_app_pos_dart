import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../msg/appSnackBar.dart';
import '../card_manager.dart';
import 'map_picker_screen.dart';

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
  static const hot = Color(0xFFEF5B16);
  static const money = Color(0xFF0B6B3F);
  static const danger = Color(0xFFD32F2F);
}

TextStyle _t(
  double size,
  FontWeight w,
  Color c, {
  double? height,
  double? spacing,
}) => TextStyle(
  fontSize: size,
  fontWeight: w,
  color: c,
  height: height,
  letterSpacing: spacing,
);

BoxDecoration _card({double radius = 22}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: _C.heroA.withValues(alpha: 0.07),
      blurRadius: 18,
      offset: const Offset(0, 7),
    ),
  ],
);

InputDecoration _input(String label, IconData icon, {String? hint}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: _t(12.5, FontWeight.w500, _C.muted),
    hintText: hint,
    prefixIcon: Icon(icon, color: _C.brand, size: 20),
    filled: true,
    fillColor: _C.bg.withValues(alpha: 0.6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: b(_C.line),
    enabledBorder: b(_C.line),
    focusedBorder: b(_C.brand, 1.6),
    errorBorder: b(_C.danger),
    focusedErrorBorder: b(_C.danger, 1.6),
    errorStyle: _t(12, FontWeight.w500, _C.danger),
  );
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class DeliveryScreen extends StatefulWidget {
  final double totalAmount;
  final Function(Map<String, dynamic> deliveryData) onConfirmDelivery;

  const DeliveryScreen({
    super.key,
    required this.totalAmount,
    required this.onConfirmDelivery,
  });

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiOrder _apiOrder = ApiOrder();
  bool _isSubmitting = false;
  bool _showAllItems = false;

  final TextEditingController _pickupController = TextEditingController(
    text: 'ហាងលក់ទំនិញរបស់អ្នក (Store Location)',
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _customFeeController = TextEditingController(
    text: '2.50',
  );

  String _selectedService = 'Grab Express';
  double _deliveryFee = 2.50;

  double _storeLat = 11.5564;
  double _storeLng = 104.9282;
  double _customerLat = 11.5650;
  double _customerLng = 104.9150;

  List<Map<String, dynamic>> _deliveryServices = [];
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoadingServices = true);
    final services = await _apiOrder.fetchDeliveryServicesFromApi();
    if (!mounted) return;

    setState(() {
      if (services.isNotEmpty) {
        _deliveryServices = services;
        _selectedService = _deliveryServices[0]['name'];
        _deliveryFee = (_deliveryServices[0]['fee'] as num).toDouble();
        _customFeeController.text = _deliveryFee.toStringAsFixed(2);
      } else {
        // 🛡️ Fallback ទុកក្នុងករណី API គ្មានទិន្នន័យ
        _deliveryServices = [
          {
            'name': 'Grab Express',
            'note': 'ដឹកជញ្ជូនហុចដល់ដៃរហ័សទាន់ចិត្ត',
            'fee': 2.50,
            'icon': '🚗',
          },
        ];
      }
      _isLoadingServices = false;
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _customFeeController.dispose();
    super.dispose();
  }

  Future<void> _pickPickup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );
    if (result != null && result is Map) {
      setState(() {
        _pickupController.text = result['address'] ?? '';
        if (result['lat'] != null && result['lng'] != null) {
          _storeLat = double.tryParse(result['lat'].toString()) ?? _storeLat;
          _storeLng = double.tryParse(result['lng'].toString()) ?? _storeLng;
        }
      });
    }
  }

  Future<void> _pickCustomerLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );
    if (result != null && result is Map) {
      setState(() {
        _addressController.text = result['address'] ?? '';
        if (result['lat'] != null && result['lng'] != null) {
          _customerLat =
              double.tryParse(result['lat'].toString()) ?? _customerLat;
          _customerLng =
              double.tryParse(result['lng'].toString()) ?? _customerLng;
        }
      });
    }
  }

  Future<void> _submitDeliveryOrder() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      int currentUserId = prefs.getInt('user_id') ?? 1;

      final cartItems = CartManager.cartItems;
      String orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      List<Map<String, dynamic>> itemsList = cartItems.map((item) {
        return {
          'product_id': item.product.id,
          'product_name': item.product.name,
          'unit_price': item.product.sellingPrice,
          'quantity': item.quantity,
          'total_price': item.product.sellingPrice * item.quantity,
        };
      }).toList();
      bool isSuccess = await _apiOrder.createOrderWithPayment(
        orderNumber: orderNumber,
        userId: currentUserId,
        subtotal: widget.totalAmount,
        discount: 0.0,
        tax: 0.0,
        total: widget.totalAmount + _deliveryFee,
        paymentMethod: 'cash_on_delivery',
        amountPaid: 0.00,
        changeAmount: 0.00,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        customerAddress: _addressController.text.trim(),
        orderType: 'delivery',
        deliveryAddress: _addressController.text.trim(),
        deliveryFee: _deliveryFee,
        pickupAddress: _pickupController.text.trim(),
        deliveryPartner: _selectedService,
        receiverName: _nameController.text.trim(),
        receiverPhone: _phoneController.text.trim(),
        note: _noteController.text.trim(),
        items: itemsList,
        storeLat: _storeLat,
        storeLng: _storeLng,
        customerLat: _customerLat,
        customerLng: _customerLng,
      );

      if (isSuccess) {
        final deliveryData = {
          'order_number': orderNumber,
          'pickup_address': _pickupController.text.trim(),
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'note': _noteController.text.trim(),
          'delivery_partner': _selectedService,
          'delivery_fee': _deliveryFee,
          'grand_total': widget.totalAmount + _deliveryFee,
          'store_lat': _storeLat,
          'store_lng': _storeLng,
          'customer_lat': _customerLat,
          'customer_lng': _customerLng,
        };

        widget.onConfirmDelivery(deliveryData);

        if (mounted) {
          CartManager.clearCart();
          Navigator.pop(context);
          Navigator.pop(context);
          AppSnackBar.showSuccess(
            context,
            'បានបង្កើតការកុម្ម៉ង់ដឹកជញ្ជូនជោគជ័យ! សូមពិនិត្យក្នុងបញ្ជីរង់ចាំដឹក។',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'មានបញ្ហាក្នុងការបញ្ជាទិញ: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _selectService(Map<String, dynamic> service) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedService = service['name'];
      _deliveryFee = (service['fee'] as num).toDouble();
      _customFeeController.text = _deliveryFee.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = CartManager.cartItems;
    final int totalItemsCount = cartItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final grand = widget.totalAmount + _deliveryFee;

    final visibleItems = _showAllItems || cartItems.length <= 3
        ? cartItems
        : cartItems.take(3).toList();

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
                SliverToBoxAdapter(
                  child: _Hero(
                    items: totalItemsCount,
                    subtotal: widget.totalAmount,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── order summary ──
                      _SectionCard(
                        icon: Icons.shopping_bag_outlined,
                        title: 'ផលិតផលបានកុម្ម៉ង់',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _C.brand.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$totalItemsCount មុខទំនិញ',
                            style: _t(12, FontWeight.w800, _C.brand),
                          ),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < visibleItems.length; i++) ...[
                              _ItemRow(
                                name: visibleItems[i].product.name,
                                imageUrl: visibleItems[i].product.imageUrl,
                                quantity: visibleItems[i].quantity,
                                price: visibleItems[i].product.sellingPrice,
                              ),
                              if (i != visibleItems.length - 1)
                                const SizedBox(height: 10),
                            ],
                            if (cartItems.length > 3) ...[
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () => setState(
                                  () => _showAllItems = !_showAllItems,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _showAllItems
                                            ? 'បង្ហាញតិចជាងនេះ'
                                            : 'មើលទាំងអស់ (+${cartItems.length - 3})',
                                        style: _t(
                                          12.5,
                                          FontWeight.w800,
                                          _C.brand,
                                        ),
                                      ),
                                      Icon(
                                        _showAllItems
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded,
                                        size: 18,
                                        color: _C.brand,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── route ──
                      _SectionCard(
                        icon: Icons.route_rounded,
                        title: 'ទីតាំងដឹកជញ្ជូន',
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _Dot(
                                  color: _C.brand,
                                  icon: Icons.store_rounded,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ទីតាំងចេញដំណើរ (Pickup Address)',
                                        style: _t(
                                          11.5,
                                          FontWeight.w600,
                                          _C.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _pickupController.text,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: _t(
                                          13.5,
                                          FontWeight.w800,
                                          _C.ink,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _PillButton(
                                  label: 'ប្ដូរ',
                                  icon: Icons.edit_location_alt_rounded,
                                  onTap: _pickPickup,
                                ),
                              ],
                            ),
                            const _DashedConnector(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: _Dot(
                                    color: _C.hot,
                                    icon: Icons.location_on_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _addressController,
                                    minLines: 1,
                                    maxLines: 3,
                                    style: _t(14, FontWeight.w600, _C.ink),
                                    decoration: InputDecoration(
                                      labelText:
                                          'អាសយដ្ឋានអ្នកទទួល (Delivery Address)*',
                                      labelStyle: _t(
                                        12.5,
                                        FontWeight.w500,
                                        _C.muted,
                                      ),
                                      filled: true,
                                      fillColor: _C.bg.withValues(alpha: 0.6),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: _C.line,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: _C.line,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: _C.brand,
                                          width: 1.6,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: _C.danger,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: _C.danger,
                                          width: 1.6,
                                        ),
                                      ),
                                      errorStyle: _t(
                                        12,
                                        FontWeight.w500,
                                        _C.danger,
                                      ),
                                    ),
                                    validator: (value) => (value ?? '').isEmpty
                                        ? 'សូមបញ្ចូលអាសយដ្ឋានដឹកជញ្ជូន'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _PillButton(
                                label: 'ជ្រើសរើសលើផែនទី',
                                icon: Icons.map_rounded,
                                onTap: _pickCustomerLocation,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── delivery partners ──
                      _SectionCard(
                        icon: Icons.local_shipping_outlined,
                        title: 'សេវាកម្មដឹកជញ្ជូន (Delivery Partners)',
                        child: _isLoadingServices
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                      color: _C.brand,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final service in _deliveryServices) ...[
                                    _ServiceCard(
                                      name: '${service['name']}',
                                      note: '${service['note'] ?? ''}',
                                      fee: (service['fee'] as num).toDouble(),
                                      emoji: service['icon']?.toString(),
                                      selected:
                                          _selectedService == service['name'],
                                      onTap: () => _selectService(service),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      10,
                                      10,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _C.bg.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _C.line),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.tune_rounded,
                                          size: 18,
                                          color: _C.brand,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'កែសម្រួលថ្លៃដឹកតាមចម្ងាយ',
                                            style: _t(
                                              13,
                                              FontWeight.w800,
                                              _C.ink,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 104,
                                          child: TextFormField(
                                            controller: _customFeeController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            style: _t(
                                              15,
                                              FontWeight.w800,
                                              _C.money,
                                            ),
                                            textAlign: TextAlign.end,
                                            decoration: InputDecoration(
                                              prefixText: '\$ ',
                                              prefixStyle: _t(
                                                15,
                                                FontWeight.w800,
                                                _C.money,
                                              ),
                                              isDense: true,
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 11,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: _C.line,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: _C.line,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: _C.brand,
                                                  width: 1.6,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                _deliveryFee =
                                                    double.tryParse(value) ??
                                                    0.0;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),

                      // ── receiver ──
                      _SectionCard(
                        icon: Icons.person_pin_circle_outlined,
                        title: 'ព័ត៌មានអ្នកទទួល (Receiver Details)',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: _t(14, FontWeight.w600, _C.ink),
                              decoration: _input(
                                'ឈ្មោះអ្នកទទួល (Receiver Name)*',
                                Icons.person_outline_rounded,
                              ),
                              validator: (value) => (value ?? '').isEmpty
                                  ? 'សូមបញ្ចូលឈ្មោះអ្នកទទួល'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: _t(14, FontWeight.w600, _C.ink),
                              decoration: _input(
                                'លេខទូរស័ព្ទ (Phone Number)*',
                                Icons.phone_outlined,
                              ),
                              validator: (value) => (value ?? '').isEmpty
                                  ? 'សូមបញ្ចូលលេខទូរស័ព្ទ'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _noteController,
                              minLines: 1,
                              maxLines: 3,
                              style: _t(14, FontWeight.w600, _C.ink),
                              decoration: _input(
                                'ចំណាំ (Note e.g. ដាក់ឥវ៉ាន់ថ្នមៗ)',
                                Icons.note_alt_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: keyboardOpen
            ? null
            : _BottomBar(
                subtotal: widget.totalAmount,
                fee: _deliveryFee,
                total: grand,
                submitting: _isSubmitting,
                onSubmit: _submitDeliveryOrder,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final int items;
  final double subtotal;
  final VoidCallback onBack;
  const _Hero({
    required this.items,
    required this.subtotal,
    required this.onBack,
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
              padding: EdgeInsets.fromLTRB(16, top + 6, 16, 18),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'សេវាដឹកជញ្ជូន (Delivery)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(
                            20,
                            FontWeight.w800,
                            Colors.white,
                            spacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ជ្រើសរើសសេវា បំពេញអាសយដ្ឋាន និងអ្នកទទួល',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(
                            12,
                            FontWeight.w500,
                            Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$items ទំនិញ',
                          style: _t(
                            10.5,
                            FontWeight.w600,
                            Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: _t(
                            17,
                            FontWeight.w800,
                            Colors.white,
                            height: 1.1,
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
// Building blocks
// ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _C.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: _C.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(14.5, FontWeight.w800, _C.ink),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int quantity;
  final double price;
  const _ItemRow({
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.price,
  });

  Widget _placeholder() => Container(
    width: 46,
    height: 46,
    color: _C.brand.withValues(alpha: 0.1),
    child: const Icon(Icons.shopping_bag_outlined, color: _C.brand, size: 22),
  );

  @override
  Widget build(BuildContext context) {
    final has = imageUrl != null && imageUrl!.isNotEmpty;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: has
              ? Image.network(
                  imageUrl!,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(13.5, FontWeight.w800, _C.ink),
              ),
              const SizedBox(height: 2),
              Text(
                'ចំនួន: $quantity × \$${price.toStringAsFixed(2)}',
                style: _t(11.5, FontWeight.w500, _C.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '\$${(price * quantity).toStringAsFixed(2)}',
          style: _t(14, FontWeight.w800, _C.money),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _Dot({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}

class _DashedConnector extends StatelessWidget {
  const _DashedConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 2,
          height: 26,
          child: CustomPaint(painter: _DashPainter()),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.line
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    var y = 2.0;
    while (y < size.height) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 4), paint);
      y += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _C.brand.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: _C.brand),
              const SizedBox(width: 5),
              Text(label, style: _t(12, FontWeight.w800, _C.brand)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String name;
  final String note;
  final double fee;
  final String? emoji;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.name,
    required this.note,
    required this.fee,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEmoji = emoji != null && emoji!.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected ? _C.brand.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _C.brand : _C.line,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _C.brand.withValues(alpha: 0.14) : _C.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: hasEmoji
                  ? Text(emoji!, style: const TextStyle(fontSize: 22))
                  : Icon(
                      Icons.delivery_dining_rounded,
                      color: selected ? _C.brand : _C.muted,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _t(14.5, FontWeight.w800, _C.ink)),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(11.5, FontWeight.w500, _C.muted, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${fee.toStringAsFixed(2)}',
                  style: _t(15, FontWeight.w800, _C.money),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected ? _C.brand : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? _C.brand : _C.line,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final double subtotal;
  final double fee;
  final double total;
  final bool submitting;
  final VoidCallback onSubmit;

  const _BottomBar({
    required this.subtotal,
    required this.fee,
    required this.total,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _C.heroA.withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('សរុប', style: _t(11.5, FontWeight.w700, _C.muted)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: _t(
                    23,
                    FontWeight.w800,
                    _C.money,
                    height: 1.1,
                    spacing: -0.6,
                  ),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)} + ដឹក \$${fee.toStringAsFixed(2)}',
                  style: _t(10.5, FontWeight.w600, _C.muted),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Opacity(
                opacity: submitting ? 0.7 : 1,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.heroA, _C.brand, _C.heroB],
                    ),
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
                      onTap: submitting ? null : onSubmit,
                      child: Center(
                        child: submitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'បន្តទៅទូទាត់',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _t(
                                        15,
                                        FontWeight.w800,
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
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

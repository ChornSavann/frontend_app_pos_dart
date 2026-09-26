import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_order.dart'; // 🟢 ត្រូវប្រាកដថាបាន import ApiOrder
import '../../msg/appSnackBar.dart';
import '../card_manager.dart';
import 'map_picker_screen.dart';
import 'order_tracking_screen.dart';

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
  final ApiOrder _apiOrder = ApiOrder(); // 🟢 កំណត់ Object សម្រាប់ហៅ API
  bool _isSubmitting = false; // សម្រាប់បង្ហាញ Loading ពេលកំពុងបង្កើត Order

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

  final List<Map<String, dynamic>> _deliveryServices = [
    {
      'name': 'Grab Express',
      'desc': 'ដឹកជញ្ជូនហុចដល់ដៃរហ័សទាន់ចិត្ត',
      'fee': 2.50,
      'icon': '🚗',
    },
    {
      'name': 'Foodpanda',
      'desc': 'សេវាដឹកជញ្ជូនអាហារ និងទំនិញ',
      'fee': 2.00,
      'icon': '🐼',
    },
    {
      'name': 'Nhan Delivery',
      'desc': 'សេវាកម្មរហ័សទូទាំងរាជធានី-ខេត្ត',
      'fee': 1.50,
      'icon': '⚡',
    },
    {
      'name': 'Wing Delivery',
      'desc': 'សុវត្ថិភាព ឆាប់រហ័ស ទុកចិត្តបាន',
      'fee': 2.20,
      'icon': 'WING',
    },
  ];

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

  Widget _buildPlaceholderImage() {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFF4F46E5),
        size: 22,
      ),
    );
  }


  Future<void> _submitDeliveryOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final cartItems = CartManager.cartItems;
      String orderNumber = "ORD-${DateTime.now().millisecondsSinceEpoch}";

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
        userId: 1,
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
        note: _noteController.text.trim(),
        items: itemsList,
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
        };

        widget.onConfirmDelivery(deliveryData);

        if (mounted) {
          CartManager.clearCart();
          Navigator.pop(context);
          Navigator.pop(context);
          AppSnackBar.showSuccess(
            context,
            "បានបង្កើតការកុម្ម៉ង់ដឹកជញ្ជូនជោគជ័យ! សូមពិនិត្យក្នុងបញ្ជីរង់ចាំដឹក។",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, "មានបញ្ហាក្នុងการបញ្ជាទិញ: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = CartManager.cartItems;
    final int totalItemsCount = cartItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "ជ្រើសរើសសេវាដឹកជញ្ជូន (Delivery)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'KhmerOSBattambang',
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📦 Order Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "ផលិតផលបានកុម្ម៉ង់ (Order Summary)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'KhmerOSBattambang',
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$totalItemsCount មុខទំនិញ",
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'KhmerOSBattambang',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final product = item.product;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child:
                                    product.imageUrl != null &&
                                        product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        product.imageUrl!,
                                        width: 45,
                                        height: 45,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildPlaceholderImage(),
                                      )
                                    : _buildPlaceholderImage(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "ចំនួន: ${item.quantity} x \$${product.sellingPrice.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "\$${(product.sellingPrice * item.quantity).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 📍 Address Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ទីតាំងចេញដំណើរ (Pickup Address)",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontFamily: 'KhmerOSBattambang',
                                ),
                              ),
                              Text(
                                _pickupController.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MapPickerScreen(),
                              ),
                            );
                            if (result != null && result is Map) {
                              setState(() {
                                _pickupController.text = result['address'];
                              });
                            }
                          },
                          child: const Text(
                            "ប្ដូរ",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'KhmerOSBattambang',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            color: Colors.green,
                            thickness: 2,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText:
                                  "អាសយដ្ឋានអ្នកទទួល (Delivery Address)*",
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontFamily: 'KhmerOSBattambang',
                              ),
                              border: InputBorder.none,
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'សូមបញ្ចូលអាសយដ្ឋានដឹកជញ្ជូន'
                                : null,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MapPickerScreen(),
                              ),
                            );
                            if (result != null && result is Map) {
                              setState(() {
                                _addressController.text = result['address'];
                              });
                            }
                          },
                          child: const Text(
                            "ផែនទី",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'KhmerOSBattambang',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ⚡ Delivery Service Options
              const Text(
                "សេវាកម្មដឹកជញ្ជូន (Delivery Partners)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'KhmerOSBattambang',
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),

              Column(
                children: _deliveryServices.map((service) {
                  bool isSelected = _selectedService == service['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedService = service['name'];
                        _deliveryFee = service['fee'];
                        _customFeeController.text = _deliveryFee
                            .toStringAsFixed(2);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Radio<String>(
                                value: service['name'],
                                groupValue: _selectedService,
                                activeColor: Colors.green,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedService = val;
                                      _deliveryFee = service['fee'];
                                      _customFeeController.text = _deliveryFee
                                          .toStringAsFixed(2);
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    service['desc'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontFamily: 'KhmerOSBattambang',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            "\$${service['fee'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // 💵 កែសម្រួលថ្លៃសេវាដឹកជញ្ជូនតាមចម្ងាយ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "កែសម្រួលថ្លៃដឹកតាមចម្ងាយ (\$):",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'KhmerOSBattambang',
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _customFeeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _deliveryFee = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 📦 Package Details Section
              const Text(
                "ព័ត៌មានអ្នកទទួល (Receiver Details)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'KhmerOSBattambang',
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "ឈ្មោះអ្នកទទួល (Receiver Name)*",
                        labelStyle: TextStyle(
                          fontFamily: 'KhmerOSBattambang',
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'សូមបញ្ចូលឈ្មោះអ្នកទទួល' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "លេខទូរស័ព្ទ (Phone Number)*",
                        labelStyle: TextStyle(
                          fontFamily: 'KhmerOSBattambang',
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'សូមបញ្ចូលលេខទូរស័ព្ទ' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: "ចំណាំ (Note e.g. ដាក់ឥវ៉ាន់ថ្នមៗ)",
                        labelStyle: TextStyle(
                          fontFamily: 'KhmerOSBattambang',
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.note_alt_outlined,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 🚀 Proceed to Payment & API Order Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitDeliveryOrder,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "បន្តទៅទូទាត់ (\$${(widget.totalAmount + _deliveryFee).toStringAsFixed(2)})",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'KhmerOSBattambang',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

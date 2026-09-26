import 'package:flutter/material.dart';
import '../../api/api_order.dart';
import '../../msg/appSnackBar.dart';

class ViewOrderScreen extends StatefulWidget {
  final int orderId;

  const ViewOrderScreen({super.key, required this.orderId});

  @override
  State<ViewOrderScreen> createState() => _ViewOrderScreenState();
}

class _ViewOrderScreenState extends State<ViewOrderScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _orderData;
  final ApiOrder _apiOrder = ApiOrder();

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiOrder.getOrderById(widget.orderId);

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _orderData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'Failed to load order details');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AppSnackBar.showError(context, 'Error: $e');
    }
  }

  // 🎨 ពណ៌សម្រាប់ Status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _orderData?['details'] as List? ?? [];
    final customer = _orderData?['customer'] as Map<String, dynamic>?;
    final payment = _orderData?['payment'] as Map<String, dynamic>?;

    // 🚚 ទាញយកទិន្នន័យ Delivery (អាស្រ័យលើការរចនាតារាង Backend របស់អ្នក អាចជា 'delivery' ឬកប់ក្នុង Order ផ្ទាល់)
    final delivery =
        _orderData?['delivery'] as Map<String, dynamic>? ?? _orderData;
    final String orderType =
        (_orderData?['order_type'] ?? delivery?['order_type'] ?? 'dine_in')
            .toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _orderData == null
          ? const Center(child: Text('No data found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🧾 1. Order Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _orderData!['order_number'] ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  _orderData!['status'] ?? '',
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (_orderData!['status'] ?? 'N/A').toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: _getStatusColor(
                                    _orderData!['status'] ?? '',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _buildInfoRow('Order Type:', orderType.toUpperCase()),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          'Date:',
                          _orderData!['created_at'] ?? 'N/A',
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          'Subtotal:',
                          '\$${_orderData!['subtotal'] ?? '0.00'}',
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          'Discount:',
                          '\$${_orderData!['discount_amount'] ?? '0.00'}',
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          'Tax:',
                          '\$${_orderData!['tax_amount'] ?? '0.00'}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _buildInfoRow(
                          'Total Amount:',
                          '\$${_orderData!['total_amount'] ?? '0.00'}',
                          isBold: true,
                          color: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🚚 2. Delivery Information Card (បង្ហាញเฉพาะពេល Order ជាប្រភេទ delivery)
                  if (orderType == 'delivery') ...[
                    const Text(
                      'Delivery Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade500.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Delivery Partner:',
                            delivery?['delivery_partner'] ??
                                delivery?['partner'] ??
                                'N/A',
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            'Delivery Fee:',
                            '\$${delivery?['delivery_fee'] ?? '0.00'}',
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            'Delivery Address:',
                            delivery?['delivery_address'] ??
                                delivery?['address'] ??
                                'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 👤 3. Customer Info Card
                  if (customer != null) ...[
                    const Text(
                      'Customer Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Name:', customer['name'] ?? 'N/A'),
                          const SizedBox(height: 6),
                          _buildInfoRow('Phone:', customer['phone'] ?? 'N/A'),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            'Address:',
                            customer['address'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 💳 4. Payment Info Card
                  if (payment != null) ...[
                    const Text(
                      'Payment Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Method:',
                            (payment['payment_method'] ?? 'cash').toUpperCase(),
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            'Amount Paid:',
                            '\$${payment['amount'] ?? '0.00'}',
                          ),
                          const SizedBox(height: 6),
                          _buildInfoRow(
                            'Change:',
                            '\$${payment['change_amount'] ?? '0.00'}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 📦 5. Items / Details List with Image
                  const Text(
                    'Products Ordered',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: details.length,
                    itemBuilder: (context, index) {
                      final item = details[index];

                      final String? imageUrl = item['product'] != null
                          ? (item['product']['image_url'] ??
                                item['product']['image'])
                          : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 🖼️ ផ្នែកបង្ហាញរូបភាពផលិតផល
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade100,
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons
                                                    .image_not_supported_outlined,
                                                color: Colors.grey,
                                                size: 24,
                                              );
                                            },
                                      )
                                    : const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 📝 ឈ្មោះផលិតផល, តម្លៃ និងចំនួន
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product_name'] ?? 'Product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price: \$${item['unit_price']} x Qty: ${double.parse(item['quantity'].toString()).toInt()}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 💰 តម្លៃសរុបប្រចាំផលិតផល
                            Text(
                              '\$${item['total_price']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF2563EB),
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
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        bool isBold = false,
        Color? color,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 🔹 ป้ายຊື່ (Label) នៅខាងឆ្វេង
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(width: 12),
        // 🔹 តម្លៃ (Value) នៅខាងស្តាំ ដាក់ក្នុង Expanded ដើម្បីការពារការ Overflow និងអាចចុះបន្ទាត់បាន
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 13,
              color: color ?? const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

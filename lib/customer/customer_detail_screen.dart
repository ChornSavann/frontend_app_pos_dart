import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_customer.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _customerData;
  List<dynamic> _customerOrders = [];
  final ApiCustomer _apiCustomer = ApiCustomer();

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
  }

  Future<void> _fetchCustomerData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiCustomer.getCustomerDetails(widget.customerId);
      if (result != null && result['success'] == true) {
        setState(() {
          _customerData = result['customer'] ?? {};
          _customerOrders = result['orders'] ?? result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.customerName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : RefreshIndicator(
              color: const Color(0xFF2563EB),
              onRefresh: _fetchCustomerData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 👤 ព័ត៌មានសង្ខេបរបស់អតិថិជន (Modern Profile Card)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                widget.customerName.isNotEmpty
                                    ? widget.customerName[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.customerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "ព័ត៌មានអតិថិជន",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1),
                        ),
                        _buildInfoRow(
                          icon: Icons.phone_rounded,
                          color: Colors.blue,
                          text: _customerData?['phone'] ?? 'គ្មានលេខទូរស័ព្ទ',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          color: Colors.orange,
                          text: _customerData?['email'] ?? 'គ្មានអ៊ីម៉ែល',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          color: Colors.red,
                          text: _customerData?['address'] ?? 'គ្មានអាសយដ្ឋាន',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 📦 ប្រវត្តិការបញ្ជាទិញ (Orders History Title)
                  const Text(
                    "ប្រវត្តិការបញ្ជាទិញទំនិញ (Orders History)",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _customerOrders.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'អតិថិជននេះមិនទាន់មានប្រវត្តិការបញ្ជាទិញទេ',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _customerOrders.length,
                          itemBuilder: (context, index) {
                            final order = _customerOrders[index];
                            double totalAmount =
                                double.tryParse(
                                  (order['total_amount'] ?? order['total'] ?? 0)
                                      .toString(),
                                ) ??
                                0.0;

                            List<dynamic> orderItems =
                                order['items'] ?? order['details'] ?? [];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🔹 ក្បាលវិក្កយបត្រ (Invoice Header)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.receipt_rounded,
                                              color: Colors.green,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${order['order_number'] ?? order['invoice_number'] ?? 'N/A'}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "\$${totalAmount.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 32),
                                    child: Text(
                                      "កាលបរិច្ឆេទ: ${order['date'] ?? order['created_at'] ?? ''}",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(
                                      height: 1,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                  ),

                                  // 🛒 បញ្ជីទំនិញលម្អិត (Items List)
                                  orderItems.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Text(
                                            "គ្មានទិន្នន័យទំនិញ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: orderItems.length,
                                          itemBuilder: (context, itemIndex) {
                                            final item = orderItems[itemIndex];
                                            final productName =
                                                item['product_name'] ??
                                                item['product']?['name'] ??
                                                'ទំនិញមិនស្គាល់ឈ្មោះ';
                                            final productImage =
                                                item['image_url'] ??
                                                item['product']?['image_url'] ??
                                                '';

                                            final quantity =
                                                item['quantity'] ?? 1;
                                            final unitPrice =
                                                double.tryParse(
                                                  (item['unit_price'] ??
                                                          item['price'] ??
                                                          0)
                                                      .toString(),
                                                ) ??
                                                0.0;
                                            final totalPrice =
                                                double.tryParse(
                                                  (item['total_price'] ??
                                                          (unitPrice *
                                                              quantity))
                                                      .toString(),
                                                ) ??
                                                0.0;

                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 5,
                                                  ),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.grey.shade100,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // 🖼️ រូបភាពទំនិញ
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    child:
                                                        productImage.isNotEmpty
                                                        ? Image.network(
                                                            productImage,
                                                            width: 44,
                                                            height: 44,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) => Container(
                                                                  width: 44,
                                                                  height: 44,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child: const Icon(
                                                                    Icons
                                                                        .image_not_supported,
                                                                    size: 18,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                ),
                                                          )
                                                        : Container(
                                                            width: 44,
                                                            height: 44,
                                                            color: Colors
                                                                .grey
                                                                .shade200,
                                                            child: const Icon(
                                                              Icons
                                                                  .shopping_bag_outlined,
                                                              size: 18,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                  ),
                                                  const SizedBox(width: 12),

                                                  // 📝 ឈ្មោះ និងចំនួន
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          productName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                  0xFF1E293B,
                                                                ),
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          "ចំនួន: $quantity  ×  \$${unitPrice.toStringAsFixed(2)}",
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // 💵 តម្លៃសរុបប្រចាំមុខទំនិញ
                                                  Text(
                                                    "\$${totalPrice.toStringAsFixed(2)}",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
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

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

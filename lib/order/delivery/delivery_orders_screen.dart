import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_order.dart';
import '../../msg/appSnackBar.dart';
import 'order_tracking_screen.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _deliveryOrders = [];

  final ApiOrder apiOrder = ApiOrder();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchDeliveryOrders();
  }

  Future<void> _fetchDeliveryOrders() async {
    setState(() => _isLoading = true);
    try {
      final data = await apiOrder.getDeliveryOrders();
      setState(() => _deliveryOrders = data);
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatusWithoutReload(
    int deliveryId,
    String newStatus,
  ) async {
    try {
      await apiOrder.updateDeliveryStatus(deliveryId, newStatus);
      _fetchDeliveryOrders();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _updateStatus(
    int deliveryId,
    String newStatus, {
    bool isCancel = false,
    required dynamic orderId,
  }) async {
    if (isCancel) {
      bool? confirmCancel = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "បញ្ជាក់ការបោះបង់",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: const Text(
              "តើអ្នកពិតជាចង់បោះបង់ការបញ្ជាទិញនេះមែនទេ? ទិន្នន័យទឹកប្រាក់នឹងត្រូវកែសម្រួលមកជា 0 និងคืนสตុកទំនិញវិញ។",
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "ទេ (No)",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "បោះបង់ (Yes)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (confirmCancel != true) return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      ),
    );

    try {
      bool success = false;

      if (isCancel) {
        success = await apiOrder.updateDeliveryPaymentAndStatusCancel(
          deliveryId: deliveryId,
          status: 'cancelled',
          paymentMethod: 'cancelled',
        );
      } else {
        success = await apiOrder.updateDeliveryStatus(deliveryId, newStatus);
      }

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          _fetchDeliveryOrders();
          AppSnackBar.showSuccess(
            context,
            isCancel
                ? "បានបោះបង់ និងកែប្រែទឹកប្រាក់មកជា 0 ជោគជ័យ!"
                : "បានធ្វើបច្ចុប្បន្នភាពស្ថានភាពជោគជ័យ!",
          );
        } else {
          AppSnackBar.showError(
            context,
            "បរាជ័យក្នុងការធ្វើបច្ចុប្បន្នភាពទិន្នន័យ!",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showError(context, "Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "គ្រប់គ្រងការដឹកជញ្ជូន",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          isScrollable: true,
          tabs: const [
            Tab(text: "រង់ចាំ (Pending)"),
            Tab(text: "កំពុងដឹក (On the Way)"),
            Tab(text: "បានបញ្ចប់ (Completed)"),
            Tab(text: "បានបោះបង់ (Cancelled)"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('pending'),
                _buildOrderList('on_the_way'),
                _buildOrderList('completed'),
                _buildOrderList('cancelled'),
              ],
            ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    final filteredList = _deliveryOrders
        .where(
          (o) =>
              o['delivery'] != null && o['delivery']['status'] == statusFilter,
        )
        .toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              "គ្មានទិន្នន័យដឹកជញ្ជូន ($statusFilter)",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredList.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final order = filteredList[index];
        final delivery = order['delivery'];

        Color badgeBg = Colors.orange.shade100;
        Color badgeText = Colors.orange.shade900;
        if (delivery['status'] == 'completed') {
          badgeBg = Colors.green.shade100;
          badgeText = Colors.green.shade900;
        } else if (delivery['status'] == 'cancelled') {
          badgeBg = Colors.red.shade100;
          badgeText = Colors.red.shade900;
        } else if (delivery['status'] == 'on_the_way') {
          badgeBg = Colors.blue.shade100;
          badgeText = Colors.blue.shade900;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ Header: Order Number & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 18,
                          color: Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${order['order_number']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        delivery['status'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),

                // 👤 Receiver Info
                Row(
                  children: [
                    const Icon(
                      Icons.person_pin_circle_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "អ្នកទទួល: ${delivery['receiver_name']}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${delivery['receiver_phone']}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 📍 Delivery Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ទីតាំង: ${delivery['delivery_address']}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 💰 Total Amount & Fee
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 18,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "សេវា: \$${delivery['delivery_fee'] ?? '0.00'}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "សរុប: \$${order['total_amount']}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                // 🚀 Action Buttons (ສະដែងเฉพาะสถานะທີ່ຍັງບໍ່ທັນ Completed/Cancelled)
                if (delivery['status'] == 'pending' ||
                    delivery['status'] == 'on_the_way') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (delivery['status'] == 'pending') ...[
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.delivery_dining, size: 18),
                              onPressed: () async {
                                await _updateStatusWithoutReload(
                                  delivery['id'],
                                  'on_the_way',
                                );

                                if (mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderTrackingScreen(
                                        orderId:
                                            order['order_number'] ??
                                            '#GRX123456',
                                        deliveryData: {
                                          'order_id': order['id'],
                                          'estimated_minutes': 1,
                                          'grand_total':
                                              double.tryParse(
                                                order['total_amount']
                                                    .toString(),
                                              ) ??
                                              0.0,
                                          'name':
                                              delivery['receiver_name'] ??
                                              'Driver',
                                          'phone':
                                              delivery['receiver_phone'] ?? '',
                                          'delivery_partner': 'POS Express',
                                        },
                                      ),
                                    ),
                                  );
                                  _fetchDeliveryOrders();
                                }
                              },
                              label: const Text(
                                "យកទៅដឹក",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ] else if (delivery['status'] == 'on_the_way') ...[
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              onPressed: () => _updateStatus(
                                delivery['id'],
                                'completed',
                                orderId: order['id'],
                              ),
                              label: const Text(
                                "ទទួលបានរួចរាល់",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          onPressed: () => _updateStatus(
                            delivery['id'],
                            'cancelled',
                            isCancel: true,
                            orderId: order['id'],
                          ),
                          label: const Text(
                            "បោះបង់",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

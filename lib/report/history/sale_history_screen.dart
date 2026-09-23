import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/api/api_order.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/report/history/view_order_screen.dart';

class SaleHistoryScreen extends StatefulWidget {
  const SaleHistoryScreen({super.key});

  @override
  State<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends State<SaleHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _ordersList = [];
  final ApiOrder _apiOrder = ApiOrder();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiOrder.getAllOrders();
      if (response != null && response['success'] == true) {
        setState(() {
          _ordersList = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Error fetching orders: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title:Text(
          TranslateConstants.sales_history.tr,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _ordersList.isEmpty
          ? const Center(
              child: Text(
                'គ្មានទិន្នន័យប្រវត្តិការលក់ទេ',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ordersList.length,
                itemBuilder: (context, index) {
                  final order = _ordersList[index];
                  String orderNumber =
                      order['order_number'] ??
                      order['invoice_number'] ??
                      'INV-N/A';
                  double amount =
                      double.tryParse(
                        (order['total_amount'] ?? order['total'] ?? 0)
                            .toString(),
                      ) ??
                      0.0;
                  List items = order['details'] ?? [];
                  String status = order['status'] ?? 'Completed';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        orderNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Items: ${items.length}  •  ${order['date'] ?? order['created_at'] ?? ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11.5,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewOrderScreen(orderId: order['id']),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

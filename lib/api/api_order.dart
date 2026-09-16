import 'dart:convert';
import 'package:http/http.dart' as http;

import '../order/card_manager.dart';

class ApiOrder {
  final String baseUrl = 'http://10.0.2.2:8000/api';

  Future<bool> createOrderWithPayment({
    required String orderNumber,
    required int? userId,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required String paymentMethod,
    required double amountPaid,
    required double changeAmount,
    required List<Map<String, dynamic>> items,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerAddress,
    }) async {
    try {
      print("🚀 កំពុងផ្ញើទិន្នន័យទៅកាន់: $baseUrl/orders");

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'order_number': orderNumber,
          'user_id': userId,
          'subtotal': subtotal,
          'discount_amount': discount,
          'tax_amount': tax,
          'total_amount': total,
          'payment_method': paymentMethod,
          'amount_paid': amountPaid,
          'change_amount': changeAmount,

          'customer_name': customerName,
          'customer_phone': customerPhone,
          'customer_email': customerEmail,
          'customer_address': customerAddress,

          'items': items,
        }),
      ).timeout(const Duration(seconds: 15));

      print("📥 Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("❌ API Error Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Payment Exception Error: $e");
      return false;
    }
  }





}
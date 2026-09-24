import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/baseurl/base_url_api.dart';


class ApiOrder {

  final String baseUrl = BaseUrlApi.baseurl;

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


  Future<Map<String, dynamic>> getAllOrders({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'), // 🟢 ប្តូរ endpoint ទៅតាម Laravel API របស់អ្នក (ឧ. /orders ឬ /sales)
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        // ត្រឡប់ទម្រង់ជា Map ដែលមាន success: true និង data ជា List
        if (decodedData is Map) {
          return {
            'success': true,
            'data': decodedData['data'] ?? decodedData,
          };
        } else if (decodedData is List) {
          return {
            'success': true,
            'data': decodedData,
          };
        }
      }

      return {'success': false, 'data': []};
    } catch (e) {
      print('Error fetching orders: $e');
      return {'success': false, 'data': []};
    }
  }

  Future<Map<String, dynamic>> getOrderById(int orderId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['success'] == true) {
        return {
          'success': true,
          'data': decodedData['data'], // 👈 ទិន្នន័យ Order ព្រមទាំង relations (details, customer, user, payment) នឹងស្ថិតនៅទីនេះ
        };
      } else {
        return {
          'success': false,
          'message': decodedData['message'] ?? 'Failed to load details'
        };
      }
    } catch (e) {
      print('Error fetching order detail: $e');
      return {'success': false, 'message': e.toString()};
    }
  }


}
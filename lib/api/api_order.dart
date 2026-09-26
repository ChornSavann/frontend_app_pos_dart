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
    int? customerId,
    String orderType = 'dine_in',
    String? deliveryAddress,
    double deliveryFee = 0.00,

    // 🛵 បន្ថែម Parameter សម្រាប់ Delivery ពេញលេញ
    String? pickupAddress,
    String? deliveryPartner,
    String? receiverName,
    String? receiverPhone,
    String? note,
  }) async {
    try {
      print("🚀 កំពុងផ្ញើទិន្នន័យទៅកាន់: $baseUrl/orders");

      final response = await http
          .post(
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
              'customer_id': customerId,
              'customer_name': customerName,
              'customer_phone': customerPhone,
              'customer_email': customerEmail,
              'customer_address': customerAddress,

              // 🚚 ផ្ញើតម្លៃ Order Type និង Delivery ទៅកាន់ Laravel Backend
              'order_type': orderType,
              'delivery_address': deliveryAddress,
              'delivery_fee': deliveryFee,
              'pickup_address': pickupAddress,
              'delivery_partner': deliveryPartner,
              'receiver_name': receiverName,
              'receiver_phone': receiverPhone,
              'note': note,

              'items': items,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print("📥 Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");
      print("Order Type ທີ່ເລືອກ: $orderType");

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
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData is Map) {
          return {'success': true, 'data': decodedData['data'] ?? decodedData};
        } else if (decodedData is List) {
          return {'success': true, 'data': decodedData};
        }
      }

      return {'success': false, 'data': []};
    } catch (e) {
      print('Error fetching orders: $e');
      return {'success': false, 'data': []};
    }
  }

  Future<Map<String, dynamic>> getOrderById(
    int orderId, {
    String? token,
  }) async {
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
        return {'success': true, 'data': decodedData['data']};
      } else {
        return {
          'success': false,
          'message': decodedData['message'] ?? 'Failed to load details',
        };
      }
    } catch (e) {
      print('Error fetching order detail: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // 1. ទទូលយកបញ្ជី Order Delivery
  Future<List<dynamic>> getDeliveryOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/delivery-orders'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      print("Error fetching delivery orders: $e");
      return [];
    }
  }

  // 2. ប្តូរ Status របស់ Delivery
  Future<bool> updateDeliveryStatus(int deliveryId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/deliveries/$deliveryId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print("Error updating delivery status: $e");
      return false;
    }
  }

  Future<bool> updateDeliveryPaymentAndStatus({
    required int deliveryId,
    required String status,
    required String paymentMethod,
    required double amountPaid,
    required double changeAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$deliveryId/complete-delivery'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'payment_method': paymentMethod,
          'amount_paid': amountPaid,
          'change_amount': changeAmount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("success to update payment: ${response.body}");
        return true;
      } else {
        print("Failed to update payment: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error in updateDeliveryPaymentAndStatus: $e");
      return false;
    }
  }

  Future<bool> updateDeliveryPaymentAndStatusCancel({
    required int deliveryId,
    required String status,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/cancel-order/$deliveryId'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'status': status,
          'payment_method': paymentMethod,
        }),
      );
      print("📥 Cancel Response Code: ${response.statusCode}");
      print("📥 Cancel Response Body: ${response.body}");
      if (response.statusCode == 200|| response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? true;
      }
      return false;
    } catch (e) {
      print("API Cancel Error: $e");
      return false;
    }
  }
}

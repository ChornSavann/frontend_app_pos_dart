import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/models/customer.dart';

import '../constants/baseurl/base_url_api.dart';

class ApiCustomer {
  final String baseUrl = BaseUrlApi.baseurl;
  Future<List<Customer>> getAllCustomers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        List data = jsonResponse['data'];
        return data.map((json) => Customer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load customers');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  Future<Customer?> getCustomerByPhone(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/phone/$phone'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Customer.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching customer by phone: $e');
      return null;
    }
  }

  Future<bool> createCustomer({
    required String name,
    required String email,
    String? phone,
    int points = 0,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'points': points,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error creating customer: $e');
      return false;
    }
  }

  // Future<bool> postCustomer(Map<String, dynamic> customerData) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/customers'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Accept': 'application/json',
  //       },
  //       body: jsonEncode(customerData),
  //     );
  //     print('Response Code: ${response.statusCode}');
  //     print('Response Body: ${response.body}');
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       return true;
  //     } else {
  //       return false;
  //     }
  //   } catch (e) {
  //     print('API Error: $e');
  //     return false;
  //   }
  // }
  Future<int?> postCustomer(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(data),
      );
      print('Response Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data']['id'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCustomer(
    int customerId,
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers/$customerId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(customerData),
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true || response.statusCode == 200) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('កំហុសក្នុងការអាប់ដេត៖ $e');
      return false;
    }
  }

  Future<bool> deleteCustomer(int customerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/customers/$customerId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      if (response.body.isNotEmpty) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error deleting customer: $e');
      return false;
    }
  }

  Future<List<Customer>> searchCustomersByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/search?name=$name'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<dynamic> data = jsonResponse['data'] ?? jsonResponse;

        return data.map((json) => Customer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching customer by name: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCustomerDetails(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$customerId/order'),
        headers: {
          'Accept': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error fetching customer details: $e");
      return null;
    }
  }
}

import 'dart:convert';
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

      if (response.statusCode == 201) {
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

      // Status 200 ឬ 204 មានន័យថាលុបជោគជ័យ
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      // ប្រសិនបើ API មានສົ່ງ Response មកជា JSON ត្រឡប់វិញ
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
}

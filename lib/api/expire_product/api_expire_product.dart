import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';

import '../../Productscreen/product_expire/models/expire_product_model.dart';
import '../../models/Product.dart';

class ApiExpireProduct {
  final baseUrl = BaseUrlApi.baseurl;
  Future<List<ExpireProductModel>> getAllExpireProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expire-products/index'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData['success'] == true) {
          List list = decodedData['data'];
          return list.map((item) => ExpireProductModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print("Error fetching all expire products: $e");
    }
    return [];
  }

  Future<List<Product>> getAvailableProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products-available-expire'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final raw = decoded is Map ? (decoded['data'] ?? []) : decoded;

        return (raw as List).map((item) => Product.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching available products: $e");
    }
    return [];
  }

  Future<List<ExpireProductModel>> getExpiringProductsFromTable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expiring-products-table'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = data['data'];
        return list.map((e) => ExpireProductModel.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching expire products: $e");
    }
    return [];
  }

  Future<bool> createExpireProductApi({
    required int productId,
    required String startDate,
    required String expireDate,
    String? batchNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expire-products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'product_id': productId,
          'start_date': startDate,
          'expire_date': expireDate,
          'batch_number': batchNumber,
        }),
      );
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      print("Error creating expire product: $e");
    }
    return false;
  }

  Future<bool> updateExpireProduct(
    int id,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expire-products/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print("Error updating expire product: $e");
    }
    return false;
  }

  Future<ExpireProductModel?> getExpireProductById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expire-products/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData['success'] == true) {
          return ExpireProductModel.fromJson(decodedData['data']);
        }
      }
    } catch (e) {
      print("Error fetching detail: $e");
    }
    return null;
  }

  Future<bool> deleteExpireProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/expire-products/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print("Error deleting expire product: $e");
    }
    return false;
  }
}

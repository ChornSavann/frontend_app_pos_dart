import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/Product.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';

class ApiPurchase {
  final String baseUrl = 'http://10.0.2.2:8000/api';

  Future<bool> createPurchase(PurchaseModel purchase, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchases'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(purchase.toJson()), // 👈 ដូរមកជា toJson() (J ធំ)
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Failed to create purchase. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error on createPurchase: $e');
      return false;
    }
  }


  Future<bool> updatePurchase(dynamic id, PurchaseModel purchase, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchases/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(purchase.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to update purchase. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error on updatePurchase: $e');
      return false;
    }
  }

  // 🗑️ មុខងារ Delete Purchase (DELETE Request)
  Future<bool> deletePurchase(dynamic id, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/purchases/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Failed to delete purchase. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error on deletePurchase: $e');
      return false;
    }
  }
  Future<List<Product>> fetchProducts({String? token}) async {
    try {
      // ⚠️ បានកែត្រង់នេះដោយបន្ថែម '$baseUrl/products'
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        // ទាញយកទិន្នន័យពី JSON structure របស់ Laravel API
        List dataList;
        if (decodedData is Map && decodedData.containsKey('data')) {
          dataList = decodedData['data'];
        } else if (decodedData is List) {
          dataList = decodedData;
        } else {
          dataList = [];
        }

        return dataList.map((dynamic item) {
          return Product.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception(
          "Failed to load products. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }
  Future<List<Supplier>> getAllSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/suppliers'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List listJson = data['data'];
        return listJson.map((json) => Supplier.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load suppliers: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<PurchaseModel>> getAllPurchases({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/purchases'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List dataList;
        if (decodedData is Map && decodedData.containsKey('data')) {
          dataList = decodedData['data'];
        } else if (decodedData is List) {
          dataList = decodedData;
        } else {
          dataList = [];
        }

        return dataList.map((json) => PurchaseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load purchases. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error on getAllPurchases: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getPurchaseById(int purchaseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/purchases/$purchaseId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {

      print('Error fetching purchase by ID: $e');
      return null;
    }
  }
}
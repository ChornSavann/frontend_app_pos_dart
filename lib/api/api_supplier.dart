import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/baseurl/base_url_api.dart';
import '../models/supplier.dart';

class ApiSupplier {
  final String baseUrl = BaseUrlApi.baseurl;

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

  Future<Supplier> createSupplier(Supplier supplier) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/suppliers'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(supplier.toJson()),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          data['success'] == true) {
        return Supplier.fromJson(data['data']);
      } else {
        throw Exception('Failed to create supplier: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Supplier> updateSupplier(int id, Supplier supplier) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(supplier.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Supplier.fromJson(data['data']);
      } else {
        throw Exception('Failed to update supplier: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

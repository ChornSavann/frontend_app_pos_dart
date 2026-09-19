import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../constants/baseurl/base_url_api.dart';
import '../../expensetype/models/expense_type.dart';

class ApiExpensetype {

  final String baseUrl = BaseUrlApi.baseurl;

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // 'Authorization': 'Bearer YOUR_TOKEN', // បើមាន Token ដាក់បន្ថែមទីនេះ
  };

  Future<List<ExpenseType>> fetchExpenseType() async {
    try {
      final url = Uri.parse('$baseUrl/expense-types');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> decodedData = jsonResponse['data'] ?? jsonResponse;

        return decodedData.map((item) {
          return ExpenseType.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception(
          "Failed to load expense types. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching expense types: $e");
    }
  }

  Future<bool> createExpenseType({
    required String name,
    required String description,
  }) async {
    try {
      final Uri url = Uri.parse('$baseUrl/expense-types/create');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'name': name, 'description': description}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error creating expense type: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> updateExpenseType({
    required int id,
    required String name,
    required String description,
  }) async {
    try {
      final Uri url = Uri.parse('$baseUrl/expense-types/update/$id');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Error updating expense type: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }


  Future<bool> deleteExpenseType(int id) async {
    try {
      final Uri url = Uri.parse('$baseUrl/expense-types/delete/$id');

      final response = await http.delete(
        url,
        headers: headers,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("Error deleting expense type: $e");
      return false;
    }
  }
}

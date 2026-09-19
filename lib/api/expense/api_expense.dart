import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/baseurl/base_url_api.dart';
import '../../expenses/models/expense.dart';

class ApiExpense {
  final String baseUrl = BaseUrlApi.baseurl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Expense>> fetchExpenses() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = data is List ? data : (data['data'] ?? []);

        return list.map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetchExpenses: $e');
      return [];
    }
  }

  Future<bool> createExpense(Expense expense) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/expenses/create'),
        headers: headers,
        body: jsonEncode(expense.toJson()),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error createExpense: $e');
      return false;
    }
  }

  Future<bool> updateExpense(int id, Expense expense) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/expenses/update/$id'),
        headers: headers,
        body: jsonEncode(expense.toJson()),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error updateExpense: $e');
      return false;
    }
  }

  // 🔍 Function ទាញយក Expense តាម ID
  Future<Expense?> fetchExpenseById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/expenses/$id'));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return Expense.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      print("Error fetching expense by id: $e");
    }
    return null;
  }

  Future<bool> deleteExpense(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/delete/$id'),
        headers: headers,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleteExpense: $e');
      return false;
    }
  }
}

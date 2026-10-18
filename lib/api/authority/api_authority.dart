import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';

import '../../login/authority/models/authority_log_model.dart';

class AuthorityApiService {
  static final String baseUrl = BaseUrlApi.baseurl;

  // 1. ផ្ញើ Log ពេល Login ឬ Logout
  static Future<void> sendAuthLog(String userId, String action) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth-logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'action': action, // 'LOGIN' ឬ 'LOGOUT'
        }),
      );
    } catch (e) {
      print("Error sending auth log: $e");
    }
  }

  // 2. ទាញយកប្រវត្តិ Log ទាំងអស់មកបង្ហាញ
  static Future<List<dynamic>> fetchAuthLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/auth-logs'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error fetching logs: $e");
    }
    return [];
  }
  // 3. 🟢 ទាញយកព័ត៌មានលម្អិត Log តាមរយៈ ID (Get Detail Log)
  static Future<AuthLogModel?> fetchAuthLogDetail(int logId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/auth-logs/$logId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return AuthLogModel.fromJson(data['data']);
        }
      }
    } catch (e) {
      print("Error fetching log detail: $e");
    }
    return null;
  }
}
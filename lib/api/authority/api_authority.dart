import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login/authority/models/authority_log_model.dart';
import 'api_helper.dart';
class AuthorityApiService {
  static final String baseUrl = BaseUrlApi.baseurl;
  static Future<void> sendAuthLog(String userId, String action) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth-logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'action': action,
        }),
      );
    } catch (e) {
      print("Error sending auth log: $e");
    }
  }


  static Future<List<dynamic>> fetchAuthLogs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/auth-logs'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        print("⚠️ Unauthorized: Token expired or invalid!");
         ApiHelper.handleUnauthorized();
        return [];
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error fetching logs: $e");
    }
    return [];
  }


  static Future<AuthLogModel?> fetchAuthLogDetail(int logId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/auth-logs/$logId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
         ApiHelper.handleUnauthorized();
        return null;
      }

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

  static Future<bool> forceLogoutUser(int userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? adminToken = prefs.getString('token');

      final url = '$baseUrl/users/$userId/force-logout';
      print("🌐 API URL: $url");
      print("🔑 Admin Token: $adminToken");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 401) {
        print("⚠️ Admin token expired or unauthorized!");
         ApiHelper.handleUnauthorized();
      }

      return false;
    } catch (e) {
      print("❌ Error force logout user: $e");
      return false;
    }
  }


  static Future<bool> deleteAuthLog(int logId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/auth-logs/$logId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
         ApiHelper.handleUnauthorized();
        return false;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("Error deleting auth log: $e");
      return false;
    }
  }


  static Future<int> verifyTokenStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null || token.isEmpty) return 401;

      final response = await http.get(
        Uri.parse('$baseUrl/user-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("🔎 API Check Status: ${response.statusCode} | Body: ${response.body}");
      return response.statusCode;
    } catch (e) {
      print("❌ Error verifying token: $e");
      return 500;
    }
  }
}
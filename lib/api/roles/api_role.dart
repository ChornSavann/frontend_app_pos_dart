import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';
import 'package:pos_inventory/users/roles/models/role.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiRole {
  final String baseUrl = BaseUrlApi.baseurl;
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  final Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<dynamic>> fetchRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/roles'),
        headers: _headers,
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          return decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          return decodedData['data'];
        }
        return [];
      } else {
        throw Exception('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching roles: $e");
      throw Exception('Connection error: $e');
    }
  }

  Future<Role> createRole(String name, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/roles/create'),
        headers: _headers,
        body: json.encode({'name': name, 'description': description}),
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      final decodedData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final roleJson = decodedData is Map && decodedData.containsKey('data')
            ? decodedData['data']
            : decodedData;

        return Role.fromJson(roleJson);
      } else {
        throw Exception(decodedData['message'] ?? 'បរាជ័យក្នុងការបង្កើត Role');
      }
    } catch (e) {
      debugPrint("Error creating role: $e");
      throw Exception('Connection error: $e');
    }
  }

  Future<Map<String, dynamic>> assignRoleToEmployee(
    String employeeId,
    String roleId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees/$employeeId/assign-role'),
        headers: _headers,
        body: json.encode({'roleId': roleId}),
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      final decodedData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              decodedData['message'] ?? 'បានកំណត់ Role ជូនបុគ្គលិកជោគជ័យ!',
        };
      } else {
        return {
          'success': false,
          'message': decodedData['message'] ?? 'បរាជ័យក្នុងការកំណត់ Role!',
        };
      }
    } catch (e) {
      debugPrint("Error assigning role: $e");
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<dynamic> getRoleWithPermissions(String roleId) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/roles/$roleId/permissions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Get Role With Permissions Status: ${response.statusCode}");
      debugPrint("Get Role With Permissions Body: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is Map) {
          if (decodedData.containsKey('data')) {
            return decodedData['data'];
          }
          return decodedData;
        }

        throw Exception('ទ្រង់ទ្រាយទិន្នន័យពី Server មិនត្រឹមត្រូវ');
      } else {
        throw Exception(
          'មិនអាចទាញយកទិន្នន័យ Role បានទេ (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint("Error fetching role with permissions: $e");
      throw Exception('Connection error: $e');
    }
  }

  Future<Map<String, dynamic>> updateRole(
    String id,
    String name,
    String description,
  ) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/roles/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name, 'description': description}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'កែប្រែ Role បានជោគជ័យ!',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'មិនអាចកែប្រែ Role នេះបានទេ',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error updating role: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteRole(String id) async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/roles/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': data['message'] ?? 'បានលុប Role ជោគជ័យ!',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'មិនអាចលុប Role នេះបានទេ',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error deleting role: $e'};
    }
  }
}

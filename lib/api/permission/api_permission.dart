import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';
import 'package:pos_inventory/users/permission/models/permission.dart';

class ApiPermission {
  final String baseUrl = BaseUrlApi.baseurl;
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Permission>> fetchPermissions() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/permissions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Fetch Permissions Status: ${response.statusCode}");
      debugPrint("Fetch Permissions Body: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        List listData = [];
        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          listData = decodedData['data'];
        }

        return listData.map((json) => Permission.fromJson(json)).toList();
      } else {
        throw Exception('បរាជ័យในการទាញយកទិន្នន័យ Permissions');
      }
    } catch (e) {
      debugPrint("Error fetching permissions: $e");
      throw Exception('Connection error: $e');
    }
  }

  Future<Permission> createPermission(String name, String description) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/permissions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name, 'description': description}),
      );

      debugPrint("Create Permission Status: ${response.statusCode}");
      debugPrint("Create Permission Body: ${response.body}");

      final decodedData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final permissionJson =
            decodedData is Map && decodedData.containsKey('data')
            ? decodedData['data']
            : decodedData;

        return Permission.fromJson(permissionJson);
      } else {
        throw Exception(
          decodedData['message'] ?? 'បរាជ័យក្នុងការបង្កើត Permission',
        );
      }
    } catch (e) {
      debugPrint("Error creating permission: $e");
      throw Exception('Connection error: $e');
    }
  }

  Future<Permission> getPermissionById(String id) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/permissions/$id/edit'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        dynamic permissionJson = data['data'] ?? data;
        if (permissionJson is List) {
          if (permissionJson.isNotEmpty) {
            permissionJson = permissionJson[0];
          } else {
            throw Exception('រកមិនឃើញទិន្នន័យ Permission ទេ');
          }
        }

        return Permission.fromJson(permissionJson);
      } else {
        throw Exception(data['message'] ?? 'រកមិនឃើញ Permission នេះទេ');
      }
    } catch (e) {
      throw Exception('Error fetching permission: $e');
    }
  }

  Future<Permission> updatePermission(
    String id,
    String name,
    String description,
  ) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/permissions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name, 'description': description}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final permissionData = data['data'] ?? data;
        return Permission.fromJson(permissionData);
      } else {
        throw Exception(
          data['message'] ?? 'មិនអាចកែប្រែទិន្នន័យ Permission បានទេ',
        );
      }
    } catch (e) {
      throw Exception('Error updating permission: $e');
    }
  }

  Future<Map<String, dynamic>> deletePermission(String id) async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/permissions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'លុប Permission បានជោគជ័យ',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'មិនអាចលុប Permission នេះបានទេ',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error deleting permission: $e'};
    }
  }

  Future<Map<String, dynamic>> getRoleWithPermissions(String roleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/roles/$roleId/permissions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Beare $_getToken()',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('មិនអាចទាញយកទិន្នន័យ Role បានទេ');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> assignPermissionsToRole(
    String roleId,
    List<int> permissionIds,
  ) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/permissions/assign/$roleId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'permission_ids': permissionIds}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'បានកំណត់សិទ្ធិជោគជ័យ!',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'មានបញ្ហាក្នុងការកំណត់សិទ្ធិ',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}

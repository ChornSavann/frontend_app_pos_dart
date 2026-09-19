import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/models/Unit.dart';

import '../constants/baseurl/base_url_api.dart';

class ApiUnit {

  final String baseUrl = BaseUrlApi.baseurl;

  Future<List<UnitModel>> fetchUnits() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/units'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);

        List<dynamic> data = [];
        if (decodedBody is List) {
          data = decodedBody;
        } else if (decodedBody is Map) {
          if (decodedBody.containsKey('data') && decodedBody['data'] is List) {
            data = decodedBody['data'];
          } else if (decodedBody.containsKey('units') &&
              decodedBody['units'] is List) {
            data = decodedBody['units'];
          }
        }

        return data.map((json) => UnitModel.fromJson(json)).toList();
      } else {
        debugPrint("Failed to load units: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("API Error: $e");
      return [];
    }
  }

  // ➕ Create Unit
  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/units'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Unit created successfully!'};
      } else {
        var decoded = jsonDecode(response.body);
        String msg = decoded['message'] ?? 'Failed to create unit';
        if (decoded.containsKey('errors')) {
          msg = decoded['errors'].values.first[0].toString();
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      debugPrint("Error Exception: $e");
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ✏️ Update Unit
  Future<Map<String, dynamic>> updateUnit(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/units/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Unit updated successfully!'};
      } else {
        var decoded = jsonDecode(response.body);
        String msg = decoded['message'] ?? 'Failed to update unit';
        if (decoded.containsKey('errors')) {
          msg = decoded['errors'].values.first[0].toString();
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ❌ Delete Unit
  Future<bool> deleteUnit(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/units/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("Delete Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("Error deleting unit: $e");
      return false;
    }
  }
}

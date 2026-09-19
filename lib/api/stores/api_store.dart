import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../stores/models/store.dart';

class ApiStore {
  final String baseUrl = "http://10.0.2.2:8000/api";
  // final header='Accept': 'application/json;
  Future<List<Store>> fetchStoreInfo() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/store'));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> listData = decodedData is List
            ? decodedData
            : decodedData['data'];

        return listData.map((item) => Store.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching Store: $e");
    }
    return [];
  }

  Future<bool> createStore({
    required String name,
    required String phone,
    required String email,
    String? website,
    required String address,
    String? description,
    String? logoPath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/store/create'),
      );

      request.fields['name'] = name;
      request.fields['phone'] = phone;
      request.fields['email'] = email;
      if (website != null) request.fields['website'] = website;
      request.fields['address'] = address;
      if (description != null) request.fields['description'] = description;

      if (logoPath != null && logoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('logo', logoPath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error creating store: $e");
      return false;
    }
  }


  Future<Map<String, dynamic>?> fetchStoreDetails(int storeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/store/edit/$storeId'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] ?? decoded;
      }
    } catch (e) {
      print('Error fetching store details: $e');
    }
    return null;
  }

  // 🚀 2. Function Update Store (รองรับการอัปโหลด Logo រូបភាពថ្មី)
  Future<bool> updateStore({
    required int storeId,
    required String name,
    required String phone,
    required String email,
    String? website,
    required String address,
    String? description,
    String? logoPath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/store/update/$storeId'));

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['_method'] = 'POST';
      request.fields['name'] = name;
      request.fields['phone'] = phone;
      request.fields['email'] = email;
      if (website != null) request.fields['website'] = website;
      request.fields['address'] = address;
      if (description != null) request.fields['description'] = description;


      if (logoPath != null && logoPath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'logo',
            logoPath,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("Response Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error updating store: $e');
      return false;
    }
  }

  // 🗑️ Delete Store API
  Future<bool> deleteStore(int storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.delete(
        Uri.parse('$baseUrl/store/destroy/$storeId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete store: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting store: $e');
      return false;
    }
  }
}

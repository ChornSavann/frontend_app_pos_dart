import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/models/brand.dart';

import '../constants/baseurl/base_url_api.dart';
class ApiBrand {

  final String baseUrl = BaseUrlApi.baseurl;

  Future<List<BrandModel>> fetchBrands() async {
    try
    {
      final response = await http.get(Uri.parse('$baseUrl/brands'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = data is List ? data : (data['data'] ?? []);
        return list.map((json) => BrandModel.fromJson(json)).toList();
      }
      else {
        throw Exception('Failed to load brands');
      }
    } catch (e) {
      print("Error fetching brands: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> createBrand({
    required String name,
    String? description,
    File? logoFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/brands'));


      request.fields['name'] = name;
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }


      if (logoFile != null) {
        var stream = http.ByteStream(logoFile.openRead());
        var length = await logoFile.length();
        var multipartFile = http.MultipartFile(
          'logo',
          stream,
          length,
          filename: logoFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Brand created successfully!',
          'data': responseData['data'] != null
              ? BrandModel.fromJson(responseData['data'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create brand',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }


  Future<Map<String, dynamic>> updateBrand({
    required int id,
    required String name,
    String? description,
    File? logoFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/brands/$id'),
      );

      request.fields['name'] = name;
      if (description != null) {
        request.fields['description'] = description;
      }

      if (logoFile != null) {
        var stream = http.ByteStream(logoFile.openRead());
        var length = await logoFile.length();
        var multipartFile = http.MultipartFile(
          'logo',
          stream,
          length,
          filename: logoFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Brand updated successfully!',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update brand',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }


  Future<bool> deleteBrand(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/brands/$id'));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error deleting brand: $e");
      return false;
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../constants/baseurl/base_url_api.dart';
import '../models/user.dart';

class ApiUser {

  final String baseUrl = BaseUrlApi.baseurl;

  Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List jsonList = data['data'] ?? data;
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load users');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    File? image, // 🖼️ បញ្ចូល image មកទីនេះវិញ ដើម្បីកុំឱ្យបាត់
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register'),
      );

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      if (phone != null) {
        request.fields['phone'] = phone;
      }

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      request.headers.addAll({'Accept': 'application/json'});

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUser({
    required int id,
    required String name,
    required String email,
    String? password,
    required String phone,
    File? image,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/$id'),
      );

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['phone'] = phone;

      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      request.headers.addAll({'Accept': 'application/json'});

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'User updated successfully!',
          'user': User.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'User deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}

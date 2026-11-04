import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../constants/baseurl/base_url_api.dart';
import '../models/category.dart';

class ApiCategory {
  final String baseUrl = BaseUrlApi.baseurl;
  // Future<List<dynamic>> fetchCategory() async {
  //   final response = await http.get(Uri.parse('$baseUrl/categories'));
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     return data['data'];
  //   } else {
  //     throw Exception("Error data response");
  //   }
  // }

  Future<List<CategoryModel>> fetchCategory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List data = decodedData is Map ? (decodedData['data'] ?? []) : decodedData;
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception("Error data response: ${response.statusCode}");
      }
    } catch (e) {
      print("Fetch Categories Error: $e");
      throw Exception("Failed to load categories: $e");
    }
  }

  Future<bool> createCategory(
    String name,
    String description,
    File? imageFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/categories'),
      );

      request.headers.addAll({"Accept": "application/json"});

      request.fields['name'] = name;
      request.fields['description'] = description;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Server Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception Error: $e");
      return false;
    }
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CategoryModel.fromJson(data['data'] ?? data);
      } else {
        debugPrint("Failed to load category details: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching category detail: $e");
      return null;
    }
  }

  Future<bool> updateCategory(
    int id,
    String name,
    String description,
    File? imageFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/categories/$id'),
      );

      request.headers.addAll({"Accept": "application/json"});

      request.fields['name'] = name;
      request.fields['description'] = description;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Update Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception Error: $e");
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      return false;
    } catch (e) {
      print("Delete Error: $e");
      return false;
    }
  }
}

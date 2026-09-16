
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiCategory {
  final String baseUrl = 'http://10.0.2.2:8000/api';
  Future<List<dynamic>> fetchCategory() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception("Error data response");
    }
  }

  // //create
  // Future<bool> createCategory(String name, String description) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/categories'),
  //       headers: {
  //         "Content-Type": "application/json", // ប្រាប់ Laravel ថាផ្ញើជា JSON
  //         "Accept": "application/json", // ប្រាប់ Laravel ថាចង់បានលទ្ធផលជា JSON
  //       },
  //       body: jsonEncode({"name": name, "description": description}),
  //     );
  //
  //     if (response.statusCode == 201 || response.statusCode == 200) {
  //       return true;
  //     } else {
  //       print("Server Error: ${response.body}");
  //       return false;
  //     }
  //   } catch (e) {
  //     print("Exception Error: $e");
  //     return false;
  //   }
  // }

  Future<bool> createCategory(String name, String description, File? imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/categories'),
      );

      request.headers.addAll({
        "Accept": "application/json",
      });

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
  //update
  //
  // Future<bool> updateCategory(int id, String name, String description) async {
  //   try {
  //     final response = await http.put(
  //       Uri.parse(
  //         '$baseUrl/categories/$id',
  //       ),
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Accept": "application/json",
  //       },
  //       body: jsonEncode({"name": name, "description": description}),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       return true;
  //     } else {
  //       print("Update Error: ${response.body}");
  //       return false;
  //     }
  //   } catch (e) {
  //     print("Exception Error: $e");
  //     return false;
  //   }
  // }

  Future<bool> updateCategory(int id, String name, String description, File? imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/categories/$id'),
      );

      request.headers.addAll({
        "Accept": "application/json",
      });

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

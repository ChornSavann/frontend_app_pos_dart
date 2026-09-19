import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';
import 'package:pos_inventory/login/plash_screnn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class ApiAuth {


  final String baseUrl = BaseUrlApi.baseurl;
  static Future<void> handleSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
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

  // Future<Map<String, dynamic>> login({
  //   required String email,
  //   required String password,
  // }) async {
  //     try {
  //       final response = await http.post(
  //         Uri.parse('$baseUrl/login'),
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Accept': 'application/json',
  //         },
  //         body: jsonEncode({'email': email, 'password': password}),
  //       );
  //
  //       final data = jsonDecode(response.body);
  //
  //       if (response.statusCode == 200) {
  //         final userData = data['data']['user'] ?? data['user'] ?? data;
  //         final token = data['data']['token'] ?? data['token'] ?? '';
  //
  //         String userName = userData['name'] ?? "Chorn Savann";
  //         String userEmail = userData['email'] ?? email;
  //         String userPhone = userData['phone'] ?? "";
  //         String userRole = userData['role'] ?? "Cashier • Register #01";
  //         String userAvatar =
  //             userData['image'] ??
  //             "https://i.pinimg.com/736x/a4/dc/0b/a4dc0b965816c932da67f6e32af547cc.jpg";
  //         int? userId = userData['id'];
  //
  //         // រក្សាទុកទិន្នន័យចូល SharedPreferences
  //         final prefs = await SharedPreferences.getInstance();
  //         if (userId != null) {
  //           await prefs.setInt('user_id', userId);
  //         }
  //         await prefs.setString('token', token);
  //         await prefs.setString('name', userName);
  //         await prefs.setString('email', userEmail);
  //         await prefs.setString('phone', userPhone);
  //         await prefs.setString('role', userRole);
  //         await prefs.setString('image', userAvatar);
  //
  //         return {'success': true, 'data': data};
  //       } else {
  //         return {
  //           'success': false,
  //           'message': data['message'] ?? 'Invalid credentials',
  //         };
  //       }
  //     } catch (e) {
  //       return {'success': false, 'message': 'Network error: $e'};
  //     }
  // }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login-user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      // ឆែកមើលថាបើ Response Body ទទេស្អាត
      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Server returned empty response.'};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data == null) {
          return {'success': false, 'message': 'Data representation is null'};
        }

        final userData = data['data']?['user'] ?? data['user'] ?? data;
        final token = data['data']?['token'] ?? data['token'] ?? '';

        if (userData == null || userData is! Map) {
          return {'success': false, 'message': 'User profile data missing.'};
        }

        String userName = userData['name'] ?? "Chorn Savann";
        String userEmail = userData['email'] ?? email;
        String userPhone = userData['phone'] ?? "";
        String userRole = userData['role'] ?? "Cashier • Register #01";
        int? userId = userData['id'];

        String rawImage = userData['image'] ?? "";
        String userAvatar;

        if (rawImage.isNotEmpty) {
          if (rawImage.startsWith('http')) {
            userAvatar = rawImage;
          } else {
            if (rawImage.startsWith('users/')) {
              userAvatar = 'http://10.0.2.2:8000/$rawImage';
            } else {
              userAvatar = 'http://10.0.2.2:8000/storage/$rawImage';
            }
          }
        } else {
          userAvatar =
              "https://i.pinimg.com/736x/a4/dc/0b/a4dc0b965816c932da67f6e32af547cc.jpg";
        }

        final prefs = await SharedPreferences.getInstance();
        if (userId != null) {
          await prefs.setInt('user_id', userId);
        }
        await prefs.setString('token', token);
        await prefs.setString('name', userName);
        await prefs.setString('email', userEmail);
        await prefs.setString('phone', userPhone);
        await prefs.setString('role', userRole);
        await prefs.setString('image', userAvatar);

        // // 🔍 យកទិន្នន័យ store ពី Response មក Save ទុក
        // final storeData = data['store']; // យោងតាម JSON ថ្មីខាង Laravel ផ្ញើមកមាន 'store' ផ្ទាល់
        // if (storeData != null && storeData is Map) {
        //   await prefs.setInt('store_id', storeData['id'] ?? 1);
        //   await prefs.setString('store_name', storeData['name'] ?? "ហាងខ្មែរ");
        //   await prefs.setString('store_logo', storeData['logo'] ?? ""); // 👈 ឥឡូវ Logo នឹងត្រូវ Save ចូល SharedPreferences ហើយ
        // }

        return {'success': true, 'data': data};
      } else {
        String errorMessage = 'Invalid credentials';
        if (data != null && data is Map) {
          if (data['message'] != null) {
            errorMessage = data['message'];
          } else if (data['errors'] != null) {
            // ករណីជួប Laravel Validation Error (ដូចជា អ៊ីមែលខុសទម្រង់)
            errorMessage = data['errors'].toString();
          }
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      await prefs.clear();
      return true;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    }
  }

  Future<String?> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? oldToken = prefs.getString('token');

      if (oldToken == null || oldToken.isEmpty) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $oldToken',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String newToken = data['token'] ?? '';

        if (newToken.isNotEmpty) {
          // 💾 រក្សាទុក Token ថ្មីចូល SharedPreferences ជំនួសអាសចាស់
          await prefs.setString('token', newToken);
          return newToken;
        }
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    File? image,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getInt('user_id');

      print("Current User ID: $userId");
      if (userId == null) {
        return {
          'success': false,
          'message': 'User ID not found in local storage. Please login again.',
        };
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/$userId'),
      );

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['phone'] = phone;

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200 && (data['success'] == true)) {
        await prefs.setString('name', name);
        await prefs.setString('email', email);
        await prefs.setString('phone', phone);

        if (data['data'] != null && data['data']['image'] != null) {
          String rawImage = data['data']['image'];
          String userAvatar;

          if (rawImage.startsWith('http')) {
            userAvatar = rawImage;
          } else if (rawImage.startsWith('users/')) {
            userAvatar = 'http://10.0.2.2:8000/$rawImage';
          } else {
            userAvatar = 'http://10.0.2.2:8000/users/$rawImage';
          }

          await prefs.setString('image', userAvatar);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.put(
        Uri.parse('$baseUrl/profile/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message':
              data['message'] ??
              'Password reset instructions sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Email not found in system',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update password',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}

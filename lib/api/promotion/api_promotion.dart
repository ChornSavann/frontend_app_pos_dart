import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/Productscreen/models/product_promotion_model.dart';
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';

class ApiPromotion {
  final String baseUrl = BaseUrlApi.baseurl;

  Future<List<ProductPromotionModel>> fetchPromotions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product-promotions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List listData = data['data'] ?? data;

        return listData
            .map((item) => ProductPromotionModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load promotions: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching promotions: $e');
    }
  }

  Future<Map<String, dynamic>> createPromotion(
    Map<String, dynamic> promotionData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/product-promotions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(promotionData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              responseBody['message'] ?? 'Promotion created successfully',
          'data': responseBody['data'] != null
              ? ProductPromotionModel.fromJson(responseBody['data'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to create promotion',
          'errors': responseBody['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<bool> updateStatus(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/product-promotions/$id/update-active'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePromotionStatus(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/product-promotions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePromotion(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/product-promotions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/Productscreen/models/product_model_banner.dart';
import 'package:pos_inventory/models/Product.dart';

import 'dart:io';

import '../constants/baseurl/base_url_api.dart';
import '../helpers/shared_preferences_helper.dart';
import '../models/brand.dart';
import '../models/category.dart';

class ApiProduct {

  final String baseUrl = BaseUrlApi.baseurl;


  Future<List<Product>> fetchProducts({int? categoryId, int? brandId}) async {
    try {
      String url = '$baseUrl/products';

      if (categoryId != null && categoryId != 0) {
        url = '$baseUrl/products/category/$categoryId';
      } else if (brandId != null && brandId != 0) {
        url = '$baseUrl/products/brand/$brandId';
      }
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> decodedData = jsonResponse['data'];

        return decodedData.map((dynamic item) {
          return Product.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception(
          "Failed to load products. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    try {
      var uri = Uri.parse('$baseUrl/products');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
      });

      request.fields['name']           = data['name']?.toString() ?? '';
      request.fields['sku']            = data['sku']?.toString() ?? '';
      request.fields['barcode']        = data['barcode']?.toString() ?? '';
      request.fields['cost_price']     = data['cost_price']?.toString() ?? '0.0';
      request.fields['selling_price']  = data['selling_price']?.toString() ?? '0.0';
      request.fields['stock_quantity'] = data['stock_quantity']?.toString() ?? '0';
      request.fields['category_id']    = data['category_id']?.toString() ?? '';
      request.fields['brand_id']       = data['brand_id']?.toString() ?? '1';
      request.fields['unit_id']        = data['unit_id']?.toString() ?? '1';
      request.fields['description']    = data['description']?.toString() ?? '';


      if (data['image'] != null && data['image'].toString().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', data['image']),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Product created successfully!'};
      } else {
        try {
          var decodedData = jsonDecode(response.body);
          String errorMessage = "Failed to create product";

          if (decodedData is Map) {
            if (decodedData.containsKey('errors')) {
              var errors = decodedData['errors'];
              if (errors is Map && errors.isNotEmpty) {
                errorMessage = errors.values.first[0].toString();
              }
            } else if (decodedData.containsKey('message')) {
              errorMessage = decodedData['message'];
            }
          }

          return {'success': false, 'message': errorMessage};
        } catch (jsonErr) {
          return {
            'success': false,
            'message': 'Server Error (${response.statusCode}): សូមពិនិត្យមើល Laravel Terminal របស់អ្នក!'
          };
        }
      }
    } catch (e) {
      debugPrint("Error Exception: $e");
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<List<dynamic>> fetchUnits() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/units'));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to load units');
      }
    } catch (e) {
      print("Error fetching units: $e");
      return [];
    }
  }


  Future<Map<String, dynamic>> updateProduct(Map<String, dynamic> data) async {
    try {
      final productId = data['id'];
      final url = Uri.parse('$baseUrl/products/$productId');
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Accept': 'application/json',
      });

      request.fields['name']           = data['name']?.toString() ?? '';
      request.fields['sku']            = data['sku']?.toString() ?? '';
      request.fields['barcode']        = data['barcode']?.toString() ?? '';
      request.fields['cost_price']     = data['cost_price']?.toString() ?? '0.0';
      request.fields['selling_price']  = data['selling_price']?.toString() ?? '0.0';
      request.fields['stock_quantity'] = data['stock_quantity']?.toString() ?? '0';
      request.fields['category_id']    = data['category_id']?.toString() ?? '';
      request.fields['brand_id']       = data['brand_id']?.toString() ?? '';
      request.fields['unit_id']        = data['unit_id']?.toString() ?? '';
      request.fields['description']    = data['description']?.toString() ?? '';

      if (data['image'] != null) {
        if (data['image'] is File) {
          File imageFile = data['image'];
          request.files.add(
            await http.MultipartFile.fromPath('image', imageFile.path),
          );
        } else if (data['image'] is String && data['image'].toString().isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath('image', data['image']),
          );
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Product updated successfully!'};
      } else {
        try {
          var decodedData = jsonDecode(response.body);
          String errorMessage = "Failed to update product";

          if (decodedData is Map) {
            if (decodedData.containsKey('errors')) {
              var errors = decodedData['errors'];
              if (errors is Map && errors.isNotEmpty) {
                errorMessage = errors.values.first[0].toString();
              }
            } else if (decodedData.containsKey('message')) {
              errorMessage = decodedData['message'];
            }
          }
          return {'success': false, 'message': errorMessage};
        } catch (jsonErr) {
          return {'success': false, 'message': 'Server Error (${response.statusCode}): ${response.body.substring(0, 100)}...'};
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final url = Uri.parse('$baseUrl/products/$id');
      final response = await http.delete(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("Deleted Successfully: ${response.body}");
        return true;
      } else {
        debugPrint("Delete Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("API Error: $e");
      return false;
    }
  }


  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> decodedData = jsonResponse['data'];

        return decodedData.map((dynamic item) {
          return CategoryModel.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception(
          "Failed to load categories. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching categories: $e");
    }
  }

  Future<List<BrandModel>> fetchBrands() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/brands'));

      debugPrint("Brand Response Code: ${response.statusCode}");
      debugPrint("Brand Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list = decoded is List ? decoded : (decoded['data'] ?? []);

        return list.map((item) => BrandModel.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching brands catch: $e");
      return [];
    }
  }

  Future<int> fetchProductCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/count'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to load product count');
      }
    } catch (e) {
      print("Error: $e");
      return 0;
    }
  }

  Future<Product> getProductById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        return Product.fromJson(jsonResponse['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Product data not found in response');
      }
    } else {
      throw Exception('Failed to load product details (Status Code: ${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    try {
      String? token = await SharedPrefsHelper.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/favorites/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_id': productId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'is_favorite': data['is_favorite'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update favorite status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<ProductModelBanner>> fetchProductsandcategory({int? categoryId}) async {
    try {
      String url = (categoryId == null || categoryId == 0)
          ? '$baseUrl/products'
          : '$baseUrl/products/category/$categoryId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> decodedData = jsonResponse['data'] ?? [];

        return decodedData.map((dynamic item) {
          return ProductModelBanner.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception(
          "Failed to load products. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }

}

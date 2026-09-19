import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../constants/baseurl/base_url_api.dart';
import '../../models/customer.dart';
import '../../models/reports/report_daily.dart';

class ApiReport {
  final BaseUrlApi baseUrlApi = BaseUrlApi();
  final String baseUrl = BaseUrlApi.baseurl;

  Future<List<ReportDaily>> fetchDailyReports() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/reports/daily"));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> listData = [];
        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('data') && decodedData['data'] is List) {
            listData = decodedData['data'];
          }
        }

        return listData
            .map((item) => ReportDaily.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('Failed to load reports: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchTopSellingProducts() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/reports/top-selling"),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> listData = [];
        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic> &&
            decodedData['data'] is List) {
          listData = decodedData['data'];
        }

        return listData.map((item) {
          final product = item['product'] ?? {};

          final productImage = product['image'] ?? item['image'] ?? '';
          final productName =
              product['name'] ?? item['product_name'] ?? 'Unknown Product';

          final totalSold =
              item['total_quantity_sold'] ?? item['quantity'] ?? 0;
          final totalRevenue =
              item['total_revenue'] ?? item['total_price'] ?? 0.0;

          return {
            'name': productName,
            'category': product['category']?['name'] ?? 'General',
            'sold_qty': double.parse(totalSold.toString()).toInt(),
            'revenue': double.parse(totalRevenue.toString()),
            'image': productImage.isNotEmpty ? productImage : '📦',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching top selling: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchLowStockProducts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/reports/low-stock"));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> listData = [];
        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic> &&
            decodedData['data'] is List) {
          listData = decodedData['data'];
        }

        return listData.map((item) {
          final category = item['category'] ?? {};
          final stockLeft = item['stock_quantity'] != null
              ? double.parse(item['stock_quantity'].toString())
              : 0.0;
          final minAlert = item['alert_quantity'] != null
              ? double.parse(item['alert_quantity'].toString())
              : 0.0;

          // កំណត់ Status ស្វ័យប្រវត្តិ (Critical បើស្តុក <= 2 ឬ <= 0)
          String status = stockLeft <= 2 ? 'Critical' : 'Low Stock';

          return {
            'id': item['id'],
            'name': item['name'] ?? 'Unknown Product',
            'category': category['name'] ?? 'General',
            'stock_left': stockLeft.toInt(),
            'min_alert': minAlert.toInt(),
            'status': status,
            'image': item['image'] ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching low stock: $e');
      return [];
    }
  }

  Future<List<Customer>> fetchCustomers() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/customers"));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List listData = [];

        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map && decodedData['data'] is List) {
          listData = decodedData['data'];
        }

        return listData.map((item) => Customer.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCustomerHistory(
    dynamic customerId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (startDate != null && endDate != null) {
        queryParams['start_date'] = startDate;
        queryParams['end_date'] = endDate;
      }

      final uri = Uri.parse(
        "$baseUrl/reports/customers/$customerId/history",
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> listData = [];

        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic> &&
            decodedData['data'] is List) {
          listData = decodedData['data'];
        }

        return listData.map((item) {
          var rawDetails = item['details'] ?? item['items'] ?? [];
          List<Map<String, dynamic>> itemsList = [];

          for (var detail in rawDetails) {
            var product = detail['product'] ?? {};
            itemsList.add({
              'product_name':
                  product['name'] ??
                  detail['product_name'] ??
                  'Unknown Product',
              'quantity':
                  double.tryParse(detail['quantity']?.toString() ?? '0') ?? 0.0,
              'price':
                  double.tryParse(
                    (detail['price'] ??
                            detail['selling_price'] ??
                            detail['unit_price'] ??
                            '0')
                        .toString(),
                  ) ??
                  0.0,
              'image': product['image'] ?? detail['image'] ?? '',
            });
          }

          return {
            'id': item['id'],
            'order_number': item['order_number'] ?? 'INV-${item['id']}',
            'total':
                double.tryParse(
                  item['total']?.toString() ??
                      item['total_amount']?.toString() ??
                      '0',
                ) ??
                0.0,
            'status': item['status'] ?? 'completed',
            'payment_method': item['payment_method'] ?? 'cash',
            'date': item['created_at']?.toString().substring(0, 10) ?? '',
            'items': itemsList,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching customer history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCustomerReport() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/reports/customers"));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> listData = [];

        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic> &&
            decodedData['data'] is List) {
          listData = decodedData['data'];
        }

        return listData.map((item) {
          final name = item['name'] ?? 'Unknown';
          double totalSpent =
              double.tryParse(
                (item['orders_sum_total_amount'] ??
                        item['orders_sum_total'] ??
                        item['total_spent'] ??
                        '0')
                    .toString(),
              ) ??
              0.0;

          int points =
              int.tryParse(item['points']?.toString() ?? '') ??
              (totalSpent / 10).toInt();

          String avatar = 'CS';
          List<String> nameParts = name.trim().split(' ');
          if (nameParts.length >= 2) {
            avatar = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
          } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
            avatar = nameParts[0]
                .substring(0, nameParts[0].length >= 2 ? 2 : 1)
                .toUpperCase();
          }

          String tier = 'Member';
          if (totalSpent > 300) {
            tier = 'VIP Gold';
          } else if (totalSpent > 150) {
            tier = 'Silver';
          }

          return {
            'id': item['id'],
            'name': name,
            'phone': item['phone'] ?? 'No Phone',
            'points': points,
            'total_spent': totalSpent,
            'tier': tier,
            'avatar': avatar,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching customer report: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchWeeklyReport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (startDate != null && endDate != null) {
        queryParams['start_date'] = startDate;
        queryParams['end_date'] = endDate;
      }

      final uri = Uri.parse(
        "$baseUrl/reports/weekly",
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> listData = [];

        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic> &&
            decodedData['data'] is List) {
          listData = decodedData['data'];
        }

        return listData.map((item) {
          // ទាញយកព័ត៌មានអតិថិជន
          var customer = item['customer'] ?? {};
          // ទាញយកបញ្ជីទំនិញ (Details)
          var rawDetails = item['details'] ?? [];
          List<Map<String, dynamic>> itemsList = [];

          for (var detail in rawDetails) {
            var product = detail['product'] ?? {};
            itemsList.add({
              'product_name':
                  product['name'] ??
                  detail['product_name'] ??
                  'Unknown Product',
              'quantity':
                  double.tryParse(detail['quantity']?.toString() ?? '0') ?? 0.0,
              'price':
                  double.tryParse(
                    (detail['price'] ??
                            detail['selling_price'] ??
                            detail['unit_price'] ??
                            '0')
                        .toString(),
                  ) ??
                  0.0,
              'image': product['image'] ?? '',
            });
          }

          return {
            'id': item['id'],
            'order_number': item['order_number'] ?? 'INV-${item['id']}',
            'customer_name': customer['name'] ?? 'Walk-in Customer',
            'customer_phone': customer['phone'] ?? '',
            'total':
                double.tryParse(
                  (item['total'] ??
                          item['grand_total'] ??
                          item['total_amount'] ??
                          '0')
                      .toString(),
                ) ??
                0.0,
            'status': item['status'] ?? 'completed',
            'payment_method':
                item['payment']?['method'] ?? item['payment_method'] ?? 'cash',
            'date': item['created_at']?.toString().substring(0, 10) ?? '',
            'items': itemsList,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching weekly report: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPurchaseReport({
    String? startDate,
    String? endDate,
    dynamic supplierId,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (startDate != null && endDate != null) {
        queryParams['start_date'] = startDate;
        queryParams['end_date'] = endDate;
      }
      if (supplierId != null) {
        queryParams['supplier_id'] = supplierId.toString();
      }

      final uri = Uri.parse(
        "$baseUrl/reports/purchases",
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> listData = [];

        if (decodedData is List) {
          listData = decodedData;
        } else if (decodedData is Map<String, dynamic> &&
            decodedData['data'] is List) {
          listData = decodedData['data'];
        }

        return listData.map((item) {
          // ទាញយកข้อมูล Supplier
          var supplier = item['supplier'] ?? {};
          // ទាញយកបញ្ជី Purchase Items
          var rawItems = item['purchase_items'] ?? item['purchaseItems'] ?? [];
          List<Map<String, dynamic>> itemsList = [];

          for (var detail in rawItems) {
            var product = detail['product'] ?? {};
            itemsList.add({
              'product_name':
                  product['name'] ??
                  detail['product_name'] ??
                  'Unknown Product',
              'quantity':
                  double.tryParse(detail['quantity']?.toString() ?? '0') ?? 0.0,
              'cost_price':
                  double.tryParse(
                    (detail['cost_price'] ?? detail['price'] ?? '0').toString(),
                  ) ??
                  0.0,
              'image': product['image'] ?? '',
            });
          }

          return {
            'id': item['id'],
            'reference_no':
                item['reference_no'] ??
                item['invoice_no'] ??
                'PO-${item['id']}',
            'supplier_name': supplier['name'] ?? 'General Supplier',
            'supplier_phone': supplier['phone'] ?? '',
            'total':
                double.tryParse(
                  (item['total'] ??
                          item['grand_total'] ??
                          item['total_amount'] ??
                          '0')
                      .toString(),
                ) ??
                0.0,
            'status': item['status'] ?? 'received',
            'date': item['created_at']?.toString().substring(0, 10) ?? '',
            'items': itemsList,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching purchase report: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchPurchaseDetail(dynamic purchaseId) async {
    try {
      final uri = Uri.parse("$baseUrl/reports/purchases/$purchaseId");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        final item = decodedData is Map<String, dynamic>
            ? (decodedData['data'] ?? decodedData)
            : {};

        var supplier = item['supplier'] ?? {};

        var rawItems = item['purchase_items'] ?? item['purchaseItems'] ?? [];
        List<Map<String, dynamic>> itemsList = [];
        for (var detail in rawItems) {
          var product = detail['product'] ?? {};
          itemsList.add({
            'product_name':
                product['name'] ?? detail['product_name'] ?? 'Unknown Product',
            'quantity':
                double.tryParse(detail['quantity']?.toString() ?? '0') ?? 0.0,
            'cost_price':
                double.tryParse(
                  (detail['unit_cost'] ??
                          detail['cost_price'] ??
                          detail['price'] ??
                          '0')
                      .toString(),
                ) ??
                0.0,
            'image': product['image'] ?? detail['image'] ?? '',
          });
        }

        return {
          'id': item['id'],
          'reference_no':
              item['reference_no'] ?? item['invoice_no'] ?? 'PO-${item['id']}',
          'supplier_name':
              supplier['name'] ?? item['supplier_name'] ?? 'General Supplier',
          'supplier_phone': supplier['phone'] ?? '',
          'total':
              double.tryParse(
                (item['total'] ??
                        item['grand_total'] ??
                        item['total_amount'] ??
                        '0')
                    .toString(),
              ) ??
              0.0,
          'status': item['status'] ?? 'Received',
          'date': item['created_at']?.toString().substring(0, 10) ?? '',
          'items': itemsList,
        };
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching purchase detail: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchTotalSalesReport() async {
    try {
      final uri = Uri.parse("$baseUrl/reports/total-sales");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        final data = decodedData is Map<String, dynamic>
            ? (decodedData['data'] ?? decodedData)
            : {};

        return {
          'total_sales':
              double.tryParse(data['total_sales']?.toString() ?? '0') ?? 0.0,
          'total_orders':
              int.tryParse(data['total_orders']?.toString() ?? '0') ?? 0,
          'total_customers':
              int.tryParse(data['total_customers']?.toString() ?? '0') ?? 0,
        };
      }
      return {'total_sales': 0.0, 'total_orders': 0, 'total_customers': 0};
    } catch (e) {
      debugPrint('Error fetching total sales report: $e');
      return {'total_sales': 0.0, 'total_orders': 0, 'total_customers': 0};
    }
  }

  Future<Map<String, dynamic>> fetchFinancialReport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = '$baseUrl/reports/financial';
      if (startDate != null && endDate != null) {
        url += '?start_date=$startDate&end_date=$endDate';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData['success'] == true) {
          return decodedData['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching financial report: $e");
    }
    return {
      'total_income': 0.0,
      'total_expense': 0.0,
      'general_expenses': 0.0,
      'purchase_expenses': 0.0,
      'net_profit': 0.0,
      'expense_breakdown': [],
      'income_breakdown': [],
      'expense_by_category': [],
    };
  }
}

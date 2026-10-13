import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';
import 'Local_db_service.dart';

class ProductSyncService {
  static final ProductSyncService instance = ProductSyncService._init();
  StreamSubscription<ConnectivityResult>? _subscription;
  final String baseUrl = BaseUrlApi.baseurl;

  ProductSyncService._init();

  void initializeSyncListener() {
    _subscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      bool hasConnection = (result != ConnectivityResult.none);

      if (hasConnection) {
        debugPrint(
          "🌐 Internet connected! Syncing offline products to MySQL...",
        );
        syncPendingProductsToMySQL();
      } else {
        debugPrint("📶 Offline Mode: No internet connection.");
      }
    });
  }

  Future<void> syncPendingProductsToMySQL() async {
    final localDb = LocalDbService.instance;
    List<Map<String, dynamic>> pendingProducts = await localDb
        .getUnsyncedProducts();

    if (pendingProducts.isEmpty) return;

    for (var item in pendingProducts) {
      int localId = item['local_id'];
      String payloadJson = item['payload_json'];

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/products'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: payloadJson,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await localDb.markProductAsSynced(localId);
          debugPrint(
            "✅ Successfully synced offline product ID: $localId to MySQL",
          );
        } else {
          debugPrint(
            "❌ Failed to sync product ID: $localId. Response: ${response.body}",
          );
        }
      } catch (e) {
        debugPrint("⚠️ Network error during product sync: $e");
        break;
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

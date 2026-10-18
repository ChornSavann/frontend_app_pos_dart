import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> showLowStockAlert({
    required int id,
    required String productName,
    required int currentStock,
  }) async {
    AndroidNotificationDetails
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'low_stock_channel',
      'Low Stock Alerts',
      channelDescription: 'Notification for products running low in stock',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFFEF4444),
      ledColor: const Color(0xFFEF4444),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: BigTextStyleInformation(
        'ផលិតផល "$productName" បច្ចុប្បន្ននៅសល់តែ ${currentStock} ឯកតាទេ។ សូមធ្វើការផ្ដល់ស្តុកបន្ថែមជាបន្ទាន់!',
        contentTitle: '⚠️ ជូនដំណឹងទំនិញជិតអស់ស្តុក!',
        summaryText: 'Low Stock Warning',
      ),
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      '⚠️ ជូនដំណឹងទំនិញជិតអស់ស្តុក!',
      'ផលិតផល $productName នៅសល់តែ ${currentStock} ឯកតាទេ។',
      platformChannelSpecifics,
    );
  }
}

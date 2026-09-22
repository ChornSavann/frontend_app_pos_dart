import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'low_stock_channel',
          'Low Stock Alerts',
          channelDescription: 'Notification for products running low in stock',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      '⚠️ ជូនដំណឹងទំនិញជិតអស់ស្តុក!',
      'ផលិតផល $productName នៅសល់តែ ${currentStock} ឯកតាទេ។ សូមធ្វើការបញ្ជាទិញបន្ថែម!',
      platformChannelSpecifics,
    );
  }
}

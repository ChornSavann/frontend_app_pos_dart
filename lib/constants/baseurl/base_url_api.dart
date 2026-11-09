import 'package:firebase_remote_config/firebase_remote_config.dart';

class BaseUrlApi {
  static String _host = "http://192.168.0.131:8000";
  static String get baseurl => "$_host/api";
  static String get baseimageUrl => _host;

  static Future<void> init() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );

      await remoteConfig.fetchAndActivate();

      final fetchedHost = remoteConfig.getString('server_host').trim();
      if (fetchedHost.isNotEmpty) {
        _host = fetchedHost.endsWith('/')
            ? fetchedHost.substring(0, fetchedHost.length - 1)
            : fetchedHost;
      }

      print("🌐 Current Base URL: $_host/api");
      print("🖼️ Current Base Image URL: $_host");
    } catch (e) {
      print("⚠️ ប្រើប្រាស់ Default IP ($_host) ដោយសារ៖ $e");
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/expenses/index_expense_screen.dart';
import 'package:pos_inventory/expensetype/index_expensetype_sreen.dart';
import 'package:pos_inventory/homesccreeen/dashboard_screen.dart';
import 'package:pos_inventory/login/plash_screnn.dart';
import 'package:pos_inventory/report/profit_lose/finance_chart_screen.dart';
import 'package:pos_inventory/report/profit_lose/finance_report_screen.dart';
import 'package:pos_inventory/stores/index_store_screen.dart';
import 'package:pos_inventory/translations/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  // ៣. បង្កើតលក្ខខណ្ឌ៖ បើមាន Token ឱ្យទៅ Home បើគ្មានទេឱ្យទៅ Login
  Widget initialScreen = (token != null && token.isNotEmpty)
      ? const DashboardScreen()
      : const SplashScreen();

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Laravel Flutter Auth',
      translations: Messages(),
      locale: Locale(
        TranslateConstants.km,
        TranslateConstants.kh,
      ), // translations will be displayed in that locale
      fallbackLocale: Locale(TranslateConstants.en, TranslateConstants.us),
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // textTheme: GoogleFonts.kantumruyProTextTheme(
        //   Theme.of(context).textTheme,
        // ),
      ),
      home: initialScreen,
      // home: FinancialReportScreen()
    );
  }
}

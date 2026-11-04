import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_inventory/api/api_product.dart';
import 'package:pos_inventory/homesccreeen/screen_home.dart';
import 'package:pos_inventory/login/login_screen.dart';
import 'package:pos_inventory/order/cart_screen.dart';
import '../Productscreen/favorite/favorite_screen.dart';
import '../Productscreen/notication/low_stock_screen.dart';
import '../Productscreen/notication/notication_service.dart';
import '../api/authority/api_authority.dart';
import '../partail/app_bar_screen.dart';
import '../partail/button_screen.dart';
import '../stores/models/store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Store? _currentStore;
  List<dynamic> _lowStockList = [];
  bool _isLoadingLowStock = false;
  final ApiProduct _apiProduct = ApiProduct();

  Timer? _authCheckTimer;

  @override
  void initState() {
    super.initState();
    _fetchLowStockData();

    _authCheckTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _verifyTokenWithServer();
    });
  }

  @override
  void dispose() {
    _authCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyTokenWithServer() async {

    int statusCode = await AuthorityApiService.verifyTokenStatus();
    if (statusCode == 401) {
      _authCheckTimer?.cancel();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _fetchLowStockData() async {
    setState(() => _isLoadingLowStock = true);
    try {
      List<dynamic> data = await _apiProduct.getLowStockProducts();

      if (mounted) {
        setState(() {
          _lowStockList = data;
          _isLoadingLowStock = false;
        });
        for (int i = 0; i < _lowStockList.length; i++) {
          var product = _lowStockList[i];
          print("📦 Product Data: $product");
          String name = product['name'] ?? 'Unknown';
          double rawStock =
              double.tryParse(product['stock_quantity'].toString()) ?? 0.0;
          int stock = rawStock.toInt();

          await NotificationService.showLowStockAlert(
            id: i,
            productName: name,
            currentStock: stock,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLowStock = false);
      }
      debugPrint("Error fetching low stock: $e");
    }
  }

  Future<void> _handleNotificationTap() async {
    final needRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LowStockScreen(lowStockProducts: _lowStockList),
      ),
    );

    if (needRefresh == true) {
      debugPrint("🔄 កំពុងទាញយកទិន្នន័យ Low Stock ថ្មី...");
      _fetchLowStockData();
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  void _navigateToFavoriteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoriteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildPOSFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBarScreen(
      store: _currentStore,
      lowStockCount: _lowStockList.length,
      onNotificationTap: _handleNotificationTap,
      onFavoriteTap: _navigateToFavoriteScreen,
    );
  }


  Widget _buildBody() {
    return const ScreenHome();
  }


  Widget _buildPOSFloatingActionButton() {
    return Transform.translate(
      offset: const Offset(0, 15),
      child: FloatingActionButton(
        onPressed: _navigateToCart,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.point_of_sale_rounded, size: 26),
      ),
    );
  }


  Widget _buildBottomNavigationBar() {
    return const ButtonScreen(currentIndex: 0);
  }
}
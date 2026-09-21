
import 'package:flutter/material.dart';
import 'package:pos_inventory/homesccreeen/screen_home.dart';
import 'package:pos_inventory/order/cart_screen.dart';
import '../partail/app_bar_screen.dart';
import '../partail/button_screen.dart';
import '../stores/models/store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Store? currentStore;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBarScreen(
        store: currentStore,
      ),

      body: ScreenHome(),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 15),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 2.0,
          shape: const CircleBorder(),
          child: const Icon(Icons.point_of_sale_rounded, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const ButtonScreen(currentIndex: 0),
    );
  }
}
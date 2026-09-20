import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/order/cart_screen.dart';
import 'package:pos_inventory/profile/edit_profile_screen.dart';
import 'package:pos_inventory/settings/about_screen.dart';
import 'package:pos_inventory/settings/currency_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/data_sync_screen.dart';
import '../settings/printer_screen.dart';
import 'app_bar_screen.dart';
import 'button_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isDarkMode = false;
  bool _autoPrintReceipt = true;
  bool _soundEnabled = true;

  String _userName = "Loading...";
  String _userRole = "Cashier • Register #01";
  String _userAvatar =
      "https://i.pinimg.com/736x/a4/dc/0b/a4dc0b965816c932da67f6e32af547cc.jpg";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? "Chorn Savann099";
      _userRole = prefs.getString('role') ?? "Cashier • Register #01";
      _userAvatar = prefs.getString('image') ?? "assets/Savann.jpg";
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF8F9FA);
    final cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF1E293B);
    final subtitleColor = _isDarkMode ? Colors.grey[400] : Colors.grey[500];

    final tileBgColor = _isDarkMode
        ? Colors.blueAccent.withValues(alpha: 0.25)
        : Colors.blueAccent.withValues(alpha: 0.1);

    final dividerColor = _isDarkMode ? Colors.grey[850]! : Colors.grey[200]!;
    final arrowBgColor = _isDarkMode
        ? const Color(0xFF2C2C2C)
        : Colors.grey[100]!;
    final arrowIconColor = _isDarkMode ? Colors.grey[400]! : Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          TranslateConstants.settings.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👤 Profile Card (រក្សាពណ៌ Gradient ព្រោះស្អាតស្រាប់)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Color(0xFF448AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(_userAvatar),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userRole,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );

                        if (result == true) {
                          _loadUserData();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ⚙️ ផ្នែកទី ១៖ HARDWARE & POS
              const Text(
                "HARDWARE & POS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color:
                      cardColor, // 👈 ប្រើប្រាស់ cardColor ដែលដូរតាម Dark Mode
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isDarkMode ? 0.3 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.print_rounded,
                      title: "Auto Print Receipt",
                      subtitle: "Print receipt automatically after payment",
                      value: _autoPrintReceipt,
                      textColor: textColor,
                      tileBgColor: tileBgColor,
                      subtitleColor: subtitleColor,
                      onChanged: (val) {
                        setState(() {
                          _autoPrintReceipt = val;
                        });
                      },
                    ),
                    Divider(height: 1, indent: 68, color: dividerColor),
                    _buildMenuTile(
                      icon: Icons.bluetooth_searching_rounded,
                      title: "Bluetooth Receipt Printer",
                      subtitle: "Connected (POS-80 Printer)",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: tileBgColor,
                      arrowBgColor: arrowBgColor,
                      arrowIconColor: arrowIconColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrinterScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 68, color: dividerColor),
                    _buildMenuTile(
                      icon: Icons.point_of_sale_rounded,
                      title: "Cash Drawer Setup",
                      subtitle: "Configure cash drawer trigger",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: tileBgColor,
                      arrowBgColor: arrowBgColor,
                      arrowIconColor: arrowIconColor,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🎨 ផ្នែកទី ២៖ PREFERENCES
              const Text(
                "PREFERENCES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardColor, // 👈 ប្រែពណ៌តាម Dark Mode
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isDarkMode ? 0.3 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: "Dark Mode",
                      subtitle: "Switch to dark theme appearance",
                      value: _isDarkMode,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: tileBgColor,
                      onChanged: (val) {
                        setState(() {
                          _isDarkMode = val;
                        });
                      },
                    ),
                    Divider(height: 1, indent: 68, color: dividerColor),
                    _buildMenuTile(
                      icon: Icons.language_rounded,
                      title: "Language / ភាសា",
                      subtitle: "Khmer / English",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: tileBgColor,
                      arrowBgColor: arrowBgColor,
                      arrowIconColor: arrowIconColor,
                      onTap: () {},
                    ),
                    Divider(height: 1, indent: 68, color: dividerColor),
                    _buildSwitchTile(
                      icon: Icons.volume_up_rounded,
                      title: "Sound Effects",
                      subtitle: "Play sound on button click & scan",
                      value: _soundEnabled,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: tileBgColor,
                      onChanged: (val) {
                        setState(() {
                          _soundEnabled = val;
                        });
                      },
                    ),
                    Divider(height: 1, indent: 68, color: dividerColor),
                    _buildMenuTile(
                      icon: Icons.currency_exchange_rounded,
                      title: "Currency / រូបិយប័ណ្ណ",
                      subtitle: "USD (\$ / ៛ Riel)",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: tileBgColor,
                      arrowBgColor: arrowBgColor,
                      arrowIconColor: arrowIconColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CurrencyScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 💻 ផ្នែកទី ៣៖ SYSTEM
              const Text(
                "SYSTEM",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardColor, // 👈 ប្រែពណ៌តាម Dark Mode
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isDarkMode ? 0.3 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.cloud_sync_rounded,
                      title: "Sync Data with Server",
                      subtitle: "Last synced: Just now",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: tileBgColor,
                      arrowBgColor: arrowBgColor,
                      arrowIconColor: arrowIconColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DataSyncScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 68, color: dividerColor),
                    _buildMenuTile(
                      icon: Icons.info_outline_rounded,
                      title: "About Khmer APP",
                      subtitle: "Version 1.0.0 (Build 2026)",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: tileBgColor,
                      arrowBgColor: arrowBgColor,
                      arrowIconColor: arrowIconColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ButtonScreen(currentIndex: 3),
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
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color? subtitleColor,
    required Color tileBgColor,
    required Color arrowBgColor,
    required Color arrowIconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: tileBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.blueAccent, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subtitleColor),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: arrowBgColor, shape: BoxShape.circle),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 12,
          color: arrowIconColor,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color? subtitleColor,
    required Color tileBgColor,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: tileBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.blueAccent, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subtitleColor),
      ),
      value: value,
      activeThumbColor: Colors.blueAccent,
      onChanged: onChanged,
    );
  }
}

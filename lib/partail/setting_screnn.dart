import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/api/api_auth.dart';
import 'package:pos_inventory/constants/baseurl/base_image_url.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/order/cart_screen.dart';
import 'package:pos_inventory/partail/profile_screen.dart';
import 'package:pos_inventory/profile/edit_profile_screen.dart';
import 'package:pos_inventory/report/history/order_history_screen.dart';
import 'package:pos_inventory/settings/about_screen.dart';
import 'package:pos_inventory/settings/cash_drawer_setup_screen.dart';
import 'package:pos_inventory/settings/currency_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings/data_sync_screen.dart';
import '../settings/printer_screen.dart';
import 'button_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final ApiAuth _apiAuth = ApiAuth();
  final baseImageUrl = BaseImageUrl.BaseimageUrl;
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
    try {
      final profileData = await _apiAuth.getProfile();

      if (profileData != null) {
        final String name = profileData['name'] ?? "Chorn Savann";
        debugPrint("🔍 Profile Data Received: $profileData");

        String role = "Cashier";
        if (profileData['role'] is Map) {
          role =
              profileData['role']['name'] ??
              profileData['role']['title'] ??
              "Cashier";
        } else if (profileData['role'] is String) {
          role = profileData['role'];
        } else if (profileData['role_name'] != null) {
          role = profileData['role_name'].toString();
        }

        debugPrint("✅ Extracted Role: $role");
        final String? image = profileData['image_url'] ?? profileData['image'];
        debugPrint("📸 Raw Image from API: $image");

        final String avatarUrl = (image != null && image.isNotEmpty)
            ? image
            : "";

        debugPrint("🔗 Final Avatar URL: $avatarUrl");

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', name);
        await prefs.setString('role', role);
        await prefs.setString('image', avatarUrl);

        setState(() {
          _userName = name;
          _userRole = "$role ";
          _userAvatar = avatarUrl.isNotEmpty ? avatarUrl : "assets/gamming.jpg";
        });
      } else {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _userName = prefs.getString('name') ?? "Chorn Savann";
          String savedRole = prefs.getString('role') ?? "Cashier";
          _userRole = "$savedRole ";
          _userAvatar = prefs.getString('image') ?? "assets/gamming.jpg";
        });
      }
    } catch (e) {
      debugPrint("Error loading profile from API: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF8F9FA);
    final cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
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
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );

                  if (result == true && mounted) {
                    _loadUserData();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF1D4ED8),
                        Color(0xFF3B82F6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 🌟 Background Decorative Circle (เพิ่มมิติความสวยงามแบบ Abstract)
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 110,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      Row(
                        children: [
                          // 🖼️ Profile Avatar with Elegant Border & Glow
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              backgroundImage: _userAvatar.startsWith('http')
                                  ? NetworkImage(_userAvatar)
                                  : AssetImage(_userAvatar) as ImageProvider,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // 📝 User Info Section
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
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),

                                // 🛡️ Role Badge with small icon
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 150,
                                        ),
                                        child: Text(
                                          _userRole,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // ✏️ Modern Rounded Edit Button
                          Material(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileScreen(),
                                  ),
                                );

                                if (result == true) {
                                  _loadUserData();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CashDrawerSetupScreen(),
                          ),
                        );
                      },
                    ),

                    Divider(height: 1, indent: 68, color: dividerColor),
                    _buildMenuTile(
                      icon: Icons.history_rounded,
                      title: "History Order",
                      subtitle: "History Order product trigger",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: tileBgColor,
                      arrowBgColor: arrowBgColor,
                      arrowIconColor: arrowIconColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderHistoryScreen(),
                          ),
                        );
                      },
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

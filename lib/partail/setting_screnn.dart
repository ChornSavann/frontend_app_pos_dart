import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../homesccreeen/darkmode/them_controller.dart';
import '../settings/data_sync_screen.dart';
import '../settings/printer_screen.dart';
import 'button_screen.dart';

/// 🎨 Colour palette for light / dark appearance
class _Pal {
  final bool dark;
  const _Pal(this.dark);

  Color get bg => dark ? const Color(0xFF0B1120) : const Color(0xFFF4F6FB);
  Color get card => dark ? const Color(0xFF151C2E) : Colors.white;
  Color get text => dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get subtext =>
      dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get label => dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  Color get divider =>
      dark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEEF1F6);
  Color get border =>
      dark ? Colors.white.withValues(alpha: 0.07) : Colors.transparent;
  Color get chevronBg =>
      dark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9);
  Color get chevron => const Color(0xFF94A3B8);
  Color get shadow => Colors.black.withValues(alpha: dark ? 0.35 : 0.05);
  List<Color> get headerGradient => dark
      ? const [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)]
      : const [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF3B82F6)];
}

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final ApiAuth _apiAuth = ApiAuth();
  final baseImageUrl = BaseImageUrl.BaseimageUrl;

  // 👇 CHANGED: dark mode now comes from the app theme (global), not local state
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  bool _autoPrintReceipt = true;
  bool _soundEnabled = true;

  String _userName = "Loading...";
  String _userRole = "Cashier • Register #01";
  String _userAvatar =
      "https://i.pinimg.com/736x/a4/dc/0b/a4dc0b965816c932da67f6e32af547cc.jpg";

  _Pal get _p => _Pal(_isDarkMode);

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
    final p = _p;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          backgroundColor: p.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            TranslateConstants.settings.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: p.text,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(p),
              const SizedBox(height: 28),

              // ⚙️ ផ្នែកទី ១៖ HARDWARE & POS
              _buildSectionLabel("HARDWARE & POS", p),
              _buildCard(p, [
                _buildSwitchTile(
                  icon: Icons.print_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: "Auto Print Receipt",
                  subtitle: "Print receipt automatically after payment",
                  value: _autoPrintReceipt,
                  onChanged: (val) {
                    setState(() {
                      _autoPrintReceipt = val;
                    });
                  },
                ),
                _buildDivider(p),
                _buildMenuTile(
                  icon: Icons.bluetooth_searching_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: "Bluetooth Receipt Printer",
                  subtitle: "Connected (POS-80 Printer)",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrinterScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(p),
                _buildMenuTile(
                  icon: Icons.point_of_sale_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: "Cash Drawer Setup",
                  subtitle: "Configure cash drawer trigger",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CashDrawerSetupScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(p),
                _buildMenuTile(
                  icon: Icons.history_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: "History Order",
                  subtitle: "History Order product trigger",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 28),

              // 🎨 ផ្នែកទី ២៖ PREFERENCES
              _buildSectionLabel("PREFERENCES", p),
              _buildCard(p, [
                _buildSwitchTile(
                  icon: _isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: "Dark Mode",
                  subtitle: "Switch to dark theme appearance",
                  value: _isDarkMode,
                  // 👇 CHANGED: toggles the global theme + saves it
                  onChanged: (val) {
                    Get.find<ThemeController>().setDark(val);
                  },
                ),
                _buildDivider(p),
                _buildMenuTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  title: "Language / ភាសា",
                  subtitle: "Khmer / English",
                  onTap: () {},
                ),
                _buildDivider(p),
                _buildSwitchTile(
                  icon: Icons.volume_up_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: "Sound Effects",
                  subtitle: "Play sound on button click & scan",
                  value: _soundEnabled,
                  onChanged: (val) {
                    setState(() {
                      _soundEnabled = val;
                    });
                  },
                ),
                _buildDivider(p),
                _buildMenuTile(
                  icon: Icons.currency_exchange_rounded,
                  iconColor: const Color(0xFF14B8A6),
                  title: "Currency / រូបិយប័ណ្ណ",
                  subtitle: "USD (\$ / ៛ Riel)",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CurrencyScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 28),

              // 💻 ផ្នែកទី ៣៖ SYSTEM
              _buildSectionLabel("SYSTEM", p),
              _buildCard(p, [
                _buildMenuTile(
                  icon: Icons.cloud_sync_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: "Sync Data with Server",
                  subtitle: "Last synced: Just now",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DataSyncScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(p),
                _buildMenuTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF64748B),
                  title: "About Khmer APP",
                  subtitle: "Version 1.0.0 (Build 2026)",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutScreen()),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
        // 👇 CHANGED: ButtonScreen now follows the app theme by itself
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
            elevation: _isDarkMode ? 0 : 2.0,
            shape: const CircleBorder(),
            child: const Icon(Icons.point_of_sale_rounded, size: 26),
          ),
        ),
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // ───────────────────────── Profile header ─────────────────────────

  Widget _buildProfileCard(_Pal p) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );

        if (result == true && mounted) {
          _loadUserData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: p.headerGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: _isDarkMode ? 0.08 : 0.0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF2563EB,
              ).withValues(alpha: _isDarkMode ? 0.25 : 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 🌟 Decorative background shapes
              Positioned(
                right: -26,
                bottom: -30,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                left: -40,
                top: -50,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Row(
                children: [
                  // 🖼️ Avatar with ring + online dot
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 2,
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
                          radius: 30,
                          backgroundColor: Colors.white,
                          backgroundImage: _userAvatar.startsWith('http')
                              ? NetworkImage(_userAvatar)
                              : AssetImage(_userAvatar) as ImageProvider,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1D4ED8),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // 📝 User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
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

                  // ✏️ Edit button
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
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
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
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
    );
  }

  // ───────────────────────── Building blocks ─────────────────────────

  Widget _buildSectionLabel(String text, _Pal p) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: p.label,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_Pal p, List<Widget> children) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildDivider(_Pal p) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 76,
      endIndent: 16,
      color: p.divider,
    );
  }

  Widget _buildIconBadge(IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDarkMode ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final p = _p;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _buildIconBadge(icon, iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: p.subtext),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: p.chevronBg, shape: BoxShape.circle),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 11,
          color: p.chevron,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final p = _p;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: _buildIconBadge(icon, iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: p.subtext),
        ),
      ),
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: Colors.blueAccent,
      inactiveThumbColor: _isDarkMode
          ? const Color(0xFF94A3B8)
          : Colors.white,
      inactiveTrackColor: _isDarkMode
          ? const Color(0xFF2A3350)
          : const Color(0xFFCBD5E1),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      onChanged: onChanged,
    );
  }
}
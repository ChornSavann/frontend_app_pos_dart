import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/api/stores/api_store.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/order/cart_screen.dart';
import 'package:pos_inventory/settings/about_screen.dart';
import 'package:pos_inventory/stores/models/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../translations/language/language_switcher_button.dart';
import '../order/card_manager.dart';
import '../models/Product.dart';
import '../../Productscreen/favorite/controller/favoritecontroller.dart'; // 👈 ផ្ទៀងផ្ទាត់ Path របស់ Controller ឱ្យបានត្រឹមត្រូវ

class AppBarScreen extends StatefulWidget implements PreferredSizeWidget {
  final int cartItemCount;
  final int lowStockCount;
  final Store? store;
  final VoidCallback? onNotificationTap;
  final List<Product>? favoriteProducts;
  final VoidCallback? onFavoriteTap;

  const AppBarScreen({
    super.key,
    this.cartItemCount = 0,
    this.lowStockCount = 0,
    this.store,
    this.onNotificationTap,
    this.favoriteProducts,
    this.onFavoriteTap,
  });

  @override
  State<AppBarScreen> createState() => _AppBarScreenState();

  @override
  Size get preferredSize => const Size.fromHeight(75);
}

class _AppBarScreenState extends State<AppBarScreen> {
  final ApiStore _apiStore = ApiStore();
  Store? _fetchedStore;
  bool _isLoadingStore = false;
  String _userName = "";

  // 🌙 NEW: follow the app theme (light / dark)
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? "";
    });
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoadingStore = true);
    try {
      List<Store> stores = await _apiStore.fetchStoreInfo();
      if (mounted) {
        setState(() {
          _fetchedStore = stores.isNotEmpty ? stores.first : null;
          _isLoadingStore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStore = false);
      }
      debugPrint("❌ ERROR fetching store in AppBar: $e");
    }
  }

  @override
  Widget build(context) {
    final bool isDark = _isDark;
    final Store store =
        widget.store ??
            _fetchedStore ??
            Store(id: null, name: '', imageUrl: '');

    return AppBar(
      toolbarHeight: 75,
      // 🌙 CHANGED: was Colors.white
      backgroundColor: isDark ? const Color(0xFF151C2E) : Colors.white,
      surfaceTintColor: Colors.transparent, // 🌙 NEW
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                // 🌙 CHANGED: was Colors.blue.shade50
                color: isDark
                    ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                // 🌙 CHANGED: was Colors.blue.shade100
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2563EB).withValues(alpha: 0.35)
                      : Colors.blue.shade100,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Builder(
                  builder: (context) {
                    if (_isLoadingStore) {
                      return const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      );
                    }

                    return (store.imageUrl != null &&
                        store.imageUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                      imageUrl: store.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        );
                      },
                    )
                        : const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 📝 Store Name & User Info Section
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    store.name.isNotEmpty
                        ? store.name
                        : TranslateConstants.khmerApp.tr,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      // 🌙 CHANGED: was Color(0xFF1E293B)
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _userName.isNotEmpty ? _userName : "Active Cashier",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            // 🌙 CHANGED: was Colors.grey.shade600
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // 🌐 Language Switcher
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.0),
            child: LanguageSwitcherButton(),
          ),
        ),
        const SizedBox(width: 2),


        Obx(() {
          final FavoriteController favController = Get.find<FavoriteController>();
          final favoriteList = favController.favoriteList;

          if (favoriteList.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildActionCircle(
                  Icons.favorite_rounded,
                  widget.onFavoriteTap ?? () {},
                  iconColor: Colors.redAccent,
                ),
                Positioned(
                  right: 2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '${favoriteList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // 🔔 Notification Action Button
        Stack(
          alignment: Alignment.center,
          children: [
            _buildActionCircle(Icons.notifications_none_rounded, () {
              if (widget.onNotificationTap != null) {
                widget.onNotificationTap!();
              }
            }),
            if (widget.lowStockCount > 0)
              Positioned(
                right: 2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.lowStockCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),

        // 🛒 Cart Action Button
        ValueListenableBuilder<int>(
          valueListenable: CartManager.cartItemCount,
          builder: (context, itemCount, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _buildActionCircle(Icons.shopping_cart_outlined, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                }),
                if (itemCount > 0)
                  Positioned(
                    right: 1,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // 🌙 CHANGED: iconColor is now optional so the default can follow dark mode
  Widget _buildActionCircle(IconData icon, VoidCallback onTap, {Color? iconColor}) {
    final bool isDark = _isDark;
    final Color resolvedIconColor =
        iconColor ?? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569));

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: resolvedIconColor, size: 20),
        onPressed: onTap,
      ),
    );
  }
}
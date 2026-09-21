import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/api/stores/api_store.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/order/cart_screen.dart';
import 'package:pos_inventory/stores/models/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../order/card_manager.dart';

class AppBarScreen extends StatefulWidget implements PreferredSizeWidget {
  final int cartItemCount;
  final Store? store;

  const AppBarScreen({super.key, this.cartItemCount = 0, this.store});

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
    final Store store =
        widget.store ??
        _fetchedStore ??
        Store(id: null, name: '', imageUrl: '');

    return AppBar(
      toolbarHeight: 75,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black12,
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade100, width: 1.2),
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

                  return (store.imageUrl != null && store.imageUrl!.isNotEmpty)
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
          const SizedBox(width: 12),

          // 📝 Store Name & User Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  store.name.isNotEmpty
                      ? store.name
                      : TranslateConstants.khmerApp.tr,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
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
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // 🌐 Language Switcher
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: LanguageSwitcherButton(),
          ),
        ),
        const SizedBox(width: 2),

        // 🔍 Search Action Button
        _buildActionCircle(Icons.search_rounded, () {}),
        const SizedBox(width: 8),

        // 🔔 Notification / Cart Action Button with Badge
        ValueListenableBuilder<int>(
          valueListenable: CartManager.cartItemCount,
          builder: (context, itemCount, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _buildActionCircle(Icons.notifications_none_rounded, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                }),
                if (itemCount > 0)
                  Positioned(
                    right: 4,
                    top: 6,
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

  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 1),
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
        icon: Icon(icon, color: const Color(0xFF475569), size: 20),
        onPressed: onTap,
      ),
    );
  }
}

// 🇰🇭🇬🇧 Language Switcher Button with GetX
class LanguageSwitcherButton extends StatefulWidget {
  const LanguageSwitcherButton({super.key});

  @override
  State<LanguageSwitcherButton> createState() => _LanguageSwitcherButtonState();
}

class _LanguageSwitcherButtonState extends State<LanguageSwitcherButton> {
  bool isKhmer = true;

  void onChangeLanguage() {
    setState(() {
      isKhmer = !isKhmer;
    });

    if (Get.locale?.languageCode == TranslateConstants.km) {
      var locale = const Locale(TranslateConstants.en, TranslateConstants.us);
      Get.updateLocale(locale);
    } else {
      var locale = const Locale(TranslateConstants.km, TranslateConstants.kh);
      Get.updateLocale(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: InkWell(
        onTap: onChangeLanguage,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isKhmer ? "🇰🇭" : "🇬🇧",
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(width: 6),
              Text(
                isKhmer ? "KH" : "EN",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

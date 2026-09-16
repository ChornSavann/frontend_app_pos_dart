import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/order/cart_screen.dart';

import '../order/card_manager.dart';

class AppBarScreen extends StatefulWidget implements PreferredSizeWidget {
  final int cartItemCount; // ទទួលតម្លៃចំនួនទំនិញពីខាងក្រៅមកបង្ហាញ

  const AppBarScreen({super.key, this.cartItemCount = 0});

  @override
  State<AppBarScreen> createState() => _AppBarScreenState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}



class _AppBarScreenState extends State<AppBarScreen> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,

      title: Flexible(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                'https://i.pinimg.com/736x/8c/f9/f0/8cf9f0712d6db75ea3ce0b8e526d82f4.jpg',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),

            // Text Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TranslateConstants.khmerApp.tr,
                    // "Khmer APP".tr,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Reg #01 • Chorn Savann",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
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
      ),

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: Colors.grey[200], thickness: 1),
      ),

      actions: [
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.0),
            child: LanguageSwitcherButton(),
          ),
        ),
        const SizedBox(width: 4),

        // 2️⃣ Search Button
        _buildActionCircle(Icons.search_rounded, () {
          // Search action
        }),
        const SizedBox(width: 4),

        // 3️⃣ Notification / Cart Button with Dynamic Badge Count
        ValueListenableBuilder<int>(
          valueListenable: CartManager
              .cartItemCount, // 🟢 ភ្ជាប់ជាមួយ CartManager ដើម្បីស្តាប់ការផ្លាស់ប្តូរចំនួន
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

                // 🟢 ប្រើប្រាស់ itemCount ដែលបានមកពី ValueListenableBuilder ជំនួសឱ្យ widget.cartItemCount
                if (itemCount > 0)
                  Positioned(
                    right: -1,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
        const SizedBox(width: 4),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: Colors.blueAccent, size: 18),
          onPressed: onTap,
        ),
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
  // មុខងារសម្រាប់ប្តូរភាសាជាមួយ GetX
  void onChangeLanguage() {
    print(Get.locale?.languageCode??"");
    setState(() {
      isKhmer = !isKhmer;
    });

    if (Get.locale?.languageCode == TranslateConstants.km) {
      var locale = Locale(TranslateConstants.en, TranslateConstants.us);
      Get.updateLocale(locale);
    } else {
      var locale = Locale(TranslateConstants.km, TranslateConstants.kh);
      Get.updateLocale(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: InkWell(
        onTap: onChangeLanguage,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isKhmer ? "🇰🇭" : "🇬🇧",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                isKhmer ? "KH" : "EN",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

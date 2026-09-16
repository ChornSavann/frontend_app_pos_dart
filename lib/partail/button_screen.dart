import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:pos_inventory/Productscreen/product_index_screen.dart';
import 'package:pos_inventory/Productscreen/product_view_screen.dart'; // ឧទាហរណ៍ Screen Home របស់បង
import 'package:pos_inventory/constants/translate_constants.dart';
import 'package:pos_inventory/homesccreeen/dashboard_screen.dart';
import 'package:pos_inventory/partail/profile_screen.dart';
import 'package:pos_inventory/partail/setting_screnn.dart';

class ButtonScreen extends StatelessWidget {
  final int
  currentIndex; // 🟢 ទទួលយកសន្ទស្សន៍បច្ចុប្បន្ន (0: Home, 1: Menu, 2: Profile, 3: Settings)

  const ButtonScreen({super.key, required this.currentIndex});

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0);

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      elevation: 15,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🏠 Home (Index 0)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (currentIndex != 0) {
                    Navigator.pushReplacement(
                      context,
                      _createRoute(
                        const DashboardScreen(),
                      ),
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_rounded,
                      color: currentIndex == 0
                          ? Colors.blueAccent
                          : Colors.grey,
                      size: 24,
                    ),
                    Text(
                      TranslateConstants.home.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: currentIndex == 0
                            ? Colors.blueAccent
                            : Colors.grey,
                        fontWeight: currentIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🍔 Menu (Index 1)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (currentIndex != 1) {
                    Navigator.pushReplacement(
                      context,
                      _createRoute(const ProductViewScreen()),
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      color: currentIndex == 1
                          ? Colors.blueAccent
                          : Colors.grey,
                      size: 24,
                    ),
                    Text(
                      TranslateConstants.menu.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: currentIndex == 1
                            ? Colors.blueAccent
                            : Colors.grey,
                        fontWeight: currentIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              width: 48,
            ), // ទុកគម្លាតឱ្យ FloatingActionButton កណ្តាល
            // 👤 Profile (Index 2)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (currentIndex != 2) {
                    Navigator.pushReplacement(
                      context,
                      _createRoute(const ProfileScreen()),
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: currentIndex == 2
                          ? Colors.blueAccent
                          : Colors.grey,
                      size: 24,
                    ),
                    Text(
                    TranslateConstants.profile.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: currentIndex == 2
                            ? Colors.blueAccent
                            : Colors.grey,
                        fontWeight: currentIndex == 2
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ⚙️ Settings (Index 3)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (currentIndex != 3) {
                    Navigator.pushReplacement(
                      context,
                      _createRoute(const SettingScreen()),
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: currentIndex == 3
                          ? Colors.blueAccent
                          : Colors.grey,
                      size: 24,
                    ),
                    Text(
                      // "Settings",
                      TranslateConstants.settings.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: currentIndex == 3
                            ? Colors.blueAccent
                            : Colors.grey,
                        fontWeight: currentIndex == 3
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

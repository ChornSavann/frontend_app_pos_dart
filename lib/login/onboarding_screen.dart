import 'package:flutter/material.dart';
import 'package:pos_inventory/login/sign_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Manage Your Inventory',
      'description':
          'Track products, stock levels, and suppliers easily in one single system with real-time updates.',
      'image':
          'https://i.pinimg.com/1200x/d8/43/df/d843df2ec1fa940efc4834eb655777d8.jpg',
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'Fast & Secure POS',
      'description':
          'Process sales quickly with barcode scanning, custom discounts, and multi-item checkout seamlessly.',
      'image':
          'https://i.pinimg.com/736x/2a/48/ca/2a48cafdc540d67a43bffac964d26e7c.jpg',
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'Real-time Reports',
      'description':
          'Get daily, weekly, and monthly business analytics and financial reports right at your fingertips.',
      'image':
          'https://i.pinimg.com/1200x/e4/b5/87/e4b587be2d0fd9cd63300b1a18e15027.jpg',
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleGoogleLogin() {
    print("Google Login Clicked");
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage == _onboardingData.length - 1;
    var currentThemeColor = _onboardingData[_currentPage]['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // 🟢 ផ្លាស់ប្តូរផ្ទៃខាងក្រោយឱ្យចេញពណ៌ប្រផេះខ្ចីស្អាត
      body: Stack(
        children: [
          // 🎨 Background Decorative Glow Effects
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentThemeColor.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentThemeColor.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ⏭️ Top Bar (Logo & Skip Button)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: currentThemeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: currentThemeColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Fahourity',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      AnimatedOpacity(
                        opacity: isLastPage ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: TextButton(
                          onPressed: isLastPage
                              ? null
                              : () {
                                  _pageController.animateToPage(
                                    _onboardingData.length - 1,
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOutCubic,
                                  );
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🖼️ PageView Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _onboardingData.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final data = _onboardingData[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // រូបភាពមានស៊ុមផ្ទៃស និង Shadow ស្អាតដាច់ដោយឡែក
                            TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.85, end: 1.0),
                              duration: const Duration(milliseconds: 400),
                              key: ValueKey(_currentPage),
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                height: 300,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentThemeColor.withOpacity(
                                        0.18,
                                      ),
                                      blurRadius: 35,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(
                                    data['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              data['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data['description'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ⚪ Indicator Dots (Modern Style)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 32 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? currentThemeColor
                            : currentThemeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 🔐 Modern Action Buttons (Login, Sign Up & Google Sign-In)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      if (isLastPage) ...[
                        // ប៊ូតុង Get Started (ពេលនៅទំព័រចុងក្រោយ)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentThemeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                              shadowColor: currentThemeColor.withOpacity(0.4),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        // ប៊ូតុង Login និង Sign Up ធម្មតា
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: currentThemeColor,
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: currentThemeColor,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 1,
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentThemeColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 6,
                                    shadowColor: currentThemeColor.withOpacity(
                                      0.4,
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 🌐 Google Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _handleGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.06),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://i.pinimg.com/736x/17/b0/95/17b095fc12a1b4fd89f6f032bbec05f9.jpg',
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.g_mobiledata,
                                      size: 24,
                                      color: Colors.blue,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

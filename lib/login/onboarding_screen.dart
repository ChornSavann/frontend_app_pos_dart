import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // A getter (not a final field) so hot reload picks up changes to this data.
  List<Map<String, dynamic>> get _onboardingData => [
    {
      'title': 'Manage Your Inventory',
      'highlight': 'Inventory',
      'description':
      'Track products, stock levels, and suppliers easily in one single system with real-time updates.',
      'image':
      'https://i.pinimg.com/1200x/d8/43/df/d843df2ec1fa940efc4834eb655777d8.jpg',
      'color': const Color(0xFF6366F1),
      'icon': Icons.inventory_2_rounded,
    },
    {
      'title': 'Fast & Secure POS',
      'highlight': 'POS',
      'description':
      'Process sales quickly with barcode scanning, custom discounts, and multi-item checkout seamlessly.',
      'image':
      'https://i.pinimg.com/736x/2a/48/ca/2a48cafdc540d67a43bffac964d26e7c.jpg',
      'color': const Color(0xFF3B82F6),
      'icon': Icons.qr_code_scanner_rounded,
    },
    {
      'title': 'Real-time Reports',
      'highlight': 'Reports',
      'description':
      'Get daily, weekly, and monthly business analytics and financial reports right at your fingertips.',
      'image':
      'https://i.pinimg.com/1200x/e4/b5/87/e4b587be2d0fd9cd63300b1a18e15027.jpg',
      'color': const Color(0xFF8B5CF6),
      'icon': Icons.insights_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleGoogleLogin() {
    debugPrint('Google Login Clicked');
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignScreen()),
    );
  }

  Color _darken(Color c, [double amount = 0.12]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Current page position as a double (updates while swiping).
  double get _page {
    if (_pageController.hasClients && _pageController.position.haveDimensions) {
      return _pageController.page ?? _currentPage.toDouble();
    }
    return _currentPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _onboardingData.length - 1;
    final Color currentThemeColor =
    _onboardingData[_currentPage]['color'] as Color;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // 🎨 Soft dotted pattern at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 360,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (_, __) => CustomPaint(
                    painter: _DotsPainter(
                      color: currentThemeColor.withValues(alpha: 0.16),
                      shift: _page * 18,
                    ),
                  ),
                ),
              ),
            ),

            // 🎨 Background glow
            Positioned(
              top: -100,
              right: -100,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      currentThemeColor.withValues(alpha: 0.2),
                      currentThemeColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -110,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      currentThemeColor.withValues(alpha: 0.15),
                      currentThemeColor.withValues(alpha: 0.0),
                    ],
                  ),
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    currentThemeColor,
                                    _darken(currentThemeColor),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: currentThemeColor.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Fahourity',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        AnimatedOpacity(
                          opacity: isLastPage ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: IgnorePointer(
                            ignoring: isLastPage,
                            child: Material(
                              color: Colors.white,
                              elevation: 0,
                              shape: StadiumBorder(
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: InkWell(
                                customBorder: const StadiumBorder(),
                                onTap: () {
                                  _pageController.animateToPage(
                                    _onboardingData.length - 1,
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOutCubic,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 9,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Skip',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🖼️ PageView Content (with parallax)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _onboardingData.length,
                      onPageChanged: (index) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final data = _onboardingData[index];
                        final Color pageColor = data['color'] as Color;

                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, _) {
                            // -1 (left) … 0 (centre) … 1 (right)
                            final double delta =
                            (index - _page).clamp(-1.0, 1.0).toDouble();
                            final double fade = 1 - delta.abs();

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // រូបភាពមានស៊ុមផ្ទៃស និង Shadow ស្អាតដាច់ដោយឡែក
                                  Transform.translate(
                                    offset: Offset(delta * 36, 0),
                                    child: Transform.scale(
                                      scale: 0.92 + 0.08 * fade,
                                      child: Opacity(
                                        opacity: (0.35 + 0.65 * fade).clamp(0.0, 1.0),
                                        child: _ImageCard(
                                          url: data['image'] as String,
                                          color: pageColor,
                                          icon: (data['icon'] as IconData?) ??
                                              Icons.storefront_rounded,
                                          parallax: delta,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Transform.translate(
                                    offset: Offset(delta * 70, 0),
                                    child: Opacity(
                                      opacity: (fade * fade).clamp(0.0, 1.0),
                                      child: Column(
                                        children: [
                                          _Title(
                                            title: data['title'] as String,
                                            highlight:
                                            (data['highlight'] as String?) ?? '',
                                            color: pageColor,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            data['description'] as String,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.grey.shade600,
                                              height: 1.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
                          gradient: _currentPage == index
                              ? LinearGradient(
                            colors: [
                              currentThemeColor,
                              _darken(currentThemeColor, 0.06),
                            ],
                          )
                              : null,
                          color: _currentPage == index
                              ? null
                              : currentThemeColor.withValues(alpha: 0.2),
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
                          _FilledButton(
                            label: 'Get Started',
                            icon: Icons.arrow_forward_rounded,
                            color: currentThemeColor,
                            darker: _darken(currentThemeColor),
                            onTap: _goLogin,
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          // ប៊ូតុង Login និង Sign Up ធម្មតា
                          Row(
                            children: [
                              Expanded(
                                child: _OutlinedButton(
                                  label: 'Login',
                                  color: currentThemeColor,
                                  onTap: _goLogin,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _FilledButton(
                                  label: 'Sign Up',
                                  color: currentThemeColor,
                                  darker: _darken(currentThemeColor),
                                  onTap: _goSignUp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 🌐 Google Login Button
                        _Pressable(
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _handleGoogleLogin,
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
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Image card: layered cards behind + parallax image + icon badge
// ─────────────────────────────────────────────────────────────
class _ImageCard extends StatelessWidget {
  final String url;
  final Color color;
  final IconData icon;
  final double parallax; // -1..1

  const _ImageCard({
    required this.url,
    required this.color,
    required this.icon,
    required this.parallax,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 314,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // layered cards behind (depth)
          Positioned(
            left: 26,
            right: 26,
            bottom: -2,
            top: 22,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          Positioned(
            left: 13,
            right: 13,
            bottom: 6,
            top: 11,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),

          // main card
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 300,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: color.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.24),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // image slides slightly inside the frame while swiping
                    Transform.translate(
                      offset: Offset(parallax * -22, 0),
                      child: Transform.scale(
                        scale: 1.12,
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, sync) {
                            if (sync) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: color.withValues(alpha: 0.06),
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: color,
                                  value: progress.expectedTotalBytes == null
                                      ? null
                                      : progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
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
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              color.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // icon badge on the corner
          Positioned(
            top: -12,
            right: 18,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, HSLColor.fromColor(color)
                      .withLightness(
                    (HSLColor.fromColor(color).lightness - 0.1).clamp(0.0, 1.0),
                  )
                      .toColor()],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Title with a highlighted keyword
// ─────────────────────────────────────────────────────────────
class _Title extends StatelessWidget {
  final String title;
  final String highlight;
  final Color color;
  const _Title({required this.title, required this.highlight, required this.color});

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: Color(0xFF0F172A),
      letterSpacing: -0.5,
      height: 1.2,
    );

    final i = title.indexOf(highlight);
    if (highlight.isEmpty || i < 0) {
      return Text(title, textAlign: TextAlign.center, style: base);
    }

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: title.substring(0, i)),
          TextSpan(text: highlight, style: base.copyWith(color: color)),
          TextSpan(text: title.substring(i + highlight.length)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Buttons
// ─────────────────────────────────────────────────────────────

/// Scales down slightly while pressed.
class _Pressable extends StatefulWidget {
  final Widget child;
  const _Pressable({required this.child});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color darker;
  final VoidCallback onTap;

  const _FilledButton({
    required this.label,
    required this.color,
    required this.darker,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, darker],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutlinedButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dotted background pattern
// ─────────────────────────────────────────────────────────────
class _DotsPainter extends CustomPainter {
  final Color color;
  final double shift;
  _DotsPainter({required this.color, required this.shift});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 22.0;
    for (double y = 10; y < size.height; y += gap) {
      // fade out towards the bottom
      final t = 1 - (y / size.height);
      paint.color = color.withValues(alpha: color.a * t);
      for (double x = -gap + (shift % gap); x < size.width + gap; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) =>
      old.color != color || old.shift != shift;
}
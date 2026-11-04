import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/login/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _loop;
  late final AnimationController _progress;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
    _loop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _progress = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..forward();

    CurvedAnimation iv(double a, double b, Curve c) =>
        CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: c));

    _logoFade = iv(0.0, 0.5, Curves.easeOut);
    _logoScale = Tween(begin: 0.8, end: 1.0).animate(iv(0.0, 0.6, Curves.easeOutCubic));
    _titleFade = iv(0.35, 0.8, Curves.easeOut);
    _titleSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(iv(0.35, 0.8, Curves.easeOutCubic));
    _subFade = iv(0.6, 1.0, Curves.easeOut);

    _progress.addStatusListener((s) {
      if (s == AnimationStatus.completed) _goNext();
    });
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const OnboardingScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌐 ផ្ទៃខាងក្រោយឋិតិវន្ត (គូរម្តងគត់)
          const RepaintBoundary(child: _Background()),

          // 🎯 មាតិកាកណ្ដាល
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ring រីកចេញ (CustomPainter)
                      RepaintBoundary(
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: CustomPaint(
                            size: const Size(280, 280),
                            painter: _RingPainter(_loop),
                          ),
                        ),
                      ),
                      // Logo
                      RepaintBoundary(
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: const _Logo(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: const Text(
                      'Khmer App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _subFade,
                  child: Text(
                    'Inventory & Khmer APP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ⏳ Progress + Footer
          Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subFade,
              child: Column(
                children: [
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 140,
                          height: 4,
                          child: LinearProgressIndicator(
                            value: _progress.value,
                            backgroundColor: Colors.white24,
                            valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Version 1.0.0 • Developed by Chorn Savann',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -80, right: -80, child: _circle(250, 0.08)),
          Positioned(bottom: -100, left: -100, child: _circle(350, 0.05)),
        ],
      ),
    );
  }

  Widget _circle(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Image.asset(
            'assets/logo.png', // ដាក់រូបក្នុង assets/ ហើយប្រកាសក្នុង pubspec.yaml
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.storefront,
              size: 70,
              color: Color(0xFF4F46E5),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Animation<double> anim;
  _RingPainter(this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (final phase in [0.0, 0.5]) {
      final t = (anim.value + phase) % 1.0;
      final radius = 78 + t * 60;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: (1 - t) * 0.35);
      canvas.drawCircle(c, math.min(radius, size.width / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => false;
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController scannerController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    _startScanner();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
  }

  Future<void> _startScanner() async {
    try {
      await scannerController.start();
    } catch (e) {
      debugPrint("Error starting scanner: $e");
    }
  }

  @override
  void dispose() {
    scannerController.stop();
    scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'ស្កេនកូដផលិតផល',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'KantumruyPro',
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: scannerController,
              builder: (context, state, child) {
                final torchState = state.torchState;
                return IconButton(
                  icon: Icon(
                    torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.amber,
                    size: 20,
                  ),
                  onPressed: () => scannerController.toggleTorch(),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) async {
              if (_isScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _isScanned = true;
                  final scannedCode = barcode.rawValue!.trim();

                  HapticFeedback.mediumImpact();
                  await scannerController.stop();

                  if (mounted) {
                    Navigator.pop(context, scannedCode);
                  }
                  break;
                }
              }
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 280,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      ..._buildCurvedScannerCorners(),
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          double topPosition = _animation.value * 130 + 15;
                          return Positioned(
                            top: topPosition,
                            left: 15,
                            right: 15,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.9),
                                    blurRadius: 8,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ដាក់ Barcode ឲ្យចំក្នុងស៊ុមដើម្បីស្កេន',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'KantumruyPro',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCurvedScannerCorners() {
    const double length = 32;
    const double thickness = 5;
    const Color color = Color(0xFF3B82F6);
    const double radiusValue = 24.0;

    return [
      // លើ - ឆ្វេង (Top-Left)
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radiusValue),
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radiusValue),
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
      ),

      // លើ - ស្ដាំ (Top-Right)
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(radiusValue),
              bottomLeft: Radius.circular(4),
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(radiusValue),
              bottomLeft: Radius.circular(4),
            ),
          ),
        ),
      ),

      // ក្រោម - ឆ្វេង (Bottom-Left)
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(radiusValue),
              topRight: Radius.circular(4),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(radiusValue),
              topRight: Radius.circular(4),
            ),
          ),
        ),
      ),

      // ក្រោម - ស្ដាំ (Bottom-Right)
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(radiusValue),
              topLeft: Radius.circular(4),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(radiusValue),
              topLeft: Radius.circular(4),
            ),
          ),
        ),
      ),
    ];
  }
}
